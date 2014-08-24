include "common.lua"
include "sidebar_tabs.lua"
include "volume_control.lua"
include "playback.lua"
include "queue.lua"

local PANEL = {}

function PANEL:Init()

	self:SetPaintBackgroundEnabled( true )
	self:SetPaintBorderEnabled( false )

	self:SetSize( 385, 580 )

	self.Tabs = vgui.Create( "MP.SidebarTabs", self )
	self.Tabs:Dock( FILL )

	local curplaytab = vgui.Create( "MP.CurrentlyPlayingTab" )
	self.Tabs:AddSheet( "CURRENTLY PLAYING", curplaytab, nil, false, false )

	local panel = vgui.Create( "Panel" )
	self.Tabs:AddSheet( "RECENTLY VIEWED", panel, nil, false, false )

	self.VolumeControls = vgui.Create( "MP.VolumeControl", self )
	self.VolumeControls:Dock( BOTTOM )
	self.VolumeControls:SetHeight( 48 )

	self:InvalidateLayout( true )

end

function PANEL:Paint(w, h)

	surface.SetDrawColor( 0, 0, 0, 140 )
	surface.DrawRect( 0, 0, w, h )

end

function PANEL:PerformLayout()

	self:CenterVertical()
	self:AlignLeft( 10 )

	self.Tabs:SizeToContentWidth()

end

local MP_SIDEBAR = vgui.RegisterTable( PANEL, "EditablePanel" )


local sidebarHooks

local function registerSidebarHook( hookname, callback, mp )

	table.insert( sidebarHooks, hookname )

	hook.Add( hookname, "MP.Sidebar", function(...)
		if MediaPlayer.DEBUG then
			print("MP.EVENTS.UI", hookname)
			PrintTable({...})
		end

		return callback(...)
	end )

end

local function setupSidebarHooks( mp )

	-- Register sidebar hooks
	sidebarHooks = {}

	registerSidebarHook( MP.EVENTS.UI.OPEN_REQUEST_MENU, function()
		MediaPlayer.HideSidebar()
		MediaPlayer.OpenRequestMenu( mp )
	end )

	registerSidebarHook( MP.EVENTS.UI.FAVORITE_MEDIA, function( media )
		-- TODO
	end )

	registerSidebarHook( MP.EVENTS.UI.VOTESKIP_MEDIA, function( media )
		-- TODO
	end )

	registerSidebarHook( MP.EVENTS.UI.REMOVE_MEDIA, function( media )
		print("TEST", media)
		if not media then return end
		MediaPlayer.RequestRemove( mp, media:UniqueID() )
	end )

	registerSidebarHook( MP.EVENTS.UI.TOGGLE_PAUSE, function()
		MediaPlayer.Pause( mp )
	end )

	registerSidebarHook( MP.EVENTS.UI.SEEK, function( seekTime )
		MediaPlayer.Seek( mp, seekTime )
	end )

	registerSidebarHook( MP.EVENTS.UI.PRIVILEGED_PLAYER, function()
		local ply = LocalPlayer()
		return mp:IsPlayerPrivileged(ply)
	end )

end

function MediaPlayer.ShowSidebar( mp )

	local sidebar = MediaPlayer._Sidebar

	if ValidPanel( sidebar ) then
		sidebar:Remove()
	end

	--
	-- Find a valid media player to use for the sidebar
	--

	-- First check if we're looking at a media player
	if not mp then
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) then return end

		mp = MediaPlayer.GetByObject( ent )
	end

	-- Else, maybe the gamemode handles this some other way (location system, etc.)
	if not mp then
		mp = hook.Run( "GetMediaPlayer" )
	end

	-- If we still can't find a media player, give up..
	if not IsValid(mp) then return end

	setupSidebarHooks(mp)

	sidebar = vgui.CreateFromTable( MP_SIDEBAR )
	sidebar:MakePopup()
	sidebar:ParentToHUD()

	sidebar:SetKeyboardInputEnabled( false )
	sidebar:SetMouseInputEnabled( true )

	hook.Run( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, mp )

	MediaPlayer._Sidebar = sidebar

end

function MediaPlayer.HideSidebar()

	local sidebar = MediaPlayer._Sidebar

	if ValidPanel( sidebar ) then
		for _, hookname in ipairs(sidebarHooks) do
			hook.Remove( hookname, "MP.Sidebar" )
		end

		sidebarHooks = nil

		sidebar:Remove()
		MediaPlayer._Sidebar = nil
	end

end

control.AddKeyPress( KEY_C, "MP.ShowSidebar", function() MediaPlayer.ShowSidebar() end )
control.AddKeyRelease( KEY_C, "MP.HideSidebar", function() MediaPlayer.HideSidebar() end )

control.AddKeyPress( KEY_SLASH, "MP.ShowSidebarTest", function()
	-- Create test fixture
	local mp = MediaPlayer.Create( 'ui-test-player' )
	mp:SetPlayerState( MP_STATE_PLAYING )

	local function CreateMedia( title, duration, url, ownerName, ownerSteamID, startTime )
		local media = MediaPlayer.GetMediaForUrl( url )

		media._metadata = {
			title = title,
			duration = duration
		}

		media._OwnerName = ownerName
		media._OwnerSteamID = ownerSteamID
		media:StartTime( startTime or RealTime() )

		return media
	end

	---------------------------------
	-- Create current media object
	---------------------------------

	mp:SetMedia( CreateMedia(
		"Test media - really long title test asdfljkasdfasdjfgasdf",
		10,
		"https://www.youtube.com/watch?v=IMorTE0lFLc",
		"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		"STEAM_0:1:15862026"
	) )


	---------------------------------
	-- Create queued media
	---------------------------------

	mp:AddMedia( CreateMedia(
		"Test media - really long title test asdfljkasdfasdjfgasdf",
		86400,
		"https://www.youtube.com/watch?v=IMorTE0lFLc",
		"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		"STEAM_0:1:15862026"
	) )

	mp:AddMedia( CreateMedia(
		"Hello world",
		1800,
		"https://www.youtube.com/watch?v=IMorTE0lFLc",
		"Sam",
		"STEAM_0:1:15862026"
	) )

	mp:AddMedia( CreateMedia(
		"ASDSDFawcasiudcg awlieufgawlie",
		180,
		"https://www.youtube.com/watch?v=IMorTE0lFLc",
		"(╯°□°）╯︵ ┻━┻",
		"STEAM_0:1:15862026",
		RealTime() - 1800
	) )

	-- Display UI using fixture
	MediaPlayer.ShowSidebar( mp )
end )
