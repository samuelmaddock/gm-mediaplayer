-- TODO: mixins will be used for adding common functionality to mediaplayer
-- types. In this case, voting functionality for items in the media queue.

local VOTE = {}

function VOTE:New( ply, value )
	local obj = setmetatable({}, self)

	self.Player = ply
	self.value = value

	return obj
end

function MEDIAPLAYER:
