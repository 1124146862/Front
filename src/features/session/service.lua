local SessionService = {}
SessionService.__index = SessionService

function SessionService.new(options)
    local self = setmetatable({}, SessionService)

    self.http_client = assert(options and options.http_client, "SessionService requires http_client")

    return self
end

function SessionService:fetchNicknameBySteamID(steam_id)
    local response = self.http_client:get("/session/nickname", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            exists = false,
            nickname = nil,
            message = response.error or "查询昵称失败。",
        }
    end

    local data = response.data or {}

    return {
        ok = true,
        exists = data.exists == true,
        nickname = data.nickname,
        message = data.message or "查询完成。",
    }
end

function SessionService:submitNickname(steam_id, nickname)
    local response = self.http_client:post("/session/nickname", {
        steam_id = steam_id,
        nickname = nickname,
    })

    if not response.ok then
        return {
            ok = false,
            nickname = nickname,
            message = response.error or "昵称提交失败。",
        }
    end

    local data = response.data or {}

    return {
        ok = true,
        nickname = data.nickname or nickname,
        message = data.message or "昵称设置成功。",
    }
end

return SessionService
