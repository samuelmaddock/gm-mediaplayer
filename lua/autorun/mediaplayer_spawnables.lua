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
		"../spawnicons/models/props/cs_office/tv_plasma",
		"Small TV",
		"models/props/cs_office/tv_plasma.mdl",
		{
			angle = Angle(-90, 90, 0),
			offset = Vector(6.5, 27.9, 35.3),
			width = 56,
			height = 33
		}
	)
end
