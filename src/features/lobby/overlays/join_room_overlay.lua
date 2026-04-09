local JoinRoomKeypad = require("src.features.lobby.components.join_room_keypad")
local I18n = require("src.core.i18n.i18n")
local WoodPanel = require("src.core.ui.wood_panel")
local WoodButton = require("src.core.ui.wood_button")

local JoinRoomOverlay = {}
JoinRoomOverlay.__index = JoinRoomOverlay

function JoinRoomOverlay.new(options)
    local self = setmetatable({}, JoinRoomOverlay)

    self.fonts = assert(options and options.fonts, "JoinRoomOverlay requires fonts")
    self.style = assert(options and options.style, "JoinRoomOverlay requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.wood_panel = WoodPanel.new(self.style)

    return self
end

function JoinRoomOverlay:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function JoinRoomOverlay:_getLayout()
    local width = 420
    local height = 502
    local x = math.floor((self.window_width - width) / 2)
    local y = math.floor((self.window_height - height) / 2)

    return {
        x = x,
        y = y,
        width = width,
        height = height,
        display_x = x + 36,
        display_y = y + 110,
        display_width = width - 72,
        keypad_x = x + 46,
        keypad_y = y + 180,
        error_y = y + 448,
    }
end

function JoinRoomOverlay:getOverlayActionAt(x, y, state)
    local layout = self:_getLayout()
    local close_x = layout.x + layout.width - 116
    local close_y = layout.y + 24
    if x >= close_x and x <= close_x + 84 and y >= close_y and y <= close_y + 40 then
        return "close"
    end

    local keypad = JoinRoomKeypad.new({
        x = layout.keypad_x,
        y = layout.keypad_y,
        hovered_key = state.overlay_hovered_key,
    })

    return keypad:getKeyAt(x, y)
end

function JoinRoomOverlay:draw(state)
    local colors = self.style.colors
    local layout = self:_getLayout()
    local current_input = state.overlay_step == "password" and state.overlay_password_input or state.overlay_room_id_input
    local title = state.overlay_step == "password" and I18n:t("lobby.overlay_password_title") or I18n:t("lobby.overlay_room_title")

    love.graphics.setColor(0, 0, 0, 0.48)
    love.graphics.rectangle("fill", 0, 0, self.window_width, self.window_height)

    self.wood_panel:draw(layout, {
        radius = 20,
        shadow_offset = 6,
        inner_inset = 10,
        border_width = 2,
        inner_border_width = 1.5,
    })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf(title, layout.x, layout.y + 40, layout.width, "center")

    love.graphics.setColor(colors.card)
    love.graphics.rectangle("fill", layout.display_x, layout.display_y, layout.display_width, 56, 14, 14)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(colors.card_border)
    love.graphics.rectangle("line", layout.display_x + 0.5, layout.display_y + 0.5, layout.display_width - 1, 56 - 1, 14, 14)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(current_input ~= "" and current_input or "-", layout.display_x, layout.display_y + 9, layout.display_width, "center")

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("common.close"),
        x = layout.x + layout.width - 116,
        y = layout.y + 24,
        width = 84,
        height = 40,
        hovered = state.overlay_hovered_key == "close",
        enabled = true,
        variant = "secondary",
        font_token = "Caption",
        radius = 12,
        shadow_offset = 3,
        inner_inset = 5,
        light_chrome = true,
    })

    JoinRoomKeypad.new({
        x = layout.keypad_x,
        y = layout.keypad_y,
        hovered_key = state.overlay_hovered_key,
    }):draw(self.fonts, self.style)

    if state.overlay_error_message ~= "" then
        love.graphics.setColor(0.92, 0.48, 0.45, 1)
        love.graphics.setFont(self.fonts:get("Caption"))
        love.graphics.printf(state.overlay_error_message, layout.x + 24, layout.error_y, layout.width - 48, "center")
    end
end

return JoinRoomOverlay
