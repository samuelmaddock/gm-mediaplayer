local math = math
local ceil = math.ceil
local clamp = math.Clamp

local surface = surface
local color_white = color_white

local PANEL = {}

function PANEL:Init()

end

derma.DefineControl( "MP.Queue", "", PANEL, "Panel" )
