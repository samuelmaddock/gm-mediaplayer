include "shared.lua"

DEFINE_BASECLASS( "mp_service_browser" )

local JS_SetVolume = "if(window.MediaPlayer) MediaPlayer.setVolume(%s);"
local JS_Seek = "if(window.MediaPlayer) MediaPlayer.seek(%s);"

local function VimeoSetVolume( self )
	if not self.Browser then return end
	local js = JS_SetVolume:format( MediaPlayer.Volume() )
	self.Browser:RunJavascript(js)
end

local function VimeoSeek( self, seekTime )
	if not self.Browser then return end
	local js = JS_Seek:format( seekTime )
	self.Browser:RunJavascript(js)
end

function SERVICE:SetVolume( volume )
	VimeoSetVolume( self )
end

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	local videoId = self:GetVimeoVideoId()

	-- local url = VimeoVideoUrl:format( videoId )
	-- browser:OpenURL( url )

	-- browser:QueueJavascript( JS_Init )

	-- local html = EmbedHTML:format( videoId )
	-- html = self.WrapHTML( html )
	-- browser:SetHTML( html )

	local url = "http://localhost/vimeo.html#" .. videoId
	browser:OpenURL( url )

end

function SERVICE:Sync()
	local seekTime = self:CurrentTime()
	if seekTime > 0 then
		VimeoSeek( self, seekTime )
	end
end
