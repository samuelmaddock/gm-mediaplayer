AddCSLuaFile "shared.lua"
AddCSLuaFile "sh_snapshot.lua"
AddCSLuaFile "cl_draw.lua"
AddCSLuaFile "cl_fullscreen.lua"
AddCSLuaFile "net.lua"
include "shared.lua"
include "net.lua"

-- Additional transmit states
TRANSMIT_LOCATION = 4

-- Media player network strings
util.AddNetworkString( "MEDIAPLAYER.Update" )
util.AddNetworkString( "MEDIAPLAYER.Media" )
util.AddNetworkString( "MEDIAPLAYER.Remove" )
util.AddNetworkString( "MEDIAPLAYER.Pause" )
util.AddNetworkString( "MEDIAPLAYER.Seek" )

function MEDIAPLAYER:PlayPause()
	local playerState = self:GetPlayerState()

	if playerState == MP_STATE_ENDED then
		return
	elseif playerState == MP_STATE_PLAYING then
		self:SetPlayerState( MP_STATE_PAUSED )
	else
		self:SetPlayerState( MP_STATE_PLAYING )
	end

	net.Start( "MEDIAPLAYER.Pause" )
		net.WriteString( self:GetId() )
		self.net.WritePlayerState( self:GetPlayerState() )
	net.Send( self._Listeners )
end

--[[---------------------------------------------------------
	Listeners
-----------------------------------------------------------]]

function MEDIAPLAYER:UpdateListeners()
	local transmitState = self._TransmitState
	local listeners = nil

	if transmitState == TRANSMIT_NEVER then
		return

	elseif transmitState == TRANSMIT_ALWAYS then

		listeners = player.GetAll()

	elseif transmitState == TRANSMIT_PVS then

		listeners = player.GetInPVS( self.Entity and self.Entity or self:GetPos() )

	elseif transmitState == TRANSMIT_LOCATION then

		local loc = self:GetLocation()

		if not Location then
			ErrorNoHalt("'Location' module not defined in mediaplayer!\n")
			debug.Trace()
			return
		elseif loc == -1 then
			ErrorNoHalt("Invalid location assigned to mediaplayer!\n")
			debug.Trace()
			return
		end

		listeners = Location.GetPlayersInLocation( loc )

	else
		ErrorNoHalt("Invalid transmit state for mediaplayer\n")
		debug.Trace()
		return
	end

	self:SetListeners(listeners)
end

function MEDIAPLAYER:GetListeners()
	return self._Listeners
end

function MEDIAPLAYER:SetListeners( listeners )

	local ValidListeners = {}

	-- Filter listeners
	for _, ply in pairs(listeners) do
		if IsValid(ply) and ply:IsConnected() and not ply:IsBot() then
			table.insert( ValidListeners, ply )
		end
	end

	-- Find players who should be removed.
	--
	-- A = self._Listeners
	-- B = listeners
	-- (A ∩ B)^c
	for _, ply in pairs(self._Listeners) do
		if not table.HasValue( ValidListeners, ply ) then
			self:RemoveListener( ply )
		end
	end

	-- Find players who should be added
	for _, ply in pairs(ValidListeners) do
		if not self:HasListener(ply) then
			self:AddListener( ply )
		end
	end

end

function MEDIAPLAYER:AddListener( ply )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.AddListener", self, ply )
	end

	table.insert( self._Listeners, ply )

	-- Send player queue information
	self:BroadcastUpdate(ply)

	-- Send current media to new listener
	if (self:GetPlayerState() >= MP_STATE_PLAYING) then
		self:SendMedia( self:CurrentMedia(), ply )
	end

	hook.Run( "MediaPlayerAddListener", self, ply )

end

function MEDIAPLAYER:RemoveListener( ply )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RemoveListener", self, ply )
	end

	local key = table.RemoveByValue( self._Listeners, ply )

	if not key then
		ErrorNoHalt( "Tried to remove player from media player " ..
			"who wasn't listening\n" )
		debug.Trace()
		return
	end

	-- Inform listener of removal
	net.Start( "MEDIAPLAYER.Remove" )
		net.WriteString( self:GetId() )
	net.Send( ply )

	hook.Run( "MediaPlayerRemoveListener", self, ply )

end

function MEDIAPLAYER:HasListener( ply )
	return table.HasValue( self._Listeners, ply )
end


--[[---------------------------------------------------------
	Queue Management
-----------------------------------------------------------]]

function MEDIAPLAYER:NextMedia( item )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.NextMedia" )
	end

	local media = nil

	-- Grab media from the queue if available
	if not self:IsQueueEmpty() then
		media = table.remove( self._Queue, item or 1 )
		self:QueueUpdated()
	end

	self:SetMedia( media )
	self:SendMedia( media )

	self:BroadcastUpdate()

end

function MEDIAPLAYER:SendMedia( media, ply )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.SendMedia", media )
	end

	-- If we're only sending media to a single player, we don't need to update
	-- all listeners
	if not ply then
		self:UpdateListeners()
	end

	local startTime = media and media:StartTime() or 0
	local receiver = ply or self._Listeners

	net.Start( "MEDIAPLAYER.Media" )
		net.WriteString( self:GetId() )
		self.net.WriteMedia( media )
		if media then
			self.net.WriteTime( startTime )
			self:OnNetWriteMedia( media )
		end
	net.Send( receiver )

end

local function queueTimeSort( a, b )
	local atime = a:GetMetadataValue( "queueTime" )
	local btime = b:GetMetadataValue( "queueTime" )

	return atime < btime
end

function MEDIAPLAYER:SortQueue()
	if self:GetQueueShuffle() then
		return -- queue has been shuffled
	end

	table.sort( self._Queue, queueTimeSort )
end

function MEDIAPLAYER:ShuffleQueue()
	self._Queue = MediaPlayerUtils.Shuffle( self._Queue )
end

--[[---------------------------------------------------------
	Media requests
-----------------------------------------------------------]]

---
-- Determine whether the player is allowed to request media. Override this for
-- custom behavior.
--
-- @return boolean
-- @return string   Error message.
--
function MEDIAPLAYER:CanPlayerRequestMedia( ply, media )
	-- Check service whitelist if it exists on the mediaplayer
	if self.ServiceWhitelist and not (
			table.HasValue(self.ServiceWhitelist, media.Id) or
			ply:IsAdmin()
		) then
		local names = MediaPlayer.GetValidServiceNames(self.ServiceWhitelist)

		local msg = "The requested media isn't supported; accepted services are as followed:\n"
		msg = msg .. table.concat( names, ", " )

		return false, msg
	end

	if self:GetQueueLocked() and not self:IsPlayerPrivileged(ply) then
		return false, "The requested media couldn't be added as the queue is locked."
	end

	return true
end

---
-- Determine whether the media should be added to the queue.
-- This should be overwritten if only certain media should be allowed.
--
-- @return boolean  Whether the media should be queued.
-- @return string   Denied reason.
--
function MEDIAPLAYER:ShouldQueueMedia( media )
	return true, nil
end

function MEDIAPLAYER:RequestMedia( media, ply )

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	local allowed, msg = self:CanPlayerRequestMedia(ply, media)

	if not allowed then
		self:NotifyPlayer( ply, msg and msg or "Your media request has been denied." )
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestMedia", media, ply )
	end

	-- Queue must have space for the request
	if #self._Queue == self:GetQueueLimit() then
		self:NotifyPlayer( ply, "The media player queue is full." )
		return
	end

	-- Make sure the media isn't already in the queue
	for _, s in ipairs(self._Queue) do
		if s.Id == media.Id and s:UniqueID() == media:UniqueID() then
			if MediaPlayer.DEBUG then
				print("MediaPlayer.RequestMedia: Duplicate request", s.Id, media.Id)
				print(media)
				print(s)
			end
			self:NotifyPlayer( ply, "The requested media was already in the queue" )
			return
		end
	end

	-- TODO: prevent media from playing if this hook returns false(?)
	hook.Run( "PreMediaPlayerMediaRequest", self, media, ply )

	-- self:NotifyPlayer( ply, "Processing media request..." )

	-- Fetch the media's metadata
	media:GetMetadata(function(data, err)

		if not data then
			err = err and err or "There was a problem fetching the requested media's metadata."
			print(err)
			self:NotifyPlayer( ply, "[Request Error] " .. err )
			return
		end

		media:SetOwner( ply )

		local queueMedia, msg = self:ShouldQueueMedia( media )

		if not queueMedia then
			self:NotifyPlayer( ply,
				msg and msg or "The requested media couldn't be queued." )
			return
		end

		-- Add the media to the queue
		self:AddMedia( media )
		self:QueueUpdated()

		local msg = string.format( "Added '%s' to the queue", media:Title() )
		self:NotifyPlayer( ply, msg )

		self:BroadcastUpdate()

		MediaPlayer.History:LogRequest( media )

		hook.Run( "PostMediaPlayerMediaRequest", self, media, ply )

	end)

end

function MEDIAPLAYER:RequestPause( ply )

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	-- Check player priviledges
	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestPause", ply )
	end

	self:PlayPause()

end

function MEDIAPLAYER:RequestSkip( ply )

	if not (self:GetPlayerState() >= MP_STATE_PLAYING) then return end

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	-- Check player priviledges
	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestSkip", ply )
	end

	self:OnMediaFinished()

end

function MEDIAPLAYER:RequestSeek( ply, seekTime )

	if not (self:GetPlayerState() >= MP_STATE_PLAYING) then return end

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	-- Check player priviledges
	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestSeek", ply, seekTime )
	end

	local media = self:CurrentMedia()

	-- Ignore requests for media that isn't timed
	if not media:IsTimed() then
		return
	end

	-- Ignore request if time is past the end of the video
	if seekTime > media:Duration() then
		self:NotifyPlayer( ply, "Request seek time was past the end of the media duration." )
		return
	end

	local startTime = RealTime() - seekTime
	media:StartTime( startTime )

	self:UpdateListeners()

	net.Start( "MEDIAPLAYER.Seek" )
		net.WriteString( self:GetId() )
		self.net.WriteTime( startTime )
	net.Send( self._Listeners )

end

function MEDIAPLAYER:RequestRemove( ply, mediaUID )

	if not (self:GetPlayerState() >= MP_STATE_PLAYING) then return end

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestRemove", ply, mediaUID )
	end

	local privileged = self:IsPlayerPrivileged(ply)
	local currentMedia = self:GetMedia()

	if currentMedia:UniqueID() == mediaUID then
		if privileged then
			self:NextMedia()
		else
			self:NotifyPlayer(ply, "You don't have permission to do that.")
		end
	else
		local idx, media

		for k, v in pairs(self._Queue) do
			if v:UniqueID() == mediaUID then
				idx, media = k, v
				break
			end
		end

		if media and ( media:GetOwner() == ply or privileged ) then
			table.remove( self._Queue, idx )
			self:BroadcastUpdate()
		end
	end

end

function MEDIAPLAYER:RequestRepeat( ply )

	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	self:SetQueueRepeat( not self:GetQueueRepeat() )
	self:BroadcastUpdate()

end

function MEDIAPLAYER:RequestShuffle( ply )

	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	self:SetQueueShuffle( not self:GetQueueShuffle() )
	self:BroadcastUpdate()

end

function MEDIAPLAYER:RequestLock( ply )

	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	if not self:IsPlayerPrivileged(ply) then
		self:NotifyPlayer(ply, "You don't have permission to do that.")
		return
	end

	self:SetQueueLocked( not self:GetQueueLocked() )
	self:BroadcastUpdate()

end


--[[---------------------------------------------------------
	Media Player Updates
-----------------------------------------------------------]]

function MEDIAPLAYER:BroadcastUpdate( ply )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.BroadcastUpdate", ply )
	end

	self:UpdateListeners()

	local receivers

	if ply then
		receivers = {ply}
	else
		receivers = self._Listeners
	end

	-- iterate and send net message to each player since their payload may be
	-- unique to themselves.
	for _, pl in ipairs(receivers) do
		net.Start( "MEDIAPLAYER.Update" )
			net.WriteString( self:GetId() )		-- unique ID
			net.WriteString( self.Name )		-- media player type
			net.WriteEntity( self:GetOwner() )
			self.net.WritePlayerState( self:GetPlayerState() )

			net.WriteBool( self:GetQueueRepeat() )
			net.WriteBool( self:GetQueueShuffle() )
			net.WriteBool( self:GetQueueLocked() )

			self:NetWriteUpdate( pl )				-- mp type-specific info

			net.WriteUInt( #self._Queue, self:GetQueueLimit(true) )
			for _, media in ipairs(self._Queue) do
				self.net.WriteMedia(media)
				self:OnNetWriteMedia( media, pl )
			end
		net.Send( pl )
	end

end

function MEDIAPLAYER:NetWriteUpdate( ply )
	-- Allows for another media player type to extend update net messages
end

function MEDIAPLAYER:OnNetWriteMedia( media, ply )
	-- Allows for another media player type to extend media net messages
end

function MEDIAPLAYER:NotifyListeners( msg )
	for _, ply in ipairs( self._Listeners ) do
		self:NotifyPlayer( ply, msg )
	end
end

function MEDIAPLAYER:NotifyPlayer( ply, msg )
	if not hook.Run( "MediaPlayerNotifyPlayer", self, ply, msg ) then
		msg = msg:sub( 1, 249 ) -- avoid ChatPrint limit
		ply:ChatPrint( msg )
	end
end
