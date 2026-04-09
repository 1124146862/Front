local MainMenuService = {}
MainMenuService.__index = MainMenuService

local I18n = require("src.core.i18n.i18n")

local function extractRoomId(response, data)
    if data and data.room_id ~= nil and tostring(data.room_id) ~= "" then
        print(string.format(
            "[main_menu_service] room_id from data.room_id=%s",
            tostring(data.room_id)
        ))
        return tostring(data.room_id)
    end

    local snapshot = data and data.snapshot or nil
    if snapshot and snapshot.room_id ~= nil and tostring(snapshot.room_id) ~= "" then
        print(string.format(
            "[main_menu_service] room_id from data.snapshot.room_id=%s",
            tostring(snapshot.room_id)
        ))
        return tostring(snapshot.room_id)
    end

    local raw_body = tostring((response or {}).raw_body or "")
    local room_id = raw_body:match([["room_id":"([^"]+)"]])
    if room_id and room_id ~= "" then
        print(string.format(
            "[main_menu_service] room_id from raw_body=%s",
            tostring(room_id)
        ))
        return room_id
    end

    print(string.format(
        "[main_menu_service] room_id missing response_ok=%s has_data=%s raw_body_prefix=%s",
        tostring(response and response.ok),
        tostring(data ~= nil),
        tostring(raw_body:sub(1, 120))
    ))
    return nil
end

function MainMenuService.new(options)
    local self = setmetatable({}, MainMenuService)

    self.http_client = assert(options and options.http_client, "MainMenuService requires http_client")

    return self
end

function MainMenuService:startSinglePlayerGame(steam_id, game_mode)
    local response = self.http_client:post("/gameplay/single-player/start", {
        steam_id = steam_id,
        game_mode = game_mode or "classic",
    })
    print(string.format(
        "[main_menu_service] startSinglePlayerGame response ok=%s status=%s has_data=%s",
        tostring(response and response.ok),
        tostring(response and response.status),
        tostring(response and response.data ~= nil)
    ))

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("main_menu.single_player_failed"),
        }
    end

    local data = response.data or {}
    local room_id = extractRoomId(response, data)
    if not room_id then
        print("[main_menu_service] startSinglePlayerGame returning failure because room_id missing")
        return {
            ok = false,
            message = I18n:t("main_menu.single_player_failed"),
        }
    end

    print(string.format(
        "[main_menu_service] startSinglePlayerGame success room_id=%s snapshot_room_id=%s",
        tostring(room_id),
        tostring(data.snapshot and data.snapshot.room_id)
    ))
    return {
        ok = true,
        room_id = room_id,
        snapshot = data.snapshot or nil,
    }
end

local function normalizeMatchmakingResult(data, fallback_message)
    data = data or {}
    return {
        ok = true,
        phase = data.phase or "idle",
        player_count = tonumber(data.player_count) or 0,
        required_player_count = tonumber(data.required_player_count) or 4,
        elapsed_seconds = tonumber(data.elapsed_seconds) or 0,
        countdown_seconds = tonumber(data.countdown_seconds) or 0,
        room_id = data.room_id and tostring(data.room_id) or nil,
        message = data.message or fallback_message or "",
    }
end

function MainMenuService:joinMatchmaking(steam_id)
    local response = self.http_client:post("/matchmaking/join", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            phase = "idle",
            player_count = 0,
            required_player_count = 4,
            elapsed_seconds = 0,
            countdown_seconds = 0,
            room_id = nil,
            message = response.error or I18n:t("main_menu.matchmaking_join_failed"),
        }
    end

    return normalizeMatchmakingResult(response.data, I18n:t("main_menu.matchmaking_joined"))
end

function MainMenuService:cancelMatchmaking(steam_id)
    local response = self.http_client:post("/matchmaking/cancel", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            phase = "idle",
            player_count = 0,
            required_player_count = 4,
            elapsed_seconds = 0,
            countdown_seconds = 0,
            room_id = nil,
            message = response.error or I18n:t("main_menu.matchmaking_cancel_failed"),
        }
    end

    return normalizeMatchmakingResult(response.data, I18n:t("main_menu.matchmaking_cancelled"))
end

function MainMenuService:fetchMatchmakingStatus(steam_id, consume_match)
    local response = self.http_client:get("/matchmaking/status", {
        steam_id = steam_id,
        consume_match = consume_match == true,
    })

    if not response.ok then
        return {
            ok = false,
            phase = "idle",
            player_count = 0,
            required_player_count = 4,
            elapsed_seconds = 0,
            countdown_seconds = 0,
            room_id = nil,
            message = response.error or I18n:t("main_menu.matchmaking_status_failed"),
        }
    end

    return normalizeMatchmakingResult(response.data, "")
end

return MainMenuService
