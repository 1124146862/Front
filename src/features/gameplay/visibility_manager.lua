local VisibilityManager = {}

function VisibilityManager.resolve(state)
    local show_result_overlay = state.ui_phase == "remaining_cards" or state.ui_phase == "settlement"
    local show_rematch_overlay = state.ui_phase == "rematch"
    local show_tribute_overlay = state.ui_phase == "tribute"
    local show_remaining_cards_overlay = show_result_overlay
    local show_deal_overlay = state.ui_phase == "dealing"

    return {
        show_player_huds = state.game ~= nil and not show_result_overlay and not show_rematch_overlay and not show_tribute_overlay,
        show_player_hand_counts = state.reveal_cards and not show_result_overlay and not show_rematch_overlay and not show_tribute_overlay and not show_deal_overlay,
        show_hand_area = state.reveal_cards and not show_result_overlay and not show_rematch_overlay and not show_tribute_overlay and not show_deal_overlay,
        show_tribute_overlay = show_tribute_overlay,
        show_deal_overlay = show_deal_overlay,
        show_wildcard_overlay = state.ui_phase == "wildcard" and state.wildcard_overlay_remaining > 0,
        show_remaining_cards_overlay = show_remaining_cards_overlay,
        show_settlement_overlay = false,
        show_rematch_overlay = show_rematch_overlay,
    }
end

return VisibilityManager
