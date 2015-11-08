local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.TabHeight = 43

function PANEL:Init()

	self:SetShowIcons( false )

	self:SetFadeTime( 0 )
	self:SetPadding( 0 )

	self.animFade = Derma_Anim( "Fade", self, self.CrossFade )

	self.Items = {}

end

function PANEL:Paint( w, h )

end

function PANEL:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )

	if not IsValid( panel ) then return end

	local Sheet = {}

	Sheet.Name = label

	Sheet.Tab = vgui.Create( "MP.SidebarTab", self )
	Sheet.Tab:SetTooltip( Tooltip )
	Sheet.Tab:Setup( label, self, panel, material )

	Sheet.Panel = panel
	Sheet.Panel.NoStretchX = NoStretchX
	Sheet.Panel.NoStretchY = NoStretchY
	Sheet.Panel:SetPos( self:GetPadding(), self.TabHeight + self:GetPadding() )
	Sheet.Panel:SetVisible( false )

	panel:SetParent( self )

	table.insert( self.Items, Sheet )

	if not self:GetActiveTab() then
		self:SetActiveTab( Sheet.Tab )
		Sheet.Panel:SetVisible( true )
	end

	-- self.tabScroller:AddPanel( Sheet.Tab )

	return Sheet

end

function PANEL:PerformLayout()

	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()

	if not ActiveTab then return end

	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout( true )

	local ActivePanel = ActiveTab:GetPanel()

	local numItems = #self.Items
	local tabWidth = ceil(self:GetWide() / numItems)

	local tab

	for k, v in pairs( self.Items ) do

		tab = v.Tab

		tab:SetSize( tabWidth, self.TabHeight )
		tab:SetPos( (k-1) * tabWidth )

		-- Handle tab panel visibility
		if tab:GetPanel() == ActivePanel then
			tab:GetPanel():SetVisible( true )
			tab:SetZPos( 100 )
		else
			tab:GetPanel():SetVisible( false )
			tab:SetZPos( 1 )
		end

		tab:ApplySchemeSettings()

	end

	ActivePanel:SetWide( self:GetWide() - Padding * 2 )
	ActivePanel:SetTall( (self:GetTall() - ActiveTab:GetTall() ) - Padding )

	ActivePanel:InvalidateLayout()

	-- Give the animation a chance
	self.animFade:Run()

end

derma.DefineControl( "MP.SidebarTabs", "", PANEL, "DPropertySheet" )


local SIDEBAR_TAB = {}

surface.CreateFont( "MP.TabTitle", {
	font = "Roboto Regular",
	size = 16,
	weight = 400
} )

SIDEBAR_TAB.BgColor = Color( 28, 100, 157 )
SIDEBAR_TAB.SelectedBorderColor = color_white
SIDEBAR_TAB.SelectedBorderHeight = 2

function SIDEBAR_TAB:Init()

	self.BaseClass.Init( self )

	self:SetFont( "MP.TabTitle" )
	self:SetContentAlignment( 5 )
	self:SetTextInset( 0, 0 )

end

function SIDEBAR_TAB:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

	if self:IsActive() then
		surface.SetDrawColor( self.SelectedBorderColor )
		surface.DrawRect( 0, h - self.SelectedBorderHeight, w, self.SelectedBorderHeight )
	end

end

function SIDEBAR_TAB:ApplySchemeSettings()

	self:SetTextInset( 0, 0 )

	-- TODO: this errors as of version 2015.03.09
	-- DLabel.ApplySchemeSettings( self )

end

derma.DefineControl( "MP.SidebarTab", "", SIDEBAR_TAB, "DTab" )



local CURRENTLY_PLAYING_TAB = {}

AccessorFunc( CURRENTLY_PLAYING_TAB, "MediaPlayerId", "MediaPlayerId" )

CURRENTLY_PLAYING_TAB.BgColor = Color( 7, 21, 33 )

function CURRENTLY_PLAYING_TAB:Init()

	self.QueuePanel = vgui.Create( "MP.Queue", self )
	self.QueuePanel:Dock( FILL )
	self.QueuePanel:DockMargin( 0, -4, 0, 0 ) -- fix offset due to seekbar

	self.PlaybackPanel = vgui.Create( "MP.Playback", self )
	self.PlaybackPanel:Dock( TOP )

	hook.Add( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, self, self.OnMediaPlayerChanged )

end

function CURRENTLY_PLAYING_TAB:OnMediaPlayerChanged( mp )

	self:SetMediaPlayerId( mp:GetId() )

	self.QueuePanel.Header.AddVidBtn:SetLocked( mp:GetQueueLocked() )

	if not self.MediaChangedHandle then
		-- set current media
		self.PlaybackPanel:OnMediaChanged( mp:GetMedia() )

		-- listen for any future media changes
		self.MediaChangedHandle = function(...)
			if ValidPanel(self.PlaybackPanel) then
				self.PlaybackPanel:OnMediaChanged(...)
			end
		end
		mp:on( MP.EVENTS.MEDIA_CHANGED, self.MediaChangedHandle )
	end

	if not self.QueueChangedHandle then
		-- set current queue
		self.QueuePanel:OnQueueChanged( mp:GetMediaQueue() )

		-- listen for any future media changes
		self.QueueChangedHandle = function(...)
			if ValidPanel(self.QueuePanel) then
				self.QueuePanel:OnQueueChanged(...)
			end
		end
		mp:on( MP.EVENTS.QUEUE_CHANGED, self.QueueChangedHandle )
	end

	if not self.PlayerStateChangeHandle then
		-- set current player state
		self.PlaybackPanel:OnPlayerStateChanged( mp:GetPlayerState() )

		-- listen for any future player state changes
		self.PlayerStateChangeHandle = function(...)
			if ValidPanel(self.PlaybackPanel) then
				self.PlaybackPanel:OnPlayerStateChanged(...)
			end
		end
		mp:on( MP.EVENTS.PLAYER_STATE_CHANGED, self.PlayerStateChangeHandle )
	end

end

function CURRENTLY_PLAYING_TAB:OnRemove()

	hook.Remove( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, self )

	local mpId = self:GetMediaPlayerId()
	local mp = MediaPlayer.GetById( mpId )

	if mp then
		mp:removeListener( MP.EVENTS.MEDIA_CHANGED, self.MediaChangedHandle )
		mp:removeListener( MP.EVENTS.QUEUE_CHANGED, self.QueueChangedHandle )
		mp:removeListener( MP.EVENTS.PLAYER_STATE_CHANGED, self.PlayerStateChangeHandle )
	end

end

function CURRENTLY_PLAYING_TAB:Paint( w, h )
	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )
end

derma.DefineControl( "MP.CurrentlyPlayingTab", "", CURRENTLY_PLAYING_TAB, "Panel" )
