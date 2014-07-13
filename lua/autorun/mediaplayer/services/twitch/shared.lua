DEFINE_BASECLASS( "mp_service_base" )

SERVICE.Name 	= "Twitch.TV - Video"
SERVICE.Id 		= "twv"
SERVICE.Base 	= "browser"

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)

	local info = obj:GetTwitchVideoInfo()
	obj._data = info.channel .. "_" .. info.chapterId

	return obj
end

function SERVICE:Match( url )
	-- TODO: should the parsed url be passed instead?
	return (string.match(url, "justin.tv") or
			string.match(url, "twitch.tv")) and
			string.match(url, ".tv/[%w_]+/%a/%d+")
end

function SERVICE:GetTwitchVideoInfo()

	local info

	if self._twitchInfo then

		info = self._twitchInfo

	elseif self.urlinfo then

		local url = self.urlinfo

		local channel, type, chapterId = string.match(url.path, "^/([%w_]+)/(%a)/(%d+)")

		-- Chapter videos use /c/ while archived videos use /b/
		if type ~= "c" then
			type = "b"
		end

		info = {
			channel		= channel,
			type		= type,
			chapterId	= chapterId
		}

		self._twitchInfo = info

	end

	return info

end
