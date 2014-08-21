MP.EVENTS = {
	MEDIA_CHANGED = "mediaChanged",
	QUEUE_CHANGED = "mp.events.queueChanged",
	PLAYER_STATE_CHANGED = "mp.events.playerStateChanged"
}

if CLIENT then

	table.Merge( MP.EVENTS, {
		VOLUME_CHANGED = "mp.events.volumeChanged"
	} )

	MP.EVENTS.UI = {
		MEDIA_PLAYER_CHANGED = "mp.events.ui.mediaPlayerChanged",
		OPEN_REQUEST_MENU = "mp.events.ui.openRequestMenu",
		FAVORITE_MEDIA = "mp.events.ui.favoriteMedia",
		VOTESKIP_MEDIA = "mp.events.ui.voteskipMedia",
		REMOVE_MEDIA = "mp.events.ui.removeMedia",
		TOGGLE_PAUSE = "mp.events.ui.togglePause",
		SEEK = "mp.events.ui.seek"
	}

end
