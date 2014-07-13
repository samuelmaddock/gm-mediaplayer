include "shared.lua"

local urllib = url

DEFINE_BASECLASS( "mp_service_browser" )

-- https://developers.google.com/youtube/player_parameters
-- TODO: add closed caption option according to cvar
SERVICE.VideoUrlFormat = "https://www.youtube.com/embed/%s?enablejsapi=1&version=3&playerapiid=ytplayer&autoplay=1&controls=0&modestbranding=1&rel=0&showinfo=0"

-- YouTube player API
-- https://developers.google.com/youtube/js_api_reference
local JS_Init = [[
if (window.MediaPlayer === undefined) {
	window.MediaPlayer = (function(){
		var playerId = '%s',
			timed = %s;

		return {

			init: function () {
				if (this.player) return;
				this.player = document.getElementById(playerId);
				if (!this.player) {
					console.error('Unable to find YouTube player element!');
					return false;
				}
			},

			isPlayerReady: function () {
				return ( this.ytReady ||
					(this.player && (this.player.setVolume !== undefined)) );
			},

			setVolume: function ( volume ) {
				if (!this.isPlayerReady()) return;
				this.player.setVolume(volume);
			},

			play: function () {
				if (!this.isPlayerReady()) return;
				this.player.playVideo();
			},

			pause: function () {
				if (!this.isPlayerReady()) return;
				this.player.pauseVideo();
			},

			seek: function ( seekTime ) {
				if (!this.isPlayerReady()) return;
				if (!timed) return;

				var state, curTime, duration, diffTime;

				state = this.player.getPlayerState();

				/*if (state < 0) {
					this.player.playVideo();
				}*/

				if (state === 3) return;

				duration = this.player.getDuration();
				if (seekTime > duration) return;

				curTime = this.player.getCurrentTime();
				diffTime = Math.abs(curTime - seekTime);
				if (diffTime < 5) return;

				this.player.seekTo(seekTime, true);
			}

		};
	})();

	MediaPlayer.init();
}

window.onYouTubePlayerReady = function (playerId) {
	MediaPlayer.ytReady = true;
	MediaPlayer.init();
};
]]

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

	if not self._setupBrowser then

		-- This doesn't always get called in time, but it's a nice fallback
		browser:AddFunction( "window", "onYouTubePlayerReady", function( playerId )
			if not playerId then return end
			self.playerId = string.JavascriptSafe( playerId )

			-- Initialize JavaScript MediaPlayer interface
			local jsinit = JS_Init:format( self.playerId, self:IsTimed() )
			browser:RunJavascript( jsinit )

			YTSetVolume( self )
		end )

		self._setupBrowser = true

	end

	local videoId = self:GetYouTubeVideoId()
	local url = self.VideoUrlFormat:format( videoId )
	local curTime = self:CurrentTime()

	-- Add start time to URL if the video didn't just begin
	if self:IsTimed() and curTime > 3 then
		url = url .. "&start=" .. math.Round(curTime)
	end

	-- Trick the embed page into thinking the referrer is youtube.com; allows
	-- playing some restricted content due to the block by default behavior
	-- described here: http://stackoverflow.com/a/13463245/1490006
	url = urllib.escape(url)
	url = "http://www.gmtower.org/apps/mediaplayer/redirect.html#" .. url

	browser:OpenURL(url)

	-- Initialize JavaScript MediaPlayer interface
	local playerId = "player1"
	local jsinit = JS_Init:format( playerId, self:IsTimed() )
	browser:QueueJavascript( jsinit )

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
	if seekTime > 0 then
		YTSeek( self, seekTime )
	end
end
