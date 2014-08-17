local FontTbl = {
	font = "Roboto Medium",
	size = 21,
	weight = 400,
	antialias = true
}

surface.CreateFont( "MP.MediaTitle", FontTbl )

FontTbl.font = "Roboto Medium"
FontTbl.size = 18
surface.CreateFont( "MP.MediaTime", FontTbl )

FontTbl.font = "Roboto Medium"
FontTbl.size = 18
surface.CreateFont( "MP.QueueHeader", FontTbl )

FontTbl.font = "Roboto Light"
surface.CreateFont( "MP.MediaDuration", FontTbl )

FontTbl.font = "Roboto Light"
FontTbl.size = 13
surface.CreateFont( "MP.Prefix", FontTbl )

FontTbl.font = "Roboto Bold"
FontTbl.size = 16
surface.CreateFont( "MP.AddedByName", FontTbl )


local MEDIA_TITLE = {}

function MEDIA_TITLE:Init()
	self.BaseClass.Init( self )
	self:SetFont( "MP.MediaTitle" )
	self:SetTextColor( color_white )
end

derma.DefineControl( "MP.MediaTitle", "", MEDIA_TITLE, "DLabel" )


local MEDIA_TIME = {}

AccessorFunc( MEDIA_TIME, "StartTime", "StartTime" )
AccessorFunc( MEDIA_TIME, "Duration", "Duration" )

function MEDIA_TIME:Init()

	self.TimeLbl = vgui.Create( "DLabel", self )
	self.TimeLbl:SetFont( "MP.MediaTime" )
	self.TimeLbl:SetText( "" )
	self.TimeLbl:SetTextColor( color_white )

	self.DividerLbl = vgui.Create( "DLabel", self )
	self.DividerLbl:SetText( "" )
	self.DividerLbl:SetFont( "MP.MediaDuration" )
	-- self.DividerLbl:SetTextColor( color_white )

	self.DurationLbl = vgui.Create( "DLabel", self )
	self.DurationLbl:SetText( "" )
	self.DurationLbl:SetFont( "MP.MediaDuration" )
	-- self.DurationLbl:SetTextColor( color_white )

	self:SetStartTime( os.time() )
	self:SetDuration( 43200 )

	self.NextThink = 0

end

function MEDIA_TIME:SetStartTime( time )
	self.StartTime = time

	self:UpdateDivider()
end

function MEDIA_TIME:SetDuration( duration )
	self.Duration = duration

	self.DurationLbl:SetText( string.FormatSeconds( duration ) )
	self:UpdateDivider()
end

function MEDIA_TIME:UpdateDivider()
	if self.StartTime and self.Duration then
		self.DividerLbl:SetText( "/" )
	end
end

function MEDIA_TIME:Think()

	local rt = RealTime()

	if self.NextThink > rt then return end

	local curTime = os.time()
	local mediaTime

	if self.StartTime then
		mediaTime = curTime - self.StartTime

		self.TimeLbl:SetText( string.FormatSeconds( mediaTime ) )
		self:InvalidateLayout()
	end

	self.NextThink = rt + 0.5

end

function MEDIA_TIME:PerformLayout()

	self.TimeLbl:SizeToContents()
	self.DividerLbl:SizeToContents()
	self.DurationLbl:SizeToContents()

	self.TimeLbl:CenterVertical()
	self.TimeLbl:AlignLeft( 0 )

	self.DividerLbl:CenterVertical()
	self.DividerLbl:MoveRightOf( self.TimeLbl )

	self.DurationLbl:CenterVertical()
	self.DurationLbl:MoveRightOf( self.DividerLbl )

	local totalwidth = self.DurationLbl:GetPos() + self.DurationLbl:GetWide()
	self:SetWide( totalwidth )

end

derma.DefineControl( "MP.MediaTime", "", MEDIA_TIME, "Panel" )


local ADDED_BY = {}

ADDED_BY.NameOffset = 4

function ADDED_BY:Init()

	self.PrefixLbl = vgui.Create( "DLabel", self )
	self.PrefixLbl:SetFont( "MP.Prefix" )
	self.PrefixLbl:SetText( "ADDED BY" )
	self.PrefixLbl:SetTextColor( color_white )
	self.PrefixLbl:SetContentAlignment( 8 )

	self.NameLbl = vgui.Create( "DLabel", self )
	self.NameLbl:SetFont( "MP.AddedByName" )
	self.NameLbl:SetText( "Foobar" )
	self.NameLbl:SetTextColor( color_white )
	self.NameLbl:SetContentAlignment( 8 )

end

function ADDED_BY:PerformLayout()

	self.PrefixLbl:SizeToContents()
	self.NameLbl:SizeToContents()

	local w = self.PrefixLbl:GetWide() + self.NameLbl:GetWide() + self.NameOffset
	local h = math.max( self.PrefixLbl:GetTall(), self.PrefixLbl:GetTall() )
	self:SetSize( w, h )

	self.PrefixLbl:AlignLeft( 0 )
	self.NameLbl:MoveRightOf( self.PrefixLbl, self.NameOffset )

	self.PrefixLbl:CenterVertical()
	self.NameLbl:CenterVertical()

end

derma.DefineControl( "MP.AddedBy", "", ADDED_BY, "Panel" )


local FAVORITE_BTN = {}

FAVORITE_BTN.FavStarOutlined = "mediaplayer/ui/fav_star_outline.png"
FAVORITE_BTN.FavStar = "mediaplayer/ui/fav_star.png"

function FAVORITE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( 21, 21 )
	self:SetImage( self.FavStarOutlined )

	self.Outlined = true

end

function FAVORITE_BTN:Think()

	local hovered = self:IsHovered()

	if self.Outlined then
		if hovered then
			self:SetImage( self.FavStar )
			self.Outlined = false
		end
	else
		if not hovered then
			self:SetImage( self.FavStarOutlined )
			self.Outlined = true
		end
	end

end

function FAVORITE_BTN:DoClick()

	-- TODO: Favorite media

end

derma.DefineControl( "MP.FavoriteButton", "", FAVORITE_BTN, "DImageButton" )


local SKIP_BTN = {}

SKIP_BTN.Icon = "mediaplayer/ui/skip.png"

function SKIP_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( 16, 16 )
	self:SetImage( self.Icon )

end

function SKIP_BTN:DoClick()

	-- TODO: Skip current media

end

derma.DefineControl( "MP.SkipButton", "", SKIP_BTN, "DImageButton" )


local REMOVE_BTN = {}

REMOVE_BTN.Icon = "mediaplayer/ui/delete.png"

function REMOVE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( 17, 20 )
	self:SetImage( self.Icon )

end

function REMOVE_BTN:DoClick()

	-- TODO: Remove current media

end

derma.DefineControl( "MP.RemoveButton", "", REMOVE_BTN, "DImageButton" )
