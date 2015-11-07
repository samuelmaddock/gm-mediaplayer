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
		width: 100%%;
		height: 100%%;
	}
	html {
		background: #fff;
	}
	body {
		overflow: hidden;
		display: -webkit-box;
		display: -moz-box;
		display: box;
		-webkit-box-orient: horizontal;
		-moz-box-orient: horizontal;
		-box-orient: horizontal;
		-webkit-box-pack: center;
		-webkit-box-align: center;
		background: -webkit-radial-gradient(center, ellipse cover,
			transparent 0%%, rgba(0, 0, 0, 0.7) 100%%);
	}
	h1 {
		margin: 0;
		padding: 0;
	}
	.background {
		position: absolute;
		display: block;
		width: 100%%;
		z-index: -1;
		-webkit-filter: blur(8px);
		-webkit-transform: scale(1.2);
		opacity: 0.66;
	}
	.content {
		color: rgba(255, 255, 255, 0.66);
		font-family: sans-serif;
		font-size: 1.5em;
		text-align: center;
		-webkit-box-flex: 1;
		-moz-box-flex: 1;
		box-flex: 1;
	}
	</style>
</head>
<body>
	<img src="asset://mapimage/gm_construct" class="background">
	<div class="content">
	  <h1>No media playing</h1>
	  <p>Hold %s while looking at the media player to reveal the queue menu.</p>
	</div>
</body>
</html>
]]

local function GetIdlescreenHTML()
	local contextMenuBind = input.LookupBinding( "+menu_context" ) or "C"
	contextMenuBind = contextMenuBind:upper()
	return DefaultIdlescreen:format( contextMenuBind )
end

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
			MediaPlayer._idlescreen:SetHTML( GetIdlescreenHTML() )
		end
	end

	return MediaPlayer._idlescreen

end
