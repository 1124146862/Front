local State = {}

function State.create()
    return {
        steam_id = nil,
        nickname_input = "",
        phase = "idle",
        status_message = "",
        error_message = "",
        input_focused = false,
        button_hovered = false,
        query_pending = false,
        submit_pending = false,
        avatar_order = {},
        avatar_page = 1,
        avatar_page_size = 15,
        avatar_visible_ids = {},
        total_avatar_pages = 1,
        selected_avatar_id = nil,
        avatar_explicit_selected = false,
        hovered_avatar_id = nil,
        hovered_avatar_prev = false,
        hovered_avatar_next = false,
        random_button_hovered = false,
        close_button_hovered = false,
        press_feedback = {
            submit = 0,
            random = 0,
            avatar_prev = 0,
            avatar_next = 0,
        },
    }
end

return State
