SERVICE.Name	= "JWPlayer"
SERVICE.Id		= "jw"
SERVICE.Base	= "res"

SERVICE.FileExtensions = {
	'mp4'
}

if CLIENT then

	-- JWVideo
	-- https://github.com/nexbr/playx/blob/master/lua/playx/client/handlers/default.lua

	-- playxlib.GenerateJWPlayer
	-- https://github.com/nexbr/playx/blob/master/lua/playxlib.lua

	-- jwplayer
	-- https://github.com/nexbr/playx/tree/gh-pages/js

	local EmbedHTML = [[
<p>Not yet implemented</p>
]]

	function SERVICE:GetHTML()
		local url = self.url

		local path = self.urlinfo.path
		local ext = path:match("[^/]+%.(%S+)$")

		local mime = MimeTypes[ext]

		return EmbedHTML:format(url, mime)
	end

	-- TODO: Sync/volume

end