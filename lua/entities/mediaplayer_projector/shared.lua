AddCSLuaFile()
DEFINE_BASECLASS( "mediaplayer_base" )

ENT.PrintName 		= "Media Player Projector"
ENT.Author 			= "Samuel Maddock"
ENT.Instructions 	= "Press Use on the entity to start watching."
ENT.Category 		= "Media Player"

ENT.Type = "anim"
ENT.Base = "mediaplayer_base"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = true

ENT.Model = Model( "models/props/cs_office/projector.mdl" )

function ENT:SetupDataTables()

	self:NetworkVar( "Entity", 0, "Flashlight" )

end

-- TODO: figure out how to get this to work; will probably involve using a
-- render target

if SERVER then

	function ENT:Initialize()

		BaseClass.Initialize(self)

		self.flashlight = ents.Create( "env_projectedtexture" )

			self.flashlight:SetParent( self.Entity )

			-- The local positions are the offsets from parent..
			self.flashlight:SetLocalPos( Vector( 0, 0, 0 ) )
			self.flashlight:SetLocalAngles( Angle(0,0,0) )

			-- Looks like only one flashlight can have shadows enabled!
			self.flashlight:SetKeyValue( "enableshadows", 1 )
			self.flashlight:SetKeyValue( "farz", 1024 )
			self.flashlight:SetKeyValue( "nearz", 12 )
			self.flashlight:SetKeyValue( "lightfov", 90 )

			local c = self:GetColor()
			local b = 1
			self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

		self.flashlight:Spawn()

		self.flashlight:Input( "SpotlightTexture", NULL, NULL, "vgui/hand.vtf" )

		self:SetFlashlight(self.flashlight)

	end

else

	local projmat = CreateMaterial( "projmat", "UnlitGeneric", {
	    ["$basetexture"] = "vgui/hand.vtf"
	})

	function ENT:Draw()

		BaseClass.Draw(self)

		local flashlight = self:GetFlashlight()
		if not IsValid(flashlight) then return end

		local mp = self:GetMediaPlayer()
		if not IsValid(mp) then return end

		local media = mp:CurrentMedia()
		local browser = media and media.Browser or MediaPlayer.GetIdlescreen()

		browser:UpdateHTMLTexture()
		local mat = browser:GetHTMLMaterial()

		local texture = mat:GetTexture("$basetexture")

		projmat:SetTexture( "$basetexture", texture )

	end

end
