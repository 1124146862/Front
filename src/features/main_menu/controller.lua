local Controller = {}
Controller.__index = Controller

local I18n = require("src.core.i18n.i18n")
local Catalog = require("src.features.session.accessories.catalog")

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
local WARDROBE_PAGE_SIZE = 8
local SINGLE_PLAYER_LOADING_DELAY = 0.18
local SERVER_ACTION_LOADING_DELAY = 0.04

local function resolutionLabel(option)
    return tostring(option.width) .. " x " .. tostring(option.height)
end

local function findLocaleIndex(locale_options, locale)
    local target = locale or I18n:getLocale()
    for index, item in ipairs(locale_options or {}) do
        if item == target then
            return index
        end
    end
    return 1
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

local function findOptionIndex(options, current_value, default_index)
    for index, value in ipairs(options or {}) do
        if value == current_value then
            return index
        end
    end
    return default_index or 1
end

local function ensureAccessories(user_profile)
    user_profile.accessories = user_profile.accessories or {}
    user_profile.accessories.owned_item_ids = user_profile.accessories.owned_item_ids or {}
    user_profile.accessories.equipped = user_profile.accessories.equipped or {}
    local equipped = user_profile.accessories.equipped
    equipped.frame = equipped.frame
end

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "MainMenuController requires state")
    self.service = assert(options and options.service, "MainMenuController requires service")
    self.session_service = assert(options and options.session_service, "MainMenuController requires session_service")
    self.user_profile = assert(options and options.user_profile, "MainMenuController requires user_profile")
    self.get_current_settings = assert(options and options.get_current_settings, "MainMenuController requires get_current_settings")
    self.on_toggle_mute = assert(options and options.on_toggle_mute, "MainMenuController requires on_toggle_mute")
    self.on_change_window_mode = assert(options and options.on_change_window_mode, "MainMenuController requires on_change_window_mode")
    self.on_change_resolution = assert(options and options.on_change_resolution, "MainMenuController requires on_change_resolution")
    self.on_change_language = assert(options and options.on_change_language, "MainMenuController requires on_change_language")
    self.on_change_target_fps = assert(options and options.on_change_target_fps, "MainMenuController requires on_change_target_fps")
    self.on_change_game_volume = assert(options and options.on_change_game_volume, "MainMenuController requires on_change_game_volume")
    self.on_change_bgm_volume = assert(options and options.on_change_bgm_volume, "MainMenuController requires on_change_bgm_volume")
    self.on_reset_settings = assert(options and options.on_reset_settings, "MainMenuController requires on_reset_settings")
    self.on_exit_game = assert(options and options.on_exit_game, "MainMenuController requires on_exit_game")
    self.on_open_lobby = assert(options and options.on_open_lobby, "MainMenuController requires on_open_lobby")
    self.on_open_single_player_game = assert(options and options.on_open_single_player_game, "MainMenuController requires on_open_single_player_game")
    self.on_open_matchmaking_game = assert(options and options.on_open_matchmaking_game, "MainMenuController requires on_open_matchmaking_game")
    self.on_toggle_matchmaking = assert(options and options.on_toggle_matchmaking, "MainMenuController requires on_toggle_matchmaking")
    self.on_open_profile_editor = assert(options and options.on_open_profile_editor, "MainMenuController requires on_open_profile_editor")
    self.user_profile.coins = tonumber(self.user_profile.coins) or 300
    ensureAccessories(self.user_profile)
    self.state.status_message = ""
    self.state.settings_resolution_options = RESOLUTION_OPTIONS
    self.state.settings_fps_options = FPS_OPTIONS
    self.state.settings_volume_options = VOLUME_OPTIONS
    self:syncAudioState()
    self:syncSettingsState()

    return self
end

function Controller:beginServerLoading(action_fn)
    if self.state.server_loading_visible then
        return false
    end
    self.state.server_loading_visible = true
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = action_fn
    self.state.hovered_action = nil
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    self.state.hovered_matchmaking_control = nil
    self.state.hovered_wardrobe_control = nil
    self.state.hovered_settings_control = nil
    return true
end

function Controller:finishServerLoading()
    self.state.server_loading_visible = false
    self.state.server_loading_elapsed = 0
    self.state.server_loading_request_started = false
    self.state.pending_server_action = nil
end

function Controller:applyMatchmakingResult(result)
    if not result.ok then
        self.state.matchmaking_message = result.message or I18n:t("main_menu.matchmaking_status_failed")
        self.state.matchmaking_busy = false
        return false
    end

    self.state.matchmaking_phase = result.phase or "idle"
    self.state.matchmaking_player_count = tonumber(result.player_count) or 0
    self.state.matchmaking_required_player_count = tonumber(result.required_player_count) or 4
    self.state.matchmaking_elapsed_seconds = tonumber(result.elapsed_seconds) or 0
    self.state.matchmaking_countdown_seconds = tonumber(result.countdown_seconds) or 0
    self.state.matchmaking_room_id = result.room_id
    self.state.matchmaking_message = result.message or ""
    self.state.matchmaking_busy = false
    self.state.matchmaking_poll_elapsed = 0
    return true
end

function Controller:_openMatchmakingOverlayNow()
    local steam_id = self.user_profile.steam_id
    if not steam_id then
        self.state.status_message = I18n:t("main_menu.matchmaking_join_failed")
        return
    end

    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
    self.state.rules_overlay_visible = false
    self.state.hovered_rules_control = nil
    self.state.mode_overlay_visible = false
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    self.state.settings_overlay_visible = false
    self.state.hovered_settings_control = nil
    self.state.matchmaking_overlay_visible = true
    self.state.hovered_matchmaking_control = nil
    self.state.matchmaking_phase = "idle"
    self.state.matchmaking_player_count = 0
    self.state.matchmaking_required_player_count = 4
    self.state.matchmaking_elapsed_seconds = 0
    self.state.matchmaking_countdown_seconds = 0
    self.state.matchmaking_room_id = nil
    self.state.matchmaking_busy = true
    self.state.matchmaking_message = ""
    self.state.status_message = ""

    local result = self.service:joinMatchmaking(steam_id)
    self:applyMatchmakingResult(result)
    if self.state.matchmaking_phase == "matched" and self.state.matchmaking_room_id then
        local room_id = self.state.matchmaking_room_id
        self.state.matchmaking_overlay_visible = false
        self.state.hovered_matchmaking_control = nil
        self.on_open_matchmaking_game(room_id)
    end
end

function Controller:openMatchmakingOverlay()
    self:beginServerLoading(function()
        self:_openMatchmakingOverlayNow()
    end)
end

function Controller:_closeMatchmakingOverlayNow()
    local steam_id = self.user_profile.steam_id
    self.state.matchmaking_overlay_visible = false
    self.state.hovered_matchmaking_control = nil
    self.state.matchmaking_phase = "idle"
    self.state.matchmaking_player_count = 0
    self.state.matchmaking_elapsed_seconds = 0
    self.state.matchmaking_countdown_seconds = 0
    self.state.matchmaking_room_id = nil
    self.state.matchmaking_busy = false
    self.state.matchmaking_poll_elapsed = 0
    if steam_id then
        local result = self.service:cancelMatchmaking(steam_id)
        if result and result.ok == false then
            self.state.status_message = result.message or I18n:t("main_menu.matchmaking_cancel_failed")
        else
            self.state.status_message = ""
        end
    end
end

function Controller:closeMatchmakingOverlay()
    self:beginServerLoading(function()
        self:_closeMatchmakingOverlayNow()
    end)
end

function Controller:pollMatchmakingStatus(consume_match)
    local steam_id = self.user_profile.steam_id
    if not steam_id then
        return false
    end
    local result = self.service:fetchMatchmakingStatus(steam_id, consume_match == true)
    if not self:applyMatchmakingResult(result) then
        return false
    end
    if self.state.matchmaking_phase == "matched" and self.state.matchmaking_room_id then
        local room_id = self.state.matchmaking_room_id
        self.state.matchmaking_overlay_visible = false
        self.state.hovered_matchmaking_control = nil
        self.on_open_matchmaking_game(room_id)
        return true
    end
    return false
end

function Controller:update(dt)
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
            return
        end
    end

    if self.state.single_player_loading_visible then
        self.state.single_player_loading_elapsed = (tonumber(self.state.single_player_loading_elapsed) or 0)
            + (tonumber(dt) or 0)
        if not self.state.single_player_loading_request_started
            and self.state.single_player_loading_elapsed >= SINGLE_PLAYER_LOADING_DELAY
        then
            self.state.single_player_loading_request_started = true
            self:startSinglePlayerGame(self.state.pending_single_player_mode)
            return
        end
    end

    if not self.state.matchmaking_overlay_visible then
        return
    end

    self.state.matchmaking_poll_elapsed = (tonumber(self.state.matchmaking_poll_elapsed) or 0) + (tonumber(dt) or 0)
    if self.state.matchmaking_poll_elapsed < 1.0 then
        return
    end

    self.state.matchmaking_poll_elapsed = 0
    self:pollMatchmakingStatus(true)
end

function Controller:shutdown()
    if self.state.matchmaking_overlay_visible then
        self:_closeMatchmakingOverlayNow()
    end
end

function Controller:getWardrobeRows()
    ensureAccessories(self.user_profile)
    local rows = {}
    local owned_lookup = {}
    for _, item_id in ipairs(self.user_profile.accessories.owned_item_ids or {}) do
        owned_lookup[item_id] = true
    end

    if (self.state.wardrobe_tab or "equipment") == "equipment" then
        rows[#rows + 1] = { marker = Catalog.NONE_MARKER }
        for _, item in ipairs(Catalog:getSlotItems("frame")) do
            if owned_lookup[item.item_id] then
                rows[#rows + 1] = { marker = item.item_id }
            end
        end
    else
        for _, item in ipairs(Catalog:getSlotItems("frame")) do
            rows[#rows + 1] = { marker = item.item_id }
        end
    end

    return rows
end

function Controller:syncWardrobeSelection()
    local rows = self:getWardrobeRows()
    local selected = self.state.wardrobe_selected_item_id
    for _, row in ipairs(rows) do
        if row.marker == selected then
            self:syncWardrobePage()
            return
        end
    end

    local equipped = (((self.user_profile or {}).accessories or {}).equipped or {}).frame
    if (self.state.wardrobe_tab or "equipment") == "equipment" then
        self.state.wardrobe_selected_item_id = equipped or Catalog.NONE_MARKER
        for _, row in ipairs(rows) do
            if row.marker == self.state.wardrobe_selected_item_id then
                self:syncWardrobePage()
                return
            end
        end
    end

    self.state.wardrobe_selected_item_id = rows[1] and rows[1].marker or nil
    self:syncWardrobePage()
end

function Controller:syncWardrobePage()
    local rows = self:getWardrobeRows()
    local total = #rows
    local page_count = math.max(1, math.ceil(total / WARDROBE_PAGE_SIZE))
    local selected = self.state.wardrobe_selected_item_id
    local selected_index = 1

    for index, row in ipairs(rows) do
        if row.marker == selected then
            selected_index = index
            break
        end
    end

    self.state.wardrobe_page_index = math.max(1, math.min(page_count, math.floor((selected_index - 1) / WARDROBE_PAGE_SIZE) + 1))
end

function Controller:openWardrobeOverlay()
    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
end

function Controller:closeWardrobeOverlay()
    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
    self.state.wardrobe_message = ""
end

function Controller:setWardrobeTab(tab_id)
    if tab_id ~= "equipment" and tab_id ~= "shop" then
        return
    end
    self.state.wardrobe_tab = tab_id
    self.state.wardrobe_page_index = 1
    self.state.wardrobe_message = ""
    self:syncWardrobeSelection()
end

function Controller:setWardrobeSlot(slot)
    if slot ~= "frame" then
        return
    end
    self.state.wardrobe_slot = "frame"
    self.state.wardrobe_message = ""
    self:syncWardrobeSelection()
end

function Controller:setWardrobeSelectedItem(marker)
    self.state.wardrobe_selected_item_id = marker
    self:syncWardrobePage()
end

function Controller:changeWardrobePage(delta)
    local rows = self:getWardrobeRows()
    local page_count = math.max(1, math.ceil(#rows / WARDROBE_PAGE_SIZE))
    local next_page = (tonumber(self.state.wardrobe_page_index) or 1) + delta
    self.state.wardrobe_page_index = math.max(1, math.min(page_count, next_page))
end

function Controller:applyWardrobeResult(result)
    if not result.ok then
        self.state.wardrobe_message = result.message or I18n:t("main_menu.wardrobe_action_failed")
        return false
    end

    self.user_profile.coins = tonumber(result.coins) or self.user_profile.coins or 300
    self.user_profile.accessories = result.accessories or self.user_profile.accessories
    ensureAccessories(self.user_profile)
    self.state.wardrobe_message = result.message or ""
    self:syncWardrobeSelection()
    return true
end

function Controller:_performWardrobeActionNow()
    local steam_id = self.user_profile.steam_id
    if not steam_id or self.state.wardrobe_busy then
        return
    end

    local marker = self.state.wardrobe_selected_item_id
    if not marker then
        self.state.wardrobe_message = I18n:t("main_menu.wardrobe_pick_hint")
        return
    end

    self.state.wardrobe_busy = true
    local result = nil
    if (self.state.wardrobe_tab or "equipment") == "shop" then
        if marker == Catalog.NONE_MARKER then
            self.state.wardrobe_busy = false
            return
        end
        local item = Catalog:getItem(marker)
        local owned_lookup = {}
        for _, item_id in ipairs((((self.user_profile or {}).accessories or {}).owned_item_ids) or {}) do
            owned_lookup[item_id] = true
        end
        if item and owned_lookup[item.item_id] then
            result = self.session_service:equipAccessory(steam_id, "frame", item.item_id)
        else
            result = self.session_service:purchaseAccessory(steam_id, marker)
        end
    else
        local item_id = marker == Catalog.NONE_MARKER and nil or marker
        result = self.session_service:equipAccessory(steam_id, self.state.wardrobe_slot or "frame", item_id)
    end
    self.state.wardrobe_busy = false
    self:applyWardrobeResult(result or { ok = false })
end

function Controller:performWardrobeAction()
    self:beginServerLoading(function()
        self:_performWardrobeActionNow()
    end)
end

function Controller:mousemoved(x, y, view)
    if self.state.server_loading_visible then
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_rules_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_confirm_dialog_control = nil
        self.state.hovered_wardrobe_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.single_player_loading_visible then
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_rules_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_confirm_dialog_control = nil
        self.state.hovered_wardrobe_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.rules_overlay_visible and self.state.rules_text_dragging then
        local start_offset = tonumber(self.state.rules_text_drag_start_offset) or 0
        local start_y = tonumber(self.state.rules_text_drag_start_y) or y
        local next_offset = start_offset + (start_y - y)
        self.state.rules_text_scroll = view.game_rules_overlay:clampTextScroll(next_offset, self.state.rules_page_index)
        self.state.hovered_rules_control = nil
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_wardrobe_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.matchmaking_overlay_visible then
        self.state.hovered_matchmaking_control = view:getMatchmakingOverlayControlAt(x, y)
        self.state.hovered_rules_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_wardrobe_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.wardrobe_overlay_visible then
        self.state.hovered_wardrobe_control = view:getWardrobeOverlayControlAt(x, y, self.state, self.user_profile)
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_rules_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.rules_overlay_visible then
        self.state.hovered_rules_control = view:getRulesOverlayControlAt(x, y, self.state)
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_settings_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.settings_overlay_visible then
        if self.state.confirm_dialog_visible then
            self.state.hovered_confirm_dialog_control = view:getConfirmDialogControlAt(x, y, self.state)
            self.state.hovered_settings_control = nil
            self.state.hovered_matchmaking_control = nil
            self.state.hovered_rules_control = nil
            self.state.hovered_action = nil
            self.state.hovered_mode_option = nil
            self.state.hovered_mode_close = false
            self.state.hovered_profile = false
            self.state.hovered_mute_icon = false
            self.state.hovered_settings_icon = false
            self.state.hovered_wardrobe_icon = false
            return
        end
        self.state.hovered_confirm_dialog_control = nil
        self.state.hovered_settings_control = view:getSettingsControlAt(x, y, self.state)
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_rules_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mode_option = nil
        self.state.hovered_mode_close = false
        self.state.hovered_profile = false
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    if self.state.mode_overlay_visible then
        self.state.hovered_mode_option = view:getModeOptionAt(x, y)
        self.state.hovered_mode_close = view:isModeOverlayCloseHovered(x, y)
        self.state.hovered_matchmaking_control = nil
        self.state.hovered_rules_control = nil
        self.state.hovered_action = nil
        self.state.hovered_mute_icon = false
        self.state.hovered_settings_icon = false
        self.state.hovered_wardrobe_icon = false
        return
    end

    self.state.hovered_profile = view:isProfileHovered(x, y)
    self.state.hovered_wardrobe_icon = view:isWardrobeIconHovered(x, y)
    self.state.hovered_mute_icon = view:isMuteIconHovered(x, y)
    self.state.hovered_settings_icon = view:isSettingsIconHovered(x, y)
    self.state.hovered_matchmaking_control = nil
    self.state.hovered_rules_control = nil
    self.state.hovered_action = view:getActionAt(x, y, self.state, self.state.hovered_action)
end

function Controller:wheelmoved(_, y, view)
    if not self.state.rules_overlay_visible then
        return false
    end

    local page_index = self.state.rules_page_index or 1
    if not (view and view.game_rules_overlay and view.game_rules_overlay:isTextPage(page_index)) then
        return false
    end

    local mouse_x, mouse_y = love.mouse.getPosition()
    if not view.game_rules_overlay:isTextScrollHit(mouse_x, mouse_y, page_index) then
        return false
    end

    local step = view.game_rules_overlay:getTextScrollStep()
    local delta = (tonumber(y) or 0) * step
    if delta == 0 then
        return false
    end

    local current = tonumber(self.state.rules_text_scroll) or 0
    local next_offset = current - delta
    self.state.rules_text_scroll = view.game_rules_overlay:clampTextScroll(next_offset, page_index)
    self.state.rules_text_dragging = false
    self.state.hovered_rules_control = nil
    return true
end

function Controller:openRulesOverlay()
    self.state.matchmaking_overlay_visible = false
    self.state.hovered_matchmaking_control = nil
    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
    self.state.mode_overlay_visible = false
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    self.state.settings_overlay_visible = false
    self.state.hovered_settings_control = nil
    self.state.rules_overlay_visible = true
    self.state.rules_page_index = 1
    self.state.hovered_rules_control = nil
    self.state.rules_text_scroll = 0
    self.state.rules_text_dragging = false
    self.state.rules_text_drag_start_y = 0
    self.state.rules_text_drag_start_offset = 0
    self.state.status_message = ""
end

function Controller:closeRulesOverlay()
    self.state.rules_overlay_visible = false
    self.state.hovered_rules_control = nil
    self.state.rules_text_dragging = false
end

function Controller:changeRulesPage(delta)
    local max_index = math.max(1, tonumber(self.state.rules_page_count) or 1)
    local next_index = (self.state.rules_page_index or 1) + delta
    if next_index < 1 then
        next_index = 1
    elseif next_index > max_index then
        next_index = max_index
    end
    self.state.rules_page_index = next_index
    self.state.rules_text_scroll = 0
    self.state.rules_text_dragging = false
end

function Controller:openSinglePlayerModeOverlay()
    self.state.matchmaking_overlay_visible = false
    self.state.hovered_matchmaking_control = nil
    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
    self.state.rules_overlay_visible = false
    self.state.hovered_rules_control = nil
    self.state.settings_overlay_visible = false
    self.state.hovered_settings_control = nil
    self.state.mode_overlay_visible = true
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    self.state.status_message = ""
end

function Controller:closeSinglePlayerModeOverlay()
    self.state.mode_overlay_visible = false
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    if not self.state.submitting then
        self.state.status_message = ""
    end
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
end

function Controller:syncAudioState()
    local settings = self.get_current_settings() or {}
    self.state.audio_mute_master = settings.audio_mute_master == true
end

function Controller:toggleMute()
    local next_mute = self.on_toggle_mute()
    if type(next_mute) == "boolean" then
        self.state.audio_mute_master = next_mute
    else
        self:syncAudioState()
    end
end

function Controller:openSettingsOverlay()
    self.state.matchmaking_overlay_visible = false
    self.state.hovered_matchmaking_control = nil
    self.state.wardrobe_overlay_visible = false
    self.state.hovered_wardrobe_control = nil
    self.state.rules_overlay_visible = false
    self.state.hovered_rules_control = nil
    self.state.mode_overlay_visible = false
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
    self:syncSettingsState()
    self.state.settings_overlay_visible = true
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
    self.state.hovered_settings_control = nil
    self.state.status_message = ""
end

function Controller:closeSettingsOverlay()
    self.state.settings_overlay_visible = false
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
    self.state.hovered_settings_control = nil
    self.state.status_message = ""
end

function Controller:openConfirmDialog(action_id)
    if action_id ~= "exit_game" then
        return
    end
    self.state.confirm_dialog_visible = true
    self.state.confirm_dialog_action = action_id
    self.state.hovered_confirm_dialog_control = nil
    self.state.hovered_settings_control = nil
end

function Controller:closeConfirmDialog()
    self.state.confirm_dialog_visible = false
    self.state.confirm_dialog_action = nil
    self.state.hovered_confirm_dialog_control = nil
end

function Controller:confirmDialogAction()
    local action_id = self.state.confirm_dialog_action
    self:closeConfirmDialog()
    if action_id == "exit_game" then
        self:exitGame()
    end
end

function Controller:setWindowMode(mode)
    if mode ~= "windowed" and mode ~= "fullscreen" then
        return
    end
    if self.state.settings_window_mode == mode then
        return
    end

    local ok = self.on_change_window_mode(mode)
    if not ok then
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_window_mode = mode
    self.state.status_message = ""
end

function Controller:changeResolution(delta)
    if self.state.settings_window_mode == "fullscreen" then
        return
    end

    local total = #self.state.settings_resolution_options
    if total <= 0 then
        return
    end

    local next_index = self.state.settings_resolution_index + delta
    if next_index < 1 then
        next_index = total
    elseif next_index > total then
        next_index = 1
    end

    local option = self.state.settings_resolution_options[next_index]
    local ok = self.on_change_resolution(option.width, option.height)
    if not ok then
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_resolution_index = next_index
    self.state.status_message = ""
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
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_language_index = next_index
    self.state.status_message = ""
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
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_fps_index = next_index
    self.state.status_message = ""
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
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_game_volume_index = next_index
    self.state.status_message = ""
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
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self.state.settings_bgm_volume_index = next_index
    self.state.status_message = ""
end

function Controller:resetSettings()
    local ok = self.on_reset_settings()
    if ok == false then
        self.state.status_message = I18n:t("main_menu.settings_apply_failed")
        self:syncSettingsState()
        return
    end

    self:syncAudioState()
    self:syncSettingsState()
    self.state.status_message = ""
end

function Controller:exitGame()
    self:closeConfirmDialog()
    self.on_exit_game()
end

function Controller:startSinglePlayerGame(game_mode)
    if self.state.submitting then
        return
    end

    print(string.format(
        "[main_menu] startSinglePlayerGame begin steam_id=%s mode=%s",
        tostring(self.user_profile and self.user_profile.steam_id),
        tostring(game_mode)
    ))
    self.state.submitting = true
    self.state.status_message = I18n:t("main_menu.single_player_starting")
    local result = self.service:startSinglePlayerGame(self.user_profile.steam_id, game_mode)
    self.state.submitting = false
    self.state.single_player_loading_visible = false
    self.state.single_player_loading_elapsed = 0
    self.state.single_player_loading_request_started = false
    self.state.pending_single_player_mode = nil
    print(string.format(
        "[main_menu] startSinglePlayerGame result ok=%s room_id=%s snapshot_room_id=%s",
        tostring(result and result.ok),
        tostring(result and result.room_id),
        tostring(result and result.snapshot and result.snapshot.room_id)
    ))

    if not result.ok then
        self.state.status_message = result.message or I18n:t("main_menu.single_player_failed")
        return
    end

    self.state.mode_overlay_visible = false
    self.state.status_message = ""
    print("[main_menu] invoking on_open_single_player_game")
    self.on_open_single_player_game(result)
end

function Controller:toggleMatchmaking()
    local result = self.on_toggle_matchmaking()
    if result and result.ok == false and result.message then
        self.state.status_message = result.message
        return false
    end
    self.state.status_message = ""
    return true
end

function Controller:beginSinglePlayerGameStart(game_mode)
    if self.state.submitting or self.state.single_player_loading_visible then
        return
    end

    self.state.status_message = I18n:t("main_menu.single_player_starting")
    self.state.single_player_loading_visible = true
    self.state.single_player_loading_elapsed = 0
    self.state.single_player_loading_request_started = false
    self.state.pending_single_player_mode = game_mode
    self.state.hovered_mode_option = nil
    self.state.hovered_mode_close = false
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return false
    end

    if self.state.server_loading_visible then
        return true
    end

    if self.state.single_player_loading_visible then
        return true
    end

    if self.state.matchmaking_overlay_visible then
        local control = view:getMatchmakingOverlayControlAt(x, y)
        if not control then
            return false
        end
        if control == "matchmaking_close" or control == "matchmaking_cancel" then
            self:closeMatchmakingOverlay()
            return true
        end
        return false
    end

    if self.state.wardrobe_overlay_visible then
        local control = view:getWardrobeOverlayControlAt(x, y, self.state, self.user_profile)
        if not control then
            return false
        end
        if control == "wardrobe_close" then
            self:closeWardrobeOverlay()
            return true
        end
        if control == "wardrobe_tab_equipment" then
            self:setWardrobeTab("equipment")
            return true
        end
        if control == "wardrobe_tab_shop" then
            self:setWardrobeTab("shop")
            return true
        end
        if control == "wardrobe_prev_page" then
            self:changeWardrobePage(-1)
            return true
        end
        if control == "wardrobe_next_page" then
            self:changeWardrobePage(1)
            return true
        end
        if control == "wardrobe_action" then
            self:performWardrobeAction()
            return true
        end
        local slot = control:match("^wardrobe_slot_(.+)$")
        if slot then
            self:setWardrobeSlot(slot)
            return true
        end
        local marker = control:match("^wardrobe_card_(.+)$")
        if marker then
            self:setWardrobeSelectedItem(marker)
            return true
        end
        return false
    end

    if self.state.rules_overlay_visible then
        local control = view:getRulesOverlayControlAt(x, y, self.state)
        if not control then
            if view.game_rules_overlay:isTextScrollHit(x, y, self.state.rules_page_index) then
                self.state.rules_text_dragging = true
                self.state.rules_text_drag_start_y = y
                self.state.rules_text_drag_start_offset = tonumber(self.state.rules_text_scroll) or 0
                return true
            end
            return false
        end
        if control == "rules_close" then
            self:closeRulesOverlay()
            return true
        end
        if control == "rules_prev" then
            self:changeRulesPage(-1)
            return true
        end
        if control == "rules_next" then
            self:changeRulesPage(1)
            return true
        end
        return false
    end

    if self.state.settings_overlay_visible then
        if self.state.confirm_dialog_visible then
            local control = view:getConfirmDialogControlAt(x, y, self.state)
            if control == "confirm_dialog_cancel" then
                self:closeConfirmDialog()
                return true
            end
            if control == "confirm_dialog_confirm" then
                self:confirmDialogAction()
                return true
            end
            return true
        end
        local control = view:getSettingsControlAt(x, y, self.state)
        if not control then
            return false
        end

        if control == "settings_close" then
            self:closeSettingsOverlay()
            return true
        end
        if control == "settings_mode_windowed" then
            self:setWindowMode("windowed")
            return true
        end
        if control == "settings_mode_fullscreen" then
            self:setWindowMode("fullscreen")
            return true
        end
        if control == "settings_resolution_prev" then
            self:changeResolution(-1)
            return true
        end
        if control == "settings_resolution_next" then
            self:changeResolution(1)
            return true
        end
        if control == "settings_language_prev" then
            self:changeLanguage(-1)
            return true
        end
        if control == "settings_language_next" then
            self:changeLanguage(1)
            return true
        end
        if control == "settings_fps_prev" then
            self:changeTargetFps(-1)
            return true
        end
        if control == "settings_fps_next" then
            self:changeTargetFps(1)
            return true
        end
        if control == "settings_game_volume_prev" then
            self:changeGameVolume(-1)
            return true
        end
        if control == "settings_game_volume_next" then
            self:changeGameVolume(1)
            return true
        end
        if control == "settings_bgm_volume_prev" then
            self:changeBgmVolume(-1)
            return true
        end
        if control == "settings_bgm_volume_next" then
            self:changeBgmVolume(1)
            return true
        end
        if control == "settings_reset_defaults" then
            self:resetSettings()
            return true
        end
        if control == "settings_exit_game" then
            self:openConfirmDialog("exit_game")
            return true
        end
        return false
    end

    if self.state.mode_overlay_visible then
        if view:isModeOverlayCloseHovered(x, y) then
            self:closeSinglePlayerModeOverlay()
            return true
        end

        local game_mode = view:getModeOptionAt(x, y)
        if game_mode then
            self:beginSinglePlayerGameStart(game_mode)
            return true
        end
        return false
    end

    if view:isProfileHovered(x, y) then
        self.on_open_profile_editor()
        return true
    end

    if view:isMuteIconHovered(x, y) then
        self:toggleMute()
        return true
    end

    if view:isWardrobeIconHovered(x, y) then
        self:openWardrobeOverlay()
        return true
    end

    if view:isSettingsIconHovered(x, y) then
        self:openSettingsOverlay()
        return true
    end

    local action = view:getActionAt(x, y, self.state, self.state.hovered_action)
    if not action then
        return false
    end

    if action == "single_player" then
        self:openSinglePlayerModeOverlay()
        return true
    end

    if action == "online_lobby" then
        self.state.status_message = ""
        self.on_open_lobby()
        return true
    end

    if action == "game_rules" then
        self:openRulesOverlay()
        return true
    end

    if action == "matchmaking" then
        self:toggleMatchmaking()
        return true
    end

    self.state.status_message = I18n:t("main_menu.coming_soon")
    return true
end

function Controller:mousereleased(x, y, button, view)
    if button ~= 1 then
        return false
    end
    if self.state.rules_text_dragging then
        self.state.rules_text_dragging = false
        return true
    end
    return false
end

function Controller:getResolutionLabel()
    local option = self.state.settings_resolution_options[self.state.settings_resolution_index]
    if not option then
        return "-"
    end
    return resolutionLabel(option)
end

return Controller
