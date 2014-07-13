AddCSLuaFile "shared.lua"
AddCSLuaFile "sh_meta.lua"
include "shared.lua"

function MEDIAPLAYER:NetWriteUpdate()
	-- Write the entity index since the actual entity may not yet exist on a
	-- client that's not fully connected.
	local entIndex = IsValid(self.Entity) and self.Entity:EntIndex() or 0
	net.WriteUInt(entIndex, 16)
end
