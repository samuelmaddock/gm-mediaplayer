local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.BgColor = Color( 13, 41, 62 )
PANEL.Padding = 12

PANEL.TrackbarProgressColor = Color( 28, 100, 157 )
PANEL.TrackbarHeight = 2

PANEL.TitleMaxWidth = 335

PANEL.KnobSize = 8

function PANEL:Init()

	self.PlayPauseBtn = vgui.Create( "MP.PlayPauseButton", self )

	self.MediaTitle = vgui.Create( "MP.MediaTitle", self )
	self.MediaTitle:SetText( "Very Bad Video That Everyone Hates Included" )

	self.MediaTime = vgui.Create( "MP.MediaTime", self )

	-- TODO: remove testing defaults
	self.MediaTime:SetStartTime( os.time() )
	self.MediaTime:SetDuration( 43200 )

	self.FavBtn = vgui.Create( "MP.FavoriteButton", self )

	-- TODO: Only allow these buttons to show for admins
	self.SkipBtn = vgui.Create( "MP.SkipButton", self )
	self.RemoveBtn = vgui.Create( "MP.RemoveButton", self )

	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

end

function PANEL:Paint( w, h )

	local progress = 0.5 -- TODO: get actual progress

	local tbHalfHeight = ceil(self.TrackbarHeight / 2)
	local knobHalfHeight = ceil(self.KnobSize / 2)

	local pw = ceil(w * progress)

	surface.SetDrawColor( self.BgColor )
	surface.DrawRect( 0, 0, w, h )

	DisableClipping( true )

		-- trackbar progress
		surface.SetDrawColor( self.TrackbarProgressColor )
		surface.DrawRect( 0, h - tbHalfHeight, pw, self.TrackbarHeight )

		-- knob
		draw.RoundedBoxEx( knobHalfHeight,
			pw,
			h - tbHalfHeight - knobHalfHeight,
			self.KnobSize, self.KnobSize,
			color_white,
			true, true, true, true )

	DisableClipping( false )

end

function PANEL:PerformLayout()

	local w = self:GetWide()

	self:SetTall( 72 )

	self.PlayPauseBtn:CenterVertical()
	self.PlayPauseBtn:AlignLeft( self.Padding )

	self.MediaTitle:SizeToContents()
	self.MediaTitle:MoveRightOf( self.PlayPauseBtn, self.Padding )
	self.MediaTitle:AlignTop( self.Padding )

	self.MediaTime:InvalidateLayout()
	self.MediaTime:MoveRightOf( self.PlayPauseBtn, self.Padding )
	self.MediaTime:AlignBottom( self.Padding )

	self.FavBtn:AlignTop( self.Padding )
	self.FavBtn:AlignRight( self.Padding )

	self.RemoveBtn:AlignBottom( self.Padding )
	self.RemoveBtn:AlignRight( self.Padding )

	self.SkipBtn:MoveLeftOf( self.RemoveBtn, self.Padding )
	self.SkipBtn:AlignBottom( self.Padding )

	self.AddedByLbl:MoveLeftOf( self.SkipBtn, self.Padding )
	self.AddedByLbl:AlignBottom( self.Padding )

	local maxTitleWidth = self.FavBtn:GetPos() -
		( self.MediaTitle:GetPos() + 5 )

	if self.MediaTitle:GetWide() > maxTitleWidth then
		self.MediaTitle:SetWide( maxTitleWidth )
	end

end

derma.DefineControl( "MP.Playback", "", PANEL, "Panel" )


local PLAYPAUSE_BTN = {}

function PLAYPAUSE_BTN:Init()

	self.BaseClass.Init( self )

	self:SetSize( 19, 25 )
	self:SetImage( "mediaplayer/ui/play.png" )

	-- TODO: Set cursor type depending on whether player is admin/owner

end

function PLAYPAUSE_BTN:DoClick()

	-- TODO: Toggle between playing and pausing state if player is admin/owner

end

derma.DefineControl( "MP.PlayPauseButton", "", PLAYPAUSE_BTN, "DImageButton" )
