local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

PANEL.Height = 72

PANEL.BgColor = Color( 13, 41, 62 )
PANEL.Padding = 12
PANEL.BtnPadding = 4

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
	if true then
		self.SkipBtn = vgui.Create( "MP.SkipButton", self )
		self.RemoveBtn = vgui.Create( "MP.RemoveButton", self )

		self.OwnerActions = true
	end

	self.AddedByLbl = vgui.Create( "MP.AddedBy", self )

	self.NextThink = 0

end

function PANEL:Think()

	local rt = RealTime()

	if rt > self.NextThink then
		-- Perform layout every second for when the media label changes width
		self:InvalidateLayout()
		self.NextThink = rt + 1
	end


end

function PANEL:OnMediaChanged( media )

	if media then
		local title = media:Title()
		self.MediaTitle:SetText( title )
		self.MediaTitle:SetToolTip( title )

		self.MediaTime:SetStartTime( media:StartTime() )
		self.MediaTime:SetDuration( media:Duration() )

		self.AddedByLbl:SetPlayer( media:GetOwner(), media:OwnerName(), media:OwnerSteamID() )

		self.AddedByLbl:Show()
		self.FavBtn:Show()
		if self.SkipBtn then self.SkipBtn:Show() end
		if self.RemoveBtn then self.RemoveBtn:Show() end
	else
		self.MediaTitle:SetText( "No media playing" )
		self.MediaTitle:SetTooltip( "" )

		self.MediaTime:Clear()

		self.AddedByLbl:Hide()
		self.FavBtn:Hide()
		if self.SkipBtn then self.SkipBtn:Hide() end
		if self.RemoveBtn then self.RemoveBtn:Hide() end
	end

	self:InvalidateLayout()

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

	self:SetTall( self.Height )

	self.PlayPauseBtn:CenterVertical()
	self.PlayPauseBtn:AlignLeft( self.Padding )

	self.MediaTitle:SizeToContents()
	self.MediaTitle:MoveRightOf( self.PlayPauseBtn, self.Padding )
	self.MediaTitle:AlignTop( self.Padding )

	self.MediaTime:InvalidateLayout()
	self.MediaTime:MoveRightOf( self.PlayPauseBtn, self.Padding )
	self.MediaTime:AlignBottom( self.Padding - 2 )

	self.FavBtn:AlignTop( self.Padding )
	self.FavBtn:AlignRight( self.Padding )

	-- 'ADDED BY Name' needs to fit between the media time and the rightmost
	-- buttons.
	local addedByMaxWidth

	if self.OwnerActions then

		self.RemoveBtn:AlignBottom( self.Padding )
		self.RemoveBtn:AlignRight( self.Padding )

		self.SkipBtn:MoveLeftOf( self.RemoveBtn, self.BtnPadding )
		self.SkipBtn:AlignBottom( self.Padding )

		addedByMaxWidth = ( self.SkipBtn:GetPos() - self.BtnPadding ) -
			( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.Padding )

	else

		addedByMaxWidth = ( w - self.Padding ) -
			( self.MediaTime:GetPos() + self.MediaTime:GetWide() + self.Padding )

	end

	self.AddedByLbl:SetMaxWidth( addedByMaxWidth )
	self.AddedByLbl:AlignBottom( self.Padding )

	if self.OwnerActions then
		self.AddedByLbl:MoveLeftOf( self.SkipBtn, self.BtnPadding )
	else
		self.AddedByLbl:AlignRight( self.Padding )
	end

	local maxTitleWidth = ( self.FavBtn:GetPos() - self.BtnPadding ) -
		( self.MediaTitle:GetPos() )

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
