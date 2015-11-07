if SERVER then
	AddCSLuaFile "shared.lua"
	AddCSLuaFile "cl_init.lua"

	resource.AddFile "materials/theater/STATIC.vmt"
end
include "shared.lua"

ENT.UseDelay = 0.5 -- seconds

function ENT:Initialize()
	self:SetModel( self.Model )

	self:SetUseType( SIMPLE_USE )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end

	-- Install media player to entity
	local mp = self:InstallMediaPlayer( self.MediaPlayerType )

	-- Network media player ID
	self:SetMediaPlayerID( mp:GetId() )
end

function ENT:Use(ply)
	if not IsValid(ply) then return end

	-- Delay request
	if ply.NextUse and ply.NextUse > CurTime() then
		return
	end

	local mp = self:GetMediaPlayer()

	if not mp then
		ErrorNoHalt("MediaPlayer test entity doesn't have player installed\n")
		debug.Trace()
		return
	end

	if mp:HasListener(ply) then
		mp:RemoveListener(ply)
	else
		mp:AddListener(ply)
	end

	ply.NextUse = CurTime() + self.UseDelay
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end

function ENT:OnEntityCopyTableFinish( data )
	local mp = self:GetMediaPlayer()
	local queue = table.Copy( mp:GetMediaQueue() )

	local media = mp:GetMedia()
	if media then
		table.insert( queue, 1, table.Copy( media ) )
	end

	data.MediaPlayerPersistData = {
		queue = queue
	}

	data._mp = nil
end

function ENT:PostEntityPaste( ply, ent, createdEnts )
	local mpdata = self.MediaPlayerPersistData
	local mp = self:GetMediaPlayer()

	for _, mediaData in ipairs( mpdata.queue ) do
		local media = MediaPlayer.GetMediaForUrl( mediaData.url )
		if not media then continue end
		table.Merge( media, mediaData )
		mp:AddMedia( media )
	end

	mp:QueueUpdated()
end
