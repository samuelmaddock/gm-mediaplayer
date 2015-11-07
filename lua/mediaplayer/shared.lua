MediaPlayer = MediaPlayer or {}
MP = MediaPlayer

include "utils.lua"
include "sh_cvars.lua"

--[[---------------------------------------------------------
	Config

	Store service API keys, etc.
-----------------------------------------------------------]]

MediaPlayer.config = {}

---
-- Apply configuration values to the mediaplayer config.
--
-- @param config	Table with configuration values.
--
function MediaPlayer.SetConfig( config )
	table.Merge( MediaPlayer.config, config )
end

---
-- Method for easily grabbing config value without checking that each fragment
-- exists.
--
-- @param key	e.g. "json.key.fragments"
--
function MediaPlayer.GetConfigValue( key )
	local value = MediaPlayerUtils.TableLookup( MediaPlayer.config, key )

	if type(value) == 'nil' then
		ErrorNoHalt("WARNING: MediaPlayer config value not found for key `" .. tostring(key) .. "`\n")
	end

	return value
end

if SERVER then
	AddCSLuaFile "config/client.lua"
	include "config/server.lua"
else
	include "config/client.lua"
end


--[[---------------------------------------------------------
	Shared includes
-----------------------------------------------------------]]

include "sh_events.lua"
include "sh_mediaplayer.lua"
include "sh_services.lua"
include "sh_history.lua"
include "sh_metadata.lua"

hook.Add("Initialize", "InitMediaPlayer", function()
	hook.Run("InitMediaPlayer", MediaPlayer)
end)

-- No fun allowed
hook.Add( "CanDrive", "DisableMediaPlayerDriving", function(ply, ent)
	if IsValid(ent) and ent.IsMediaPlayerEntity then
		return IsValid(ply) and ply:IsAdmin()
	end
end)
