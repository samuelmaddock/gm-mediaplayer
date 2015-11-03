AddCSLuaFile "shared.lua"
include "shared.lua"

local urllib = url

local ClientId = MediaPlayer.GetConfigValue('soundcloud.client_id')

-- http://developers.soundcloud.com/docs/api/reference
local MetadataUrl = {
	resolve = "http://api.soundcloud.com/resolve.json?url=%s&client_id=" .. ClientId,
	tracks = ""
}

local function OnReceiveMetadata( self, callback, body )
	local resp = util.JSONToTable(body)
	if not resp then
		callback(false)
		return
	end

	if resp.errors then
		callback(false, "The requested SoundCloud song wasn't found")
		return
	end

	local artist = resp.user and resp.user.username or "[Unknown artist]"
	local stream = resp.stream_url

	if not stream then
		callback(false, "The requested SoundCloud song doesn't allow streaming")
		return
	end

	local thumbnail = resp.artwork_url
	if thumbnail then
		thumbnail = string.Replace( thumbnail, 'large', 't500x500' )
	end

	-- http://developers.soundcloud.com/docs/api/reference#tracks
	local metadata = {}
	metadata.title		= (resp.title or "[Unknown title]") .. " - " .. artist
	metadata.duration	= math.ceil(tonumber(resp.duration) / 1000) -- responds in ms
	metadata.thumbnail	= thumbnail

	metadata.extra = {
		stream = stream
	}

	self:SetMetadata(metadata, true)
	MediaPlayer.Metadata:Save(self)

	self.url = stream .. "?client_id=" .. ClientId

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

		metadata.extra = cache.extra

		self:SetMetadata(metadata)
		MediaPlayer.Metadata:Save(self)

		if metadata.extra then
			local extra = util.JSONToTable(metadata.extra)

			if extra.stream then
				self.url = tostring(extra.stream) .. "?client_id=" .. ClientId
			end
		end

		callback(self._metadata)

	else

		-- TODO: predetermine if we can skip the call to /resolve; check for
		-- /track or /playlist in the url path.

		local apiurl = MetadataUrl.resolve:format( self.url )

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
