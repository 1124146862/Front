local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local RematchOverlayWood = {}
RematchOverlayWood.__index = RematchOverlayWood

local function contains(frame, x, y)
    return x >= frame.x
        and x <= frame.x + frame.width
        and y >= frame.y
        and y <= frame.y + frame.height
end

local function buildButtonFrames(panel)
    local button_y = panel.y + panel.height - 92
    local gap = 28
    local confirm_width = 288
    local leave_width = 188
    local total_width = confirm_width + leave_width + gap
    local start_x = panel.x + math.floor((panel.width - total_width) / 2)
    return {
        confirm = {
            x = start_x,
            y = button_y,
            width = confirm_width,
            height = 54,
        },
        leave = {
            x = start_x + confirm_width + gap,
            y = button_y,
            width = leave_width,
            height = 54,
        },
    }
end

local function getResultText(is_my_win)
    if is_my_win == false then
        return I18n:t("gameplay.rematch_result_lose")
    end
    return I18n:t("gameplay.rematch_result_win")
end

local function shouldShowButtonProgress(rematch)
    local required = tonumber((rematch or {}).required_human_count or 0) or 0
    return required > 1
end

local function buildConfirmLabel(rematch)
    local label = I18n:t("gameplay.rematch_confirm")
    if not shouldShowButtonProgress(rematch) then
        return label
    end

    local confirmed = tonumber((rematch or {}).confirmed_human_count or 0) or 0
    local required = tonumber((rematch or {}).required_human_count or 0) or 0
    return string.format("%s %d/%d", label, confirmed, required)
end

local function drawSwingTitle(fonts, frame, text, color)
    local font = fonts:get("Title1")
    local time = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local swing = math.sin(time * 2.2) * 0.045
    local bob = math.sin(time * 3.1) * 4
    local scale_jitter = 1 + math.sin(time * 2.8) * 0.03
    local text_width = font:getWidth(text)
    local text_height = font:getHeight()
    local fit_scale = math.min(1, (frame.width - 16) / math.max(text_width, 1))
    local scale = fit_scale * scale_jitter
    local draw_x = -math.floor(text_width * 0.5)
    local draw_y = -math.floor(text_height * 0.5)
    local center_x = frame.x + math.floor(frame.width * 0.5)
    local center_y = frame.y + math.floor(frame.height * 0.5)

    love.graphics.push()
    love.graphics.translate(center_x, center_y + bob)
    love.graphics.rotate(swing)
    love.graphics.scale(scale, scale)
    love.graphics.setFont(font)

    love.graphics.setColor(0.33, 0.18, 0.07, 0.25)
    love.graphics.print(text, draw_x + 4, draw_y + 6)

    love.graphics.setColor(color)
    love.graphics.print(text, draw_x, draw_y)
    love.graphics.pop()
end

function RematchOverlayWood.new(options)
    local self = setmetatable({}, RematchOverlayWood)

    self.fonts = assert(options and options.fonts, "RematchOverlayWood requires fonts")
    self.style = assert(options and options.style, "RematchOverlayWood requires style")
    self.panel = WoodPanel.new(self.style)

    return self
end

function RematchOverlayWood:_getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = 760
    local panel_h = 500
    return {
        x = math.floor((width - panel_w) / 2),
        y = math.floor((height - panel_h) / 2),
        width = panel_w,
        height = panel_h,
    }
end

function RematchOverlayWood:getControlAt(x, y, options)
    local panel = self:_getPanelFrame()
    local buttons = buildButtonFrames(panel)
    local rematch = (options and options.rematch) or {}

    if rematch.can_start ~= false and contains(buttons.confirm, x, y) then
        return "confirm_rematch"
    end
    if contains(buttons.leave, x, y) then
        return "leave_to_main_menu"
    end
    return nil
end

function RematchOverlayWood:draw(settlement, rematch, options)
    local colors = self.style.colors
    local panel = self:_getPanelFrame()
    local buttons = buildButtonFrames(panel)
    options = options or {}
    settlement = settlement or {}
    rematch = rematch or {}

    local winning_team_id = tonumber(settlement.winning_team_id)
    local my_team_id = tonumber(options.my_team_id)
    local is_my_win = nil
    if winning_team_id ~= nil and my_team_id ~= nil then
        is_my_win = winning_team_id == my_team_id
    end

    local title_frame = {
        x = panel.x + 56,
        y = panel.y + 104,
        width = panel.width - 112,
        height = 160,
    }

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.panel:draw(panel, {
        radius = 24,
        shadow_offset = 10,
        inner_inset = 12,
        border_width = 3,
    })

    drawSwingTitle(
        self.fonts,
        title_frame,
        getResultText(is_my_win),
        is_my_win == false and colors.error or colors.hud_title
    )

    WoodButton.draw(self.fonts, self.style, {
        label = buildConfirmLabel(rematch),
        x = buttons.confirm.x,
        y = buttons.confirm.y,
        width = buttons.confirm.width,
        height = buttons.confirm.height,
        hovered = options.confirm_hovered == true and rematch.can_start ~= false,
        enabled = rematch.can_start ~= false,
        variant = "primary",
        font_token = shouldShowButtonProgress(rematch) and "TextSmall" or "Text",
        radius = 14,
        bold = false,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("gameplay.back_to_main_menu"),
        x = buttons.leave.x,
        y = buttons.leave.y,
        width = buttons.leave.width,
        height = buttons.leave.height,
        hovered = options.leave_hovered == true,
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 14,
        bold = false,
    })
end

return RematchOverlayWood
