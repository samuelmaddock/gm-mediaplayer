MediaPlayer.Cvars = {}

MediaPlayer.Cvars.Debug = CreateConVar( "mediaplayer_debug", 0, FCVAR_DONTRECORD, "Enables media player debug mode; logs a bunch of actions into the console." )
MediaPlayer.DEBUG = MediaPlayer.Cvars.Debug:GetBool()
cvars.AddChangeCallback( "mediaplayer_debug", function(name, old, new)
	MediaPlayer.DEBUG = new == 1
end)

MediaPlayer.Cvars.AllowWebpages = CreateConVar( "mediaplayer_allow_webpages", 0, {
	FCVAR_ARCHIVE,
	FCVAR_NOTIFY,
	FCVAR_REPLICATED,
	FCVAR_SERVER_CAN_EXECUTE
}, "Allows any webpage to be requested." )

MediaPlayer.Cvars.QueueLimit = CreateConVar( "mediaplayer_queue_limit", 64, {
	FCVAR_REPLICATED,
	FCVAR_SERVER_CAN_EXECUTE
}, "Maximum size of a media player queue." )

if CLIENT then

	MediaPlayer.Cvars.Resolution	= CreateClientConVar( "mediaplayer_resolution", 480, true, false )
	MediaPlayer.Cvars.Audio3D		= CreateClientConVar( "mediaplayer_3daudio", 1, true, false )
	MediaPlayer.Cvars.Volume		= CreateClientConVar( "mediaplayer_volume", 0.15, true, false )
	MediaPlayer.Cvars.MuteUnfocused	= CreateClientConVar( "mediaplayer_mute_unfocused", 1, true, false )
	MediaPlayer.Cvars.Fullscreen	= CreateClientConVar( "mediaplayer_fullscreen", 0, false, false )
	MediaPlayer.Cvars.DrawThumbnails = CreateClientConVar( "mediaplayer_draw_thumbnails", 0, true, false )

end
