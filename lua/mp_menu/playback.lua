local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.Height = 72

PANEL.BgColor = Color( 13, 41, 62 )
PANEL.Padding = 12
PANEL.BtnSpacing = 4

-- PANEL.TrackbarProgressColor = Color( 28, 100, 157 )
PANEL.SeekbarHeight = 8

PANEL.TitleMaxWidth = 335

PANEL.KnobSize = 8

function PANEL:Init()

	self.PlayPauseBtn = vgui.Create( "MP.PlayPauseButton", self )

	self.MediaTitle = vgui.Create( "MP.MediaTitle", self )
	self.MediaTitle:SetText( "Very Bad Video That Everyone Hates Included" )

	self.MediaTime = vgui.Create( "MP.MediaTime", self )
	self.MediaTime:SetShowCurrentTime( true )
	self.MediaTime:SetListenForSeekEvents( true )

	self.BtnList = vgui.Create( "DHorizontalList", self )
	self.BtnList:SetSpacing( self.BtnSpacing )

	self.FavBtn = vgui.Create( "MP.FavoriteButton", self )

	hook.Run( MP.EVENTS.UI.SETUP_PLAYBACK_PANEL, self )

	if hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then
		self.SkipBtn = vgui.Create( "MP.SkipButton" )
		self:AddButton( self.SkipBtn )
	end

	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

	self.Seekbar = vgui.Create( "MP.Seekbar", self )

	self.NextThink = 0

end

function PANEL:AddButton( panel )
	self.BtnList:AddItem( panel )
end

function PANEL:Think()

	local rt = RealTime()

	if rt > self.NextThink then
		-- Perform layout every second for when the media label changes width
		self:InvalidateLayout()
		self.NextThink = rt + 1
	end

end

function PANEL:OnMediaChanged( media )

	self._Media = media

	if media then
		local title = media:Title()
		self.MediaTitle:SetText( title )
		self.MediaTitle:SetToolTip( title )

		self.AddedByLbl:SetPlayer( media:GetOwner(), media:OwnerName(), media:OwnerSteamID() )

		self.AddedByLbl:Show()
		self.FavBtn:Hide()
		self.BtnList:Show()
	else
		self.MediaTitle:SetText( "No media playing" )
		self.MediaTitle:SetTooltip( "" )

		self.AddedByLbl:Hide()
		self.FavBtn:Hide()
		self.BtnList:Hide()
	end

	if media and media:IsTimed() then
		self.MediaTime:SetMedia( media )

		self.Seekbar:SetMedia( media )
		self.Seekbar:Show()
	else
		self.MediaTime:SetMedia( nil )
		self.MediaTime:Hide()

		self.Seekbar:SetMedia( nil )
		self.Seekbar:Hide()
	end

	-- apply media for all buttons
	for _, btn in pairs( self.BtnList:GetItems() ) do
		if ValidPanel(btn) and isfunction(btn.SetMedia) then
			btn:SetMedia( media )
		end
	end

	self:InvalidateLayout()

end

function PANEL:OnPlayerStateChanged( playerState )

	self.PlayPauseBtn:SetPlayerState( playerState )

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h - self.SeekbarHeight / 2 )

end

function PANEL:PerformLayout()

	local w, h = self:GetSize()

	self:SetTall( self.Height )

	self.PlayPauseBtn:CenterVertical()
	self.PlayPauseBtn:AlignLeft( self.Padding )

	self.MediaTitle:SizeToContents()
	self.MediaTitle:MoveRightOf( self.PlayPauseBtn, self.Padding )

	if self._Media then
		self.MediaTitle:AlignTop( self.Padding )
	else
		self.MediaTitle:CenterVertical()
	end

	self.MediaTime:InvalidateLayout()
	self.MediaTime:MoveRightOf( self.PlayPauseBtn, self.Padding )
	self.MediaTime:AlignBottom( self.Padding - 2 )

	self.FavBtn:AlignTop( self.Padding )
	self.FavBtn:AlignRight( self.Padding )

	self.BtnList:InvalidateLayout(true)
	self.BtnList:AlignBottom( self.Padding )
	self.BtnList:AlignRight( self.Padding )

	-- 'ADDED BY Name' needs to fit between the media time and the rightmost
	-- buttons.
	local addedByMaxWidth = ( self.BtnList:GetPos() - self.BtnSpacing ) -
		( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.Padding )

	self.AddedByLbl:SetMaxWidth( addedByMaxWidth )
	self.AddedByLbl:AlignBottom( self.Padding )
	self.AddedByLbl:MoveLeftOf( self.BtnList, self.BtnSpacing )

	local maxTitleWidth = ( self.FavBtn:GetPos() - self.BtnSpacing ) -
		( self.MediaTitle:GetPos() )

	if self.MediaTitle:GetWide() > maxTitleWidth then
		self.MediaTitle:SetWide( maxTitleWidth )
	end

	self.Seekbar:SetSize( w, self.SeekbarHeight )
	self.Seekbar:SetPos( 0, h - self.SeekbarHeight )

	self:SetTall( self.Height + self.SeekbarHeight / 2 )

end

derma.DefineControl( "MP.Playback", "", PANEL, "Panel" )


local PLAYPAUSE_BTN = {
	StateIcons = {
		[1] = nil, -- MP_STATE_ENDED
		[2] = "mp-pause", -- MP_STATE_PLAYING
		[3] = "mp-play" -- MP_STATE_PAUSED
	}
}

function PLAYPAUSE_BTN:Init()
	self.BaseClass.Init( self )

	self:SetSize( 22, 25 )
	self:SetHighlighted( true )
end

function PLAYPAUSE_BTN:SetPlayerState( playerState )

	self.PlayerState = playerState

	playerState = (playerState or 0) + 1 -- Lua can't index 0

	local icon = self.StateIcons[ playerState ]

	if icon then
		self:SetIcon( icon )
		self:SetIconVisible(true)
	else
		self:SetIconVisible(false)
	end

	-- Set cursor type depending on whether player is admin/owner
	if hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then
		self:SetCursor( "hand" )
	else
		self:SetCursor( "arrow" )
	end

end

function PLAYPAUSE_BTN:DoClick()

	hook.Run( MP.EVENTS.UI.TOGGLE_PAUSE )

end

derma.DefineControl( "MP.PlayPauseButton", "", PLAYPAUSE_BTN, "MP.SidebarButton" )


local SEEKBAR = {}

SEEKBAR.KnobSize = 8
SEEKBAR.BarHeight = 2

SEEKBAR.ProgressColor = Color( 28, 100, 157 )

AccessorFunc( SEEKBAR, "m_Media", "Media" )

function SEEKBAR:Init()

	self.BaseClass.Init( self )

	self.Knob:SetSize( self.KnobSize, self.KnobSize )
	self.Knob.Paint = self.PaintKnob

	self.Knob.OnMousePressed = function( panel, mousecode )
			self:OnStartEditing( self )
			DButton.OnMousePressed( panel, mousecode )
		end
	self.Knob.OnMouseReleased = function( panel, mousecode )
			self:OnStopEditing( self )
			DButton.OnMouseReleased( panel, mousecode )
		end

	-- Remove some hidden panel child from the inherited DSlider control; I have
	-- no idea where it's being created...
	for _, child in pairs( self:GetChildren() ) do
		if child ~= self.Knob then
			child:Remove()
		end
	end

end

function SEEKBAR:OnStartEditing()

	-- only allow admins/owners to control seeking
	if not hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then return end

	hook.Run( MP.EVENTS.UI.START_SEEKING, self )

end

function SEEKBAR:OnStopEditing()

	-- only allow admins/owners to control seeking
	if not hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then return end

	hook.Run( MP.EVENTS.UI.STOP_SEEKING, self )

	if self.m_Media then
		local seekTime = ceil(self.m_fSlideX * self.m_Media:Duration())
		hook.Run( MP.EVENTS.UI.SEEK, seekTime )
	end

end

function SEEKBAR:OnMousePressed( mcode )
	self:OnStartEditing()
	self.BaseClass.OnMousePressed( self, mcode )
end

function SEEKBAR:OnMouseReleased( mcode )
	self:OnStopEditing()
	self.BaseClass.OnMouseReleased( self, mcode )
end

function SEEKBAR:Think()

	local media = self.m_Media

	if media and not self:IsEditing() then
		local progress = media:CurrentTime() / media:Duration()
		progress = clamp(progress, 0, 1)

		self:SetSlideX( progress )
		self:InvalidateLayout()
	end

end

function SEEKBAR:Paint( w, h )

	local midy = ceil( h / 2 )
	local bary = ceil(midy - (self.BarHeight / 2))

	local progress = self:GetSlideX()

	surface.SetDrawColor( self.ProgressColor )
	surface.DrawRect( 0, bary, ceil(w * progress), self.BarHeight )

end

function SEEKBAR:PaintKnob( w, h )

	draw.RoundedBoxEx( ceil(w/2), 0, 0, w, h, color_white, true, true, true, true )

end

derma.DefineControl( "MP.Seekbar", "", SEEKBAR, "DSlider" )
