local RoomService = {}
RoomService.__index = RoomService
local I18n = require("src.core.i18n.i18n")

function RoomService.new(options)
    local self = setmetatable({}, RoomService)

    self.http_client = assert(options and options.http_client, "RoomService requires http_client")
    self.ws_client = assert(options and options.ws_client, "RoomService requires ws_client")

    return self
end

function RoomService:fetchRoom(room_id, steam_id)
    local response = self.http_client:get("/room/" .. tostring(room_id), {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("room.load_failed"),
        }
    end

    return {
        ok = true,
        room = response.data or {},
        message = I18n:t("room.room_refreshed"),
    }
end

function RoomService:connectRoomChannel(room_id, steam_id)
    self.ws_client:start(room_id, steam_id)
end

function RoomService:disconnectRoomChannel()
    self.ws_client:stop()
end

function RoomService:pollRoomChannel()
    return self.ws_client:poll()
end

function RoomService:requestSnapshot()
    self.ws_client:send({
        type = "request_snapshot",
        payload = {},
    })
end

function RoomService:setReady(is_ready)
    self.ws_client:send({
        type = "set_ready",
        payload = {
            is_ready = is_ready,
        },
    })
end

function RoomService:changeSeat(seat_index)
    self.ws_client:send({
        type = "change_seat",
        payload = {
            seat_index = seat_index,
        },
    })
end

function RoomService:updateConfig(title, game_mode, password)
    self.ws_client:send({
        type = "update_room_config",
        payload = {
            title = title,
            game_mode = game_mode,
            password = password ~= "" and password or nil,
        },
    })
end

function RoomService:addBot()
    self.ws_client:send({
        type = "add_bot",
        payload = {},
    })
end

function RoomService:removeBot(bot_steam_id)
    self.ws_client:send({
        type = "remove_bot",
        payload = {
            bot_steam_id = bot_steam_id,
        },
    })
end

function RoomService:leaveRoom()
    self.ws_client:send({
        type = "leave_room",
        payload = {},
    })
end

return RoomService
