local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

function PANEL:Init()

	self.Header = vgui.Create( "MP.QueueHeader", self )
	self.Header:Dock( TOP )

end

derma.DefineControl( "MP.Queue", "", PANEL, "Panel" )


local QUEUE_HEADER = {}

QUEUE_HEADER.BgColor = Color( 7, 21, 33 )

QUEUE_HEADER.Height = 43
QUEUE_HEADER.Padding = 10

function QUEUE_HEADER:Init()

	self:SetTall( self.Height )

	self.Label = vgui.Create( "DLabel", self )
	self.Label:SetText( "NEXT UP" )
	self.Label:SetFont( "MP.QueueHeader" )

	self.AddVidBtn = vgui.Create( "MP.AddVideoButton", self )

end

function QUEUE_HEADER:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

end

function QUEUE_HEADER:PerformLayout()

	self.Label:CenterVertical()
	self.Label:AlignLeft( self.Padding )

	self.AddVidBtn:InvalidateLayout()
	self.AddVidBtn:CenterVertical()
	self.AddVidBtn:AlignRight( self.Padding )

end

derma.DefineControl( "MP.QueueHeader", "", QUEUE_HEADER, "Panel" )


local ADD_VIDEO_BTN = {}

ADD_VIDEO_BTN.Color = Color( 232, 78, 64 )
ADD_VIDEO_BTN.HoverColor = Color( 252, 98, 84 )

ADD_VIDEO_BTN.PlusIcon = "mediaplayer/ui/plus.png"

function ADD_VIDEO_BTN:Init()

	self.BaseClass.Init( self )

	self:SetFont( "MP.QueueHeader" )
	self:SetText( "ADD A VIDEO" )
	self:SetTextColor( color_white )

	self:SetIcon( self.PlusIcon )

	self:SetSize( 118, 24 )

end

function ADD_VIDEO_BTN:Paint( w, h )

	local col

	if self:IsHovered() then
		col = self.HoverColor
	else
		col = self.Color
	end

	surface.SetDrawColor( col )
	surface.DrawRect( 0, 0, w, h )

end

derma.DefineControl( "MP.AddVideoButton", "", ADD_VIDEO_BTN, "DButton" )
