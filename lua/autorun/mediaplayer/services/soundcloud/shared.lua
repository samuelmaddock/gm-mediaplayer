DEFINE_BASECLASS( "mp_service_base" )

SERVICE.Name 	= "SoundCloud"
SERVICE.Id 		= "sc"
SERVICE.Base 	= "af"

SERVICE.PrefetchMetadata = false

function SERVICE:New( url )
	local obj = BaseClass.New(self, url)

	-- TODO: grab id from /tracks/:id, etc.
	obj._data = obj.urlinfo.path or '0'

	return obj
end

function SERVICE:Match( url )
	return string.match( url, "soundcloud.com" )
end
