include "shared.lua"

local draw = draw
local surface = surface
local Start3D2D = cam.Start3D2D
local End3D2D = cam.End3D2D

local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local color_white = color_white

local StaticMaterial = Material( "theater/STATIC" )
local TextScale = 700

function ENT:Draw()
	self:DrawModel()

	local mp = self:GetMediaPlayer()

	if not mp then
		self:DrawMediaPlayerOff()
	end
end

function ENT:DrawMediaPlayerOff()
	local w, h, pos, ang = self:GetMediaPlayerPosition()

	Start3D2D( pos, ang, 1 )
		surface.SetDrawColor( color_white )
		surface.SetMaterial( StaticMaterial )
		surface.DrawTexturedRect( 0, 0, w, h )
	End3D2D()

	local scale = w / TextScale
	Start3D2D( pos, ang, scale )
		local tw, th = w / scale, h / scale
		draw.SimpleText( "Press E to begin watching", "MediaTitle",
			tw/2, th/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	End3D2D()
end
