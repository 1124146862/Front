local I18n = require("src.core.i18n.i18n")
local IconCloseButton = require("src.core.ui.icon_close_button")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local MatchmakingOverlay = {}
MatchmakingOverlay.__index = MatchmakingOverlay

local function contains(bounds, x, y)
    return x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height
end

local function formatElapsed(seconds)
    local total = math.max(0, math.floor((tonumber(seconds) or 0) + 0.5))
    local mins = math.floor(total / 60)
    local secs = total % 60
    return string.format("%02d:%02d", mins, secs)
end

function MatchmakingOverlay.new(options)
    local self = setmetatable({}, MatchmakingOverlay)
    self.fonts = assert(options and options.fonts, "MatchmakingOverlay requires fonts")
    self.style = assert(options and options.style, "MatchmakingOverlay requires style")
    self.wood_panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    return self
end

function MatchmakingOverlay:getFrame()
    local width = 640
    local height = 388
    return {
        x = math.floor((love.graphics.getWidth() - width) * 0.5),
        y = math.floor((love.graphics.getHeight() - height) * 0.5),
        width = width,
        height = height,
    }
end

function MatchmakingOverlay:getCloseBounds()
    local frame = self:getFrame()
    return {
        x = frame.x + frame.width - 58,
        y = frame.y + 14,
        width = 38,
        height = 38,
    }
end

function MatchmakingOverlay:getCancelBounds()
    local frame = self:getFrame()
    return {
        x = frame.x + math.floor((frame.width - 220) * 0.5),
        y = frame.y + frame.height - 76,
        width = 220,
        height = 50,
    }
end

function MatchmakingOverlay:getControlAt(x, y)
    if contains(self:getCloseBounds(), x, y) then
        return "matchmaking_close"
    end
    if contains(self:getCancelBounds(), x, y) then
        return "matchmaking_cancel"
    end
    return nil
end

function MatchmakingOverlay:draw(state)
    local frame = self:getFrame()
    local colors = self.style.colors
    local player_count = tonumber(state.matchmaking_player_count) or 0
    local required_count = tonumber(state.matchmaking_required_player_count) or 4
    local elapsed_seconds = tonumber(state.matchmaking_elapsed_seconds) or 0
    local countdown_seconds = tonumber(state.matchmaking_countdown_seconds) or 0
    local phase = tostring(state.matchmaking_phase or "idle")

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.wood_panel:draw(frame, { radius = 22, shadow_offset = 10 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("main_menu.matchmaking_title"), frame.x, frame.y + 14, frame.width, "center")

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(I18n:t("main_menu.matchmaking_subtitle"), frame.x + 40, frame.y + 64, frame.width - 80, "center")

    local count_panel = {
        x = frame.x + 36,
        y = frame.y + 112,
        width = frame.width - 72,
        height = 110,
    }
    love.graphics.setColor(0.98, 0.94, 0.84, 0.96)
    love.graphics.rectangle("fill", count_panel.x, count_panel.y, count_panel.width, count_panel.height, 18, 18)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.74, 0.48, 0.24, 0.56)
    love.graphics.rectangle("line", count_panel.x + 1, count_panel.y + 1, count_panel.width - 2, count_panel.height - 2, 18, 18)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(I18n:t("main_menu.matchmaking_players_label"), count_panel.x, count_panel.y + 18, count_panel.width, "center")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf(
        I18n:t("main_menu.matchmaking_players_value", { current = player_count, required = required_count }),
        count_panel.x,
        count_panel.y + 44,
        count_panel.width,
        "center"
    )

    local elapsed_panel = {
        x = frame.x + 36,
        y = frame.y + 238,
        width = math.floor((frame.width - 92) * 0.5),
        height = 76,
    }
    local phase_panel = {
        x = elapsed_panel.x + elapsed_panel.width + 20,
        y = elapsed_panel.y,
        width = elapsed_panel.width,
        height = elapsed_panel.height,
    }

    for _, panel in ipairs({ elapsed_panel, phase_panel }) do
        love.graphics.setColor(0.98, 0.94, 0.84, 0.96)
        love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height, 16, 16)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.74, 0.48, 0.24, 0.50)
        love.graphics.rectangle("line", panel.x + 1, panel.y + 1, panel.width - 2, panel.height - 2, 16, 16)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(I18n:t("main_menu.matchmaking_elapsed_label"), elapsed_panel.x, elapsed_panel.y + 14, elapsed_panel.width, "center")
    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf(formatElapsed(elapsed_seconds), elapsed_panel.x, elapsed_panel.y + 36, elapsed_panel.width, "center")

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(I18n:t("main_menu.matchmaking_status_label"), phase_panel.x, phase_panel.y + 14, phase_panel.width, "center")

    local phase_key = "main_menu.matchmaking_phase_idle"
    if phase == "searching" then
        phase_key = "main_menu.matchmaking_phase_searching"
    elseif phase == "starting" then
        phase_key = "main_menu.matchmaking_phase_starting"
    elseif phase == "matched" then
        phase_key = "main_menu.matchmaking_phase_matched"
    end
    local phase_text = I18n:t(phase_key)
    if phase == "starting" then
        phase_text = phase_text .. " " .. string.format("%.1fs", math.max(0, countdown_seconds))
    end

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(phase_text, phase_panel.x + 14, phase_panel.y + 34, phase_panel.width - 28, "center")

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(tostring(state.matchmaking_message or ""), frame.x + 44, frame.y + 326, frame.width - 88, "center")

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("main_menu.matchmaking_cancel"),
        x = self:getCancelBounds().x,
        y = self:getCancelBounds().y,
        width = self:getCancelBounds().width,
        height = self:getCancelBounds().height,
        hovered = state.hovered_matchmaking_control == "matchmaking_cancel",
        enabled = state.matchmaking_busy ~= true,
        variant = "secondary",
        font_token = "Text",
        radius = 12,
    })

    self.close_button:draw(self:getCloseBounds(), state.hovered_matchmaking_control == "matchmaking_close")
end

return MatchmakingOverlay
