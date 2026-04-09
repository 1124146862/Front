local JoinRoomKeypad = {}
JoinRoomKeypad.__index = JoinRoomKeypad
local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")

local KEYS = {
    { id = "1", label = "1" },
    { id = "2", label = "2" },
    { id = "3", label = "3" },
    { id = "4", label = "4" },
    { id = "5", label = "5" },
    { id = "6", label = "6" },
    { id = "7", label = "7" },
    { id = "8", label = "8" },
    { id = "9", label = "9" },
    { id = "delete", label = function()
        return I18n:t("common.delete")
    end },
    { id = "0", label = "0" },
    { id = "ok", label = function()
        return I18n:t("common.ok")
    end },
}

function JoinRoomKeypad.new(options)
    local self = setmetatable({}, JoinRoomKeypad)

    self.x = options.x or 0
    self.y = options.y or 0
    self.button_width = options.button_width or 104
    self.button_height = options.button_height or 60
    self.gap = options.gap or 10
    self.hovered_key = options.hovered_key

    return self
end

function JoinRoomKeypad:getButtons()
    local buttons = {}

    for index, key in ipairs(KEYS) do
        local row = math.floor((index - 1) / 3)
        local col = (index - 1) % 3
        buttons[#buttons + 1] = {
            id = key.id,
            label = type(key.label) == "function" and key.label() or key.label,
            x = self.x + col * (self.button_width + self.gap),
            y = self.y + row * (self.button_height + self.gap),
            width = self.button_width,
            height = self.button_height,
            hovered = self.hovered_key == key.id,
        }
    end

    return buttons
end

function JoinRoomKeypad:getKeyAt(x, y)
    for _, button in ipairs(self:getButtons()) do
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            return button.id
        end
    end

    return nil
end

function JoinRoomKeypad:draw(fonts, style)
    for _, button in ipairs(self:getButtons()) do
        WoodButton.draw(fonts, style, {
            label = button.label,
            x = button.x,
            y = button.y,
            width = button.width,
            height = button.height,
            hovered = button.hovered,
            enabled = true,
            variant = (button.id == "ok") and "primary" or "secondary",
            font_token = "TextSmall",
            radius = 12,
            shadow_offset = 3,
            inner_inset = 5,
            light_chrome = true,
        })
    end
end

return JoinRoomKeypad
