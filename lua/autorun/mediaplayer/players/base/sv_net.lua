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
