local Controller = {}
Controller.__index = Controller
local I18n = require("src.core.i18n.i18n")
local Actions = require("src.features.gameplay.controllers.actions")
local Helpers = require("src.features.gameplay.controllers.helpers")
local InputRouter = require("src.features.gameplay.controllers.input_router")
local PresentationFlow = require("src.features.gameplay.controllers.presentation_flow")
local RealtimeHandler = require("src.features.gameplay.controllers.realtime_handler")
local SnapshotApplier = require("src.features.gameplay.controllers.snapshot_applier")
local BackgroundThemeCatalog = require("src.core.backgrounds.themes.background_theme_catalog")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")

local RESOLUTION_OPTIONS = {
    -- 720P
    { width = 1280, height = 720 },
    -- 900P
    { width = 1600, height = 900 },
    -- 1080P
    { width = 1920, height = 1080 },
}

local FPS_OPTIONS = { 30, 60, 90, 120, 144 }
local VOLUME_OPTIONS = {
    0.0, 0.05, 0.1, 0.15, 0.2,
    0.25, 0.3, 0.35, 0.4, 0.45,
    0.5, 0.55, 0.6, 0.65, 0.7,
    0.75, 0.8, 0.85, 0.9, 0.95, 1.0,
}

local BACKGROUND_THEME_OPTIONS = BackgroundThemeCatalog.OPTIONS
local GAME_BGM_OPTIONS = { "game_default", "bgm1", "bgm2", "bgm3", "bgm4", "bgm5" }
local SERVER_ACTION_LOADING_DELAY = 0.04
local GAME_SNAPSHOT_REQUEST_INTERVAL_SECONDS = 1.0
local GAME_SNAPSHOT_REQUEST_MAX_WAIT_SECONDS = 12.0
local REALTIME_SNAPSHOT_WATCHDOG_INTERVAL_SECONDS = 2.0
local BUTTON_PRESS_FEEDBACK_DURATION = 0.24
local BUTTON_ACTION_DELAY_SECONDS = 0.4

local function findLocaleIndex(locale_options, locale)
    local target = locale or I18n:getLocale()
    for index, item in ipairs(locale_options or {}) do
        if item == target then
            return index
        end
    end
    return 1
end

local function shouldWatchdogPollSnapshot(state)
    local ui_phase = tostring((state or {}).ui_phase or "")
    if ui_phase == "tribute"
        or ui_phase == "dealing"
        or ui_phase == "hand_loading"
        or ui_phase == "result_transition"
        or ui_phase == "remaining_cards"
        or ui_phase == "settlement"
        or ui_phase == "rematch"
    then
        return true
    end
    return (state or {}).action_waiting == true
end

local function findResolutionIndex(width, height)
    local target_w = tonumber(width) or 1600
    local target_h = tonumber(height) or 900

    for index, option in ipairs(RESOLUTION_OPTIONS) do
        if option.width == target_w and option.height == target_h then
            return index
        end
    end

    local best_index = 1
    local best_score = math.huge
    for index, option in ipairs(RESOLUTION_OPTIONS) do
        local diff_w = option.width - target_w
        local diff_h = option.height - target_h
        local score = diff_w * diff_w + diff_h * diff_h
        if score < best_score then
            best_score = score
            best_index = index
        end
    end

    return best_index
end

local function findFpsIndex(target_fps)
    local target = tonumber(target_fps) or 60
    for index, value in ipairs(FPS_OPTIONS) do
        if value == target then
            return index
        end
    end

    local best_index = 1
    local best_distance = math.huge
    for index, value in ipairs(FPS_OPTIONS) do
        local distance = math.abs(value - target)
        if distance < best_distance then
            best_distance = distance
            best_index = index
        end
    end

    return best_index
end

local function findVolumeIndex(volume)
    local target = tonumber(volume)
    if not target then
        target = 1.0
    end

    local best_index = 1
    local best_distance = math.huge
    for index, value in ipairs(VOLUME_OPTIONS) do
        local distance = math.abs(value - target)
        if distance < best_distance then
            best_distance = distance
            best_index = index
        end
    end

    return best_index
end

local function findBackgroundThemeIndex(theme_id)
    local normalized = BackgroundThemeCatalog.normalizeThemeId(theme_id)
    for index, value in ipairs(BACKGROUND_THEME_OPTIONS) do
        if value == normalized then
            return index
        end
    end
    return 1
end

local function findOptionIndex(options, current_value, default_index)
    for index, value in ipairs(options or {}) do
        if value == current_value then
            return index
        end
    end
    return default_index or 1
end

local function tickButtonPressFeedback(state, dt)
    local feedback = state and state.button_press_feedback
    if type(feedback) ~= "table" then
        return
    end
    local delta = tonumber(dt) or 0
    if delta <= 0 then
        return
    end
    local decay = delta / BUTTON_PRESS_FEEDBACK_DURATION
    for key, value in pairs(feedback) do
        feedback[key] = math.max(0, (tonumber(value) or 0) - decay)
    end
end

local function shouldAutoPassForInsufficientHand(state)
    if type(state) ~= "table" or state.ui_phase ~= "playing" then
        return false
    end
    if state.action_waiting or state.server_loading_visible then
        return false
    end
    if not Helpers.isMyTurn(state) or Helpers.hasPlayControl(state) then
        return false
    end

    local hand_cards = ((state.game or {}).my_hand_cards) or {}
    local last_play_cards = ((state.last_play or {}).cards) or {}
    if #last_play_cards == 0 then
        return false
    end

    return #hand_cards < #last_play_cards
end

local function syncPendingTurnCountdown(state, dt)
    if type(state) ~= "table" then
        return
    end
    if tostring(((state.game or {}).phase) or "") ~= "playing" then
        return
    end
    if tostring(state.ui_phase or "") ~= "playing" then
        return
    end

    local pending_remaining = tonumber(state.turn_countdown_pending_remaining) or 0
    local pending_duration = tonumber(state.turn_countdown_pending_duration) or 0
    if pending_remaining <= 0 then
        return
    end

    local delta = tonumber(dt) or 0
    if delta > 0 then
        state.turn_countdown_pending_remaining = math.max(0, pending_remaining - delta)
        pending_remaining = tonumber(state.turn_countdown_pending_remaining) or 0
    end

    if (tonumber(state.arrange_remaining) or 0) > 0 then
        return
    end

    if (tonumber(state.turn_countdown_remaining) or 0) > 0 then
        state.turn_countdown_pending_remaining = 0
        state.turn_countdown_pending_duration = 0
        state.arrange_hold_visible = false
        return
    end

    state.turn_countdown_remaining = pending_remaining
    state.turn_countdown_duration = math.max(pending_duration, pending_remaining)
    state.turn_countdown_pending_remaining = 0
    state.turn_countdown_pending_duration = 0
    state.arrange_hold_visible = false
    return true
end

local function syncArrangeProgressRequest(controller, dt)
    local state = controller.state
    if type(state) ~= "table" then
        return
    end

    if state.loading or state.fatal_error_message ~= "" then
        state.arrange_progress_request_active = false
        return
    end

    if tostring(((state.game or {}).phase) or "") ~= "playing" or tostring(state.ui_phase or "") ~= "playing" then
        state.arrange_progress_request_active = false
        return
    end

    local arrange_remaining = tonumber(state.arrange_remaining) or 0
    if arrange_remaining > 0 then
        state.arrange_progress_request_active = false
        return
    end

    if state.arrange_zero_hold ~= true then
        state.arrange_zero_hold = true
    end

    if (tonumber(state.turn_countdown_remaining) or 0) > 0 then
        state.arrange_progress_request_active = false
        return
    end

    if not state.arrange_hold_visible then
        state.arrange_progress_request_active = false
        return
    end

    if not state.arrange_progress_request_active then
        state.arrange_progress_request_active = true
        controller:requestGameSnapshot()
    end
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "GameplayController requires state")
    self.service = assert(options and options.service, "GameplayController requires service")
    self.get_current_settings = assert(options and options.get_current_settings, "GameplayController requires get_current_settings")
    self.on_change_window_mode = assert(options and options.on_change_window_mode, "GameplayController requires on_change_window_mode")
    self.on_change_resolution = assert(options and options.on_change_resolution, "GameplayController requires on_change_resolution")
    self.on_change_language = assert(options and options.on_change_language, "GameplayController requires on_change_language")
    self.on_change_target_fps = assert(options and options.on_change_target_fps, "GameplayController requires on_change_target_fps")
    self.on_change_game_volume = assert(options and options.on_change_game_volume, "GameplayController requires on_change_game_volume")
    self.on_change_bgm_volume = assert(options and options.on_change_bgm_volume, "GameplayController requires on_change_bgm_volume")
    self.on_change_game_bgm = assert(options and options.on_change_game_bgm, "GameplayController requires on_change_game_bgm")
    self.on_toggle_mute = assert(options and options.on_toggle_mute, "GameplayController requires on_toggle_mute")
    self.on_reset_settings = assert(options and options.on_reset_settings, "GameplayController requires on_reset_settings")
    self.on_get_background_theme = assert(options and options.on_get_background_theme, "GameplayController requires on_get_background_theme")
    self.on_set_background_theme = assert(options and options.on_set_background_theme, "GameplayController requires on_set_background_theme")
    self.on_regenerate_background_theme = assert(options and options.on_regenerate_background_theme, "GameplayController requires on_regenerate_background_theme")
    self.on_change_card_high_contrast = assert(options and options.on_change_card_high_contrast, "GameplayController requires on_change_card_high_contrast")
    self.on_change_card_theme = assert(options and options.on_change_card_theme, "GameplayController requires on_change_card_theme")
    self.on_change_card_back = assert(options and options.on_change_card_back, "GameplayController requires on_change_card_back")
    self.on_sync_card_settings = options and options.on_sync_card_settings or nil
    self.on_play_sfx = options and options.on_play_sfx or nil
    self.on_get_sfx_duration = options and options.on_get_sfx_duration or nil
    self.on_start_looped_sfx = options and options.on_start_looped_sfx or nil
    self.on_stop_looped_sfx = options and options.on_stop_looped_sfx or nil
    self.on_back_to_main_menu = options and options.on_back_to_main_menu or nil
    self.on_exit_game = options and options.on_exit_game or nil
    self.initial_game = options and options.initial_game or nil
    self.dealing_sfx_active = false
    self.turn_timer_sfx_active = false
    self.left_room_handled = false

    self.state.settings_resolution_options = RESOLUTION_OPTIONS
    self.state.settings_fps_options = FPS_OPTIONS
    self.state.settings_volume_options = VOLUME_OPTIONS
    self.state.settings_game_bgm_options = GAME_BGM_OPTIONS
    self.state.server_loading_visible = false
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = nil
    self:syncAudioState()
    self:syncSettingsState()
    self:syncBackgroundThemeState()
    self:syncCardThemeFromPreferences()
    self:syncCardThemeState()

    if self.initial_game then
        self.state.loading = false
        self.state.fatal_error_message = ""
        self.state.status_message = ""
        self.state.game = SnapshotApplier.prepareSnapshot(self.state, self.initial_game)
        self.state.last_play = Helpers.buildLastPlayViewModel(self.state.game)
        SnapshotApplier.seedPlayHistory(self.state, self.state.game)
        PresentationFlow.beginHandPresentation(self.state)
    else
        self.state.loading = true
        self.state.fatal_error_message = ""
        self.state.status_message = I18n:t("gameplay.loading_status")
        self.state.game_snapshot_request_elapsed = 0
        self.state.game_snapshot_request_attempts = 0
    end
    self.service:connectGameChannel(self.state.room_id, self.state.steam_id)
    if not self.initial_game then
        self:requestGameSnapshot()
    end

    return self
end

function Controller:requestGameSnapshot()
    if self.left_room_handled == true then
        return
    end
    if tostring((self.state or {}).room_id or "") == "" then
        return
    end
    self.service:requestGameSnapshot()
    self.state.game_snapshot_request_attempts = (tonumber(self.state.game_snapshot_request_attempts) or 0) + 1
end

function Controller:beginServerLoading(action_fn)
    if self.state.server_loading_visible then
        return false
    end
    self.state.server_loading_visible = true
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = action_fn
    self.state.server_loading_message = nil
    self.state.hovered_settings_control = nil
    self.state.hovered_settings_button = false
    return true
end

function Controller:finishServerLoading()
    self.state.server_loading_visible = false
    self.state.server_loading_message = nil
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = nil
end

function Controller:syncAudioState()
    local settings = self.get_current_settings() or {}
    self.state.audio_mute_master = settings.audio_mute_master == true
end

function Controller:syncSettingsState()
    local settings = self.get_current_settings() or {}
    local locale_options = I18n:getOrderedLocales()
    self.state.settings_window_mode = settings.window_mode == "fullscreen" and "fullscreen" or "windowed"
    self.state.settings_language_options = locale_options
    self.state.settings_language_index = findLocaleIndex(locale_options, settings.language)
    self.state.settings_resolution_index = findResolutionIndex(settings.window_width, settings.window_height)
    self.state.settings_fps_index = findFpsIndex(settings.target_fps)
    self.state.settings_game_volume_index = findVolumeIndex(settings.audio_sfx_volume)
    self.state.settings_bgm_volume_index = findVolumeIndex(settings.audio_bgm_volume)
    self.state.settings_game_bgm_index = findOptionIndex(self.state.settings_game_bgm_options, settings.preferred_game_bgm_id or "game_default", 1)
end

function Controller:syncBackgroundThemeState()
    local theme_id = BackgroundThemeCatalog.normalizeThemeId(self.on_get_background_theme())
    self.state.settings_background_theme_options = BACKGROUND_THEME_OPTIONS
    self.state.settings_background_theme_id = theme_id
    self.state.settings_background_theme_index = findBackgroundThemeIndex(theme_id)
end

function Controller:syncCardThemeFromPreferences()
    local settings = self.get_current_settings() or {}
    self.state.card_theme_config = self.state.card_theme_config or {}
    self.state.card_theme_config.high_contrast = settings.cards_high_contrast == true
end

function Controller:syncCardThemeState()
    local card_config = self.state.card_theme_config or {}
    local theme_options = self.state.settings_card_theme_options or {}
    local back_options = self.state.settings_card_back_options or {}
    self.state.settings_card_theme_index = findOptionIndex(
        theme_options,
        ThemeCatalog.normalizeThemeId(card_config.theme_id),
        1
    )
    self.state.settings_card_back_index = findOptionIndex(back_options, card_config.back_id or "classic_grid", 1)
end

function Controller:openSettingsOverlay()
    self:syncAudioState()
    self:syncSettingsState()
    self:syncBackgroundThemeState()
    self:syncCardThemeFromPreferences()
    self:syncCardThemeState()
    self.state.settings_overlay_visible = true
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
    self.state.settings_background_preview_theme_id = nil
    self.state.settings_background_preview_seed = nil
    self.state.hovered_settings_control = nil
    self.state.hovered_settings_button = false
end

function Controller:closeSettingsOverlay()
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
    self.state.settings_background_preview_theme_id = nil
    self.state.settings_background_preview_seed = nil
    if self.state.card_settings_dirty
        and self.on_sync_card_settings
        and type(self.on_sync_card_settings) == "function"
    then
        self:beginServerLoading(function()
            local ok = self.on_sync_card_settings()
            if ok == false then
                Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
                return
            end
            self.state.card_settings_dirty = false
            self.state.settings_overlay_visible = false
            self.state.hovered_settings_control = nil
            self.state.hovered_settings_button = false
            self.state.hovered_confirm_dialog_control = nil
        end)
        self.state.server_loading_message = I18n:t("common.save") .. " " .. I18n:t("gameplay.settings_title")
        return
    end

    self.state.settings_overlay_visible = false
    self.state.settings_background_preview_theme_id = nil
    self.state.settings_background_preview_seed = nil
    self.state.hovered_settings_control = nil
    self.state.hovered_settings_button = false
end

function Controller:openConfirmDialog(action_id)
    if action_id ~= "back_to_main_menu" and action_id ~= "exit_game" then
        return
    end
    self.state.confirm_dialog_visible = true
    self.state.confirm_dialog_action = action_id
    self.state.hovered_confirm_dialog_control = nil
    self.state.hovered_settings_control = nil
    self.state.hovered_settings_button = false
end

function Controller:closeConfirmDialog()
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
end

function Controller:confirmDialogAction()
    local action_id = self.state.confirm_dialog_action
    self:closeConfirmDialog()
    if action_id == "back_to_main_menu" then
        self:leaveToMainMenu()
        return
    end
    if action_id == "exit_game" then
        self:exitGame()
    end
end

function Controller:openPlayerProfile(role_key)
    local game = self.state.game or {}
    local my_seat_index = tonumber(game.my_seat_index) or 0
    for _, player in ipairs(game.players or {}) do
        local role = Helpers.getRelativePositionKey(my_seat_index, tonumber(player.seat_index) or 0)
        if role == role_key then
            self.state.profile_overlay_player = player
            self.state.show_player_profile_overlay = true
            self.state.hovered_player_profile_control = nil
            return
        end
    end
end

function Controller:closePlayerProfile()
    self.state.show_player_profile_overlay = false
    self.state.hovered_player_profile_control = nil
    self.state.profile_overlay_player = nil
end

function Controller:setSettingsTab(tab_id)
    if tab_id ~= "display_audio" and tab_id ~= "background" and tab_id ~= "cards" then
        return
    end
    self.state.settings_tab = tab_id
end

function Controller:setWindowMode(mode)
    if mode ~= "windowed" and mode ~= "fullscreen" then
        return
    end
    if self.state.settings_window_mode == mode then
        return
    end

    local ok = self.on_change_window_mode(mode)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_window_mode = mode
end

function Controller:changeResolution(delta)
    if self.state.settings_window_mode == "fullscreen" then
        return
    end

    local options = self.state.settings_resolution_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_resolution_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local option = options[next_index]
    local ok = self.on_change_resolution(option.width, option.height)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_resolution_index = next_index
end

function Controller:changeLanguage(delta)
    local options = self.state.settings_language_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_language_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local locale = options[next_index]
    local ok = self.on_change_language(locale)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end

    self.state.settings_language_index = next_index
    SnapshotApplier.refreshLocalizedPresentation(self.state)
end

function Controller:changeTargetFps(delta)
    local options = self.state.settings_fps_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_fps_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local target_fps = options[next_index]
    local ok = self.on_change_target_fps(target_fps)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_fps_index = next_index
end

function Controller:changeGameVolume(delta)
    local options = self.state.settings_volume_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_game_volume_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local volume = options[next_index]
    local ok = self.on_change_game_volume(volume)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_game_volume_index = next_index
end

function Controller:changeBgmVolume(delta)
    local options = self.state.settings_volume_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_bgm_volume_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local volume = options[next_index]
    local ok = self.on_change_bgm_volume(volume)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_bgm_volume_index = next_index
end

function Controller:changeGameBgm(delta)
    local options = self.state.settings_game_bgm_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_game_bgm_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local bgm_id = options[next_index]
    local ok = self.on_change_game_bgm(bgm_id)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncSettingsState()
        return
    end
    self.state.settings_game_bgm_index = next_index
end

function Controller:toggleMute()
    local next_mute = self.on_toggle_mute()
    if type(next_mute) == "boolean" then
        self.state.audio_mute_master = next_mute
    else
        self:syncAudioState()
    end
end

function Controller:resetSettings()
    local ok = self.on_reset_settings()
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        return
    end
    self:syncAudioState()
    self:syncSettingsState()
    self:syncBackgroundThemeState()
    self:syncCardThemeFromPreferences()
    self:syncCardThemeState()
end

function Controller:setBackgroundTheme(theme_id)
    local ok = self.on_set_background_theme(theme_id)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        return
    end
    self:syncBackgroundThemeState()
end

function Controller:regenerateBackgroundTheme()
    local ok = self.on_regenerate_background_theme()
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
    end
end

function Controller:toggleCardHighContrast()
    local next_value = not (self.state.card_theme_config.high_contrast == true)
    local ok = self.on_change_card_high_contrast(next_value)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncCardThemeFromPreferences()
        return
    end
    self.state.card_theme_config.high_contrast = next_value
end

function Controller:cycleCardTheme(delta)
    local options = self.state.settings_card_theme_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_card_theme_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end
    local next_theme_id = options[next_index]
    local ok = self.on_change_card_theme(next_theme_id)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncCardThemeState()
        return
    end
    self.state.settings_card_theme_index = next_index
    self.state.card_theme_config.theme_id = next_theme_id
    self.state.card_settings_dirty = true
end

function Controller:cycleCardBack(delta)
    local options = self.state.settings_card_back_options or {}
    local total = #options
    if total <= 0 then
        return
    end
    local next_index = self.state.settings_card_back_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end
    local next_back_id = options[next_index]
    local ok = self.on_change_card_back(next_back_id)
    if ok == false then
        Actions.showToast(self, I18n:t("gameplay.settings_apply_failed"))
        self:syncCardThemeState()
        return
    end
    self.state.settings_card_back_index = next_index
    self.state.card_theme_config.back_id = next_back_id
    self.state.card_settings_dirty = true
end

function Controller:showToast(message)
    Actions.showToast(self, message)
end

function Controller:playSfx(sfx_id)
    if not self.on_play_sfx or type(self.on_play_sfx) ~= "function" then
        return false
    end
    return self.on_play_sfx(sfx_id) == true
end

function Controller:startHandCountAlert(seat_index)
    local seat = tonumber(seat_index)
    if seat == nil then
        return false
    end
    self.state.hand_count_alerts = self.state.hand_count_alerts or {}
    self.state.hand_count_alerts[seat] = {
        remaining = 0.82,
        duration = 0.82,
    }
    return true
end

function Controller:getSfxDuration(sfx_id)
    if not self.on_get_sfx_duration or type(self.on_get_sfx_duration) ~= "function" then
        return nil
    end
    local duration = self.on_get_sfx_duration(sfx_id)
    if type(duration) ~= "number" or duration <= 0 then
        return nil
    end
    return duration
end

function Controller:startLoopedSfx(sfx_id, options)
    if not self.on_start_looped_sfx or type(self.on_start_looped_sfx) ~= "function" then
        return false
    end
    return self.on_start_looped_sfx(sfx_id, options) == true
end

function Controller:stopLoopedSfx(sfx_id)
    if not self.on_stop_looped_sfx or type(self.on_stop_looped_sfx) ~= "function" then
        return false
    end
    return self.on_stop_looped_sfx(sfx_id) == true
end

function Controller:stopTransientLoopedSfx()
    if self.dealing_sfx_active then
        self:stopLoopedSfx("dealing")
        self.dealing_sfx_active = false
    end
    if self.turn_timer_sfx_active then
        self:stopLoopedSfx("turn_timer")
        self.turn_timer_sfx_active = false
    end
end

function Controller:clearGameplaySessionState()
    local state = self.state

    self:stopTransientLoopedSfx()

    state.loading = false
    state.fatal_error_message = ""
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0
    state.status_message = ""
    state.game = nil
    state.ui_phase = "loading"
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.tribute_countdown_remaining = 0
    state.tribute_countdown_duration = 0
    state.tribute_force_visible = false
    state.tribute_overlay_snapshot = nil
    state.turn_countdown_remaining = 0
    state.turn_countdown_duration = 0
    state.turn_countdown_pending_remaining = 0
    state.turn_countdown_pending_duration = 0
    state.arrange_hold_visible = false
    state.arrange_zero_hold = false
    state.arrange_progress_request_active = false
    state.arrange_progress_request_elapsed = 0
    state.wildcard_overlay_remaining = 0
    state.deal_overlay_remaining = 0
    state.deal_overlay_duration = 0
    state.deal_sfx_start_remaining = 0
    state.hand_loading_remaining = 0
    state.hand_loading_duration = 0
    state.arrange_remaining = 0
    state.arrange_duration = 0
    state.reveal_cards = false
    state.selected_card_ids = {}
    state.pinned_card_ids = {}
    state.pinned_card_groups = {}
    state.hovered_card_id = nil
    state.hovered_control = nil
    state.selected_tribute_card_id = nil
    state.hovered_tribute_card_id = nil
    state.hovered_tribute_control = nil
    state.show_round_info_overlay = false
    state.round_info_active_tab = "history"
    state.hovered_round_info_button = false
    state.hovered_round_info_overlay_control = nil
    state.hand_history_scroll = 0
    state.play_history_hand_no = nil
    state.hovered_debug_button = false
    state.hovered_settings_button = false
    state.hovered_settings_control = nil
    state.hovered_player_hud_role = nil
    state.show_player_profile_overlay = false
    state.hovered_player_profile_control = nil
    state.profile_overlay_player = nil
    state.pass_markers = {}
    state.realtime_status = "disconnected"
    state.realtime_hint_message = ""
    state.realtime_last_bridge_error_signature = ""
    state.game_snapshot_request_elapsed = 0
    state.game_snapshot_request_attempts = 0
    state.realtime_snapshot_watchdog_elapsed = 0
    state.action_waiting = false
    state.suppress_next_pass_sfx = false
    state.last_play = nil
    state.settlement_countdown_remaining = 0
    state.settlement_countdown_duration = 0
    state.result_transition_remaining = 0
    state.result_transition_duration = 0
    state.remaining_cards_reveal_remaining = 0
    state.remaining_cards_reveal_duration = 0
    state.remaining_cards_intro_remaining = 0
    state.remaining_cards_intro_duration = 0
    state.remaining_cards_countdown_remaining = 0
    state.remaining_cards_countdown_duration = 0
    state.result_revealed_hands = nil
    state.remaining_cards_button_hovered = false
    state.hand_count_alerts = {}
    state.settlement_button_hovered = false
    state.rematch_confirm_button_hovered = false
    state.rematch_leave_button_hovered = false
    state.pending_button_action = nil
    state.pending_button_action_timer = 0
    state.pending_button_action_progress = 0
    state.confirm_dialog_visible = false
    state.confirm_dialog_action = nil
    state.hovered_confirm_dialog_control = nil
    state.server_loading_visible = false
    state.server_loading_message = nil
    state.server_loading_elapsed = 0
    state.server_loading_request_started = false
    state.pending_server_action = nil
end

function Controller:syncDealingLoopedSfx()
    local should_play = self.state.ui_phase == "dealing"
        and self.state.deal_overlay_remaining > 0
        and self.state.deal_overlay_remaining <= math.max(tonumber(self.state.deal_sfx_start_remaining) or 0, 0)
        and not self.state.server_loading_visible
        and not self.state.loading
        and self.state.fatal_error_message == ""

    if should_play and not self.dealing_sfx_active then
        self:startLoopedSfx("dealing", { pitch = 3, gain = 4.0 })
        self.dealing_sfx_active = true
        return
    end

    if (not should_play) and self.dealing_sfx_active then
        self:stopLoopedSfx("dealing")
        self.dealing_sfx_active = false
    end
end

function Controller:syncTurnCountdown(dt)
    local game = self.state.game or {}
    if tostring(game.phase or "") ~= "playing" then
        return
    end
    if (tonumber(self.state.turn_countdown_remaining) or 0) <= 0 then
        self.state.turn_countdown_remaining = 0
        return
    end
    self.state.turn_countdown_remaining = math.max(0, self.state.turn_countdown_remaining - dt)
end

function Controller:syncTurnTimerLoopedSfx()
    local should_play = self.state.ui_phase == "playing"
        and (tonumber(self.state.turn_countdown_duration) or 0) > 0
        and (tonumber(self.state.turn_countdown_remaining) or 0) > 0
        and (tonumber(self.state.turn_countdown_remaining) or 0) <= 5
        and not self.state.server_loading_visible
        and not self.state.loading
        and self.state.fatal_error_message == ""

    if should_play and not self.turn_timer_sfx_active then
        self:startLoopedSfx("turn_timer", { gain = 0.95 })
        self.turn_timer_sfx_active = true
        return
    end

    if (not should_play) and self.turn_timer_sfx_active then
        self:stopLoopedSfx("turn_timer")
        self.turn_timer_sfx_active = false
    end
end

function Controller:syncHandCountAlerts(dt)
    local alerts = self.state.hand_count_alerts or {}
    for seat_index, alert in pairs(alerts) do
        local next_remaining = math.max(0, tonumber(alert.remaining or 0) - dt)
        if next_remaining <= 0 then
            alerts[seat_index] = nil
        else
            alert.remaining = next_remaining
        end
    end
end

function Controller:loadGame()
    Actions.loadGame(self)
end

function Controller:applyGameSnapshot(snapshot)
    SnapshotApplier.apply(self, snapshot)
end

function Controller:startNextHand()
    Actions.startNextHand(self)
end

function Controller:skipRemainingCardsView()
    Actions.skipRemainingCardsView(self)
end

function Controller:confirmRematch()
    Actions.confirmRematch(self)
end

function Controller:leaveToMainMenu()
    self:closeConfirmDialog()
    self:stopTransientLoopedSfx()
    self:beginServerLoading(function()
        Actions.leaveToMainMenu(self)
    end)
end

function Controller:exitGame()
    self:closeConfirmDialog()
    if self.on_exit_game and type(self.on_exit_game) == "function" then
        self.on_exit_game()
        return
    end
    if love and love.event and love.event.quit then
        love.event.quit()
    end
end

function Controller:debugAutoplayHand()
    Actions.debugAutoplayHand(self)
end

function Controller:isMyTurn()
    return Helpers.isMyTurn(self.state)
end

function Controller:hasPlayControl()
    return Helpers.hasPlayControl(self.state)
end

function Controller:playSelectedCards()
    Actions.playSelectedCards(self)
end

function Controller:passTurn()
    Actions.passTurn(self)
end

function Controller:triggerButtonPressFeedback(control_id)
    local feedback = self.state and self.state.button_press_feedback
    if type(feedback) ~= "table" then
        return
    end
    if feedback[control_id] == nil then
        return
    end
    feedback[control_id] = 1
end

function Controller:queueButtonAction(control_id)
    if control_id ~= "play_cards" and control_id ~= "pass_turn" then
        return false
    end
    if self.state.pending_button_action ~= nil then
        return false
    end
    self.state.pending_button_action = control_id
    self.state.pending_button_action_timer = BUTTON_ACTION_DELAY_SECONDS
    self.state.pending_button_action_progress = 0
    return true
end

function Controller:flushQueuedButtonAction()
    self.state.pending_button_action = nil
    self.state.pending_button_action_timer = 0
    self.state.pending_button_action_progress = 0
end

function Controller:submitTributeCard()
    Actions.submitTributeCard(self)
end

function Controller:handleRealtimePacket(packet)
    RealtimeHandler.handle(self, packet)
end

function Controller:update(dt)
    tickButtonPressFeedback(self.state, dt)
    if self.left_room_handled == true then
        return
    end
    if self.state.pending_button_action then
        self.state.pending_button_action_timer = math.max(0, (tonumber(self.state.pending_button_action_timer) or 0) - (tonumber(dt) or 0))
        local remain = tonumber(self.state.pending_button_action_timer) or 0
        self.state.pending_button_action_progress = math.max(0, math.min(1, 1 - (remain / BUTTON_ACTION_DELAY_SECONDS)))
        if self.state.pending_button_action_timer <= 0 then
            self:flushQueuedButtonAction()
        end
    else
        self.state.pending_button_action_progress = 0
    end

    if self.state.server_loading_visible then
        self.state.server_loading_elapsed = (tonumber(self.state.server_loading_elapsed) or 0) + (tonumber(dt) or 0)
        if not self.state.server_loading_request_started
            and self.state.server_loading_elapsed >= SERVER_ACTION_LOADING_DELAY
        then
            self.state.server_loading_request_started = true
            local action_fn = self.state.pending_server_action
            if action_fn then
                action_fn()
            end
            self:finishServerLoading()
            if self.left_room_handled == true then
                return
            end
        end
    end

    local packets = self.service:pollGameChannel()
    for _, packet in ipairs(packets) do
        self:handleRealtimePacket(packet)
        if self.left_room_handled == true then
            return
        end
    end

    if not self.state.loading and self.state.fatal_error_message == "" then
        if self.state.realtime_status == "connected" and shouldWatchdogPollSnapshot(self.state) then
            self.state.realtime_snapshot_watchdog_elapsed = (tonumber(self.state.realtime_snapshot_watchdog_elapsed) or 0) + (tonumber(dt) or 0)
            if (tonumber(self.state.realtime_snapshot_watchdog_elapsed) or 0) >= REALTIME_SNAPSHOT_WATCHDOG_INTERVAL_SECONDS then
                self.state.realtime_snapshot_watchdog_elapsed = 0
                self:requestGameSnapshot()
            end
        else
            self.state.realtime_snapshot_watchdog_elapsed = 0
        end
    end

    if self.state.loading and self.state.fatal_error_message == "" then
        self.state.game_snapshot_request_elapsed = (tonumber(self.state.game_snapshot_request_elapsed) or 0) + (tonumber(dt) or 0)
        local elapsed = tonumber(self.state.game_snapshot_request_elapsed) or 0
        if self.state.realtime_status == "connected"
            and elapsed >= GAME_SNAPSHOT_REQUEST_INTERVAL_SECONDS
        then
            self.state.game_snapshot_request_elapsed = 0
            self:requestGameSnapshot()
        end

        local waited = (tonumber(self.state.game_snapshot_request_attempts) or 0) * GAME_SNAPSHOT_REQUEST_INTERVAL_SECONDS + elapsed
        if waited >= GAME_SNAPSHOT_REQUEST_MAX_WAIT_SECONDS then
            self.state.loading = false
            self.state.fatal_error_message = I18n:t("gameplay.realtime_failed")
            self.state.status_message = ""
        end
    end

    if (tonumber(self.state.result_transition_remaining) or 0) > 0 then
        self.state.result_transition_remaining = math.max(
            0,
            (tonumber(self.state.result_transition_remaining) or 0) - (tonumber(dt) or 0)
        )
        if (tonumber(self.state.result_transition_remaining) or 0) <= 0 then
            self.state.result_transition_remaining = 0
            self.state.result_transition_duration = 0
            if type(self.state.game) == "table" and next(self.state.game) ~= nil then
                SnapshotApplier.apply(self, self.state.game)
            end
        end
    end

    self:syncDealingLoopedSfx()
    self:syncTurnTimerLoopedSfx()
    if self.state.loading or self.state.fatal_error_message ~= "" then
        return
    end
    PresentationFlow.update(self, dt)
    local promoted_turn_countdown = syncPendingTurnCountdown(self.state, dt) == true
    syncArrangeProgressRequest(self, dt)
    if shouldAutoPassForInsufficientHand(self.state) then
        print(string.format(
            "[gameplay] auto pass triggered hand_count=%d last_play_count=%d",
            #((((self.state or {}).game or {}).my_hand_cards) or {}),
            #((((self.state or {}).last_play or {}).cards) or {})
        ))
        self:passTurn()
    end
    self:syncHandCountAlerts(dt)
    if not promoted_turn_countdown then
        self:syncTurnCountdown(dt)
    end
    self:syncDealingLoopedSfx()
    self:syncTurnTimerLoopedSfx()
end

function Controller:mousemoved(x, y, view)
    InputRouter.mousemoved(self, x, y, view)
end

function Controller:mousepressed(x, y, button, view)
    return InputRouter.mousepressed(self, x, y, button, view)
end

function Controller:mousereleased(x, y, button, view)
    return InputRouter.mousereleased(self, x, y, button, view)
end

function Controller:keypressed(key)
    InputRouter.keypressed(self, key)
end

function Controller:wheelmoved(x, y, view)
    return InputRouter.wheelmoved(self, x, y, view)
end

function Controller:shutdown()
    self:clearGameplaySessionState()
    self.service:disconnectGameChannel(true)
end

function Controller:handleLeftRoom()
    if self.left_room_handled == true then
        print(string.format(
            "[gameplay] handleLeftRoom skipped duplicate room_id=%s steam_id=%s",
            tostring(self.state and self.state.room_id),
            tostring(self.state and self.state.steam_id)
        ))
        return
    end

    self.left_room_handled = true
    self:clearGameplaySessionState()
    self.service:disconnectGameChannel(true)
    print(string.format(
        "[gameplay] handleLeftRoom room_id=%s steam_id=%s",
        tostring(self.state and self.state.room_id),
        tostring(self.state and self.state.steam_id)
    ))
    if self.on_back_to_main_menu then
        self.on_back_to_main_menu()
    end
end

return Controller
