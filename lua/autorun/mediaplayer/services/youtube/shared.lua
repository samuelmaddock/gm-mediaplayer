DEFINE_BASECLASS( "mp_service_base" )

SERVICE.Name 	= "YouTube"
SERVICE.Id 		= "yt"
SERVICE.Base 	= "browser"

local YtVideoIdPattern = "[%a%d-_]+"
local UrlSchemes = {
	"youtube%.com/watch%?v=" .. YtVideoIdPattern,
	"youtu%.be/watch%?v=" .. YtVideoIdPattern,
	"youtube%.com/v/" .. YtVideoIdPattern,
	"youtu%.be/v/" .. YtVideoIdPattern,
	"youtube%.googleapis%.com/v/" .. YtVideoIdPattern
}

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)
	obj._data = obj:GetYouTubeVideoId()
	return obj
end

function SERVICE:Match( url )
	for _, pattern in pairs(UrlSchemes) do
		if string.find( url, pattern ) then
			return true
		end
	end

	return false
end

function SERVICE:IsTimed()
	if self._istimed == nil then
		-- YouTube Live resolves to 0 second video duration
		self._istimed = self:Duration() > 0
	end

	return self._istimed
end

function SERVICE:GetYouTubeVideoId()

	local videoId

	if self.videoId then

		videoId = self.videoId

	elseif self.urlinfo then

		local url = self.urlinfo

		-- http://www.youtube.com/watch?v=(videoId)
		if url.query and url.query.v then
			videoId = url.query.v

		-- http://www.youtube.com/v/(videoId)
		elseif url.path and string.match(url.path, "^/v/([%a%d-_]+)") then
			videoId = string.match(url.path, "^/v/([%a%d-_]+)")

		-- http://youtube.googleapis.com/v/(videoId)
		elseif url.path and string.match(url.path, "^/v/([%a%d-_]+)") then
			videoId = string.match(url.path, "^/v/([%a%d-_]+)")

		-- http://youtu.be/(videoId)
		elseif string.match(url.host, "youtu.be") and
			url.path and string.match(url.path, "^/([%a%d-_]+)$") and
			( (not url.query) or #url.query == 0 ) then -- short url

			videoId = string.match(url.path, "^/([%a%d-_]+)$")
		end

		self.videoId = videoId

	end

	return videoId

end
