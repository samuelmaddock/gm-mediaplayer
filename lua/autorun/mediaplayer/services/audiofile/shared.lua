local urllib = url

SERVICE.Name 	= "Audio file"
SERVICE.Id 		= "af"

SERVICE.PrefetchMetadata = true

local SupportedEncodings = {
	'([^/]+%.[mM][pP]3)$',    -- mp3
	'([^/]+%.[wW][aA][vV])$', -- wav
	'([^/]+%.[oO][gG][gG])$'  -- ogg
}

function SERVICE:Match( url )
	-- check supported encodings
	for _, encoding in pairs(SupportedEncodings) do
		if url:find(encoding) then
			return true
		end
	end
	return false
end
