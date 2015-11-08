include "shared.lua"
include "cl_draw.lua"
include "cl_fullscreen.lua"
include "net.lua"

local CeilPower2 = MediaPlayerUtils.CeilPower2

function MEDIAPLAYER:NetReadUpdate()
	-- Allows for another media player type to extend update net messages
end

function MEDIAPLAYER:OnNetReadMedia( media )
	-- Allows for another media player type to extend media net messages
end

function MEDIAPLAYER:OnQueueKeyPressed( down, held )
	self._LastMediaUpdate = RealTime()
end


--[[---------------------------------------------------------
	Networking
-----------------------------------------------------------]]

local function OnMediaUpdate( len )

	local mpId = net.ReadString()
	local mpType = net.ReadString()

	if MediaPlayer.DEBUG then
		print( "Received MEDIAPLAYER.Update", mpId, mpType )
	end

	local mp = MediaPlayer.GetById(mpId)
	if not mp then
		mp = MediaPlayer.Create( mpId, mpType )
	end

	-- Read owner; may be NULL
	local owner = net.ReadEntity()
	if IsValid( owner ) then
		mp:SetOwner( owner )
	end

	local state = mp.net.ReadPlayerState()

	local queueRepeat = net.ReadBool()
	mp:SetQueueRepeat( queueRepeat )

	local queueShuffle = net.ReadBool()
	mp:SetQueueShuffle( queueShuffle )

	local queueLocked = net.ReadBool()
	mp:SetQueueLocked( queueLocked )

	-- Read extended update information
	mp:NetReadUpdate()

	-- Clear old queue
	mp:ClearMediaQueue()

	-- Read queue information
	local count = net.ReadUInt( mp:GetQueueLimit(true) )
	for i = 1, count do
		local media = mp.net.ReadMedia()
		mp:OnNetReadMedia(media)
		mp:AddMedia(media)
	end

	mp:QueueUpdated()

	mp:SetPlayerState( state )

	hook.Call( "OnMediaPlayerUpdate", mp )

end
net.Receive( "MEDIAPLAYER.Update", OnMediaUpdate )

local function OnMediaSet( len )

	if MediaPlayer.DEBUG then
		print( "Received MEDIAPLAYER.Media" )
	end

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)

	if not mp then
		if MediaPlayer.DEBUG then
			ErrorNoHalt("Received media for invalid mediaplayer\n")
			print("ID: " .. tostring(mpId))
			debug.Trace()
		end
		return
	end

	if mp:GetPlayerState() >= MP_STATE_PLAYING then
		mp:OnMediaFinished()
		mp:QueueUpdated()
	end

	local media = mp.net.ReadMedia()

	if media then
		local startTime = mp.net.ReadTime()
		media:StartTime( startTime )

		mp:OnNetReadMedia(media)

		local state = mp:GetPlayerState()

		if state == MP_STATE_PLAYING then
			media:Play()
		else
			media:Pause()
		end
	end

	mp:SetMedia( media )

end
net.Receive( "MEDIAPLAYER.Media", OnMediaSet )

local function OnMediaRemoved( len )

	if MediaPlayer.DEBUG then
		print( "Received MEDIAPLAYER.Remove" )
	end

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)
	if not mp then return end

	mp:Remove()

end
net.Receive( "MEDIAPLAYER.Remove", OnMediaRemoved )

local function OnMediaSeek( len )

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)
	if not ( mp and (mp:GetPlayerState() >= MP_STATE_PLAYING) ) then return end

	local startTime = mp.net.ReadTime()

	if MediaPlayer.DEBUG then
		print( "Received MEDIAPLAYER.Seek", mpId, startTime )
	end

	local media = mp:CurrentMedia()

	if media then
		media:StartTime( startTime )
	else
		ErrorNoHalt('ERROR: MediaPlayer received seek message while no media is playing' ..
			'[' .. mpId .. ']\n')
		MediaPlayer.RequestUpdate( mp )
	end

end
net.Receive( "MEDIAPLAYER.Seek", OnMediaSeek )

local function OnMediaPause( len )

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)
	if not mp then return end

	local state = mp.net.ReadPlayerState()

	if MediaPlayer.DEBUG then
		print( "Received MEDIAPLAYER.Pause", mpId, state )
	end

	mp:SetPlayerState( state )

end
net.Receive( "MEDIAPLAYER.Pause", OnMediaPause )
