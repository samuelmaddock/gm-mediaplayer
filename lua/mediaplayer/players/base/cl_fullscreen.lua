local pcall = pcall
local Color = Color
local RealTime = RealTime
local ScrW = ScrW
local ScrH = ScrH
local ValidPanel = ValidPanel
local Vector = Vector
local cam = cam
local draw = draw
local math = math
local string = string
local surface = surface

local FullscreenCvar = MediaPlayer.Cvars.Fullscreen

--[[---------------------------------------------------------
	Convar callback
-----------------------------------------------------------]]

local function OnFullscreenConVarChanged( name, old, new )

	new = (new == "1.00")
	old = (old == "1.00")

	local media

	for _, mp in pairs(MediaPlayer.List) do

		mp._LastMediaUpdate = RealTime()

		media = mp:CurrentMedia()

		if IsValid(media) and ValidPanel(media.Browser) then
			MediaPlayer.SetBrowserSize( media.Browser )
		end

	end

	MediaPlayer.SetBrowserSize( MediaPlayer.GetIdlescreen() )

	hook.Run( "MediaPlayerFullscreenToggled", new, old )

end
cvars.AddChangeCallback( FullscreenCvar:GetName(), OnFullscreenConVarChanged )


--[[---------------------------------------------------------
	Client controls for toggling fullscreen
-----------------------------------------------------------]]

inputhook.AddKeyPress( KEY_F11, "Toggle MediaPlayer Fullscreen", function()

	local isFullscreen = FullscreenCvar:GetBool()
	local numMp = #MediaPlayer.GetAll()

	-- only toggle if there's an active media player or we're in fullscreen mode
	if numMp == 0 and not isFullscreen then
		return
	end

	local value = isFullscreen and 0 or 1
	RunConsoleCommand( "mediaplayer_fullscreen", value )

end )


--[[---------------------------------------------------------
	Draw functions
-----------------------------------------------------------]]

function MEDIAPLAYER:DrawFullscreen()

	-- Don't draw if we're not fullscreen
	if not FullscreenCvar:GetBool() then return end

	local w, h = ScrW(), ScrH()
	local media = self:CurrentMedia()

	if IsValid(media) then

		-- Custom media draw function
		if media.Draw then
			media:Draw( w, h )
		end
		-- TODO: else draw 'not yet implemented' screen?

		-- Draw media info
		local succ, err = pcall( self.DrawMediaInfo, self, media, w, h )
		if not succ then
			print( err )
		end

	else

		local browser = MediaPlayer.GetIdlescreen()

		if ValidPanel(browser) then
			self:DrawHTML( browser, w, h )
		end

	end

end
