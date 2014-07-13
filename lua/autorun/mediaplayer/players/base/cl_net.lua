local net = net

local EOT = "\4" -- End of transmission

MEDIAPLAYER.net = {}
local mpnet = MEDIAPLAYER.net

function mpnet.ReadDuration()
	return net.ReadUInt(16)
end

function mpnet.ReadMedia()
	local url = net.ReadString()

	if url == EOT then
		return nil
	end

	local title = net.ReadString()
	local duration = mpnet.ReadDuration()
	local ownerName = net.ReadString()
	local ownerSteamId = net.ReadString()

	-- Create media object
	local media = MediaPlayer.GetMediaForUrl( url )

	-- Set metadata
	media._metadata = {
		title = title,
		duration = duration
	}

	media._OwnerName = ownerName
	media._OwnerSteamID = ownerSteamId

	return media
end

local StateBits = math.CeilPower2(NUM_MP_STATE) / 2
function mpnet.ReadPlayerState()
	return net.ReadUInt(StateBits)
end
