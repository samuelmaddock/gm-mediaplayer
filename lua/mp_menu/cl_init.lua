MP = MP or {}
MP.EVENTS = MP.EVENTS or {}

MP.EVENTS.UI = {

	--[[--------------------------------------------------------
		Sidebar events
	----------------------------------------------------------]]

	SETUP_SIDEBAR = "mp.events.ui.sidebarChanged",
	SETUP_PLAYBACK_PANEL = "mp.events.ui.setupPlaybackPanel",
	SETUP_MEDIA_PANEL = "mp.events.ui.setupMediaPanel",

	MEDIA_PLAYER_CHANGED = "mp.events.ui.mediaPlayerChanged",

	OPEN_REQUEST_MENU = "mp.events.ui.openRequestMenu",
	FAVORITE_MEDIA = "mp.events.ui.favoriteMedia",
	REMOVE_MEDIA = "mp.events.ui.removeMedia",
	TOGGLE_PAUSE = "mp.events.ui.togglePause",
	SEEK = "mp.events.ui.seek",

	START_SEEKING = "mp.events.ui.startSeeking",
	STOP_SEEKING = "mp.events.ui.stopSeeking",

	PRIVILEGED_PLAYER = "mp.events.ui.privilegedPlayer"

}

include "sidebar.lua"
