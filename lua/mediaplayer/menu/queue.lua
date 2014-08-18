local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

function PANEL:Init()

	self.Header = vgui.Create( "MP.QueueHeader", self )
	self.Header:Dock( TOP )

	self.List = vgui.Create( "MP.QueueList", self )
	self.List:Dock( FILL )

end

function PANEL:OnQueueChanged( queue )

	self.List:Clear()

	for _, media in pairs(queue) do
		local item = vgui.Create( "MP.MediaItem" )
		self.List:AddItem( item )
	end

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


local QUEUE_LIST = {}

QUEUE_LIST.BgColor = Color( 7, 21, 33 )

function QUEUE_LIST:Init()

	self.BaseClass.Init( self )

	self:SetSpacing( 1 )

	-- TODO: Replace with custom scrollbar
	self:EnableVerticalScrollbar()

end

function QUEUE_LIST:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

end

derma.DefineControl( "MP.QueueList", "", QUEUE_LIST, "DPanelList" )


local MEDIA_ITEM = {}

MEDIA_ITEM.Height = 64

MEDIA_ITEM.BgColor = Color( 13, 41, 62 )
MEDIA_ITEM.HPadding = 12
MEDIA_ITEM.VPadding = 8

MEDIA_ITEM.TrackbarProgressColor = Color( 28, 100, 157 )
MEDIA_ITEM.TrackbarHeight = 2

MEDIA_ITEM.TitleMaxWidth = 335

MEDIA_ITEM.KnobSize = 8

function MEDIA_ITEM:Init()

	self.MediaTitle = vgui.Create( "MP.MediaTitle", self )
	self.MediaTitle:SetText( "Very Bad Video That Everyone Hates Included" )

	self.MediaTime = vgui.Create( "MP.MediaTime", self )

	-- TODO: remove testing defaults
	self.MediaTime:SetDuration( math.Rand(0, 86400) )

	self.FavBtn = vgui.Create( "MP.FavoriteButton", self )

	-- TODO: Only allow these buttons to show for admins
	self.RemoveBtn = vgui.Create( "MP.RemoveButton", self )

	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

end

function MEDIA_ITEM:Paint( w, h )

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

end

function MEDIA_ITEM:PerformLayout()

	local w = self:GetWide()

	self:SetTall( self.Height )

	self.MediaTitle:SizeToContents()
	self.MediaTitle:AlignLeft( self.HPadding )
	self.MediaTitle:AlignTop( self.VPadding )

	self.MediaTime:InvalidateLayout()
	self.MediaTime:AlignLeft( self.HPadding )
	self.MediaTime:AlignBottom( self.VPadding )

	self.FavBtn:AlignTop( self.VPadding )
	self.FavBtn:AlignRight( self.HPadding )

	self.RemoveBtn:AlignBottom( self.VPadding )
	self.RemoveBtn:AlignRight( self.HPadding )

	self.AddedByLbl:MoveLeftOf( self.RemoveBtn, self.HPadding )
	self.AddedByLbl:AlignBottom( self.VPadding )

	local maxTitleWidth = self.FavBtn:GetPos() -
		( self.MediaTitle:GetPos() + 5 )

	if self.MediaTitle:GetWide() > maxTitleWidth then
		self.MediaTitle:SetWide( maxTitleWidth )
	end

end

derma.DefineControl( "MP.MediaItem", "", MEDIA_ITEM, "Panel" )
