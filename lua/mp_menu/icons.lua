local spritesheet = spritesheet

--[[--------------------------------------------
	Icons spritesheet
----------------------------------------------]]

local mpSpritesheetMat = Material( "mediaplayer/ui/spritesheet2015-10-7.png" )
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
	mpIcon( "mp-thumbs-up",			0, 0, 18, 21 ),
	mpIcon( "mp-thumbs-down",		1, 0, 18, 21 ),
	mpIcon( "mp-delete",			2, 0, 15, 20 ),
	mpIcon( "mp-favorite",			3, 0, 21, 21 ),
	mpIcon( "mp-favorite-outline", 	4, 0, 21, 21 ),
	mpIcon( "mp-volume-mute", 		0, 1, 18, 17 ),
	mpIcon( "mp-volume", 			1, 1, 18, 17 ),
	mpIcon( "mp-back", 				2, 1, 16, 17 ),
	mpIcon( "mp-forward", 			3, 1, 16, 17 ),
	mpIcon( "mp-home", 				4, 1, 19, 17 ),
	mpIcon( "mp-close", 			0, 2, 16, 16 ),
	mpIcon( "mp-skip", 				1, 2, 16, 16 ),
	mpIcon( "mp-refresh", 			2, 2, 16, 15 ),
	mpIcon( "mp-plus", 				3, 2, 14, 14 ),
	mpIcon( "mp-repeat", 			4, 2, 18, 18 ),
	mpIcon( "mp-shuffle", 			0, 3, 16, 16 ),
	mpIcon( "mp-replay", 			1, 3, 13, 16 ),
	mpIcon( "mp-lock", 			    2, 3, 12, 16 ),
	mpIcon( "mp-lock-open", 		3, 3, 12, 16 ),

	mpIcon( "mp-play", 				3, 4, 19, 25 ),
	mpIcon( "mp-pause",				4, 4, 22, 24 ),
}


--[[--------------------------------------------
	DIcon
----------------------------------------------]]

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
	DIconButton
----------------------------------------------]]

local DICONLBLBTN = {}

AccessorFunc( DICONLBLBTN, "m_LabelSpacing", "LabelSpacing" )
AccessorFunc( DICONLBLBTN, "m_Padding", "Padding" )

function DICONLBLBTN:Init()

	self.BaseClass.Init( self )

	self.BtnLbl = vgui.Create( "DLabel", self )
	self.BtnLbl:SetText( "" )

	self:SetLabelSpacing( 4 )
	self:SetPadding( 4 )

end

function DICONLBLBTN:PerformLayout()

	self.m_Icon:SizeToContents()
	self.m_Icon:AlignLeft( self.m_Padding )

	self.BtnLbl:SizeToContents()
	self.BtnLbl:MoveRightOf( self.m_Icon, self.m_LabelSpacing )

	local w = self.BtnLbl:GetPos() + self.BtnLbl:GetWide() + self.m_Padding
	local h = math.max( self.m_Icon:GetTall(), self.BtnLbl:GetTall() )
	self:SetWide( w, h )

	self.m_Icon:CenterVertical()
	self.BtnLbl:CenterVertical()

end

derma.DefineControl( "DIconLabeledButton", "", DICONLBLBTN, "DIconButton" )
