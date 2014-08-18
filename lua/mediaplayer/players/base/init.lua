AddCSLuaFile "shared.lua"
AddCSLuaFile "cl_draw.lua"
AddCSLuaFile "cl_fullscreen.lua"
AddCSLuaFile "cl_net.lua"
include "shared.lua"
include "sv_net.lua"

-- Additional transmit states
TRANSMIT_LOCATION = 4

-- Media player network strings
util.AddNetworkString( "MEDIAPLAYER.Update" )
util.AddNetworkString( "MEDIAPLAYER.Media" )
util.AddNetworkString( "MEDIAPLAYER.Remove" )
util.AddNetworkString( "MEDIAPLAYER.Pause" )
util.AddNetworkString( "MEDIAPLAYER.Seek" )


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

	hook.Call( "MediaPlayerAddListener", self, ply )

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

	hook.Call( "MediaPlayerRemoveListener", self, ply )

end

function MEDIAPLAYER:HasListener( ply )
	return table.HasValue( self._Listeners, ply )
end


--[[---------------------------------------------------------
	Queue Management
-----------------------------------------------------------]]

function MEDIAPLAYER:NextMedia()

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.NextMedia" )
	end

	local media = nil

	-- Grab media from the queue if available
	if not self:IsQueueEmpty() then
		media = table.remove( self._Queue, 1 )
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

	self:UpdateListeners()

	local startTime = media and media:StartTime() or 0

	net.Start( "MEDIAPLAYER.Media" )
		net.WriteString( self:GetId() )
		self.net.WriteMedia( media )
		self.net.WriteTime( startTime )
	net.Send( ply or self._Listeners )

end


--[[---------------------------------------------------------
	Media requests
-----------------------------------------------------------]]

---
-- Determine whether the player is allowed to request media. Override this for
-- custom behavior.
--
-- @return boolean
--
function MEDIAPLAYER:CanPlayerRequestMedia( ply, media )
	-- Check service whitelist if it exists on the mediaplayer
	if self.ServiceWhitelist and not table.HasValue(self.ServiceWhitelist, media.Id) then
		local names = MediaPlayer.GetValidServiceNames(self.ServiceWhitelist)

		local msg = "The requested media isn't supported; accepted services are as followed:\n"
		msg = msg .. table.concat( names, ", " )

		self:NotifyPlayer( ply, msg )

		return false
	end

	return true
end

---
-- Determine whether the media should be added to the queue.
-- This should be overwritten if only certain media should be allowed.
--
-- @return boolean
--
function MEDIAPLAYER:ShouldAddMedia( media )
	return true
end

-- TODO: Remove this function in favor of RequestMedia
function MEDIAPLAYER:RequestUrl( url, ply )

	if not IsValid(ply) then return end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestUrl", url, ply )
	end

	-- Queue must have space for the request
	if #self._Queue == self.MaxMediaItems then
		self:NotifyPlayer( ply, "The media player queue is full." )
		return
	end

	-- Validate the URL
	if not MediaPlayer.ValidUrl( url ) then
		self:NotifyPlayer( ply, "The requested URL wasn't valid." )
		return
	end

	-- Build the media object for the URL
	local media = MediaPlayer.GetMediaForUrl( url )

	self:RequestMedia( media, ply )

end

function MEDIAPLAYER:RequestMedia( media, ply )

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) and
			self:CanPlayerRequestMedia(ply, media) ) then
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestMedia", media, ply )
	end

	-- Queue must have space for the request
	if #self._Queue == self.MaxMediaItems then
		self:NotifyPlayer( ply, "The media player queue is full." )
		return
	end

	-- Make sure the media isn't already in the queue
	for _, s in pairs(self._Queue) do
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
			self:NotifyPlayer( ply, "[Request Error] " .. err )
			return
		end

		media:SetOwner( ply )

		if not self:ShouldAddMedia(media) then
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
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestPause", ply )
	end

	-- Toggle player state
	if self:GetPlayerState() == MP_STATE_PLAYING then
		self:SetPlayerState( MP_STATE_PAUSED )
	else
		self:SetPlayerState( MP_STATE_PLAYING )
	end

	net.Start( "MEDIAPLAYER.Pause" )
		net.WriteString( self:GetId() )
		self.net.WritePlayerState( self:GetPlayerState() )
	net.Send( self._Listeners )

end

function MEDIAPLAYER:RequestSkip( ply )

	if not (self:GetPlayerState() >= MP_STATE_PLAYING) then return end

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	-- Check player priviledges
	if not self:IsPlayerPrivileged(ply) then
		return
	end

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.RequestSkip", ply )
	end

	self:NextMedia()

end

local function ParseTime( time )
    local tbl = {}

	-- insert fragments in reverse
	for fragment, _ in string.gmatch(time, ":?(%d+)") do
		table.insert(tbl, 1, tonumber(fragment) or 0)
	end

	if #tbl == 0 then
		return nil
	end

	local seconds = 0

	for i = 1, #tbl do
		seconds = seconds + tbl[i] * math.max(60 ^ (i-1), 1)
	end

	return seconds
end

function MEDIAPLAYER:RequestSeek( ply, seekTime )

	if not (self:GetPlayerState() >= MP_STATE_PLAYING) then return end

	-- Player must be valid and also a listener
	if not ( IsValid(ply) and self:HasListener(ply) ) then
		return
	end

	-- Check player priviledges
	if not self:IsPlayerPrivileged(ply) then
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

	-- Convert HH:MM:SS to seconds
	local seconds = ParseTime( seekTime )
	if not seconds then return end

	-- Ignore request if time is past the end of the video
	if seconds > media:Duration() then
		self:NotifyPlayer( ply, "Request seek time was past the end of the media duration" )
		return
	end

	local startTime = RealTime() - seconds
	media:StartTime( startTime )

	self:UpdateListeners()

	net.Start( "MEDIAPLAYER.Seek" )
		net.WriteString( self:GetId() )
		self.net.WriteTime( startTime )
	net.Send( self._Listeners )

end


--[[---------------------------------------------------------
	Media Player Updates
-----------------------------------------------------------]]

function MEDIAPLAYER:BroadcastUpdate( ply )

	if MediaPlayer.DEBUG then
		print( "MEDIAPLAYER.BroadcastUpdate", ply )
	end

	self:UpdateListeners()

	net.Start( "MEDIAPLAYER.Update" )
		net.WriteString( self:GetId() )
		net.WriteString( self.Name )
		self.net.WritePlayerState( self:GetPlayerState() )
		self:NetWriteUpdate()
		net.WriteUInt( #self._Queue, math.CeilPower2(self.MaxMediaItems)/2 )
		for _, media in pairs(self._Queue) do
			self.net.WriteMedia(media)
		end
	net.Send( ply or self._Listeners )

end

function MEDIAPLAYER:NetWriteUpdate()
	-- Allows for another media player type to extend update net messages
end

-- Player requesting queue update
net.Receive( "MEDIAPLAYER.Update", function(len, ply)
	local id = net.ReadString()
	local mp = MediaPlayer.GetById(id)
	if not mp then return end
	-- TODO: prevent request spam
	mp:BroadcastUpdate(ply)
end )


function MEDIAPLAYER:NotifyPlayer( ply, msg )
	ply:ChatPrint( msg )
end
