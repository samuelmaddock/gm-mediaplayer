hook.Add( "PopulateMenuBar", "MediaPlayerOptions_MenuBar", function( menubar )

	local m = menubar:AddOrGetMenu( "Media Player" )

	m:AddCVar( "Fullscreen", "mediaplayer_fullscreen", "1", "0" )

end )
