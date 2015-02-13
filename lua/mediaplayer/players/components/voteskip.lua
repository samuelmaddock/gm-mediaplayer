--[[--------------------------------------------
	Voteskip Manager
----------------------------------------------]]

local VoteskipManager = {}
VoteskipManager.__index = VoteskipManager

local VOTESKIP_REQ_VOTE_RATIO = 2/3

---
-- Initialize the Voteskip Manager object.
--
function VoteskipManager:New( mp, ratio )
	local obj = setmetatable({}, self)
	obj._mp = mp
	obj._votes = {}
	obj._value = 0
	obj._ratio = VOTESKIP_REQ_VOTE_RATIO
	return obj
end

function VoteskipManager:GetNumVotes()
	return self._value
end

function VoteskipManager:GetNumRequiredVotes( totalPlayers )
	return math.ceil( totalPlayers * self._ratio )
end

function VoteskipManager:GetNumRemainingVotes( totalPlayers )
	local numVotes = self:GetNumVotes()
	local reqVotes = self:GetNumRequiredVotes( totalPlayers )
	return ( reqVotes - numVotes )
end

function VoteskipManager:ShouldSkip( totalPlayers )
	if totalPlayers <= 0 then
		return false
	end

	self:Invalidate()

	local reqVotes = self:GetNumRequiredVotes( totalPlayers )
	return ( self._value >= reqVotes )
end

---
-- Clears all votes.
--
function VoteskipManager:Clear()
	self._votes = {}
	self._value = 0
end

---
-- Add vote.
--
-- @param ply	Player.
-- @param value	Vote value.
--
function VoteskipManager:AddVote( ply, value )
	if not IsValid(ply) then return end
	if not value then value = 1 end

	-- value can't be negative
	value = math.max( 0, value )

	local uid = ply:SteamID64()
	local vote = self._votes[ uid ]

	if vote then
		-- update existing vote
		if value == 0 then
			-- clear player vote
			self._votes[ uid ] = nil
		else
			vote.value = value
		end
	else
		vote = MediaPlayer.VOTE:New( ply, value )
		self._votes[ uid ] = vote
	end

	self:Invalidate()
end

---
-- Remove the player's vote.
--
-- @param ply	Player.
--
function VoteskipManager:RemoveVote( ply )
	self:AddVote( ply, 0 )
end

---
-- Get whether the player has already voted.
--
-- @param ply	Player.
-- @return Whether the player has voted.
--
function VoteskipManager:HasVoted( ply )
	if not IsValid( ply ) then return false end

	local uid = ply:SteamID64()
	local vote = self._votes[ uid ]

	return ( vote ~= nil )
end

---
-- Iterate through all votes and determine if they're still valid. This should
-- called prior to getting the top vote.
--
-- @return Whether any votes were invalid and removed.
--
function VoteskipManager:Invalidate()
	local value = 0
	local changed = false

	for uid, vote in pairs(self._votes) do
		local ply = vote.player
		if IsValid( ply ) and self._mp:HasListener( ply ) then
			value = value + vote.value
		else
			self._votes[ uid ] = nil
			changed = true
		end
	end

	if self._value ~= value then
		self._value = value
		changed = true
	end

	return changed
end

MediaPlayer.VoteskipManager = VoteskipManager
