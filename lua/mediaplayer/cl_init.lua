if MediaPlayer then
	-- TODO: compare versions?
	if MediaPlayer.__refresh then
		MediaPlayer.__refresh = nil
	else
		return -- MediaPlayer has already been registered
	end
end

include "controls/dmediaplayerhtml.lua"
include "controls/dhtmlcontrols.lua"
include "controls/dmediaplayerrequest.lua"
include "shared.lua"
include "cl_idlescreen.lua"

-- menu
include "menu/sidebar.lua"

function MediaPlayer.Volume( volume )

	local cur = MediaPlayer.Cvars.Volume:GetFloat()

	if volume then

		-- Normalize volume
		volume = volume > 1 and volume/100 or volume

		-- Set volume convar
		RunConsoleCommand( "mediaplayer_volume", volume )

		-- Apply volume to all media players
		for _, mp in pairs(MediaPlayer.GetAll()) do
			if mp:IsPlaying() then
				local media = mp:CurrentMedia()
				media:Volume( volume )
			end
		end

		hook.Run( MP.EVENTS.VOLUME_CHANGED, volume, cur )

		cur = volume

	end

	return cur

end

function MediaPlayer.Resolution( resolution )

	if resolution then
		resolution = math.Clamp( resolution, 16, 4096 )
		RunConsoleCommand( "mediaplayer_resolution", resolution )
	end

	return MediaPlayer.Cvars.Resolution:GetFloat()

end

-- TODO: Change to using a subscribe model rather than polling
function MediaPlayer.Poll( id )

	net.Start( "MEDIAPLAYER.Update" )
		net.WriteString( id )
	net.SendToServer()

end

local function GetMediaPlayerId( obj )
	local mpId

	-- Determine mp parameter type and get the associated ID.
	if isentity(obj) and obj.IsMediaPlayerEntity then
		mpId = obj:GetMediaPlayerID()
	-- elseif isentity(obj) and IsValid( obj:GetMediaPlayer() ) then
	-- 	local mp = mp:GetMediaPlayer()
	-- 	mpId = mp:GetId()
	elseif istable(obj) and obj.IsMediaPlayer then
		mpId = obj:GetId()
	elseif isstring(obj) then
		mpId = obj
	else
		return false -- Invalid parameters
	end

	return mpId
end

---
-- Request to begin listening to a media player.
--
-- @param Entity|Table|String	Media player reference.
--
function MediaPlayer.RequestListen( obj )

	local mpId = GetMediaPlayerId(obj)
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestListen" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Request mediaplayer update.
--
-- @param Entity|Table|String	Media player reference.
--
function MediaPlayer.RequestUpdate( obj )

	local mpId = GetMediaPlayerId(obj)
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestUpdate" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Request a URL to be played on the given media player.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Requested media URL.
--
function MediaPlayer.Request( obj, url )

	local mpId = GetMediaPlayerId( obj )
	if not mpId then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.Request:", url, mpId)
	end

	-- Verify valid URL as to not waste time networking
	if not MediaPlayer.ValidUrl( url ) then
		LocalPlayer():ChatPrint("The requested URL was invalid.")
		return false
	end

	local media = MediaPlayer.GetMediaForUrl( url )

	local function request( err )
		if err then
			-- TODO: don't use chatprint to notify the user
			LocalPlayer():ChatPrint( "Request failed: " .. err )
			return
		end

		net.Start( "MEDIAPLAYER.RequestMedia" )
			net.WriteString( mpId )
			net.WriteString( url )
			media:NetWriteRequest() -- send any additional data
		net.SendToServer()

		if MediaPlayer.DEBUG then
			print("MEDIAPLAYER.Request sent to server")
		end
	end

	-- Prepare any data prior to requesting if necessary
	if media.PrefetchMetadata then
		media:PreRequest(request) -- async
	else
		request() -- sync
	end

end

function MediaPlayer.Pause( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestPause" )
		net.WriteString( mpId )
	net.SendToServer()

end

function MediaPlayer.Skip( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestSkip" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Seek to a specific time in the current media.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Seek time; HH:MM:SS
--
function MediaPlayer.Seek( mp, time )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestSeek" )
		net.WriteString( mpId )
		net.WriteString( time )
	net.SendToServer()

end

---
-- Remove the given media.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Media unique ID.
--
function MediaPlayer.RequestRemove( mp, mediaUID )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestRemove" )
		net.WriteString( mpId )
		net.WriteString( mediaUID )
	net.SendToServer()

end


--[[---------------------------------------------------------
	Utility functions
-----------------------------------------------------------]]

local FullscreenCvar = MediaPlayer.Cvars.Fullscreen

function MediaPlayer.SetBrowserSize( browser, w, h )

	local fullscreen = FullscreenCvar:GetBool()

	if fullscreen then
		w, h = ScrW(), ScrH()
	end

	browser:SetSize( w, h, fullscreen )

end

function MediaPlayer.OpenRequestMenu( mp )

	if ValidPanel(MediaPlayer._RequestMenu) then
		return
	end

	local req = vgui.Create( "MPRequestFrame" )
	req:SetMediaPlayer( mp )
	req:MakePopup()
	req:Center()

	req.OnClose = function()
		MediaPlayer._RequestMenu = nil
	end

	MediaPlayer._RequestMenu = req

end

function MediaPlayer.MenuRequest( url )

	local menu = MediaPlayer._RequestMenu

	if not ValidPanel(menu) then
		return
	end

	local mp = menu:GetMediaPlayer()

	menu:Close()

	MediaPlayer.Request( mp, url )

end


--[[---------------------------------------------------------
	Fonts
-----------------------------------------------------------]]

local common = {
	-- font		= "Open Sans Condensed",
	-- font		= "Oswald",
	font		= "Clear Sans Medium",
	antialias	= true,
	weight		= 400
}

surface.CreateFont( "MediaTitle", table.Merge(common, { size = 72 }) )
surface.CreateFont( "MediaRequestButton", table.Merge(common, { size = 26 }) )
