local State = {}

function State.create(room_id, user_profile)
    return {
        room_id = room_id,
        steam_id = user_profile.steam_id,
        nickname = user_profile.nickname,
        room = nil,
        loading = false,
        saving = false,
        leaving = false,
        hovered_control = nil,
        focused_field = nil,
        error_message = "",
        status_message = "正在加载房间信息...",
        config_title_input = "",
        config_mode_input = "",
        config_password_input = "",
    }
end

return State
