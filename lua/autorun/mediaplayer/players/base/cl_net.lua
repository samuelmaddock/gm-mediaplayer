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

---
-- Treshold for determining if server and client system time differ.
--
local TIME_OFFSET_THRESHOLD = 2

---
-- Adjusts time returned from the server in case server and client system clocks
-- are offset.
--
local function correctTime( time, serverTime )
	local curTime = os.time()
	local diffTime = os.difftime( serverTime, curTime )

	if diffTime > TIME_OFFSET_THRESHOLD then
		if MediaPlayer.DEBUG then
			print("mpnet.ReadTime: Server and client epoch differs", diffTime)
		end

		return time + diffTime
	else
		return time
	end
end

-- Unix epoch is a 32-bit signed integer
function mpnet.ReadTime()
	local time = net.ReadInt(32)
	local sync = net.ReadBit() == 1

	if sync then
		local serverTime = net.ReadInt(32)
		return correctTime(time, serverTime)
	else
		return time
	end
end
