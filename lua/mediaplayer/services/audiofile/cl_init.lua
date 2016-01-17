include "shared.lua"

DEFINE_BASECLASS( "mp_service_base" )

-- http://www.un4seen.com/doc/#bass/BASS_StreamCreateURL.html

SERVICE.StreamOptions = { "noplay", "noblock" }

local MAX_LOAD_ATTEMPTS = 3
local Audio3DCvar = MediaPlayer.Cvars.Audio3D

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

	if IsValid(self.Channel) then
		self.Channel:Play()
	else
		local settings = table.Copy(self.StreamOptions)

		-- .ogg files can't seem to use 3d?
		if Audio3DCvar:GetBool() and IsValid(self.Entity) and
				not self.url:match(".ogg") then
			table.insert(settings, "3d")
		end

		settings = table.concat(settings, " ")

		local function loadAudio( callback )
			if not self:IsPlaying() or IsValid( self.Channel ) then return end
			MediaPlayerUtils.LoadStreamChannel( self.url, settings, callback )
		end

		-- Loading audio can fail the first time, so let's retry a few times
		-- before giving up.
		MediaPlayerUtils.Retry(
			loadAudio,
			function( channel )
				self.Channel = channel

				-- The song may have been skipped before the channel was
				-- created, only play if the media state is set to play.
				if self:IsPlaying() then
					self:Volume()
					self:Sync()

					self.Channel:Play()
				end

				self:emit('channelReady', channel)
			end,
			function()
				local msg = ("Failed to load media player audio '%s'"):format( self.url )
				LocalPlayer():ChatPrint( msg )
			end,
			MAX_LOAD_ATTEMPTS
		)
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

	local function preload( callback )
		MediaPlayerUtils.LoadStreamChannel( self.url, nil, callback )
	end

	-- Preloading audio can fail the first time, so let's retry a few times
	-- before giving up.
	MediaPlayerUtils.Retry(
		preload,
		function( channel )
			-- Set metadata to later send to the server; IGModAudioChannel is
			-- only accessible on the client.
			self:SetMetadataValue( "title", channel:GetFileName() )
			self:SetMetadataValue( "duration", channel:GetLength() )

			channel:Stop()
			callback()
		end,
		function()
			callback( "There was a problem receiving the audio stream, please try again." )
		end,
		MAX_LOAD_ATTEMPTS
	)

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
local VisualizerBarAlpha = 220

local BANDS	= 28

local function DrawSpectrumAnalyzer( fft, w, h )

	local b0 = 1
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
		col.a = VisualizerBarAlpha
		surface.SetDrawColor(col)

		surface.DrawRect(
			math.ceil(x*(w/BANDS)),
			math.ceil(h - y - 1),
			math.ceil(w/BANDS) - 2,
			y + 1
		)
	end

end


local HTMLMaterial = HTMLMaterial
local color_white = color_white
local FFT_2048 = FFT_2048
local GMOD_CHANNEL_PLAYING = GMOD_CHANNEL_PLAYING

local HTMLMAT_STYLE_ARTWORK = 'htmlmat.style.artwork'
AddHTMLMaterialStyle( HTMLMAT_STYLE_ARTWORK, {
	width = 720,
	height = 480
}, HTMLMAT_STYLE_COVER )

function SERVICE:Draw( w, h )

	surface.SetDrawColor( VisualizerBgColor )
	surface.DrawRect( 0, 0, w, h )

	local thumbnail = self:Thumbnail()
	if thumbnail then
		DrawHTMLMaterial( thumbnail, HTMLMAT_STYLE_ARTWORK, w, h )
	end

	local channel = self.Channel
	if IsValid(channel) and channel:GetState() == GMOD_CHANNEL_PLAYING then
		local fft = {}
		channel:FFT( fft, FFT_2048 )
		
		-- exposed on the table in case anyone wants to use this
		self.fft = fft
		
		DrawSpectrumAnalyzer( fft, w, h )
	end
	
	self:PostDraw()

end

function SERVICE:PostDraw()
	-- override this
end
