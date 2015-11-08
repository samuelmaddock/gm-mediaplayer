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

local AddEnabledColor = Color( 232, 78, 64 )
local AddEnabledHoverColor = Color( 252, 98, 84 )

local AddDisabledColor = Color( 140, 140, 140 )

ADD_VIDEO_BTN.Color = AddEnabledColor
ADD_VIDEO_BTN.HoverColor = AddEnabledHoverColor

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

function ADD_VIDEO_BTN:SetLocked( locked )

	if locked and not hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER ) then
		self:SetDisabled( true )
		self.Color = AddDisabledColor
		self.HoverColor = AddDisabledColor
		self:SetIcon( "mp-lock" )
	end

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

function QUEUE_LIST:Init()

	self.BaseClass.Init( self )

	self:SetSpacing( 1 )

	-- TODO: Replace with custom scrollbar
	self:EnableVerticalScrollbar()

end

derma.DefineControl( "MP.QueueList", "", QUEUE_LIST, "DPanelList" )


local MEDIA_ITEM = {}

MEDIA_ITEM.Height = 64

MEDIA_ITEM.BgColor = Color( 13, 41, 62 )
MEDIA_ITEM.HPadding = 12
MEDIA_ITEM.VPadding = 8
MEDIA_ITEM.BtnSpacing = 4

MEDIA_ITEM.TrackbarProgressColor = Color( 28, 100, 157 )
MEDIA_ITEM.TrackbarHeight = 2

MEDIA_ITEM.TitleMaxWidth = 335

MEDIA_ITEM.KnobSize = 8

function MEDIA_ITEM:Init()

	self.MediaTitle = vgui.Create( "MP.MediaTitle", self )
	self.MediaTime = vgui.Create( "MP.MediaTime", self )
	self.FavBtn = vgui.Create( "MP.FavoriteButton", self )
	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

	self.BtnList = vgui.Create( "DHorizontalList", self )
	self.BtnList:SetSpacing( self.BtnSpacing )

end

function MEDIA_ITEM:SetMedia( media )

	self.MediaTitle:SetText( media:Title() )
	self.MediaTime:SetMedia( media )
	self.AddedByLbl:SetPlayer( media:GetOwner(), media:OwnerName(), media:OwnerSteamID() )

	self.FavBtn:SetMedia( media )

	hook.Run( MP.EVENTS.UI.SETUP_MEDIA_PANEL, self, media )

	-- Detect if player has privileges to remove media from queue
	local privileged = hook.Run( MP.EVENTS.UI.PRIVILEGED_PLAYER )
	if privileged or media:IsOwner( LocalPlayer() ) then
		self.RemoveBtn = vgui.Create( "MP.RemoveButton" )
		self:AddButton( self.RemoveBtn )
	end

	-- apply media for all buttons
	for _, btn in pairs( self.BtnList:GetItems() ) do
		if ValidPanel(btn) and isfunction(btn.SetMedia) then
			btn:SetMedia( media )
		end
	end

end

function MEDIA_ITEM:AddButton( panel )
	self.BtnList:AddItem( panel )
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

	self.FavBtn:Hide()
	self.FavBtn:AlignTop( self.VPadding )
	self.FavBtn:AlignRight( self.HPadding )

	self.BtnList:InvalidateLayout(true)
	self.BtnList:AlignBottom( self.VPadding )
	self.BtnList:AlignRight( self.HPadding )

	local maxAddedByWidth = ( self.BtnList:GetPos() - 8 ) -
			( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.HPadding )

	self.AddedByLbl:SetMaxWidth( maxAddedByWidth )
	self.AddedByLbl:AlignBottom( self.VPadding )
	self.AddedByLbl:MoveLeftOf( self.BtnList, 8 )

	local maxTitleWidth = self.FavBtn:GetPos() -
		( self.MediaTitle:GetPos() + 5 )

	if self.MediaTitle:GetWide() > maxTitleWidth then
		self.MediaTitle:SetWide( maxTitleWidth )
	end

end

derma.DefineControl( "MP.MediaItem", "", MEDIA_ITEM, "Panel" )
