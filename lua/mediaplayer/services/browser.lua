DEFINE_BASECLASS( "mp_service_base" )

SERVICE.Name 	= "Browser Base"
SERVICE.Id 		= "browser"
SERVICE.Abstract = true

if CLIENT then

	function SERVICE:GetBrowser()
		return self.Browser
	end

	function SERVICE:OnBrowserReady( browser )
		-- TODO: make sure this resolution is correct
		local resolution = MediaPlayer.Resolution()
		MediaPlayer.SetBrowserSize( browser, resolution * 16/9, resolution )

		-- Implement this in a child service
	end

	function SERVICE:SetVolume( volume )
		-- Implement this in a child service
	end

	function SERVICE:Volume( volume )
		local origVolume = volume

		volume = BaseClass.Volume( self, volume )

		if origVolume and ValidPanel( self.Browser ) then
			self:SetVolume( volume )
		end

		return volume
	end

	function SERVICE:Play()

		BaseClass.Play( self )

		if self.Browser and ValidPanel(self.Browser) then
			self:OnBrowserReady( self.Browser )
		else

			self._promise = browserpool.get(function( panel )

				if not panel then
					return
				end

				if self._promise then
					self._promise = nil
				end

				self.Browser = panel
				self:OnBrowserReady( panel )

			end)
		end

	end

	function SERVICE:Stop()
		BaseClass.Stop( self )

		if self._promise then
			self._promise:Cancel('Service has been stopped')
		end

		if self.Browser then
			browserpool.release( self.Browser )
			self.Browser = nil
		end
	end

	local StartHtml = [[
	<!DOCTYPE html>
	<html>
	<head>
		<meta charset="utf-8">
		<title>Media Player</title>
		<style type="text/css">
		html, body {
			margin: 0;
			padding: 0;
			width: 100%;
			height: 100%;
			overflow: hidden;
		}

		* { box-sizing: border-box }

		body {
			background-color: #282828;
			color: #cecece;
		}
		</style>
	</head>
	<body>
	]]

	local EndHtml = [[
	</body>
	</html>
	]]

	function SERVICE.WrapHTML( html )
		return table.concat({ StartHtml, html, EndHtml })
	end

	--[[---------------------------------------------------------
		Draw 3D2D
	-----------------------------------------------------------]]

	local ValidPanel = ValidPanel
	local SetDrawColor = surface.SetDrawColor
	local DrawRect = surface.DrawRect
	local HTMLTexture = draw.HTMLTexture

	function SERVICE:Draw( w, h )

		if ValidPanel(self.Browser) then
			SetDrawColor( 0, 0, 0, 255 )
			DrawRect( 0, 0, w, h )
			HTMLTexture( self.Browser, w, h )
		end

	end

end
