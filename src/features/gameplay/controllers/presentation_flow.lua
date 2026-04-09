local I18n = require("src.core.i18n.i18n")
local Helpers = require("src.features.gameplay.controllers.helpers")

local PresentationFlow = {}

local WILDCARD_OVERLAY_DURATION = 1.8
local POST_DEAL_BUFFER_DURATION = 0
local HAND_REVEAL_SFX_ID = "hand_reveal"
local REMAINING_CARDS_PANEL_INTRO_DURATION = 0.44

local OPEN_INTRO_WEIGHT = 0.45
local OPEN_CUT_WEIGHT = 0.60
local OPEN_FLIP_WEIGHT = 0.45
local OPEN_RESTACK_WEIGHT = 0.45
local OPEN_DEAL_WEIGHT = 4.05

local CLOSED_INTRO_WEIGHT = 0.8
local CLOSED_DEAL_WEIGHT = 5.2

local function getDealOverlayDuration(state)
    local configured = tonumber(((((state or {}).game or {}).game_config or {}).deal_display_seconds) or 0) or 0
    if configured > 0 then
        return configured
    end
    return 10
end

local function hasVisibleOpenCard(game)
    game = game or {}
    return tostring(game.open_card_id or "") ~= ""
        and game.open_card_seat ~= nil
        and game.open_card_cut_count ~= nil
        and game.open_card_deal_index ~= nil
end

local function computeDealSfxStartRemaining(duration, show_open_card)
    duration = math.max(0, tonumber(duration) or 0)
    if duration <= 0 then
        return 0
    end

    local lead_in_weight = CLOSED_INTRO_WEIGHT
    local total_weight = CLOSED_INTRO_WEIGHT + CLOSED_DEAL_WEIGHT
    if show_open_card then
        lead_in_weight = OPEN_INTRO_WEIGHT + OPEN_CUT_WEIGHT + OPEN_FLIP_WEIGHT + OPEN_RESTACK_WEIGHT
        total_weight = lead_in_weight + OPEN_DEAL_WEIGHT
    end

    local deal_start_elapsed = duration * (lead_in_weight / total_weight)
    return math.max(0, duration - deal_start_elapsed)
end

function PresentationFlow.beginDealing(state)
    local show_open_card = hasVisibleOpenCard(state.game)
    local deal_duration = getDealOverlayDuration(state)
    state.ui_phase = "dealing"
    state.reveal_cards = false
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.tribute_countdown_remaining = 0
    state.tribute_countdown_duration = 0
    state.tribute_force_visible = false
    state.tribute_overlay_snapshot = nil
    state.selected_tribute_card_id = nil
    state.hovered_tribute_card_id = nil
    state.hovered_tribute_control = nil
    state.wildcard_overlay_remaining = 0
    state.deal_overlay_remaining = deal_duration
    state.deal_overlay_duration = deal_duration
    state.deal_sfx_start_remaining = computeDealSfxStartRemaining(deal_duration, show_open_card)
    state.hand_loading_remaining = 0
    state.hand_loading_duration = 0
    state.arrange_remaining = 0
    state.arrange_duration = 0
    state.status_message = I18n:t("gameplay.dealing_status")
end

function PresentationFlow.beginTribute(state)
    state.ui_phase = "tribute"
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.wildcard_overlay_remaining = 0
    state.deal_overlay_remaining = 0
    state.deal_overlay_duration = 0
    state.deal_sfx_start_remaining = 0
    state.hand_loading_remaining = 0
    state.hand_loading_duration = 0
    state.arrange_remaining = 0
    state.arrange_duration = 0
    state.arrange_hold_visible = false
    state.arrange_zero_hold = false
    state.arrange_progress_request_active = false
    state.arrange_progress_request_elapsed = 0
    local tribute = ((state.game or {}).tribute) or {}
    state.tribute_countdown_duration = tonumber(tribute.timeout_seconds or 0) or 0
    state.tribute_countdown_remaining = tonumber(tribute.countdown_remaining_seconds or 0) or 0
    state.tribute_overlay_snapshot = state.game
    state.status_message = (tribute.message) or I18n:t("gameplay.tribute_status")
end

function PresentationFlow.beginArranging(state)
    state.ui_phase = "arranging"
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.tribute_countdown_remaining = 0
    state.tribute_countdown_duration = 0
    state.tribute_force_visible = false
    state.tribute_overlay_snapshot = nil
    state.wildcard_overlay_remaining = 0
    state.deal_overlay_remaining = 0
    state.deal_overlay_duration = 0
    state.deal_sfx_start_remaining = 0
    state.hand_loading_remaining = 0
    state.hand_loading_duration = 0
    state.arrange_remaining = 0
    state.arrange_duration = 0
    state.status_message = I18n:t("gameplay.arranging_status")
end

function PresentationFlow.beginHandLoading(controller)
    local state = controller.state
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.tribute_countdown_remaining = 0
    state.tribute_countdown_duration = 0
    state.tribute_force_visible = false
    state.tribute_overlay_snapshot = nil
    state.wildcard_overlay_remaining = 0
    state.deal_overlay_remaining = 0
    state.deal_overlay_duration = 0
    state.deal_sfx_start_remaining = 0
    state.arrange_duration = tonumber(((state.game or {}).arrange_timeout_seconds) or 0) or 0
    state.arrange_hold_visible = true
    state.arrange_zero_hold = false
    state.hand_loading_duration = POST_DEAL_BUFFER_DURATION
    state.hand_loading_remaining = POST_DEAL_BUFFER_DURATION
    state.reveal_cards = true
    state.status_message = ""
    controller:playSfx(HAND_REVEAL_SFX_ID)
    state.ui_phase = "hand_loading"
end

function PresentationFlow.revealHand(controller)
    PresentationFlow.beginHandLoading(controller)
end

function PresentationFlow.beginHandPresentation(state)
    state.selected_card_ids = {}
    state.pinned_card_ids = {}
    state.pinned_card_groups = {}
    state.hovered_card_id = nil
    state.hovered_control = nil
    state.hovered_player_hud_role = nil
    state.selected_tribute_card_id = nil
    state.hovered_tribute_card_id = nil
    state.hovered_tribute_control = nil
    state.show_round_info_overlay = false
    state.round_info_active_tab = "history"
    state.hovered_round_info_button = false
    state.hovered_round_info_overlay_control = nil
    state.show_player_profile_overlay = false
    state.hovered_player_profile_control = nil
    state.profile_overlay_player = nil
    state.action_waiting = false
    state.reveal_cards = false
    state.fatal_error_message = ""
    state.settlement_button_hovered = false
    state.settlement_countdown_remaining = 0
    state.settlement_countdown_duration = 0
    state.tribute_overlay_remaining = 0
    state.tribute_notice_remaining = 0
    state.tribute_countdown_remaining = 0
    state.tribute_countdown_duration = 0
    state.tribute_force_visible = false
    state.tribute_overlay_snapshot = nil
    state.hand_loading_remaining = 0
    state.hand_loading_duration = 0
    state.arrange_duration = 0
    state.arrange_hold_visible = false
    state.result_revealed_hands = nil

    local game_mode = tostring(((state.game or {}).game_config or {}).game_mode or "classic")
    if Helpers.hasActiveTribute(state.game) then
        -- If the new-hand snapshot already entered tribute/anti-tribute,
        -- go straight to that overlay instead of replaying the dealing phase.
        PresentationFlow.beginTribute(state)
    elseif game_mode == "level" and state.game.is_first_hand == false then
        PresentationFlow.beginDealing(state)
    elseif state.game.wildcard_card and state.game.wildcard_card ~= state.game.previous_wildcard_card then
        state.ui_phase = "wildcard"
        state.wildcard_overlay_remaining = WILDCARD_OVERLAY_DURATION
        state.deal_overlay_remaining = 0
        state.deal_sfx_start_remaining = 0
        state.arrange_remaining = 0
        state.arrange_duration = 0
        state.status_message = I18n:t("gameplay.wildcard_status")
    else
        PresentationFlow.beginDealing(state)
    end
end

function PresentationFlow.update(controller, dt)
    local state = controller.state

    if state.toast_remaining > 0 then
        state.toast_remaining = math.max(0, state.toast_remaining - dt)
        if state.toast_remaining <= 0 then
            state.toast_message = ""
            state.toast_duration = 0
        end
    end

    if state.ui_phase == "settlement" and state.settlement_countdown_remaining > 0 then
        state.settlement_countdown_remaining = math.max(0, state.settlement_countdown_remaining - dt)
    end

    if state.ui_phase == "remaining_cards" then
        local previous_reveal_remaining = math.max(0, tonumber(state.remaining_cards_reveal_remaining) or 0)
        state.remaining_cards_reveal_remaining = math.max(0, previous_reveal_remaining - dt)
        if previous_reveal_remaining > 0 and state.remaining_cards_reveal_remaining <= 0 then
            state.remaining_cards_intro_duration = REMAINING_CARDS_PANEL_INTRO_DURATION
            state.remaining_cards_intro_remaining = REMAINING_CARDS_PANEL_INTRO_DURATION
        end
        state.remaining_cards_intro_remaining = math.max(0, (tonumber(state.remaining_cards_intro_remaining) or 0) - dt)
        state.remaining_cards_countdown_remaining = math.max(0, (tonumber(state.remaining_cards_countdown_remaining) or 0) - dt)
        return
    end

    if state.ui_phase == "tribute" then
        local tribute_game = state.game or {}
        if state.tribute_force_visible == true
            and not Helpers.hasActiveTribute(tribute_game)
            and state.tribute_overlay_snapshot ~= nil
        then
            tribute_game = state.tribute_overlay_snapshot
        end
        local tribute = (tribute_game.tribute) or {}
        state.tribute_countdown_remaining = math.max(0, state.tribute_countdown_remaining - dt)
        state.status_message = (tribute.message) or I18n:t("gameplay.tribute_status")
        if state.tribute_force_visible == true
            and state.tribute_countdown_remaining <= 0
            and not Helpers.hasActiveTribute(state.game)
        then
            state.tribute_force_visible = false
            state.tribute_overlay_snapshot = nil
            if tostring(((state.game or {}).phase) or "") == "dealing" then
                PresentationFlow.beginDealing(state)
            elseif state.reveal_cards then
                state.ui_phase = "playing"
            else
                PresentationFlow.beginHandLoading(controller)
            end
        end
        return
    end

    if state.ui_phase == "wildcard" and state.wildcard_overlay_remaining > 0 then
        state.wildcard_overlay_remaining = math.max(0, state.wildcard_overlay_remaining - dt)
        if state.wildcard_overlay_remaining <= 0 then
            local show_open_card = hasVisibleOpenCard(state.game)
            local deal_duration = getDealOverlayDuration(state)
            state.ui_phase = "dealing"
            state.deal_overlay_remaining = deal_duration
            state.deal_overlay_duration = deal_duration
            state.deal_sfx_start_remaining = computeDealSfxStartRemaining(deal_duration, show_open_card)
            state.status_message = I18n:t("gameplay.dealing_status")
        end
        return
    end

    if state.ui_phase == "dealing" and state.deal_overlay_remaining > 0 then
        state.deal_overlay_remaining = math.max(0, state.deal_overlay_remaining - dt)
        if state.deal_overlay_remaining <= 0 then
            state.deal_overlay_remaining = 0
            state.deal_sfx_start_remaining = 0
            if Helpers.hasActiveTribute(state.game) then
                PresentationFlow.beginTribute(state)
            elseif not state.reveal_cards then
                PresentationFlow.beginHandLoading(controller)
            end
        end
        return
    end

    if state.ui_phase == "hand_loading" then
        state.hand_loading_remaining = math.max(0, state.hand_loading_remaining - dt)
        if state.hand_loading_remaining <= 0 then
            state.hand_loading_remaining = 0
            state.hand_loading_duration = 0
            state.ui_phase = "playing"
            state.arrange_duration = tonumber(((state.game or {}).arrange_timeout_seconds) or 0) or 0
            state.arrange_remaining = tonumber(((state.game or {}).arrange_countdown_remaining_seconds) or 0) or 0
        end
        return
    end

    if state.ui_phase == "playing" and (tonumber(state.arrange_remaining) or 0) > 0 then
        state.arrange_remaining = math.max(0, (tonumber(state.arrange_remaining) or 0) - dt)
    end
end

return PresentationFlow
