local ceil = math.ceil
local clamp = math.Clamp

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

	local curTime = RealTime()
	local mediaTime

	if self.StartTime then
		mediaTime = clamp( curTime - self.StartTime, 0, self.Duration )

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


--[[--------------------------------------------
	Icons spritesheet
----------------------------------------------]]

local mpSpritesheetMat = Material( "mediaplayer/ui/spritesheet.png" )
local blockSize = 24

local function mpIcon( name, i, j, w, h )
	return {
		name = name,
		mat = mpSpritesheetMat,
		w = w,
		h = h,
		xoffset = i * blockSize,
		yoffset = j * blockSize
	}
end

spritesheet.Register {
	mpIcon( "mp-thumbs-up",			0, 0, 21, 21 ),
	mpIcon( "mp-thumbs-down",		1, 0, 21, 21 ),
	mpIcon( "mp-delete",			2, 0, 15, 20 ),
	mpIcon( "mp-favorite",			3, 0, 21, 21 ),
	mpIcon( "mp-favorite-outline", 	4, 0, 21, 21 ),
	mpIcon( "mp-volume-mute", 		0, 1, 18, 17 ),
	mpIcon( "mp-volume", 			1, 1, 18, 17 ),
	mpIcon( "mp-back", 				2, 1, 21, 21 ),
	mpIcon( "mp-forward", 			3, 1, 21, 21 ),
	mpIcon( "mp-home", 				4, 1, 21, 21 ),
	mpIcon( "mp-close", 			0, 2, 21, 21 ),
	mpIcon( "mp-skip", 				1, 2, 16, 16 ),
	mpIcon( "mp-refresh", 			2, 2, 21, 21 ),
	mpIcon( "mp-plus", 				3, 2, 21, 21 ),

	mpIcon( "mp-play", 				3, 4, 19, 25 ),
	mpIcon( "mp-pause",				4, 4, 22, 24 ),
}


--[[--------------------------------------------
	DIcon
----------------------------------------------]]

local spritesheet = spritesheet

local DICON = {}

AccessorFunc( DICON, "m_strIcon", 				"Icon" )
AccessorFunc( DICON, "m_Color", 				"IconColor" )
AccessorFunc( DICON, "m_bKeepAspect", 			"KeepAspect" )

function DICON:Init()

	self:SetIconColor( color_white )
	self:SetMouseInputEnabled( false )
	self:SetKeyboardInputEnabled( false )

	self:SetKeepAspect( false )

	self.IconWidth = 10
	self.IconHeight = 10

end

function DICON:SetIcon( icon )

	self.m_strIcon = icon

	self.IconWidth, self.IconHeight = spritesheet.GetIconSize( icon )

end

function DICON:SizeToContents( strImage )

	self:SetSize( self.IconWidth, self.IconHeight )

end

function DICON:Paint( w, h )
	self:PaintAt( 0, 0, w, h )
end

function DICON:PaintAt( x, y, dw, dh )

	if not self.m_strIcon then return end

	if ( self.m_bKeepAspect ) then

		local w = self.IconWidth
		local h = self.IconHeight

		-- Image is bigger than panel, shrink to suitable size
		if ( w > dw and h > dh ) then

			if ( w > dw ) then

				local diff = dw / w
				w = w * diff
				h = h * diff

			end

			if ( h > dh ) then

				local diff = dh / h
				w = w * diff
				h = h * diff

			end

		end

		if ( w < dw ) then

			local diff = dw / w
			w = w * diff
			h = h * diff

		end

		if ( h < dh ) then

			local diff = dh / h
			w = w * diff
			h = h * diff

		end

		local OffX = ceil((dw - w) * 0.5)
		local OffY = ceil((dh - h) * 0.5)

		spritesheet.DrawIcon( self.m_strIcon, OffX+y, OffY+y, w, h, self.m_Color )
		return true

	end

	spritesheet.DrawIcon( self.m_strIcon, x, y, dw, dh, self.m_Color )
	return true

end

derma.DefineControl( "DIcon", "", DICON, "DPanel" )


--[[--------------------------------------------
	DIconButton
----------------------------------------------]]

local DICONBTN = {}

AccessorFunc( DICONBTN, "m_strIcon", "Icon" )
AccessorFunc( DICONBTN, "m_bStretchToFit", 			"StretchToFit" )

function DICONBTN:Init()

	self:SetDrawBackground( false )
	self:SetDrawBorder( false )
	self:SetStretchToFit( false )

	self:SetCursor( "hand" )
	self.m_Icon = vgui.Create( "DIcon", self )

	self:SetText( "" )

	self:SetColor( Color( 255, 255, 255, 255 ) )

end

function DICONBTN:SetIconVisible( bBool )

	self.m_Icon:SetVisible( bBool )

end

function DICONBTN:SetIcon( strIcon )

	self.m_Icon:SetIcon( strIcon )

end

function DICONBTN:SetColor( col )

	self.m_Icon:SetIconColor( col )

end

function DICONBTN:GetIcon()

	return self.m_Icon:GetIcon()

end

function DICONBTN:SetKeepAspect( bKeep )

	self.m_Icon:SetKeepAspect( bKeep )

end

function DICONBTN:SizeToContents( )

	self.m_Icon:SizeToContents()
	self:SetSize( self.m_Icon:GetWide(), self.m_Icon:GetTall() )

end

function DICONBTN:OnMousePressed( mousecode )

	DButton.OnMousePressed( self, mousecode )


	--[[if ( self.m_bStretchToFit ) then

		self.m_Icon:SetPos( 2, 2 )
		self.m_Icon:SetSize( self:GetWide() - 4, self:GetTall() - 4 )

	else

		self.m_Icon:SizeToContents()
		self.m_Icon:SetSize( self.m_Icon:GetWide() * 0.8, self.m_Icon:GetTall() * 0.8 )
		self.m_Icon:Center()

	end]]

end

function DICONBTN:OnMouseReleased( mousecode )

	DButton.OnMouseReleased( self, mousecode )

	--[[if ( self.m_bStretchToFit ) then

		self.m_Icon:SetPos( 0, 0 )
		self.m_Icon:SetSize( self:GetSize() )

	else

		self.m_Icon:SizeToContents()
		self.m_Icon:Center()

	end]]

end

function DICONBTN:PerformLayout()

	if ( self.m_bStretchToFit ) then

		self.m_Icon:SetPos( 0, 0 )
		self.m_Icon:SetSize( self:GetSize() )

	else

		self.m_Icon:SizeToContents()
		self.m_Icon:Center()

	end

end

derma.DefineControl( "DIconButton", "", DICONBTN, "DButton" )


--[[--------------------------------------------
	Sidebar buttons
----------------------------------------------]]

local SIDEBAR_BTN = {}

AccessorFunc( SIDEBAR_BTN, "m_Media", "Media" )

function SIDEBAR_BTN:Init()

	self:SetSize( 21, 21 )

end

-- function SIDEBAR_BTN:Paint(w,h)
-- 	surface.SetDrawColor(255,0,0)
-- 	surface.DrawRect(0,0,w,h)
-- end

derma.DefineControl( "MP.SidebarButton", "", SIDEBAR_BTN, "DIconButton" )


local FAVORITE_BTN = {}

AccessorFunc( FAVORITE_BTN, "Favorited", "Favorited" )

function FAVORITE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetIcon( "mp-favorite-outline" )
	self:SetFavorited( false )
	self.Outlined = true

end

function FAVORITE_BTN:Think()

	if not self.Favorited then
		local hovered = self:IsHovered()

		if self.Outlined then
			if hovered then
				self:SetIcon( "mp-favorite" )
				self.Outlined = false
			end
		else
			if not hovered then
				self:SetIcon( "mp-favorite-outline" )
				self.Outlined = true
			end
		end
	end

end

function FAVORITE_BTN:DoClick()

	hook.Run( MP.EVENTS.UI.FAVORITE_MEDIA, self.m_Media )

end

derma.DefineControl( "MP.FavoriteButton", "", FAVORITE_BTN, "MP.SidebarButton" )


local SKIP_BTN = {}

function SKIP_BTN:Init()

	self.BaseClass.Init( self )

	self:SetIcon( "mp-skip" )

end

function SKIP_BTN:DoClick()

	hook.Run( MP.EVENTS.UI.VOTESKIP_MEDIA, self.m_Media )

end

derma.DefineControl( "MP.SkipButton", "", SKIP_BTN, "MP.SidebarButton" )


local REMOVE_BTN = {}

function REMOVE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetIcon( "mp-delete" )

end

function REMOVE_BTN:DoClick()

	hook.Run( MP.EVENTS.UI.REMOVE_MEDIA, self.m_Media )

end

derma.DefineControl( "MP.RemoveButton", "", REMOVE_BTN, "MP.SidebarButton" )
