local function LoadMediaPlayer()
	print( "Loading 'mediaplayer' addon..." )

	-- Check if MediaPlayer has already been loaded
	if MediaPlayer then
		MediaPlayer.__refresh = true

		-- HACK: Lua refresh fix; access local variable of baseclass lib
		local _, BaseClassTable = debug.getupvalue(baseclass.Get, 1)
		for classname, _ in pairs(BaseClassTable) do
			if classname:find("mp_") then
				BaseClassTable[classname] = nil
			end
		end
	end

	-- shared includes
	IncludeCS "includes/extensions/sh_file.lua"
	IncludeCS "includes/extensions/sh_math.lua"
	IncludeCS "includes/extensions/sh_table.lua"
	IncludeCS "includes/extensions/sh_url.lua"
	IncludeCS "includes/modules/EventEmitter.lua"

	if SERVER then
		-- download clientside includes
		AddCSLuaFile "includes/modules/browserpool.lua"
		AddCSLuaFile "includes/modules/control.lua"
		AddCSLuaFile "includes/modules/htmlmaterial.lua"
		AddCSLuaFile "includes/extensions/cl_draw.lua"

		-- initialize serverside mediaplayer
		include "mediaplayer/init.lua"
	else
		-- clientside includes
		include "includes/modules/browserpool.lua"
		include "includes/modules/control.lua"
		include "includes/modules/htmlmaterial.lua"
		include "includes/extensions/cl_draw.lua"

		-- initialize clientside mediaplayer
		include "mediaplayer/cl_init.lua"
	end

	-- Sandbox includes; these must always be included as the gamemode is still
	-- set as 'base' when the addon is loading. Can't check if gamemode derives
	-- Sandbox.
	IncludeCS "menubar/mp_options.lua"
	include "properties/mediaplayer.lua"

	if SERVER then
		-- Reinstall media players on Lua refresh
		for _, mp in pairs(MediaPlayer.GetAll()) do
			if IsValid(mp.Entity) then
				-- cache entity
				local ent = mp.Entity
				local queue = mp._Queue
				local listeners = mp._Listeners

				-- remove media player
				mp:Remove()

				-- install new media player
				ent:InstallMediaPlayer()

				-- reinitialize settings
				mp = ent._mp
				-- mp._Queue = queue

				-- TODO: reapply listeners, for some reason the table is empty
				-- after Lua refresh
				mp:SetListeners( listeners )
			end
		end
	end
end

-- First time load
LoadMediaPlayer()

-- Fix for Lua refresh not always working...
hook.Add( "OnReloaded", "MediaPlayerRefresh", LoadMediaPlayer )
