local IconCloseButton = require("src.core.ui.icon_close_button")
local SettingsButton = require("src.core.ui.settings_button")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")
local I18n = require("src.core.i18n.i18n")
local BackgroundThemeCatalog = require("src.core.backgrounds.themes.background_theme_catalog")
local MainMenuStyle = require("src.features.main_menu.style")
local IconButtonsStyle = require("src.features.main_menu.icon_buttons_style")
local CardThemeManager = require("src.features.gameplay.card_themes.card_theme_manager")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")
local CardBackStyle = require("src.features.gameplay.components.card_back_style")

local GameplaySettingsOverlay = {}
GameplaySettingsOverlay.__index = GameplaySettingsOverlay

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

local function volumeLabel(value)
    local percent = math.floor((tonumber(value) or 0) * 100 + 0.5)
    return I18n:t("gameplay.settings_volume_value", {
        percent = percent,
    })
end

local function gameBgmLabel(bgm_id)
    local suffix = tostring(bgm_id or ""):match("^bgm(%d+)$")
    if suffix then
        local key = "gameplay.settings_bgm_option_" .. suffix
        local label = I18n:t(key)
        if label ~= key then
            return label
        end
        return "BGM " .. suffix
    end
    return I18n:t("gameplay.settings_bgm_option_default")
end

local function cardThemeLabel(theme_id)
    return I18n:t(ThemeCatalog.getLabelKey(theme_id))
end

local function cardBackLabel(back_id)
    if back_id == "placeholder_clean" then
        back_id = "violet_tile"
    elseif back_id == "placeholder_dark" then
        back_id = "midnight_star"
    end
    if back_id == "classic_grid" then
        return I18n:t("gameplay.settings_cards_back_default")
    end
    if back_id == "emerald_lattice" then
        return I18n:t("gameplay.settings_cards_back_emerald_lattice")
    end
    if back_id == "crimson_fan" then
        return I18n:t("gameplay.settings_cards_back_crimson_fan")
    end
    if back_id == "violet_tile" then
        return I18n:t("gameplay.settings_cards_back_violet_tile")
    end
    if back_id == "midnight_star" then
        return I18n:t("gameplay.settings_cards_back_midnight_star")
    end
    return I18n:t("gameplay.settings_cards_back_default")
end

local function backgroundThemeLabel(theme_id)
    return BackgroundThemeCatalog.getLabel(theme_id)
end

local function drawFallbackBackgroundPreview(theme_id, x, y, width, height)
    local palette = {
        spring = { bg = { 0.57, 0.78, 0.50, 1 }, accent = { 0.91, 0.67, 0.78, 0.75 } },
        summer = { bg = { 0.43, 0.69, 0.39, 1 }, accent = { 0.96, 0.85, 0.53, 0.7 } },
        autumn = { bg = { 0.67, 0.52, 0.34, 1 }, accent = { 0.91, 0.61, 0.34, 0.72 } },
        winter = { bg = { 0.69, 0.77, 0.85, 1 }, accent = { 0.95, 0.97, 1.0, 0.72 } },
        cosmos = { bg = { 0.03, 0.05, 0.10, 1 }, accent = { 0.42, 0.70, 1.0, 0.90 } },
        nebula = { bg = { 0.05, 0.06, 0.14, 1 }, accent = { 0.64, 0.36, 0.96, 0.88 } },
        galaxy = { bg = { 0.04, 0.04, 0.12, 1 }, accent = { 1.0, 0.68, 0.36, 0.86 } },
        warp = { bg = { 0.04, 0.07, 0.13, 1 }, accent = { 0.22, 0.88, 0.98, 0.84 } },
    }
    local style = palette[BackgroundThemeCatalog.normalizeThemeId(theme_id)] or palette.cosmos
    love.graphics.setColor(style.bg)
    love.graphics.rectangle("fill", x, y, width, height, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.08)
    for index = 0, 11 do
        local px = x + index * width / 12
        love.graphics.line(px, y, px + height * 0.35, y + height)
    end
    love.graphics.setColor(style.accent)
    local dot_step = 26
    for px = x + dot_step * 0.5, x + width, dot_step do
        for py = y + dot_step * 0.5, y + height, dot_step do
            love.graphics.circle("fill", px, py, 1.8)
        end
    end
    love.graphics.setColor(1, 1, 1, 0.14)
    love.graphics.printf(backgroundThemeLabel(theme_id), x, y + math.floor(height * 0.40), width, "center")
end

function GameplaySettingsOverlay.new(options)
    local self = setmetatable({}, GameplaySettingsOverlay)

    self.fonts = assert(options and options.fonts, "GameplaySettingsOverlay requires fonts")
    self.ui_style = MainMenuStyle
    self.icon_style = IconButtonsStyle
    self.panel = WoodPanel.new(self.ui_style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.ui_style,
    })
    self.settings_button = SettingsButton.new()
    self.background_preview_drawer = options and options.background_preview_drawer or nil
    self.card_theme_manager = CardThemeManager.new()

    return self
end

function GameplaySettingsOverlay:getSettingsButtonBounds(window_width, custom_bounds)
    if custom_bounds then
        return {
            x = custom_bounds.x,
            y = custom_bounds.y,
            width = custom_bounds.width,
            height = custom_bounds.height,
        }
    end
    local layout = self.icon_style.layout
    local size = layout.button_size or 64
    local margin = layout.right_margin or 22
    local top = layout.top_margin or 18
    return {
        x = window_width - margin - size,
        y = top,
        width = size,
        height = size,
    }
end

function GameplaySettingsOverlay:getOverlayFrame(window_width, window_height)
    local width = clamp(window_width - 48, 980, 1180)
    local height = clamp(window_height - 40, 620, 760)
    return {
        x = math.floor((window_width - width) * 0.5),
        y = math.floor((window_height - height) * 0.5),
        width = width,
        height = height,
    }
end

function GameplaySettingsOverlay:getCloseBounds(window_width, window_height)
    local frame = self:getOverlayFrame(window_width, window_height)
    return {
        x = frame.x + frame.width - 58,
        y = frame.y + 16,
        width = 38,
        height = 38,
    }
end

function GameplaySettingsOverlay:getTabBounds(window_width, window_height)
    local frame = self:getOverlayFrame(window_width, window_height)
    local left = frame.x + 28
    local top = frame.y + 92
    local gap = 14
    local width = math.floor((frame.width - 56 - gap * 2) / 3)
    local height = 52
    return {
        display_audio = { x = left, y = top, width = width, height = height },
        background = { x = left + width + gap, y = top, width = width, height = height },
        cards = { x = left + (width + gap) * 2, y = top, width = width, height = height },
    }
end

function GameplaySettingsOverlay:getContentFrame(window_width, window_height)
    local frame = self:getOverlayFrame(window_width, window_height)
    local tabs = self:getTabBounds(window_width, window_height)
    local top = tabs.display_audio.y + tabs.display_audio.height + 20
    local bottom_margin = 24
    return {
        x = frame.x + 24,
        y = top,
        width = frame.width - 48,
        height = frame.y + frame.height - top - bottom_margin,
    }
end

function GameplaySettingsOverlay:getFooterSectionBounds(window_width, window_height)
    local content = self:getContentFrame(window_width, window_height)
    local action_h = 42
    local action_gap = 28
    local action_left = content.x + 18
    local action_row_width = content.width - 36
    local reset_width = math.floor(action_row_width * 0.24)
    local menu_exit_total = action_row_width - reset_width - action_gap * 2
    local menu_width = math.floor(menu_exit_total * 0.5)
    local exit_width = menu_exit_total - menu_width
    local action_y = content.y + content.height - action_h - 16

    return {
        reset_defaults = { x = action_left, y = action_y, width = reset_width, height = action_h },
        back_to_main_menu = { x = action_left + reset_width + action_gap, y = action_y, width = menu_width, height = action_h },
        exit_game = { x = action_left + reset_width + action_gap + menu_width + action_gap, y = action_y, width = exit_width, height = action_h },
    }
end

function GameplaySettingsOverlay:getTabContentFrame(window_width, window_height)
    local content = self:getContentFrame(window_width, window_height)
    local footer = self:getFooterSectionBounds(window_width, window_height)
    local section_gap = 22
    local footer_top = footer.reset_defaults.y

    return {
        x = content.x,
        y = content.y,
        width = content.width,
        height = math.max(180, footer_top - section_gap - content.y),
    }
end

function GameplaySettingsOverlay:getDisplaySectionBounds(window_width, window_height)
    local content = self:getTabContentFrame(window_width, window_height)
    local row_start = content.y + 18
    local controls_x = content.x + content.width - (54 + 12 + 230 + 12 + 54) - 18
    local mode_x = content.x + content.width - (160 + 14 + 160) - 18
    local control_height = 50
    local row_count = 7
    local bottom_padding = 14
    local available_height = content.y + content.height - row_start - control_height - bottom_padding
    local row_step = math.floor(available_height / math.max(1, row_count - 1))
    row_step = clamp(row_step, 60, 84)
    local mode_y = row_start

    return {
        mode_windowed = { x = mode_x, y = mode_y, width = 160, height = 50 },
        mode_fullscreen = { x = mode_x + 174, y = mode_y, width = 160, height = 50 },
        resolution_prev = { x = controls_x, y = row_start + row_step, width = 54, height = 50 },
        resolution_value = { x = controls_x + 66, y = row_start + row_step, width = 230, height = 50 },
        resolution_next = { x = controls_x + 308, y = row_start + row_step, width = 54, height = 50 },
        language_prev = { x = controls_x, y = row_start + row_step * 2, width = 54, height = 50 },
        language_value = { x = controls_x + 66, y = row_start + row_step * 2, width = 230, height = 50 },
        language_next = { x = controls_x + 308, y = row_start + row_step * 2, width = 54, height = 50 },
        fps_prev = { x = controls_x, y = row_start + row_step * 3, width = 54, height = 50 },
        fps_value = { x = controls_x + 66, y = row_start + row_step * 3, width = 230, height = 50 },
        fps_next = { x = controls_x + 308, y = row_start + row_step * 3, width = 54, height = 50 },
        game_volume_prev = { x = controls_x, y = row_start + row_step * 4, width = 54, height = 50 },
        game_volume_value = { x = controls_x + 66, y = row_start + row_step * 4, width = 230, height = 50 },
        game_volume_next = { x = controls_x + 308, y = row_start + row_step * 4, width = 54, height = 50 },
        bgm_volume_prev = { x = controls_x, y = row_start + row_step * 5, width = 54, height = 50 },
        bgm_volume_value = { x = controls_x + 66, y = row_start + row_step * 5, width = 230, height = 50 },
        bgm_volume_next = { x = controls_x + 308, y = row_start + row_step * 5, width = 54, height = 50 },
        game_bgm_prev = { x = controls_x, y = row_start + row_step * 6, width = 54, height = 50 },
        game_bgm_value = { x = controls_x + 66, y = row_start + row_step * 6, width = 230, height = 50 },
        game_bgm_next = { x = controls_x + 308, y = row_start + row_step * 6, width = 54, height = 50 },
    }
end

function GameplaySettingsOverlay:getBackgroundSectionBounds(window_width, window_height)
    local content = self:getTabContentFrame(window_width, window_height)
    local outer_padding = 16
    local col_gap = 12
    local row_gap = 12
    local grid_x = content.x + outer_padding
    local grid_y = content.y + outer_padding
    local grid_w = content.width - outer_padding * 2
    local grid_h = content.height - outer_padding * 2

    local width = math.floor((grid_w - col_gap * 3) / 4)
    local height = math.floor((grid_h - row_gap) / 2)
    local left = grid_x
    local top = grid_y
    local second_row_y = top + height + row_gap

    return {
        spring = { x = left, y = top, width = width, height = height },
        summer = { x = left + width + col_gap, y = top, width = width, height = height },
        autumn = { x = left + (width + col_gap) * 2, y = top, width = width, height = height },
        winter = { x = left + (width + col_gap) * 3, y = top, width = width, height = height },
        cosmos = { x = left, y = second_row_y, width = width, height = height },
        nebula = { x = left + width + col_gap, y = second_row_y, width = width, height = height },
        galaxy = { x = left + (width + col_gap) * 2, y = second_row_y, width = width, height = height },
        warp = { x = left + (width + col_gap) * 3, y = second_row_y, width = width, height = height },
    }
end

function GameplaySettingsOverlay:getCardsSectionBounds(window_width, window_height)
    local content = self:getTabContentFrame(window_width, window_height)
    local outer_pad = 22
    local top_y = content.y + outer_pad
    local row_gap = 18
    local row1_h = 48
    local row2_y = top_y + row1_h + row_gap
    local row2_h = content.height - (row2_y - content.y) - outer_pad
    local col_gap = 22
    local back_w = math.floor((content.width - outer_pad * 2 - col_gap) * 0.30)
    local theme_w = content.width - outer_pad * 2 - col_gap - back_w
    local back_x = content.x + outer_pad
    local theme_x = back_x + back_w + col_gap
    local panel_pad = 18
    local top_controls_h = 52
    local preview_gap = 18

    local back_control_y = row2_y + panel_pad
    local back_preview_area_x = back_x + panel_pad
    local back_preview_area_y = back_control_y + top_controls_h + preview_gap
    local back_preview_area_w = back_w - panel_pad * 2
    local back_preview_area_h = math.max(120, row2_y + row2_h - panel_pad - back_preview_area_y)

    local theme_control_y = row2_y + panel_pad
    local theme_preview_area_x = theme_x + panel_pad
    local theme_preview_area_y = theme_control_y + top_controls_h + preview_gap
    local theme_preview_area_w = theme_w - panel_pad * 2
    local theme_preview_area_h = math.max(120, row2_y + row2_h - panel_pad - theme_preview_area_y)

    local back_preview_max_w = math.max(120, back_preview_area_w)
    local back_preview_max_h = back_preview_area_h
    local back_preview_h = clamp(math.min(back_preview_max_h, math.floor(back_preview_max_w * 1.42)), 180, 320)
    local back_preview_w = clamp(math.floor(back_preview_h / 1.42), 120, back_preview_max_w)
    if back_preview_w > back_preview_max_w then
        back_preview_w = back_preview_max_w
        back_preview_h = math.floor(back_preview_w * 1.42)
    end
    local back_preview_x = back_preview_area_x + math.floor((back_preview_area_w - back_preview_w) * 0.5)
    local back_preview_y = back_preview_area_y + math.floor((back_preview_area_h - back_preview_h) * 0.5)

    local card_gap = 14
    local theme_preview_max_w = math.max(240, theme_preview_area_w)
    local theme_preview_max_h = theme_preview_area_h
    local card_w_from_width = math.floor((theme_preview_max_w - card_gap * 3) / 4)
    local card_h_from_width = math.floor(card_w_from_width * 1.42)
    local card_h = math.min(card_h_from_width, theme_preview_max_h)
    local card_w = math.floor(card_h / 1.42)
    card_w = clamp(card_w, 88, 136)
    card_h = math.floor(card_w * 1.42)
    if card_h > theme_preview_max_h then
        card_h = theme_preview_max_h
        card_w = math.floor(card_h / 1.42)
    end
    local cards_total_w = card_w * 4 + card_gap * 3
    local cards_start_x = theme_preview_area_x + math.floor((theme_preview_area_w - cards_total_w) * 0.5)
    local cards_y = theme_preview_area_y + math.floor((theme_preview_area_h - card_h) * 0.5)
    local toggle_width = 230
    local high_gap = 32
    local label_width = 280
    local high_group_w = label_width + high_gap + toggle_width
    local high_group_x = content.x + math.floor((content.width - high_group_w) * 0.5)

    return {
        high_contrast_label = { x = high_group_x, y = top_y + 10, width = label_width, height = 28 },
        high_contrast = { x = high_group_x + label_width + high_gap, y = top_y, width = toggle_width, height = 48 },
        back_panel = { x = back_x, y = row2_y, width = back_w, height = row2_h },
        theme_panel = { x = theme_x, y = row2_y, width = theme_w, height = row2_h },
        joker_preview = { x = cards_start_x, y = cards_y, width = card_w, height = card_h },
        j_preview = { x = cards_start_x + (card_w + card_gap), y = cards_y, width = card_w, height = card_h },
        q_preview = { x = cards_start_x + (card_w + card_gap) * 2, y = cards_y, width = card_w, height = card_h },
        k_preview = { x = cards_start_x + (card_w + card_gap) * 3, y = cards_y, width = card_w, height = card_h },
        theme_prev = { x = theme_x + panel_pad, y = theme_control_y, width = 54, height = 52 },
        theme_value = { x = theme_x + panel_pad + 66, y = theme_control_y, width = theme_w - panel_pad * 2 - 132, height = 52 },
        theme_next = { x = theme_x + theme_w - panel_pad - 54, y = theme_control_y, width = 54, height = 52 },
        back_prev = { x = back_x + panel_pad, y = back_control_y, width = 54, height = 52 },
        back_value = { x = back_x + panel_pad + 66, y = back_control_y, width = back_w - panel_pad * 2 - 132, height = 52 },
        back_next = { x = back_x + back_w - panel_pad - 54, y = back_control_y, width = 54, height = 52 },
        back_preview = { x = back_preview_x, y = back_preview_y, width = back_preview_w, height = back_preview_h },
    }
end

function GameplaySettingsOverlay:getControlAt(x, y, state, window_width, window_height, settings_button_bounds)
    if state.loading or (state.fatal_error_message or "") ~= "" then
        return nil
    end

    if not state.settings_overlay_visible then
        if contains(self:getSettingsButtonBounds(window_width, settings_button_bounds), x, y) then
            return "open_settings"
        end
        return nil
    end

    local close_bounds = self:getCloseBounds(window_width, window_height)
    if contains(close_bounds, x, y) then
        return "settings_close"
    end

    local tabs = self:getTabBounds(window_width, window_height)
    if contains(tabs.display_audio, x, y) then
        return "settings_tab_display_audio"
    end
    if contains(tabs.background, x, y) then
        return "settings_tab_background"
    end
    if contains(tabs.cards, x, y) then
        return "settings_tab_cards"
    end

    local footer = self:getFooterSectionBounds(window_width, window_height)
    if contains(footer.reset_defaults, x, y) then
        return "settings_reset_defaults"
    end
    if contains(footer.back_to_main_menu, x, y) then
        return "settings_back_to_main_menu"
    end
    if contains(footer.exit_game, x, y) then
        return "settings_exit_game"
    end

    local active_tab = state.settings_tab or "display_audio"
    if active_tab == "display_audio" then
        local bounds = self:getDisplaySectionBounds(window_width, window_height)
        if contains(bounds.mode_windowed, x, y) then
            return "settings_mode_windowed"
        end
        if contains(bounds.mode_fullscreen, x, y) then
            return "settings_mode_fullscreen"
        end
        if state.settings_window_mode ~= "fullscreen" and contains(bounds.resolution_prev, x, y) then
            return "settings_resolution_prev"
        end
        if state.settings_window_mode ~= "fullscreen" and contains(bounds.resolution_next, x, y) then
            return "settings_resolution_next"
        end
        if contains(bounds.language_prev, x, y) then
            return "settings_language_prev"
        end
        if contains(bounds.language_next, x, y) then
            return "settings_language_next"
        end
        if contains(bounds.fps_prev, x, y) then
            return "settings_fps_prev"
        end
        if contains(bounds.fps_next, x, y) then
            return "settings_fps_next"
        end
        if contains(bounds.game_volume_prev, x, y) then
            return "settings_game_volume_prev"
        end
        if contains(bounds.game_volume_next, x, y) then
            return "settings_game_volume_next"
        end
        if contains(bounds.bgm_volume_prev, x, y) then
            return "settings_bgm_volume_prev"
        end
        if contains(bounds.bgm_volume_next, x, y) then
            return "settings_bgm_volume_next"
        end
        if contains(bounds.game_bgm_prev, x, y) then
            return "settings_game_bgm_prev"
        end
        if contains(bounds.game_bgm_next, x, y) then
            return "settings_game_bgm_next"
        end
        return nil
    end

    if active_tab == "background" then
        local bounds = self:getBackgroundSectionBounds(window_width, window_height)
        if contains(bounds.spring, x, y) then
            return "settings_background_spring"
        end
        if contains(bounds.summer, x, y) then
            return "settings_background_summer"
        end
        if contains(bounds.autumn, x, y) then
            return "settings_background_autumn"
        end
        if contains(bounds.winter, x, y) then
            return "settings_background_winter"
        end
        if contains(bounds.cosmos, x, y) then
            return "settings_background_cosmos"
        end
        if contains(bounds.nebula, x, y) then
            return "settings_background_nebula"
        end
        if contains(bounds.galaxy, x, y) then
            return "settings_background_galaxy"
        end
        if contains(bounds.warp, x, y) then
            return "settings_background_warp"
        end
        return nil
    end

    local bounds = self:getCardsSectionBounds(window_width, window_height)
    if contains(bounds.high_contrast, x, y) then
        return "settings_cards_high_contrast_toggle"
    end
    if contains(bounds.theme_prev, x, y) then
        return "settings_cards_theme_prev"
    end
    if contains(bounds.theme_next, x, y) then
        return "settings_cards_theme_next"
    end
    if contains(bounds.back_prev, x, y) then
        return "settings_cards_back_prev"
    end
    if contains(bounds.back_next, x, y) then
        return "settings_cards_back_next"
    end
    return nil
end

function GameplaySettingsOverlay:drawSettingsButton(state, window_width, settings_button_bounds)
    local frame = self:getSettingsButtonBounds(window_width, settings_button_bounds)

    self.settings_button:draw(frame, {
        hovered = state.hovered_settings_button == true,
    })
end

function GameplaySettingsOverlay:drawBackgroundPreviewOverlay(state, window_width, window_height)
    local theme_id = state and state.settings_background_preview_theme_id or nil
    if not theme_id then
        return
    end
    local preview_seed = state and state.settings_background_preview_seed or nil

    local preview_drawn = false
    if self.background_preview_drawer then
        preview_drawn = self.background_preview_drawer(theme_id, {
            x = 0,
            y = 0,
            width = window_width,
            height = window_height,
            mode = "fullscreen",
            preview_seed = preview_seed,
        }) == true
    end

    if not preview_drawn then
        drawFallbackBackgroundPreview(theme_id, 0, 0, window_width, window_height)
    end

    love.graphics.setColor(0, 0, 0, 0.12)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)
    love.graphics.setColor(1, 1, 1, 1)
end

function GameplaySettingsOverlay:draw(state, window_width, window_height)
    local colors = self.ui_style.colors
    local frame = self:getOverlayFrame(window_width, window_height)
    local tabs = self:getTabBounds(window_width, window_height)
    local content = self:getContentFrame(window_width, window_height)
    local footer = self:getFooterSectionBounds(window_width, window_height)
    local active_tab = state.settings_tab or "display_audio"

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)
    self.panel:draw(frame, { radius = 20, shadow_offset = 8 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("gameplay.settings_title"), frame.x, frame.y + 18, frame.width, "center")

    local function drawTab(tab_id, bounds, label_key)
        WoodButton.draw(self.fonts, self.ui_style, {
            label = I18n:t(label_key),
            x = bounds.x,
            y = bounds.y,
            width = bounds.width,
            height = bounds.height,
            hovered = state.hovered_settings_control == ("settings_tab_" .. tab_id),
            enabled = true,
            variant = active_tab == tab_id and "primary" or "secondary",
            font_token = "Caption",
            radius = 10,
        })
    end

    drawTab("display_audio", tabs.display_audio, "gameplay.settings_tab_display_audio")
    drawTab("background", tabs.background, "gameplay.settings_tab_background")
    drawTab("cards", tabs.cards, "gameplay.settings_tab_cards")

    love.graphics.setColor(colors.panel_shadow)
    love.graphics.rectangle("fill", content.x, content.y, content.width, content.height, 14, 14)
    love.graphics.setColor(colors.panel_inner)
    love.graphics.rectangle("fill", content.x + 2, content.y + 2, content.width - 4, content.height - 4, 12, 12)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(colors.panel_border)
    love.graphics.rectangle("line", content.x + 1, content.y + 1, content.width - 2, content.height - 2, 13, 13)
    love.graphics.setLineWidth(1)

    if active_tab == "display_audio" then
        local bounds = self:getDisplaySectionBounds(window_width, window_height)
        local locale_options = state.settings_language_options or I18n:getOrderedLocales()
        local current_locale = locale_options[state.settings_language_index or 1]
        local language_label = current_locale and I18n:getLocaleShortLabel(current_locale) or "-"
        local resolution = (state.settings_resolution_options or {})[state.settings_resolution_index or 1]
        local resolution_label = resolution and (tostring(resolution.width) .. " x " .. tostring(resolution.height)) or "-"
        local fps = (state.settings_fps_options or {})[state.settings_fps_index or 1]
        local fps_label = fps and I18n:t("gameplay.settings_fps_value", { fps = fps }) or "-"
        local game_volume = (state.settings_volume_options or {})[state.settings_game_volume_index or 1]
        local bgm_volume = (state.settings_volume_options or {})[state.settings_bgm_volume_index or 1]
        local game_bgm_options = state.settings_game_bgm_options or {}
        local game_bgm = game_bgm_options[state.settings_game_bgm_index or 1] or "game_default"

        love.graphics.setColor(colors.text_secondary)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.print(I18n:t("gameplay.settings_display_mode"), content.x + 18, bounds.mode_windowed.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_resolution"), content.x + 18, bounds.resolution_prev.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_language"), content.x + 18, bounds.language_prev.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_fps"), content.x + 18, bounds.fps_prev.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_game_volume"), content.x + 18, bounds.game_volume_prev.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_bgm_volume"), content.x + 18, bounds.bgm_volume_prev.y + 14)
        love.graphics.print(I18n:t("gameplay.settings_game_bgm"), content.x + 18, bounds.game_bgm_prev.y + 14)

        WoodButton.draw(self.fonts, self.ui_style, {
            label = I18n:t("gameplay.settings_mode_windowed"),
            x = bounds.mode_windowed.x,
            y = bounds.mode_windowed.y,
            width = bounds.mode_windowed.width,
            height = bounds.mode_windowed.height,
            hovered = state.hovered_settings_control == "settings_mode_windowed",
            enabled = true,
            variant = state.settings_window_mode == "windowed" and "primary" or "secondary",
            font_token = "Text",
            radius = 10,
        })
        WoodButton.draw(self.fonts, self.ui_style, {
            label = I18n:t("gameplay.settings_mode_fullscreen"),
            x = bounds.mode_fullscreen.x,
            y = bounds.mode_fullscreen.y,
            width = bounds.mode_fullscreen.width,
            height = bounds.mode_fullscreen.height,
            hovered = state.hovered_settings_control == "settings_mode_fullscreen",
            enabled = true,
            variant = state.settings_window_mode == "fullscreen" and "primary" or "secondary",
            font_token = "Text",
            radius = 10,
        })

        local resolution_enabled = state.settings_window_mode ~= "fullscreen"
        local function drawTriple(prev_id, next_id, prev_bounds, value_bounds, next_bounds, label, enabled, label_locale)
            WoodButton.draw(self.fonts, self.ui_style, {
                label = "<",
                x = prev_bounds.x,
                y = prev_bounds.y,
                width = prev_bounds.width,
                height = prev_bounds.height,
                hovered = state.hovered_settings_control == prev_id,
                enabled = enabled,
                variant = "secondary",
                font_token = "Text",
                radius = 10,
            })
            WoodButton.draw(self.fonts, self.ui_style, {
                label = label,
                locale = label_locale,
                x = value_bounds.x,
                y = value_bounds.y,
                width = value_bounds.width,
                height = value_bounds.height,
                hovered = false,
                enabled = enabled,
                variant = "secondary",
                font_token = "Text",
                radius = 10,
            })
            WoodButton.draw(self.fonts, self.ui_style, {
                label = ">",
                x = next_bounds.x,
                y = next_bounds.y,
                width = next_bounds.width,
                height = next_bounds.height,
                hovered = state.hovered_settings_control == next_id,
                enabled = enabled,
                variant = "secondary",
                font_token = "Text",
                radius = 10,
            })
        end

        drawTriple("settings_resolution_prev", "settings_resolution_next", bounds.resolution_prev, bounds.resolution_value, bounds.resolution_next, resolution_label, resolution_enabled)
        drawTriple("settings_language_prev", "settings_language_next", bounds.language_prev, bounds.language_value, bounds.language_next, language_label, true, current_locale)
        drawTriple("settings_fps_prev", "settings_fps_next", bounds.fps_prev, bounds.fps_value, bounds.fps_next, fps_label, true)
        drawTriple("settings_game_volume_prev", "settings_game_volume_next", bounds.game_volume_prev, bounds.game_volume_value, bounds.game_volume_next, volumeLabel(game_volume), true)
        drawTriple("settings_bgm_volume_prev", "settings_bgm_volume_next", bounds.bgm_volume_prev, bounds.bgm_volume_value, bounds.bgm_volume_next, volumeLabel(bgm_volume), true)
        drawTriple("settings_game_bgm_prev", "settings_game_bgm_next", bounds.game_bgm_prev, bounds.game_bgm_value, bounds.game_bgm_next, gameBgmLabel(game_bgm), true)

    elseif active_tab == "background" then
        local bounds = self:getBackgroundSectionBounds(window_width, window_height)
        local current_id = BackgroundThemeCatalog.normalizeThemeId(state.settings_background_theme_id)
        local function drawBackgroundCard(control_id, card_bounds, theme_id)
            local hovered = state.hovered_settings_control == control_id
            local selected = current_id == theme_id
            local radius = 12
            local inset = 6
            local preview = {
                x = card_bounds.x + inset,
                y = card_bounds.y + inset,
                width = card_bounds.width - inset * 2,
                height = card_bounds.height - inset * 2,
            }

            love.graphics.setColor(0, 0, 0, 0.22)
            love.graphics.rectangle("fill", card_bounds.x, card_bounds.y + 4, card_bounds.width, card_bounds.height, radius, radius)

            love.graphics.setColor(selected and colors.button_primary_frame or colors.button_secondary_frame)
            love.graphics.rectangle("fill", card_bounds.x, card_bounds.y, card_bounds.width, card_bounds.height, radius, radius)

            local preview_drawn = false
            if self.background_preview_drawer then
                preview_drawn = self.background_preview_drawer(theme_id, preview) == true
            end
            if not preview_drawn then
                drawFallbackBackgroundPreview(theme_id, preview.x, preview.y, preview.width, preview.height)
            end

            if hovered then
                love.graphics.setColor(1, 1, 1, 0.08)
                love.graphics.rectangle("fill", preview.x, preview.y, preview.width, preview.height, radius - 4, radius - 4)
            end

            local label_h = math.max(34, math.floor(card_bounds.height * 0.24))
            local label_y = card_bounds.y + card_bounds.height - label_h - inset
            love.graphics.setColor(0.1, 0.08, 0.06, selected and 0.74 or 0.62)
            love.graphics.rectangle("fill", preview.x + 2, label_y, preview.width - 4, label_h, 8, 8)

            love.graphics.setLineWidth(2)
            love.graphics.setColor(selected and colors.button_primary_border or colors.button_secondary_border)
            love.graphics.rectangle("line", card_bounds.x + 1, card_bounds.y + 1, card_bounds.width - 2, card_bounds.height - 2, radius, radius)
            love.graphics.rectangle("line", preview.x, preview.y, preview.width, preview.height, radius - 4, radius - 4)
            love.graphics.setLineWidth(1)

            love.graphics.setFont(self.fonts:get("Text"))
            love.graphics.setColor(1, 0.98, 0.92, 1)
            love.graphics.printf(backgroundThemeLabel(theme_id), preview.x, label_y + 8, preview.width, "center")
        end

        drawBackgroundCard("settings_background_spring", bounds.spring, "spring")
        drawBackgroundCard("settings_background_summer", bounds.summer, "summer")
        drawBackgroundCard("settings_background_autumn", bounds.autumn, "autumn")
        drawBackgroundCard("settings_background_winter", bounds.winter, "winter")
        drawBackgroundCard("settings_background_cosmos", bounds.cosmos, "cosmos")
        drawBackgroundCard("settings_background_nebula", bounds.nebula, "nebula")
        drawBackgroundCard("settings_background_galaxy", bounds.galaxy, "galaxy")
        drawBackgroundCard("settings_background_warp", bounds.warp, "warp")
    else
        local bounds = self:getCardsSectionBounds(window_width, window_height)
        local options = state.settings_card_theme_options or {}
        local back_options = state.settings_card_back_options or {}
        local current_theme_id = options[state.settings_card_theme_index or 1] or ThemeCatalog.DEFAULT_THEME_ID
        local current_back_id = back_options[state.settings_card_back_index or 1] or "classic_grid"

        local function drawPreviewCard(frame, draw_face)
            love.graphics.setColor(0, 0, 0, 0.14)
            love.graphics.rectangle("fill", frame.x + 2, frame.y + 4, frame.width, frame.height, 10, 10)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, 10, 10)
            love.graphics.setColor(0.24, 0.28, 0.34, 0.95)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", frame.x, frame.y, frame.width, frame.height, 10, 10)
            love.graphics.setLineWidth(1)
            if draw_face then
                draw_face(frame)
            end
        end

        local function drawSoftPanel(panel_bounds)
            love.graphics.setColor(0.86, 0.72, 0.48, 0.10)
            love.graphics.rectangle("fill", panel_bounds.x + 2, panel_bounds.y + 4, panel_bounds.width, panel_bounds.height, 16, 16)
            love.graphics.setColor(0.98, 0.93, 0.80, 0.92)
            love.graphics.rectangle("fill", panel_bounds.x, panel_bounds.y, panel_bounds.width, panel_bounds.height, 16, 16)
        end

        drawSoftPanel(bounds.back_panel)
        drawSoftPanel(bounds.theme_panel)

        drawPreviewCard(bounds.joker_preview, function(frame)
            self.card_theme_manager:drawJoker(current_theme_id, frame, { is_big_joker = true })
        end)
        drawPreviewCard(bounds.j_preview, function(frame)
            self.card_theme_manager:drawFace(current_theme_id, "J", frame, {
                suit = "B",
                rank = "J",
                suit_color = { 0.86, 0.22, 0.22, 1 },
            })
        end)
        drawPreviewCard(bounds.q_preview, function(frame)
            self.card_theme_manager:drawFace(current_theme_id, "Q", frame, {
                suit = "A",
                rank = "Q",
                suit_color = { 0.12, 0.12, 0.14, 1 },
            })
        end)
        drawPreviewCard(bounds.k_preview, function(frame)
            self.card_theme_manager:drawFace(current_theme_id, "K", frame, {
                suit = "D",
                rank = "K",
                suit_color = { 0.86, 0.22, 0.22, 1 },
            })
        end)

        drawPreviewCard(bounds.back_preview, function(frame)
            CardBackStyle.draw(frame.x + 8, frame.y + 8, frame.width - 16, frame.height - 16, current_back_id, {
                outer_radius = 10,
                inner_radius = 8,
                inset = 2,
            })
        end)

        love.graphics.setColor(colors.text_secondary)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.print(I18n:t("gameplay.settings_cards_high_contrast"), bounds.high_contrast_label.x, bounds.high_contrast_label.y)

        WoodButton.draw(self.fonts, self.ui_style, {
            label = state.card_theme_config.high_contrast and I18n:t("gameplay.settings_checkbox_checked") or I18n:t("gameplay.settings_checkbox_unchecked"),
            x = bounds.high_contrast.x,
            y = bounds.high_contrast.y,
            width = bounds.high_contrast.width,
            height = bounds.high_contrast.height,
            hovered = state.hovered_settings_control == "settings_cards_high_contrast_toggle",
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = "<",
            x = bounds.theme_prev.x,
            y = bounds.theme_prev.y,
            width = bounds.theme_prev.width,
            height = bounds.theme_prev.height,
            hovered = state.hovered_settings_control == "settings_cards_theme_prev",
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = cardThemeLabel(current_theme_id),
            x = bounds.theme_value.x,
            y = bounds.theme_value.y,
            width = bounds.theme_value.width,
            height = bounds.theme_value.height,
            hovered = false,
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = ">",
            x = bounds.theme_next.x,
            y = bounds.theme_next.y,
            width = bounds.theme_next.width,
            height = bounds.theme_next.height,
            hovered = state.hovered_settings_control == "settings_cards_theme_next",
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = "<",
            x = bounds.back_prev.x,
            y = bounds.back_prev.y,
            width = bounds.back_prev.width,
            height = bounds.back_prev.height,
            hovered = state.hovered_settings_control == "settings_cards_back_prev",
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = cardBackLabel(current_back_id),
            x = bounds.back_value.x,
            y = bounds.back_value.y,
            width = bounds.back_value.width,
            height = bounds.back_value.height,
            hovered = false,
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })

        WoodButton.draw(self.fonts, self.ui_style, {
            label = ">",
            x = bounds.back_next.x,
            y = bounds.back_next.y,
            width = bounds.back_next.width,
            height = bounds.back_next.height,
            hovered = state.hovered_settings_control == "settings_cards_back_next",
            enabled = true,
            variant = "secondary",
            font_token = "Text",
            radius = 10,
        })
    end

    WoodButton.draw(self.fonts, self.ui_style, {
        label = I18n:t("gameplay.settings_reset_defaults"),
        x = footer.reset_defaults.x,
        y = footer.reset_defaults.y,
        width = footer.reset_defaults.width,
        height = footer.reset_defaults.height,
        hovered = state.hovered_settings_control == "settings_reset_defaults",
        enabled = true,
        variant = "secondary",
        font_token = "Caption",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.ui_style, {
        label = I18n:t("gameplay.settings_back_to_main_menu"),
        x = footer.back_to_main_menu.x,
        y = footer.back_to_main_menu.y,
        width = footer.back_to_main_menu.width,
        height = footer.back_to_main_menu.height,
        hovered = state.hovered_settings_control == "settings_back_to_main_menu",
        enabled = true,
        variant = "secondary",
        font_token = "Caption",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.ui_style, {
        label = I18n:t("gameplay.settings_exit_game"),
        x = footer.exit_game.x,
        y = footer.exit_game.y,
        width = footer.exit_game.width,
        height = footer.exit_game.height,
        hovered = state.hovered_settings_control == "settings_exit_game",
        enabled = true,
        variant = "secondary",
        font_token = "Caption",
        radius = 10,
    })

    self.close_button:draw(self:getCloseBounds(window_width, window_height), state.hovered_settings_control == "settings_close")
end

return GameplaySettingsOverlay
