AddCSLuaFile "shared.lua"
include "shared.lua"

local urllib = url

local APIKey = MediaPlayer.GetConfigValue('twitch.client_id')
local MetadataUrl = "https://api.twitch.tv/kraken/videos/%s?client_id=%s"

local function OnReceiveMetadata( self, callback, body )

	local metadata = {}

	local response = util.JSONToTable( body )
	if not response then
		callback(false)
		return
	end

	-- Stream invalid
	if response.status and response.status == 404 then
		return callback( false, "Twitch.TV: " .. tostring(response.message) )
	end

	metadata.title = response.title
	metadata.duration = response.length

	-- Add 30 seconds to accomodate for ads in video over 5 minutes
	local duration = tonumber(metadata.duration)
	if duration and duration > ( 60 * 5 ) then
		metadata.duration = duration + 30
	end

	metadata.thumbnail = response.preview

	self:SetMetadata(metadata, true)
	MediaPlayer.Metadata:Save(self)

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
		metadata.duration = cache.duration
		metadata.thumbnail = cache.thumbnail

		self:SetMetadata(metadata)
		MediaPlayer.Metadata:Save(self)

		callback(self._metadata)

	else

		local info = self:GetTwitchVideoInfo()

		-- API call fix
		if info.type == 'b' then
			info.type = 'a'
		end

		local apiurl = MetadataUrl:format( info.type .. info.chapterId, APIKey )

		self:Fetch( apiurl,
			function( body, length, headers, code )
				OnReceiveMetadata( self, callback, body )
			end,
			function( code )
				callback(false, "Failed to load Twitch.TV ["..tostring(code).."]")
			end,

			-- Twitch.TV API v3 headers
			{
				["Accept"] = "application/vnd.twitchtv.v3+json"
			}
		)

	end
end
