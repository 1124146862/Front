local State = {}

function State.create()
    return {
        rooms = {},
        total = 0,
        page = 1,
        page_size = 2,
        has_prev = false,
        has_next = false,
        loading = false,
        submitting = false,
        error_message = "",
        status_message = "正在加载房间列表...",
        hovered_control = nil,
        focused_field = nil,
        create_title_input = "我的房间",
        create_mode_input = "classic",
        create_password_input = "",
        join_room_id_input = "",
        join_password_input = "",
    }
end

return State
