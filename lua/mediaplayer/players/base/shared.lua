local MediaPlayer = MediaPlayer

local HasFocus = system.HasFocus
local MuteUnfocused = MediaPlayer.Cvars.MuteUnfocused
local CeilPower2 = MediaPlayerUtils.CeilPower2

--[[---------------------------------------------------------
	Base Media Player
-----------------------------------------------------------]]

local MEDIAPLAYER = MEDIAPLAYER
MEDIAPLAYER.__index = MEDIAPLAYER

-- Inherit EventEmitter for all mediaplayer instances
EventEmitter:new(MEDIAPLAYER)

MEDIAPLAYER.Name = "base"
MEDIAPLAYER.IsMediaPlayer = true
MEDIAPLAYER.NoMedia = "\4" -- end of transmission character

-- Media Player states
MP_STATE_ENDED = 0
MP_STATE_PLAYING = 1
MP_STATE_PAUSED  = 2
NUM_MP_STATE = 3

include "sh_snapshot.lua"

--
-- Initialize the media player object.
--
function MEDIAPLAYER:Init(params)
	self._Queue = {}		-- media queue
	self._Media = nil		-- current media
	self._Owner = nil		-- media player owner

	self._State = MP_STATE_ENDED -- waiting for new media

	if SERVER then

		self._TransmitState = TRANSMIT_ALWAYS
		self._Listeners = {}

		self._Location = -1

	else

		self._LastMediaUpdate = 0
		inputhook.Add( KEY_Q, self, self.OnQueueKeyPressed )
		inputhook.Add( KEY_C, self, self.OnQueueKeyPressed )

	end

	-- Merge in any passed in params
	-- table.Merge(self, params or {})
end

--
-- Get whether the media player is valid.
--
-- @return boolean	Whether the media player is valid
--
function MEDIAPLAYER:IsValid()
	if self._removed then
		return false
	end

	return true
end

--
-- String coercion metamethod
--
-- @return String	Media player string representation
--
function MEDIAPLAYER:__tostring()
	return self:GetId()
end

--
-- Get the media player's unique ID.
--
-- @return Number	Media player ID.
--
function MEDIAPLAYER:GetId()
	return self.id
end

--
-- Get the media player's type.
--
-- @return String	MP type.
--
function MEDIAPLAYER:GetType()
	return self.Name
end

function MEDIAPLAYER:GetPlayerState()
	return self._State
end

function MEDIAPLAYER:SetPlayerState( state )
	local current = self._State
	self._State = state

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.SetPlayerState", state )
	end

	if current ~= state then
		self:OnPlayerStateChanged( current, state )
	end
end

function MEDIAPLAYER:OnPlayerStateChanged( old, new )
	local media = self:GetMedia()
	local validMedia = IsValid(media)

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.OnPlayerStateChanged", old .. ' => ' .. new )
	end

	if new == MP_STATE_PLAYING then
		if validMedia and not media:IsPlaying() then
			media:Play()
		end
	elseif new == MP_STATE_PAUSED then
		if validMedia and media:IsPlaying() then
			media:Pause()
		end
	end

	self:emit( MP.EVENTS.PLAYER_STATE_CHANGED, new, old )
end

--
-- Get whether the media player is currently playing media.
--
-- @return boolean	Media is playing
--
function MEDIAPLAYER:IsPlaying()
	return self._State == MP_STATE_PLAYING
end

--
-- Get the media player's position.
--
-- @return Vector3	Media player's position
--
function MEDIAPLAYER:GetPos()
	if not self._pos then
		self._pos = Vector(0,0,0)
	end
	return self._pos
end

--
-- Get the media player's location ID.
--
-- @return Number	Media player's location ID
--
function MEDIAPLAYER:GetLocation()
	return self._Location
end

function MEDIAPLAYER:GetOwner()
	return self._Owner
end

function MEDIAPLAYER:SetOwner( ply )
	self._Owner = ply
end

---
-- Determines if the player has privileges to use media controls (skip, seek,
-- etc.). Override this for custom behavior.
--
function MEDIAPLAYER:IsPlayerPrivileged( ply )
	return ply == self:GetOwner() or ply:IsAdmin() or
		hook.Run( "MediaPlayerIsPlayerPrivileged", self, ply )
end

---
-- Media player update
--
function MEDIAPLAYER:Think()

	if SERVER then
		self:UpdateListeners()
	end

	local media = self:GetMedia()
	local validMedia = IsValid(media)

	-- Waiting to play new media
	if SERVER then
		if self._State <= MP_STATE_ENDED then

			-- Check queue for videos to play
			if not self:IsQueueEmpty() then
				self:OnMediaFinished()
			end

		elseif self._State == MP_STATE_PLAYING then

			-- Wait for media to finish
			if validMedia and media:IsTimed() then
				local time = media:CurrentTime()
				local duration = media:Duration()

				if time > duration then
					self:OnMediaFinished()
				end
			end

		end
	end

	if CLIENT and validMedia then
		media:Sync()

		local volume

		-- TODO: add a GAMEMODE hook to determine if sound should be muted
		if not HasFocus() and MuteUnfocused:GetBool() then
			volume = 0
		else
			volume = MediaPlayer.Volume()
		end

		media:Volume( volume )
	end

end

--
-- Get the currently playing media.
--
-- @return Media	Currently playing media
--
function MEDIAPLAYER:GetMedia()
	return self._Media
end

MEDIAPLAYER.CurrentMedia = MEDIAPLAYER.GetMedia

--
-- Set the currently playing media.
--
-- @param media		Media object.
--
function MEDIAPLAYER:SetMedia( media )
	self._Media = media
	self:OnMediaStarted( media )

	-- NOTE: media can be nil!
	self:emit(MP.EVENTS.MEDIA_CHANGED, media)
end

--
-- Get the media queue.
-- TODO: Remove this as it should only be accessed internally?
--
-- @return table	Media queue.
--
function MEDIAPLAYER:GetMediaQueue()
	return self._Queue
end

--
-- Clear the media queue.
--
function MEDIAPLAYER:ClearMediaQueue()
	self._Queue = {}
	if SERVER then
		self:BroadcastUpdate()
	end
end

--
-- Get whether the media queue is empty.
--
-- @return boolean	Whether the queue is empty
--
function MEDIAPLAYER:IsQueueEmpty()
	return #self._Queue == 0
end

function MEDIAPLAYER:GetQueueLimit( bNetLength )
	local limit = MediaPlayer.Cvars.QueueLimit:GetInt()

	if bNetLength then
		limit = math.max( CeilPower2( limit ) / 2, 2 )
	end

	return limit
end

function MEDIAPLAYER:GetQueueRepeat()
	return self._QueueRepeat
end

function MEDIAPLAYER:SetQueueRepeat( shouldRepeat )
	self._QueueRepeat = shouldRepeat
end

function MEDIAPLAYER:GetQueueShuffle()
	return self._QueueShuffle
end

function MEDIAPLAYER:SetQueueShuffle( shouldShuffle )
	self._QueueShuffle = shouldShuffle

	if SERVER then
		if shouldShuffle then
			self:ShuffleQueue()
		else
			self:SortQueue()
		end
	end
end

function MEDIAPLAYER:GetQueueLocked()
	return self._QueueLocked
end

function MEDIAPLAYER:SetQueueLocked( locked )
	self._QueueLocked = locked
end

---
-- Called when the queue is updated; emits a change event.
--
function MEDIAPLAYER:QueueUpdated()
	if SERVER then
		self:SortQueue()
	end

	self:emit( MP.EVENTS.QUEUE_CHANGED, self._Queue )
end

--
-- Add media to the queue.
--
-- @param media		Media object.
--
function MEDIAPLAYER:AddMedia( media )
	if not media then return end

	if SERVER then
		-- cache the time the media has been queued for sorting purposes
		media:SetMetadataValue("queueTime", RealTime())
	end

	table.insert( self._Queue, media )
end

--
-- Event called when media should begin playing.
--
-- @param media		Media object to be played.
--
function MEDIAPLAYER:OnMediaStarted( media )

	media = media or self:CurrentMedia()

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.OnMediaStarted", media )
	end

	if IsValid(media) then

		if SERVER then
			local startTime
			local currentTime = media:CurrentTime()

			if currentTime > 0 then
				startTime = RealTime() - currentTime
			else
				startTime = RealTime()
			end

			media:StartTime( startTime + 1 )
		else
			self._LastMediaUpdate = RealTime()
		end

		if SERVER then
			self:SetPlayerState( MP_STATE_PLAYING )
		end

		self:emit('mediaStarted', media)

	elseif SERVER then
		self:SetPlayerState( MP_STATE_ENDED )
	end

end

--
-- Event called when media should stop playing and the next in the queue
-- should begin.
--
-- @param media		Media object to stop.
--
function MEDIAPLAYER:OnMediaFinished( media )

	media = media or self:CurrentMedia()

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.OnMediaFinished", media )
	end

	if SERVER then
		self:SetPlayerState( MP_STATE_ENDED )
	end

	self._Media = nil

	if CLIENT and IsValid(media) then
		media:Stop()
	end

	self:emit('mediaFinished', media)

	if SERVER then
		if media and self:GetQueueRepeat() then
			media:ResetTime()
			self:AddMedia( media )
		end

		self:NextMedia()
	end

end

--
-- Event called when the media player is to be removed/destroyed.
--
function MEDIAPLAYER:Remove()
	MediaPlayer.Destroy( self )
	self._removed = true

	if SERVER then

		-- Remove all listeners
		for _, ply in pairs( self._Listeners ) do
			-- TODO: it's probably better not to send individual net messages
			-- for each player removed.
			self:RemoveListener( ply )
		end

	else

		local media = self:CurrentMedia()

		if IsValid(media) then
			media:Stop()
		end

	end
end

function MEDIAPLAYER:GetSupportedServiceIDs()

	local serviceIDs = table.Copy( MediaPlayer.GetSupportedServiceIDs() )

	if self.ServiceWhitelist then
		local tbl = {}

		for _, id in ipairs(serviceIDs) do
			if table.HasValue( self.ServiceWhitelist, id ) then
				table.insert( tbl, id )
			end
		end

		serviceIDs = tbl
	end

	return serviceIDs

end
