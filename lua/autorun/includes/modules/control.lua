local IsValid = IsValid
local pairs = pairs
local RealTime = RealTime
local type = type
local IsKeyDown = input.IsKeyDown
local IsGameUIVisible = gui.IsGameUIVisible
local IsConsoleVisible = gui.IsConsoleVisible

_G.control = {}

local HoldTime = 0.3

local LastPress = nil
local LastKey = nil
local KeyControls = {}

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
function control.Add( key, name, onToggle )

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

---
-- Removes a registered key callback.
--
-- @param key	`KEY_` enum.
-- @param name	Unique identifier or a valid object.
--
function control.Remove( key, name )

	if not KeyControls[ key ] then return end

	KeyControls[ key ][ name ] = nil

end
