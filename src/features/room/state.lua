local State = {}
local I18n = require("src.core.i18n.i18n")

function State.create(room_id, user_profile, options)
    options = options or {}

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
        status_message = I18n:t("room.loading_room"),
        overlay_visible = false,
        overlay_step = "password",
        overlay_room_id_input = "",
        overlay_password_input = "",
        overlay_error_message = "",
        overlay_hovered_key = nil,
        realtime_status = "disconnected",
        server_loading_visible = false,
        server_loading_message = nil,
        server_loading_elapsed = 0,
        server_loading_request_started = false,
        pending_server_action = nil,
        config_title_input = "",
        config_mode_input = "",
        config_password_input = "",
        auto_single_player_bootstrap = options.auto_single_player_bootstrap == true,
    }
end

return State
