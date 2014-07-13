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

local function dispatch(name, func, down, held)
	-- Use same behavior as the hook system
	if type(name) == 'table' then
		if IsValid(name) then
			func( name, down, held )
		else
			handles[ name ] = nil
		end
	else
		func( down, held )
	end
end

local function InputThink()

	if IsGameUIVisible() or IsConsoleVisible() then return end

	for key, handles in pairs( KeyControls ) do
		for name, tbl in pairs( handles ) do

			if tbl.Enabled then

				-- Key hold (repeat press)
				if tbl.LastPress and tbl.LastPress + HoldTime < RealTime() then
					dispatch(name, tbl.Toggle, true, true)
					tbl.LastPress = RealTime()
				end

				-- Key release
				if not IsKeyDown( key ) then
					dispatch(name, tbl.Toggle, false)
					tbl.Enabled = false
				end

			else

				-- Key press
				if IsKeyDown( key ) then
					dispatch(name, tbl.Toggle, true)
					tbl.Enabled = true
					tbl.LastPress = RealTime()
				end

			end

		end
	end

end
hook.Add( "Think", "InputManagerThink", InputThink )

function control.Add( key, name, onToggle )

	if not (key and onToggle) then return end

	if not KeyControls[ key ] then
		KeyControls[ key ] = {}
	end

	KeyControls[ key ][ name ] = {
		Enabled = false,
		LastPress = 0,
		Toggle = onToggle
		--[[Toggle = function(...)
			local msg, err = pcall( onToggle, ... )
			if err then
				print( "ERROR: " .. msg )
			end
		end]]
	}

end

function control.Remove( key, name )

	if not KeyControls[ key ] then return end

	KeyControls[ key ][ name ] = nil

end
