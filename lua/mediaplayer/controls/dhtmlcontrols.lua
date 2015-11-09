--[[__                                       _
 / _| __ _  ___ ___ _ __  _   _ _ __   ___| |__
| |_ / _` |/ __/ _ \ '_ \| | | | '_ \ / __| '_ \
|  _| (_| | (_|  __/ |_) | |_| | | | | (__| | | |
|_|  \__,_|\___\___| .__/ \__,_|_| |_|\___|_| |_|
                   |_| 2010 --]]

--[[---------------------------------------------------------
	Browser controls
-----------------------------------------------------------]]

local urllib = url

local PANEL = {}

AccessorFunc( PANEL, "HomeURL", "HomeURL", FORCE_STRING )

function PANEL:Init()

	local ButtonSize = 32
	local Margins = 2
	local Spacing = 0

	self.BackButton = vgui.Create( "DIconButton", self )
	self.BackButton:SetIcon( "mp-back" )
	self.BackButton:SetSize( ButtonSize, ButtonSize )
	self.BackButton:Dock( LEFT )
	self.BackButton:DockMargin( Spacing*3, Margins, Spacing, Margins )
	self.BackButton.DoClick = function()
		self.BackButton:SetDisabled( true )
		self:HTMLBack()
		self.Cur = self.Cur - 1
		self.Navigating = true
	end

	self.ForwardButton = vgui.Create( "DIconButton", self )
	self.ForwardButton:SetIcon( "mp-forward" )
	self.ForwardButton:SetSize( ButtonSize, ButtonSize )
	self.ForwardButton:Dock( LEFT )
	self.ForwardButton:DockMargin( Spacing, Margins, Spacing, Margins )
	self.ForwardButton.DoClick = function()
		self.ForwardButton:SetDisabled( true )
		self:HTMLForward()
		self.Cur = self.Cur + 1
		self.Navigating = true
	end

	self.RefreshButton = vgui.Create( "MPRefreshButton", self )
	self.RefreshButton:SetSize( ButtonSize, ButtonSize )
	self.RefreshButton:Dock( LEFT )
	self.RefreshButton:DockMargin( Spacing, Margins, Spacing, Margins )
	self.RefreshButton.DoClick = function()
		self.RefreshButton:SetDisabled( true )
		self.Refreshing = true
		self.HTML:Refresh()
	end

	self.HomeButton = vgui.Create( "DIconButton", self )
	self.HomeButton:SetIcon( "mp-home" )
	self.HomeButton:SetSize( ButtonSize, ButtonSize )
	self.HomeButton:Dock( LEFT )
	self.HomeButton:DockMargin( Spacing, Margins, Spacing*3, Margins )
	self.HomeButton.DoClick = function()
		self.HTML:Stop()
		self.HTML:OpenURL( self:GetHomeURL() )
	end

	self.AddressBar = vgui.Create( "DTextEntry", self )
	self.AddressBar:Dock( FILL )
	self.AddressBar:DockMargin( Spacing, Margins * 3, Spacing, Margins * 3 )
	self.AddressBar.OnEnter = function()
		self.HTML:Stop()
		self.HTML:OpenURL( self.AddressBar:GetValue() )
	end

	local AddrSetText = self.AddressBar.SetText
	self.AddressBar.SetText = function (panel, text)
		AddrSetText( panel, urllib.unescape(text) )
	end

	self.RequestButton = vgui.Create( "MPRequestButton", self )
	self.RequestButton:SetDisabled( true )
	self.RequestButton:Dock( RIGHT )
	self.RequestButton:DockMargin( 8, 4, 8, 4 )
	self.RequestButton.DoClick = function()
		MediaPlayer.MenuRequest( self.HTML:GetURL() )
	end

	self:SetHeight( ButtonSize + Margins * 2 )

	self.NavStack = 0
	self.History = {}
	self.Cur = 1

	-- This is the default look, feel free to change it on your created control :)
	self:SetButtonColor( Color( 250, 250, 250, 200 ) )
	self.BorderSize = 4
	self.BackgroundColor = Color( 33, 33, 33, 255 )
	self:SetHomeURL( "http://www.google.com" )

end

function PANEL:SetHTML( html )

	self.HTML = html

	if ( html.URL ) then
		self:SetHomeURL( self.HTML.URL )
	end

	self.RefreshButton:SetHTML(html)
	self.AddressBar:SetText( self:GetHomeURL() )
	self:UpdateHistory( self:GetHomeURL() )

	local OnFinishLoading = self.HTML.OnFinishLoading
	self.HTML.OnFinishLoading = function( panel )

		local url = self.HTML:GetURL()

		self.AddressBar:SetText( url )
		self:FinishedLoading()

		if OnFinishLoading then
			OnFinishLoading( panel )
		end

	end

	local OnURLChanged = self.HTML.OnURLChanged
	self.HTML.OnURLChanged = function ( panel, url )

		self.AddressBar:SetText( url )
		self.NavStack = self.NavStack + 1
		self:StartedLoading()
		self:UpdateHistory( url )

		-- Check for valid URL
		local isValidUrl = MediaPlayer.ValidUrl( url )
		self.RequestButton:SetDisabled( not isValidUrl )

		if ( OnURLChanged ) then
			OnURLChanged( panel, url )
		end

	end

end

function PANEL:UpdateHistory( url )

	--print( "PANEL:UpdateHistory", url )
	self.Cur = math.Clamp( self.Cur, 1, table.Count( self.History ) )

	local top = self.History[self.Cur]

	-- Ignore page refresh
	if top == url then
		return
	end

	if ( self.Refreshing ) then

		self.Refreshing = false
		self.RefreshButton:SetDisabled( false )
		return

	end

	if ( self.Navigating ) then

		self.Navigating = false
		self:UpdateNavButtonStatus()
		return

	end

	-- We were back in the history queue, but now we're navigating
	-- So clear the front out so we can re-write history!!
	if ( self.Cur < table.Count( self.History ) ) then

		for i = self.Cur+1, table.Count( self.History ) do
			self.History[i] = nil
		end

	end

	self.Cur = table.insert( self.History, url )

	self:UpdateNavButtonStatus()

end

function PANEL:HTMLBack()
	if self.Cur <= 1 then return end
	self.Cur = self.Cur - 1
	self.HTML:OpenURL( self.History[ self.Cur ], true )
end

function PANEL:HTMLForward()
	if self.Cur == #self.History then return end
	self.Cur = self.Cur + 1
	self.HTML:OpenURL( self.History[ self.Cur ], true )
end

function PANEL:FinishedLoading()

	self.RefreshButton:SetDisabled( false )

end

function PANEL:StartedLoading()

	self.RefreshButton:SetDisabled( true )

end

function PANEL:UpdateNavButtonStatus()

	--print( self.Cur, table.Count( self.History ) )

	self.ForwardButton:SetDisabled( self.Cur >= table.Count( self.History ) )
	self.BackButton:SetDisabled( self.Cur == 1 )

end

function PANEL:SetButtonColor( col )

	self.BackButton:SetColor( col )
	self.ForwardButton:SetColor( col )
	self.RefreshButton:SetColor( col )
	self.HomeButton:SetColor( col )

end

function PANEL:Paint()

	draw.RoundedBoxEx( self.BorderSize, 0, 0, self:GetWide(), self:GetTall(), self.BackgroundColor, true, true, false, false )

end

derma.DefineControl( "MPHTMLControls", "", PANEL, "Panel" )


--[[---------------------------------------------------------
	Media request button
	Embedded inside of the browser controls.
-----------------------------------------------------------]]

local RequestButton = {}

-- RequestButton.DisabledColor = Color(189, 195, 199)
-- RequestButton.DepressedColor = Color(192, 57, 43)
RequestButton.HoverColor = Color(192, 57, 43)
RequestButton.DefaultColor = Color(231, 76, 60)
RequestButton.DisabledColor = RequestButton.DefaultColor
RequestButton.DepressedColor = RequestButton.DefaultColor

RequestButton.DefaultTextColor = Color(236, 236, 236)
RequestButton.DisabledTextColor = Color(158, 48, 36)

function RequestButton:Init()
	DButton.Init(self)

	local ButtonSize = 32

	self:SetSize( ButtonSize*8, ButtonSize )
	self:SetFont( "MediaRequestButton" )

	self:SetDisabled( true )
end

function RequestButton:SetDisabled( disabled )
	if disabled then
		self:SetText( "SEARCH FOR MEDIA" )
	else
		self:SetText( "REQUEST URL" )
	end

	DButton.SetDisabled( self, disabled )
end

function RequestButton:UpdateColours()
	if self:GetDisabled() then
		return self:SetTextStyleColor( self.DisabledTextColor )
	else
		return self:SetTextStyleColor( self.DefaultTextColor )
	end
end

function RequestButton:Paint( w, h )
	local col

	if self:GetDisabled() then
		col = self.DisabledColor
	elseif self.Depressed or self.m_bSelected then
		col = self.DepressedColor
	elseif self:IsHovered() then
		col = self.HoverColor
	else
		-- Pulse effect
		local h, s, v = ColorToHSV( self.DefaultColor )
		v = 0.7 + math.sin(RealTime() * 10) * 0.3

		col = HSVToColor(h,s,v)
	end

	draw.RoundedBox( 2, 0, 0, w, h, col )
end

derma.DefineControl( "MPRequestButton", "", RequestButton, "DButton" )


--[[---------------------------------------------------------
	Media refresh button
	Embedded inside of the browser controls.
-----------------------------------------------------------]]

local RefreshButton = {}

AccessorFunc( RefreshButton, "HTML", "HTML" )

function RefreshButton:Init()
	self.BaseClass.Init( self )
	self:SetIcon( "mp-refresh" )
	self:SetText( "" )
end

local Matrix = Matrix
local vecTranslate = Vector()
local angRotate = Angle()

function RefreshButton:Paint( w, h )

	if ValidPanel(self.HTML) and self.HTML:IsLoading() then
		local x, y = self:LocalToScreen(0,0)

		vecTranslate.x = x + w / 2
		vecTranslate.y = y + h / 2

		angRotate.y = RealTime() * 512

		local mat = Matrix()
		mat:Translate( vecTranslate )
		mat:Rotate( angRotate )
		mat:Translate( -vecTranslate )
		cam.PushModelMatrix( mat )
		self._PushedMatrix = true
	end

	self.BaseClass.Paint( self, w, h )

end

function RefreshButton:PaintOver()

	if self._PushedMatrix then
		cam.PopModelMatrix()
		self._PushedMatrix = nil
	end

end

derma.DefineControl( "MPRefreshButton", "", RefreshButton, "DIconButton" )
