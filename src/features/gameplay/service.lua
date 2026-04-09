local GameplayService = {}
GameplayService.__index = GameplayService
local I18n = require("src.core.i18n.i18n")

function GameplayService.new(options)
    local self = setmetatable({}, GameplayService)

    self.http_client = assert(options and options.http_client, "GameplayService requires http_client")
    self.ws_client = options and options.ws_client or nil

    return self
end

function GameplayService:fetchGame(room_id, steam_id)
    local response = self.http_client:get("/gameplay/" .. tostring(room_id), {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("gameplay.load_failed"),
        }
    end

    return {
        ok = true,
        game = response.data or {},
    }
end

function GameplayService:connectGameChannel(room_id, steam_id)
    if self.ws_client then
        self.ws_client:start(room_id, steam_id)
    end
end

function GameplayService:disconnectGameChannel(fast)
    if self.ws_client then
        self.ws_client:stop(fast == true)
    end
end

function GameplayService:pollGameChannel()
    if not self.ws_client then
        return {}
    end
    return self.ws_client:poll()
end

function GameplayService:requestGameSnapshot()
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "request_game_snapshot",
        payload = {},
    })
end

function GameplayService:playCards(cards, command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "play_cards",
        payload = {
            cards = cards,
            command_id = command_id,
        },
    })
end

function GameplayService:passTurn(command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "pass_turn",
        payload = {
            command_id = command_id,
        },
    })
end

function GameplayService:startNextHand(command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "start_next_hand",
        payload = {
            command_id = command_id,
        },
    })
end

function GameplayService:skipRemainingCardsView(command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "skip_remaining_cards_view",
        payload = {
            command_id = command_id,
        },
    })
end

function GameplayService:confirmRematch(command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "confirm_rematch",
        payload = {
            command_id = command_id,
        },
    })
end

function GameplayService:leaveRoom(room_id, steam_id)
    local response = self.http_client:post("/room/" .. tostring(room_id) .. "/leave", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            message = response.error or I18n:t("gameplay.realtime_failed"),
        }
    end

    return {
        ok = true,
        payload = response.data or {},
    }
end

function GameplayService:returnToMainMenu(steam_id)
    local response = self.http_client:post("/session/return-to-main-menu", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            cleaned_room_ids = {},
            deleted_room_ids = {},
            managed_room_ids = {},
            message = response.error or I18n:t("gameplay.realtime_failed"),
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        cleaned_room_ids = data.cleaned_room_ids or {},
        deleted_room_ids = data.deleted_room_ids or {},
        managed_room_ids = data.managed_room_ids or {},
        message = data.message or "returned_to_main_menu",
    }
end

function GameplayService:debugAutoplayHand(command_id)
    if not self.ws_client then
        return
    end

    self.ws_client:send({
        type = "debug_autoplay_hand",
        payload = {
            command_id = command_id,
        },
    })
end

function GameplayService:submitTribute(card_id, command_id)
    if not self.ws_client then
        return
    end
    self.ws_client:send({
        type = "submit_tribute",
        payload = {
            card_id = card_id,
            command_id = command_id,
        },
    })
end

function GameplayService:submitReturnTribute(card_id, command_id)
    if not self.ws_client then
        return
    end
    self.ws_client:send({
        type = "submit_return_tribute",
        payload = {
            card_id = card_id,
            command_id = command_id,
        },
    })
end

function GameplayService:completeAntiTribute(command_id)
    if not self.ws_client then
        return
    end
    self.ws_client:send({
        type = "complete_anti_tribute",
        payload = {
            command_id = command_id,
        },
    })
end

return GameplayService
