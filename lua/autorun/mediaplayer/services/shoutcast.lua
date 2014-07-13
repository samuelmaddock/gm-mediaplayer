SERVICE.Name	= "SHOUTcast"
SERVICE.Id		= "shc"
SERVICE.Base	= "af"

-- DEFINE_BASECLASS( "mp_service_af" )

local StationUrlPattern = "yp.shoutcast.com/sbin/tunein%-station%.pls%?id=%d+"

function SERVICE:Match( url )
	return url:match( StationUrlPattern )
end

function SERVICE:IsTimed()
	return false
end
