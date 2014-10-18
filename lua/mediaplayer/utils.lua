if SERVER then AddCSLuaFile() end

local file = file
local math = math
local ceil = math.ceil
local floor = math.floor
local Round = math.Round
local log = math.log
local pow = math.pow
local format = string.format
local tostring = tostring
local IsValid = IsValid


local utils = {}

---
-- Ceil the given number to the largest power of two.
--
function utils.CeilPower2(n)
	return pow(2, ceil(log(n) / log(2)))
end

---
-- Method for easily grabbing a value from a table without checking that each
-- fragment exists.
--
-- @param tbl Table
-- @param key e.g. "json.key.fragments"
--
function utils.TableLookup( tbl, key )
	local fragments = string.Split(key, '.')
	local value = tbl

	for _, fragment in ipairs(fragments) do
		value = value[fragment]

		if not value then
			return nil
		end
	end

	return value
end

---
-- Formats the number of seconds to a string.
-- e.g. 3612 => 24:12
--
function utils.FormatSeconds(sec)
	sec = Round(sec)

	local hours = floor(sec / 3600)
	local minutes = floor((sec % 3600) / 60)
	local seconds = sec % 60

	if minutes < 10 then
		minutes = "0" .. tostring(minutes)
	end

	if seconds < 10 then
		seconds = "0" .. tostring(seconds)
	end

	if hours > 0 then
		return format("%s:%s:%s", hours, minutes, seconds)
	else
		return format("%s:%s", minutes, seconds)
	end
end

if CLIENT then

	local CeilPower2 = utils.CeilPower2
	local SetDrawColor = surface.SetDrawColor
	local SetMaterial = surface.SetMaterial
	local DrawTexturedRect = surface.DrawTexturedRect

	local color_white = color_white

	function utils.DrawHTMLPanel( panel, w, h )
		if not (IsValid( panel ) and w and h) then return end

		panel:UpdateHTMLTexture()

		local pw, ph = panel:GetSize()

		-- Convert to scalar
		w = w / pw
		h = h / ph

		-- Fix for non-power-of-two html panel size
		pw = CeilPower2(pw)
		ph = CeilPower2(ph)

		SetDrawColor( color_white )
		SetMaterial( panel:GetHTMLMaterial() )
		DrawTexturedRect( 0, 0, w * pw, h * ph )
	end

end

_G.MediaPlayerUtils = utils
