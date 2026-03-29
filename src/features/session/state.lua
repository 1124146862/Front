local State = {}

function State.create()
    return {
        steam_id = nil,
        nickname_input = "",
        phase = "idle",
        status_message = "",
        error_message = "",
        input_focused = false,
        query_pending = false,
        submit_pending = false,
    }
end

return State
