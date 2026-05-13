local _, addon = ...
if not addon then
	addon = _G.Blizz or {}
	_G.Blizz = addon
end

-- core/eventbus.lua
-- Pub/Sub-Bus mit pcall-Error-Containment.
-- Subscriber-Errors landen in addon.errors (ring buffer, max 50).

local EventBus = {}
EventBus.__subscribers = {} -- [eventName] = { [token] = callback }
EventBus.__nextToken = 0
EventBus.__errors = addon.errors or {}
addon.errors = EventBus.__errors

local MAX_ERRORS = 50

local function log_error(event, err)
	table.insert(EventBus.__errors, {
		event = event,
		err = tostring(err),
		time = (GetTime and GetTime()) or 0,
	})
	while #EventBus.__errors > MAX_ERRORS do
		table.remove(EventBus.__errors, 1)
	end
end

function EventBus:subscribe(event, callback)
	assert(type(event) == "string", "event must be string")
	assert(type(callback) == "function", "callback must be function")
	self.__subscribers[event] = self.__subscribers[event] or {}
	self.__nextToken = self.__nextToken + 1
	local token = self.__nextToken
	self.__subscribers[event][token] = callback
	return { event = event, token = token }
end

function EventBus:unsubscribe(handle)
	if not handle or not self.__subscribers[handle.event] then
		return
	end
	self.__subscribers[handle.event][handle.token] = nil
end

function EventBus:dispatch(event, ...)
	local subs = self.__subscribers[event]
	if not subs then
		return
	end
	for _, cb in pairs(subs) do
		local ok, err = pcall(cb, ...)
		if not ok then
			log_error(event, err)
		end
	end
end

addon.EventBus = EventBus
return EventBus
