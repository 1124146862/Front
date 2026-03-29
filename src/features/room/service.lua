local RoomService = {}
RoomService.__index = RoomService

function RoomService.new(options)
    local self = setmetatable({}, RoomService)

    self.http_client = assert(options and options.http_client, "RoomService requires http_client")

    return self
end

function RoomService:fetchRoom(room_id, steam_id)
    local response = self.http_client:get("/room/" .. tostring(room_id), {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or "房间信息加载失败。",
        }
    end

    return {
        ok = true,
        room = response.data or {},
        message = "房间信息已刷新。",
    }
end

function RoomService:setReady(room_id, steam_id, is_ready)
    local response = self.http_client:post("/room/" .. tostring(room_id) .. "/ready", {
        steam_id = steam_id,
        is_ready = is_ready,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or "准备状态更新失败。",
        }
    end

    return {
        ok = true,
        room = response.data or {},
        message = is_ready and "已准备。" or "已取消准备。",
    }
end

function RoomService:updateConfig(room_id, steam_id, title, game_mode, password)
    local response = self.http_client:patch("/room/" .. tostring(room_id) .. "/config", {
        steam_id = steam_id,
        title = title,
        game_mode = game_mode,
        password = password ~= "" and password or nil,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or "房间配置保存失败。",
        }
    end

    return {
        ok = true,
        room = response.data or {},
        message = "房间配置已保存。",
    }
end

function RoomService:leaveRoom(room_id, steam_id)
    local response = self.http_client:post("/room/" .. tostring(room_id) .. "/leave", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or "离开房间失败。",
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        deleted = data.deleted == true,
        message = data.message or "已离开房间。",
    }
end

return RoomService
