--[[---------------------------------------------------------
	Media Player History
-----------------------------------------------------------]]

MediaPlayer.History = {}

---
-- Default metadata table name
-- @type String
--
local TableName = "mediaplayer_history"

---
-- SQLite table struct
-- @type String
--
local TableStruct = string.format([[
CREATE TABLE %s (
	id				INTEGER PRIMARY KEY AUTOINCREMENT,
	mediaid			VARCHAR(48),
	url				VARCHAR(512),
	player_name		VARCHAR(32),
	steamid			VARCHAR(32),
	time			DATETIME DEFAULT CURRENT_TIMESTAMP
)]], TableName)

---
-- Default number of results to return
-- @type Integer
--
local DefaultResultLimit = 100

---
-- Log the given media as a request.
--
-- @param media		Media service object.
-- @return table	SQL query results.
--
function MediaPlayer.History:LogRequest( media )
	local id = media:UniqueID()
	if not id then return end

	local ply = media:GetOwner()
	if not IsValid(ply) then return end

	local query = string.format( "INSERT INTO `%s` " ..
			"(mediaid,url,player_name,steamid) " ..
			"VALUES ('%s',%s,%s,'%s')",
			TableName,
			media:UniqueID(),
			sql.SQLStr( media:Url() ),
			sql.SQLStr( ply:Nick() ),
			ply:SteamID64() or -1 )

	local result = sql.Query(query)

	if MediaPlayer.DEBUG then
		print("MediaPlayer.History.LogRequest")
		print(query)
		if istable(result) then
			PrintTable(result)
		else
			print(result)
		end
	end

	return result
end

function MediaPlayer.History:GetRequestsByPlayer( ply, limit )
	if not isnumber(limit) then
		limit = DefaultResultLimit
	end

	local query = string.format( [[
SELECT H.*, M.title, M.thumbnail, M.duration
FROM %s AS H
JOIN mediaplayer_metadata AS M
	ON (M.id = H.mediaid)
WHERE steamid='%s'
LIMIT %d]],
			TableName,
			ply:SteamID64() or -1,
			limit )

	local result = sql.Query(query)

	if MediaPlayer.DEBUG then
		print("MediaPlayer.History.GetRequestsByPlayer", ply, limit)
		print(query)
		if istable(result) then
			PrintTable(result)
		else
			print(result)
		end
	end

	return result
end

-- Create the SQLite table if it doesn't exist
if not sql.TableExists(TableName) then
	Msg("MediaPlayer.History: Creating `" .. TableName .. "` table...\n")
	print(sql.Query(TableStruct))
end
