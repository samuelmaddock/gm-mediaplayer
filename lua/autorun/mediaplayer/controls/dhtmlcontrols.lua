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

	self.BackButton = vgui.Create( "DImageButton", self )
	self.BackButton:SetSize( ButtonSize, ButtonSize )
	self.BackButton:SetMaterial( "gui/HTML/back" )
	self.BackButton:Dock( LEFT )
	self.BackButton:DockMargin( Spacing*3, Margins, Spacing, Margins )
	self.BackButton.DoClick = function()
		self.BackButton:SetDisabled( true )
		self:HTMLBack()
		self.Cur = self.Cur - 1
		self.Navigating = true
	end

	self.ForwardButton = vgui.Create( "DImageButton", self )
	self.ForwardButton:SetSize( ButtonSize, ButtonSize )
	self.ForwardButton:SetMaterial( "gui/HTML/forward" )
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

	self.HomeButton = vgui.Create( "DImageButton", self )
	self.HomeButton:SetSize( ButtonSize, ButtonSize )
	self.HomeButton:SetMaterial( "gui/HTML/home" )
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

	local OldFunc = self.HTML.OpeningURL
	self.HTML.OpeningURL = function( panel, url, target, postdata, bredirect )

		self.NavStack = self.NavStack + 1
		self.AddressBar:SetText( url )
		self:StartedLoading()

		if ( OldFunc ) then
			OldFunc( panel, url, target, postdata, bredirect )
		end

		self:UpdateHistory( url )

	end

	local OldFunc = self.HTML.FinishedURL
	self.HTML.FinishedURL = function( panel, url )

		self.AddressBar:SetText( url )
		self:FinishedLoading()

		-- Check for valid URL
		if MediaPlayer.ValidUrl( url ) then
			self.RequestButton:SetDisabled( false )
		else
			self.RequestButton:SetDisabled( true )
		end

		if ( OldFunc ) then
			OldFunc( panel, url )
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
		self:SetText( "FIND A VIDEO" )
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

local LoadingTexture = surface.GetTextureID("gui/html/refresh")

function RefreshButton:Init()
	DButton.Init(self)

	self:SetText( "" )
	self.TextureColor = Color(255,255,255,255)
end

function RefreshButton:SetColor( color )
	self.TextureColor = color
end

function RefreshButton:Paint( w, h )
	local ang = 0

	if ValidPanel(self.HTML) and self.HTML:IsLoading() then
		ang = RealTime() * -512
	end

	surface.SetDrawColor(self.TextureColor)
	surface.SetTexture(LoadingTexture)
	surface.DrawTexturedRectRotated( w/2, h/2, w, h, ang )
end

derma.DefineControl( "MPRefreshButton", "", RefreshButton, "DButton" )
