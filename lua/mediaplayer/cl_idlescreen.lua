local DefaultIdlescreen = [[
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>MediaPlayer Idlescreen</title>
	<style type="text/css">
	.repeating-grid {
	  z-index: -1;
	  position: absolute;
	  top: 0;
	  bottom: 0;
	  left: 0;
	  right: 0;
	  background-size: 120px 120px;
	  background-image: -webkit-repeating-linear-gradient(0deg, rgba(0, 0, 0, 0.08), rgba(0, 0, 0, 0.08) 2px, transparent 2px, transparent 120px), -webkit-repeating-linear-gradient(-90deg, rgba(0, 0, 0, 0.08), rgba(0, 0, 0, 0.08) 2px, transparent 2px, transparent 120px), -webkit-repeating-linear-gradient(0deg, rgba(0, 0, 0, 0.08), rgba(0, 0, 0, 0.08) 1px, transparent 1px, transparent 30px), -webkit-repeating-linear-gradient(-90deg, rgba(0, 0, 0, 0.08), rgba(0, 0, 0, 0.08) 1px, transparent 1px, transparent 30px);
	}
	.background-example {
	  opacity: 0.66;
	  z-index: -2;
	  position: absolute;
	  top: 0;
	  bottom: 0;
	  left: 0;
	  right: 0;
	  background: #6e00ff;
	  /* Old browsers */
	  background: -moz-linear-gradient(-45deg, #6e00ff 0%, #ff7700 100%);
	  background: -webkit-gradient(linear, left top, right bottom, color-stop(0%, #6e00ff), color-stop(100%, #ff7700));
	  /* Chrome,Safari4+ */
	  background: -webkit-linear-gradient(-45deg, #6e00ff 0%, #ff7700 100%);
	  /* Chrome10+,Safari5.1+ */
	  background: -o-linear-gradient(-45deg, #6e00ff 0%, #ff7700 100%);
	  /* Opera 11.10+ */
	  background: -ms-linear-gradient(-45deg, #6e00ff 0%, #ff7700 100%);
	  /* IE10+ */
	  background: linear-gradient(135deg, #6e00ff 0%, #ff7700 100%);
	  /* W3C */
	  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#6e00ff', endColorstr='#ff7700', GradientType=1);
	  /* IE6-9 fallback on horizontal gradient */
	}
	html {
		background: #fff;
	}
	html,
	body {
	  margin: 0;
	  padding: 0;
	  width: 100%;
	  height: 100%;
	  overflow: hidden;
	  display: -webkit-box;
	  display: -moz-box;
	  display: box;
	  -webkit-box-orient: horizontal;
	  -moz-box-orient: horizontal;
	  -box-orient: horizontal;
	  -webkit-box-pack: center;
	  -webkit-box-align: center;
	}
	.content {
	  color: rgba(0, 0, 0, 0.66);
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
	<div class="repeating-grid"></div>
	<div class="background-example"></div>

	<div class="content">
	  <h1>No media playing</h1>
	  <p>Right-click on the media player to see a list of available actions</p>
	</div>
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
