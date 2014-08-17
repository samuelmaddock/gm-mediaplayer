---
-- EventEmitter
--
-- Based off of Wolfy87's JavaScript EventEmitter
--
local EventEmitter = {}

local function indexOfListener(listeners, listener)
	local value
	local i = #listeners


	while i > 0 do
		value = listeners[i]
		if type(value) == 'table' and value.listener == listener then
			return i
		end
		i = i - 1
	end

	return -1
end

function EventEmitter:new(obj)
	if obj then
		table.Inherit(obj, self)
	else
		return setmetatable({}, self)
	end
end

function EventEmitter:getListeners(evt)
	local events = self:_getEvents()
	local response

	-- TODO: accept pattern matching

	if not events[evt] then
		local tbl = {}
		tbl.__array = true
		events[evt] = tbl
	end

	response = events[evt]

	return response
end

--[[function EventEmitter:flattenListeners(listeners)

end]]

function EventEmitter:getListenersAsObject(evt)
	local listeners = self:getListeners(evt)
	local response

	if listeners.__array then
		response = {}
		response[evt] = listeners
	end

	return response or listeners, wrapped
end

function EventEmitter:addListener(evt, listener)
	local listeners = self:getListenersAsObject(evt)
	local listenerIsWrapped = type(listener) == 'table'

	for key, _ in pairs(listeners) do
		if rawget(listeners, key) and indexOfListener(listeners[key], listener) == -1 then
			local value

			if listenerIsWrapped then
				value = listener
			else
				value = {
					listener = listener,
					once = false
				}
			end

			table.insert(listeners[key], value)
		end
	end

	return self
end

EventEmitter.on = EventEmitter.addListener

function EventEmitter:addOnceListener(evt, listener)
	return self:addListener(evt, {
		listener = listener,
		once = true
	})
end

EventEmitter.once = EventEmitter.addOnceListener

function EventEmitter:removeListener(evt, listener)
	local listeners = self:getListenersAsObject(evt)
	local index

	for key, _ in pairs(listeners) do
		if rawget(listeners, key) then
			index = indexOfListener(listeners[key], listener)

			if index ~= -1 then
				table.remove(listeners[key], index)
			end
		end
	end

	return self
end

EventEmitter.off = EventEmitter.removeListener

--[[function EventEmitter:addListeners(evt, listeners)

end]]

function EventEmitter:removeEvent(evt)
	local typeStr = type(evt)
	local events = self:_getEvents()
	local key

	if typeStr == 'string' then
		events[evt] = nil
	else
		self._events = nil
	end

	return self
end

EventEmitter.removeAllListeners = EventEmitter.removeEvent

function EventEmitter:emitEvent(evt, ...)
	local listeners = self:getListenersAsObject(evt)
	local listener, i, key, response

	for key, _ in pairs(listeners) do
		if rawget(listeners, key) then
			i = #listeners[key]

			while i > 0 do
				listener = listeners[key][i]

				if listener.once == true then
					self:removeListener(evt, listener.listener)
				end

				response = listener.listener(...)

				if response == self:_getOnceReturnValue() then
					self:removeListener(evt, listener.listener)
				end

				i = i - 1
			end
		end
	end

	return self
end

EventEmitter.trigger = EventEmitter.emitEvent
EventEmitter.emit = EventEmitter.emitEvent

function EventEmitter:setOnceReturnValue(value)
	self._onceReturnValue = value
	return self
end

function EventEmitter:_getOnceReturnValue()
	if rawget(self, '_onceReturnValue') then
		return self._onceReturnValue
	else
		return true
	end
end

function EventEmitter:_getEvents()
	if not self._events then
		self._events = {}
	end

	return self._events
end

_G.EventEmitter = EventEmitter
