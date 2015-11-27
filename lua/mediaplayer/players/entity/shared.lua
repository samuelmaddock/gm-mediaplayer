include "sh_meta.lua"

DEFINE_BASECLASS( "mp_base" )

--[[---------------------------------------------------------
	Entity Media Player
-----------------------------------------------------------]]

local MEDIAPLAYER = MEDIAPLAYER
MEDIAPLAYER.Name = "entity"

function MEDIAPLAYER:IsValid()
	if not BaseClass.IsValid(self) then
		return false
	end

	local ent = self.Entity

	if ent then
		return IsValid(ent)
	end

	-- Client may still be waiting on the entity to be created by the network;
	-- let's just say it's valid until the entity is setup
	return true
end

function MEDIAPLAYER:Init(...)
	BaseClass.Init(self, ...)

	if SERVER then
		-- Manually manage listeners by default
		self._TransmitState = TRANSMIT_NEVER
	end
end

function MEDIAPLAYER:SetEntity(ent)
	self.Entity = ent

	if SERVER then
		local creator = ent:GetCreator()

		if IsValid(creator) and creator:IsPlayer() then
			self:SetOwner(creator)
		end
	else
		-- Setup hooks for drawing the screen onto the entity
		hook.Add( "HUDPaint", self, self.DrawFullscreen )
		hook.Add( "PostDrawOpaqueRenderables", self, self.Draw )
	end
end

function MEDIAPLAYER:GetEntity()
	-- Clients may wait for the entity to become valid
	if CLIENT and self._EntIndex then
		local ent = Entity(self._EntIndex)

		if IsValid(ent) and ent ~= NULL then
			ent:InstallMediaPlayer(self)
			self._EntIndex = nil
		else
			return nil
		end
	end

	return self.Entity
end

function MEDIAPLAYER:GetPos()
	return IsValid(self.Entity) and self.Entity:GetPos() or Vector(0,0,0)
end

function MEDIAPLAYER:GetLocation()
	if IsValid(self.Entity) and self.Entity.Location then
		return self.Entity:Location()
	end
	return self._Location
end

function MEDIAPLAYER:Think()
	BaseClass.Think(self)

	local ent = self:GetEntity()

	if IsValid(ent) then
		-- Lua refresh fix
		if ent._mp ~= self then
			self:Remove()
		end
	elseif SERVER then
		-- Only remove on the server since the client may still be connecting
		-- and the entity will be created when they finish.
		self:Remove()
	end
end

function MEDIAPLAYER:Remove()
	-- remove draw hooks
	if CLIENT then
		hook.Remove( "HUDPaint", self )
		hook.Remove( "PostDrawOpaqueRenderables", self )
	end

	-- remove reference to media player installed on entity
	if self.Entity then
		self.Entity._mp = nil
	end

	BaseClass.Remove(self)
end
