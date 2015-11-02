local PANEL = {}

DEFINE_BASECLASS( "Panel" )

local DEBUG = false

local JS_CallbackHack = [[(function(){
	var funcname = '%s';
	window[funcname] = function(){
		_gm[funcname].apply(_gm,arguments);
	}
})();]]

local FilterCVar = CreateClientConVar( "js_console_filter", 0, true, false )

local FILTER_ALL = 0
local FILTER_NONE = 1

--[[---------------------------------------------------------

-----------------------------------------------------------]]

function PANEL:Init()

	self.JS = {}
	self.Callbacks = {}

	self.URL = "about:blank"

	--
	-- Implement a console - because awesomium doesn't provide it for us anymore
	--
	local console_funcs = {'log','error','debug','warn','info'}
	for _, func in pairs(console_funcs) do
		self:AddFunction( "console", func, function(param)
			self:ConsoleMessage( param, func )
		end )
	end

	self:AddFunction( "gmod", "getUrl", function( url )
		self:SetURL( url )
	end )

end

function PANEL:Think()

	if self:IsLoading() then

		-- Call started loading
		if not self._loading then

			-- Get the page URL
			self:FetchPageURL()

			self._loading = true
			self:OnStartLoading()

		end

	else

		-- Call finished loading
		if self._loading then

			-- Get the page URL
			self:FetchPageURL()

			-- Hack to add window object callbacks
			if self.Callbacks.window then
				for funcname, callback in pairs(self.Callbacks.window) do
					self:RunJavascript( JS_CallbackHack:format(funcname) )
				end
			end

			self._loading = nil
			self:OnFinishLoading()

		end

		-- Run queued javascript
		if self.JS then
			for k, v in pairs( self.JS ) do
				self:RunJavascript( v )
			end
			self.JS = nil
		end

	end

	-- HACK: Poll page for URL change
	if not self._nextUrlPoll or self._nextUrlPoll < RealTime() then
		self:FetchPageURL()
		self._nextUrlPoll = RealTime() + 1
	end

end

function PANEL:FetchPageURL()
	local js = "gmod.getUrl(window.location.href);"
	self:RunJavascript(js)
end

function PANEL:GetURL()
	return self.URL
end

function PANEL:SetURL( url )
	local current = self.URL

	if current ~= url then
		self:OnURLChanged( url, current )
	end

	self.URL = url
end

function PANEL:OnURLChanged( new, old )

end


--[[---------------------------------------------------------
	Awesomium Override Functions
-----------------------------------------------------------]]

function PANEL:SetSize( w, h, fullscreen )

	if fullscreen then

		-- Cache fullscreen size
		local cw, ch = self:GetSize()
		self._OrigSize = { w = cw, h = ch }

		-- Render before the HUD
		self:ParentToHUD()

	elseif self._OrigSize then

		-- Restore cached size
		w = self._OrigSize.w
		h = self._OrigSize.h
		self._OrigSize = nil

		-- Reparent due to hud parented panels sometimes being inaccessible
		-- from Lua.
		self:SetParent( vgui.GetWorldPanel() )

	else
		self._OrigSize = nil
	end

	if not (w and h) then return end

	BaseClass.SetSize( self, w, h )

end

function PANEL:OpenURL( url )

	if DEBUG then
		print("DMediaPlayerHTML.OpenURL", url)
	end

	self:SetURL( url )

	BaseClass.OpenURL( self, url )

end

function PANEL:SetHTML( html )

	if DEBUG then
		print("DMediaPlayerHTML.SetHTML")
		print(html)
	end

	BaseClass.SetHTML( self, html )

end


--[[---------------------------------------------------------
	Window loading events
-----------------------------------------------------------]]

--
-- Called when the page begins loading
--
function PANEL:OnStartLoading()

end

--
-- Called when the page finishes loading all assets
--
function PANEL:OnFinishLoading()

end


--[[---------------------------------------------------------
	Lua => JavaScript queue

	This code only runs when the page is finished loading;
	this means all assets (images, CSS, etc.) must load first!
-----------------------------------------------------------]]

function PANEL:QueueJavascript( js )

	--
	-- Can skip using the queue if there's nothing else in it
	--
	if not ( self.JS or self:IsLoading() ) then
		return self:RunJavascript( js )
	end

	self.JS = self.JS or {}

	table.insert( self.JS, js )
	self:Think()

end

PANEL.QueueJavaScript = PANEL.QueueJavascript
PANEL.Call = PANEL.QueueJavascript


--[[---------------------------------------------------------
	Handle console logging from JavaScript
-----------------------------------------------------------]]

PANEL.ConsoleColors = {
	["default"]	= Color(255,160,255),
	["text"]	= Color(255,255,255),
	["error"]	= Color(235,57,65),
	["warn"]	= Color(227,181,23),
	["info"]	= Color(100,173,229),
}

function PANEL:ConsoleMessage( ... )

	local filterLevel = FilterCVar:GetInt()

	local args = {...}
	local msg = args[1]

	-- Three arguments are passed in if an error occured
	if #args == 3 and filterLevel > FILTER_ALL then

		local script = args[2]
		local linenum = args[3]
		local col = self.ConsoleColors.error

		local out = {
			"[JavaScript]",
			msg,
			",",
			script,
			":",
			linenum,
			"\n"
		}

		MsgC( col, table.concat(out, " ") )

	else

		if not isstring( msg ) then
			msg = "*js variable* (" .. type(msg) .. ": " .. tostring(msg) .. ")"
		end

		-- Run Lua from JavaScript console logging (POTENTIALLY HARMFUL!)
		--[[if msg:StartWith( "RUNLUA:" ) then
			local strLua = msg:sub( 8 )

			SELF = self
			RunString( strLua )
			SELF = nil

			return
		end]]

		-- Play a sound from JavaScript console logging
		if msg:StartWith( "PLAY:" ) then
			local soundpath = msg:sub( 7 )
			surface.PlaySound( soundpath )
			return
		end

		if filterLevel == FILTER_ALL then return end

		local func = args[2]

		-- Output console message with prefix
		local prefixColor = self.ConsoleColors.default
		local prefix = "[HTML"
		if func and func:len() > 0 and func ~= "log" then
			if self.ConsoleColors[func] then
				prefixColor = self.ConsoleColors[func]
			end
			prefix = prefix .. ":" .. func:upper()
		end
		prefix = prefix .. "] "

		MsgC( prefixColor, prefix )
		MsgC( self.ConsoleColors.text, msg, "\n" )

	end

end


--[[---------------------------------------------------------
	JavaScript callbacks
-----------------------------------------------------------]]

local JSObjects = {
	window	= "_gm",
	this	= "_gm",
	_gm		= "window"
}

--
-- Called by the engine when a callback function is called
--
function PANEL:OnCallback( obj, func, args )

	-- Hack for adding window callbacks
	obj = JSObjects[obj] or obj

	if not self.Callbacks[ obj ] then return end

	--
	-- Use AddFunction to add functions to this.
	--
	local f = self.Callbacks[ obj ][ func ]

	if ( f ) then
		return f( unpack( args ) )
	end

end

--
-- Add a function to Javascript
--
function PANEL:AddFunction( obj, funcname, func )

	-- Hack for adding window callbacks
	-- obj = JSObjects[obj] or obj

	if obj == "this" then
		obj = "window"
	end

	-- Create the `object` if it doesn't exist
	if not self.Callbacks[ obj ] then
		self:NewObject( obj )
		self.Callbacks[ obj ] = {}
	end

	-- This creates the function in javascript (which redirects to c++ which calls OnCallback here)
	self:NewObjectCallback( JSObjects[obj] or obj, funcname )

	-- Store the function so OnCallback can find it and call it
	self.Callbacks[ obj ][ funcname ] = func

end


--[[---------------------------------------------------------
	Remove Scrollbars
-----------------------------------------------------------]]

local JS_RemoveScrollbars = "document.body.style.overflow = 'hidden';"

function PANEL:RemoveScrollbars()
	self:QueueJavascript(JS_RemoveScrollbars)
end


--[[---------------------------------------------------------
	Compatibility functions
-----------------------------------------------------------]]

function PANEL:OpeningURL( url )
end

function PANEL:FinishedURL( url )
end

derma.DefineControl( "DMediaPlayerHTML", "", PANEL, "Awesomium" )
