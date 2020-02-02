util.AddNetworkString( "MEDIAPLAYER.RequestListen" )
util.AddNetworkString( "MEDIAPLAYER.RequestUpdate" )
util.AddNetworkString( "MEDIAPLAYER.RequestMedia" )
util.AddNetworkString( "MEDIAPLAYER.RequestPause" )
util.AddNetworkString( "MEDIAPLAYER.RequestSkip" )
util.AddNetworkString( "MEDIAPLAYER.RequestSeek" )
util.AddNetworkString( "MEDIAPLAYER.RequestRemove" )
util.AddNetworkString( "MEDIAPLAYER.RequestRepeat" )
util.AddNetworkString( "MEDIAPLAYER.RequestShuffle" )
util.AddNetworkString( "MEDIAPLAYER.RequestLock" )

local REQUEST_DELAY = 0.2

local function RequestWrapper( func )
	local nextRequest
	return function( len, ply )
		if not IsValid(ply) then return end

		if nextRequest and nextRequest > RealTime() then
			return
		end

		local mpId = net.ReadString()
		local mp = MediaPlayer.GetById(mpId)
		if not IsValid(mp) then return end

		func( mp, ply )

		nextRequest = RealTime() + REQUEST_DELAY
	end
end

net.Receive( "MEDIAPLAYER.RequestListen", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestListen:", mpId, ply)
	end

	-- TODO: check if listener can actually be a listener
	if mp:HasListener(ply) then
		mp:RemoveListener(ply)
	else
		mp:AddListener(ply)
	end

end) )

---
-- Event called when a player requests a media update. This will occur when
-- a client determines it's not synced correctly.
--
-- @param len Net message length.
-- @param ply Player who sent the net message.
--
net.Receive( "MEDIAPLAYER.RequestUpdate", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestUpdate:", mpId, ply)
	end

	mp:SendMedia( mp:GetMedia(), ply )

end) )

net.Receive( "MEDIAPLAYER.RequestMedia", RequestWrapper(function(mp, ply)

	local url = net.ReadString()

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestMedia:", url, mp:GetId(), ply)
	end

	local allowWebpage = MediaPlayer.Cvars.AllowWebpages:GetBool()

	-- Validate the URL
	if not MediaPlayer.ValidUrl( url ) and not allowWebpage then
		mp:NotifyPlayer( ply, "The requested URL was invalid." )
		return
	end

	-- Build the media object for the URL
	local media = MediaPlayer.GetMediaForUrl( url, allowWebpage )
	media:NetReadRequest()

	mp:RequestMedia( media, ply )

end) )

net.Receive( "MEDIAPLAYER.RequestPause", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestPause:", mp:GetId(), ply)
	end

	mp:RequestPause( ply )

end) )

net.Receive( "MEDIAPLAYER.RequestSkip", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestSkip:", mp:GetId(), ply)
	end

	mp:RequestSkip( ply )

end) )

net.Receive( "MEDIAPLAYER.RequestSeek", RequestWrapper(function(mp, ply)

	local seekTime = net.ReadInt(32)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestSeek:", mp:GetId(), seekTime, ply)
	end

	mp:RequestSeek( ply, seekTime )

end) )

net.Receive( "MEDIAPLAYER.RequestRemove", RequestWrapper(function(mp, ply)

	local mediaUID = net.ReadString()

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestRemove:", mp:GetId(), mediaUID, ply)
	end

	mp:RequestRemove( ply, mediaUID )

end) )

net.Receive( "MEDIAPLAYER.RequestRepeat", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestRepeat:", mp:GetId(), ply)
	end

	mp:RequestRepeat( ply )

end) )

net.Receive( "MEDIAPLAYER.RequestShuffle", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestShuffle:", mp:GetId(), ply)
	end

	mp:RequestShuffle( ply )

end) )

net.Receive( "MEDIAPLAYER.RequestLock", RequestWrapper(function(mp, ply)

	if MediaPlayer.DEBUG then
		print("MEDIAPLAYER.RequestLock:", mp:GetId(), ply)
	end

	mp:RequestLock( ply )

end) )
