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

		if self.urlinfo.path then
			local path = self.urlinfo.path
			path = string.match( path, pattern ) -- get filename

			if path then
				title = urllib.unescape( path )
			else
				title = self.url
			end
		else
			title = self.url
		end

		self._metadata = {
			title 		= title or self.Name,
			url 		= self.url
		}

	end

	if callback then
		callback(self._metadata)
	end

end
