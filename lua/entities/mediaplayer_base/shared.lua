AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false

ENT.Model = Model( "models/gmod_tower/suitetv.mdl" )

ENT.MediaPlayerType = "entity"
ENT.UseDelay = 0.5 -- seconds

ENT.IsMediaPlayerEntity = true

function ENT:Initialize()

	if SERVER then
		self:SetModel( self.Model )

		self:SetUseType( SIMPLE_USE )

		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:EnableMotion( false )
		end

		self:DrawShadow( false )

		-- Install media player to entity
		local mp = self:InstallMediaPlayer( self.MediaPlayerType )

		-- Network media player ID
		self:SetMediaPlayerID( mp:GetId() )
	end

end

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "MediaPlayerID" )

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

function ENT:OnRemove()
	local mp = self:GetMediaPlayer()
	if mp then
		mp:Remove()
	end
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
