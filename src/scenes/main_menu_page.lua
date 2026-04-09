local Controller = require("src.features.main_menu.controller")
local MainMenuService = require("src.features.main_menu.service")
local SessionService = require("src.features.session.service")
local Style = require("src.features.main_menu.style")
local MainMenuView = require("src.features.main_menu.views.main_menu_view")
local HttpClient = require("src.infra.network.http_client")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")

local MainMenuPage = {}
MainMenuPage.__index = MainMenuPage

local function buildCardThemeConfig(user_profile)
    local settings = (user_profile and user_profile.card_settings) or {}
    return {
        theme_id = ThemeCatalog.normalizeThemeId(settings.theme_id),
        high_contrast = settings.high_contrast == true,
        back_id = settings.back_id or "classic_grid",
    }
end

function MainMenuPage.new(options)
    local self = setmetatable({}, MainMenuPage)

    local fonts = assert(options and options.fonts, "MainMenuPage requires fonts")
    local on_open_lobby = assert(options and options.on_open_lobby, "MainMenuPage requires on_open_lobby")
    local on_open_single_player_game = assert(options and options.on_open_single_player_game, "MainMenuPage requires on_open_single_player_game")
    local on_open_matchmaking_game = assert(options and options.on_open_matchmaking_game, "MainMenuPage requires on_open_matchmaking_game")
    local on_toggle_matchmaking = assert(options and options.on_toggle_matchmaking, "MainMenuPage requires on_toggle_matchmaking")
    local on_open_profile_editor = assert(options and options.on_open_profile_editor, "MainMenuPage requires on_open_profile_editor")
    local on_change_window_mode = assert(options and options.on_change_window_mode, "MainMenuPage requires on_change_window_mode")
    local on_change_resolution = assert(options and options.on_change_resolution, "MainMenuPage requires on_change_resolution")
    local on_change_language = assert(options and options.on_change_language, "MainMenuPage requires on_change_language")
    local on_change_target_fps = assert(options and options.on_change_target_fps, "MainMenuPage requires on_change_target_fps")
    local on_change_game_volume = assert(options and options.on_change_game_volume, "MainMenuPage requires on_change_game_volume")
    local on_change_bgm_volume = assert(options and options.on_change_bgm_volume, "MainMenuPage requires on_change_bgm_volume")
    local on_reset_settings = assert(options and options.on_reset_settings, "MainMenuPage requires on_reset_settings")
    local on_exit_game = assert(options and options.on_exit_game, "MainMenuPage requires on_exit_game")
    local on_toggle_mute = assert(options and options.on_toggle_mute, "MainMenuPage requires on_toggle_mute")
    local get_current_settings = assert(options and options.get_current_settings, "MainMenuPage requires get_current_settings")
    self.get_matchmaking_state = assert(options and options.get_matchmaking_state, "MainMenuPage requires get_matchmaking_state")

    self.user_profile = (options and options.user_profile) or {}
    self.backgrounds = options and options.backgrounds or nil
    local initial_settings = (options and options.settings) or {}
    self.state = {
        hovered_action = nil,
        status_message = "",
        submitting = false,
        rules_overlay_visible = false,
        hovered_rules_control = nil,
        rules_page_index = 1,
        rules_page_count = 1,
        rules_text_scroll = 0,
        rules_text_dragging = false,
        rules_text_drag_start_y = 0,
        rules_text_drag_start_offset = 0,
        matchmaking_overlay_visible = false,
        hovered_matchmaking_control = nil,
        matchmaking_phase = "idle",
        matchmaking_player_count = 0,
        matchmaking_required_player_count = 4,
        matchmaking_elapsed_seconds = 0,
        matchmaking_countdown_seconds = 0,
        matchmaking_room_id = nil,
        matchmaking_busy = false,
        matchmaking_message = "",
        matchmaking_poll_elapsed = 0,
        matchmaking_queue_active = false,
        matchmaking_transition_locked = false,
        mode_overlay_visible = false,
        hovered_mode_option = nil,
        hovered_mode_close = false,
        single_player_loading_visible = false,
        single_player_loading_elapsed = 0,
        single_player_loading_request_started = false,
        pending_single_player_mode = nil,
        server_loading_visible = false,
        server_loading_elapsed = 0,
        server_loading_request_started = false,
        pending_server_action = nil,
        hovered_profile = false,
        hovered_wardrobe_icon = false,
        hovered_mute_icon = false,
        hovered_settings_icon = false,
        wardrobe_overlay_visible = false,
        hovered_wardrobe_control = nil,
        wardrobe_tab = "equipment",
        wardrobe_slot = "frame",
        wardrobe_selected_item_id = nil,
        wardrobe_page_index = 1,
        wardrobe_busy = false,
        wardrobe_message = "",
        settings_overlay_visible = false,
        hovered_settings_control = nil,
        confirm_dialog_visible = false,
        confirm_dialog_action = nil,
        hovered_confirm_dialog_control = nil,
        settings_window_mode = initial_settings.window_mode or "windowed",
        settings_language_options = {},
        settings_language_index = 1,
        settings_resolution_options = {},
        settings_resolution_index = 1,
        settings_fps_options = {},
        settings_fps_index = 1,
        settings_volume_options = {},
        settings_game_volume_index = 1,
        settings_bgm_volume_index = 1,
        audio_mute_master = initial_settings.audio_mute_master == true,
        card_theme_config = buildCardThemeConfig(self.user_profile),
    }
    self.view = MainMenuView.new({
        fonts = fonts,
        style = Style,
    })
    self.state.rules_page_count = self.view.game_rules_overlay:getPageCount()
    self.controller = Controller.new({
        state = self.state,
        service = MainMenuService.new({
            http_client = HttpClient.new(),
        }),
        session_service = SessionService.new({
            http_client = HttpClient.new(),
        }),
        user_profile = self.user_profile,
        get_current_settings = get_current_settings,
        on_toggle_mute = on_toggle_mute,
        on_change_window_mode = on_change_window_mode,
        on_change_resolution = on_change_resolution,
        on_change_language = on_change_language,
        on_change_target_fps = on_change_target_fps,
        on_change_game_volume = on_change_game_volume,
        on_change_bgm_volume = on_change_bgm_volume,
        on_reset_settings = on_reset_settings,
        on_exit_game = on_exit_game,
        on_open_lobby = on_open_lobby,
        on_open_single_player_game = on_open_single_player_game,
        on_open_matchmaking_game = on_open_matchmaking_game,
        on_toggle_matchmaking = on_toggle_matchmaking,
        on_open_profile_editor = on_open_profile_editor,
    })

    return self
end

function MainMenuPage:draw()
    if self.backgrounds then
        self.backgrounds:draw("MainMenuBG")
    end
    self.view:draw(self.state, self.user_profile)
end

function MainMenuPage:update(dt)
    local matchmaking_state = self.get_matchmaking_state and self.get_matchmaking_state() or nil
    self.state.matchmaking_queue_active = matchmaking_state and matchmaking_state.queue_active == true
    self.state.matchmaking_transition_locked = matchmaking_state and matchmaking_state.matched_holding == true
    if self.controller and self.controller.update then
        self.controller:update(dt)
    end
    if self.view and self.view.update then
        self.view:update(dt, self.state)
    end
end

function MainMenuPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function MainMenuPage:mousepressed(x, y, button)
    local handled = self.controller:mousepressed(x, y, button, self.view)
    if handled then
        return true
    end

    if button == 1
        and self.backgrounds
        and self.backgrounds.handleMainMenuBackgroundClick
        and self.view:isBackgroundClickable(x, y, self.state)
    then
        self.backgrounds:handleMainMenuBackgroundClick(x, y)
        return true
    end

    return false
end

function MainMenuPage:mousereleased(x, y, button)
    if self.controller and self.controller.mousereleased then
        return self.controller:mousereleased(x, y, button, self.view) == true
    end
    return false
end

function MainMenuPage:wheelmoved(x, y)
    if self.controller and self.controller.wheelmoved then
        return self.controller:wheelmoved(x, y, self.view) == true
    end
    return false
end

function MainMenuPage:resize()
    self.view:resize()
end

function MainMenuPage:shutdown()
    if self.controller and self.controller.shutdown then
        self.controller:shutdown()
    end
end

return MainMenuPage
