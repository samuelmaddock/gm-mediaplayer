local IsValid = IsValid
local pairs = pairs
local RealTime = RealTime
local type = type
local IsKeyDown = input.IsKeyDown
local IsGameUIVisible = gui.IsGameUIVisible
local IsConsoleVisible = gui.IsConsoleVisible

_G.inputhook = {}

local HoldTime = 0.3

local LastPress = nil
local LastKey = nil
local KeyControls = {}

local function getEventArgs( a, b, c )
	if c == nil then
		return a, b
	else
		return b, c
	end
end

local function InputThink()

	if IsGameUIVisible() or IsConsoleVisible() then return end

	local dispatch, down, held

	for key, handles in pairs( KeyControls ) do
		for name, tbl in pairs( handles ) do

			dispatch = false

			if tbl.Enabled then

				-- Key hold (repeat press)
				if tbl.LastPress and tbl.LastPress + HoldTime < RealTime() then
					dispatch = true
					down = true
					held = true

					tbl.LastPress = RealTime()
				end

				-- Key release
				if not IsKeyDown( key ) then
					dispatch = true
					down = false

					tbl.Enabled = false
				end

			else

				-- Key press
				if IsKeyDown( key ) then
					dispatch = true
					down = true

					tbl.Enabled = true
					tbl.LastPress = RealTime()
				end

			end

			if dispatch then
				-- Use same behavior as the hook system
				if type(name) == 'table' then
					if IsValid(name) then
						tbl.Toggle( name, down, held )
					else
						handles[ name ] = nil
					end
				else
					tbl.Toggle( down, held )
				end
			end

		end
	end

end
hook.Add( "Think", "InputManagerThink", InputThink )

---
-- Adds a callback to be dispatched when a key is pressed.
--
-- @param key		`KEY_` enum.
-- @param name		Unique identifier or a valid object.
-- @param onToggle	Callback function.
--
function inputhook.Add( key, name, onToggle )

	if not (key and onToggle) then return end

	if not KeyControls[ key ] then
		KeyControls[ key ] = {}
	end

	KeyControls[ key ][ name ] = {
		Enabled = false,
		LastPress = 0,
		Toggle = onToggle
	}

end

function inputhook.AddKeyPress( key, name, onToggle )

	inputhook.Add( key, name, function( a, b, c )
		local down, held = getEventArgs(a, b, c)

		-- ignore if key down, but held OR key is not down
		if down then
			if held then return end
		else
			return
		end

		onToggle( a, b, c )
	end )

end

function inputhook.AddKeyRelease( key, name, onToggle )

	inputhook.Add( key, name, function( a, b, c )
		local down, held = getEventArgs(a, b, c)

		-- ignore if key is down
		if down then return end

		onToggle( a, b, c )
	end )

end

---
-- Removes a registered key callback.
--
-- @param key	`KEY_` enum.
-- @param name	Unique identifier or a valid object.
--
function inputhook.Remove( key, name )

	if not KeyControls[ key ] then return end

	KeyControls[ key ][ name ] = nil

end
