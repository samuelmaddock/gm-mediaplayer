AddCSLuaFile "shared.lua"
include "shared.lua"

local TableLookup = MediaPlayerUtils.TableLookup
local htmlentities_decode = url.htmlentities_decode

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
			-- On Success
			function( body, length, headers, code )
				local status, metadata = pcall(self.ParseYTMetaDataFromHTML, self, body)

				-- html couldn't be parsed
				if not status or not metadata.title or not isnumber(metadata.duration) then
					-- Title is nil or Duration is nan
					if istable(metadata) then
						metadata = "title = "..type(metadata.title)..", duration = "..type(metadata.duration)
					end
					-- Misc error
					callback(false, "Failed to parse HTML Page for metadata: "..metadata)
					return
				end

				self:SetMetadata(metadata, true)

				if self:IsTimed() then
					MediaPlayer.Metadata:Save(self)
				end

				callback(self._metadata)
			end,
			-- On failure
			function( reason )
				callback(false, "Failed to fetch YouTube HTTP metadata [reason="..tostring(reason).."]")
			end,
			-- Headers
			{
				["User-Agent"] = "Googlebot"
			}
		)
	end
end

---
-- Get the value for an attribute from a html element
--
local function ParseElementAttribute( element, attribute )
	if not element then return end
	-- Find the desired attribute
	local output = string.match( element, attribute.."%s-=%s-%b\"\"" )
	if not output then return end
	-- Remove the 'attribute=' part
	output = string.gsub( output, attribute.."%s-=%s-", "" )
	-- Trim the quotes around the value string
	return string.sub( output, 2, -2 )
end

---
-- Get the contents of a html element by removing tags
-- Used as fallback for when title cannot be found
--
local function ParseElementContent( element )
	if not element then return end
	-- Trim start
	local output = string.gsub( element, "^%s-<%w->%s-", "" )
	-- Trim end
	return string.gsub( output, "%s-</%w->%s-$", "" )
end

-- Lua search patterns to find metadata from the html
local patterns = {
	["title"] = "<meta%sproperty=\"og:title\"%s-content=%b\"\">",
	["title_fallback"] = "<title>.-</title>",
	["thumb"] = "<meta%sproperty=\"og:image\"%s-content=%b\"\">",
	["thumb_fallback"] = "<link%sitemprop=\"thumbnailUrl\"%s-href=%b\"\">",
	["duration"] = "<meta%sitemprop%s-=%s-\"duration\"%s-content%s-=%s-%b\"\">",
	["live"] = "<meta%sitemprop%s-=%s-\"isLiveBroadcast\"%s-content%s-=%s-%b\"\">",
	["live_enddate"] = "<meta%sitemprop%s-=%s-\"endDate\"%s-content%s-=%s-%b\"\">"
}

---
-- Function to parse video metadata straight from the html instead of using the API
--
function SERVICE:ParseYTMetaDataFromHTML( html )
	--MetaData table to return when we're done
	local metadata = {}

	-- Fetch title and thumbnail, with fallbacks if needed
	metadata.title = ParseElementAttribute(string.match(html, patterns["title"]), "content")
		or ParseElementContent(string.match(html, patterns["title_fallback"]))

	-- Parse HTML entities in the title into symbols
	metadata.title = htmlentities_decode(metadata.title)

	metadata.thumbnail = ParseElementAttribute(string.match(html, patterns["thumb"]), "content")
		or ParseElementAttribute(string.match(html, patterns["thumb_fallback"]), "href")

	-- See if the video is an ongoing live broadcast
	-- Set duration to 0 if it is, otherwise use the actual duration
	local isLiveBroadcast = tobool(ParseElementAttribute(string.match(html, patterns["live"]), "content"))
	local broadcastEndDate = string.match(html, patterns["live_enddate"])
	if isLiveBroadcast and not broadcastEndDate then
		-- Mark as live video
		metadata.duration = 0
	else
		local durationISO8601 = ParseElementAttribute(string.match(html, patterns["duration"]), "content")
		if isstring(durationISO8601) then
			metadata.duration = math.max(1, convertISO8601Time(durationISO8601))
		end
	end

	return metadata
end
