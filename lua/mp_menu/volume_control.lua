local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.Margin = 16
PANEL.ButtonWidth = 18
PANEL.ButtonSpacing = 8
PANEL.BackgroundColor = Color( 28, 100, 157 )

function PANEL:Init()

	self.BaseClass.Init( self )

	self.VolumeButton = vgui.Create( "MP.VolumeButton", self )

	self.VolumeSlider = vgui.Create( "MP.VolumeSlider", self )

	self.BtnList = vgui.Create( "DHorizontalList", self )
	self.BtnList:SetSpacing( self.ButtonSpacing )

	if hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then
		self.RepeatBtn = vgui.Create( "MP.RepeatButton" )
		self:AddButton( self.RepeatBtn )
		self.ShuffleBtn = vgui.Create( "MP.ShuffleButton" )
		self:AddButton( self.ShuffleBtn )
		self.LockBtn = vgui.Create( "MP.LockButton" )
		self:AddButton( self.LockBtn )
	end

	self:OnVolumeChanged( MediaPlayer.Volume() )

	hook.Add( MP.EVENTS.VOLUME_CHANGED, self, self.OnVolumeChanged )
	hook.Add( MP.EVENTS.UI.MEDIA_PLAYER_CHANGED, self, self.OnMediaPlayerChanged )

end

function PANEL:AddButton( panel )
	self.BtnList:AddItem( panel )
end

function PANEL:OnVolumeChanged( volume )

	self.VolumeSlider:SetSlideX( volume )

	self:InvalidateChildren()

end

function PANEL:OnMediaPlayerChanged( mp )

	if hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then
		self.RepeatBtn:SetEnabled( mp:GetQueueRepeat() )
		self.ShuffleBtn:SetEnabled( mp:GetQueueShuffle() )
		self.LockBtn:SetEnabled( mp:GetQueueLocked() )
	end

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( self.BackgroundColor )
	surface.DrawRect( 0, 0, w, h )

end

function PANEL:PerformLayout( w, h )

	self.BtnList:InvalidateLayout( true )
	self.BtnList:CenterVertical()
	self.BtnList:AlignRight( self.Margin )

	self.VolumeButton:CenterVertical()
	self.VolumeButton:AlignLeft( self.Margin )

	local sliderWidth = ( self.BtnList:GetPos() - 15 ) -
			( self.VolumeButton:GetPos() + self.VolumeButton:GetWide() + 15 )
	self.VolumeSlider:SetWide( sliderWidth )
	self.VolumeSlider:CenterVertical()
	self.VolumeSlider:MoveRightOf( self.VolumeButton, 15 )

end

function PANEL:OnRemove()

	hook.Remove( MP.EVENTS.VOLUME_CHANGED, self )

end

derma.DefineControl( "MP.VolumeControl", "", PANEL, "DPanel" )


local VOLUME_BUTTON = {}

function VOLUME_BUTTON:Init()

	self.BaseClass.Init( self )

	self:SetIcon( 'mp-volume' )
	self:SetSize( 18, 17 )

end

function VOLUME_BUTTON:DoClick()

	MediaPlayer.ToggleMute()

end

derma.DefineControl( "MP.VolumeButton", "", VOLUME_BUTTON, "MP.SidebarButton" )


local VOLUME_SLIDER = {}

VOLUME_SLIDER.BarHeight = 3
VOLUME_SLIDER.KnobSize = 12

VOLUME_SLIDER.BarBgColor = Color( 13, 41, 62 )

VOLUME_SLIDER.ScrollIncrement = 0.1 -- out of 1

function VOLUME_SLIDER:Init()

	self.BaseClass.Init( self )

	self.Knob:SetSize( self.KnobSize, self.KnobSize )
	self.Knob.Paint = self.PaintKnob

	-- Remove some hidden panel child from the inherited DSlider control; I have
	-- no idea where it's being created...
	for _, child in pairs( self:GetChildren() ) do
		if child ~= self.Knob then
			child:Remove()
		end
	end

end

function VOLUME_SLIDER:Paint( w, h )

	local progress = self.m_fSlideX
	local vmid = ceil((h / 2) - (self.BarHeight / 2))

	surface.SetDrawColor( self.BarBgColor )
	surface.DrawRect( 0, vmid, w, self.BarHeight )

	surface.SetDrawColor( color_white )
	surface.DrawRect( 0, vmid, ceil(w * progress), self.BarHeight )

end

function VOLUME_SLIDER:PaintKnob( w, h )

	draw.RoundedBoxEx( ceil(w/2), 0, 0, w, h, color_white, true, true, true, true )

end

function VOLUME_SLIDER:SetSlideX( value )

	if self._lockVolume then return end

	value = clamp(value, 0, 1)

	self.m_fSlideX = value
	self:InvalidateLayout()

	self._lockVolume = true
	MediaPlayer.Volume( value )
	self._lockVolume = nil

end

function VOLUME_SLIDER:OnMouseWheeled( delta )

	local change = self.ScrollIncrement * delta
	local value = clamp(self.m_fSlideX + change, 0, 1)

	self:SetSlideX( value )

end

derma.DefineControl( "MP.VolumeSlider", "", VOLUME_SLIDER, "DSlider" )


local REPEAT_BTN = {}

function REPEAT_BTN:Init()
	self.BaseClass.Init( self )
	self:SetIcon( "mp-repeat" )
	self:SetTooltip( "Repeat" )
end

function REPEAT_BTN:DoClick()
	self.BaseClass.DoClick( self )
	hook.Run( MP.EVENTS.UI.TOGGLE_REPEAT )
end

derma.DefineControl( "MP.RepeatButton", "", REPEAT_BTN, "MP.SidebarToggleButton" )


local SHUFFLE_BTN = {}

function SHUFFLE_BTN:Init()
	self.BaseClass.Init( self )
	self:SetIcon( "mp-shuffle" )
	self:SetTooltip( "Shuffle" )
end

function SHUFFLE_BTN:DoClick()
	self.BaseClass.DoClick( self )
	hook.Run( MP.EVENTS.UI.TOGGLE_SHUFFLE )
end

derma.DefineControl( "MP.ShuffleButton", "", SHUFFLE_BTN, "MP.SidebarToggleButton" )


local LOCK_BTN = {}

function LOCK_BTN:Init()
	self.BaseClass.Init( self )
	self:SetIcon( "mp-lock-open" )
	self:SetTooltip( "Toggle Queue Lock" )
end

function LOCK_BTN:DoClick()
	self.BaseClass.DoClick( self )

	hook.Run( MP.EVENTS.UI.TOGGLE_LOCK )
	self:UpdateIcon()
end

function LOCK_BTN:SetEnabled( bEnabled )
	self.BaseClass.SetEnabled( self, bEnabled )
	self:UpdateIcon()
end

function LOCK_BTN:UpdateIcon()
	local icon = self:GetEnabled() and "mp-lock" or "mp-lock-open"
	self:SetIcon( icon )
end

derma.DefineControl( "MP.LockButton", "", LOCK_BTN, "MP.SidebarToggleButton" )
