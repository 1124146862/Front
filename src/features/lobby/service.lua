local LobbyService = {}
LobbyService.__index = LobbyService

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
            message = response.error or "房间列表加载失败。",
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
        message = "大厅列表已刷新。",
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
            message = response.error or "创建房间失败。",
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        room_id = data.room_id,
        message = "创建房间成功。",
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
            message = response.error or "加入房间失败。",
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        room_id = data.room_id or tostring(room_id),
        message = "加入房间成功。",
    }
end

return LobbyService
