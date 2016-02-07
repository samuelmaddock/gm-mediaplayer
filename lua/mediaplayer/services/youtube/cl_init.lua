include "shared.lua"

local urllib = url

local htmlBaseUrl = MediaPlayer.GetConfigValue('html.base_url')

DEFINE_BASECLASS( "mp_service_browser" )

-- https://developers.google.com/youtube/player_parameters
-- TODO: add closed caption option according to cvar
SERVICE.VideoUrlFormat = htmlBaseUrl .. "youtube.html"

local JS_SetVolume = "if(window.MediaPlayer) MediaPlayer.setVolume(%s);"
local JS_Seek = "if(window.MediaPlayer) MediaPlayer.seek(%s);"
local JS_Play = "if(window.MediaPlayer) MediaPlayer.play();"
local JS_Pause = "if(window.MediaPlayer) MediaPlayer.pause();"

local function YTSetVolume( self )
	-- if not self.playerId then return end
	local js = JS_SetVolume:format( MediaPlayer.Volume() * 100 )
	if self.Browser then
		self.Browser:RunJavascript(js)
	end
end

local function YTSeek( self, seekTime )
	-- if not self.playerId then return end
	local js = JS_Seek:format( seekTime )
	if self.Browser then
		self.Browser:RunJavascript(js)
	end
end

function SERVICE:SetVolume( volume )
	local js = JS_SetVolume:format( MediaPlayer.Volume() * 100 )
	self.Browser:RunJavascript(js)
end

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	-- Resume paused player
	if self._YTPaused then
		self.Browser:RunJavascript( JS_Play )
		self._YTPaused = nil
		return
	end

	local videoId = self:GetYouTubeVideoId()
	local timedParam = self:IsTimed() and '1' or '0'
	local url = self.VideoUrlFormat .. '?v=' .. videoId ..
				'&timed=' .. timedParam

	local curTime = self:CurrentTime()

	-- Add start time to URL if the video didn't just begin
	if self:IsTimed() and curTime > 3 then
		url = url .. "&start=" .. math.Round(curTime)
	end

	browser:OpenURL(url)

end

function SERVICE:Pause()
	BaseClass.Pause( self )

	if ValidPanel(self.Browser) then
		self.Browser:RunJavascript(JS_Pause)
		self._YTPaused = true
	end
end

function SERVICE:Sync()
	local seekTime = self:CurrentTime()
	if self:IsPlaying() and self:IsTimed() and seekTime > 0 then
		YTSeek( self, seekTime )
	end
end

function SERVICE:IsMouseInputEnabled()
	return IsValid( self.Browser )
end
