local string = string
local urllib = url
local os = os

local FormatSeconds = MediaPlayerUtils.FormatSeconds

SERVICE.Name 	= "Base Service"
SERVICE.Id 		= "base"
SERVICE.Abstract = true

-- Inherit EventEmitter for all service instances
EventEmitter:new(SERVICE)

local OwnerInfoPattern = "%s [%s]"

function SERVICE:New( url )
	local obj = setmetatable( {}, {
		__index = self,
		__tostring = self.__tostring
	} )

	obj.url = url

	local success, urlinfo = pcall(urllib.parse2, url)
	obj.urlinfo = success and urlinfo or {}

	if CLIENT then
		obj._playing = false
		obj._volume = 0.33
	end

	return obj
end

function SERVICE:__tostring()
	return string.format( '%s, %s, %s',
		self:Title(),
		FormatSeconds(self:Duration()),
		self:OwnerName() )
end

--
-- Determines if the media is valid.
--
-- @return boolean
--
function SERVICE:IsValid()
	return true
end

--
-- Determines if the media supports the given URL.
--
-- @param url URL.
-- @return boolean
--
function SERVICE:Match( url )
	return false
end

--
-- Gives the unique data used as part of the primary key in the metadata
-- database.
--
-- @return String
--
function SERVICE:Data()
	return self._data
end

function SERVICE:Owner()
	return self._Owner
end

SERVICE.GetOwner = SERVICE.Owner

function SERVICE:OwnerName()
	return self._OwnerName or ""
end

function SERVICE:OwnerSteamID()
	return self._OwnerSteamID or ""
end

function SERVICE:OwnerInfo()
	return OwnerInfoPattern:format( self._OwnerName, self._OwnerSteamID )
end

function SERVICE:IsOwner( ply )
	return ply == self:GetOwner() or
		ply:SteamID() == self:OwnerSteamID()
end

function SERVICE:Title()
	return self._metadata and self._metadata.title or "Unknown"
end

function SERVICE:Duration( duration )
	if duration then
		self._metadata = self._metadata or {}
		self._metadata.duration = duration
	end

	return self._metadata and self._metadata.duration or -1
end

--
-- Determines whether the media is timed.
--
-- @return boolean
--
function SERVICE:IsTimed()
	return true
end

function SERVICE:Thumbnail()
	return self._metadata and self._metadata.thumbnail
end

function SERVICE:Url()
	return self.url
end

SERVICE.URL = SERVICE.Url

function SERVICE:SetMetadata( metadata, new )
	self._metadata = metadata

	if new then
		local title = self._metadata.title or "Unknown"
		title = title:sub(1, MaxTitleLength)

		-- Escape any '%' char with a letter following it
		title = title:gsub('%%%a', '%%%%')

		self._metadata.title = title
	end
end

function SERVICE:SetMetadataValue( key, value )
	if not self._metadata then
		self._metadata = {}
	end

	self._metadata[key] = value
end

function SERVICE:GetMetadataValue( key )
	return self._metadata and self._metadata[key]
end

function SERVICE:UniqueID()
	if not self._id then
		local data = self:Data()
		if not data then
			data = util.CRC(self.url)
		end

		-- e.g. yt-G2MORmw703o
		self._id = string.format( "%s-%s", self.Id, data )
	end

	return self._id
end

--[[----------------------------------------------------------------------------
	Playback
------------------------------------------------------------------------------]]

function SERVICE:StartTime( seconds )
	if type(seconds) == 'number' then
		if self._PauseTime then
			self._PauseTime = RealTime()
		end

		self._StartTime = seconds
	end

	if self._PauseTime then
		local diff = self._PauseTime - self._StartTime
		return RealTime() - diff
	else
		return self._StartTime
	end
end

function SERVICE:CurrentTime()
	if self._StartTime then
		if self._PauseTime then
			return self._PauseTime - self._StartTime
		else
			return RealTime() - self._StartTime
		end
	else
		return -1
	end
end

function SERVICE:ResetTime()
	self._StartTime = nil
	self._PauseTime = nil
end

function SERVICE:IsPlaying()
	return self._playing
end

function SERVICE:Play()
	if self._PauseTime then
		-- Update start time to match the time when paused
		self._StartTime = RealTime() - (self._PauseTime - self._StartTime)
		self._PauseTime = nil
	end

	self._playing = true

	if CLIENT then
		self:emit('play')
	end
end

function SERVICE:Pause()
	self._PauseTime = RealTime()
	self._playing = false

	if CLIENT then
		self:emit('pause')
	end
end
