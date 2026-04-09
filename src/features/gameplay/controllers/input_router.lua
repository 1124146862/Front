local I18n = require("src.core.i18n.i18n")
local Actions = require("src.features.gameplay.controllers.actions")

local InputRouter = {}
local HAND_HISTORY_MAX_VISIBLE_ROWS = 3

local function newPreviewSeed()
    local seed = os.time()
    if love.timer and love.timer.getTime then
        seed = seed + math.floor(love.timer.getTime() * 100000)
    end
    return seed
end

local function resolveBackgroundThemeId(control)
    if control == "settings_background_spring" then
        return "spring"
    end
    if control == "settings_background_summer" then
        return "summer"
    end
    if control == "settings_background_autumn" then
        return "autumn"
    end
    if control == "settings_background_winter" then
        return "winter"
    end
    if control == "settings_background_cosmos" then
        return "cosmos"
    end
    if control == "settings_background_nebula" then
        return "nebula"
    end
    if control == "settings_background_galaxy" then
        return "galaxy"
    end
    if control == "settings_background_warp" then
        return "warp"
    end
    return nil
end

local function parsePlayerProfileRole(control)
    if type(control) ~= "string" then
        return nil
    end
    return control:match("^open_player_profile:(.+)$")
end

local function canInteractWithHand(state)
    if not state or not state.reveal_cards then
        return false
    end
    local phase = tostring(state.ui_phase or "")
    return phase == "playing" or phase == "hand_loading"
end

function InputRouter.mousemoved(controller, x, y, view)
    local state = controller.state

    if state.server_loading_visible then
        state.hovered_settings_control = nil
        state.hovered_confirm_dialog_control = nil
        state.hovered_settings_button = false
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.hovered_control = nil
        state.hovered_card_id = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        state.hovered_player_hud_role = nil
        state.hovered_player_profile_control = nil
        return
    end

    if state.settings_overlay_visible then
        if state.confirm_dialog_visible then
            state.hovered_confirm_dialog_control = view:getConfirmDialogControlAt(x, y, state)
            state.hovered_settings_control = nil
            state.hovered_settings_button = false
            state.hovered_round_info_button = false
            state.hovered_round_info_overlay_control = nil
            state.hovered_debug_button = false
            state.hovered_control = nil
            state.hovered_card_id = nil
            state.hovered_tribute_card_id = nil
            state.hovered_tribute_control = nil
            state.hovered_player_hud_role = nil
            state.hovered_player_profile_control = nil
            return
        end
        state.hovered_confirm_dialog_control = nil
        state.hovered_settings_control = view:getSettingsControlAt(x, y, state)
        state.hovered_settings_button = false
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.hovered_control = nil
        state.hovered_card_id = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        state.hovered_player_hud_role = nil
        state.hovered_player_profile_control = nil
        return
    end

    if state.show_player_profile_overlay then
        state.hovered_player_profile_control = view:getPlayerProfileControlAt(x, y, state)
        state.hovered_settings_button = false
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.hovered_control = nil
        state.hovered_card_id = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        state.hovered_player_hud_role = nil
        return
    end

    state.hovered_player_profile_control = nil
    state.hovered_settings_button = view:getSettingsControlAt(x, y, state) == "open_settings"

    if state.show_round_info_overlay then
        state.hovered_round_info_overlay_control = view:getRoundInfoControlAt(x, y, state)
        state.hovered_round_info_button = false
        state.hovered_debug_button = false
        state.hovered_settings_button = false
        state.hovered_control = nil
        state.hovered_card_id = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        state.hovered_player_hud_role = nil
        return
    end

    if state.ui_phase == "remaining_cards" or state.ui_phase == "settlement" then
        state.remaining_cards_button_hovered = view:getRemainingCardsControlAt(x, y, state) == "close_remaining_cards"
        state.settlement_button_hovered = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.hovered_control = view:getMuteControlAt(x, y)
        state.hovered_card_id = nil
        state.hovered_player_hud_role = nil
        return
    end

    if state.ui_phase == "rematch" then
        local control = view:getRematchControlAt(x, y, state)
        state.rematch_confirm_button_hovered = control == "confirm_rematch"
        state.rematch_leave_button_hovered = control == "leave_to_main_menu"
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.hovered_control = view:getMuteControlAt(x, y)
        state.hovered_card_id = nil
        state.hovered_player_hud_role = nil
        return
    end

    state.hovered_debug_button = view:getDebugControlAt(x, y, state) == "debug_autoplay_hand"

    if state.ui_phase == "tribute" then
        state.hovered_tribute_control = view:getTributeControlAt(x, y, state)
        state.hovered_tribute_card_id = view:getTributeHoveredCardId(x, y, state)
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_control = view:getMuteControlAt(x, y)
        state.hovered_card_id = nil
        state.hovered_player_hud_role = nil
        return
    end

    state.hovered_player_hud_role = view:getHudRoleAt(x, y, state)
    state.hovered_round_info_button = view:getRoundInfoControlAt(x, y, state) == "open_round_info"
    state.hovered_control = view:getControlAt(x, y, state)
    if not canInteractWithHand(state) then
        state.hovered_card_id = nil
        return
    end
    state.hovered_card_id = view:getHoveredCardId(x, y, state)
end

function InputRouter.mousepressed(controller, x, y, button, view)
    local state = controller.state

    if button ~= 1 then
        return false
    end

    if state.server_loading_visible then
        return true
    end

    if state.settings_overlay_visible then
        if state.confirm_dialog_visible then
            local control = view:getConfirmDialogControlAt(x, y, state)
            if control == "confirm_dialog_cancel" then
                controller:closeConfirmDialog()
                return true
            end
            if control == "confirm_dialog_confirm" then
                controller:confirmDialogAction()
                return true
            end
            return true
        end
        local control = view:getSettingsControlAt(x, y, state)
        local preview_theme = resolveBackgroundThemeId(control)
        if preview_theme then
            state.settings_background_preview_theme_id = preview_theme
            state.settings_background_preview_seed = newPreviewSeed()
        end
        if control == "settings_close" then
            controller:closeSettingsOverlay()
            return true
        end
        if control == "settings_tab_display_audio" then
            controller:setSettingsTab("display_audio")
            return true
        end
        if control == "settings_tab_background" then
            controller:setSettingsTab("background")
            return true
        end
        if control == "settings_tab_cards" then
            controller:setSettingsTab("cards")
            return true
        end
        if control == "settings_mode_windowed" then
            controller:setWindowMode("windowed")
            return true
        end
        if control == "settings_mode_fullscreen" then
            controller:setWindowMode("fullscreen")
            return true
        end
        if control == "settings_resolution_prev" then
            controller:changeResolution(-1)
            return true
        end
        if control == "settings_resolution_next" then
            controller:changeResolution(1)
            return true
        end
        if control == "settings_language_prev" then
            controller:changeLanguage(-1)
            return true
        end
        if control == "settings_language_next" then
            controller:changeLanguage(1)
            return true
        end
        if control == "settings_fps_prev" then
            controller:changeTargetFps(-1)
            return true
        end
        if control == "settings_fps_next" then
            controller:changeTargetFps(1)
            return true
        end
        if control == "settings_game_volume_prev" then
            controller:changeGameVolume(-1)
            return true
        end
        if control == "settings_game_volume_next" then
            controller:changeGameVolume(1)
            return true
        end
        if control == "settings_bgm_volume_prev" then
            controller:changeBgmVolume(-1)
            return true
        end
        if control == "settings_bgm_volume_next" then
            controller:changeBgmVolume(1)
            return true
        end
        if control == "settings_game_bgm_prev" then
            controller:changeGameBgm(-1)
            return true
        end
        if control == "settings_game_bgm_next" then
            controller:changeGameBgm(1)
            return true
        end
        if control == "settings_reset_defaults" then
            controller:resetSettings()
            return true
        end
        if control == "settings_back_to_main_menu" then
            controller:openConfirmDialog("back_to_main_menu")
            return true
        end
        if control == "settings_exit_game" then
            controller:openConfirmDialog("exit_game")
            return true
        end
        if preview_theme then
            controller:setBackgroundTheme(preview_theme)
            return true
        end
        if control == "settings_cards_high_contrast_toggle" then
            controller:toggleCardHighContrast()
            return true
        end
        if control == "settings_cards_theme_prev" then
            controller:cycleCardTheme(-1)
            return true
        end
        if control == "settings_cards_theme_next" then
            controller:cycleCardTheme(1)
            return true
        end
        if control == "settings_cards_back_prev" then
            controller:cycleCardBack(-1)
            return true
        end
        if control == "settings_cards_back_next" then
            controller:cycleCardBack(1)
            return true
        end
        return false
    end

    if state.show_player_profile_overlay then
        local control = view:getPlayerProfileControlAt(x, y, state)
        if control == "close_player_profile" then
            controller:closePlayerProfile()
            return true
        end
        return true
    end

    if view:getSettingsControlAt(x, y, state) == "open_settings" then
        controller:openSettingsOverlay()
        return true
    end

    if view:getMuteControlAt(x, y) == "toggle_mute_button" then
        controller:toggleMute()
        return true
    end

    if state.show_round_info_overlay then
        local control = view:getRoundInfoControlAt(x, y, state)
        if control == "close_round_info" then
            state.show_round_info_overlay = false
            state.hovered_round_info_overlay_control = nil
            return true
        end
        if control == "round_info_tab_history" then
            state.round_info_active_tab = "history"
            return true
        end
        if control == "round_info_tab_tribute" then
            state.round_info_active_tab = "tribute"
            return true
        end
        return true
    end

    local control = view:getControlAt(x, y, state)
    local profile_role = parsePlayerProfileRole(control)
    if profile_role then
        controller:openPlayerProfile(profile_role)
        return true
    end

    if state.ui_phase == "remaining_cards" or state.ui_phase == "settlement" then
        local control = view:getRemainingCardsControlAt(x, y, state)
        if control == "close_remaining_cards" then
            local game_phase = tostring(((state.game or {}).phase) or "")
            if game_phase == "settlement" then
                Actions.startNextHand(controller)
            else
                Actions.skipRemainingCardsView(controller)
            end
            return true
        end
        return false
    end

    if state.ui_phase == "rematch" then
        local control = view:getRematchControlAt(x, y, state)
        if control == "confirm_rematch" then
            Actions.confirmRematch(controller)
            return true
        elseif control == "leave_to_main_menu" then
            controller:leaveToMainMenu()
            return true
        end
        return false
    end

    if state.ui_phase == "tribute" then
        local debug_control = view:getDebugControlAt(x, y, state)
        if debug_control == "debug_autoplay_hand" then
            Actions.debugAutoplayHand(controller)
            return true
        end
        local control = view:getTributeControlAt(x, y, state)
        if control == "rank_hand_cards" then
            Actions.rankHandCards(controller)
            return true
        end
        if control == "pin_selected_cards" then
            Actions.pinSelectedCards(controller)
            return true
        end
        if control == "submit_tribute" or control == "submit_return_tribute" then
            Actions.submitTributeCard(controller)
            return true
        end

        local card_id = view:getTributeHoveredCardId(x, y, state)
        if not card_id then
            return false
        end

        local allowed_cards = {}
        for _, allowed_id in ipairs((((state.game or {}).tribute) or {}).candidate_cards or {}) do
            allowed_cards[allowed_id] = true
        end

        if state.selected_card_ids[card_id] then
            state.selected_card_ids[card_id] = nil
        else
            state.selected_card_ids[card_id] = true
        end

        if allowed_cards[card_id] then
            if state.selected_tribute_card_id == card_id then
                state.selected_tribute_card_id = nil
            else
                state.selected_tribute_card_id = card_id
            end
        end
        controller:playSfx("card_click")
        return false
    end

    local round_info_control = view:getRoundInfoControlAt(x, y, state)
    if round_info_control == "open_round_info" then
        state.show_round_info_overlay = true
        state.round_info_active_tab = "history"
        state.hand_history_scroll = 0
        return true
    end

    if not canInteractWithHand(state) then
        return false
    end

    local debug_control = view:getDebugControlAt(x, y, state)
    if debug_control == "debug_autoplay_hand" then
        Actions.debugAutoplayHand(controller)
        return true
    end

    if state.ui_phase == "playing" and control == "rank_hand_cards" then
        Actions.rankHandCards(controller)
        return true
    end
    if state.ui_phase == "playing" and control == "pin_selected_cards" then
        Actions.pinSelectedCards(controller)
        return true
    end
    if state.ui_phase == "playing" and control == "play_cards" then
        if state.pending_button_action then
            return true
        end
        controller:triggerButtonPressFeedback("play_cards")
        controller:queueButtonAction("play_cards")
        Actions.playSelectedCards(controller)
        return true
    end
    if state.ui_phase == "playing" and control == "pass_turn" then
        if state.pending_button_action then
            return true
        end
        controller:triggerButtonPressFeedback("pass_turn")
        controller:queueButtonAction("pass_turn")
        Actions.passTurn(controller)
        return true
    end

    local card_id = view:getClickedCardId(x, y, state)
    if not card_id then
        return false
    end

    if state.selected_card_ids[card_id] then
        state.selected_card_ids[card_id] = nil
    else
        state.selected_card_ids[card_id] = true
    end
    controller:playSfx("card_click")
    return false
end

function InputRouter.mousereleased(controller, x, y, button, view)
    local state = controller.state
    if button ~= 1 then
        return false
    end
    if state.settings_background_preview_theme_id then
        state.settings_background_preview_theme_id = nil
        state.settings_background_preview_seed = nil
        return true
    end
    return false
end

function InputRouter.wheelmoved(controller, x, y, view)
    local state = controller.state
    if state.server_loading_visible or state.settings_overlay_visible or state.show_player_profile_overlay then
        return false
    end
    if not state.show_round_info_overlay or state.round_info_active_tab ~= "history" then
        return false
    end
    if y == 0 then
        return false
    end

    local delta = y < 0 and 1 or -1
    local total = #(state.play_history_entries or {})
    local max_scroll = math.max(total - HAND_HISTORY_MAX_VISIBLE_ROWS, 0)
    state.hand_history_scroll = math.max(0, math.min(max_scroll, (tonumber(state.hand_history_scroll) or 0) + delta))
    return true
end

function InputRouter.keypressed(controller, key)
    local state = controller.state
    if state.server_loading_visible then
        return
    end
    if key == "escape" then
        if state.settings_overlay_visible then
            if state.confirm_dialog_visible then
                controller:closeConfirmDialog()
                return
            end
            controller:closeSettingsOverlay()
            return
        end
        if state.show_player_profile_overlay then
            controller:closePlayerProfile()
            return
        end
        if state.show_round_info_overlay then
            state.show_round_info_overlay = false
            state.hovered_round_info_button = false
            state.hovered_round_info_overlay_control = nil
            return
        end
        state.selected_card_ids = {}
        state.selected_tribute_card_id = nil
        state.hovered_card_id = nil
        state.hovered_control = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        state.hovered_player_hud_role = nil
        state.hovered_player_profile_control = nil
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.hovered_debug_button = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
    end
end

return InputRouter
