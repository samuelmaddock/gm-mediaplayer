---
-- YouTube Data API v3 library.
--
-- https://developers.google.com/youtube/v3/
--
_G.youtube = {}

youtube.apiKey = nil

---
-- Referer header is required for requests.
--
youtube.referer = ''

youtube.metadataUrl = "https://www.googleapis.com/youtube/v3/videos?id=%s&key=%s&type=video&part=contentDetails,snippet,status&videoEmbeddable=true&videoSyndicated=true"

function youtube.queryVideoMetadata( uri )
	local def = Deferred()

	HTTP{
		url = uri,
		method = "GET",
		headers = {
			Referer = youtube.referer
		},
		success = function ( code, body, headers )

			-- def:Resolve(...)
		end,
		failed = function ( err )
			def:Reject(err)
		end
	}

	return def:Promise()
end

---
-- Helper function for converting ISO 8601 time strings; this is the formatting
-- used for duration specified in the YouTube v3 API.
--
-- http://stackoverflow.com/a/22149575/1490006
--
function youtube.convertISO8601Time( duration )
	local a = {}

	for part in string.gmatch(duration, "%d+") do
	   table.insert(a, part)
	end

	if duration:find('M') and not (duration:find('H') or duration:find('S')) then
		a = {0, a[1], 0}
	end

	if duration:find('H') and not duration:find('M') then
		a = {a[1], 0, a[2]}
	end

	if duration:find('H') and not (duration:find('M') or duration:find('S')) then
		a = {a[1], 0, 0}
	end

	duration = 0

	if #a == 3 then
		duration = duration + tonumber(a[1]) * 3600
		duration = duration + tonumber(a[2]) * 60
		duration = duration + tonumber(a[3])
	end

	if #a == 2 then
		duration = duration + tonumber(a[1]) * 60
		duration = duration + tonumber(a[2])
	end

	if #a == 1 then
		duration = duration + tonumber(a[1])
	end

	return duration
end
