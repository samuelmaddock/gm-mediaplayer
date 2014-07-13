AddCSLuaFile "shared.lua"
include "shared.lua"

local urllib = url
local FilenamePattern = "([^/]+)%.%w-$"

local function titleFallback(self, callback)
	local path = self.urlinfo.path
	path = string.match( path, FilenamePattern ) -- get filename

	title = urllib.unescape( path )
	self._metadata.title = title

	self:SetMetadata(self._metadata, true)
	MediaPlayer.Metadata:Save(self)

	callback(self._metadata)
end

--[[local function id3(self, callback)
	self:Fetch( self.url,
		function(body, len, headers, code)
			local title, artist

			-- check header
			if body:sub(1, 4) == "TAG+" then
				title = body:sub(5, 56)
				artist = body:sub(57, 116)
			elseif body:sub(1, 3) == "TAG" then
				title = body:sub(4, 33)
				artist = body:sub(34, 63)
			else
				titleFallback(self, callback)
				return
			end

			title = title:Trim()
			artist = artist:Trim()

			print("ID3 SUCCESS:", title, artist)

			if artist:len() > 0 then
				title = artist .. ' - ' .. title
			end

			self._metadata.title = title

			callback(self._metadata)
		end,

		function()
			titleFallback(self, callback)
		end,

		{
			["Range"] = "bytes=-128"
		}
	)
end]]

function SERVICE:GetMetadata( callback )

	local ext = self:GetExtension()

	-- if ext == 'mp3' then
	-- 	id3(self, callback)
	-- else

		if not self._metadata then
			self._metadata = {
				title 		= "Unknown audio",
				duration 	= 0
			}
		end

		if callback then
			self:SetMetadata(self._metadata, true)
			MediaPlayer.Metadata:Save(self)

			callback(self._metadata)
		end

	-- end

end

function SERVICE:GetExtension()
	if not self._extension then
		self._extension = string.GetExtensionFromFilename(self.url)
	end
	return self._extension
end

function SERVICE:NetReadRequest()

	if not self.PrefetchMetadata then return end

	local title = net.ReadString()

	-- If the title is just the URL, grab just the filename instead
	if title == self.url then
		local path = self.urlinfo.path
		path = string.match( path, FilenamePattern ) -- get filename

		title = urllib.unescape( path )
	end

	self._metadata = self._metadata or {}
	self._metadata.title = title
	self._metadata.duration = net.ReadUInt( 16 )

end
