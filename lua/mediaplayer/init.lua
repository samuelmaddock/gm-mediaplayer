if MediaPlayer then
	-- TODO: compare versions?
	if MediaPlayer.__refresh then
		MediaPlayer.__refresh = nil
	else
		return -- MediaPlayer has already been registered
	end
end

resource.AddSingleFile "materials/mediaplayer/ui/spritesheet2015-10-7.png"
resource.AddFile "resource/fonts/ClearSans-Medium.ttf"

AddCSLuaFile "controls/dmediaplayerhtml.lua"
AddCSLuaFile "controls/dhtmlcontrols.lua"
AddCSLuaFile "controls/dmediaplayerrequest.lua"
AddCSLuaFile "cl_init.lua"
AddCSLuaFile "cl_requests.lua"
AddCSLuaFile "cl_idlescreen.lua"
AddCSLuaFile "cl_screen.lua"
AddCSLuaFile "shared.lua"
AddCSLuaFile "sh_events.lua"
AddCSLuaFile "sh_mediaplayer.lua"
AddCSLuaFile "sh_services.lua"
AddCSLuaFile "sh_history.lua"
AddCSLuaFile "sh_metadata.lua"
AddCSLuaFile "sh_cvars.lua"

include "shared.lua"
include "sv_requests.lua"

-- TODO: move this into its own file
MediaPlayer.net = MediaPlayer.net or {}

function MediaPlayer.net.ReadMediaPlayer()

	local mpId = net.ReadString()
	local mp = MediaPlayer.GetById(mpId)

	if not IsValid(mp) then
		if MediaPlayer.DEBUG then
			print("MEDIAPLAYER.Request: Invalid media player ID", mpId, mp)
		end
		return false
	end

	return mp

end
