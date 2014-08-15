local DefaultIdlescreen = [[
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>MediaPlayer Idlescreen</title>
	<style type="text/css">
	html, body {
		margin: 0;
		padding: 0;
		width: 100%;
		height: 100%;
	}

	* { box-sizing: border-box }

	body {
		background-color: #ececec;
		color: #313131;
		padding: 15px;
	}
	</style>
</head>
<body>
	<h1>MediaPlayer Idlescreen</h1>
	<p>Right-click on the media player to see a list of available actions.</p>
</body>
</html>
]]

function MediaPlayer.GetIdlescreen()

	if not MediaPlayer._idlescreen then
		local browser = vgui.Create( "DMediaPlayerHTML" )
		browser:SetPaintedManually(true)
		browser:SetKeyBoardInputEnabled(false)
		browser:SetMouseInputEnabled(false)
		browser:SetPos(0,0)

		local resolution = MediaPlayer.Resolution()
		browser:SetSize( resolution * 16/9, resolution )

		-- TODO: set proper browser size

		MediaPlayer._idlescreen = browser

		local setup = hook.Run( "MediaPlayerSetupIdlescreen", browser )
		if not setup then
			MediaPlayer._idlescreen:SetHTML( DefaultIdlescreen )
		end
	end

	return MediaPlayer._idlescreen

end