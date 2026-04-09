local ButtonText = require("src.core.ui.button_text")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local ConfirmationDialog = {}
ConfirmationDialog.__index = ConfirmationDialog

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function withAlpha(color, alpha)
    if type(color) ~= "table" then
        return { 1, 1, 1, alpha }
    end

    return {
        color[1] or 1,
        color[2] or 1,
        color[3] or 1,
        alpha == nil and (color[4] or 1) or alpha,
    }
end

local function resolveTextPalette(colors)
    colors = colors or {}

    local title = colors.hud_title or colors.button_primary_text or colors.text_primary or { 0.39, 0.18, 0.08, 1 }
    local message = colors.hud_subtext or colors.button_secondary_text or colors.text_secondary or title
    local shadow = colors.hud_text_shadow or { 0.98, 0.9, 0.76, 0.42 }

    return {
        title = title,
        message = message,
        title_shadow = withAlpha(shadow, math.min(0.62, (shadow[4] or 1) * 0.95)),
        message_shadow = withAlpha(shadow, math.min(0.46, (shadow[4] or 1) * 0.72)),
    }
end

function ConfirmationDialog.new(options)
    local self = setmetatable({}, ConfirmationDialog)
    self.fonts = assert(options and options.fonts, "ConfirmationDialog requires fonts")
    self.style = assert(options and options.style, "ConfirmationDialog requires style")
    self.panel = WoodPanel.new(self.style)
    return self
end

function ConfirmationDialog:getFrame(window_width, window_height)
    local width = clamp(window_width - 96, 360, 520)
    local height = clamp(window_height - 160, 220, 260)
    return {
        x = math.floor((window_width - width) * 0.5),
        y = math.floor((window_height - height) * 0.5),
        width = width,
        height = height,
    }
end

function ConfirmationDialog:getMessageBounds(window_width, window_height)
    local frame = self:getFrame(window_width, window_height)
    return {
        x = frame.x + 28,
        y = frame.y + 74,
        width = frame.width - 56,
        height = math.max(56, frame.height - 150),
    }
end

function ConfirmationDialog:getButtonBounds(window_width, window_height)
    local frame = self:getFrame(window_width, window_height)
    local gap = 18
    local button_width = math.floor((frame.width - 56 - gap) * 0.5)
    local button_height = 44
    local button_y = frame.y + frame.height - button_height - 24
    local left_x = frame.x + 28

    return {
        cancel = {
            x = left_x,
            y = button_y,
            width = button_width,
            height = button_height,
        },
        confirm = {
            x = left_x + button_width + gap,
            y = button_y,
            width = frame.x + frame.width - 28 - (left_x + button_width + gap),
            height = button_height,
        },
    }
end

function ConfirmationDialog:getControlAt(x, y, window_width, window_height)
    local buttons = self:getButtonBounds(window_width, window_height)
    if contains(buttons.cancel, x, y) then
        return "confirm_dialog_cancel"
    end
    if contains(buttons.confirm, x, y) then
        return "confirm_dialog_confirm"
    end
    return nil
end

function ConfirmationDialog:draw(config, window_width, window_height, hovered_control)
    if type(config) ~= "table" then
        return
    end

    local frame = self:getFrame(window_width, window_height)
    local message_bounds = self:getMessageBounds(window_width, window_height)
    local buttons = self:getButtonBounds(window_width, window_height)
    local colors = self.style.colors or {}
    local text_palette = resolveTextPalette(colors)
    local title_font = self.fonts:get("Title3")
    local message_font = self.fonts:get("Text")
    local _, wrapped_lines = message_font:getWrap(tostring(config.message or ""), message_bounds.width)
    local line_count = math.max(1, #wrapped_lines)
    local message_y = message_bounds.y + math.floor((message_bounds.height - line_count * message_font:getHeight()) * 0.5) - 1

    love.graphics.setColor(0.05, 0.03, 0.01, 0.58)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)

    self.panel:draw(frame, {
        radius = 18,
        shadow_offset = 6,
        inner_inset = 8,
        border_width = 2,
        inner_border_width = 1,
    })

    ButtonText.draw(title_font, tostring(config.title or ""), frame.x + 20, frame.y + 18, frame.width - 40, "center", text_palette.title, {
        bold = true,
        bold_offset = 1,
        shadow_color = text_palette.title_shadow,
    })

    ButtonText.draw(
        message_font,
        tostring(config.message or ""),
        message_bounds.x,
        message_y,
        message_bounds.width,
        "center",
        text_palette.message,
        {
            bold = true,
            bold_offset = 1,
            shadow_color = text_palette.message_shadow,
        }
    )

    WoodButton.draw(self.fonts, self.style, {
        label = tostring(config.cancel_label or ""),
        x = buttons.cancel.x,
        y = buttons.cancel.y,
        width = buttons.cancel.width,
        height = buttons.cancel.height,
        hovered = hovered_control == "confirm_dialog_cancel",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 12,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = tostring(config.confirm_label or ""),
        x = buttons.confirm.x,
        y = buttons.confirm.y,
        width = buttons.confirm.width,
        height = buttons.confirm.height,
        hovered = hovered_control == "confirm_dialog_confirm",
        enabled = true,
        variant = "primary",
        font_token = "Text",
        radius = 12,
    })
end

return ConfirmationDialog
