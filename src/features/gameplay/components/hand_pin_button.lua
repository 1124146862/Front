local HandButtonPinStyle = require("src.features.gameplay.components.hand_button_pin_style")

local HandPinButton = {}
HandPinButton.__index = HandPinButton

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.w
        and y >= bounds.y
        and y <= bounds.y + bounds.h
end

function HandPinButton.new()
    return setmetatable({
        style = HandButtonPinStyle,
        hover_t = 0,
        press_t = 0,
        active_t = 0,
    }, HandPinButton)
end

function HandPinButton:getSize()
    return self.style.w, self.style.h
end

function HandPinButton:contains(bounds, x, y)
    return contains(bounds, x, y)
end

function HandPinButton:update(dt, hovered, activated)
    local target_hover = hovered and 1 or 0
    local target_active = activated and 1 or 0
    local speed = 9
    self.hover_t = self.hover_t + (target_hover - self.hover_t) * math.min(1, dt * speed)
    self.press_t = self.press_t + (0 - self.press_t) * math.min(1, dt * 12)
    self.active_t = self.active_t + (target_active - self.active_t) * math.min(1, dt * 8)
end

function HandPinButton:draw(bounds, options)
    options = options or {}
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local active_wave = (0.5 + 0.5 * math.sin(t * 6.2)) * self.active_t
    local display_hover = math.max(self.hover_t, active_wave * 0.55)
    local wobble_y = math.sin(t * 7.0) * 1.2 * self.active_t
    local style = self.style
    style:draw({
        x = bounds.x,
        y = bounds.y,
        w = bounds.w,
        h = bounds.h,
    }, {
        visibleT = options.visible and 1 or 0,
        hoverT = display_hover,
        pressT = self.press_t,
        scale = 1.12 + 0.02 * active_wave,
        offsetY = wobble_y,
    })
end

return HandPinButton
