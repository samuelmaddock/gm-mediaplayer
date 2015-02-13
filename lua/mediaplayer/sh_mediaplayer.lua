if SERVER then
	include "players/components/vote.lua"
	include "players/components/voteskip.lua"
end

--[[---------------------------------------------------------
	Media Player Types
-----------------------------------------------------------]]

MediaPlayer.Type = {}

local function setBaseClass( name, tbl )
	local classname = "mp_" .. name

	if MediaPlayer.Type[name] ~= nil then
		if MediaPlayer.DEBUG then
			Msg("Media player type '" .. name .. "' is already registered. ")
			Msg("Clearing baseclass...\n")
		end

		-- HACK: removes registered baseclass if it already exists to avoid Lua
		-- refresh table.Merge errors...
		local _, BaseClassTable = debug.getupvalue(baseclass.Get, 1)
		BaseClassTable[classname] = nil
	end

	baseclass.Set( classname, tbl )
end

---
-- Registers a media player type.
--
-- @param tbl	Media player type table.
--
function MediaPlayer.Register( tbl )

	local name = tbl.Name

	if not name then
		ErrorNoHalt("MediaPlayer.Register - Must include name property\n")
		debug.Trace()
		return
	end

	name = name:lower() -- always use lowercase names
	tbl.Name = name
	tbl.__index = tbl

	-- Set base meta table
	local base = tbl.Base or "base"
	if base and name ~= "base" then
		base = base:lower()

		if not MediaPlayer.Type[base] then
			ErrorNoHalt("MediaPlayer.Register - Invalid base name: " .. base .. "\n")
			debug.Trace()
			return
		end

		base = MediaPlayer.Type[base]

		setmetatable(tbl, {
			__index = base,
			__tostring = base.__tostring
		})
	end

	-- Store media player type as a base class
	setBaseClass( name, tbl )

	-- Save player type
	MediaPlayer.Type[name] = tbl

	if MediaPlayer.DEBUG then
		Msg( "MediaPlayer.Register\t" .. name .. "\n" )
	end

end

function MediaPlayer.IsValidType( type )
	return MediaPlayer.Type[type] ~= nil
end

-- Load players
do
	local path = "players/"
	local players = {
		"base", -- MUST LOAD FIRST!
		"entity"
	}

	for _, player in ipairs(players) do
		local clfile = path .. player .. "/cl_init.lua"
		local svfile = path .. player .. "/init.lua"

		MEDIAPLAYER = {}

		if SERVER then
			AddCSLuaFile(clfile)
			include(svfile)
		else
			include(clfile)
		end

		MediaPlayer.Register( MEDIAPLAYER )
		MEDIAPLAYER = nil
	end
end


--[[---------------------------------------------------------
	Media Player Helpers
-----------------------------------------------------------]]

MediaPlayer.List = MediaPlayer.List or {}
MediaPlayer._count = MediaPlayer._count or 0

---
-- Creates a media player object.
--
-- @param id		Media player ID.
-- @param type?		Media player type (defaults to 'base').
-- @return table	Media player object.
--
function MediaPlayer.Create( id, type )
	-- Inherit media player type
	local PlayerType = MediaPlayer.Type[type]
	PlayerType = PlayerType or MediaPlayer.Type.base

	-- Create media player object
	local mp = setmetatable( {}, { __index = PlayerType } )

	-- Assign unique ID
	if id then
		mp.id = id
	elseif SERVER then
		MediaPlayer._count = MediaPlayer._count + 1
		mp.id = MediaPlayer._count
	else
		mp.id = id or -1
	end

	mp:Init()

	-- Add to media player list
	MediaPlayer.List[mp.id] = mp

	if MediaPlayer.DEBUG then
		print( "Created Media Player", mp, mp.Name, type )
	end

	return mp
end

---
-- Destroys the given media player object.
--
-- @param table		Media player object.
--
function MediaPlayer.Destroy( mp )
	-- TODO: does this need anything else?
	MediaPlayer.List[mp.id] = nil

	if MediaPlayer.DEBUG then
		print( "Destroyed Media Player '" .. tostring(mp.id) .. "'" )
	end
end

---
-- Gets the media player associated with the given ID.
--
-- @param id		Media player ID.
-- @return table 	Media player object.
--
function MediaPlayer.GetById( id )
	local mp = MediaPlayer.List[id]
	if mp then
		return mp
	else
		-- Since entity indexes can change, let's iterate the list just to
		-- be sure...
		for _, mp in pairs(MediaPlayer.List) do
			if mp:GetId() == id then
				return mp
			end
		end
	end
end

---
-- Gets all active media players.
--
-- @return table	Array of all active media players.
--
function MediaPlayer.GetAll()
	local tbl = {}

	for _, mp in pairs( MediaPlayer.List ) do
		table.insert( tbl, mp )
	end

	return tbl
end

---
-- Gets the media player associated with the given object.
--
-- @param obj Any object.
--
function MediaPlayer.GetByObject( obj )
	local mp = nil

	if isentity(obj) and obj.IsMediaPlayerEntity then
		mp = obj:GetMediaPlayer()
	elseif istable(obj) and obj.IsMediaPlayer then
		mp = obj
	elseif isstring(obj) then
		mp = MediaPlayer.GetById(obj)
	end

	return mp
end


--[[---------------------------------------------------------
	Media Player Think Loop
-----------------------------------------------------------]]

MediaPlayer.ThinkInterval = 0.2 -- seconds

local function MediaPlayerThink()
	for id, mp in pairs( MediaPlayer.List ) do
		local succ, err = pcall(mp.Think, mp)
		if not succ then
			ErrorNoHalt(err .. "\n")

			-- TODO: recreate mediaplayer object instead
			mp:Remove()
		end
	end
end

if timer.Exists( "MediaPlayerThink" ) then
	timer.Destroy( "MediaPlayerThink" )
end

-- TODO: only start timer when at least one mediaplayer is created; stop it when
-- there are none left.
timer.Create( "MediaPlayerThink", MediaPlayer.ThinkInterval, 0, MediaPlayerThink )
timer.Start( "MediaPlayerThink" )
