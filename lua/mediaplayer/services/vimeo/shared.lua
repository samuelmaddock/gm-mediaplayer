DEFINE_BASECLASS( "mp_service_browser" )

SERVICE.Name 	= "Vimeo"
SERVICE.Id 		= "vm"
SERVICE.Base 	= "browser"

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)
	obj._data = obj:GetVimeoVideoId()
	return obj
end

function SERVICE:Match( url )
	return string.find( url, "vimeo.com/%d+" )
end

function SERVICE:GetVimeoVideoId()

	local videoId

	if self.videoId then

		videoId = self.videoId

	elseif self.urlinfo then

		local url = self.urlinfo

		-- http://www.vimeo.com/(videoId)
		videoId = string.match(url.path, "^/(%d+)")

		self.videoId = videoId

	end

	return videoId

end
