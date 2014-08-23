MP = MP or {}
MP.EVENTS = MP.EVENTS or {}

MP.EVENTS.UI = {
	MEDIA_PLAYER_CHANGED = "mp.events.ui.mediaPlayerChanged",
	OPEN_REQUEST_MENU = "mp.events.ui.openRequestMenu",
	FAVORITE_MEDIA = "mp.events.ui.favoriteMedia",
	VOTESKIP_MEDIA = "mp.events.ui.voteskipMedia",
	REMOVE_MEDIA = "mp.events.ui.removeMedia",
	TOGGLE_PAUSE = "mp.events.ui.togglePause",
	SEEK = "mp.events.ui.seek",

	START_SEEKING = "mp.events.ui.startSeeking",
	STOP_SEEKING = "mp.events.ui.stopSeeking",

	PRIVILEGED_PLAYER = "mp.events.ui.privilegedPlayer"
}

include "sidebar.lua"
