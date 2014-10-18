AddCSLuaFile "shared.lua"
include "shared.lua"

local TableLookup = MediaPlayerUtils.TableLookup

-- TODO:
-- https://video.google.com/get_player?wmode=opaque&ps=docs&partnerid=30&docid=0B9Kudw3An4Hnci1VZ0pwcHhJc00&enablejsapi=1
-- http://stackoverflow.com/questions/17779197/google-drive-embed-no-iframe
-- https://developers.google.com/drive/v2/reference/files/get

local APIKey = MediaPlayer.GetConfigValue('google.api_key')
local MetadataUrl = "https://www.googleapis.com/drive/v2/files/%s?key=%s"

local SupportedExtensions = { 'mp4' }

local function OnReceiveMetadata( self, callback, body )

	local metadata = {}

	local resp = util.JSONToTable( body )
	if not resp then
		return callback(false)
	end

	if resp.error then
		return callback(false, TableLookup(resp, 'error.message'))
	end

	local ext = resp.fileExtension or ''

	if not table.HasValue(SupportedExtensions, ext) then
		return callback(false, 'MediaPlayer currently only supports .mp4 Google Drive videos')
	end

	metadata.title = resp.title
	metadata.thumbnail = resp.thumbnailLink

	-- TODO: duration? etc.
	-- no duration metadata returned :(
	metadata.duration = 3600 * 4 -- default to 4 hours

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
		metadata.duration = tonumber(cache.duration)
		metadata.thumbnail = cache.thumbnail

		self:SetMetadata(metadata)
		MediaPlayer.Metadata:Save(self)

		callback(self._metadata)

	else

		local fileId = self:GetGoogleDriveFileId()
		local apiurl = MetadataUrl:format( fileId, APIKey )

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
