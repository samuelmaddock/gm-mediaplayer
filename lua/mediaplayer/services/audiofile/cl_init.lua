include "shared.lua"

DEFINE_BASECLASS( "mp_service_base" )

-- http://www.un4seen.com/doc/#bass/BASS_StreamCreateURL.html

SERVICE.StreamOptions = { "noplay", "noblock" }

local MAX_LOAD_ATTEMPTS = 3

function SERVICE:Volume( volume )

	volume = BaseClass.Volume( self, volume )

	if IsValid(self.Channel) then
		local vol = volume > 1 and volume/100 or volume

		-- IGModAudioChannel is limited by the actual gmod volume
		-- local gmvolume = GetConVarNumber("volume")
		-- if gmvolume > vol then
		-- 	vol = vol / gmvolume
		-- else
		-- 	vol = 1
		-- end

		self.Channel:SetVolume( math.sqrt(vol) )
	end

	return volume

end

function SERVICE:Play()

	BaseClass.Play( self )

	if self.LoadAttempts and self.LoadAttempts >= MAX_LOAD_ATTEMPTS then
		-- TODO: display failure message to player
		MsgN( "Failed to load media after " .. MAX_LOAD_ATTEMPTS ..
			" attempts: " .. tostring(self.url) )
		return
	end

	if IsValid(self.Channel) then
		self.Channel:Play()
	else
		local settings = table.Copy(self.StreamOptions)

		-- .ogg files can't seem to use 3d?
		if IsValid(self.Entity) and not self.url:match(".ogg") then
			table.insert(settings, "3d")
		end

		settings = table.concat(settings, " ")

		sound.PlayURL( self.url, settings, function( channel )
			if IsValid(channel) then
				self.Channel = channel

				-- The song may have been skipped before the channel was
				-- created, only play if the media state is set to play.
				if self:IsPlaying() then
					self:Volume()
					self:Sync()

					self.Channel:Play()
				end

				self:emit('channelReady', channel)
				self.LoadAttempts = nil
			else
				self.LoadAttempts = (self.LoadAttempts or 0) + 1

				MsgN( "Failed to load media, trying again... " .. tostring(self.url) )

				-- Let's try again...
				timer.Simple( 2 ^ self.LoadAttempts, function()
					if self:IsPlaying() then
						self:Play()
					end
				end )
			end
		end )
	end

end

function SERVICE:Pause()
	BaseClass.Pause(self)

	if IsValid(self.Channel) then
		self.Channel:Pause()
	end
end

function SERVICE:Stop()
	BaseClass.Stop(self)

	if IsValid(self.Channel) then
		self.Channel:Stop()
	end
end

function SERVICE:Sync()
	if self:IsPlaying() and IsValid(self.Channel) then
		if self:IsTimed() then
			self:SyncTime()
		end

		self:SyncEntityPos()
	end
end

function SERVICE:SyncTime()
	local state = self.Channel:GetState()

	if state ~= GMOD_CHANNEL_STALLED then
		local duration = self.Channel:GetLength()
		local seekTime = math.min(duration, self:CurrentTime())
		local curTime = self.Channel:GetTime()
		local diffTime = math.abs(curTime - seekTime)

		if diffTime > 5 then
			self.Channel:SetTime( seekTime )
		end
	end
end

function SERVICE:SyncEntityPos()
	if IsValid(self.Entity) then

		if self.Channel:Is3D() then
			-- apparently these are the default values?
			self.Channel:Set3DFadeDistance( 500, 1000 )

			self.Channel:SetPos( self.Entity:GetPos() )
		else
			-- TODO: Fake 3D volume
			-- http://facepunch.com/showthread.php?t=1302124&p=41975238&viewfull=1#post41975238

			-- local volume = BaseClass.Volume( self, volume )
			-- local vol = volume > 1 and volume/100 or volume
			-- self.Channel:SetVolume( vol )
		end

	end
end

function SERVICE:PreRequest( callback )

	-- LocalPlayer():ChatPrint( "Prefetching data for '" .. self.url .. "'..." )

	sound.PlayURL( self.url, "noplay", function( channel )

		if MediaPlayer.DEBUG then
			print("AUDIOFILE.PreRequest", channel)
		end

		if IsValid(channel) then
			-- Set metadata to later send to the server; IGModAudioChannel is
			-- only accessible on the client.
			self._metadata = {}
			self._metadata.title = channel:GetFileName()
			self._metadata.duration = channel:GetLength()

			-- TODO: limit the duration in some way so a client doesn't try to
			-- spoof this

			callback()

			channel:Stop()
		else
			callback("There was a problem prefetching audio metadata.")
		end

	end )

end

function SERVICE:NetWriteRequest()
	net.WriteString( self:Title() )
	net.WriteUInt( self:Duration(), 16 )
end

--[[---------------------------------------------------------
	Draw 3D2D
-----------------------------------------------------------]]

local IsValid = IsValid
local draw = draw
local math = math
local surface = surface

local VisualizerBgColor = Color(44, 62, 80, 255)
local VisualizerBarColor = Color(52, 152, 219)

local BandGridHeight = 16
local BandGridWidth = math.ceil( BandGridHeight * 16/9 )

local NumBands = 256
local BandStepSize = math.floor(NumBands / BandGridWidth)

local BarPadding = 1

-- local BandGrid = {}

-- for x = 1, BandGridWidth do
-- 	BandGrid[x] = {}
-- 	for y = 1, BandGridHeight do
-- 		BandGrid[x][y] =
-- 	end
-- end

-- http://inchoatethoughts.com/a-wpf-spectrum-analyzer-for-audio-visualization
-- http://wpfsvl.codeplex.com/SourceControl/latest#WPFSoundVisualizationLib/Main/Source/WPFSoundVisualizationLibrary/Spectrum Analyzer/SpectrumAnalyzer.cs

--[[function MEDIAPLAYER:DrawSpectrumAnalyzer( media, w, h )

	local channel = media.Channel

	if channel:GetState() ~= GMOD_CHANNEL_PLAYING then
		return
	end

	local fft = {}
	channel:FFT( fft, FFT_512 )

	surface.SetDrawColor(VisualizerBarColor)

	local BarWidth = math.floor(w / BandGridWidth)
	local b0 = 1

	for x = 0, BandGridWidth do
		local sum = 0
		local sc = 0
		local b1 = math.pow(2, x * 10.0 / BandGridWidth)

		if (b1 > NumBands) then b1 = NumBands end
		if (b1<=b0) then b1 = b0 end

		sc=10+b1-b0

		while b0 < b1 do
			sum = sum + fft[b0]
			b0 = b0 + 1
		end

		local BarHeight = math.floor(math.sqrt(sum/math.log10(sc)) * 1.7 * h)
		BarHeight = math.Clamp(BarHeight, 0, h)

		surface.DrawRect(
			(x * BarWidth) + BarPadding,
			h - BarHeight,
			BarWidth - (BarPadding * 2),
			BarHeight
		)
	end

end]]

local BANDS	= 28

function DrawSpectrumAnalyzer( channel, w, h )

	-- Background
	surface.SetDrawColor( VisualizerBgColor )
	surface.DrawRect( 0, 0, w, h )

	if channel:GetState() ~= GMOD_CHANNEL_PLAYING then
		return
	end

	local fft = {}
	channel:FFT( fft, FFT_2048 )
	local b0 = 1

	-- surface.SetDrawColor(VisualizerBarColor)

	local x, y

	for x = 0, BANDS do
		local sum = 0
		local sc = 0
		local b1 = math.pow(2,x*10.0/(BANDS-1))

		if (b1>1023) then b1=1023 end
		if (b1<=b0) then b1=b0+1 end
		sc=10+b1-b0;
		while b0 < b1 do
			sum = sum + fft[b0]
			b0 = b0 + 1
		end

		y = (math.sqrt(sum/math.log10(sc))*1.7*h)-4
		y = math.Clamp(y, 0, h)

		local col = HSVToColor( 120 - (120 * y/h), 1, 1 )
		surface.SetDrawColor(col)

		surface.DrawRect(
			math.ceil(x*(w/BANDS)),
			math.ceil(h - y - 1),
			math.ceil(w/BANDS) - 2,
			y + 1
		)
	end
end


function SERVICE:Draw( w, h )

	if IsValid(self.Channel) then
		DrawSpectrumAnalyzer( self.Channel, w, h )
	end

end
