include "shared.lua"

DEFINE_BASECLASS( "mp_service_browser" )

local TwitchUrl = "http://www.twitch.tv/%s/%s/%s/popout"

---
-- Approximate amount of time it takes for the Twitch video player to load upon
-- loading the webpage.
--
local playerLoadDelay = 5

local secMinute = 60
local secHour = secMinute * 60

local function formatTwitchTime( seconds )
	local hours = math.floor((seconds / secHour) % 24)
	local minutes = math.floor((seconds / secMinute) % 60)
	seconds = math.floor(seconds % 60)

	local tbl = {}

	if hours > 0 then
		table.insert(tbl, hours)
		table.insert(tbl, 'h')
	end

	if hours > 0 or minutes > 0 then
		table.insert(tbl, minutes)
		table.insert(tbl, 'm')
	end

	table.insert(tbl, seconds)
	table.insert(tbl, 's')

	return table.concat(tbl, '')
end

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	local info = self:GetTwitchVideoInfo()
	local url = TwitchUrl:format(info.channel, info.type, info.chapterId)

	-- Move current time forward due to twitch player load time
	local curTime = math.min( self:CurrentTime() + playerLoadDelay, self:Duration() )

	local time = math.ceil( curTime )
	if time > 5 then
		url = url .. '?t=' .. formatTwitchTime(time)
	end

	browser:OpenURL( url )

end
