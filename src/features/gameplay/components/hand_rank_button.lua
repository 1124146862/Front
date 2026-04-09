local HandButtonRankStyle = require("src.features.gameplay.components.hand_button_rank_style")

local HandRankButton = {}
HandRankButton.__index = HandRankButton

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.w
        and y >= bounds.y
        and y <= bounds.y + bounds.h
end

function HandRankButton.new()
    return setmetatable({
        style = HandButtonRankStyle,
        hover_t = 0,
        press_t = 0,
    }, HandRankButton)
end

function HandRankButton:getSize()
    return self.style.w, self.style.h
end

function HandRankButton:contains(bounds, x, y)
    return contains(bounds, x, y)
end

function HandRankButton:update(dt, hovered)
    local target_hover = hovered and 1 or 0
    local speed = 9
    self.hover_t = self.hover_t + (target_hover - self.hover_t) * math.min(1, dt * speed)
    self.press_t = self.press_t + (0 - self.press_t) * math.min(1, dt * 12)
end

function HandRankButton:draw(bounds, options)
    options = options or {}
    local style = self.style
    style:draw({
        x = bounds.x,
        y = bounds.y,
        w = bounds.w,
        h = bounds.h,
    }, {
        visibleT = options.visible and 1 or 0,
        hoverT = self.hover_t,
        pressT = self.press_t,
        scale = 1.12,
        offsetY = 0,
    })
end

return HandRankButton
