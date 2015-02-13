--[[--------------------------------------------
	Vote object
----------------------------------------------]]

local VOTE = {}
VOTE.__index = VOTE

function VOTE:New( ply, value )
	local obj = setmetatable( {}, self )

	obj.player = ply
	obj.value = value or 1

	return obj
end

function VOTE:IsValid()
	return IsValid(self.player)
end

function VOTE:GetPlayer()
	return self.player
end

function VOTE:GetValue()
	return self.value
end

MediaPlayer.VOTE = VOTE


--[[--------------------------------------------
	Vote Manager
----------------------------------------------]]

local VoteManager = {}
VoteManager.__index = VoteManager

--
-- Initialize the media player object.
--
-- @param mp Media player object.
--
function VoteManager:New( mp )
	local obj = setmetatable({}, self)
	obj._mp = mp
	obj._votes = {}
	return obj
end

---
-- Clears all votes.
--
function VoteManager:Clear()
	self._votes = {}
end

function VoteManager:ClearVotesForMedia( media )
	self._votes[media:UniqueID()] = nil
end

---
-- Add vote for a player and media
--
-- @param media	Media object.
-- @param ply	Player.
-- @param value	Vote value.
--
function VoteManager:AddVote( media, ply, value )
	if not IsValid(ply) then return end

	local uid = media:UniqueID()

	local votes

	if self._votes[uid] then
		votes = self._votes[uid]
	else
		votes = {
			media = media,
			count = 0
		}
		self._votes[uid] = votes
	end

	local vote = self:GetVoteByPlayer(media, ply)

	-- Update vote if player has already voted
	if vote then
		vote.value = value
	else
		vote = VOTE:New(ply, value)
		table.insert( votes, vote )
	end

	-- player is retracting their vote
	if value == 0 then
		for k, v in ipairs(votes) do
			if v:GetPlayer() == ply then
				table.remove( votes, k )
				break
			end
		end
	end

	-- recalculate vote count
	self:GetVoteCountForMedia( media, true )
end

---
-- Remove the player's vote for a media item.
--
-- @param media	Media object.
-- @param ply	Player.
--
function VoteManager:RemoveVote( media, ply )
	self:AddVote( media, ply, 0 )
end

---
-- Get whether the player has already voted for the media.
--
-- @param media	Media object.
-- @param ply	Player.
-- @return Whether the player has voted for the media.
--
function VoteManager:HasVoted( media, ply )
	local uid = media:UniqueID()

	local votes = self._votes[uid]
	if not votes then return false end

	for k, vote in ipairs(votes) do
		if vote:GetPlayer() == ply then
			return true
		end
	end

	return false
end

---
-- Get the vote count for the given media.
--
-- @param media	Media object or UID.
-- @return Vote count for media.
--
function VoteManager:GetVoteCountForMedia( media, forceCalc )
	local uid = isstring(media) and media or media:UniqueID()

	local votes = self._votes[uid]
	if not votes then return 0 end

	if not votes.count or forceCalc then
		local count = 0

		for k, vote in ipairs(votes) do
			count = count + vote:GetValue()
		end

		votes.count = count
	end

	return votes.count
end

function VoteManager:GetVoteByPlayer( media, ply )
	local uid = media:UniqueID()

	local votes = self._votes[uid]
	if not votes then return nil end

	for _, vote in ipairs(votes) do
		if vote:GetPlayer() == ply then
			return vote
		end
	end

	return nil
end

---
-- Get the top voted media unique ID. VoteManager:Invalidate() should be called
-- prior to this in case any players may have disconnected.
--
-- @param removeMedia	Remove the media from the vote manager.
-- @return Top voted media UID.
--
function VoteManager:GetTopVote( removeMedia )
	local media, topVotes = nil, nil

	for uid, _ in pairs(self._votes) do
		local votes = self:GetVoteCountForMedia( uid )

		if not topVotes or votes > topVotes then
			media = self._votes[uid].media
			topVotes = votes
		end
	end

	if removeMedia and media then
		self._votes[media:UniqueID()] = nil
	end

	return media, topVotes
end

---
-- Iterate through all votes and determine if they're still valid. This should
-- called prior to getting the top vote.
--
-- @return Whether any votes were invalid and removed.
--
function VoteManager:Invalidate()
	local changed = false

	for uid, votes in pairs(self._votes) do
		local numVotes = 0

		for k, vote in ipairs(votes) do
			-- check for valid player in case they may have disconnected
			if not (IsValid(vote) and self._mp:HasListener(vote:GetPlayer())) then
				table.remove( votes, k )
				changed = true
			else
				numVotes = numVotes + 1
			end
		end

		if numVotes == 0 then
			self._votes[uid] = nil
		end
	end

	return changed
end

MediaPlayer.VoteManager = VoteManager
