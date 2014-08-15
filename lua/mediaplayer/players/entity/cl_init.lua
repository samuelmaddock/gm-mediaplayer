include "shared.lua"

DEFINE_BASECLASS( "mp_base" )

local pcall = pcall
local print = print
local Angle = Angle
local IsValid = IsValid
local ValidPanel = ValidPanel
local Vector = Vector
local cam = cam
local Start3D = cam.Start3D
local Start3D2D = cam.Start3D2D
local End3D2D = cam.End3D2D
local draw = draw
local math = math
local string = string
local surface = surface

local FullscreenCvar = MediaPlayer.Cvars.Fullscreen

MEDIAPLAYER.Enable3DAudio = true

function MEDIAPLAYER:NetReadUpdate()
	local entIndex = net.ReadUInt(16)
	local ent = Entity(entIndex)
	local mpEnt = self.Entity

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.NetReadUpdate[entity]: ", ent, entIndex)
	end

	if ent ~= mpEnt then
		if IsValid(ent) and ent ~= NULL then
			ent:InstallMediaPlayer( self )
		else
			-- Wait until the entity becomes valid
			self._EntIndex = entIndex
		end
	end
end

local RenderScale = 0.1
local InfoScale = 1/17

function MEDIAPLAYER:Draw( bDrawingDepth, bDrawingSkybox )

	local ent = self.Entity

	if --bDrawingSkybox or
			FullscreenCvar:GetBool() or -- Don't draw if we're drawing fullscreen
			not IsValid(ent) or
			(ent.IsDormant and ent:IsDormant()) then
		return
	end

	local media = self:CurrentMedia()

	-- TODO: Draw thumbnail at far distances?

	local w, h, pos, ang = ent:GetMediaPlayerPosition()

	-- Render scale
	local rw, rh = w / RenderScale, h / RenderScale

	if IsValid(media) then

		-- Custom media draw function
		if media.Draw then
			Start3D2D( pos, ang, RenderScale )
				media:Draw( rw, rh )
			End3D2D()
		end
		-- TODO: else draw 'not yet implemented' screen?

		-- Media info
		Start3D2D( pos, ang, InfoScale )
			local iw, ih = w / InfoScale, h / InfoScale
			local succ, err = pcall( self.DrawMediaInfo, self, media, iw, ih )
			if not succ then
				print( err )
			end
		End3D2D()

	else

		local browser = MediaPlayer.GetIdlescreen()

		if ValidPanel(browser) then
			Start3D2D( pos, ang, RenderScale )
				self:DrawHTML( browser, rw, rh )
			End3D2D()
		end

	end

end

function MEDIAPLAYER:SetMedia( media )
	if media and self.Enable3DAudio then
		-- Set entity on media for 3D support
		media.Entity = self:GetEntity()
	end

	BaseClass.SetMedia( self, media )
end
