--[[---------------------------------------------------------
	Media Player Entity Meta
-----------------------------------------------------------]]

local EntityMeta = FindMetaTable("Entity")
if not EntityMeta then return end

function EntityMeta:GetMediaPlayer()
	return self._mp
end

--
-- Installs a media player reference to the entity.
--
-- @param Table|String?  mp    Media player table or string type.
-- @param String?        mpId  Media player unique ID.
--
function EntityMeta:InstallMediaPlayer( mp, mpId )
	if not istable(mp) then
		local mpType = isstring(mp) and mp or "entity"

		if not MediaPlayer.IsValidType(mpType) then
			ErrorNoHalt("ERROR: Attempted to install invalid mediaplayer type onto an entity!\n")
			ErrorNoHalt("ENTITY: " .. tostring(self) .. "\n")
			ErrorNoHalt("TYPE: " .. tostring(mpType) .. "\n")
			mpType = "entity" -- default
		end

		local mpId = mpId or "Entity" .. self:EntIndex()
		mp = MediaPlayer.Create( mpId, mpType )
	end

	self._mp = mp
	self._mp:SetEntity(self)

	local creator = self.GetCreator and self:GetCreator()
	if IsValid( creator ) then
		self._mp:SetOwner( creator )
	end

	if isfunction(self.SetupMediaPlayer) then
		self:SetupMediaPlayer(mp)
	end

	return mp
end

local DefaultConfig = {
	offset	= Vector(0,0,0),	-- translation from entity origin
	angle	= Angle(0,90,90),	-- rotation
	-- attachment = "corner"	-- attachment name
	width = 64,					-- screen width
	height = 64 * 9/16			-- screen height
}

function EntityMeta:GetMediaPlayerPosition()
	local cfg = self.PlayerConfig or DefaultConfig

	local w = (cfg.width or DefaultConfig.width)
	local h = (cfg.height or DefaultConfig.height)
	local angles = (cfg.angle or DefaultConfig.angle)

	local pos, ang

	if cfg.attachment then
		local idx = self:LookupAttachment(cfg.attachment)
		if not idx then
			local err = string.format("MediaPlayer:Entity.Draw: Invalid attachment '%s'\n", cfg.attachment)
			Error(err)
		end

		-- Get attachment orientation
		local attach = self:GetAttachment(idx)
		pos = attach.pos
		ang = attach.ang
	else
		pos = self:GetPos() -- TODO: use GetRenderOrigin?
	end

	-- Apply offset
	if cfg.offset then
		pos = pos +
			self:GetForward() * cfg.offset.x +
			self:GetRight() * cfg.offset.y +
			self:GetUp() * cfg.offset.z
	end

	-- Set angles
	ang = ang or self:GetAngles() -- TODO: use GetRenderAngles?

	ang:RotateAroundAxis( ang:Right(), angles.p )
	ang:RotateAroundAxis( ang:Up(), angles.y )
	ang:RotateAroundAxis( ang:Forward(), angles.r )

	return w, h, pos, ang
end
