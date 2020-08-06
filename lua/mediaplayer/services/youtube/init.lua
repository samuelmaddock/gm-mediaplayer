AddCSLuaFile "shared.lua"
include "shared.lua"

local TableLookup = MediaPlayerUtils.TableLookup

-- https://developers.google.com/youtube/v3/
local APIKey = MediaPlayer.GetConfigValue('google.api_key')
local MetadataUrl = "https://www.googleapis.com/youtube/v3/videos?id=%s&key=%s&type=video&part=contentDetails,snippet,status&videoEmbeddable=true&videoSyndicated=true"

---
-- Helper function for converting ISO 8601 time strings; this is the formatting
-- used for duration specified in the YouTube v3 API.
--
-- http://stackoverflow.com/a/22149575/1490006
--
local function convertISO8601Time( duration )
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

local function OnReceiveMetadata( self, callback, body )

	local metadata = {}

	-- Check for valid JSON response
	local resp = util.JSONToTable( body )
	if not resp then
		return callback(false)
	end

	-- If 'error' key is present, the query failed.
	if resp.error then
		return callback(false, TableLookup(resp, 'error.message'))
	end

	-- We need at least one result
	local results = TableLookup(resp, 'pageInfo.totalResults')
	if not ( results and results > 0 ) then
		return callback(false, "Requested video wasn't found")
	end

	local item = resp.items[1]

	-- Video must be embeddable
	if not TableLookup(item, 'status.embeddable') then
		return callback( false, "Requested video was embed disabled" )
	end

	metadata.title = TableLookup(item, 'snippet.title')

	-- Check for live broadcast
	local liveBroadcast = TableLookup(item, 'snippet.liveBroadcastContent')
	if liveBroadcast == 'none' then
		-- Duration is an ISO 8601 string
		local durationStr = TableLookup(item, 'contentDetails.duration')
		metadata.duration = math.max(1, convertISO8601Time(durationStr))
	else
		metadata.duration = 0 -- mark as live video
	end

	-- 'medium' size thumbnail doesn't have letterboxing
	metadata.thumbnail = TableLookup(item, 'snippet.thumbnails.medium.url')

	self:SetMetadata(metadata, true)

	if self:IsTimed() then
		MediaPlayer.Metadata:Save(self)
	end

	callback(self._metadata)

end

function SERVICE:GetMetadata( callback )
	if self._metadata then
		callback( self._metadata )
		return
	end

	local cache = MediaPlayer.Metadata:Query(self)

	if MediaPlayer.DEBUG then
		print("MediaPlayer.GetMetadata Cache results:")
		PrintTable(cache or {})
	end

	if cache then

		local metadata = {}

		metadata.title = cache.title
		metadata.duration = tonumber(cache.duration)
		metadata.thumbnail = cache.thumbnail

		self:SetMetadata(metadata)

		if self:IsTimed() then
			MediaPlayer.Metadata:Save(self)
		end

		callback(self._metadata)

	else
		local videoId = self:GetYouTubeVideoId()
		local videoUrl = "https://www.youtube.com/watch?v="..videoId

		self:Fetch( videoUrl,
			--On Success
			function( body, length, headers, code )
				local metadata = self:ParseYTMetaDataFromHTML(body, videoId)

				--html couldn't be parsed
				if (!metadata.title || !metadata.duration) then
					callback(false, "Failed to parse HTML Page for metadata")
					return
				end

				self:SetMetadata(metadata, true)

				if self:IsTimed() then
					MediaPlayer.Metadata:Save(self)
				end
			
				callback(self._metadata)
			end,
			-- On failure
			function( code )
				callback(false, "Failed to load YouTube ["..tostring(code).."]")
			end,
			--Headers
			{
				["User-Agent"] = "Googlebot"
			}
		)
	end
end

---
-- Function to parse video metadata straight from the html instead of using the API
--
function SERVICE:ParseYTMetaDataFromHTML( html, videoId )

    -- Get the value for an attribute from a html element
    local function ParseElementAttribute( element, attribute )
        if !element then return end
        -- Find the desired attribute
        local output = string.match( element, attribute.."%s-=%s-%b\"\"" )
        if !output then return end
        -- Remove the 'attribute=' part
        output = string.gsub( output, attribute.."%s-=%s-", "" )
        -- Trim the quotes around the value string
        return string.sub( output, 2, -2 )
    end
    -- Get the contents of a html element by removing tags
    -- Used as fallback for when title cannot be found
    local function ParseElementContent( element )
        if !element then return end
        -- Trim start
        local output = string.gsub( element, "^%s-<%w->%s-", "" )
        -- Trim end
        return string.gsub( output, "%s-</%w->%s-$", "" )
	end
	
	--MetaData table to return when we're done
	local metadata = {}
    
    -- Lua search patterns to find metadata from the html
    local patterns = {
        ["title"] = "<meta%sproperty=\"og:title\"%s-content=%b\"\">",
        ["titlepat_fallback"] = "<title>.-</title>",
        ["thumb"] = "<meta%sproperty=\"og:image\"%s-content=%b\"\">",
        ["thumb_fallback"] = "<link%sitemprop=\"thumbnailUrl\"%s-href=%b\"\">",
        ["duration"] = "<meta%sitemprop%s-=%s-\"duration\"%s-content%s-=%s-%b\"\">",
        ["live"] = "<meta%sitemprop%s-=%s-\"isLiveBroadcast\"%s-content%s-=%s-%b\"\">"
    }

	-- Fetch title and thumbnail, with fallbacks if needed
	metadata.title = ParseElementAttribute(string.match(html, patterns["title"]), "content") 
		or ParseElementContent(string.match(body, patterns["title_fallback"]))

	metadata.thumbnail = ParseElementAttribute(string.match(html, patterns["thumb"]), "content") 
		or ParseElementAttribute(string.match(body, patterns["thumb_fallback"]), "href")

    -- See if the video is a live broadcast
    -- Set duration to 0 if it is, otherwise use the actual duration
    local isLiveBroadcast = tobool(ParseElementAttribute(string.match(html, patterns["live"]), "content"))
	if (isLiveBroadcast) then 
		-- Mark as live video
        metadata.duration = 0
    else 
        local durationISO8601 = ParseElementAttribute(string.match(html, patterns["duration"]), "content")
        metadata.duration = math.max(1, convertISO8601Time(durationISO8601))
    end

	return metadata
end
