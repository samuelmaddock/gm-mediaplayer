local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.Margin = 12

function PANEL:Init()

	self.BaseClass.Init( self )

	self.VolumeButton = vgui.Create( "MP.VolumeButton", self )

	-- self.VolumeSlider = vgui.Create( "MP.VolumeSlider", self )
	-- self.VolumeSlider:Dock( FILL )

	-- local lrMargin = self.Margin * 2
	-- self.VolumeSlider:DockMargin( lrMargin, 0, lrMargin, 0 )

	self.VolumeLabel = vgui.Create( "DLabel", self )
	self.VolumeLabel:SetContentAlignment( 5 ) -- center

	self.Volume = -1

end

function PANEL:Think()

	local volume = MediaPlayer.Volume()

	if self.Volume ~= volume then
		-- self.VolumeSlider:SetValue( volume )
		self.VolumeLabel:SetText( volume )

		self.Volume = volume
	end

end

function PANEL:Paint(w, h)

end

function PANEL:PerformLayout()

	-- self.VolumeButton:CenterVertical()
	-- self.VolumeButton:AlignLeft( self.Margin )

	-- self.VolumeLabel:SizeToContents()
	-- self.VolumeLabel:CenterVertical()
	-- self.VolumeLabel:AlignLeft( self.Margin )

end

derma.DefineControl( "MP.VolumeControl", "", PANEL, "DPanel" )


local VOLUME_BUTTON = {}

local VolumeIconMat = Material( "mediaplayer/ui/volume.png" )

function VOLUME_BUTTON:Init()

	self.BaseClass.Init( self )

end

function VOLUME_BUTTON:Paint(w, h)

	surface.SetDrawColor( color_white )
	surface.SetMaterial( VolumeIconMat )
	surface.DrawRect( 0, 0, w, h )

end

function VOLUME_BUTTON:DoClick()

	-- TODO: Toggle mute

end

derma.DefineControl( "MP.VolumeButton", "", VOLUME_BUTTON, "DLabel" )


local VOLUME_SLIDER = {}

function VOLUME_SLIDER:Init()

	self.BaseClass.Init( self )

end

function VOLUME_SLIDER:Paint(w, h)

	-- TODO

end

derma.DefineControl( "MP.VolumeSlider", "", VOLUME_SLIDER, "DSlider" )
