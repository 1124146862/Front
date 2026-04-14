local PresentationFlow = require("src.features.gameplay.controllers.presentation_flow")
local Helpers = require("src.features.gameplay.controllers.helpers")
local GameplayConfig = require("src.features.gameplay.gameplay_config")
local AvatarRegistry = require("src.features.session.avatars.registry")

local SnapshotApplier = {}
local PINNED_GROUP_MAX_COUNT = 6
local HAND_HISTORY_MAX_VISIBLE_ROWS = 3
local RESULT_TRANSITION_DURATION = 1.5
local AVAILABLE_AVATAR_IDS = {}

for _, avatar in ipairs(AvatarRegistry or {}) do
    local avatar_id = tostring((avatar or {}).id or "")
    if avatar_id ~= "" then
        AVAILABLE_AVATAR_IDS[#AVAILABLE_AVATAR_IDS + 1] = avatar_id
    end
end

if #AVAILABLE_AVATAR_IDS == 0 then
    for index = 1, 45 do
        AVAILABLE_AVATAR_IDS[#AVAILABLE_AVATAR_IDS + 1] = ("avatar_%d"):format(index)
    end
end

local function randomInt(max_value)
    if max_value <= 1 then
        return 1
    end
    if love and love.math and type(love.math.random) == "function" then
        return love.math.random(max_value)
    end
    return math.random(max_value)
end

local function pickRandomAvatarId(used_avatar_ids)
    local candidates = {}
    for _, avatar_id in ipairs(AVAILABLE_AVATAR_IDS) do
        if not used_avatar_ids[avatar_id] then
            candidates[#candidates + 1] = avatar_id
        end
    end
    if #candidates == 0 then
        candidates = AVAILABLE_AVATAR_IDS
    end
    return candidates[randomInt(#candidates)]
end

local function getBotAvatarSlotKey(player, fallback_index)
    local seat_index = tonumber((player or {}).seat_index)
    if seat_index ~= nil then
        return ("seat:%d"):format(seat_index)
    end

    local player_id = tostring((player or {}).player_id or "")
    if player_id ~= "" then
        return "player_id:" .. player_id
    end

    local steam_id = tostring((player or {}).steam_id or "")
    if steam_id ~= "" then
        return "steam_id:" .. steam_id
    end

    return "bot:" .. tostring(fallback_index or 0)
end

local function maybeAssignSinglePlayerBotAvatars(state, game)
    local game_config = (game or {}).game_config or {}
    if game_config.is_single_player ~= true then
        return
    end

    local players = (game or {}).players
    if type(players) ~= "table" or #players == 0 then
        return
    end

    state.single_player_bot_avatar_by_seat = state.single_player_bot_avatar_by_seat or {}
    local avatar_by_seat = state.single_player_bot_avatar_by_seat
    local used_avatar_ids = {}

    for index, player in ipairs(players) do
        local explicit_avatar_id = tostring((player or {}).avatar_id or "")
        if explicit_avatar_id ~= "" then
            used_avatar_ids[explicit_avatar_id] = true
        end
        if (player or {}).is_bot == true then
            local seat_key = getBotAvatarSlotKey(player, index)
            if explicit_avatar_id ~= "" then
                avatar_by_seat[seat_key] = explicit_avatar_id
            end
        end
    end

    for index, player in ipairs(players) do
        if (player or {}).is_bot == true then
            local explicit_avatar_id = tostring((player or {}).avatar_id or "")
            if explicit_avatar_id == "" then
                local seat_key = getBotAvatarSlotKey(player, index)
                local mapped_avatar_id = tostring(avatar_by_seat[seat_key] or "")
                if mapped_avatar_id == "" then
                    mapped_avatar_id = pickRandomAvatarId(used_avatar_ids)
                    avatar_by_seat[seat_key] = mapped_avatar_id
                end
                player.avatar_id = mapped_avatar_id
                used_avatar_ids[mapped_avatar_id] = true
            end
        end
    end
end

function SnapshotApplier.prepareSnapshot(state, snapshot)
    local prepared = snapshot or {}
    maybeAssignSinglePlayerBotAvatars(state or {}, prepared)
    if type((state or {}).card_theme_config) == "table" then
        state.card_theme_config.wildcard_card = prepared.wildcard_card
    end
    return prepared
end

local function copyRevealedHands(rows)
    local copied = {}
    for _, seat_info in ipairs(rows or {}) do
        copied[#copied + 1] = {
            seat_index = seat_info and seat_info.seat_index or nil,
            hand_cards = seat_info and seat_info.hand_cards or {},
        }
    end
    return copied
end

local function getLastActionEntry(game)
    local last_action = (game or {}).last_action
    if type(last_action) == "table" and next(last_action) ~= nil then
        return last_action, tonumber(last_action.turn_index) or 0
    end
    local history = ((game or {}).history) or {}
    local count = #history
    return history[count], count
end

local function buildHistorySignature(entry, fallback_index)
    if type(entry) ~= "table" then
        return ""
    end
    return table.concat({
        tostring(entry.turn_index or fallback_index or 0),
        tostring(entry.seat_index or entry.actor_seat or entry.player_seat or -1),
        tostring(entry.action_type or ""),
        tostring(entry.command_id or ""),
    }, "|")
end

local function getEntrySeat(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return tonumber(entry.seat_index or entry.actor_seat or entry.player_seat)
end

local function getMyTeamId(game)
    local my_seat = tonumber((game or {}).my_seat_index)
    for _, player in ipairs(((game or {}).players) or {}) do
        if tonumber(player.seat_index) == my_seat then
            return tonumber(player.team_id)
        end
    end
    if my_seat ~= nil then
        return my_seat % 2
    end
    return nil
end

local function applyAntiTributeForceVisible(controller, state, current_game, current_tribute)
    local my_team_id = getMyTeamId(current_game)
    local anti_team_id = tonumber((current_tribute or {}).anti_tribute_team_id)
    local anti_duration = tonumber((current_tribute or {}).timeout_seconds or 0) or 0
    if anti_duration <= 0 then
        anti_duration = 6
    end

    state.tribute_force_visible = true
    state.tribute_overlay_snapshot = current_game
    state.tribute_countdown_duration = anti_duration
    state.tribute_countdown_remaining = anti_duration

    if my_team_id ~= nil and anti_team_id ~= nil and my_team_id == anti_team_id then
        controller:playSfx("win_round")
    else
        controller:playSfx("failed_round")
    end
end

local function getSeatHandCount(game, seat_index)
    local seat = tonumber(seat_index)
    if seat == nil then
        return nil
    end

    local my_seat = tonumber((game or {}).my_seat_index)
    if my_seat ~= nil and seat == my_seat then
        local my_hand_cards = ((game or {}).my_hand_cards) or {}
        return #my_hand_cards
    end

    for _, player in ipairs(((game or {}).players) or {}) do
        if tonumber(player.seat_index) == seat then
            return tonumber(player.hand_count) or 0
        end
    end
    return nil
end

local function maybeTriggerLowHandCountAlerts(controller, previous_game, current_game)
    local threshold = tonumber(GameplayConfig.low_hand_count_alert_threshold) or 10
    local sfx_ids = GameplayConfig.low_hand_count_alert_sfx_ids or { "hand_count_alert" }
    if type(previous_game) ~= "table" or type(current_game) ~= "table" then
        return
    end
    if tostring(current_game.phase or "") ~= "playing" then
        return
    end
    if previous_game.game_id == nil or previous_game.hand_no ~= current_game.hand_no then
        return
    end

    local triggered = false
    for seat_index = 0, 3 do
        local previous_count = getSeatHandCount(previous_game, seat_index)
        local current_count = getSeatHandCount(current_game, seat_index)
        if previous_count ~= nil and current_count ~= nil then
            if previous_count > threshold and current_count > 0 and current_count <= threshold then
                if controller:startHandCountAlert(seat_index) then
                    triggered = true
                end
            end
        end
    end

    if triggered then
        for _, sfx_id in ipairs(sfx_ids) do
            if tostring(sfx_id or "") ~= "" then
                controller:playSfx(sfx_id)
            end
        end
    end
end

local function maybeTriggerPlayerFinishedAlert(controller, previous_game, current_game)
    if type(previous_game) ~= "table" or type(current_game) ~= "table" then
        return
    end
    if previous_game.game_id == nil or previous_game.hand_no ~= current_game.hand_no then
        return
    end

    for seat_index = 0, 3 do
        local previous_count = getSeatHandCount(previous_game, seat_index)
        local current_count = getSeatHandCount(current_game, seat_index)
        if previous_count ~= nil and current_count ~= nil then
            if previous_count > 0 and current_count == 0 then
                controller:playSfx("hand_count_alert")
                return
            end
        end
    end
end

local function resolvePlaySfxId(entry)
    local pattern_type = tostring((entry or {}).pattern_type or "")
    if pattern_type == "bomb" or pattern_type == "straight_flush" or pattern_type == "joker_bomb" then
        return "bomb_sound"
    end
    return "play_card"
end

local function flattenPinnedGroups(groups)
    local flat = {}
    for _, group in ipairs(groups or {}) do
        local cards = group and (group.cards or group) or {}
        for _, card_id in ipairs(cards) do
            flat[#flat + 1] = card_id
        end
    end
    return flat
end

local function buildPassMarkers(game)
    local explicit_pass_seats = ((game or {}).pass_seats) or {}
    if #explicit_pass_seats > 0 then
        local markers = {}
        for _, seat_index in ipairs(explicit_pass_seats) do
            markers[tonumber(seat_index)] = true
        end
        return markers
    end

    local markers = {}
    local latest_action_by_seat = {}
    local history = (game or {}).history or {}
    for index = #history, 1, -1 do
        local entry = history[index] or {}
        local seat = getEntrySeat(entry)
        local action_type = tostring(entry.action_type or "")
        if seat ~= nil and latest_action_by_seat[seat] == nil then
            latest_action_by_seat[seat] = action_type
        end
    end

    local current_actor = tonumber((game or {}).current_actor_seat)
    for seat, action_type in pairs(latest_action_by_seat) do
        if action_type == "pass" and seat ~= current_actor then
            markers[seat] = true
        end
    end

    return markers
end

local function isTrackablePlayHistoryEntry(entry)
    local action_type = tostring((entry or {}).action_type or "")
    return action_type == "play" or action_type == "pass"
end

local function findPlayerBySeat(game, seat_index)
    local target_seat = tonumber(seat_index)
    if target_seat == nil then
        return nil
    end
    for _, player in ipairs(((game or {}).players) or {}) do
        if tonumber(player.seat_index) == target_seat then
            return player
        end
    end
    return nil
end

local function buildPlayHistoryRow(game, entry, fallback_index)
    if not isTrackablePlayHistoryEntry(entry) then
        return nil
    end

    local seat_index = getEntrySeat(entry)
    if seat_index == nil then
        return nil
    end

    local player = findPlayerBySeat(game, seat_index) or {}
    return {
        signature = buildHistorySignature(entry, fallback_index),
        turn_index = tonumber((entry or {}).turn_index) or tonumber(fallback_index) or 0,
        seat_index = seat_index,
        role_key = Helpers.getRelativePositionKey((game or {}).my_seat_index or 0, seat_index),
        role_label = Helpers.getRelativePositionLabel((game or {}).my_seat_index or 0, seat_index),
        avatar_id = tostring(player.avatar_id or "avatar_1"),
        accessories = player.accessories,
        action_type = tostring((entry or {}).action_type or ""),
        cards = Helpers.sortPinnedGroupCards((entry or {}).cards or {}, {
            pattern_type = (entry or {}).pattern_type,
            card_count = #((entry or {}).cards or {}),
            wildcard_card = (game or {}).wildcard_card,
        }),
    }
end

local function clearPlayHistoryState(state, hand_no)
    state.play_history_hand_no = hand_no
    state.play_history_last_seen_signature = ""
    state.play_history_entries = {}
    state.play_history_signatures = {}
    state.hand_history_scroll = 0
end

local function appendPlayHistoryRow(state, row)
    if type(row) ~= "table" then
        return false
    end

    local signature = tostring(row.signature or "")
    state.play_history_signatures = state.play_history_signatures or {}
    state.play_history_entries = state.play_history_entries or {}
    if signature ~= "" and state.play_history_signatures[signature] then
        return false
    end

    row.display_index = #state.play_history_entries + 1
    table.insert(state.play_history_entries, row)
    if signature ~= "" then
        state.play_history_signatures[signature] = true
    end

    return true
end

local function clampPlayHistoryScroll(state)
    local max_scroll = math.max(#(state.play_history_entries or {}) - HAND_HISTORY_MAX_VISIBLE_ROWS, 0)
    state.hand_history_scroll = math.max(0, math.min(max_scroll, tonumber(state.hand_history_scroll) or 0))
end

local function rebuildPlayHistoryState(state, current_game)
    local current_hand_no = tostring((current_game or {}).hand_no or "")
    local previous_scroll = tonumber((state or {}).hand_history_scroll) or 0
    local last_action, fallback_index = getLastActionEntry(current_game)

    state.play_history_hand_no = current_hand_no
    state.play_history_last_seen_signature = buildHistorySignature(last_action, fallback_index)
    state.play_history_entries = {}
    state.play_history_signatures = {}

    for index, entry in ipairs((current_game or {}).history or {}) do
        appendPlayHistoryRow(state, buildPlayHistoryRow(current_game, entry, index))
    end

    state.hand_history_scroll = previous_scroll
    clampPlayHistoryScroll(state)
end

local function syncPlayHistoryState(state, current_game)
    local current_hand_no = tostring((current_game or {}).hand_no or "")
    local last_action, fallback_index = getLastActionEntry(current_game)
    local current_signature = buildHistorySignature(last_action, fallback_index)
    if state.play_history_hand_no ~= current_hand_no then
        clearPlayHistoryState(state, current_hand_no)
        state.play_history_last_seen_signature = current_signature
        return
    end

    if current_signature == "" or current_signature == tostring(state.play_history_last_seen_signature or "") then
        clampPlayHistoryScroll(state)
        return
    end

    appendPlayHistoryRow(state, buildPlayHistoryRow(current_game, last_action, fallback_index))
    state.play_history_last_seen_signature = current_signature

    clampPlayHistoryScroll(state)
end

local function hasTributeInfo(game)
    if tostring(((game or {}).game_config or {}).game_mode or "classic") ~= "level" then
        return false
    end
    for _, entry in ipairs((game or {}).history or {}) do
        local action_type = tostring((entry or {}).action_type or "")
        if action_type == "tribute" or action_type == "return_tribute" or action_type == "anti_tribute" then
            return true
        end
    end
    return false
end

function SnapshotApplier.seedPlayHistory(state, game)
    syncPlayHistoryState(state or {}, game or {})
end

function SnapshotApplier.refreshLocalizedPresentation(state)
    local safe_state = state or {}
    safe_state.last_play = Helpers.buildLastPlayViewModel(safe_state.game)
    rebuildPlayHistoryState(safe_state, safe_state.game or {})
end

function SnapshotApplier.apply(controller, snapshot)
    local state = controller.state
    local previous_game = state.game or {}
    local previous_ui_phase = state.ui_phase
    local previous_remaining_reveal_remaining = tonumber(state.remaining_cards_reveal_remaining) or 0
    local is_initial_snapshot = previous_game.game_id == nil
    local previous_last_entry, previous_history_count = getLastActionEntry(previous_game)
    state.game = SnapshotApplier.prepareSnapshot(state, snapshot)
    state.last_play = Helpers.buildLastPlayViewModel(state.game)
    local current_last_entry, current_history_count = getLastActionEntry(state.game)

    if current_history_count > 0 then
        local previous_sig = buildHistorySignature(previous_last_entry, previous_history_count)
        local current_sig = buildHistorySignature(current_last_entry, current_history_count)
        if current_sig ~= "" and current_sig ~= previous_sig then
            local action_type = tostring((current_last_entry or {}).action_type or "")
            local actor_seat = getEntrySeat(current_last_entry)
            local my_seat = tonumber(((state.game or {}).my_seat_index))
            if action_type == "pass" and actor_seat ~= nil and my_seat ~= nil then
                if actor_seat ~= my_seat then
                    controller:playSfx("pass_sound")
                else
                    if state.suppress_next_pass_sfx then
                        state.suppress_next_pass_sfx = false
                    else
                        controller:playSfx("pass_sound")
                    end
                end
            elseif action_type == "play" then
                controller:playSfx(resolvePlaySfxId(current_last_entry))
            end
            if state.suppress_next_pass_sfx and (action_type ~= "pass" or actor_seat ~= my_seat) then
                state.suppress_next_pass_sfx = false
            end
        end
    end

    local valid_cards = {}
    for _, card_id in ipairs((state.game or {}).my_hand_cards or {}) do
        valid_cards[card_id] = true
    end
    for card_id in pairs(state.selected_card_ids) do
        if not valid_cards[card_id] then
            state.selected_card_ids[card_id] = nil
        end
    end
    local next_groups = {}
    local source_groups = state.pinned_card_groups
    if type(source_groups) ~= "table" or #source_groups == 0 then
        source_groups = {}
        if #((state.pinned_card_ids or {})) > 0 then
            source_groups = {
                { cards = state.pinned_card_ids },
            }
        end
    end
    for _, group in ipairs(source_groups) do
        local next_group_cards = {}
        for _, card_id in ipairs((group and (group.cards or group)) or {}) do
            if valid_cards[card_id] then
                next_group_cards[#next_group_cards + 1] = card_id
                if #next_group_cards >= PINNED_GROUP_MAX_COUNT then
                    break
                end
            end
        end
        if #next_group_cards > 0 then
            next_groups[#next_groups + 1] = {
                cards = Helpers.sortPinnedGroupCards(next_group_cards),
            }
        end
    end
    state.pinned_card_groups = next_groups
    state.pinned_card_ids = flattenPinnedGroups(next_groups)
    if state.selected_tribute_card_id and not valid_cards[state.selected_tribute_card_id] then
        state.selected_tribute_card_id = nil
    end

    state.hovered_card_id = nil
    state.hand_drag_selection = nil
    state.hovered_control = nil
    state.hovered_tribute_card_id = nil
    state.hovered_tribute_control = nil
    state.hovered_round_info_button = false
    state.hovered_round_info_overlay_control = nil
    state.hovered_player_hud_role = nil
    state.hovered_player_profile_control = nil
    state.hovered_debug_button = false
    state.action_waiting = false
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0

    if state.show_player_profile_overlay then
        local target_seat = tonumber((state.profile_overlay_player or {}).seat_index)
        local matched_player = nil
        if target_seat ~= nil then
            for _, player in ipairs((state.game or {}).players or {}) do
                if tonumber(player.seat_index) == target_seat then
                    matched_player = player
                    break
                end
            end
        end
        if matched_player then
            state.profile_overlay_player = matched_player
        else
            state.show_player_profile_overlay = false
            state.profile_overlay_player = nil
        end
    end

    local current_game = state.game or {}
    syncPlayHistoryState(state, current_game)
    if state.round_info_active_tab == "tribute" and not hasTributeInfo(current_game) then
        state.round_info_active_tab = "history"
    end
    if tostring(current_game.phase or "") ~= "playing" then
        state.turn_countdown_pending_remaining = 0
        state.turn_countdown_pending_duration = 0
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
    end
    maybeTriggerPlayerFinishedAlert(controller, previous_game, current_game)
    maybeTriggerLowHandCountAlerts(controller, previous_game, current_game)
    state.pass_markers = buildPassMarkers(current_game)
    local tribute_state = ((current_game or {}).tribute) or {}
    if #((tribute_state.candidate_cards) or {}) == 0 then
        state.selected_tribute_card_id = nil
    end
    local has_active_tribute = Helpers.hasActiveTribute(current_game)
    if has_active_tribute then
        state.tribute_countdown_remaining = tonumber((((current_game or {}).tribute) or {}).countdown_remaining_seconds or 0) or 0
        state.tribute_countdown_duration = tonumber((((current_game or {}).tribute) or {}).timeout_seconds or 0) or 0
    elseif state.tribute_force_visible ~= true then
        state.tribute_countdown_remaining = 0
        state.tribute_countdown_duration = 0
    end
    if has_active_tribute then
        state.tribute_overlay_snapshot = current_game
    end
    if has_active_tribute then
        state.arrange_remaining = 0
        state.arrange_duration = 0
        state.turn_countdown_pending_remaining = 0
        state.turn_countdown_pending_duration = 0
        state.turn_countdown_remaining = 0
        state.turn_countdown_duration = 0
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
    else
        state.arrange_remaining = tonumber((current_game or {}).arrange_countdown_remaining_seconds or 0) or 0
        state.arrange_duration = tonumber((current_game or {}).arrange_timeout_seconds or 0) or 0
        local turn_countdown_remaining = tonumber((current_game or {}).turn_countdown_remaining_seconds or 0) or 0
        local turn_countdown_duration = tonumber((current_game or {}).turn_timeout_seconds or 0) or 0
        if state.arrange_remaining > 0 and turn_countdown_remaining > 0 then
            state.turn_countdown_pending_remaining = turn_countdown_remaining
            state.turn_countdown_pending_duration = turn_countdown_duration
            state.turn_countdown_remaining = 0
            state.turn_countdown_duration = 0
            state.arrange_hold_visible = true
        else
            state.turn_countdown_pending_remaining = 0
            state.turn_countdown_pending_duration = 0
            state.turn_countdown_remaining = turn_countdown_remaining
            state.turn_countdown_duration = turn_countdown_duration
            if turn_countdown_remaining > 0 then
                state.arrange_hold_visible = false
                state.arrange_zero_hold = false
                state.arrange_progress_request_active = false
                state.arrange_progress_request_elapsed = 0
            elseif state.arrange_remaining > 0 then
                state.arrange_hold_visible = true
            end
        end
    end
    local previous_tribute = (previous_game or {}).tribute or {}
    local current_tribute = (current_game or {}).tribute or {}
    local previous_tribute_phase = tostring(previous_tribute.phase or "")
    local current_tribute_phase = tostring(current_tribute.phase or "")
    local entering_new_hand = (current_game.hand_no ~= nil and previous_game.hand_no ~= nil and current_game.hand_no ~= previous_game.hand_no)
        or (previous_game.phase == "settlement" and current_game.phase ~= "settlement")
    local tribute_started = not Helpers.hasActiveTribute(previous_game) and Helpers.hasActiveTribute(current_game)
    local tribute_finished = Helpers.hasActiveTribute(previous_game) and not Helpers.hasActiveTribute(current_game)
    local anti_tribute_started = current_tribute_phase == "anti_tribute"
        and current_tribute.anti_tribute == true
        and previous_tribute_phase ~= "anti_tribute"
    local current_phase = tostring(current_game.phase or "")
    local entered_result_phase = previous_game.game_id ~= nil
        and tostring(previous_game.phase or "") == "playing"
        and (current_phase == "remaining_cards" or current_phase == "settlement")
    local has_last_play_cards = type(((state.last_play or {}).cards)) == "table"
        and #(((state.last_play or {}).cards)) > 0
    if entered_result_phase and has_last_play_cards and (tonumber(state.result_transition_remaining) or 0) <= 0 then
        state.result_transition_duration = RESULT_TRANSITION_DURATION
        state.result_transition_remaining = RESULT_TRANSITION_DURATION
    end
    local freeze_result_transition = (tonumber(state.result_transition_remaining) or 0) > 0
        and (current_phase == "remaining_cards" or current_phase == "settlement")
    if not freeze_result_transition and current_phase ~= "remaining_cards" and current_phase ~= "settlement" then
        state.result_transition_remaining = 0
        state.result_transition_duration = 0
    end

    if freeze_result_transition then
        state.tribute_force_visible = false
        state.tribute_overlay_snapshot = nil
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.reveal_cards = true
        state.status_message = ""
        state.ui_phase = "result_transition"
        state.remaining_cards_button_hovered = false
        state.settlement_button_hovered = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
        state.remaining_cards_reveal_remaining = 0
        state.remaining_cards_reveal_duration = 0
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
        state.remaining_cards_countdown_remaining = 0
        state.remaining_cards_countdown_duration = 0
        state.settlement_countdown_remaining = 0
        state.settlement_countdown_duration = 0
        state.result_revealed_hands = nil
        state.last_settlement_hand_no = nil
    elseif current_game.phase == "settlement" then
        state.result_transition_remaining = 0
        state.result_transition_duration = 0
        state.tribute_force_visible = false
        state.tribute_overlay_snapshot = nil
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.reveal_cards = false
        state.status_message = ""
        state.remaining_cards_button_hovered = false
        local is_match_finished = ((((current_game or {}).settlement) or {}).is_match_won) == true
        local is_single_player = (current_game.game_config or {}).is_single_player == true
        if state.result_revealed_hands == nil then
            state.result_revealed_hands = copyRevealedHands(((((previous_game or {}).remaining_cards) or {}).revealed_hands) or {})
        end
        state.ui_phase = is_match_finished and "rematch" or "remaining_cards"
        state.settlement_button_hovered = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
        local duration = tonumber(((current_game.game_config or {}).settlement_countdown_seconds) or 0) or 0
        local backend_remaining = tonumber((current_game or {}).settlement_countdown_remaining_seconds or 0) or 0
        state.settlement_countdown_duration = duration
        if is_match_finished or is_single_player then
            state.settlement_countdown_remaining = 0
        else
            state.settlement_countdown_remaining = backend_remaining
        end
        state.remaining_cards_reveal_remaining = 0
        state.remaining_cards_reveal_duration = 0
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
        -- The remaining-cards overlay already showed its own countdown in the
        -- previous phase. Keep the merged result page visible during settlement,
        -- but do not remap the settlement autostart countdown onto the same bar.
        state.remaining_cards_countdown_remaining = 0
        state.remaining_cards_countdown_duration = 0
        if state.last_settlement_hand_no ~= current_game.hand_no then
            state.last_settlement_hand_no = current_game.hand_no
            if previous_game.game_id ~= nil and state.last_settlement_audio_hand_no ~= current_game.hand_no then
                local winning_team_id = tonumber((((current_game or {}).settlement) or {}).winning_team_id)
                local my_team_id = getMyTeamId(current_game)
                if winning_team_id ~= nil and my_team_id ~= nil then
                    controller:playSfx(my_team_id == winning_team_id and "win_round" or "failed_round")
                    state.last_settlement_audio_hand_no = current_game.hand_no
                end
            end
            if is_single_player and not is_match_finished then
                controller:startNextHand()
            end
        end
    elseif current_game.phase == "remaining_cards" then
        state.result_transition_remaining = 0
        state.result_transition_duration = 0
        state.tribute_force_visible = false
        state.tribute_overlay_snapshot = nil
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.selected_card_ids = {}
        state.hovered_card_id = nil
        state.hovered_control = nil
        state.reveal_cards = false
        state.status_message = ""
        state.action_waiting = false
        state.remaining_cards_button_hovered = false
        local remaining_cards = (current_game or {}).remaining_cards or {}
        state.result_revealed_hands = copyRevealedHands(remaining_cards.revealed_hands or {})
        state.ui_phase = "remaining_cards"
        state.remaining_cards_reveal_duration = tonumber(remaining_cards.reveal_delay_seconds or 0) or 0
        state.remaining_cards_reveal_remaining = tonumber(remaining_cards.reveal_remaining_seconds or 0) or 0
        if state.remaining_cards_reveal_remaining > 0 then
            state.remaining_cards_intro_remaining = 0
            state.remaining_cards_intro_duration = 0.44
        elseif previous_ui_phase ~= "remaining_cards" or previous_remaining_reveal_remaining > 0 then
            state.remaining_cards_intro_duration = 0.44
            state.remaining_cards_intro_remaining = 0.44
        end
        state.remaining_cards_countdown_duration = tonumber(remaining_cards.countdown_seconds or 0) or 0
        state.remaining_cards_countdown_remaining = tonumber(remaining_cards.countdown_remaining_seconds or 0) or 0
        state.settlement_countdown_remaining = 0
        state.settlement_countdown_duration = 0
        state.settlement_button_hovered = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
        if previous_game.game_id ~= nil and state.last_settlement_audio_hand_no ~= current_game.hand_no then
            local winning_team_id = tonumber((((current_game or {}).settlement) or {}).winning_team_id)
            local my_team_id = getMyTeamId(current_game)
            if winning_team_id ~= nil and my_team_id ~= nil then
                controller:playSfx(my_team_id == winning_team_id and "win_round" or "failed_round")
                state.last_settlement_audio_hand_no = current_game.hand_no
            end
        end
        state.last_settlement_hand_no = nil
    elseif is_initial_snapshot and tostring(current_game.phase or "") == "dealing" then
        PresentationFlow.beginHandPresentation(state)
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif is_initial_snapshot and tostring(current_game.phase or "") == "playing" and not Helpers.hasActiveTribute(current_game) then
        PresentationFlow.beginHandPresentation(state)
        state.reveal_cards = true
        state.ui_phase = "playing"
        state.result_revealed_hands = nil
        state.deal_overlay_remaining = 0
        state.deal_overlay_duration = 0
        state.deal_sfx_start_remaining = 0
        state.hand_loading_remaining = 0
        state.hand_loading_duration = 0
        state.status_message = ""
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif entering_new_hand then
        PresentationFlow.beginHandPresentation(state)
        state.result_revealed_hands = nil
        state.last_settlement_hand_no = nil
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif tribute_started then
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.result_revealed_hands = nil
        PresentationFlow.beginTribute(state)
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif tribute_finished then
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.result_revealed_hands = nil
        state.selected_card_ids = {}
        state.hovered_card_id = nil
        state.hovered_control = nil
        state.hovered_tribute_card_id = nil
        state.hovered_tribute_control = nil
        if state.tribute_force_visible ~= true then
            if tostring(current_game.phase or "") == "dealing" then
                PresentationFlow.beginDealing(state)
            else
                PresentationFlow.beginHandLoading(controller)
            end
        else
            state.ui_phase = "tribute"
        end
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif previous_game.phase == "dealing" and current_game.phase ~= "dealing" and not state.reveal_cards then
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.result_revealed_hands = nil
        if Helpers.hasActiveTribute(current_game) then
            PresentationFlow.beginTribute(state)
        else
            PresentationFlow.beginHandLoading(controller)
        end
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif Helpers.hasActiveTribute(current_game) then
        state.arrange_hold_visible = false
        state.arrange_zero_hold = false
        state.arrange_progress_request_active = false
        state.arrange_progress_request_elapsed = 0
        state.result_revealed_hands = nil
        state.ui_phase = "tribute"
        state.status_message = (((current_game or {}).tribute) or {}).message or ""
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
    elseif state.tribute_force_visible == true and (tonumber(state.tribute_countdown_remaining) or 0) > 0 then
        state.ui_phase = "tribute"
        state.status_message = ((((state.tribute_overlay_snapshot or {}).tribute) or {}).message) or ""
    elseif state.reveal_cards then
        state.result_revealed_hands = nil
        if (tonumber(state.hand_loading_remaining) or 0) > 0 then
            state.ui_phase = "hand_loading"
        else
            state.ui_phase = "playing"
        end
        state.settlement_countdown_remaining = 0
        state.settlement_countdown_duration = 0
        state.settlement_button_hovered = false
        state.rematch_confirm_button_hovered = false
        state.rematch_leave_button_hovered = false
        state.remaining_cards_reveal_remaining = 0
        state.remaining_cards_reveal_duration = 0
        state.remaining_cards_intro_remaining = 0
        state.remaining_cards_intro_duration = 0
        state.remaining_cards_countdown_remaining = 0
        state.remaining_cards_countdown_duration = 0
        state.remaining_cards_button_hovered = false
        state.last_settlement_hand_no = nil
    end

    if anti_tribute_started then
        applyAntiTributeForceVisible(controller, state, current_game, current_tribute)
    end

    if state.ui_phase ~= "playing" then
        state.show_player_profile_overlay = false
        state.hovered_player_profile_control = nil
        state.profile_overlay_player = nil
        state.show_round_info_overlay = false
        state.hovered_round_info_button = false
        state.hovered_round_info_overlay_control = nil
        state.round_info_active_tab = "history"
    end

    local game = state.game or {}
    local is_my_turn = game.current_actor_seat ~= nil and game.current_actor_seat == game.my_seat_index
    print(string.format(
        "[gameplay] applied snapshot actor=%s my_seat=%s has_control=%s action_waiting=%s is_my_turn=%s phase=%s",
        tostring(game.current_actor_seat),
        tostring(game.my_seat_index),
        tostring(game.has_play_control),
        tostring(state.action_waiting),
        tostring(is_my_turn),
        tostring(game.phase)
    ))
end

return SnapshotApplier
