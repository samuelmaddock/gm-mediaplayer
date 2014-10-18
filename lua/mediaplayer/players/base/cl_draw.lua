local pcall = pcall
local Color = Color
local RealTime = RealTime
local ValidPanel = ValidPanel
local Vector = Vector
local cam = cam
local draw = draw
local math = math
local string = string
local surface = surface

local DrawHTMLPanel = MediaPlayerUtils.DrawHTMLPanel
local FormatSeconds = MediaPlayerUtils.FormatSeconds

local TEXT_ALIGN_CENTER	= draw.TEXT_ALIGN_CENTER
local TEXT_ALIGN_TOP	= draw.TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM	= draw.TEXT_ALIGN_BOTTOM
local TEXT_ALIGN_LEFT	= draw.TEXT_ALIGN_LEFT
local TEXT_ALIGN_RIGHT	= draw.TEXT_ALIGN_RIGHT

local TextPaddingX = 12
local TextPaddingY = 12

local TextBoxPaddingX = 8
local TextBoxPaddingY = 2

local TextBgColor = Color(0, 0, 0, 200)
local BarBgColor = Color(0, 0, 0, 200)
local BarFgColor = Color(255, 255, 255, 255)

local function DrawText( text, font, x, y, xalign, yalign )
	return draw.SimpleText( text, font, x, y, color_white, xalign, yalign )
end

local function DrawTextBox( text, font, x, y, xalign, yalign )

	xalign = xalign or TEXT_ALIGN_LEFT
	yalign = yalign or TEXT_ALIGN_TOP

	surface.SetFont( font )
	tw, th = surface.GetTextSize( text )

	if xalign == TEXT_ALIGN_CENTER then
		x = x - tw/2
	elseif xalign == TEXT_ALIGN_RIGHT then
		x = x - tw
	end

	if yalign == TEXT_ALIGN_CENTER then
		y = y - th/2
	elseif yalign == TEXT_ALIGN_BOTTOM then
		y = y - th
	end

	surface.SetDrawColor( TextBgColor )
	surface.DrawRect( x, y,
		tw + TextBoxPaddingX * 2,
		th + TextBoxPaddingY * 2 )

end

local UTF8SubLastCharPattern = "[^\128-\191][\128-\191]*$"
local OverflowString = "..." -- ellipsis

---
-- Limits a rendered string's width based on a maximum width.
--
-- @param text		Text string.
-- @param font		Font.
-- @param w			Maximum width.
-- @return String	String fitting the maximum required width.
--
local function RestrictStringWidth( text, font, w )

	-- TODO: Cache this

	surface.SetFont( font )
	local curwidth = surface.GetTextSize( text )
	local overflow = false

	-- Reduce text by one character until it fits
	while curwidth > w do

		-- Text has overflowed, append overflow string on return
		if not overflow then
			overflow = true
		end

		-- Cut off last character
		text = string.gsub(text, UTF8SubLastCharPattern, "")

		-- Check size again
		curwidth = surface.GetTextSize( text .. OverflowString )

	end

	return overflow and (text .. OverflowString) or text

end

function MEDIAPLAYER:DrawHTML( browser, w, h )
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawRect( 0, 0, w, h )
	DrawHTMLPanel( browser, w, h )
end

function MEDIAPLAYER:DrawMediaInfo( media, w, h )

	-- TODO: Fadeout media info instead of just hiding
	if not vgui.CursorVisible() and RealTime() - self._LastMediaUpdate > 3 then
		return
	end

	-- Text dimensions
	local tw, th

	-- Title background
	local titleStr = RestrictStringWidth( media:Title(), "MediaTitle",
		w - (TextPaddingX * 2 + TextBoxPaddingX * 2) )

	DrawTextBox( titleStr, "MediaTitle", TextPaddingX, TextPaddingY )

	-- Title
	DrawText( titleStr, "MediaTitle",
		TextPaddingX + TextBoxPaddingX,
		TextPaddingY + TextBoxPaddingY )

	-- Track bar
	if media:IsTimed() then

		local duration = media:Duration()
		local curTime = media:CurrentTime()
		local percent = math.Clamp( curTime / duration, 0, 1 )

		-- Bar height
		local bh = math.Round(h * 1/32)

		-- Bar background
		draw.RoundedBox( 0, 0, h - bh, w, bh, BarBgColor )

		-- Bar foreground (progress)
		draw.RoundedBox( 0, 0, h - bh, w * percent, bh, BarFgColor )

		local timeY = h - bh - TextPaddingY * 2

		-- Current time
		local curTimeStr = FormatSeconds(math.Clamp(math.Round(curTime), 0, duration))

		DrawTextBox( curTimeStr, "MediaTitle", TextPaddingX, timeY,
			TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
		DrawText( curTimeStr, "MediaTitle", TextPaddingX * 2, timeY,
			TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )

		-- Duration
		local durationStr = FormatSeconds( duration )

		DrawTextBox( durationStr, "MediaTitle", w - TextPaddingX * 2, timeY,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
		DrawText( durationStr, "MediaTitle", w - TextBoxPaddingX * 2, timeY,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )

	end

	-- Volume
	local volume = MediaPlayer.Volume()
	local volumeStr = tostring( math.Round( volume * 100 ) )

	-- DrawText( volumeStr, "MediaTitle", w - TextPaddingX, h/2,
		-- TEXT_ALIGN_CENTER )


	-- Loading indicator

end
