if browserpool then return end -- ignore Lua refresh

local table = table
local vgui = vgui

_G.browserpool = {}

---
-- Debug variable which will allow outputting messages if enabled.
-- @type boolean
--
local DEBUG = true

---
-- Array of available, pooled browsers
-- @type table
--
local available = {}

---
-- Array of active, pooled browsers.
-- @type table
--
local active = {}

---
-- Array of pending requests for a browser.
-- @type table
--
local pending = {}

---
-- Minimum number of active browsers to be pooled.
-- @type Number
--
local numMin = 2

---
-- Maximum number of active browsers to be pooled.
-- @type Number
--
local numMax = 4

---
-- Number of currently active browsers.
-- @type Number
--
local numActive = 0

---
-- Number of currently pending browser requests.
-- @type Number
--
local numPending = 0

---
-- Number of total browser requests.
-- @type Number
--
local numRequests = 0

---
-- Default URL to set browsers on setup/teardown.
-- @type String
--
local defaultUrl = "data:text/html,"

---
-- JavaScript code to remove an object's property.
-- @type String
--
local JS_RemoveProp = "delete %s.%s;"

---
-- Helper function to setup/teardown a browser panel.
--
-- @param panel?	Browser panel to be cleaned up.
-- @return Panel	DMediaPlayerHTML panel instance.
--
local function setupPanel( panel )

	-- Create a new panel if it wasn't passed in
	if panel then
		panel:Stop()
	else
		panel = vgui.Create("DMediaPlayerHTML")
	end

	-- Hide panel
	-- panel:SetSize(0, 0)
	panel:SetPos(0, 0)

	-- Disable input
	panel:SetKeyBoardInputEnabled(false)
	panel:SetMouseInputEnabled(false)

	-- Browser panels are usually manually drawn, use a regular panel if not
	panel:SetPaintedManually(true)

	-- Fix for panel not getting cleared after 3/2017 update
	panel:SetHTML( "" )

	-- Set default URL
	panel:OpenURL( defaultUrl )

	-- Remove any added function callbacks
	for obj, tbl in pairs(panel.Callbacks) do
		if obj ~= "console" then
			for funcname, _ in pairs(tbl) do
				panel:QueueJavascript(JS_RemoveProp:format(obj, funcname))
			end
		end
	end

	return panel

end

---
-- Local function for removing cancelled browser promises via closures.
--
-- @param Promise	Browser bromise.
-- @return Boolean	Success status.
--
local function removePromise( promise )
	local id = promise:GetId()

	if not pending[id] then
		ErrorNoHalt( "browserpool: Failed to remove promise.\n" )
		print( promise, id )
		debug.Trace()
		return false
	end

	pending[id] = nil
	numPending = numPending - 1

	return true
end

---
-- Browser promise for resolving browser requests when there isn't an available
-- browser at the time of request.
--
local BrowserPromise = {}
local BrowserPromiseMeta = { __index = BrowserPromise }

function BrowserPromise:New( callback, id )
	return setmetatable(
		{ __cb = callback, __id = id or -1 },
		BrowserPromiseMeta
	)
end

function BrowserPromise:GetId()
	return self.__id
end

function BrowserPromise:Resolve( value )
	self.__cb(value)
end

function BrowserPromise:Cancel( reason )
	self.__cb(false, reason)
	removePromise(self)
end

---
-- Retrieves an available browser panel from the pool. Otherwise, a new panel
-- will be created.
--
-- @return Panel	DMediaPlayerHTML panel instance.
--
function browserpool.get( callback )

	numRequests = numRequests + 1

	if DEBUG then
		print( string.format("browserpool: get [Active: %s][Available: %s][Pending: %s]",
			numActive, #available, numPending ) )
	end

	local panel

	-- Check if there's an available panel
	if #available > 0 then

		panel = table.remove( available )
		table.insert( active, panel )

		callback( panel )

	elseif numActive < numMax then -- create a new panel

		panel = setupPanel()
		numActive = numActive + 1

		if DEBUG then
			print( "browserpool: Spawned new browser [Active: "..numActive.."]" )
		end

		table.insert( active, panel )
		callback( panel )

	else -- wait for an available browser

		local promise = BrowserPromise:New( callback, numRequests )

		pending[numRequests] = promise
		numPending = numPending + 1

		return promise

	end

end

---
-- Releases the given browser panel from the active pool.
--
-- Remember to unset references to the browser instance after releasing:
--		browserpool.release( self.Browser )
--		self.Browser = nil
--
-- @param panel		Browser panel to be released.
-- @return boolean	Whether the panel was successfully removed.
--
function browserpool.release( panel, destroy )

	if not panel then return end

	local key = table.KeyFromValue( active, panel )

	-- Unable to find active browser panel
	if not key then
		ErrorNoHalt( "browserpool: Attempted to release unactive browser.\n" )
		debug.Trace()

		-- Remove browser even if the request was invalid
		if ValidPanel(panel) then
			panel:Remove()
		end

		return false
	end

	-- Resolve an open promise if one exists
	if numPending > 0 and not destroy then

		-- Get the earliest request first
		local id = table.GetFirstKey( pending )
		local promise = pending[id]

		-- Cleanup panel
		setupPanel( panel )

		promise:Resolve( panel )
		removePromise( promise )

	else

		if not table.remove( active, key ) then
			ErrorNoHalt( "browserpool: Failed to remove panel from active browsers.\n" )
			debug.Trace()

			-- Remove browser even if the request was invalid
			if ValidPanel(panel) then
				panel:Remove()
			end

			return false
		end

		-- Remove panel if there are more active than the minimum pool size
		if numActive > numMin then

			panel:Remove()
			numActive = numActive - 1

			if DEBUG then
				print( "browserpool: Destroyed browser [Active: "..numActive.."]" )
			end

		elseif not destroy then

			-- Cleanup panel
			setupPanel( panel )

			-- Add to the pool
			table.insert( available, panel )

			if DEBUG then
				print( "browserpool: Pooled browser [Active: "..numActive.."]" )
			end

		end

	end

	return true

end
