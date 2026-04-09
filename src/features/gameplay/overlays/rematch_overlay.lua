local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local RematchOverlay = {}
RematchOverlay.__index = RematchOverlay

local function contains(frame, x, y)
    return x >= frame.x
        and x <= frame.x + frame.width
        and y >= frame.y
        and y <= frame.y + frame.height
end

local function buildButtonFrames(panel)
    local button_y = panel.y + panel.height - 92
    local gap = 28
    local confirm_width = 240
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

local function drawPlaque(frame)
    love.graphics.setColor(0.30, 0.17, 0.08, 0.20)
    love.graphics.rectangle("fill", frame.x, frame.y + 5, frame.width, frame.height, 18, 18)

    love.graphics.setColor(0.72, 0.47, 0.24, 0.98)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 18, 18)

    love.graphics.setColor(0.88, 0.66, 0.39, 0.14)
    for index = 0, 4 do
        local stripe_y = frame.y + 18 + index * 16
        love.graphics.rectangle("fill", frame.x + 16, stripe_y, frame.width - 32, 2, 1, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.42, 0.24, 0.12, 0.98)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 18, 18)
    love.graphics.setLineWidth(1)
end

function RematchOverlay.new(options)
    local self = setmetatable({}, RematchOverlay)

    self.fonts = assert(options and options.fonts, "RematchOverlay requires fonts")
    self.style = assert(options and options.style, "RematchOverlay requires style")
    self.panel = WoodPanel.new(self.style)

    return self
end

function RematchOverlay:_getPanelFrame()
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

function RematchOverlay:getControlAt(x, y, options)
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

function RematchOverlay:draw(settlement, rematch, options)
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
        x = panel.x + 54,
        y = panel.y + 112,
        width = panel.width - 108,
        height = 104,
    }
    local progress_frame = {
        x = panel.x + 148,
        y = panel.y + 248,
        width = panel.width - 296,
        height = 78,
    }

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.panel:draw(panel, {
        radius = 24,
        shadow_offset = 10,
        inner_inset = 12,
        border_width = 3,
    })

    drawPlaque(title_frame)
    drawPlaque(progress_frame)

    love.graphics.setColor(is_my_win == false and colors.error or colors.hud_title)
    love.graphics.setFont(self.fonts:get("Title"))
    love.graphics.printf(getResultText(is_my_win), title_frame.x, title_frame.y + 27, title_frame.width, "center")

    local required = tonumber(rematch.required_human_count or 0) or 0
    local confirmed = tonumber(rematch.confirmed_human_count or 0) or 0
    love.graphics.setColor(colors.hud_text)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(
        I18n:t("gameplay.rematch_progress", {
            confirmed = tostring(confirmed),
            required = tostring(required),
        }),
        progress_frame.x + 12,
        progress_frame.y + 24,
        progress_frame.width - 24,
        "center"
    )

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("gameplay.rematch_confirm"),
        x = buttons.confirm.x,
        y = buttons.confirm.y,
        width = buttons.confirm.width,
        height = buttons.confirm.height,
        hovered = options.confirm_hovered == true and rematch.can_start ~= false,
        enabled = rematch.can_start ~= false,
        variant = "primary",
        font_token = "Text",
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

return RematchOverlay
