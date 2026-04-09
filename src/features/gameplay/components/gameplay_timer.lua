local GamePlayTimerStyle = require("src.features.gameplay.components.gameplay_timer_style")

local GamePlayTimer = {}
GamePlayTimer.__index = GamePlayTimer

local function normalizeSeatValue(seat)
    if seat == nil then
        return nil
    end

    if type(seat) == "string" then
        local n = tonumber(seat)
        if n ~= nil then
            return n
        end
        return seat
    end

    if type(seat) == "number" then
        return seat
    end

    return seat
end

local function resolveSeatKey(self, seat)
    local value = normalizeSeatValue(seat)
    if value == nil then
        return nil
    end

    if self.anchors[value] then
        return value
    end

    if self.seatAlias and self.seatAlias[value] and self.anchors[self.seatAlias[value]] then
        return self.seatAlias[value]
    end

    local string_value = tostring(value)
    if self.seatAlias and self.seatAlias[string_value] and self.anchors[self.seatAlias[string_value]] then
        return self.seatAlias[string_value]
    end

    return value
end

function GamePlayTimer.new(options)
    local self = setmetatable({}, GamePlayTimer)

    self.currentSeat = nil
    self.duration = 15
    self.remaining = 0
    self.running = false
    self.expired = false
    self.expiredSeat = nil
    self.visible = true
    self.anchors = {}
    self.seatAlias = {}
    self.style = GamePlayTimerStyle.getDefaultStyle()

    self:init(options or {})
    return self
end

function GamePlayTimer:init(opts)
    opts = opts or {}

    self.style = GamePlayTimerStyle.getDefaultStyle()
    if opts.duration then
        self.duration = tonumber(opts.duration) or self.duration
    end
    if opts.style then
        GamePlayTimerStyle.apply(self.style, opts.style)
    end
    if opts.visible ~= nil then
        self.visible = not not opts.visible
    end

    self.currentSeat = nil
    self.remaining = 0
    self.running = false
    self.expired = false
    self.expiredSeat = nil
    self.anchors = {}
    self.seatAlias = {}
end

function GamePlayTimer:setVisible(v)
    self.visible = not not v
end

function GamePlayTimer:setDuration(seconds)
    self.duration = tonumber(seconds) or self.duration
end

function GamePlayTimer:setStyle(styleOverrides)
    GamePlayTimerStyle.apply(self.style, styleOverrides or {})
end

function GamePlayTimer:setSeatAnchor(seat, x, y)
    self.anchors[seat] = { x = x, y = y }
end

function GamePlayTimer:setSeatRect(seat, x, y, w, h)
    local s = self.style
    self.anchors[seat] = {
        x = x + w * 0.5 - s.w * 0.5,
        y = y - s.offsetY - s.h,
    }
end

function GamePlayTimer:clearSeatAnchor(seat)
    self.anchors[seat] = nil
end

function GamePlayTimer:setSeatAlias(rawSeat, timerKey)
    if rawSeat == nil or timerKey == nil then
        return
    end

    self.seatAlias[rawSeat] = timerKey
    self.seatAlias[tostring(rawSeat)] = timerKey
end

function GamePlayTimer:clearSeatAlias(rawSeat)
    if rawSeat == nil then
        return
    end

    self.seatAlias[rawSeat] = nil
    self.seatAlias[tostring(rawSeat)] = nil
end

function GamePlayTimer:clearAllSeatAlias()
    self.seatAlias = {}
end

function GamePlayTimer:startTurn(seat, seconds)
    local resolvedSeat = resolveSeatKey(self, seat)

    self.currentSeat = resolvedSeat
    self.duration = tonumber(seconds) or self.duration
    self.remaining = self.duration
    self.running = true
    self.expired = false
    self.expiredSeat = nil
end

function GamePlayTimer:syncTurn(seat, remaining, duration)
    local resolvedSeat = resolveSeatKey(self, seat)
    self.duration = math.max(0, tonumber(duration) or 0)
    self.remaining = math.max(0, tonumber(remaining) or 0)

    if not self.visible or resolvedSeat == nil or self.duration <= 0 or self.remaining <= 0 then
        self.currentSeat = nil
        self.running = false
        self.expired = false
        self.expiredSeat = nil
        return
    end

    self.currentSeat = resolvedSeat
    self.running = true
    self.expired = false
    self.expiredSeat = nil
end

function GamePlayTimer:stop()
    self.currentSeat = nil
    self.remaining = 0
    self.running = false
    self.expired = false
    self.expiredSeat = nil
end

function GamePlayTimer:pause()
    self.running = false
end

function GamePlayTimer:resume()
    if self.currentSeat and self.remaining > 0 then
        self.running = true
    end
end

function GamePlayTimer:isRunning()
    return self.running
end

function GamePlayTimer:getCurrentSeat()
    return self.currentSeat
end

function GamePlayTimer:getRemaining()
    return self.remaining
end

function GamePlayTimer:getRemainingInt()
    return math.max(0, math.ceil(self.remaining))
end

function GamePlayTimer:isExpired()
    return self.expired
end

function GamePlayTimer:consumeExpired()
    if not self.expired then
        return nil
    end

    local seat = self.expiredSeat
    self.expired = false
    self.expiredSeat = nil
    return seat
end

function GamePlayTimer:update(dt)
    if not self.visible or not self.running or not self.currentSeat then
        return
    end

    self.remaining = self.remaining - dt
    if self.remaining <= 0 then
        self.remaining = 0
        self.running = false
        self.expired = true
        self.expiredSeat = self.currentSeat
    end
end

function GamePlayTimer:draw()
    if not self.visible then
        return
    end

    if not self.currentSeat then
        return
    end

    if not self.anchors[self.currentSeat] then
        return
    end

    GamePlayTimerStyle.draw(self)
end

return GamePlayTimer
