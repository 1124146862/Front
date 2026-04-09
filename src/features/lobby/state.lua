local State = {}
local I18n = require("src.core.i18n.i18n")

function State.create()
    return {
        rooms = {},
        total = 0,
        page = 1,
        page_size = 5,
        has_prev = false,
        has_next = false,
        loading = false,
        submitting = false,
        error_message = "",
        status_message = I18n:t("lobby.loading_rooms"),
        hovered_control = nil,
        overlay_visible = false,
        overlay_step = "room_id",
        overlay_room_id_input = "",
        overlay_password_input = "",
        overlay_error_message = "",
        overlay_hovered_key = nil,
        hovered_join_room_id = nil,
        server_loading_visible = false,
        server_loading_message = nil,
        server_loading_elapsed = 0,
        server_loading_request_started = false,
        pending_server_action = nil,
    }
end

return State
