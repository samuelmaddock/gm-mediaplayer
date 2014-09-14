local net = net

local EOT = "\4" -- End of transmission

MEDIAPLAYER.net = {}
local mpnet = MEDIAPLAYER.net

function mpnet.ReadDuration()
	return net.ReadUInt(16)
end

function mpnet.ReadMedia()
	local uid = net.ReadString()

	if uid == EOT then
		return nil
	end

	local url = net.ReadString()
	local title = net.ReadString()
	local duration = mpnet.ReadDuration()
	local ownerName = net.ReadString()
	local ownerSteamId = net.ReadString()

	-- Create media object
	local media = MediaPlayer.GetMediaForUrl( url )

	-- Set uniqud ID to match the server
	media._id = uid

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
-- Threshold for determining if server and client system time differ.
--
local TIME_OFFSET_THRESHOLD = 2

---
-- Adjusts time returned from the server since RealTime will always differ.
--
local function correctTime( time, serverTime )
	local curTime = RealTime()
	local diffTime = os.difftime( serverTime, curTime )

	if math.abs(diffTime) > TIME_OFFSET_THRESHOLD then
		return time - diffTime
	else
		return time
	end
end

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

---
-- Read a vote value; uses [-8,8] as the limit in case someone wants to have
-- a vote value count more than once.
--
function mpnet.ReadVote()
	return net.ReadInt(3)
end
