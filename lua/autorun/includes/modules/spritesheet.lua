local math = math
local surface = surface
local table = table

_G.spritesheet = {}

local icons = {}

--[[
	Icon format example:
	{
		name 	= "example-icon",  -- icon name
		mat 	= Material( "path/spritesheet.png" ), -- material for spritesheet
		w 		= 32, 	-- icon width
		h 		= 32, 	-- icon height
		xoffset = 64, 	-- x-axis offset relative to the texture (optional)
		yoffset = 128 	-- y-axis offset relative to the texture (optional)
	}
]]

local function registerIcon( icon )
	local name = icon.name
	if not name then
		MsgN( "Icon has no name" )
		return false
	end

	local mat = icon.mat
	if not mat or mat:IsError() then
		MsgN( "Icon '" .. name .. "' uses an invalid material '" .. mat:GetName() .. "'" )
		return false
	end

	-- calculate texture UV min/max coordinates
	local mw, mh = mat:Width(), mat:Height()
	local xoffset, yoffset = icon.xoffset or 0, icon.yoffset or 0
	local umin, vmin = xoffset / mw, yoffset / mh
	local umax, vmax = umin + (icon.w / mw), vmin + (icon.h / mh)

	icon.umin = umin
	icon.umax = umax
	icon.vmin = vmin
	icon.vmax = vmax

	-- remove unneeded properties
	icon.xoffset = nil
	icon.yoffset = nil

	return true
end

---
-- Registers a single or list of icons.
--
function spritesheet.Register( iconTbl )
	iconTbl = table.Copy( iconTbl or {} )

	-- passed in single icon; wrap inside table for iteration
	if #iconTbl == 0 then
		iconTbl = { iconTbl }
	end

	-- register all icons
	for _, icon in ipairs(iconTbl) do
		local valid = registerIcon( icon )
		if valid then
			icons[icon.name] = icon
		end
	end

	return true
end

---
-- Gets the icon's width and height
--
function spritesheet.GetIconSize( name )
	local icon = icons[name]
	if not icon then
		MsgN( "Invalid icon '" .. tostring(name) .. "' passed into spritesheet.GetIconSize!" )
		return
	end

	return icon.w, icon.h
end

function spritesheet.DrawIcon( name, x, y, w, h, color )
	local icon = icons[name]
	if not icon then
		MsgN( "Invalid icon '" .. tostring(name) .. "' passed into spritesheet.DrawIcon!" )
		return
	end

	if color then surface.SetDrawColor(color) end
	surface.SetMaterial(icon.mat)
	surface.DrawTexturedRectUV( x, y, w, h,
		icon.umin, icon.vmin, icon.umax, icon.vmax )
end
