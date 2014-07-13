local CurTime = CurTime
local RealTime = RealTime
local FrameTime = FrameTime
local Material = Material
local pairs = pairs
local tonumber = tonumber
local table = table
local string = string
local type = type
local surface = surface
local HSVToColor = HSVToColor
local Lerp = Lerp
local Msg = Msg
local math = math
local draw = draw
local cam = cam
local Matrix = Matrix
local Angle = Angle
local Vector = Vector
local setmetatable = setmetatable
local ScrW = ScrW
local ScrH = ScrH
local ValidPanel = ValidPanel
local Color = Color
local color_white = color_white
local color_black = color_black
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER

function draw.HTMLPanel( panel, w, h )

	if not ValidPanel( panel ) then return end
	if not (w and h) then return end

	panel:UpdateHTMLTexture()

	local pw, ph = panel:GetSize()

	-- Convert to scalar
	w = w / pw
	h = h / ph

	-- Fix for non-power-of-two html panel size
	pw = math.CeilPower2(pw)
	ph = math.CeilPower2(ph)

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( panel:GetHTMLMaterial() )
	surface.DrawTexturedRect( 0, 0, w * pw, h * ph )

end

draw.HTMLTexture = draw.HTMLPanel

function draw.HTMLMaterial( mat, w, h )

	if not (w and h) then return end

	local pw, ph = w, h

	-- Convert to scalar
	w = w / pw
	h = h / ph

	-- Fix for non-power-of-two html panel size
	pw = math.CeilPower2(pw)
	ph = math.CeilPower2(ph)

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( mat )
	surface.DrawTexturedRect( 0, 0, w * pw, h * ph )

end
