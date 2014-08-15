local net = net

local EOT = "\4" -- End of transmission

MEDIAPLAYER.net = {}
local mpnet = MEDIAPLAYER.net

function mpnet.WriteDuration( seconds )
	net.WriteUInt( seconds, 16 )
end

function mpnet.WriteMedia( media )
	if media then
		net.WriteString( media:Url() )
		net.WriteString( media:Title() )
		mpnet.WriteDuration( media:Duration() )
		net.WriteString( media:OwnerName() )
		net.WriteString( media:OwnerSteamID() )
	else
		net.WriteString( EOT )
	end
end

local StateBits = math.CeilPower2(NUM_MP_STATE) / 2
function mpnet.WritePlayerState( state )
	net.WriteUInt(state, StateBits)
end

---
-- Writes the given epoch;
-- Unix epoch is a 32-bit signed integer.
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
		net.WriteInt( os.time(), 32 )
	end
end
