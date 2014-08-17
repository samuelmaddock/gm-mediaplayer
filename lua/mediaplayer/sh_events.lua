MP.EVENTS = {
	MEDIA_CHANGED = "mediaChanged"
}

if CLIENT then

	table.Merge( MP.EVENTS, {
		VOLUME_CHANGED = "mp.events.volumeChanged"
	} )

	MP.EVENTS.UI = {
		MEDIA_PLAYER_CHANGED = "mp.events.ui.mediaPlayerChanged"
	}

end
