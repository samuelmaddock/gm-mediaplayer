include "shared.lua"

local htmlBaseUrl = MediaPlayer.GetConfigValue('html.base_url')

DEFINE_BASECLASS( "mp_service_browser" )

local TwitchUrl = "http://www.twitch.tv/%s/popout"

local JS_Play = "if(window.MediaPlayer) MediaPlayer.play();"
local JS_Pause = "if(window.MediaPlayer) MediaPlayer.pause();"

local JS_HideControls = [[
document.body.style.cssText = 'overflow:hidden;height:106.8% !important';]]

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	local channel = self:GetTwitchChannel()
	local url = TwitchUrl:format(channel)

	browser:OpenURL( url )

	browser:QueueJavascript( JS_HideControls )
	self:InjectScript( htmlBaseUrl .. "scripts/services/twitch.js" )

end

function SERVICE:Pause()
	BaseClass.Pause( self )

	if ValidPanel(self.Browser) then
		self.Browser:RunJavascript(JS_Pause)
		self._YTPaused = true
	end
end
