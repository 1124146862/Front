local SessionService = {}
SessionService.__index = SessionService

local I18n = require("src.core.i18n.i18n")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")

local function emptyAccessories()
    return {
        owned_item_ids = {},
        equipped = {
            frame = nil,
        },
    }
end

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
            avatar_id = "avatar_1",
            coins = 300,
            accessories = emptyAccessories(),
            card_settings = {
                theme_id = ThemeCatalog.DEFAULT_THEME_ID,
                back_id = "classic_grid",
            },
            message = response.error or I18n:t("session.fetch_failed"),
        }
    end

    local data = response.data or {}

    return {
        ok = true,
        exists = data.exists == true,
        nickname = data.nickname,
        avatar_id = data.avatar_id or "avatar_1",
        coins = tonumber(data.coins) or 300,
        accessories = data.accessories or emptyAccessories(),
        card_settings = data.card_settings or { theme_id = ThemeCatalog.DEFAULT_THEME_ID, back_id = "classic_grid" },
        message = data.message or I18n:t("session.fetch_done"),
    }
end

function SessionService:submitNickname(steam_id, nickname, avatar_id)
    local response = self.http_client:post("/session/nickname", {
        steam_id = steam_id,
        nickname = nickname,
        avatar_id = avatar_id or "avatar_1",
    })

    if not response.ok then
        return {
            ok = false,
            nickname = nickname,
            avatar_id = avatar_id or "avatar_1",
            coins = 300,
            accessories = emptyAccessories(),
            card_settings = {
                theme_id = ThemeCatalog.DEFAULT_THEME_ID,
                back_id = "classic_grid",
            },
            message = response.error or I18n:t("session.submit_failed"),
        }
    end

    local data = response.data or {}

    return {
        ok = true,
        nickname = data.nickname or nickname,
        avatar_id = data.avatar_id or avatar_id or "avatar_1",
        coins = tonumber(data.coins) or 300,
        accessories = data.accessories or emptyAccessories(),
        card_settings = data.card_settings or { theme_id = ThemeCatalog.DEFAULT_THEME_ID, back_id = "classic_grid" },
        message = data.message or I18n:t("session.submit_success"),
    }
end

function SessionService:updateCardSettings(steam_id, card_settings)
    local response = self.http_client:post("/session/card-settings", {
        steam_id = steam_id,
        card_settings = {
            theme_id = ThemeCatalog.normalizeThemeId(card_settings and card_settings.theme_id),
            back_id = (card_settings and card_settings.back_id) or "classic_grid",
        },
    })

    if not response.ok then
        return {
            ok = false,
            card_settings = card_settings,
            message = response.error or I18n:t("session.submit_failed"),
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        card_settings = data.card_settings or card_settings or { theme_id = ThemeCatalog.DEFAULT_THEME_ID, back_id = "classic_grid" },
        message = data.message or I18n:t("session.submit_success"),
    }
end

function SessionService:returnToMainMenu(steam_id)
    local response = self.http_client:post("/session/return-to-main-menu", {
        steam_id = steam_id,
    })

    if not response.ok then
        return {
            ok = false,
            cleaned_room_ids = {},
            deleted_room_ids = {},
            message = response.error or "return_to_main_menu_failed",
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        cleaned_room_ids = data.cleaned_room_ids or {},
        deleted_room_ids = data.deleted_room_ids or {},
        message = data.message or "returned_to_main_menu",
    }
end

function SessionService:purchaseAccessory(steam_id, item_id)
    local response = self.http_client:post("/session/accessories/purchase", {
        steam_id = steam_id,
        item_id = item_id,
    })

    if not response.ok then
        return {
            ok = false,
            item_id = item_id,
            message = response.error or I18n:t("main_menu.wardrobe_purchase_failed"),
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        item_id = item_id,
        coins = tonumber(data.coins) or 300,
        accessories = data.accessories or emptyAccessories(),
        message = data.message or I18n:t("main_menu.wardrobe_purchase_success"),
    }
end

function SessionService:equipAccessory(steam_id, slot, item_id)
    local response = self.http_client:post("/session/accessories/equip", {
        steam_id = steam_id,
        slot = slot,
        item_id = item_id,
    })

    if not response.ok then
        return {
            ok = false,
            slot = slot,
            item_id = item_id,
            message = response.error or I18n:t("main_menu.wardrobe_equip_failed"),
        }
    end

    local data = response.data or {}
    return {
        ok = true,
        slot = slot,
        item_id = item_id,
        coins = tonumber(data.coins) or 300,
        accessories = data.accessories or emptyAccessories(),
        message = data.message or I18n:t("main_menu.wardrobe_equip_success"),
    }
end

return SessionService
