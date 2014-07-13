include "shared.lua"

DEFINE_BASECLASS( "mp_service_browser" )

-- data:text/html,<object type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" wmode="opaque" data="https://video.google.com/get_player?docid=0B1K_ByAqaFKGamdrajd6WXFUSEs0VHI4eTJHNHpPdw&partnerid=30&el=leaf&cc_load_policy=1&enablejsapi=1&autoplay=1&start=30" width="100%" height="100%" style="visibility: visible;"></object>

-- https://docs.google.com/file/d/0B1K_ByAqaFKGamdrajd6WXFUSEs0VHI4eTJHNHpPdw/preview

local EmbedHtml = [[
<object type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" wmode="opaque" data="%s" width="100%%" height="100%%" style="visibility: visible;"></object>]]

SERVICE.VideoUrlFormat = "https://video.google.com/get_player?docid=%s&enablejsapi=1&autoplay=1&controls=0&modestbranding=1&rel=0&showinfo=0&wmode=opaque&ps=docs&partnerid=30"

function SERVICE:OnBrowserReady( browser )

	BaseClass.OnBrowserReady( self, browser )

	local fileId = self:GetGoogleDriveFileId()

	local url = self.VideoUrlFormat:format(fileId)
	local curTime = self:CurrentTime()

	-- Add start time to URL if the video didn't just begin
	if self:IsTimed() and curTime > 3 then
		url = url .. "&start=" .. math.Round(curTime)
	end

	local html = self.WrapHTML( EmbedHtml:format(url) )
	browser:SetHTML( html )

end
