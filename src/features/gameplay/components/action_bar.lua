local ActionBar = {}
ActionBar.__index = ActionBar
local I18n = require("src.core.i18n.i18n")
local PassRegion = require("src.features.gameplay.components.pass_region")

local function contains(frame, x, y)
    return x >= frame.x
        and x <= frame.x + frame.width
        and y >= frame.y
        and y <= frame.y + frame.height
end

function ActionBar.new(options)
    local self = setmetatable({}, ActionBar)

    self.fonts = assert(options and options.fonts, "ActionBar requires fonts")
    self.style = assert(options and options.style, "ActionBar requires style")

    return self
end

local function resolveButtonFrame(frame, key)
    if type(frame) ~= "table" then
        return nil
    end
    if frame[key] then
        return frame[key]
    end
    return frame
end

function ActionBar:_buildButtons(frame, config)
    local buttons = {}
    local button_width = 170
    local button_height = 56
    local play_frame = resolveButtonFrame(frame, "play") or frame
    local pass_frame = resolveButtonFrame(frame, "pass") or frame
    local play_x = play_frame.x + math.floor((play_frame.width - button_width) * 0.5)
    local play_y = play_frame.y + math.floor((play_frame.height - button_height) * 0.5)
    local pass_x = pass_frame.x + math.floor((pass_frame.width - button_width) * 0.5)
    local pass_y = pass_frame.y + math.floor((pass_frame.height - button_height) * 0.5)
    local hold_id = config.pending_action
    local hold_active = (tonumber(config.pending_action_timer) or 0) > 0

    if not config.is_my_turn or config.action_waiting then
        if hold_active and (hold_id == "play_cards" or hold_id == "pass_turn") then
            local is_play = hold_id == "play_cards"
            buttons[#buttons + 1] = {
                id = hold_id,
                label = I18n:t(is_play and "gameplay.play" or "gameplay.pass"),
                enabled = false,
                x = is_play and play_x or pass_x,
                y = is_play and play_y or pass_y,
                width = button_width,
                height = button_height,
                variant = is_play and "primary" or "secondary",
            }
        end
        return buttons
    end

    if config.has_play_control then
        buttons[#buttons + 1] = {
            id = "play_cards",
            label = I18n:t("gameplay.play"),
            enabled = true,
            x = play_x,
            y = play_y,
            width = button_width,
            height = button_height,
            variant = "primary",
        }
        return buttons
    end

    buttons[#buttons + 1] = {
        id = "play_cards",
        label = I18n:t("gameplay.play"),
        enabled = true,
        x = play_x,
        y = play_y,
        width = button_width,
        height = button_height,
        variant = "primary",
    }
    buttons[#buttons + 1] = {
        id = "pass_turn",
        label = I18n:t("gameplay.pass"),
        enabled = true,
        x = pass_x,
        y = pass_y,
        width = button_width,
        height = button_height,
        variant = "secondary",
    }

    return buttons
end

function ActionBar:getControlAt(x, y, frame, config)
    local buttons = self:_buildButtons(frame, config)
    for _, button in ipairs(buttons) do
        if contains(button, x, y) and button.enabled then
            return button.id
        end
    end

    return nil
end

function ActionBar:draw(frame, config)
    local buttons = self:_buildButtons(frame, config)
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or 0

    for _, button in ipairs(buttons) do
        local draw_x = button.x
        local draw_y = button.y
        local press_strength = (config.pressed_controls or {})[button.id] or 0
        if config.pending_action == button.id then
            press_strength = math.max(press_strength, tonumber(config.pending_action_progress) or 0)
        end

        if button.id == "play_cards" and config.can_play then
            local pulse = 0.12 + 0.08 * math.sin(t * 2.1)
            love.graphics.setColor(0.32, 0.62, 1.0, pulse)
            love.graphics.rectangle("fill", draw_x - 6, draw_y - 5, button.width + 12, button.height + 10, 12, 12)
            love.graphics.setColor(0.35, 0.70, 1.0, pulse * 0.7)
            love.graphics.rectangle("fill", draw_x - 3, draw_y - 2, button.width + 6, button.height + 4, 10, 10)
        end

        PassRegion.drawBadge(self.fonts, {
            x = draw_x,
            y = draw_y,
            width = button.width,
            height = button.height,
        }, {
            label = button.label,
            hovered = config.hovered_control == button.id and button.enabled,
            press_strength = press_strength,
            enabled = button.enabled,
            tone = button.id == "pass_turn" and "default" or "blue",
            font_size = 24,
            font_token = "TextBig",
            pad_x = 20,
            pad_y = 10,
        })
    end
end

return ActionBar
