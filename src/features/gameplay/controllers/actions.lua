local I18n = require("src.core.i18n.i18n")
local Helpers = require("src.features.gameplay.controllers.helpers")
local PresentationFlow = require("src.features.gameplay.controllers.presentation_flow")

local Actions = {}

local TOAST_DURATION = 1.4
local PINNED_GROUP_MAX_COUNT = 6

local function flattenPinnedGroups(groups)
    local flat = {}
    for _, group in ipairs(groups or {}) do
        for _, card_id in ipairs((group and (group.cards or group)) or {}) do
            flat[#flat + 1] = card_id
        end
    end
    return flat
end

local function clearHandArrangementSelection(state)
    state.selected_card_ids = {}
    state.hovered_card_id = nil
    state.hovered_control = nil
end

local function clearTributeInteraction(state, preserve_selected_card)
    if not preserve_selected_card then
        state.selected_tribute_card_id = nil
    end
    state.hovered_tribute_card_id = nil
    state.hovered_tribute_control = nil
end

local function clearArrangementSelection(state)
    clearHandArrangementSelection(state)
    clearTributeInteraction(state, false)
end

local function collectArrangementSelectedCards(state)
    if tostring((state or {}).ui_phase or "") == "tribute" then
        local selected_cards = Helpers.collectSelectedCards(state)
        if #selected_cards > 0 then
            return selected_cards
        end
        local selected_tribute_card_id = tostring((state or {}).selected_tribute_card_id or "")
        if selected_tribute_card_id ~= "" then
            return { selected_tribute_card_id }
        end
        return {}
    end
    return Helpers.collectSelectedCards(state)
end

local function countHandArrangementSelections(state)
    return #Helpers.collectSelectedCards(state)
end

local function getSingleTributeSelectionMessage()
    local message = I18n:t("gameplay.select_only_one_tribute_card")
    if message == "gameplay.select_only_one_tribute_card" then
        return "Please select only one tribute or return tribute card."
    end
    return message
end

local function applyPinnedSelection(state, selected_cards)
    local hand_cards = ((state.game or {}).my_hand_cards) or {}
    local hand_set = {}
    for _, card_id in ipairs(hand_cards) do
        hand_set[card_id] = true
    end

    local selected_set = {}
    for _, card_id in ipairs(selected_cards) do
        selected_set[card_id] = true
    end

    local next_groups = {}
    local used = {}

    for _, group in ipairs(state.pinned_card_groups or {}) do
        local next_group_cards = {}
        for _, card_id in ipairs((group and (group.cards or group)) or {}) do
            if hand_set[card_id] and not selected_set[card_id] and not used[card_id] then
                used[card_id] = true
                next_group_cards[#next_group_cards + 1] = card_id
            end
            if #next_group_cards >= PINNED_GROUP_MAX_COUNT then
                break
            end
        end
        if #next_group_cards > 0 then
            next_groups[#next_groups + 1] = {
                cards = Helpers.sortPinnedGroupCards(next_group_cards),
            }
        end
    end

    local selected_group_cards = {}
    local overflow = false
    for _, card_id in ipairs(selected_cards) do
        if hand_set[card_id] and not used[card_id] then
            if #selected_group_cards < PINNED_GROUP_MAX_COUNT then
                used[card_id] = true
                selected_group_cards[#selected_group_cards + 1] = card_id
            else
                overflow = true
            end
        end
    end

    if #selected_group_cards > 0 then
        table.insert(next_groups, 1, {
            cards = Helpers.sortPinnedGroupCards(selected_group_cards),
        })
    end

    state.pinned_card_groups = next_groups
    state.pinned_card_ids = flattenPinnedGroups(next_groups)
    clearHandArrangementSelection(state)
    if tostring((state or {}).ui_phase or "") == "tribute" then
        clearTributeInteraction(state, true)
    else
        clearTributeInteraction(state, false)
    end

    return overflow
end

function Actions.showToast(controller, message)
    local state = controller.state
    state.toast_message = message or ""
    state.toast_remaining = state.toast_message ~= "" and TOAST_DURATION or 0
    state.toast_duration = state.toast_remaining
end

function Actions.loadGame(controller)
    local state = controller.state
    local service = controller.service

    state.loading = true
    state.fatal_error_message = ""
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0
    state.status_message = I18n:t("gameplay.loading_status")

    local result = service:fetchGame(state.room_id, state.steam_id)
    state.loading = false

    if not result.ok then
        state.fatal_error_message = result.message or I18n:t("gameplay.load_failed")
        state.status_message = ""
        return
    end

    state.game = result.game or {}
    state.last_play = Helpers.buildLastPlayViewModel(state.game)
    PresentationFlow.beginHandPresentation(state)
end

function Actions.startNextHand(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    local command_id = Helpers.buildCommandId(state, "next")
    controller.service:startNextHand(command_id)
    state.action_waiting = true
    state.settlement_button_hovered = false
end

function Actions.confirmRematch(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    local command_id = Helpers.buildCommandId(state, "rematch")
    controller.service:confirmRematch(command_id)
    state.action_waiting = true
    state.rematch_confirm_button_hovered = false
end

function Actions.skipRemainingCardsView(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    local command_id = Helpers.buildCommandId(state, "skip-remaining")
    controller.service:skipRemainingCardsView(command_id)
    state.action_waiting = true
    state.remaining_cards_button_hovered = false
end

function Actions.leaveToMainMenu(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    print(string.format(
        "[gameplay] leaveToMainMenu clicked room_id=%s steam_id=%s",
        tostring(state.room_id),
        tostring(state.steam_id)
    ))

    state.action_waiting = true
    state.rematch_leave_button_hovered = false
    state.status_message = I18n:t("gameplay.leaving_room")

    local result = controller.service:leaveRoom(state.room_id, state.steam_id)
    state.action_waiting = false

    print(string.format(
        "[gameplay] leaveToMainMenu result ok=%s room_id=%s steam_id=%s message=%s",
        tostring(result and result.ok),
        tostring(state.room_id),
        tostring(state.steam_id),
        tostring(result and result.message)
    ))

    if not result.ok then
        Actions.showToast(controller, result.message or I18n:t("gameplay.realtime_failed"))
        return
    end

    controller:handleLeftRoom()
end

function Actions.debugAutoplayHand(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    local command_id = Helpers.buildCommandId(state, "debug-auto")
    controller.service:debugAutoplayHand(command_id)
    state.action_waiting = true
    state.hovered_debug_button = false
end

function Actions.playSelectedCards(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    local selected_cards = Helpers.collectSelectedCards(state)
    if #selected_cards == 0 then
        Actions.showToast(controller, I18n:t("gameplay.select_cards_first"))
        return
    end

    local command_id = Helpers.buildCommandId(state, "play")
    print(string.format("[gameplay] submit play command_id=%s cards=%s", command_id, table.concat(selected_cards, ",")))
    controller.service:playCards(selected_cards, command_id)
    state.action_waiting = true
    state.status_message = ""
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0
end

function Actions.passTurn(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end

    controller:playSfx("pass_sound")
    local command_id = Helpers.buildCommandId(state, "pass")
    print(string.format("[gameplay] submit pass command_id=%s", command_id))
    controller.service:passTurn(command_id)
    state.suppress_next_pass_sfx = true
    state.selected_card_ids = {}
    state.hovered_card_id = nil
    state.hovered_control = nil
    state.action_waiting = true
    state.status_message = ""
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0
end

function Actions.submitTributeCard(controller)
    local state = controller.state
    if state.action_waiting then
        return
    end
    if tostring((state or {}).ui_phase or "") == "tribute" and countHandArrangementSelections(state) > 1 then
        Actions.showToast(controller, getSingleTributeSelectionMessage())
        return
    end
    if not state.selected_tribute_card_id then
        Actions.showToast(controller, I18n:t("gameplay.select_tribute_card_first"))
        return
    end

    local tribute = ((state.game or {}).tribute) or {}
    local command_id = Helpers.buildCommandId(state, tribute.action_type == "return_tribute" and "return" or "tribute")
    if tribute.action_type == "return_tribute" then
        controller.service:submitReturnTribute(state.selected_tribute_card_id, command_id)
    else
        controller.service:submitTribute(state.selected_tribute_card_id, command_id)
    end
    state.action_waiting = true
    state.toast_message = ""
    state.toast_remaining = 0
    state.toast_duration = 0
end

function Actions.pinSelectedCards(controller)
    local state = controller.state
    local selected_cards = collectArrangementSelectedCards(state)
    if #selected_cards == 0 then
        Actions.showToast(controller, I18n:t("gameplay.pin_select_first"))
        return
    end

    local overflow = applyPinnedSelection(state, selected_cards)
    if overflow then
        Actions.showToast(controller, I18n:t("gameplay.pin_limit_reached", {
            count = tostring(PINNED_GROUP_MAX_COUNT),
        }))
    end
end

function Actions.rankHandCards(controller)
    local state = controller.state
    state.pinned_card_ids = {}
    state.pinned_card_groups = {}
    clearHandArrangementSelection(state)
    if tostring((state or {}).ui_phase or "") == "tribute" then
        clearTributeInteraction(state, true)
    else
        clearTributeInteraction(state, false)
    end
end

return Actions
