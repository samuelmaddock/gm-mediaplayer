include "icons.lua"
include "common.lua"
include "sidebar_tabs.lua"
include "volume_control.lua"
include "playback.lua"
include "queue.lua"
include "horizontal_list.lua"


--[[--------------------------------------------
	Sidebar root panel
----------------------------------------------]]

local PANEL = {}

function PANEL:Init()

	self:SetName( "MediaPlayerSidebar" )

	self:SetPaintBackgroundEnabled( true )
	self:SetPaintBorderEnabled( false )

	self:SetZPos( -99 )
	self:SetSize( 385, 580 )

	self.Tabs = vgui.Create( "MP.SidebarTabs", self )
	self.Tabs:Dock( FILL )

	local curplaytab = vgui.Create( "MP.CurrentlyPlayingTab" )
	self.Tabs:AddSheet( "CURRENTLY PLAYING", curplaytab, nil, false, false )

	-- TODO: Implement clientside media history for recently viewed tab
	-- local panel = vgui.Create( "Panel" )
	-- self.Tabs:AddSheet( "RECENTLY VIEWED", panel, nil, false, false )

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


--[[--------------------------------------------
	Sidebar presenter
----------------------------------------------]]

local SidebarPresenter = {
	hooks = {}
}

AccessorFunc( SidebarPresenter, "m_Media", "Media" )

function SidebarPresenter:RegisterHook( hookname, callback )

	table.insert( self.hooks, hookname )

	hook.Add( hookname, "MP.SidebarPresenter", function(...)
		if MediaPlayer.DEBUG then
			print("MP.EVENTS.UI", hookname)
			PrintTable({...})
		end

		return callback(...)
	end )

end

function SidebarPresenter:SetupEvents()

	local mp = self:GetMedia()

	self:RegisterHook( MP.EVENTS.UI.OPEN_REQUEST_MENU, function()
		self:HideSidebar()
		MediaPlayer.OpenRequestMenu( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.FAVORITE_MEDIA, function( media )
		-- TODO
	end )

	self:RegisterHook( MP.EVENTS.UI.REMOVE_MEDIA, function( media )
		if not media then return end
		MediaPlayer.RequestRemove( mp, media:UniqueID() )
	end )

	self:RegisterHook( MP.EVENTS.UI.SKIP_MEDIA, function()
		MediaPlayer.Skip( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.TOGGLE_LOCK, function()
		MediaPlayer.RequestLock( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.TOGGLE_PAUSE, function()
		MediaPlayer.Pause( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.TOGGLE_REPEAT, function()
		MediaPlayer.RequestRepeat( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.TOGGLE_SHUFFLE, function()
		MediaPlayer.RequestShuffle( mp )
	end )

	self:RegisterHook( MP.EVENTS.UI.SEEK, function( seekTime )
		MediaPlayer.Seek( mp, seekTime )
	end )

	self:RegisterHook( MP.EVENTS.UI.PRIVILEGED_PLAYER, function()
		local ply = LocalPlayer()
		return mp:IsPlayerPrivileged(ply)
	end )

end

function SidebarPresenter:ClearEvents()

	for _, hookname in ipairs(self.hooks) do
		hook.Remove( hookname, "MP.SidebarPresenter" )
	end

end

function SidebarPresenter:ShowSidebar( mp )

	self:SetMedia( mp )

	if ValidPanel(self.Sidebar) then
		self:HideSidebar()
	end

	self:SetupEvents()

	-- Can be used to extend sidebar functionality
	hook.Run( MP.EVENTS.UI.SETUP_SIDEBAR, self, mp )

	local sidebar = vgui.CreateFromTable( MP_SIDEBAR )
	sidebar:MakePopup()

	-- sidebar:SetKeyboardInputEnabled( false )
	sidebar:SetMouseInputEnabled( true )

	hook.Run( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, mp )

	self.Sidebar = sidebar

end

function SidebarPresenter:HideSidebar()

	if not self.Sidebar then return end

	self:ClearEvents()

	if ValidPanel(self.Sidebar) then
		self.Sidebar:Remove()
	end

	self.Sidebar = nil

end


--[[--------------------------------------------
	MediaPlayer library sidebar helpers
----------------------------------------------]]

function MediaPlayer.ShowSidebar( mp )

	--
	-- Find a valid media player to use for the sidebar
	--

	-- First check if we're looking at a media player
	if not mp then
		local ent = LocalPlayer():GetEyeTrace().Entity
		if IsValid(ent) then
			mp = MediaPlayer.GetByObject( ent )
		end
	end

	-- Else, maybe the gamemode handles this some other way (location system, etc.)
	if not mp then
		mp = hook.Run( "GetMediaPlayer" )
	end

	-- If we still can't find a media player, give up..
	if not IsValid(mp) then return end

	SidebarPresenter:ShowSidebar( mp )

end

function MediaPlayer.HideSidebar()

	SidebarPresenter:HideSidebar()

end

hook.Add( "OnContextMenuOpen", "MP.ShowSidebar", function()
	MediaPlayer.ShowSidebar()
end )
hook.Add( "OnContextMenuClose", "MP.HideSidebar", function()
	MediaPlayer.HideSidebar()
end )

--[[--------------------------------------------
	Sidebar UI test - remove this eventually
----------------------------------------------]]

--[[inputhook.AddKeyPress( KEY_PAGEUP, "MP.ShowSidebarTest", function()
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
end )]]
