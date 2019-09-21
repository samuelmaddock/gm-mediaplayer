SERVICE = {}
SERVICE.Name = "HTML5 Video"
SERVICE.Id = "h5v"
SERVICE.Base = "res"
SERVICE.FileExtensions = {'webm'} -- 'mp4',	-- not yet supported by Awesomium -- 'ogg'	-- already registered as audio, need a work-around :(
local base = baseclass.Get"mp_service_base"
local res = baseclass.Get"mp_service_res"

local MimeTypes = {
	webm = "video/webm",
	mp4 = "video/mp4",
	ogg = "video/ogg"
}

local EmbedHTML = [[
<video id="player" autoplay style="
		width: 100%%;
		height: 100%%;">
	<source src="%s" type="%s">
</video>
]]
local JS_Volume = [[(function () {
	var elem = document.getElementById('player');
	if (elem) {
		elem.volume = %s;
	}
}());]]
local JS_Seek = [[(function () {
	var elem = document.getElementById('player');
	if (elem) {
		var time = %s;
		var ctime = elem.currentTime;
		var diff = time-ctime;
		if (diff<0) { diff=-diff; };
		if (diff>2) {
			elem.currentTime = time;
		}
	}
}());]]
local JS_Play = [[(function () {
	var elem = document.getElementById('player');
	if (elem) {		
	elem.play();

	}
}());]]
local JS_Pause = [[(function () {
	var elem = document.getElementById('player');
	if (elem) {
		elem.pause();
	}
}());]]

local function VideoElementSeek(self, seekTime)
	if not self.Browser then return end
	local js = JS_Seek:format(seekTime)
	self.Browser:RunJavascript(js)
end

function SERVICE:GetHTML()
	local url = self.url
	local path = self.urlinfo.path
	local ext = path:match("[^/]+%.(%S+)$")
	local mime = MimeTypes[ext]

	return EmbedHTML:format(url, mime)
end

function SERVICE:Volume(volume)
	local origVolume = volume
	volume = base.Volume(self, volume)

	if origVolume and ValidPanel(self.Browser) then
		self.Browser:RunJavascript(JS_Volume:format(volume))
	end
end

function SERVICE:IsTimed()
	return true
end

function SERVICE:GetMetadata(callback)
	res.GetMetadata(self, function(meta)
		meta.duration = 60 * 60 * 4

		if callback then
			callback(meta)
		end
	end)
end

if CLIENT then
	function SERVICE:Pause()
		res.Pause(self)

		if ValidPanel(self.Browser) then
			self.Browser:RunJavascript(JS_Pauser)
			self._YTPaused = true
		end
	end

	function SERVICE:Play()
		res.Play(self)

		if ValidPanel(self.Browser) then
			self.Browser:RunJavascript(JS_Play)
		end
	end
end

function SERVICE:Sync()
	--print("sync", self, "|")
	local seekTime = self:CurrentTime()

	if seekTime > 0 then
		VideoElementSeek(self, seekTime)
	end
end

MediaPlayer.RegisterService(SERVICE)