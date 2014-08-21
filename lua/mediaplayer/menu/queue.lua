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
		item:SetMedia( media )

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

function ADD_VIDEO_BTN:Init()

	self.BtnLbl = vgui.Create( "DLabel", self )
	self.BtnLbl:SetText( "Button" )

	self:SetLabelSpacing( 4 )
	self:SetPadding( 4 )

	self.BtnLbl:SetFont( "MP.QueueHeader" )
	self.BtnLbl:SetText( "ADD MEDIA" )
	self.BtnLbl:SetTextColor( color_white )

	self:SetIcon( "mp-plus" )

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

function ADD_VIDEO_BTN:DoClick()
	hook.Run( MP.EVENTS.UI.OPEN_REQUEST_MENU )
end

derma.DefineControl( "MP.AddVideoButton", "", ADD_VIDEO_BTN, "DIconLabeledButton" )


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
	self.MediaTime = vgui.Create( "MP.MediaTime", self )
	self.FavBtn = vgui.Create( "MP.FavoriteButton", self )
	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

end

function MEDIA_ITEM:SetMedia( media )

	self.MediaTitle:SetText( media:Title() )
	self.MediaTime:SetDuration( media:Duration() )
	self.AddedByLbl:SetPlayer( media:GetOwner(), media:OwnerName(), media:OwnerSteamID() )

	self.FavBtn:SetMedia( media )

	-- TODO: detect if player has privileges to remove media from queue
	-- e.g. they requested the media or they're an admin
	if true then
		self.RemoveBtn = vgui.Create( "MP.RemoveButton", self )
		self.RemoveBtn:SetMedia( media )
	end

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
	self.MediaTime:AlignBottom( self.VPadding - 3 )

	self.FavBtn:AlignTop( self.VPadding )
	self.FavBtn:AlignRight( self.HPadding )


	local maxAddedByWidth

	if self.RemoveBtn then
		self.RemoveBtn:AlignBottom( self.VPadding )
		self.RemoveBtn:AlignRight( self.HPadding )

		maxAddedByWidth = ( self.RemoveBtn:GetPos() - 4 ) -
			( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.HPadding )
	else
		maxAddedByWidth = ( w - self.HPadding ) -
			( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.HPadding )
	end

	self.AddedByLbl:SetMaxWidth( maxAddedByWidth )
	self.AddedByLbl:AlignBottom( self.VPadding )

	if self.RemoveBtn then
		self.AddedByLbl:MoveLeftOf( self.RemoveBtn, 4 )
	else
		self.AddedByLbl:AlignRight( self.HPadding )
	end

	local maxTitleWidth = self.FavBtn:GetPos() -
		( self.MediaTitle:GetPos() + 5 )

	if self.MediaTitle:GetWide() > maxTitleWidth then
		self.MediaTitle:SetWide( maxTitleWidth )
	end

end

derma.DefineControl( "MP.MediaItem", "", MEDIA_ITEM, "Panel" )
