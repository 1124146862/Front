local LobbyService = {}
LobbyService.__index = LobbyService

local I18n = require("src.core.i18n.i18n")

local function extractRoomId(response, data, fallback_room_id)
    if data and data.room_id ~= nil and tostring(data.room_id) ~= "" then
        print(string.format(
            "[lobby_service] room_id from data.room_id=%s",
            tostring(data.room_id)
        ))
        return tostring(data.room_id)
    end

    if fallback_room_id ~= nil and tostring(fallback_room_id) ~= "" then
        print(string.format(
            "[lobby_service] room_id from fallback=%s",
            tostring(fallback_room_id)
        ))
        return tostring(fallback_room_id)
    end

    local raw_body = tostring((response or {}).raw_body or "")
    local room_id = raw_body:match([["room_id":"([^"]+)"]])
    if room_id and room_id ~= "" then
        print(string.format(
            "[lobby_service] room_id from raw_body=%s",
            tostring(room_id)
        ))
        return room_id
    end

    print(string.format(
        "[lobby_service] room_id missing response_ok=%s has_data=%s raw_body_prefix=%s",
        tostring(response and response.ok),
        tostring(data ~= nil),
        tostring(raw_body:sub(1, 120))
    ))
    return nil
end

function LobbyService.new(options)
    local self = setmetatable({}, LobbyService)

    self.http_client = assert(options and options.http_client, "LobbyService requires http_client")

    return self
end

function LobbyService:fetchRooms(page, page_size)
    local response = self.http_client:get("/lobby/rooms", {
        page = page,
        page_size = page_size,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("lobby.load_failed"),
        }
    end

    local data = response.data or {}

    return {
        ok = true,
        total = data.total or 0,
        page = data.page or page,
        page_size = data.page_size or page_size,
        has_prev = data.has_prev == true,
        has_next = data.has_next == true,
        rooms = data.rooms or {},
        message = I18n:t("lobby.refreshed"),
    }
end

function LobbyService:createRoom(steam_id, title, game_mode, password)
    local response = self.http_client:post("/lobby/rooms", {
        steam_id = steam_id,
        title = title,
        game_mode = game_mode,
        password = password ~= "" and password or nil,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("lobby.create_failed"),
        }
    end

    local data = response.data or {}
    local room_id = extractRoomId(response, data)
    if not room_id then
        return {
            ok = false,
            message = I18n:t("lobby.create_failed"),
        }
    end

    return {
        ok = true,
        room_id = room_id,
        message = I18n:t("lobby.create_success"),
    }
end

function LobbyService:fetchRoomDetail(room_id)
    local response = self.http_client:get("/lobby/rooms/" .. tostring(room_id))

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("lobby.detail_failed"),
            error_code = response.error_code,
        }
    end

    return {
        ok = true,
        room = response.data or {},
    }
end

function LobbyService:joinRoom(room_id, steam_id, password)
    local response = self.http_client:post("/lobby/rooms/" .. tostring(room_id) .. "/join", {
        steam_id = steam_id,
        password = password ~= "" and password or nil,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("lobby.join_failed"),
            error_code = response.error_code,
        }
    end

    local data = response.data or {}
    local resolved_room_id = extractRoomId(response, data, room_id)
    if not resolved_room_id then
        return {
            ok = false,
            message = I18n:t("lobby.join_failed"),
            error_code = response.error_code,
        }
    end

    return {
        ok = true,
        room_id = resolved_room_id,
        message = I18n:t("lobby.join_success"),
    }
end

return LobbyService
