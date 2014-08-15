SERVICE.Name 	= "Image"
SERVICE.Id 		= "img"
SERVICE.Base 	= "res"

SERVICE.FileExtensions = { 'png', 'jpg', 'jpeg', 'gif' }

if CLIENT then

	local EmbedHTML = [[
<div style="background-image: url(%s);
			background-repeat: no-repeat;
			background-size: contain;
			background-position: center center;
			width: 100%%;
			height: 100%%;">
</div>
]]

	function SERVICE:GetHTML()
		return EmbedHTML:format( self.url )
	end

end