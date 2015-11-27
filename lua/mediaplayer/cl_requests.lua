local function GetMediaPlayerId( obj )
	local mpId

	-- Determine mp parameter type and get the associated ID.
	if isentity(obj) and obj.IsMediaPlayerEntity then
		mpId = obj:GetMediaPlayerID()
	-- elseif isentity(obj) and IsValid( obj:GetMediaPlayer() ) then
	-- 	local mp = mp:GetMediaPlayer()
	-- 	mpId = mp:GetId()
	elseif istable(obj) and obj.IsMediaPlayer then
		mpId = obj:GetId()
	elseif isstring(obj) then
		mpId = obj
	else
		return false -- Invalid parameters
	end

	return mpId
end

---
-- Request to begin listening to a media player.
--
-- @param Entity|Table|String	Media player reference.
--
function MediaPlayer.RequestListen( obj )

	local mpId = GetMediaPlayerId(obj)
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestListen" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Request mediaplayer update.
--
-- @param Entity|Table|String	Media player reference.
--
function MediaPlayer.RequestUpdate( obj )

	local mpId = GetMediaPlayerId(obj)
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestUpdate" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Request a URL to be played on the given media player.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Requested media URL.
--
function MediaPlayer.Request( obj, url )

	local mpId = GetMediaPlayerId( obj )
	if not mpId then return end

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.Request:", url, mpId)
	end

	local mp = MediaPlayer.GetById( mpId )

	local allowWebpage = MediaPlayer.Cvars.AllowWebpages:GetBool()

	-- Verify valid URL as to not waste time networking
	if not MediaPlayer.ValidUrl( url ) and not allowWebpage then
		LocalPlayer():ChatPrint("The requested URL was invalid.")
		return false
	end

	local media = MediaPlayer.GetMediaForUrl( url, allowWebpage )

	local function request( err )
		if err then
			-- TODO: don't use chatprint to notify the user
			LocalPlayer():ChatPrint( "Request failed: " .. err )
			return
		end

		if not IsValid( mp ) then
			-- media player may have been removed before we could finish the
			-- async prerequest action
			return
		end

		net.Start( "MEDIAPLAYER.RequestMedia" )
			net.WriteString( mpId )
			net.WriteString( url )
			media:NetWriteRequest() -- send any additional data
		net.SendToServer()

		if MediaPlayer.DEBUG then
			print("MEDIAPLAYER.Request sent to server")
		end
	end

	-- Prepare any data prior to requesting if necessary
	if media.PrefetchMetadata then
		media:PreRequest(request) -- async
	else
		request() -- sync
	end

end

function MediaPlayer.Pause( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestPause" )
		net.WriteString( mpId )
	net.SendToServer()

end

function MediaPlayer.Skip( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestSkip" )
		net.WriteString( mpId )
	net.SendToServer()

end

---
-- Seek to a specific time in the current media.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Seek time; HH:MM:SS
--
function MediaPlayer.Seek( mp, time )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	-- always convert to time in seconds before sending
	if type(time) == 'string' then
		time = MediaPlayerUtils.ParseHHMMSS(time) or 0
	end

	net.Start( "MEDIAPLAYER.RequestSeek" )
		net.WriteString( mpId )
		net.WriteInt( time, 32 )
	net.SendToServer()

end

---
-- Remove the given media.
--
-- @param Entity|Table|String	Media player reference.
-- @param String				Media unique ID.
--
function MediaPlayer.RequestRemove( mp, mediaUID )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestRemove" )
		net.WriteString( mpId )
		net.WriteString( mediaUID )
	net.SendToServer()

end

function MediaPlayer.RequestRepeat( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestRepeat" )
		net.WriteString( mpId )
	net.SendToServer()

end

function MediaPlayer.RequestShuffle( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestShuffle" )
		net.WriteString( mpId )
	net.SendToServer()

end

function MediaPlayer.RequestLock( mp )

	local mpId = GetMediaPlayerId( mp )
	if not mpId then return end

	net.Start( "MEDIAPLAYER.RequestLock" )
		net.WriteString( mpId )
	net.SendToServer()

end
