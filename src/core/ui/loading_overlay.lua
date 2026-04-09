local LoadingOverlay = {}
LoadingOverlay.__index = LoadingOverlay
local I18n = require("src.core.i18n.i18n")

local function trimTrailingDots(text)
    local normalized = tostring(text or "")
    normalized = normalized:gsub("…+$", "")
    normalized = normalized:gsub("%.+$", "")
    normalized = normalized:gsub("%s+$", "")
    if normalized == "" then
        local fallback = tostring(I18n:t("common.loading") or "Loading")
        fallback = fallback:gsub("…+$", ""):gsub("%.+$", ""):gsub("%s+$", "")
        return fallback ~= "" and fallback or "Loading"
    end
    return normalized
end

function LoadingOverlay.new(options)
    local self = setmetatable({}, LoadingOverlay)
    self.fonts = assert(options and options.fonts, "LoadingOverlay requires fonts")
    self.visible = false
    self.message = options and options.message or nil
    self.message_key = options and options.message_key or "common.loading"
    self.dot_timer = 0
    self.dot_index = 1
    self.dot_interval = tonumber((options and options.dot_interval) or 0.42) or 0.42
    return self
end

function LoadingOverlay:show(message)
    local was_visible = self.visible == true
    if message ~= nil then
        self.message = trimTrailingDots(message)
    else
        self.message = nil
    end
    self.visible = true
    if not was_visible then
        self.dot_timer = 0
        self.dot_index = 1
    end
end

function LoadingOverlay:hide()
    self.visible = false
end

function LoadingOverlay:isVisible()
    return self.visible == true
end

function LoadingOverlay:update(dt)
    if not self.visible then
        return
    end
    self.dot_timer = self.dot_timer + math.max(tonumber(dt) or 0, 0)
    while self.dot_timer >= self.dot_interval do
        self.dot_timer = self.dot_timer - self.dot_interval
        self.dot_index = self.dot_index + 1
        if self.dot_index > 3 then
            self.dot_index = 1
        end
    end
end

function LoadingOverlay:_dots()
    return string.rep(".", self.dot_index)
end

function LoadingOverlay:_resolveMessage()
    if self.message ~= nil then
        return trimTrailingDots(self.message)
    end
    return trimTrailingDots(I18n:t(self.message_key or "common.loading"))
end

function LoadingOverlay:draw(width, height)
    if not self.visible then
        return
    end

    local w = tonumber(width) or love.graphics.getWidth()
    local h = tonumber(height) or love.graphics.getHeight()

    love.graphics.setColor(0.03, 0.05, 0.08, 0.52)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local panel_w = math.max(320, math.floor(w * 0.32))
    local panel_h = 130
    local panel_x = math.floor((w - panel_w) * 0.5)
    local panel_y = math.floor((h - panel_h) * 0.5)

    love.graphics.setColor(0.0, 0.0, 0.0, 0.20)
    love.graphics.rectangle("fill", panel_x + 2, panel_y + 5, panel_w, panel_h, 16, 16)

    love.graphics.setColor(0.95, 0.85, 0.67, 0.98)
    love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, 16, 16)
    love.graphics.setColor(0.46, 0.23, 0.10, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panel_x + 1.5, panel_y + 1.5, panel_w - 3, panel_h - 3, 16, 16)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.34, 0.16, 0.06, 1.0)
    local locale = I18n:getLocale()
    if self.fonts.getForLocale then
        love.graphics.setFont(self.fonts:getForLocale("Title3", locale))
    else
        love.graphics.setFont(self.fonts:get("Title3"))
    end
    love.graphics.printf(self:_resolveMessage() .. self:_dots(), panel_x, panel_y + 52, panel_w, "center")
end

return LoadingOverlay
