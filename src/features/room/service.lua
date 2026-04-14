local RoomService = {}
RoomService.__index = RoomService
local I18n = require("src.core.i18n.i18n")

local function normalizePlayer(player)
    local normalized = player or {}
    if normalized.steam_id ~= nil then
        normalized.steam_id = tostring(normalized.steam_id)
    end
    return normalized
end

local function normalizeRoom(room)
    local normalized = room or {}
    if normalized.owner_steam_id ~= nil then
        normalized.owner_steam_id = tostring(normalized.owner_steam_id)
    end

    local players = {}
    for _, player in ipairs(normalized.players or {}) do
        players[#players + 1] = normalizePlayer(player)
    end
    normalized.players = players
    return normalized
end

local function wrapRoomResponse(response, fallback_message)
    if not response.ok then
        return {
            ok = false,
            status = response.status,
            error_code = response.error_code,
            message = response.error or fallback_message or I18n:t("room.load_failed"),
        }
    end

    return {
        ok = true,
        room = normalizeRoom(response.data or {}),
        message = (response.data or {}).message or fallback_message or I18n:t("room.room_refreshed"),
    }
end

function RoomService.new(options)
    local self = setmetatable({}, RoomService)

    self.http_client = assert(options and options.http_client, "RoomService requires http_client")
    self.ws_client = assert(options and options.ws_client, "RoomService requires ws_client")

    return self
end

function RoomService:fetchRoom(room_id, steam_id)
    return wrapRoomResponse(self.http_client:get("/room/" .. tostring(room_id), {
        steam_id = steam_id,
    }), I18n:t("room.room_refreshed"))
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

function RoomService:setReady(room_id, steam_id, is_ready)
    return wrapRoomResponse(self.http_client:post("/room/" .. tostring(room_id) .. "/ready", {
        steam_id = steam_id,
        is_ready = is_ready == true,
    }), I18n:t("room.saving_ready"))
end

function RoomService:changeSeat(room_id, steam_id, seat_index)
    return wrapRoomResponse(self.http_client:post("/room/" .. tostring(room_id) .. "/seat", {
        steam_id = steam_id,
        seat_index = seat_index,
    }), I18n:t("room.room_refreshed"))
end

function RoomService:updateConfig(room_id, steam_id, title, game_mode, password)
    return wrapRoomResponse(self.http_client:patch("/room/" .. tostring(room_id) .. "/config", {
        steam_id = steam_id,
        title = title,
        game_mode = game_mode,
        password = password ~= "" and password or nil,
    }), I18n:t("room.saving_config"))
end

function RoomService:addBot(room_id, steam_id)
    return wrapRoomResponse(self.http_client:post("/room/" .. tostring(room_id) .. "/bots", {
        steam_id = steam_id,
    }), I18n:t("room.adding_bot"))
end

function RoomService:removeBot(room_id, steam_id, bot_steam_id)
    return wrapRoomResponse(self.http_client:post("/room/" .. tostring(room_id) .. "/bots/remove", {
        steam_id = steam_id,
        bot_steam_id = bot_steam_id,
    }), I18n:t("room.room_refreshed"))
end

function RoomService:leaveRoom(room_id, steam_id)
    local response = self.http_client:post("/room/" .. tostring(room_id) .. "/leave", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            status = response.status,
            error_code = response.error_code,
            deleted = false,
            message = response.error or I18n:t("room.load_failed"),
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        room_id = tostring(data.room_id or room_id),
        deleted = data.deleted == true,
        message = data.message or I18n:t("room.leaving"),
    }
end

return RoomService
