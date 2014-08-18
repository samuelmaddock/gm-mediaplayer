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

	self.NextThink = 0

end

function MEDIA_TIME:SetStartTime( time )
	self.StartTime = time

	local text = time and "0:00" or ""
	self.TimeLbl:SetText( text )

	self:UpdateDivider()
end

function MEDIA_TIME:SetDuration( duration )
	self.Duration = duration

	local text = duration and string.FormatSeconds( duration ) or ""
	self.DurationLbl:SetText( text )

	self:UpdateDivider()
end

function MEDIA_TIME:UpdateDivider()
	local text = (self.StartTime and self.Duration) and "/" or ""
	self.DividerLbl:SetText( text )
end

function MEDIA_TIME:Clear()
	self:SetStartTime( nil )
	self:SetDuration( nil )
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

ADDED_BY.Height = 21
ADDED_BY.NameOffset = 4

function ADDED_BY:Init()

	self.PrefixLbl = vgui.Create( "DLabel", self )
	self.PrefixLbl:SetFont( "MP.Prefix" )
	self.PrefixLbl:SetText( "ADDED BY" )
	self.PrefixLbl:SetTextColor( color_white )
	self.PrefixLbl:SetContentAlignment( 8 )

	self.NameLbl = vgui.Create( "DLabel", self )
	self.NameLbl:SetFont( "MP.AddedByName" )
	self.NameLbl:SetText( "Unknown" )
	self.NameLbl:SetTextColor( color_white )
	self.NameLbl:SetContentAlignment( 8 )

end

function ADDED_BY:SetPlayer( ply, name, steamId )
	self.NameLbl:SetText( name )
	self.NameLbl:SetTooltip( steamId )
end

function ADDED_BY:SetMaxWidth( width )
	self.maxWidth = width
	self:InvalidateLayout()
end

function ADDED_BY:PerformLayout()

	self.PrefixLbl:SizeToContents()
	self.NameLbl:SizeToContents()

	local pw = self.PrefixLbl:GetWide()
	local nw = self.NameLbl:GetWide()
	local w = pw + nw + self.NameOffset

	if self.maxWidth then
		w = math.min( w, self.maxWidth )

		-- Clips name label to the maximum width; looks kind of bad since the
		-- ellipsis start too early for some reason.
		-- nw = math.max( 0, w - self.NameOffset - pw )
		-- self.NameLbl:SetWide( nw )
	end

	self:SetSize( w, self.Height )

	self.PrefixLbl:AlignLeft( 0 )
	self.NameLbl:MoveRightOf( self.PrefixLbl, self.NameOffset )

	-- align text baselines
	self.PrefixLbl:AlignBottom( 3 )
	self.NameLbl:AlignBottom( 3 )

end

derma.DefineControl( "MP.AddedBy", "", ADDED_BY, "Panel" )

local BUTTON_SIZE = 21

local FAVORITE_BTN = {}

FAVORITE_BTN.FavStarOutlined = "mediaplayer/ui/fav_star_outline.png"
FAVORITE_BTN.FavStar = "mediaplayer/ui/fav_star.png"

function FAVORITE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( BUTTON_SIZE, BUTTON_SIZE )
	self:SetStretchToFit( false )

	self:SetImage( self.FavStarOutlined )

	self.Outlined = true

end

function FAVORITE_BTN:SetImage( strImage, strBackup )

	self.m_Image:SetImage( strImage, strBackup )

	self.m_Image.ActualWidth = 21
	self.m_Image.ActualHeight = 21

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

	self:SetSize( BUTTON_SIZE, BUTTON_SIZE )
	self:SetStretchToFit( false )

	self:SetImage( self.Icon )
	self.m_Image.ActualWidth = 16
	self.m_Image.ActualHeight = 16

end

function SKIP_BTN:DoClick()

	-- TODO: Skip current media

end

derma.DefineControl( "MP.SkipButton", "", SKIP_BTN, "DImageButton" )


local REMOVE_BTN = {}

REMOVE_BTN.Icon = "mediaplayer/ui/delete.png"

function REMOVE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( BUTTON_SIZE, BUTTON_SIZE )
	self:SetStretchToFit( false )

	self:SetImage( self.Icon )
	self.m_Image.ActualWidth = 17
	self.m_Image.ActualHeight = 20

end

function REMOVE_BTN:DoClick()

	-- TODO: Remove current media

end

derma.DefineControl( "MP.RemoveButton", "", REMOVE_BTN, "DImageButton" )
