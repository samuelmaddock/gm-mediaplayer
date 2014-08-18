MP.EVENTS = {
	MEDIA_CHANGED = "mediaChanged",
	QUEUE_CHANGED = "mp.events.queueChanged"
}

if CLIENT then

	table.Merge( MP.EVENTS, {
		VOLUME_CHANGED = "mp.events.volumeChanged"
	} )

	MP.EVENTS.UI = {
		MEDIA_PLAYER_CHANGED = "mp.events.ui.mediaPlayerChanged"
	}

end
