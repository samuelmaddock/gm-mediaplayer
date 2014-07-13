DEFINE_BASECLASS( "mp_service_base" )

SERVICE.Name 	= "Google Drive"
SERVICE.Id 		= "gd"
SERVICE.Base 	= "yt"

local GdFileIdPattern = "[%a%d-_]+"
local UrlSchemes = {
	"docs%.google%.com/file/d/" .. GdFileIdPattern .. "/",
	"drive%.google%.com/file/d/" .. GdFileIdPattern .. "/"
}

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)
	obj._data = obj:GetGoogleDriveFileId()
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
	return true
end

function SERVICE:GetGoogleDriveFileId()

	local videoId

	if self.videoId then

		videoId = self.videoId

	elseif self.urlinfo then

		local url = self.urlinfo

		-- https://docs.google.com/file/d/(videoId)
		if url.path and string.match(url.path, "^/file/d/([%a%d-_]+)") then
			videoId = string.match(url.path, "^/file/d/([%a%d-_]+)")
		end

		self.videoId = videoId

	end

	return videoId

end

-- Used for clientside inheritence of the YouTube service
SERVICE.GetYouTubeVideoId = GetGoogleDriveFileId
