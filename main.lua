local source_root = love.filesystem.getSource()
if source_root and source_root ~= "" then
    local lua_paths = table.concat({
        source_root .. "/?.lua",
        source_root .. "/?/init.lua",
    }, ";")
    if not string.find(package.path or "", source_root, 1, true) then
        package.path = lua_paths .. ";" .. package.path
    end
end

local FontManager = require("src.core.font_manager")
local AudioManager = require("src.core.audio.audio_manager")
local BackgroundManager = require("src.core.background_manager")
local AppConfig = require("src.core.config.app_config")
local I18n = require("src.core.i18n.i18n")
local AppSettingsStore = require("src.core.settings.app_settings_store")
local DefaultSettings = require("src.core.settings.app_settings_config")
local BackgroundThemeCatalog = require("src.core.backgrounds.themes.background_theme_catalog")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")
local MainMenuStyle = require("src.features.main_menu.style")
local MatchmakingManager = require("src.features.matchmaking.manager")
local SessionService = require("src.features.session.service")
local SteamIDProvider = require("src.features.session.steam_id_provider")
local GameplayPage = require("src.scenes.gameplay_page")
local LobbyPage = require("src.scenes.lobby_page")
local MainMenuPage = require("src.scenes.main_menu_page")
local NicknameCheckPage = require("src.scenes.nickname_check_page")
local RoomPage = require("src.scenes.room_page")
local WelcomePage = require("src.scenes.welcome_page")
local HttpClient = require("src.infra.network.http_client")
local RuntimeConfig = require("src.infra.network.runtime_config")
local RuntimeFlags = require("src.infra.system.runtime_flags")

local app = {
    fonts = nil,
    audio = nil,
    backgrounds = nil,
    scene = nil,
    settings = nil,
    settings_store = nil,
    steam_id = nil,
    user_profile = {},
    did_auto_random_nickname = false,
    target_fps = 60,
    pending_card_settings_save = nil,
    resize_guard = false,
    matchmaking = nil,
}

local showMainMenuPage
local showRoomPage
local showGameplayPage
local showProfileEditorPage

local CARD_SETTINGS_SAVE_RETRY_SECONDS = 2.0
local TARGET_ASPECT_W = 16
local TARGET_ASPECT_H = 9
local MAIN_MENU_CLEANUP_DEBOUNCE_SECONDS = 0.75
local SHOW_LOCAL_TEST_SERVER_OPTION = true

local function trimValue(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function normalizeServerPort(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        return fallback
    end
    numeric = math.floor(numeric)
    if numeric < 1 or numeric > 65535 then
        return fallback
    end
    return numeric
end

local function copyServerPreset(network)
    return {
        host = trimValue(network and network.host),
        port = normalizeServerPort(network and network.port, 8123),
        use_tls = network and network.use_tls == true,
    }
end

local SERVER_PRESETS = {
    domestic = copyServerPreset((((AppConfig or {}).network or {}).ip_based_servers or {}).domestic),
    overseas = copyServerPreset((((AppConfig or {}).network or {}).ip_based_servers or {}).overseas),
    local_test = copyServerPreset((((AppConfig or {}).network or {}).local_server)),
}

local SERVER_OPTION_DEFINITIONS = {
    {
        id = "domestic",
        label_key = "welcome.server_domestic",
    },
    {
        id = "overseas",
        label_key = "welcome.server_overseas",
    },
    {
        id = "local_test",
        label_key = "welcome.server_local_test",
        enabled = function()
            return SHOW_LOCAL_TEST_SERVER_OPTION == true
        end,
    },
}

local function getVisibleServerOptionDefinitions()
    local options = {}
    for _, definition in ipairs(SERVER_OPTION_DEFINITIONS) do
        local enabled = definition.enabled == nil or definition.enabled() == true
        if enabled then
            options[#options + 1] = definition
        end
    end
    return options
end

local function networkMatchesPreset(settings, preset)
    if not preset then
        return false
    end

    return trimValue((settings or {}).server_host) == trimValue(preset.host)
        and normalizeServerPort((settings or {}).server_port, preset.port) == preset.port
        and (((settings or {}).server_use_tls) == true) == (preset.use_tls == true)
end

local function getSelectedServerKey(settings)
    for _, option in ipairs(getVisibleServerOptionDefinitions()) do
        if networkMatchesPreset(settings, SERVER_PRESETS[option.id]) then
            return option.id
        end
    end
    return nil
end

local function buildServerSettingsPatch(server_key)
    local preset = SERVER_PRESETS[server_key]
    if not preset then
        return nil
    end

    local urls = AppConfig.buildBaseUrls(preset)
    return {
        server_host = preset.host,
        server_port = preset.port,
        server_use_tls = preset.use_tls,
        server_http_base_url = urls.http,
        server_ws_base_url = urls.ws,
    }
end

local function normalizeWindowedAspect(width, height)
    local w = math.max(640, math.floor(tonumber(width) or 1600))
    local h = math.max(360, math.floor(tonumber(height) or 900))
    local target_h = math.max(360, math.floor(w * TARGET_ASPECT_H / TARGET_ASPECT_W + 0.5))
    local target_w = math.max(640, math.floor(h * TARGET_ASPECT_W / TARGET_ASPECT_H + 0.5))
    local normalized_w
    local normalized_h

    if math.abs(target_h - h) <= math.abs(target_w - w) then
        normalized_w, normalized_h = w, target_h
    else
        normalized_w, normalized_h = target_w, h
    end

    local desktop_w, desktop_h = love.window.getDesktopDimensions(1)
    local max_w = math.max(640, math.floor((tonumber(desktop_w) or normalized_w) - 80))
    local max_h = math.max(360, math.floor((tonumber(desktop_h) or normalized_h) - 120))

    if normalized_w <= max_w and normalized_h <= max_h then
        return normalized_w, normalized_h
    end

    if max_w * TARGET_ASPECT_H <= max_h * TARGET_ASPECT_W then
        normalized_w = max_w
        normalized_h = math.max(360, math.floor(normalized_w * TARGET_ASPECT_H / TARGET_ASPECT_W + 0.5))
    else
        normalized_h = max_h
        normalized_w = math.max(640, math.floor(normalized_h * TARGET_ASPECT_W / TARGET_ASPECT_H + 0.5))
    end

    return normalized_w, normalized_h
end

local function applyDisplaySettings(settings)
    settings = settings or {}
    local mode = settings.window_mode or "windowed"
    local width = tonumber(settings.window_width) or 1600
    local height = tonumber(settings.window_height) or 900

    local _, _, current_flags = love.window.getMode()
    local flags = {}
    for key, value in pairs(current_flags or {}) do
        flags[key] = value
    end
    flags.resizable = true
    flags.minwidth = flags.minwidth or 960
    flags.minheight = flags.minheight or 540
    flags.fullscreen = mode == "fullscreen"
    if flags.fullscreen and (not flags.fullscreentype or flags.fullscreentype == "") then
        flags.fullscreentype = "desktop"
    end

    local target_w = width
    local target_h = height
    if flags.fullscreen then
        target_w, target_h = love.window.getDesktopDimensions(flags.display or 1)
    else
        target_w, target_h = normalizeWindowedAspect(width, height)
        settings.window_width = target_w
        settings.window_height = target_h
    end

    local ok = love.window.setMode(target_w, target_h, flags)
    if ok and app.backgrounds and app.backgrounds.onDisplayChanged then
        app.backgrounds:onDisplayChanged()
    end
    if ok and app.scene and app.scene.resize then
        app.scene:resize(love.graphics.getWidth(), love.graphics.getHeight())
    end
    return ok
end

local function applyFrameSettings(settings)
    local target_fps = math.floor(tonumber((settings or {}).target_fps) or 60)
    if target_fps < 15 then
        target_fps = 15
    end
    app.target_fps = target_fps
end

local function carrySessionRuntimeSettings(next_settings, previous_settings)
    local source = previous_settings or app.settings or {}
    next_settings.window_mode = source.window_mode or next_settings.window_mode or "windowed"
    next_settings.audio_mute_master = source.audio_mute_master == true
    next_settings.audio_mute_bgm = source.audio_mute_bgm == true
    next_settings.audio_mute_sfx = source.audio_mute_sfx == true
    return next_settings
end

local function updatePersistedSettings(patch)
    local previous = app.settings or {}
    local updated = app.settings_store:update(patch)
    app.settings = carrySessionRuntimeSettings(updated, previous)
    RuntimeConfig.applySettings(app.settings)
    return app.settings
end

local function setSceneBgm(scene_id)
    if not app.audio then
        return
    end

    local bgm_id = "main"
    if scene_id == "gameplay" then
        bgm_id = app.settings.preferred_game_bgm_id or "game_default"
    end
    if not app.audio:setBgm(bgm_id) then
        app.audio:setBgm(scene_id == "gameplay" and "game_default" or "main")
    end
end

local function setScene(next_scene)
    if app.scene and app.scene.shutdown then
        app.scene:shutdown()
    end
    if app.audio and app.audio.stopAllLoopedSfx then
        app.audio:stopAllLoopedSfx()
    end
    app.scene = next_scene
    print(string.format(
        "[main] setScene scene_type=%s",
        tostring(app.scene and app.scene.__index)
    ))
end

local function applyLanguage(locale)
    app.settings = updatePersistedSettings({
        language = locale,
    })
    app.user_profile.language = app.settings.language
    I18n:setLocale(app.settings.language)
    if app.audio then
        app.audio:applySettings(app.settings)
    end
end

local function createSessionService()
    return SessionService.new({
        http_client = HttpClient.new(),
    })
end

local function cleanupMainMenuRoomPresence(user_profile)
    local steam_id = (user_profile and user_profile.steam_id) or app.steam_id
    if not steam_id then
        return
    end

    local now = love and love.timer and love.timer.getTime and love.timer.getTime() or os.clock()
    if app.main_menu_cleanup_in_progress == true then
        print(string.format(
            "[main] cleanupMainMenuRoomPresence skipped in_progress steam_id=%s",
            tostring(steam_id)
        ))
        return
    end

    if tostring(app.last_main_menu_cleanup_steam_id or "") == tostring(steam_id)
        and (tonumber(app.last_main_menu_cleanup_at) or 0) > 0
        and (now - (tonumber(app.last_main_menu_cleanup_at) or 0)) < MAIN_MENU_CLEANUP_DEBOUNCE_SECONDS
    then
        print(string.format(
            "[main] cleanupMainMenuRoomPresence skipped debounce steam_id=%s",
            tostring(steam_id)
        ))
        return
    end

    app.main_menu_cleanup_in_progress = true
    local result = createSessionService():returnToMainMenu(steam_id)
    app.main_menu_cleanup_in_progress = false
    app.last_main_menu_cleanup_steam_id = steam_id
    app.last_main_menu_cleanup_at = now
    print(string.format(
        "[main] cleanupMainMenuRoomPresence steam_id=%s ok=%s cleaned=%s deleted=%s message=%s",
        tostring(steam_id),
        tostring(result and result.ok),
        tostring(result and table.concat(result.cleaned_room_ids or {}, ",")),
        tostring(result and table.concat(result.deleted_room_ids or {}, ",")),
        tostring(result and result.message)
    ))
end

local function logNetworkDiagnostics()
    local client = HttpClient.new()
    local snapshot = RuntimeFlags.snapshot()
    print(string.format(
        "[network] mode=%s os=%s fused=%s http_client=%s http_base=%s ws_base=%s",
        tostring(snapshot.active_mode),
        tostring(snapshot.os_name),
        tostring(snapshot.is_fused),
        tostring(client and client.mode),
        tostring(RuntimeConfig.getHttpBaseUrl()),
        tostring(RuntimeConfig.getWsBaseUrl())
    ))
    print(string.format(
        "[network] env_proxy HTTP_PROXY=%s HTTPS_PROXY=%s ALL_PROXY=%s NO_PROXY=%s",
        tostring(os.getenv("HTTP_PROXY") or ""),
        tostring(os.getenv("HTTPS_PROXY") or ""),
        tostring(os.getenv("ALL_PROXY") or ""),
        tostring(os.getenv("NO_PROXY") or "")
    ))
end

local function normalizeAccessories(accessories)
    local equipped = ((accessories or {}).equipped) or {}
    return {
        owned_item_ids = ((accessories or {}).owned_item_ids) or {},
        equipped = {
            frame = equipped.frame,
            head = equipped.head,
            eyes = equipped.eyes,
            nose = equipped.nose,
            neck = equipped.neck,
        },
    }
end

local function normalizeUserProfile(user_profile)
    local profile = user_profile or {}
    profile.language = profile.language or app.settings.language or I18n:getLocale()
    local card_settings = profile.card_settings or {}
    profile.card_settings = {
        theme_id = ThemeCatalog.normalizeThemeId(card_settings.theme_id),
        back_id = card_settings.back_id or "classic_grid",
    }
    profile.coins = tonumber(profile.coins) or 300
    profile.accessories = normalizeAccessories(profile.accessories)
    return profile
end

local function buildUserProfileFromSessionResult(steam_id, result, fallback_profile)
    if result and result.ok and result.exists then
        return {
            steam_id = steam_id,
            nickname = result.nickname,
            avatar_id = result.avatar_id or "avatar_1",
            coins = tonumber(result.coins) or 300,
            accessories = normalizeAccessories(result.accessories),
            card_settings = result.card_settings or {
                theme_id = ThemeCatalog.DEFAULT_THEME_ID,
                back_id = "classic_grid",
            },
            language = app.settings.language or I18n:getLocale(),
        }
    end

    local fallback = normalizeUserProfile(fallback_profile or app.user_profile or {})
    fallback.steam_id = fallback.steam_id or steam_id
    fallback.language = app.settings.language or I18n:getLocale()
    return fallback
end

local function fetchLatestUserProfile(steam_id, fallback_profile)
    local result = createSessionService():fetchNicknameBySteamID(steam_id)
    return buildUserProfileFromSessionResult(steam_id, result, fallback_profile)
end

local function saveUserCardSettings(patch)
    local steam_id = app.user_profile.steam_id or app.steam_id
    if not steam_id then
        return false
    end

    local pending = app.pending_card_settings_save
    local current = (pending and pending.settings) or ((app.user_profile or {}).card_settings) or {}
    local next_settings = {
        theme_id = ThemeCatalog.normalizeThemeId(patch.theme_id or current.theme_id),
        back_id = patch.back_id or current.back_id or "classic_grid",
    }

    app.user_profile.card_settings = next_settings
    app.pending_card_settings_save = {
        steam_id = steam_id,
        settings = next_settings,
        delay_seconds = 0,
        retry_count = 0,
    }
    return true
end

local function flushPendingCardSettingsSave(force)
    local pending = app.pending_card_settings_save
    if not pending then
        return true
    end

    if not force and (tonumber(pending.delay_seconds) or 0) > 0 then
        return false
    end

    local result = createSessionService():updateCardSettings(pending.steam_id, pending.settings)
    if result.ok then
        app.user_profile.card_settings = result.card_settings or pending.settings
        app.pending_card_settings_save = nil
        return true
    end

    pending.retry_count = (tonumber(pending.retry_count) or 0) + 1
    if pending.retry_count >= 2 then
        app.pending_card_settings_save = nil
        return false
    end

    pending.delay_seconds = CARD_SETTINGS_SAVE_RETRY_SECONDS
    return false
end

showGameplayPage = function(room)
    print(string.format(
        "[main] showGameplayPage room_id=%s initial_game_room_id=%s",
        tostring(room and room.room_id),
        tostring(room and room.initial_game and room.initial_game.room_id)
    ))
    if app.backgrounds then
        local layout_mode = app.backgrounds.getBackgroundLayoutMode and app.backgrounds:getBackgroundLayoutMode() or "grid"
        local selected_theme_id = app.backgrounds.getGameplayThemeId and app.backgrounds:getGameplayThemeId() or nil
        local carry_main_menu_selection = (layout_mode == "single" and selected_theme_id ~= nil)
        if not carry_main_menu_selection then
            local applied = false
            if layout_mode == "grid" and app.backgrounds.selectRandomSeasonalGameplayTheme then
                applied = app.backgrounds:selectRandomSeasonalGameplayTheme() ~= nil
            end

            local preferred_theme = BackgroundThemeCatalog.normalizeThemeId(app.settings.preferred_gameplay_background_theme)
            if preferred_theme ~= app.settings.preferred_gameplay_background_theme then
                app.settings = updatePersistedSettings({
                    preferred_gameplay_background_theme = preferred_theme,
                })
            end
            if not applied and preferred_theme and app.backgrounds.setGameplayTheme then
                applied = app.backgrounds:setGameplayTheme(preferred_theme) == true
            end
            if not applied and app.backgrounds.selectRandomGameplayTheme then
                app.backgrounds:selectRandomGameplayTheme()
            end
        end
    end

    local next_scene = GameplayPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        room = room,
        user_profile = app.user_profile,
        get_current_settings = function()
            return app.settings
        end,
        on_change_window_mode = function(window_mode)
            local previous_mode = app.settings.window_mode == "fullscreen" and "fullscreen" or "windowed"
            app.settings.window_mode = window_mode
            local ok = applyDisplaySettings(app.settings)
            if not ok then
                app.settings.window_mode = previous_mode
                applyDisplaySettings(app.settings)
                return false
            end
            return true
        end,
        on_change_resolution = function(width, height)
            local normalized_w, normalized_h = normalizeWindowedAspect(width, height)
            app.settings = updatePersistedSettings({
                window_width = normalized_w,
                window_height = normalized_h,
            })
            if app.settings.window_mode == "fullscreen" then
                return true
            end
            return applyDisplaySettings(app.settings)
        end,
        on_change_language = function(locale)
            applyLanguage(locale)
            return true
        end,
        on_change_target_fps = function(target_fps)
            app.settings = updatePersistedSettings({
                target_fps = target_fps,
            })
            applyFrameSettings(app.settings)
            return true
        end,
        on_change_game_volume = function(volume)
            app.settings = updatePersistedSettings({
                audio_sfx_volume = volume,
            })
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return true
        end,
        on_change_bgm_volume = function(volume)
            app.settings = updatePersistedSettings({
                audio_bgm_volume = volume,
            })
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return true
        end,
        on_change_game_bgm = function(bgm_id)
            app.settings = updatePersistedSettings({
                preferred_game_bgm_id = bgm_id,
            })
            if app.audio then
                app.audio:setBgm(bgm_id)
            end
            return true
        end,
        on_toggle_mute = function()
            local next_mute = not (app.settings.audio_mute_master == true)
            app.settings.audio_mute_master = next_mute
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return next_mute
        end,
        on_reset_settings = function()
            app.settings = updatePersistedSettings({
                language = DefaultSettings.language,
                server_host = DefaultSettings.server_host,
                server_port = DefaultSettings.server_port,
                server_use_tls = DefaultSettings.server_use_tls,
                server_http_base_url = DefaultSettings.server_http_base_url,
                server_ws_base_url = DefaultSettings.server_ws_base_url,
                window_width = DefaultSettings.window_width,
                window_height = DefaultSettings.window_height,
                target_fps = DefaultSettings.target_fps,
                audio_master_volume = DefaultSettings.audio_master_volume,
                audio_bgm_volume = DefaultSettings.audio_bgm_volume,
                audio_sfx_volume = DefaultSettings.audio_sfx_volume,
                preferred_game_bgm_id = DefaultSettings.preferred_game_bgm_id,
                preferred_gameplay_background_theme = DefaultSettings.preferred_gameplay_background_theme,
                cards_high_contrast = DefaultSettings.cards_high_contrast,
            })
            app.settings.window_mode = "windowed"
            app.settings.audio_mute_master = false
            app.settings.audio_mute_bgm = false
            app.settings.audio_mute_sfx = false
            app.user_profile.language = app.settings.language
            I18n:setLocale(app.settings.language)
            applyFrameSettings(app.settings)
            if app.audio then
                app.audio:applySettings(app.settings)
                app.audio:setBgm(app.settings.preferred_game_bgm_id or "game_default")
            end
            return applyDisplaySettings(app.settings)
        end,
        on_get_background_theme = function()
            if app.backgrounds and app.backgrounds.getGameplayThemeId then
                return app.backgrounds:getGameplayThemeId()
            end
            return nil
        end,
        on_set_background_theme = function(theme_id)
            if not app.backgrounds or not app.backgrounds.setGameplayTheme then
                return false
            end
            if app.backgrounds:setGameplayTheme(theme_id) ~= true then
                return false
            end
            app.settings = updatePersistedSettings({
                preferred_gameplay_background_theme = theme_id,
            })
            return true
        end,
        on_regenerate_background_theme = function()
            if not app.backgrounds or not app.backgrounds.regenerateGameplayTheme then
                return false
            end
            return app.backgrounds:regenerateGameplayTheme()
        end,
        on_change_card_high_contrast = function(enabled)
            app.settings = updatePersistedSettings({
                cards_high_contrast = enabled == true,
            })
            return true
        end,
        on_change_card_theme = function(theme_id)
            return saveUserCardSettings({
                theme_id = theme_id,
            })
        end,
        on_change_card_back = function(back_id)
            return saveUserCardSettings({
                back_id = back_id,
            })
        end,
        on_sync_card_settings = function()
            return flushPendingCardSettingsSave(true)
        end,
        on_play_sfx = function(sfx_id)
            if not app.audio or type(app.audio.playSfx) ~= "function" then
                return false
            end
            return app.audio:playSfx(sfx_id)
        end,
        on_get_sfx_duration = function(sfx_id)
            if not app.audio or type(app.audio.getSfxDuration) ~= "function" then
                return nil
            end
            return app.audio:getSfxDuration(sfx_id)
        end,
        on_start_looped_sfx = function(sfx_id, options)
            if not app.audio or type(app.audio.playLoopedSfx) ~= "function" then
                return false
            end
            return app.audio:playLoopedSfx(sfx_id, options)
        end,
        on_stop_looped_sfx = function(sfx_id)
            if not app.audio or type(app.audio.stopLoopedSfx) ~= "function" then
                return false
            end
            return app.audio:stopLoopedSfx(sfx_id)
        end,
        on_back_to_main_menu = function()
            showMainMenuPage()
        end,
        on_exit_game = function()
            if love and love.event and love.event.quit then
                love.event.quit()
            end
        end,
    })
    print("[main] GameplayPage.new completed")
    setScene(next_scene)
    setSceneBgm("gameplay")
end

showRoomPage = function(room_id, options)
    options = options or {}

    setScene(RoomPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        room_id = room_id,
        user_profile = app.user_profile,
        on_back_to_lobby = options.on_back_to_lobby or function()
            setScene(LobbyPage.new({
                fonts = app.fonts,
                backgrounds = app.backgrounds,
                user_profile = app.user_profile,
                on_back = function()
                    showMainMenuPage()
                end,
                on_enter_room = function(next_room_id)
                    showRoomPage(next_room_id)
                end,
            }))
            setSceneBgm("lobby")
        end,
        on_game_started = function(room)
            showGameplayPage(room)
        end,
        auto_single_player_bootstrap = options.auto_single_player_bootstrap == true,
    }))
    setSceneBgm("room")
end

showMainMenuPage = function(user_profile)
    app.user_profile = normalizeUserProfile(user_profile or app.user_profile or {})
    setScene(MainMenuPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        settings = app.settings,
        get_current_settings = function()
            return app.settings
        end,
        user_profile = app.user_profile,
        on_change_window_mode = function(window_mode)
            local previous_mode = app.settings.window_mode == "fullscreen" and "fullscreen" or "windowed"
            app.settings.window_mode = window_mode
            local ok = applyDisplaySettings(app.settings)
            if not ok then
                app.settings.window_mode = previous_mode
                applyDisplaySettings(app.settings)
                return false
            end
            return true
        end,
        on_change_resolution = function(width, height)
            local normalized_w, normalized_h = normalizeWindowedAspect(width, height)
            app.settings = updatePersistedSettings({
                window_width = normalized_w,
                window_height = normalized_h,
            })
            if app.settings.window_mode == "fullscreen" then
                return true
            end
            return applyDisplaySettings(app.settings)
        end,
        on_change_language = function(locale)
            applyLanguage(locale)
            return true
        end,
        on_change_target_fps = function(target_fps)
            app.settings = updatePersistedSettings({
                target_fps = target_fps,
            })
            applyFrameSettings(app.settings)
            return true
        end,
        on_change_game_volume = function(volume)
            app.settings = updatePersistedSettings({
                audio_sfx_volume = volume,
            })
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return true
        end,
        on_change_bgm_volume = function(volume)
            app.settings = updatePersistedSettings({
                audio_bgm_volume = volume,
            })
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return true
        end,
        on_reset_settings = function()
            app.settings = updatePersistedSettings({
                language = DefaultSettings.language,
                server_host = DefaultSettings.server_host,
                server_port = DefaultSettings.server_port,
                server_use_tls = DefaultSettings.server_use_tls,
                server_http_base_url = DefaultSettings.server_http_base_url,
                server_ws_base_url = DefaultSettings.server_ws_base_url,
                window_width = DefaultSettings.window_width,
                window_height = DefaultSettings.window_height,
                target_fps = DefaultSettings.target_fps,
                audio_master_volume = DefaultSettings.audio_master_volume,
                audio_bgm_volume = DefaultSettings.audio_bgm_volume,
                audio_sfx_volume = DefaultSettings.audio_sfx_volume,
                preferred_game_bgm_id = DefaultSettings.preferred_game_bgm_id,
                preferred_gameplay_background_theme = DefaultSettings.preferred_gameplay_background_theme,
                cards_high_contrast = DefaultSettings.cards_high_contrast,
            })
            app.settings.window_mode = "windowed"
            app.settings.audio_mute_master = false
            app.settings.audio_mute_bgm = false
            app.settings.audio_mute_sfx = false
            app.user_profile.language = app.settings.language
            I18n:setLocale(app.settings.language)
            applyFrameSettings(app.settings)
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return applyDisplaySettings(app.settings)
        end,
        on_toggle_mute = function()
            local next_mute = not (app.settings.audio_mute_master == true)
            app.settings.audio_mute_master = next_mute
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return next_mute
        end,
        on_exit_game = function()
            if love and love.event and love.event.quit then
                love.event.quit()
            end
        end,
        on_open_single_player_game = function(result)
            print(string.format(
                "[main] on_open_single_player_game room_id=%s snapshot_room_id=%s",
                tostring(result and result.room_id),
                tostring(result and result.snapshot and result.snapshot.room_id)
            ))
            showGameplayPage({
                room_id = result.room_id,
                initial_game = result.snapshot,
            })
        end,
        on_open_matchmaking_game = function(room_id)
            showGameplayPage({
                room_id = room_id,
            })
        end,
        on_toggle_matchmaking = function()
            return app.matchmaking:toggle()
        end,
        get_matchmaking_state = function()
            return app.matchmaking:getSnapshot()
        end,
        on_open_lobby = function()
            setScene(LobbyPage.new({
                fonts = app.fonts,
                backgrounds = app.backgrounds,
                user_profile = app.user_profile,
                on_back = function()
                    showMainMenuPage()
                end,
                on_enter_room = function(room_id)
                    showRoomPage(room_id)
                end,
            }))
            setSceneBgm("lobby")
        end,
        on_open_profile_editor = function()
            showProfileEditorPage()
        end,
    }))
    setSceneBgm("main_menu")
    cleanupMainMenuRoomPresence(app.user_profile)
end

showProfileEditorPage = function()
    local steam_id = app.user_profile.steam_id or app.steam_id
    setScene(NicknameCheckPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        initial_steam_id = steam_id,
        force_edit = true,
        on_close = function()
            showMainMenuPage(app.user_profile)
        end,
        on_session_ready = function(user_profile)
            user_profile.language = app.settings.language or I18n:getLocale()
            showMainMenuPage(user_profile)
        end,
    }))
    setSceneBgm("nickname_check")
end

local function showNicknameCheckPage()
    setScene(NicknameCheckPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        on_session_ready = function(user_profile)
            showMainMenuPage(user_profile)
        end,
    }))
    setSceneBgm("nickname_check")
end

local function resolveSessionAndEnter()
    local steam_id = app.steam_id
    local session_service = createSessionService()
    local result = session_service:fetchNicknameBySteamID(steam_id)

    if result.ok and result.exists then
        showMainMenuPage(buildUserProfileFromSessionResult(steam_id, result))
        return
    end

    local should_auto_random = not app.did_auto_random_nickname
    setScene(NicknameCheckPage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        initial_steam_id = steam_id,
        initial_fetch_result = result,
        auto_randomize = should_auto_random,
        on_session_ready = function(user_profile)
            showMainMenuPage(user_profile)
        end,
    }))
    if should_auto_random then
        app.did_auto_random_nickname = true
    end
    setSceneBgm("nickname_check")
end

local function showWelcomePage(options)
    options = options or {}
    setScene(WelcomePage.new({
        fonts = app.fonts,
        backgrounds = app.backgrounds,
        language_overlay_visible = options.language_overlay_visible == true,
        get_server_options = function()
            return getVisibleServerOptionDefinitions()
        end,
        get_selected_server_key = function()
            return getSelectedServerKey(app.settings)
        end,
        on_change_server = function(server_key)
            local patch = buildServerSettingsPatch(server_key)
            if not patch then
                return false
            end
            app.settings = updatePersistedSettings(patch)
            return true
        end,
        on_toggle_mute = function()
            local next_mute = not (app.settings.audio_mute_master == true)
            app.settings.audio_mute_master = next_mute
            if app.audio then
                app.audio:applySettings(app.settings)
            end
            return next_mute
        end,
        is_muted = function()
            return app.settings.audio_mute_master == true
        end,
        on_toggle_fullscreen = function()
            local current_mode = app.settings.window_mode == "fullscreen" and "fullscreen" or "windowed"
            local next_mode = current_mode == "fullscreen" and "windowed" or "fullscreen"
            app.settings.window_mode = next_mode
            local ok = applyDisplaySettings(app.settings)
            if not ok then
                app.settings.window_mode = current_mode
                applyDisplaySettings(app.settings)
                return false
            end
            return true
        end,
        is_fullscreen = function()
            return app.settings.window_mode == "fullscreen"
        end,
        on_change_language = function(locale)
            applyLanguage(locale)
            showWelcomePage({
                language_overlay_visible = true,
            })
        end,
        on_continue = function()
            resolveSessionAndEnter()
        end,
    }))
    setSceneBgm("welcome")
end

function love.load()
    love.graphics.setBackgroundColor(0.05, 0.07, 0.09, 1)
    love.keyboard.setKeyRepeat(false)

    app.settings_store = AppSettingsStore.new()
    app.settings = app.settings_store:load()
    if app.settings.window_mode ~= "fullscreen" then
        local normalized_w, normalized_h = normalizeWindowedAspect(app.settings.window_width, app.settings.window_height)
        if normalized_w ~= tonumber(app.settings.window_width) or normalized_h ~= tonumber(app.settings.window_height) then
            app.settings = app.settings_store:update({
                window_width = normalized_w,
                window_height = normalized_h,
            })
        end
    end
    RuntimeConfig.applySettings(app.settings)
    logNetworkDiagnostics()
    applyFrameSettings(app.settings)
    applyDisplaySettings(app.settings)

    app.fonts = FontManager.new()
    app.backgrounds = BackgroundManager.new()
    app.audio = AudioManager.new({
        settings = app.settings,
    })
    app.matchmaking = MatchmakingManager.new({
        fonts = app.fonts,
        style = MainMenuStyle,
        get_steam_id = function()
            return (app.user_profile and app.user_profile.steam_id) or app.steam_id
        end,
        on_enter_room = function(room_id)
            showGameplayPage({
                room_id = room_id,
            })
        end,
    })
    I18n:setLocale(app.settings.language)
    app.user_profile.language = app.settings.language
    app.user_profile.coins = tonumber(app.user_profile.coins) or 300
    app.user_profile.accessories = normalizeAccessories(app.user_profile.accessories)
    app.steam_id = SteamIDProvider.new({
        source = app.settings.steam_id_source,
        fake_steam_id = app.settings.fake_steam_id,
        random_for_test = app.settings.steam_id_random_for_test,
    }):getSteamID()

    showWelcomePage()
end

function love.update(dt)
    if app.target_fps and app.target_fps > 0 and love.timer and love.timer.sleep then
        local min_dt = 1 / app.target_fps
        if dt < min_dt then
            -- Throttle the loop without inflating simulation time.
            -- The sleep duration will be reflected naturally in the next frame's dt.
            love.timer.sleep(min_dt - dt)
        end
    end

    if app.audio and app.audio.update then
        app.audio:update(dt)
    end
    if app.backgrounds and app.backgrounds.update then
        app.backgrounds:update(dt)
    end
    if app.scene and app.scene.update then
        app.scene:update(dt)
    end
    if app.matchmaking and app.matchmaking.update then
        app.matchmaking:update(dt)
    end
end

function love.draw()
    if app.scene and app.scene.draw then
        app.scene:draw()
    end
    if app.matchmaking and app.matchmaking.draw then
        app.matchmaking:draw()
    end
end

function love.mousemoved(x, y, dx, dy)
    if app.scene and app.scene.mousemoved then
        app.scene:mousemoved(x, y, dx, dy)
    end
    if app.matchmaking and app.matchmaking.mousemoved then
        app.matchmaking:mousemoved(x, y)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    local handled = false
    if app.matchmaking and app.matchmaking.mousepressed then
        handled = app.matchmaking:mousepressed(x, y, button) == true
    end
    if not handled and app.scene and app.scene.mousepressed then
        handled = handled or (app.scene:mousepressed(x, y, button, istouch, presses) == true)
    end
    if handled and button == 1 and app.audio then
        app.audio:playClick()
    end
end

function love.wheelmoved(x, y)
    local handled = false
    if app.matchmaking and app.matchmaking.wheelmoved then
        handled = app.matchmaking:wheelmoved(x, y) == true
    end
    if not handled and app.scene and app.scene.wheelmoved then
        handled = handled or (app.scene:wheelmoved(x, y) == true)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    local handled = false
    if app.matchmaking and app.matchmaking.mousereleased then
        handled = app.matchmaking:mousereleased(x, y, button) == true
    end
    if not handled and app.scene and app.scene.mousereleased then
        handled = handled or (app.scene:mousereleased(x, y, button, istouch, presses) == true)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if app.scene and app.scene.keypressed then
        app.scene:keypressed(key, scancode, isrepeat)
    end
end

function love.textinput(text)
    if app.scene and app.scene.textinput then
        app.scene:textinput(text)
    end
end

function love.resize(width, height)
    if app.settings and app.settings.window_mode ~= "fullscreen" then
        local target_w, target_h = normalizeWindowedAspect(width, height)
        if (target_w ~= width or target_h ~= height) and not app.resize_guard then
            app.resize_guard = true
            app.settings.window_width = target_w
            app.settings.window_height = target_h
            applyDisplaySettings(app.settings)
            app.resize_guard = false
        end
    end

    local final_w = love.graphics.getWidth()
    local final_h = love.graphics.getHeight()
    if app.scene and app.scene.resize then
        app.scene:resize(final_w, final_h)
    end
end

function love.quit()
    flushPendingCardSettingsSave(true)
    if app.matchmaking and app.matchmaking.shutdown then
        app.matchmaking:shutdown()
    end
    if app.scene and app.scene.shutdown then
        app.scene:shutdown()
    end
    if app.audio and app.audio.shutdown then
        app.audio:shutdown()
    end
end
