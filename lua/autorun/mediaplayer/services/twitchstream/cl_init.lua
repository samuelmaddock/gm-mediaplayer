include "shared.lua"

DEFINE_BASECLASS( "mp_service_browser" )

local TwitchUrl = "http://www.twitch.tv/%s/popout"

local JS_HideControls = [[
document.body.style.cssText = 'overflow:hidden;height:106.8% !important';]]

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	local channel = self:GetTwitchChannel()
	local url = TwitchUrl:format(channel)

	browser:OpenURL( url )

	browser.OnFinishLoading = function(self)
		self:QueueJavascript(JS_HideControls)
	end

end
