local MediaPlayerClass = "mediaplayer_tv"

local function AddMediaPlayerModel( spawnName, name, model, playerConfig )
	list.Set( "SpawnableEntities", spawnName, {
		PrintName = name,
		ClassName = MediaPlayerClass,
		Category = "Media Player",
		DropToFloor = true,
		KeyValues = {
			model = model
		}
	} )

	list.Set( "MediaPlayerModelConfigs", model, playerConfig )
end

AddMediaPlayerModel(
	"../spawnicons/models/hunter/plates/plate5x8",
	"Huge Billboard",
	"models/hunter/plates/plate5x8.mdl",
	{
		angle = Angle(0, 90, 0),
		offset = Vector(-118.8, 189.8, 2.5),
		width = 380,
		height = 238
	}
)

if SERVER or IsMounted( "cstrike" ) then

	AddMediaPlayerModel(
		"../spawnicons/models/props/cs_assault/billboard",
		"Billboard",
		"models/props/cs_assault/billboard.mdl",
		{
			angle = Angle(-90, 90, 0),
			offset = Vector(1, 110.5, 57.5),
			width = 221,
			height = 115
		}
	)
	
end

AddMediaPlayerModel(
		"../spawnicons/models/props_phx/rt_screen",
		"Small TV",
		"models/props_phx/rt_screen.mdl",
		{
			angle = Angle(-90, 90, 0),
			offset = Vector(6.5, 27.9, 35.3),
			width = 56,
			height = 33
		}
	)

if SERVER then

	-- fix for media player owner not getting set on alternate model spawn
	hook.Add( "PlayerSpawnedSENT", "MediaPlayer.SetOwner", function(ply, ent)
		if not ent.IsMediaPlayerEntity then return end
		ent:SetCreator(ply)
		local mp = ent:GetMediaPlayer()
		mp:SetOwner(ply)
	end )

end


AddMediaPlayerModel(
	"../spawnicons/models/props_lab/citizenradio",
	"Billboard",
	"models/props_lab/citizenradio.mdl",
	{
		angle = Angle(0, 90, 0),
		offset = Vector(-7,12,17.3),
		width = 27.2*0.85,
		height = 15.3*0.85
	}
)

AddMediaPlayerModel(
	"../spawnicons/models/props_lab/citizenradio",
	"Billboard",
	"models/props_lab/citizenradio.mdl",
	{
		angle = Angle(0, 90, 0),
		offset = Vector(-7,12,17.3),
		width = 27.2*0.85,
		height = 15.3*0.85
	}
)
AddMediaPlayerModel(
	"../spawnicons/models/props_lab/huladoll",
	"Big",
	"models/props_lab/huladoll.mdl",
	{
		angle = Angle(0, 0, 90),
		offset = Vector(-1366*.5,5,768),
		width = 1366,
		height = 768
	}
)

AddMediaPlayerModel(
	"../spawnicons/models/props_lab/huladoll",
	"Big",
	"models/props_lab/huladoll.mdl",
	{
		angle = Angle(0, 0, 90),
		offset = Vector(-1366*.5,5,768),
		width = 1366,
		height = 768
	}
)

AddMediaPlayerModel(
	"../spawnicons/models/props_junk/popcan01a",
	"Smallish",
	"models/props_junk/popcan01a.mdl",
	{
		angle = Angle(0, 0, 90),
		offset = Vector(-227.56*.5,5,128),
		width = 227.56,
		height = 128
	}
)
