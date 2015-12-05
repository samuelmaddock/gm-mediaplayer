--[[---------------------------------------------------------
	Pass mouse clicks into media player browser
-----------------------------------------------------------]]

local MAX_SCREEN_DISTANCE = 1000

local function getScreenPos( ent, aimVector )
	local w, h, pos, ang = ent:GetMediaPlayerPosition()
	local eyePos = LocalPlayer():EyePos()

	if pos:Distance( eyePos ) > MAX_SCREEN_DISTANCE then
		return
	end

	local screenNormal = ang:Up()

	if screenNormal:Dot( aimVector ) > 0 then
		return -- prevent clicks from behind the screen
	end

	local hitPos = util.IntersectRayWithPlane(
		eyePos,
		aimVector,
		pos,
		screenNormal
	)

	if not hitPos then
		return
	end

	if MediaPlayer.DEBUG then
		debugoverlay.Cross( hitPos, 1, 60 )
	end

	local localPos = WorldToLocal( pos, ang, hitPos, ang )
	local x, y = -localPos.x, localPos.y

	if ( x < 0 or x > w ) or ( y < 0 or y > h ) then
		return -- out of screen bounds
	end

	return x / w, y / h
end

function MediaPlayer.DispatchScreenTrace( func, aimVector )
	if type(func) ~= "function" then return end
	if not aimVector then
		aimVector = LocalPlayer():GetAimVector()
	end

	for name, mp in pairs( MediaPlayer.List ) do
		local ent = mp.Entity
		if IsValid( mp ) and not ent:IsDormant() then
			local x, y = getScreenPos( ent, aimVector )
			if x and y then
				func(mp, x, y)
			end
		end
	end
end

local function mpMouseReleased( mp, x, y )
	mp:OnMousePressed(x, y)
end

local function mousePressed( mouseCode, aimVector )
	if mouseCode ~= MOUSE_LEFT then
		return
	end

	MediaPlayer.DispatchScreenTrace( mpMouseReleased, aimVector )
end
hook.Add( "GUIMouseReleased", "MediaPlayer.ScreenIntersect", mousePressed )


--[[---------------------------------------------------------
	Pass mouse scrolling into media player browser
-----------------------------------------------------------]]

local mouseScroll = MediaPlayerUtils.Throttle(function( dt )
	MediaPlayer.DispatchScreenTrace(function(mp)
		mp:OnMouseWheeled(dt)
	end, aimVector)
end, 0.01, { trailing = false })

hook.Add( "ContextMenuCreated", "MediaPlayer.Scroll", function( contextMenu )
	if contextMenu.OnMouseWheeled then return end
	contextMenu.OnMouseWheeled = function(panel, scrollDelta)
		mouseScroll(scrollDelta)
	end
end )

--[[
local function checkMouseScroll( ply, cmd )
	local scrollDelta = cmd:GetMouseWheel()
	if scrollDelta == 0 then return end
	mouseScroll(scrollDelta)
end
hook.Add( "StartCommand", "MediaPlayer.Scroll", checkMouseScroll )
]]

--[[---------------------------------------------------------
	Prevent weapons from firing while the context menu is
	open and the cursor is aiming at a screen.
-----------------------------------------------------------]]

local function isAimingAtScreen()
	local aimVector = LocalPlayer():GetAimVector()
	for name, mp in pairs( MediaPlayer.List ) do
		local ent = mp.Entity
		if IsValid( mp ) and not ent:IsDormant() then
			local x, y = getScreenPos( ent, aimVector )
			if x then
				return true
			end
		end
	end
end

local function preventWorldClicker()
	local ply = LocalPlayer()

	if not ply:IsWorldClicking() then return end

	local ent = ply:GetEyeTrace().Entity
	if not ( IsValid(ent) and ent.IsMediaPlayerEntity ) then return end

	if isAimingAtScreen() then
		return true
	end
end
hook.Add( "PreventScreenClicks", "MediaPlayer.PreventWorldClicker", preventWorldClicker )
