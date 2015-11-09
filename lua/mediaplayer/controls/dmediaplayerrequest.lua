local PANEL = {}
PANEL.HistoryWidth = 300
PANEL.BackgroundColor = Color(22, 22, 22)

local CloseTexture = Material( "theater/close.png" )

AccessorFunc( PANEL, "m_MediaPlayer", "MediaPlayer" )

function PANEL:Init()

	self:SetPaintBackgroundEnabled( true )
	self:SetFocusTopLevel( true )

	local w = math.Clamp( ScrW() - 100, 800, 1152 + self.HistoryWidth )
	local h = ScrH()
	if h > 800 then
		h = h * 3/4
	elseif h > 600 then
		h = h * 7/8
	end
	self:SetSize( w, h )

	self.CloseButton = vgui.Create( "DIconButton", self )
	self.CloseButton:SetSize( 32, 32 )
	self.CloseButton:SetIcon( "mp-close" )
	self.CloseButton:SetColor( Color( 250, 250, 250, 200 ) )
	self.CloseButton:SetZPos( 5 )
	self.CloseButton:SetText( "" )
	self.CloseButton.DoClick = function ( button )
		self:Close()
	end

	self.BrowserContainer = vgui.Create( "DPanel", self )
	self.BrowserContainer:Dock( FILL )

	self.Browser = vgui.Create( "DMediaPlayerHTML", self.BrowserContainer )
	self.Browser:Dock( FILL )

	self.Browser:AddFunction( "gmod", "requestUrl", function (url)
		MediaPlayer.MenuRequest( url )
		self:Close()
	end )

	self.Browser:AddFunction( "gmod", "openUrl", function (url)
		gui.OpenURL( url )
	end )

	self.Browser:AddFunction( "gmod", "getServices", function ()
		local mp = self.m_MediaPlayer

		if mp then
			self:SendServices( mp )
		end
	end )

	local requestUrl = MediaPlayer.GetConfigValue( 'request.url' )
	self.Browser:OpenURL( requestUrl )

	self.Controls = vgui.Create( "MPHTMLControls", self.BrowserContainer )
	self.Controls:Dock( TOP )
	self.Controls:DockPadding( 0, 0, 32, 0 )
	self.Controls:SetHTML( self.Browser )
	self.Controls.BorderSize = 0

	-- Listen for all mouse press events
	hook.Add( "GUIMousePressed", self, self.OnGUIMousePressed )

end

local function GetServiceIDs( mp )
	-- Send list of supported services to the request page for filtering out
	-- service icons
	local serviceIDs = mp:GetSupportedServiceIDs()
	serviceIDs = table.concat( serviceIDs, "," )

	return serviceIDs
end

function PANEL:SendServices( mp )
	local js = "if (typeof window.setServices === 'function') { setServices('%s'); }"
	js = js:format( GetServiceIDs(mp) )

	self.Browser:RunJavascript( js )
	self.Browser:QueueJavascript( js )
end

function PANEL:SetMediaPlayer( mp )
	self.m_MediaPlayer = mp

	self:SendServices( mp )
end

function PANEL:Paint( w, h )

	-- Draw background for fully transparent webpages
	surface.SetDrawColor( self.BackgroundColor )
	surface.DrawRect( 0, 0, w, h )

	return true

end

function PANEL:OnRemove()
	hook.Remove( "GUIMousePressed", self )
end

function PANEL:Close()
	if ValidPanel(self.Browser) then
		self.Browser:Remove()
	end

	self:OnClose()
	self:Remove()
end

function PANEL:OnClose()

end

function PANEL:CheckClose()

	local x, y = self:CursorPos()

	-- Remove panel if mouse is clicked outside of itself
	if not (gui.IsGameUIVisible() or gui.IsConsoleVisible()) and
		( x < 0 or x > self:GetWide() or y < 0 or y > self:GetTall() ) then
		self:Close()
	end

end

function PANEL:PerformLayout( w, h )

	self.CloseButton:SetPos( w - 36, 2 )

end

---
-- Close the panel when the mouse has been pressed outside of the panel.
--
function PANEL:OnGUIMousePressed( key )

	if key == MOUSE_LEFT then
		self:CheckClose()
	end

end

vgui.Register( "MPRequestFrame", PANEL, "EditablePanel" )
