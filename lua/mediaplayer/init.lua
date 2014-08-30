if MediaPlayer then
	-- TODO: compare versions?
	if MediaPlayer.__refresh then
		MediaPlayer.__refresh = nil
	else
		return -- MediaPlayer has already been registered
	end
end

resource.AddFile "materials/mediaplayer/ui/spritesheet.png"
resource.AddFile "resource/fonts/ClearSans-Medium.ttf"

AddCSLuaFile "controls/dmediaplayerhtml.lua"
AddCSLuaFile "controls/dhtmlcontrols.lua"
AddCSLuaFile "controls/dmediaplayerrequest.lua"
AddCSLuaFile "cl_init.lua"
AddCSLuaFile "cl_idlescreen.lua"
AddCSLuaFile "shared.lua"
AddCSLuaFile "sh_events.lua"
AddCSLuaFile "sh_mediaplayer.lua"
AddCSLuaFile "sh_services.lua"
AddCSLuaFile "sh_history.lua"
AddCSLuaFile "sh_metadata.lua"

include "shared.lua"

-- TODO: move this into its own file
MediaPlayer.net = MediaPlayer.net or {}

function MediaPlayer.net.ReadMediaPlayer()

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)

	if not IsValid(mp) then
		if MediaPlayer.DEBUG then
			print("MEDIAPLAYER.Request: Invalid media player ID", mpId, mp)
		end
		return false
	end

	return mp

end

--[[---------------------------------------------------------
	Request
-----------------------------------------------------------]]

util.AddNetworkString( "MEDIAPLAYER.RequestListen" )
util.AddNetworkString( "MEDIAPLAYER.RequestUpdate" )
util.AddNetworkString( "MEDIAPLAYER.RequestMedia" )
util.AddNetworkString( "MEDIAPLAYER.RequestPause" )
util.AddNetworkString( "MEDIAPLAYER.RequestSkip" )
util.AddNetworkString( "MEDIAPLAYER.RequestSeek" )
util.AddNetworkString( "MEDIAPLAYER.RequestRemove" )

local ListenDelay = 0.5 -- seconds

local function OnListenRequest( len, ply )

	if not IsValid(ply) then return end

	if ply._NextListen and ply._NextListen > CurTime() then
		return
	end

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)
	if not IsValid(mp) then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestListen:", mpId, ply)
	end

	-- TODO: check if listener can actually be a listener
	if mp:HasListener(ply) then
		mp:RemoveListener(ply)
	else
		mp:AddListener(ply)
	end

	ply._NextListen = CurTime() + ListenDelay

end
net.Receive( "MEDIAPLAYER.RequestListen", OnListenRequest )

---
-- Event called when a player requests a media update. This will occur when
-- a client determines it's not synced correctly.
--
-- @param len Net message length.
-- @param ply Player who sent the net message.
--
local function OnUpdateRequest( len, ply )

	if not IsValid(ply) then return end

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)
	if not IsValid(mp) then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestUpdate:", mpId, ply)
	end

	mp:SendMedia( mp:GetMedia(), ply )

end
net.Receive( "MEDIAPLAYER.RequestUpdate", OnUpdateRequest )

local function OnMediaRequest( len, ply )

	if not IsValid(ply) then return end

	-- TODO: impose request delay for player

	local mp = MediaPlayer.net.ReadMediaPlayer()
	if not mp then return end

	local url = net.ReadString()

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestMedia:", url, mp:GetId(), ply)
	end

	-- Validate the URL
	if not MediaPlayer.ValidUrl( url ) then
		ply:ChatPrint( "The requested URL wasn't valid." )
		return
	end

	-- Build the media object for the URL
	local media = MediaPlayer.GetMediaForUrl( url )
	media:NetReadRequest()

	mp:RequestMedia( media, ply )

end
net.Receive( "MEDIAPLAYER.RequestMedia", OnMediaRequest )

local function OnPauseMedia( len, ply )

	if not IsValid(ply) then return end

	local mp = MediaPlayer.net.ReadMediaPlayer()
	if not mp then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestPause:", mp:GetId(), ply)
	end

	mp:RequestPause( ply )

end
net.Receive( "MEDIAPLAYER.RequestPause", OnPauseMedia )

local function OnSkipMedia( len, ply )

	if not IsValid(ply) then return end

	local mp = MediaPlayer.net.ReadMediaPlayer()
	if not mp then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestSkip:", mp:GetId(), ply)
	end

	mp:RequestSkip( ply )

end
net.Receive( "MEDIAPLAYER.RequestSkip", OnSkipMedia )


local function OnSeekMedia( len, ply )

	if not IsValid(ply) then return end

	local mp = MediaPlayer.net.ReadMediaPlayer()
	if not mp then return end

	local seekTime = net.ReadInt(32)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestSeek:", mp:GetId(), seekTime, ply)
	end

	mp:RequestSeek( ply, seekTime )

end
net.Receive( "MEDIAPLAYER.RequestSeek", OnSeekMedia )


local function OnRemoveMedia( len, ply )

	if not IsValid(ply) then return end

	local mp = MediaPlayer.net.ReadMediaPlayer()
	if not mp then return end

	local mediaUID = net.ReadString()

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestRemove:", mp:GetId(), mediaUID, ply)
	end

	mp:RequestRemove( ply, mediaUID )

end
net.Receive( "MEDIAPLAYER.RequestRemove", OnRemoveMedia )
