local I18n = require("src.core.i18n.i18n")
local Actions = require("src.features.gameplay.controllers.actions")
local SnapshotApplier = require("src.features.gameplay.controllers.snapshot_applier")

local RealtimeHandler = {}

local function buildEventsPathHint(state)
    local room_id = tostring((state and state.room_id) or "room")
    local steam_id = tostring((state and state.steam_id) or "steam")
    local relative = string.format("runtime/room_ws/%s_%s/events.ndjson", room_id, steam_id)

    if love and love.filesystem and love.filesystem.getSaveDirectory then
        local save_dir = tostring(love.filesystem.getSaveDirectory() or "")
        if save_dir ~= "" then
            return relative, (save_dir .. "/" .. relative):gsub("/+", "/")
        end
    end
    return relative, relative
end

local function showRoomClosedNotice(message)
    if tostring(message or "") == "" then
        return
    end
    if love and love.window and type(love.window.showMessageBox) == "function" then
        pcall(love.window.showMessageBox, I18n:t("gameplay.room_closed_title"), tostring(message), "info")
    end
end

local function isTerminalRoomError(payload)
    payload = payload or {}
    local code = tostring(payload.code or "")
    local message = tostring(payload.message or "")
    local lower_message = string.lower(message)
    if code == "room_not_found" then
        return true
    end
    if message == "Room is closed." then
        return true
    end
    if message == "Current user is not in this game." then
        return true
    end
    if lower_message:find("room", 1, true) and (
        lower_message:find("not found", 1, true)
        or lower_message:find("closed", 1, true)
    ) then
        return true
    end
    if lower_message:find("current user", 1, true) and lower_message:find("not in this game", 1, true) then
        return true
    end
    return false
end

function RealtimeHandler.handle(controller, packet)
    if controller.left_room_handled == true then
        return
    end

    local state = controller.state

    if packet.type == "bridge_status" then
        local payload = packet.payload or {}
        local status = payload.status or state.realtime_status
        state.realtime_status = status

        if status == "connected" then
            if state.loading then
                state.game_snapshot_request_elapsed = 0
                controller:requestGameSnapshot()
            end
            return
        end

        if status == "error" then
            state.action_waiting = false
            local reason = tostring(payload.message or I18n:t("gameplay.realtime_failed"))
            if isTerminalRoomError({ message = reason }) then
                showRoomClosedNotice(I18n:t("gameplay.room_closed_generic"))
                controller:handleLeftRoom()
                return
            end
            print(string.format(
                "[gameplay][ws] bridge_status=error room=%s steam_id=%s reason=%s",
                tostring(state.room_id),
                tostring(state.steam_id),
                tostring(reason)
            ))
            return
        end

        if status == "connecting" or status == "disconnected" then
            if status == "disconnected" then
                state.action_waiting = false
            end
            local relative_path, absolute_path = buildEventsPathHint(state)
            print(string.format(
                "[gameplay][ws] bridge_status=%s room=%s steam_id=%s events=%s absolute=%s",
                tostring(status),
                tostring(state.room_id),
                tostring(state.steam_id),
                tostring(relative_path),
                tostring(absolute_path)
            ))
        end
        return
    end

    if packet.type == "error" then
        local payload = packet.payload or {}
        local message = payload.message or ""
        local localized_errors = {
            not_your_turn = I18n:t("gameplay.error_not_your_turn"),
            card_not_in_hand = I18n:t("gameplay.error_card_not_in_hand"),
            invalid_pattern = I18n:t("gameplay.error_invalid_pattern"),
            play_not_strong_enough = I18n:t("gameplay.error_play_not_strong_enough"),
            pass_not_allowed = I18n:t("gameplay.error_pass_not_allowed"),
            game_not_playing = I18n:t("gameplay.error_game_not_playing"),
            empty_play = I18n:t("gameplay.select_cards_first"),
            tribute_not_allowed = I18n:t("gameplay.error_tribute_not_allowed"),
            return_tribute_not_allowed = I18n:t("gameplay.error_return_tribute_not_allowed"),
            anti_tribute_not_ready = I18n:t("gameplay.error_anti_tribute_not_ready"),
            remaining_cards_not_available = I18n:t("gameplay.error_remaining_cards_not_available"),
            remaining_cards_skip_not_allowed = I18n:t("gameplay.error_remaining_cards_skip_not_allowed"),
            rematch_not_available = I18n:t("gameplay.error_rematch_not_available"),
            rematch_not_allowed = I18n:t("gameplay.error_rematch_not_allowed"),
            new_match_player_count_invalid = I18n:t("gameplay.error_new_match_player_count_invalid"),
        }
        if payload.code == "unknown_room_command" then
            return
        end
        if isTerminalRoomError(payload) then
            state.action_waiting = false
            showRoomClosedNotice(I18n:t("gameplay.room_closed_generic"))
            controller:handleLeftRoom()
            return
        end
        state.action_waiting = false
        Actions.showToast(controller, localized_errors[payload.code] or (message ~= "" and message or I18n:t("gameplay.realtime_failed")))
        return
    end

    if packet.type == "left_room" then
        state.action_waiting = false
        controller:handleLeftRoom()
        return
    end

    if packet.type == "room_closed" then
        local payload = packet.payload or {}
        local reason = tostring(payload.reason or "")
        local message = tostring(payload.message or "")
        if message == "" then
            if reason == "inactive_timeout" then
                message = I18n:t("gameplay.room_closed_inactive_timeout")
            else
                message = I18n:t("gameplay.room_closed_generic")
            end
        end
        state.action_waiting = false
        showRoomClosedNotice(message)
        controller:handleLeftRoom()
        return
    end

    if packet.type == "game_snapshot" then
        local payload = packet.payload or {}
        state.loading = false
        state.fatal_error_message = ""
        state.status_message = ""
        state.game_snapshot_request_elapsed = 0
        state.game_snapshot_request_attempts = 0
        state.realtime_snapshot_watchdog_elapsed = 0
        print(string.format(
            "[gameplay] snapshot actor=%s my_seat=%s has_control=%s phase=%s selected=%s reveal=%s",
            tostring(payload.current_actor_seat),
            tostring(payload.my_seat_index),
            tostring(payload.has_play_control),
            tostring(payload.phase),
            tostring(next(state.selected_card_ids) ~= nil),
            tostring(state.reveal_cards)
        ))
        SnapshotApplier.apply(controller, payload)
        return
    end

    if packet.type == "room_snapshot" then
        local payload = packet.payload or {}
        if state.loading and tostring(payload.status or "") == "in_game" then
            controller:requestGameSnapshot()
        end
    end
end

return RealtimeHandler
