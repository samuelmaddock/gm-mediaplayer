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
		local apiurl = MetadataUrl:format( videoId, APIKey )

		self:Fetch( apiurl,
			function( body, length, headers, code )
				OnReceiveMetadata( self, callback, body )
			end,
			function( code )
				callback(false, "Failed to load YouTube ["..tostring(code).."]")
			end
		)

	end
end
