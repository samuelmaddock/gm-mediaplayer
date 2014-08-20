_G.spritesheet = {}

local icons = {}

--[[
	Icon format example:
	{
		name 	= "example-icon",  -- icon name
		mat 	= Material( "path/spritesheet.png" ), -- material for spritesheet
		w 		= 32, 	-- icon width
		h 		= 32, 	-- icon height
		xoffset = 64, 	-- x-axis offset relative to the texture
		yoffset = 128 	-- y-axis offset relative to the texture
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

	icon.matWidth = mat:Width()
	icon.matHeight = mat:Height()

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
	end

	return icon.w, icon.h
end


local verts = {{},{},{},{}}
local otw, oth, tw, th, uoffset, voffset, umax, vmax

function spritesheet.DrawIcon( name, x, y, w, h, color )
	local icon = icons[name]
	if not icon then
		MsgN( "Invalid icon '" .. tostring(name) .. "' passed into spritesheet.DrawIcon!" )
	end

	otw, oth = icon.matWidth, icon.matHeight
	uoffset, voffset = icon.xoffset / otw, icon.yoffset / oth
	umax, vmax = uoffset + (icon.w / otw), voffset + (icon.h / oth)

	verts[1].x = x
	verts[1].y = y
	verts[1].u = uoffset
	verts[1].v = voffset

	verts[2].x = x + w
	verts[2].y = y
	verts[2].u = umax
	verts[2].v = voffset

	verts[3].x = x + w
	verts[3].y = y + h
	verts[3].u = umax
	verts[3].v = vmax

	verts[4].x = x
	verts[4].y = y + h
	verts[4].u = uoffset
	verts[4].v = vmax

	if color then surface.SetDrawColor(color) end
	surface.SetMaterial(icon.mat)
	surface.DrawPoly(verts)
end
