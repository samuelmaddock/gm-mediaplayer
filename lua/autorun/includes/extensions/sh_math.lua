local math = math
local ceil = math.ceil
local log = math.log
local pow = math.pow

-- Ceil the given number to the largest power of two
function math.CeilPower2(n)
	return pow(2, ceil(log(n) / log(2)))
end
