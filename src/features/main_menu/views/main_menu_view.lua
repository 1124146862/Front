local MainMenuEntryActionButton = require("src.features.main_menu.components.main_menu_entry_action_button")
local TopIconButtonGroup = require("src.features.main_menu.components.top_icon_button_group")
local GameRulesOverlay = require("src.features.main_menu.overlays.game_rules_overlay")
local MatchmakingOverlay = require("src.features.main_menu.overlays.matchmaking_overlay")
local WardrobeOverlay = require("src.features.main_menu.overlays.wardrobe_overlay")
local ConfirmationDialog = require("src.core.ui.confirmation_dialog")
local WoodButton = require("src.core.ui.wood_button")
local IconCloseButton = require("src.core.ui.icon_close_button")
local MuteButton = require("src.core.ui.mute_button")
local SettingsButton = require("src.core.ui.settings_button")
local WardrobeButton = require("src.core.ui.wardrobe_button")
local WoodPanel = require("src.core.ui.wood_panel")
local ButtonText = require("src.core.ui.button_text")
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local IconButtonsStyle = require("src.features.main_menu.icon_buttons_style")
local I18n = require("src.core.i18n.i18n")
local LoadingOverlay = require("src.core.ui.loading_overlay")

local MainMenuView = {}
MainMenuView.__index = MainMenuView

local ACTIONS = {
    { id = "single_player", key = "main_menu.single_player", enabled = true, variant = "primary" },
    { id = "online_lobby", key = "main_menu.online_lobby", enabled = true, variant = "secondary" },
    { id = "game_rules", key = "main_menu.game_rules", enabled = true, variant = "secondary" },
}

local MODE_OPTIONS = {
    { id = "classic", label_key = "main_menu.single_player_mode_classic" },
    { id = "level", label_key = "main_menu.single_player_mode_level" },
}

local function containsPoint(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.w
        and y >= bounds.y
        and y <= bounds.y + bounds.h
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function resolveProfilePlaqueMetrics(layout, font, avatar_size, nickname)
    local base_avatar = layout.profile_avatar_size or avatar_size
    if base_avatar <= 0 then
        base_avatar = avatar_size
    end
    local scale = avatar_size / base_avatar

    local plaque_height_base = layout.profile_plaque_height or math.floor(base_avatar * 0.44)
    local plaque_padding_base = layout.profile_plaque_padding or math.floor(base_avatar * 0.19)
    local plaque_gap_base = layout.profile_plaque_gap or math.floor(base_avatar * 0.14)
    local plaque_min_base = layout.profile_plaque_min or 0
    local plaque_max_base = layout.profile_plaque_max or math.floor(base_avatar * 3.6)
    local plaque_radius_base = layout.profile_plaque_radius or math.floor((layout.profile_plaque_height or plaque_height_base) * 0.35)

    local plaque_h = math.max(28, math.floor(plaque_height_base * scale + 0.5))
    local plaque_padding = math.max(10, math.floor(plaque_padding_base * scale + 0.5))
    local plaque_gap = math.max(8, math.floor(plaque_gap_base * scale + 0.5))
    local plaque_min = math.floor(plaque_min_base * scale + 0.5)
    local derived_min = math.floor(plaque_h * 2.4)
    if plaque_min <= 0 then
        plaque_min = derived_min
    else
        plaque_min = math.min(plaque_min, derived_min)
    end
    local plaque_max = math.max(plaque_min + 40, math.floor(plaque_max_base * scale + 0.5))
    local plaque_radius = math.max(10, math.floor(plaque_radius_base * scale + 0.5))

    local raw_width = font:getWidth(nickname) + plaque_padding * 2
    local plaque_w = clamp(raw_width, plaque_min, plaque_max)

    return {
        w = plaque_w,
        h = plaque_h,
        padding = plaque_padding,
        gap = plaque_gap,
        radius = plaque_radius,
        scale = scale,
    }
end

local function volumePercentLabel(value)
    local percent = math.floor((tonumber(value) or 0) * 100 + 0.5)
    return I18n:t("main_menu.settings_volume_value", { percent = percent })
end

function MainMenuView.new(options)
    local self = setmetatable({}, MainMenuView)

    self.fonts = assert(options and options.fonts, "MainMenuView requires fonts")
    self.style = assert(options and options.style, "MainMenuView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.wood_panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.mute_button = MuteButton.new()
    self.settings_button = SettingsButton.new()
    self.wardrobe_button = WardrobeButton.new()
    self.icon_style = IconButtonsStyle
    self.top_icon_buttons = TopIconButtonGroup.new({
        style = self.icon_style,
    })
    self.game_rules_overlay = GameRulesOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.matchmaking_overlay = MatchmakingOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.wardrobe_overlay = WardrobeOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.confirmation_dialog = ConfirmationDialog.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.loading_overlay = LoadingOverlay.new({
        fonts = self.fonts,
        message_key = "common.loading",
    })
    self.avatars_by_id = {}

    for _, avatar in ipairs(AvatarRegistry) do
        if type(avatar) == "table" and type(avatar.id) == "string" then
            self.avatars_by_id[avatar.id] = avatar
        end
    end

    return self
end

function MainMenuView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function MainMenuView:update(dt, state)
    local busy = state and (state.single_player_loading_visible or state.server_loading_visible)
    if busy then
        self.loading_overlay:show()
    else
        self.loading_overlay:hide()
    end
    self.loading_overlay:update(dt)
end

function MainMenuView:resolveMenuActionDescriptors(state)
    local actions = {}
    for _, action in ipairs(ACTIONS) do
        local enabled = action.enabled
        local label = I18n:t(action.key)
        local variant = action.variant
        if state and state.submitting and action.id == "single_player" then
            enabled = false
        end
        if action.id == "matchmaking" and state then
            if state.matchmaking_transition_locked then
                label = I18n:t("main_menu.matchmaking_phase_matched")
                enabled = false
            elseif state.matchmaking_queue_active then
                label = I18n:t("main_menu.matchmaking_cancel")
                variant = "primary"
            end
        end

        actions[#actions + 1] = {
            id = action.id,
            label = label,
            enabled = enabled,
            hovered = state and state.hovered_action == action.id,
            variant = variant,
        }
    end

    return actions
end

function MainMenuView:resolveMenuLayout(state)
    local layout = self.style.layout
    local padding = layout.panel_padding or 18
    local gap = layout.menu_gap or 12
    local cols = 1
    local min_button_w = layout.menu_button_min_width or layout.menu_button_width or 210
    local button_h = layout.menu_button_height or 64
    local text_padding = layout.menu_button_text_padding or 56
    local actions = self:resolveMenuActionDescriptors(state)
    local rows = math.max(1, math.ceil(#actions / cols))
    local horizontal_margin = layout.menu_panel_min_window_margin or 40
    local max_button_w = layout.menu_button_max_width
    if type(max_button_w) ~= "number" or max_button_w <= 0 then
        local max_content_w = math.max(
            min_button_w * cols + (cols - 1) * gap,
            self.window_width - horizontal_margin * 2 - padding * 2
        )
        max_button_w = math.max(min_button_w, math.floor((max_content_w - (cols - 1) * gap) / cols))
    end

    local button_font = self.fonts:get("Button")
    local column_widths = {}
    for column = 1, cols do
        column_widths[column] = min_button_w
    end

    for index, action in ipairs(actions) do
        local column = ((index - 1) % cols) + 1
        local measured_width = math.ceil(button_font:getWidth(action.label) + text_padding)
        local target_width = clamp(measured_width, min_button_w, max_button_w)
        if target_width > column_widths[column] then
            column_widths[column] = target_width
        end
    end

    local content_width = (cols - 1) * gap
    for column = 1, cols do
        content_width = content_width + column_widths[column]
    end
    local content_height = rows * button_h + (rows - 1) * gap
    local panel_width = content_width + padding * 2
    local panel_height = content_height + padding * 2
    local panel_x = math.floor((self.window_width - panel_width) / 2)
    local panel_y = math.floor((self.window_height - panel_height) / 2)

    local column_offsets = {}
    local running_x = 0
    for column = 1, cols do
        column_offsets[column] = running_x
        running_x = running_x + column_widths[column] + gap
    end

    return {
        actions = actions,
        cols = cols,
        rows = rows,
        gap = gap,
        padding = padding,
        button_h = button_h,
        column_widths = column_widths,
        column_offsets = column_offsets,
        panel = {
            x = panel_x,
            y = panel_y,
            w = panel_width,
            h = panel_height,
        },
    }
end

function MainMenuView:getButtons(state)
    local metrics = self:resolveMenuLayout(state)
    local panel = metrics.panel
    local start_x = panel.x + metrics.padding
    local start_y = panel.y + metrics.padding
    local buttons = {}

    for index, action in ipairs(metrics.actions) do
        local column = ((index - 1) % metrics.cols) + 1
        local row = math.floor((index - 1) / metrics.cols) + 1
        local x = start_x + metrics.column_offsets[column]
        local y = start_y + (row - 1) * (metrics.button_h + metrics.gap)
        buttons[#buttons + 1] = {
            id = action.id,
            label = action.label,
            enabled = action.enabled,
            hovered = action.hovered,
            x = x,
            y = y,
            width = metrics.column_widths[column],
            height = metrics.button_h,
            variant = action.variant,
        }
    end

    return buttons
end

function MainMenuView:getMainPanelBounds(state)
    return self:resolveMenuLayout(state).panel
end

function MainMenuView:getProfileButtonBounds()
    local profile = self._last_user_profile or {}
    local nickname = tostring(profile.nickname or "-")
    local layout = self.style.layout
    local font = self.fonts:get("TextSmall")
    local avatar_size = layout.profile_avatar_size or 96
    local plaque = resolveProfilePlaqueMetrics(layout, font, avatar_size, nickname)
    return {
        x = layout.profile_x or 24,
        y = layout.profile_y or 16,
        w = avatar_size + plaque.gap + plaque.w,
        h = math.max(avatar_size, plaque.h),
    }
end

function MainMenuView:isProfileHovered(x, y)
    local bounds = self:getProfileButtonBounds()
    return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

function MainMenuView:getTopIconFrames()
    return self.top_icon_buttons:getFrames(self.window_width, self:getProfileButtonBounds())
end

function MainMenuView:getTopIconControlAt(x, y)
    return self.top_icon_buttons:hitTest(self.window_width, self:getProfileButtonBounds(), x, y)
end

function MainMenuView:isMuteIconHovered(x, y)
    return self:getTopIconControlAt(x, y) == "mute"
end

function MainMenuView:isWardrobeIconHovered(x, y)
    return false
end

function MainMenuView:isSettingsIconHovered(x, y)
    return self:getTopIconControlAt(x, y) == "settings"
end

function MainMenuView:getWardrobeOverlayControlAt(x, y, state, user_profile)
    return self.wardrobe_overlay:getControlAt(x, y, state, user_profile)
end

function MainMenuView:getMatchmakingOverlayControlAt(x, y)
    return self.matchmaking_overlay:getControlAt(x, y)
end

function MainMenuView:getActionAt(x, y, state_or_hovered_action, hovered_action)
    local resolved_state
    if type(state_or_hovered_action) == "table" then
        resolved_state = state_or_hovered_action
    else
        hovered_action = state_or_hovered_action
    end
    if resolved_state and hovered_action == nil then
        hovered_action = resolved_state.hovered_action
    end

    local buttons = self:getButtons({
        hovered_action = hovered_action,
        submitting = resolved_state and resolved_state.submitting or false,
        matchmaking_transition_locked = resolved_state and resolved_state.matchmaking_transition_locked or false,
        matchmaking_queue_active = resolved_state and resolved_state.matchmaking_queue_active or false,
    })
    for _, button in ipairs(buttons) do
        if containsPoint({ x = button.x, y = button.y, w = button.width, h = button.height }, x, y) then
            return button.id
        end
    end

    return nil
end

function MainMenuView:isBackgroundClickable(x, y, state)
    if state and (
        state.mode_overlay_visible
        or state.rules_overlay_visible
        or state.matchmaking_overlay_visible
        or state.wardrobe_overlay_visible
        or state.settings_overlay_visible
        or state.single_player_loading_visible
        or state.server_loading_visible
    ) then
        return false
    end

    if self:isProfileHovered(x, y)
        or self:isMuteIconHovered(x, y)
        or self:isWardrobeIconHovered(x, y)
        or self:isSettingsIconHovered(x, y)
    then
        return false
    end

    if self:getActionAt(x, y, state, nil) ~= nil then
        return false
    end

    if containsPoint(self:getMainPanelBounds(state), x, y) then
        return false
    end

    return true
end

function MainMenuView:getModeOverlayFrame()
    local width = 440
    local height = 188
    return {
        x = math.floor((self.window_width - width) / 2),
        y = math.floor((self.window_height - height) / 2),
        width = width,
        height = height,
    }
end

function MainMenuView:getModeOptionButtons(state)
    local frame = self:getModeOverlayFrame()
    local buttons = {}
    local button_width = 260
    local button_height = 48
    local start_x = frame.x + math.floor((frame.width - button_width) / 2)
    local start_y = frame.y + 54

    for index, option in ipairs(MODE_OPTIONS) do
        buttons[#buttons + 1] = {
            id = option.id,
            label = I18n:t(option.label_key),
            x = start_x,
            y = start_y + (index - 1) * (button_height + 10),
            width = button_width,
            height = button_height,
            hovered = state and state.hovered_mode_option == option.id,
            variant = index == 1 and "primary" or "secondary",
        }
    end

    return buttons
end

function MainMenuView:getModeOptionAt(x, y)
    for _, button in ipairs(self:getModeOptionButtons({ hovered_mode_option = nil })) do
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            return button.id
        end
    end
    return nil
end

function MainMenuView:getSinglePlayerLoadingBounds()
    local width = math.min(420, self.window_width - 40)
    local height = 136
    return {
        x = math.floor((self.window_width - width) / 2),
        y = math.floor((self.window_height - height) / 2),
        width = width,
        height = height,
    }
end

function MainMenuView:drawSinglePlayerLoadingOverlay(state)
    self.loading_overlay:draw(self.window_width, self.window_height)
end

function MainMenuView:getModeOverlayCloseBounds()
    local frame = self:getModeOverlayFrame()
    return {
        x = frame.x + frame.width - 58,
        y = frame.y + 14,
        width = 38,
        height = 38,
    }
end

function MainMenuView:getRulesOverlayControlAt(x, y, state)
    return self.game_rules_overlay:getControlAt(x, y, (state and state.rules_page_index) or 1)
end

function MainMenuView:drawRulesOverlay(state)
    self.game_rules_overlay:draw(
        (state and state.rules_page_index) or 1,
        state and state.hovered_rules_control or nil,
        state and state.card_theme_config or nil,
        state and state.rules_text_scroll or 0
    )
end

function MainMenuView:isModeOverlayCloseHovered(x, y)
    local bounds = self:getModeOverlayCloseBounds()
    return x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height
end

function MainMenuView:getSettingsOverlayFrame()
    local width = 700
    local height = 626
    return {
        x = math.floor((self.window_width - width) / 2),
        y = math.floor((self.window_height - height) / 2),
        width = width,
        height = height,
    }
end

function MainMenuView:getSettingsOverlayCloseBounds()
    local frame = self:getSettingsOverlayFrame()
    return {
        x = frame.x + frame.width - 58,
        y = frame.y + 14,
        width = 38,
        height = 38,
    }
end

function MainMenuView:getSettingsModeButtonBounds(mode_id)
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 78
    local width = 170
    local height = 52
    local left_x = frame.x + frame.width - 64 - width * 2 - 14

    if mode_id == "windowed" then
        return { x = left_x, y = y, width = width, height = height }
    end

    return { x = left_x + width + 14, y = y, width = width, height = height }
end

function MainMenuView:getSettingsResolutionBounds()
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 152
    local left_x = frame.x + frame.width - 64 - 370

    return {
        prev = { x = left_x, y = y, width = 58, height = 52 },
        value = { x = left_x + 72, y = y, width = 226, height = 52 },
        next = { x = left_x + 312, y = y, width = 58, height = 52 },
    }
end

function MainMenuView:getSettingsLanguageBounds()
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 226
    local left_x = frame.x + frame.width - 64 - 370

    return {
        prev = { x = left_x, y = y, width = 58, height = 52 },
        value = { x = left_x + 72, y = y, width = 226, height = 52 },
        next = { x = left_x + 312, y = y, width = 58, height = 52 },
    }
end

function MainMenuView:getSettingsFpsBounds()
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 300
    local left_x = frame.x + frame.width - 64 - 370

    return {
        prev = { x = left_x, y = y, width = 58, height = 52 },
        value = { x = left_x + 72, y = y, width = 226, height = 52 },
        next = { x = left_x + 312, y = y, width = 58, height = 52 },
    }
end

function MainMenuView:getSettingsGameVolumeBounds()
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 374
    local left_x = frame.x + frame.width - 64 - 370

    return {
        prev = { x = left_x, y = y, width = 58, height = 52 },
        value = { x = left_x + 72, y = y, width = 226, height = 52 },
        next = { x = left_x + 312, y = y, width = 58, height = 52 },
    }
end

function MainMenuView:getSettingsBgmVolumeBounds()
    local frame = self:getSettingsOverlayFrame()
    local y = frame.y + 448
    local left_x = frame.x + frame.width - 64 - 370

    return {
        prev = { x = left_x, y = y, width = 58, height = 52 },
        value = { x = left_x + 72, y = y, width = 226, height = 52 },
        next = { x = left_x + 312, y = y, width = 58, height = 52 },
    }
end

function MainMenuView:getSettingsFooterBounds()
    local frame = self:getSettingsOverlayFrame()
    local button_width = 248
    local button_gap = 24
    local total_width = button_width * 2 + button_gap
    local left_x = frame.x + math.floor((frame.width - total_width) / 2)
    local y = frame.y + 538

    return {
        reset_defaults = {
            x = left_x,
            y = y,
            width = button_width,
            height = 54,
        },
        exit_game = {
            x = left_x + button_width + button_gap,
            y = y,
            width = button_width,
            height = 54,
        },
    }
end

function MainMenuView:getSettingsResetDefaultsBounds()
    return self:getSettingsFooterBounds().reset_defaults
end

function MainMenuView:getSettingsExitGameBounds()
    return self:getSettingsFooterBounds().exit_game
end

function MainMenuView:getSettingsControlAt(x, y, state)
    local close_bounds = self:getSettingsOverlayCloseBounds()
    if x >= close_bounds.x and x <= close_bounds.x + close_bounds.width and y >= close_bounds.y and y <= close_bounds.y + close_bounds.height then
        return "settings_close"
    end

    local windowed_bounds = self:getSettingsModeButtonBounds("windowed")
    if x >= windowed_bounds.x and x <= windowed_bounds.x + windowed_bounds.width and y >= windowed_bounds.y and y <= windowed_bounds.y + windowed_bounds.height then
        return "settings_mode_windowed"
    end

    local fullscreen_bounds = self:getSettingsModeButtonBounds("fullscreen")
    if x >= fullscreen_bounds.x and x <= fullscreen_bounds.x + fullscreen_bounds.width and y >= fullscreen_bounds.y and y <= fullscreen_bounds.y + fullscreen_bounds.height then
        return "settings_mode_fullscreen"
    end

    local resolution_bounds = self:getSettingsResolutionBounds()
    local resolution_enabled = state and state.settings_window_mode ~= "fullscreen"
    if resolution_enabled and x >= resolution_bounds.prev.x and x <= resolution_bounds.prev.x + resolution_bounds.prev.width and y >= resolution_bounds.prev.y and y <= resolution_bounds.prev.y + resolution_bounds.prev.height then
        return "settings_resolution_prev"
    end
    if resolution_enabled and x >= resolution_bounds.next.x and x <= resolution_bounds.next.x + resolution_bounds.next.width and y >= resolution_bounds.next.y and y <= resolution_bounds.next.y + resolution_bounds.next.height then
        return "settings_resolution_next"
    end

    local language_bounds = self:getSettingsLanguageBounds()
    if x >= language_bounds.prev.x and x <= language_bounds.prev.x + language_bounds.prev.width and y >= language_bounds.prev.y and y <= language_bounds.prev.y + language_bounds.prev.height then
        return "settings_language_prev"
    end
    if x >= language_bounds.next.x and x <= language_bounds.next.x + language_bounds.next.width and y >= language_bounds.next.y and y <= language_bounds.next.y + language_bounds.next.height then
        return "settings_language_next"
    end

    local fps_bounds = self:getSettingsFpsBounds()
    if x >= fps_bounds.prev.x and x <= fps_bounds.prev.x + fps_bounds.prev.width and y >= fps_bounds.prev.y and y <= fps_bounds.prev.y + fps_bounds.prev.height then
        return "settings_fps_prev"
    end
    if x >= fps_bounds.next.x and x <= fps_bounds.next.x + fps_bounds.next.width and y >= fps_bounds.next.y and y <= fps_bounds.next.y + fps_bounds.next.height then
        return "settings_fps_next"
    end

    local game_volume_bounds = self:getSettingsGameVolumeBounds()
    if x >= game_volume_bounds.prev.x and x <= game_volume_bounds.prev.x + game_volume_bounds.prev.width and y >= game_volume_bounds.prev.y and y <= game_volume_bounds.prev.y + game_volume_bounds.prev.height then
        return "settings_game_volume_prev"
    end
    if x >= game_volume_bounds.next.x and x <= game_volume_bounds.next.x + game_volume_bounds.next.width and y >= game_volume_bounds.next.y and y <= game_volume_bounds.next.y + game_volume_bounds.next.height then
        return "settings_game_volume_next"
    end

    local bgm_volume_bounds = self:getSettingsBgmVolumeBounds()
    if x >= bgm_volume_bounds.prev.x and x <= bgm_volume_bounds.prev.x + bgm_volume_bounds.prev.width and y >= bgm_volume_bounds.prev.y and y <= bgm_volume_bounds.prev.y + bgm_volume_bounds.prev.height then
        return "settings_bgm_volume_prev"
    end
    if x >= bgm_volume_bounds.next.x and x <= bgm_volume_bounds.next.x + bgm_volume_bounds.next.width and y >= bgm_volume_bounds.next.y and y <= bgm_volume_bounds.next.y + bgm_volume_bounds.next.height then
        return "settings_bgm_volume_next"
    end

    local reset_bounds = self:getSettingsResetDefaultsBounds()
    if x >= reset_bounds.x and x <= reset_bounds.x + reset_bounds.width and y >= reset_bounds.y and y <= reset_bounds.y + reset_bounds.height then
        return "settings_reset_defaults"
    end

    local exit_bounds = self:getSettingsExitGameBounds()
    if x >= exit_bounds.x and x <= exit_bounds.x + exit_bounds.width and y >= exit_bounds.y and y <= exit_bounds.y + exit_bounds.height then
        return "settings_exit_game"
    end

    return nil
end

function MainMenuView:getConfirmDialogControlAt(x, y, state)
    if not state.confirm_dialog_visible then
        return nil
    end
    return self.confirmation_dialog:getControlAt(x, y, self.window_width, self.window_height)
end

function MainMenuView:drawModeOverlay(state)
    local colors = self.style.colors
    local frame = self:getModeOverlayFrame()

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, self.window_width, self.window_height)

    self.wood_panel:draw(frame, { radius = 20, shadow_offset = 8 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("main_menu.single_player_mode_title"), frame.x, frame.y + 10, frame.width, "center")

    for _, button in ipairs(self:getModeOptionButtons(state)) do
        MainMenuEntryActionButton.drawButton(self.fonts, self.style, {
            label = button.label,
            x = button.x,
            y = button.y,
            width = button.width,
            height = button.height,
            hovered = button.hovered,
            enabled = true,
            variant = button.variant,
            font_token = "Text",
            radius = 14,
            bold = true,
            bold_offset = 1,
        })
    end

    self.close_button:draw(self:getModeOverlayCloseBounds(), state.hovered_mode_close)
end

function MainMenuView:drawSettingsOverlay(state)
    local colors = self.style.colors
    local frame = self:getSettingsOverlayFrame()
    local mode_windowed_bounds = self:getSettingsModeButtonBounds("windowed")
    local mode_fullscreen_bounds = self:getSettingsModeButtonBounds("fullscreen")
    local resolution_bounds = self:getSettingsResolutionBounds()
    local language_bounds = self:getSettingsLanguageBounds()
    local fps_bounds = self:getSettingsFpsBounds()
    local game_volume_bounds = self:getSettingsGameVolumeBounds()
    local bgm_volume_bounds = self:getSettingsBgmVolumeBounds()
    local footer_bounds = self:getSettingsFooterBounds()
    local reset_defaults_bounds = footer_bounds.reset_defaults
    local exit_game_bounds = footer_bounds.exit_game
    local resolution_options = state.settings_resolution_options or {}
    local resolution_index = state.settings_resolution_index or 1
    local current_resolution = resolution_options[resolution_index]
    local resolution_label = current_resolution and (tostring(current_resolution.width) .. " x " .. tostring(current_resolution.height)) or "-"
    local locale_options = state.settings_language_options or I18n:getOrderedLocales()
    local locale_index = state.settings_language_index or 1
    local current_locale = locale_options[locale_index]
    local language_label = current_locale and I18n:getLocaleShortLabel(current_locale) or "-"
    local fps_options = state.settings_fps_options or {}
    local fps_index = state.settings_fps_index or 1
    local current_fps = fps_options[fps_index]
    local fps_label = current_fps and I18n:t("main_menu.settings_fps_value", { fps = current_fps }) or "-"
    local volume_options = state.settings_volume_options or {}
    local game_volume_index = state.settings_game_volume_index or 1
    local bgm_volume_index = state.settings_bgm_volume_index or 1
    local game_volume_label = volumePercentLabel(volume_options[game_volume_index])
    local bgm_volume_label = volumePercentLabel(volume_options[bgm_volume_index])
    local resolution_enabled = state.settings_window_mode ~= "fullscreen"

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, self.window_width, self.window_height)

    self.wood_panel:draw(frame, { radius = 20, shadow_offset = 8 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("main_menu.settings_title"), frame.x, frame.y + 18, frame.width, "center")

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_display_mode"), frame.x + 66, frame.y + 92)

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("main_menu.settings_mode_windowed"),
        x = mode_windowed_bounds.x,
        y = mode_windowed_bounds.y,
        width = mode_windowed_bounds.width,
        height = mode_windowed_bounds.height,
        hovered = state.hovered_settings_control == "settings_mode_windowed",
        enabled = true,
        variant = state.settings_window_mode == "windowed" and "primary" or "secondary",
        font_token = "Text",
        radius = 12,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("main_menu.settings_mode_fullscreen"),
        x = mode_fullscreen_bounds.x,
        y = mode_fullscreen_bounds.y,
        width = mode_fullscreen_bounds.width,
        height = mode_fullscreen_bounds.height,
        hovered = state.hovered_settings_control == "settings_mode_fullscreen",
        enabled = true,
        variant = state.settings_window_mode == "fullscreen" and "primary" or "secondary",
        font_token = "Text",
        radius = 12,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_resolution"), frame.x + 66, frame.y + 166)

    WoodButton.draw(self.fonts, self.style, {
        label = "<",
        x = resolution_bounds.prev.x,
        y = resolution_bounds.prev.y,
        width = resolution_bounds.prev.width,
        height = resolution_bounds.prev.height,
        hovered = state.hovered_settings_control == "settings_resolution_prev",
        enabled = resolution_enabled,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = resolution_label,
        x = resolution_bounds.value.x,
        y = resolution_bounds.value.y,
        width = resolution_bounds.value.width,
        height = resolution_bounds.value.height,
        hovered = false,
        enabled = resolution_enabled,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = ">",
        x = resolution_bounds.next.x,
        y = resolution_bounds.next.y,
        width = resolution_bounds.next.width,
        height = resolution_bounds.next.height,
        hovered = state.hovered_settings_control == "settings_resolution_next",
        enabled = resolution_enabled,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_language"), frame.x + 66, frame.y + 240)

    WoodButton.draw(self.fonts, self.style, {
        label = "<",
        x = language_bounds.prev.x,
        y = language_bounds.prev.y,
        width = language_bounds.prev.width,
        height = language_bounds.prev.height,
        hovered = state.hovered_settings_control == "settings_language_prev",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = language_label,
        locale = current_locale,
        x = language_bounds.value.x,
        y = language_bounds.value.y,
        width = language_bounds.value.width,
        height = language_bounds.value.height,
        hovered = false,
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = ">",
        x = language_bounds.next.x,
        y = language_bounds.next.y,
        width = language_bounds.next.width,
        height = language_bounds.next.height,
        hovered = state.hovered_settings_control == "settings_language_next",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_fps"), frame.x + 66, frame.y + 314)

    WoodButton.draw(self.fonts, self.style, {
        label = "<",
        x = fps_bounds.prev.x,
        y = fps_bounds.prev.y,
        width = fps_bounds.prev.width,
        height = fps_bounds.prev.height,
        hovered = state.hovered_settings_control == "settings_fps_prev",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = fps_label,
        x = fps_bounds.value.x,
        y = fps_bounds.value.y,
        width = fps_bounds.value.width,
        height = fps_bounds.value.height,
        hovered = false,
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = ">",
        x = fps_bounds.next.x,
        y = fps_bounds.next.y,
        width = fps_bounds.next.width,
        height = fps_bounds.next.height,
        hovered = state.hovered_settings_control == "settings_fps_next",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_game_volume"), frame.x + 66, frame.y + 388)

    WoodButton.draw(self.fonts, self.style, {
        label = "<",
        x = game_volume_bounds.prev.x,
        y = game_volume_bounds.prev.y,
        width = game_volume_bounds.prev.width,
        height = game_volume_bounds.prev.height,
        hovered = state.hovered_settings_control == "settings_game_volume_prev",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = game_volume_label,
        x = game_volume_bounds.value.x,
        y = game_volume_bounds.value.y,
        width = game_volume_bounds.value.width,
        height = game_volume_bounds.value.height,
        hovered = false,
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = ">",
        x = game_volume_bounds.next.x,
        y = game_volume_bounds.next.y,
        width = game_volume_bounds.next.width,
        height = game_volume_bounds.next.height,
        hovered = state.hovered_settings_control == "settings_game_volume_next",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("main_menu.settings_bgm_volume"), frame.x + 66, frame.y + 462)

    WoodButton.draw(self.fonts, self.style, {
        label = "<",
        x = bgm_volume_bounds.prev.x,
        y = bgm_volume_bounds.prev.y,
        width = bgm_volume_bounds.prev.width,
        height = bgm_volume_bounds.prev.height,
        hovered = state.hovered_settings_control == "settings_bgm_volume_prev",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = bgm_volume_label,
        x = bgm_volume_bounds.value.x,
        y = bgm_volume_bounds.value.y,
        width = bgm_volume_bounds.value.width,
        height = bgm_volume_bounds.value.height,
        hovered = false,
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = ">",
        x = bgm_volume_bounds.next.x,
        y = bgm_volume_bounds.next.y,
        width = bgm_volume_bounds.next.width,
        height = bgm_volume_bounds.next.height,
        hovered = state.hovered_settings_control == "settings_bgm_volume_next",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 10,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("main_menu.settings_reset_defaults"),
        x = reset_defaults_bounds.x,
        y = reset_defaults_bounds.y,
        width = reset_defaults_bounds.width,
        height = reset_defaults_bounds.height,
        hovered = state.hovered_settings_control == "settings_reset_defaults",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 12,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("main_menu.settings_exit_game"),
        x = exit_game_bounds.x,
        y = exit_game_bounds.y,
        width = exit_game_bounds.width,
        height = exit_game_bounds.height,
        hovered = state.hovered_settings_control == "settings_exit_game",
        enabled = true,
        variant = "secondary",
        font_token = "Text",
        radius = 12,
    })

    self.close_button:draw(self:getSettingsOverlayCloseBounds(), state.hovered_settings_control == "settings_close")
end

function MainMenuView:drawMuteIcon(state)
    local frame = self:getTopIconFrames().mute
    local muted = state and state.audio_mute_master == true

    self.mute_button:draw(frame, {
        muted = muted,
        hovered = state and state.hovered_mute_icon == true,
    })
end

function MainMenuView:drawWardrobeIcon(state)
    return nil
end

function MainMenuView:drawSettingsIcon(state)
    local frame = self:getTopIconFrames().settings

    self.settings_button:draw(frame, {
        hovered = state and state.hovered_settings_icon == true,
    })
end

function MainMenuView:draw(state, user_profile)
    self._last_user_profile = user_profile
    local colors = self.style.colors
    local layout = self.style.layout
    local panel = self:getMainPanelBounds(state)
    local profile_bounds = self:getProfileButtonBounds()

    local avatar_id = (user_profile or {}).avatar_id or "avatar_1"
    local avatar = self.avatars_by_id[avatar_id] or self.avatars_by_id["avatar_1"]
    local avatar_size = layout.profile_avatar_size or 96
    local avatar_x = profile_bounds.x
    local avatar_y = profile_bounds.y + math.floor((profile_bounds.h - avatar_size) / 2)
    local avatar_bounds = {
        x = avatar_x,
        y = avatar_y,
        w = avatar_size,
        h = avatar_size,
    }
    local avatar_center_x = avatar_x + avatar_size * 0.5
    local avatar_center_y = avatar_y + avatar_size * 0.5
    local frame_size = layout.profile_avatar_frame_size or math.floor(avatar_size * 0.78)
    local frame_radius = frame_size * 0.5
    local frame_shadow_offset = layout.profile_avatar_shadow_offset or 4

    love.graphics.setColor(colors.avatar_shadow[1], colors.avatar_shadow[2], colors.avatar_shadow[3], colors.avatar_shadow[4])
    love.graphics.circle("fill", avatar_center_x, avatar_center_y + frame_shadow_offset, frame_radius + 2)

    love.graphics.setColor(colors.avatar_fill[1], colors.avatar_fill[2], colors.avatar_fill[3], colors.avatar_fill[4])
    love.graphics.circle("fill", avatar_center_x, avatar_center_y, frame_radius)

    if avatar then
        love.graphics.stencil(function()
            love.graphics.circle("fill", avatar_center_x, avatar_center_y, avatar_size * 0.5)
        end, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        AvatarTile.drawArt(self.style, avatar, avatar_bounds, {
            content_padding_ratio = 0.05,
        })
        love.graphics.setStencilTest()
    end

    love.graphics.setLineWidth(4)
    love.graphics.setColor(colors.avatar_frame[1], colors.avatar_frame[2], colors.avatar_frame[3], colors.avatar_frame[4])
    love.graphics.circle("line", avatar_center_x, avatar_center_y, frame_radius - 1)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(colors.avatar_border[1], colors.avatar_border[2], colors.avatar_border[3], colors.avatar_border[4])
    love.graphics.circle("line", avatar_center_x, avatar_center_y, frame_radius - 4)
    love.graphics.setLineWidth(1)

    local name_font = self.fonts:get("Text")
    love.graphics.setFont(name_font)
    local nickname = tostring((user_profile or {}).nickname or "-")
    local plaque = resolveProfilePlaqueMetrics(layout, name_font, avatar_size, nickname)
    local plaque_gap = plaque.gap
    local plaque_x = avatar_x + avatar_size + plaque_gap
    local plaque_y = profile_bounds.y + math.floor((profile_bounds.h - plaque.h) / 2)
    local plaque_shadow = math.max(2, math.floor(plaque.h * 0.08))
    local plaque_radius = plaque.radius
    local tab_w = math.floor(plaque.h * 0.6)
    local tab_h = math.floor(plaque.h * 0.45)
    local tab_x = avatar_bounds.x + avatar_bounds.w - math.floor(tab_w * 0.35)
    local tab_y = plaque_y + math.floor((plaque.h - tab_h) * 0.5)

    love.graphics.setColor(0.44, 0.26, 0.13, state.hovered_profile == true and 0.24 or 0.18)
    love.graphics.rectangle("fill", plaque_x + 2, plaque_y + plaque_shadow, plaque.w, plaque.h, plaque_radius, plaque_radius)

    love.graphics.setColor(0.74, 0.48, 0.24, state.hovered_profile == true and 0.98 or 0.92)
    love.graphics.rectangle("fill", tab_x, tab_y, tab_w, tab_h, math.floor(tab_h * 0.45), math.floor(tab_h * 0.45))

    love.graphics.setColor(0.98, 0.92, 0.76, state.hovered_profile == true and 0.98 or 0.92)
    love.graphics.rectangle("fill", plaque_x, plaque_y, plaque.w, plaque.h, plaque_radius, plaque_radius)

    love.graphics.setColor(0.78, 0.55, 0.31, 0.42)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", plaque_x + 1, plaque_y + 1, plaque.w - 2, plaque.h - 2, plaque_radius, plaque_radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.66, 0.45, 0.24, 0.18)
    local grain_x = plaque_x + math.floor(plaque.padding * 0.8)
    local grain_w = plaque.w - math.floor(plaque.padding * 1.6)
    local grain_y1 = plaque_y + math.floor(plaque.h * 0.28)
    local grain_y2 = plaque_y + math.floor(plaque.h * 0.52)
    love.graphics.rectangle("fill", grain_x, grain_y1, grain_w, 2, 1, 1)
    love.graphics.rectangle("fill", grain_x, grain_y2, grain_w, 2, 1, 1)

    love.graphics.setColor(1.0, 0.97, 0.90, 0.84)
    local text_y = plaque_y + math.floor((plaque.h - name_font:getHeight()) * 0.5) - 1
    love.graphics.printf(
        nickname,
        plaque_x + plaque.padding,
        text_y + 2,
        plaque.w - plaque.padding * 2,
        "left"
    )
    love.graphics.printf(
        nickname,
        plaque_x + plaque.padding + 1,
        text_y + 2,
        plaque.w - plaque.padding * 2,
        "left"
    )

    ButtonText.draw(name_font, nickname, plaque_x + plaque.padding - 1, text_y, plaque.w - plaque.padding * 2, "left", { 0.42, 0.22, 0.10, 0.98 }, {
        bold = true,
        bold_offset = 1,
    })

    self:drawMuteIcon(state)
    self:drawSettingsIcon(state)

    self.wood_panel:draw({
        x = panel.x,
        y = panel.y,
        width = panel.w,
        height = panel.h,
    }, { radius = 18, shadow_offset = 6, inner_inset = 8, border_width = 2, inner_border_width = 1 })

    for _, button in ipairs(self:getButtons(state)) do
        WoodButton.draw(self.fonts, self.style, {
            label = button.label,
            x = button.x,
            y = button.y,
            width = button.width,
            height = button.height,
            hovered = button.hovered,
            enabled = button.enabled,
            variant = button.variant,
            font_token = "Button",
            radius = 12,
            shadow_offset = 5,
            inner_inset = 6,
        })
    end

    if state.rules_overlay_visible then
        self:drawRulesOverlay(state)
        if state.single_player_loading_visible or state.server_loading_visible then
            self:drawSinglePlayerLoadingOverlay(state)
        end
        return
    end

    if state.matchmaking_overlay_visible then
        self.matchmaking_overlay:draw(state)
        if state.single_player_loading_visible or state.server_loading_visible then
            self:drawSinglePlayerLoadingOverlay(state)
        end
        return
    end

    if state.mode_overlay_visible then
        self:drawModeOverlay(state)
        if state.single_player_loading_visible or state.server_loading_visible then
            self:drawSinglePlayerLoadingOverlay(state)
        end
        return
    end

    if state.settings_overlay_visible then
        self:drawSettingsOverlay(state)
        if state.confirm_dialog_visible then
            self.confirmation_dialog:draw({
                title = I18n:t("common.confirm"),
                message = I18n:t("common.confirm_exit_game"),
                cancel_label = I18n:t("common.cancel"),
                confirm_label = I18n:t("common.confirm"),
            }, self.window_width, self.window_height, state.hovered_confirm_dialog_control)
        end
    end

    if state.single_player_loading_visible or state.server_loading_visible then
        self:drawSinglePlayerLoadingOverlay(state)
    end
end

return MainMenuView
