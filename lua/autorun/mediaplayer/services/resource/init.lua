AddCSLuaFile "shared.lua"
include "shared.lua"

local urllib = url
local FilenamePattern = "([^/]+)%.%S+$"
local FilenameExtPattern = "([^/]+%.%S+)$"

SERVICE.TitleIncludeExtension = true -- include extension in title

function SERVICE:GetMetadata( callback )

	if not self._metadata then

		local title

		local pattern = self.TitleIncludeExtension and
			FilenameExtPattern or FilenamePattern

		local path = self.urlinfo.path
		path = string.match( path, pattern ) -- get filename

		title = urllib.unescape( path )

		self._metadata = {
			title 		= title or self.Name,
			url 		= self.url
		}

	end

	if callback then
		callback(self._metadata)
	end

end