local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.Margin = 20
PANEL.ButtonWidth = 18
PANEL.BackgroundColor = Color( 28, 100, 157 )

function PANEL:Init()

	self.BaseClass.Init( self )

	self.VolumeButton = vgui.Create( "MP.VolumeButton", self )

	self.VolumeSlider = vgui.Create( "MP.VolumeSlider", self )
	self.VolumeSlider:Dock( FILL )

	local lrMargin = self.Margin * 2 + self.ButtonWidth
	self.VolumeSlider:DockMargin( lrMargin, 0, lrMargin, 0 )

	self.VolumeLabel = vgui.Create( "DLabel", self )
	self.VolumeLabel:SetContentAlignment( 6 ) -- center right

	self:OnVolumeChanged( MediaPlayer.Volume() )

	hook.Add( MP.EVENTS.VOLUME_CHANGED, self, self.OnVolumeChanged )

end

function PANEL:OnVolumeChanged( volume )

	local scaledVolume = math.Round(volume * 100)

	self.VolumeSlider:SetSlideX( volume )
	self.VolumeLabel:SetText( scaledVolume )

	self:InvalidateChildren()

end

function PANEL:Paint( w, h )

	surface.SetDrawColor( self.BackgroundColor )
	surface.DrawRect( 0, 0, w, h )

end

function PANEL:PerformLayout()

	self.VolumeButton:CenterVertical()
	self.VolumeButton:AlignLeft( self.Margin )

	self.VolumeLabel:SizeToContents()
	self.VolumeLabel:CenterVertical()
	self.VolumeLabel:AlignRight( self.Margin )

end

derma.DefineControl( "MP.VolumeControl", "", PANEL, "DPanel" )


local VOLUME_BUTTON = {}

VOLUME_BUTTON.EnabledIcon = "mediaplayer/ui/volume.vmt"
local textId = surface.GetTextureID( "mediaplayer/ui/volume.vmt" )

function VOLUME_BUTTON:Init()

	self.BaseClass.Init( self )

	self:SetSize( 16, 15 )

	-- self:SetImage( self.EnabledIcon )

end

function VOLUME_BUTTON:PaintOver( w, h )
	surface.SetDrawColor( color_white )
	surface.SetTexture( textId )
	surface.DrawTexturedRect( 0, 0, w, h )
end

function VOLUME_BUTTON:DoClick()

	-- TODO: Toggle mute
	print "CLICKED VOLUME BUTTON"

end

derma.DefineControl( "MP.VolumeButton", "", VOLUME_BUTTON, "DImageButton" )


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
