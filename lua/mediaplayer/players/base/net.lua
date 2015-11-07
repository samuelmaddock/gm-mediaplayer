local net = net
local CeilPower2 = MediaPlayerUtils.CeilPower2

local EOT = "\4" -- End of transmission

MEDIAPLAYER.net = {}
local mpnet = MEDIAPLAYER.net

function mpnet.ReadDuration()
	return net.ReadUInt(16)
end

function mpnet.WriteDuration( seconds )
	net.WriteUInt( seconds, 16 )
end

function mpnet.ReadMedia()
	local uid = net.ReadString()

	if uid == EOT then
		return nil
	end

	local url = net.ReadString()
	local metadata = net.ReadTable()
	local ownerName = net.ReadString()
	local ownerSteamId = net.ReadString()

	-- Create media object
	local media = MediaPlayer.GetMediaForUrl( url, true )

	-- Set uniqud ID to match the server
	media._id = uid

	media:SetMetadata( metadata, true )
	media._OwnerName = ownerName
	media._OwnerSteamID = ownerSteamId

	return media
end

function mpnet.WriteMedia( media )
	if media then
		net.WriteString( media:UniqueID() )
		net.WriteString( media:Url() )
		net.WriteTable( media._metadata or {} )
		net.WriteString( media:OwnerName() )
		net.WriteString( media:OwnerSteamID() )
	else
		net.WriteString( EOT )
	end
end

local StateBits = CeilPower2(NUM_MP_STATE) / 2

function mpnet.ReadPlayerState()
	return net.ReadUInt(StateBits)
end

function mpnet.WritePlayerState( state )
	net.WriteUInt(state, StateBits)
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
-- Writes the given epoch.
--
-- @param time Epoch.
-- @param sync Whether the time should be synced on the client (default: true).
--
function mpnet.WriteTime( time, sync )
	if sync == nil then sync = true end
	sync = tobool(sync)

	net.WriteInt( time, 32 )
	net.WriteBit( sync )

	if sync then
		-- We must send the current time in case either the server or the
		-- client's system clock is offset.
		net.WriteInt( RealTime(), 32 )
	end
end

---
-- Read a vote value or count.
--
function mpnet.ReadVote()
	return net.ReadInt(9)
end

---
-- Write a vote value or count.
--
function mpnet.WriteVote( value )
	net.WriteInt( value, 9 )
end
