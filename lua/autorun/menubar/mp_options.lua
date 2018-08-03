hook.Add( "PopulateMenuBar", "MediaPlayerOptions_MenuBar", function( menubar )

	local m = menubar:AddOrGetMenu( "▶  Media Player" )

	m:AddCVar( "Fullscreen", "mediaplayer_fullscreen", "1", "0" )

	m:AddSpacer()

	m:AddOption( "Turn Off All", function()
		for _, mp in ipairs(MediaPlayer.GetAll()) do
			MediaPlayer.RequestListen( mp )
		end

		MediaPlayer.HideSidebar()
	end )

end )
