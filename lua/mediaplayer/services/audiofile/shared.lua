local urllib = url

SERVICE.Name 	= "Audio file"
SERVICE.Id 		= "af"

SERVICE.PrefetchMetadata = true

local SupportedEncodings = {
	'([^/]+%.mp3)',    -- mp3
	'([^/]+%.wav)', -- wav
	'([^/]+%.ogg)'  -- ogg
}

function SERVICE:Match( url )
	url = string.lower(url or "")

	-- check supported encodings
	for _, encoding in pairs(SupportedEncodings) do
		if url:find(encoding) then
			return true
		end
	end

	return false
end
