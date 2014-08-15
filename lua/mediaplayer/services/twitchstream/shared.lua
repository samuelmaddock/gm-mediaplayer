DEFINE_BASECLASS( "mp_service_browser" )

SERVICE.Name 	= "Twitch.TV - Stream"
SERVICE.Id 		= "twl"
SERVICE.Base 	= "browser"

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)

	local channel = obj:GetTwitchChannel()
	obj._data = channel

	return obj
end

function SERVICE:Match( url )
	return string.match(url, "twitch.tv") and
			string.match(url, ".tv/[%w_]+$")
end

function SERVICE:IsTimed()
	return false
end

function SERVICE:GetTwitchChannel()

	local channel

	if self._twitchChannel then

		channel = self._twitchChannel

	elseif self.urlinfo then

		local url = self.urlinfo

		channel = string.match(url.path, "^/([%w_]+)")
		self._twitchChannel = channel

	end

	return channel

end
