ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false

ENT.Model = Model( "models/props/cs_office/tv_plasma.mdl" )

ENT.MediaPlayerType = "entity"
ENT.IsMediaPlayerEntity = true

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "MediaPlayerID" )
end

function ENT:OnRemove()
	local mp = self:GetMediaPlayer()
	if mp then
		mp:Remove()
	end
end
