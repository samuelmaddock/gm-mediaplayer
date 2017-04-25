AddCSLuaFile "shared.lua"
include "shared.lua"

local urllib = url

local APIKey = MediaPlayer.GetConfigValue('twitch.client_id')
local MetadataUrl = "https://api.twitch.tv/kraken/streams/%s?client_id=%s"

local function OnReceiveMetadata( self, callback, body )

	local metadata = {}

	local response = util.JSONToTable( body )
	if not response then
		callback(false)
		return
	end
	
	local stream = response.stream

	-- Stream offline
	if not stream then
		return callback( false, "Twitch.TV: The requested stream was offline" )
	end

	local channel = stream.channel
	local status = channel and channel.status or "Twitch.TV Stream"

	metadata.title = status
	metadata.thumbnail = stream.preview.medium

	self:SetMetadata(metadata, true)

	callback(self._metadata)

end

function SERVICE:GetMetadata( callback )

	if self._metadata then
		callback( self._metadata )
		return
	end

	local channel = self:GetTwitchChannel()
	local apiurl = MetadataUrl:format( channel, APIKey )

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