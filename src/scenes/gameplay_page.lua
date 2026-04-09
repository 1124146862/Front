local Controller = require("src.features.gameplay.controller")
local GameplayService = require("src.features.gameplay.service")
local State = require("src.features.gameplay.state")
local Style = require("src.features.gameplay.style")
local GameplayView = require("src.features.gameplay.views.gameplay_view")
local HttpClient = require("src.infra.network.http_client")
local RoomWebSocketClient = require("src.infra.network.room_ws_client")

local GameplayPage = {}
GameplayPage.__index = GameplayPage

function GameplayPage.new(options)
    local self = setmetatable({}, GameplayPage)

    local fonts = assert(options and options.fonts, "GameplayPage requires fonts")
    local room = assert(options and options.room, "GameplayPage requires room")
    local user_profile = assert(options and options.user_profile, "GameplayPage requires user_profile")
    local get_current_settings = assert(options and options.get_current_settings, "GameplayPage requires get_current_settings")
    local on_change_window_mode = assert(options and options.on_change_window_mode, "GameplayPage requires on_change_window_mode")
    local on_change_resolution = assert(options and options.on_change_resolution, "GameplayPage requires on_change_resolution")
    local on_change_language = assert(options and options.on_change_language, "GameplayPage requires on_change_language")
    local on_change_target_fps = assert(options and options.on_change_target_fps, "GameplayPage requires on_change_target_fps")
    local on_change_game_volume = assert(options and options.on_change_game_volume, "GameplayPage requires on_change_game_volume")
    local on_change_bgm_volume = assert(options and options.on_change_bgm_volume, "GameplayPage requires on_change_bgm_volume")
    local on_change_game_bgm = assert(options and options.on_change_game_bgm, "GameplayPage requires on_change_game_bgm")
    local on_toggle_mute = assert(options and options.on_toggle_mute, "GameplayPage requires on_toggle_mute")
    local on_reset_settings = assert(options and options.on_reset_settings, "GameplayPage requires on_reset_settings")
    local on_get_background_theme = assert(options and options.on_get_background_theme, "GameplayPage requires on_get_background_theme")
    local on_set_background_theme = assert(options and options.on_set_background_theme, "GameplayPage requires on_set_background_theme")
    local on_regenerate_background_theme = assert(options and options.on_regenerate_background_theme, "GameplayPage requires on_regenerate_background_theme")
    local on_change_card_high_contrast = assert(options and options.on_change_card_high_contrast, "GameplayPage requires on_change_card_high_contrast")
    local on_change_card_theme = assert(options and options.on_change_card_theme, "GameplayPage requires on_change_card_theme")
    local on_change_card_back = assert(options and options.on_change_card_back, "GameplayPage requires on_change_card_back")
    local on_sync_card_settings = options and options.on_sync_card_settings or nil
    local on_play_sfx = options and options.on_play_sfx or nil
    local on_get_sfx_duration = options and options.on_get_sfx_duration or nil
    local on_start_looped_sfx = options and options.on_start_looped_sfx or nil
    local on_stop_looped_sfx = options and options.on_stop_looped_sfx or nil

    self.backgrounds = options and options.backgrounds or nil
    if self.backgrounds
        and self.backgrounds.getGameplayThemeId
        and not self.backgrounds:getGameplayThemeId()
    then
        local selected = nil
        if self.backgrounds.getBackgroundLayoutMode
            and self.backgrounds:getBackgroundLayoutMode() == "grid"
            and self.backgrounds.selectRandomSeasonalGameplayTheme then
            selected = self.backgrounds:selectRandomSeasonalGameplayTheme()
        elseif self.backgrounds.selectRandomGameplayTheme then
            selected = self.backgrounds:selectRandomGameplayTheme()
        end
        if not selected
            and self.backgrounds.selectRandomGameplayTheme then
            self.backgrounds:selectRandomGameplayTheme()
        end
    end
    self.state = State.create(room.room_id, user_profile, room.initial_game)
    self.view = GameplayView.new({
        fonts = fonts,
        style = Style,
        backgrounds = self.backgrounds,
    })
    self.controller = Controller.new({
        state = self.state,
        service = GameplayService.new({
            http_client = HttpClient.new(),
            ws_client = RoomWebSocketClient.new(),
        }),
        get_current_settings = get_current_settings,
        on_change_window_mode = on_change_window_mode,
        on_change_resolution = on_change_resolution,
        on_change_language = on_change_language,
        on_change_target_fps = on_change_target_fps,
        on_change_game_volume = on_change_game_volume,
        on_change_bgm_volume = on_change_bgm_volume,
        on_change_game_bgm = on_change_game_bgm,
        on_toggle_mute = on_toggle_mute,
        on_reset_settings = on_reset_settings,
        on_get_background_theme = on_get_background_theme,
        on_set_background_theme = on_set_background_theme,
        on_regenerate_background_theme = on_regenerate_background_theme,
        on_change_card_high_contrast = on_change_card_high_contrast,
        on_change_card_theme = on_change_card_theme,
        on_change_card_back = on_change_card_back,
        on_sync_card_settings = on_sync_card_settings,
        on_play_sfx = on_play_sfx,
        on_get_sfx_duration = on_get_sfx_duration,
        on_start_looped_sfx = on_start_looped_sfx,
        on_stop_looped_sfx = on_stop_looped_sfx,
        on_back_to_main_menu = options and options.on_back_to_main_menu or nil,
        on_exit_game = options and options.on_exit_game or nil,
        initial_game = room.initial_game,
    })

    return self
end

function GameplayPage:update(dt)
    self.controller:update(dt)
    self.view:update(dt, self.state)
end

function GameplayPage:draw()
    if self.backgrounds then
        self.backgrounds:draw("GamePlayBG")
    end
    self.view:draw(self.state)
end

function GameplayPage:resize()
    self.view:resize()
end

function GameplayPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function GameplayPage:mousepressed(x, y, button)
    return self.controller:mousepressed(x, y, button, self.view)
end

function GameplayPage:mousereleased(x, y, button)
    return self.controller:mousereleased(x, y, button, self.view)
end

function GameplayPage:keypressed(key)
    self.controller:keypressed(key)
end

function GameplayPage:wheelmoved(x, y)
    if self.controller and self.controller.wheelmoved then
        return self.controller:wheelmoved(x, y, self.view) == true
    end
    return false
end

function GameplayPage:shutdown()
    self.controller:shutdown()
end

return GameplayPage
