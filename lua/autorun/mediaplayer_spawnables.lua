local MediaPlayerClass = "mediaplayer_tv"

local function AddMediaPlayerModel( name, model, playerConfig )
	list.Set( "SpawnableEntities", name, {
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

AddMediaPlayerModel( "Huge Billboard", "models/hunter/plates/plate5x8.mdl", {
	angle = Angle(0, 90, 0),
	offset = Vector(-118.8, 189.8, 1.8),
	width = 380,
	height = 238
} )
