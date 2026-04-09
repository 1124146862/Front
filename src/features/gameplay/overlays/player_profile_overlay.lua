local WoodPanel = require("src.core.ui.wood_panel")
local IconCloseButton = require("src.core.ui.icon_close_button")
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local RelationPalette = require("src.features.gameplay.relation_palette")
local I18n = require("src.core.i18n.i18n")

local PlayerProfileOverlay = {}
PlayerProfileOverlay.__index = PlayerProfileOverlay

function PlayerProfileOverlay.new(options)
    local self = setmetatable({}, PlayerProfileOverlay)
    self.fonts = assert(options and options.fonts, "PlayerProfileOverlay requires fonts")
    self.style = assert(options and options.style, "PlayerProfileOverlay requires style")
    self.panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.avatars_by_id = {}
    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end
    return self
end

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function resolveAvatarId(player, my_steam_id, my_avatar_id)
    local explicit_avatar = tostring((player or {}).avatar_id or "")
    if explicit_avatar ~= "" then
        return explicit_avatar
    end
    if tonumber((player or {}).player_id) == tonumber(my_steam_id) and tostring(my_avatar_id or "") ~= "" then
        return tostring(my_avatar_id)
    end
    local seat_index = tonumber((player or {}).seat_index) or 0
    local seed = ((player or {}).is_bot == true) and (seat_index + 13) or (seat_index + 1)
    return ("avatar_%d"):format((seed % 32) + 1)
end

local function resolveAccessories(player, my_steam_id, my_accessories)
    if type((player or {}).accessories) == "table" then
        return player.accessories
    end
    if tonumber((player or {}).player_id) == tonumber(my_steam_id) and type(my_accessories) == "table" then
        return my_accessories
    end
    return nil
end

local function resolveRelativeSeatLabel(my_seat_index, seat_index)
    if my_seat_index == nil or seat_index == nil then
        return nil
    end

    local relative = (seat_index - my_seat_index + 4) % 4
    if relative == 0 then
        return I18n:t("gameplay.self")
    end
    if relative == 1 then
        return I18n:t("gameplay.next")
    end
    if relative == 2 then
        return I18n:t("gameplay.opposite")
    end
    return I18n:t("gameplay.previous")
end

local function resolveRelativeSeatKey(my_seat_index, seat_index)
    if my_seat_index == nil or seat_index == nil then
        return nil
    end

    local relative = (seat_index - my_seat_index + 4) % 4
    if relative == 0 then
        return "self"
    end
    if relative == 1 then
        return "next"
    end
    if relative == 2 then
        return "opposite"
    end
    return "previous"
end

function PlayerProfileOverlay:getFrame(window_width, window_height)
    local width = math.min(420, window_width - 96)
    local height = math.min(300, window_height - 96)
    return {
        x = math.floor((window_width - width) * 0.5),
        y = math.floor((window_height - height) * 0.5),
        width = width,
        height = height,
    }
end

function PlayerProfileOverlay:getCloseBounds(window_width, window_height)
    local frame = self:getFrame(window_width, window_height)
    return {
        x = frame.x + frame.width - 54,
        y = frame.y + 16,
        width = 36,
        height = 36,
    }
end

function PlayerProfileOverlay:getControlAt(x, y, window_width, window_height)
    if contains(self:getCloseBounds(window_width, window_height), x, y) then
        return "close_player_profile"
    end
    return nil
end

function PlayerProfileOverlay:draw(player, options)
    options = options or {}
    local window_width = options.window_width or love.graphics.getWidth()
    local window_height = options.window_height or love.graphics.getHeight()
    local hovered_close = options.hovered_close == true
    local my_steam_id = options.my_steam_id
    local my_avatar_id = options.my_avatar_id
    local my_accessories = options.my_accessories
    local my_seat_index = tonumber(options.my_seat_index)

    local frame = self:getFrame(window_width, window_height)
    local colors = self.style.colors
    local nickname = tostring((player or {}).nickname or "-")
    local seat_index = tonumber((player or {}).seat_index)
    local relative_role_key = resolveRelativeSeatKey(my_seat_index, seat_index)
    local relative_label = resolveRelativeSeatLabel(my_seat_index, seat_index)
    local seat_text = relative_label or (seat_index ~= nil and string.format("%d", seat_index + 1) or "-")
    local role_text = (player or {}).is_bot and I18n:t("room.role_bot") or I18n:t("room.role_player")
    local seat_label = I18n:t("room.seat", { seat = seat_text })

    love.graphics.setColor(self.style.colors.overlay)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)
    self.panel:draw(frame, {
        radius = 18,
        shadow_offset = 8,
        inner_inset = 10,
    })

    love.graphics.setColor(colors.hud_title or colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf(I18n:t("gameplay.player_profile_title"), frame.x, frame.y + 18, frame.width, "center")

    love.graphics.setColor(colors.panel_grain[1], colors.panel_grain[2], colors.panel_grain[3], 0.32)
    love.graphics.rectangle("fill", frame.x + 22, frame.y + 56, frame.width - 44, 2)

    local avatar_bounds = {
        x = frame.x + math.floor((frame.width - 126) * 0.5),
        y = frame.y + 72,
        w = 126,
        h = 126,
    }
    local avatar_id = resolveAvatarId(player or {}, my_steam_id, my_avatar_id)
    local avatar = self.avatars_by_id[avatar_id]
    if avatar then
        AvatarTile.draw(self.style, avatar, avatar_bounds, {
            hovered = false,
            selected = true,
            pin_frame = true,
            accessories = resolveAccessories(player or {}, my_steam_id, my_accessories),
        })
    end

    local name_card = {
        x = frame.x + 52,
        y = frame.y + 212,
        width = frame.width - 104,
        height = 66,
    }
    love.graphics.setColor(colors.card_alt[1], colors.card_alt[2], colors.card_alt[3], 0.12)
    love.graphics.rectangle("fill", name_card.x, name_card.y, name_card.width, name_card.height, 14, 14)
    love.graphics.setColor(colors.panel_border[1], colors.panel_border[2], colors.panel_border[3], 0.22)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", name_card.x + 1, name_card.y + 1, name_card.width - 2, name_card.height - 2, 14, 14)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(colors.hud_text or colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf(nickname, name_card.x + 12, name_card.y + 10, name_card.width - 24, "center")

    local function drawMetaPill(x, y, width, label, palette)
        palette = palette or {
            fill = colors.hud_badge_fill,
            border = colors.hud_badge_border,
            text = colors.hud_badge_text or colors.hud_subtext or colors.text_secondary,
        }
        love.graphics.setColor(palette.fill[1], palette.fill[2], palette.fill[3], 0.92)
        love.graphics.rectangle("fill", x, y, width, 20, 10, 10)
        love.graphics.setColor(palette.border[1], palette.border[2], palette.border[3], 0.65)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, 19, 10, 10)
        love.graphics.setColor(palette.text)
        love.graphics.setFont(self.fonts:get("Caption"))
        love.graphics.printf(label, x, y + 3, width, "center")
    end

    local pill_gap = 10
    local caption_font = self.fonts:get("Caption")
    local seat_w = math.max(94, caption_font:getWidth(seat_label) + 24)
    local role_w = math.max(78, caption_font:getWidth(role_text) + 24)
    local total_w = seat_w + role_w + pill_gap
    local pill_x = name_card.x + math.floor((name_card.width - total_w) * 0.5)
    local pill_y = name_card.y + 40
    drawMetaPill(pill_x, pill_y, seat_w, seat_label, relative_role_key and RelationPalette.get(relative_role_key) or nil)
    drawMetaPill(pill_x + seat_w + pill_gap, pill_y, role_w, role_text)

    self.close_button:draw(self:getCloseBounds(window_width, window_height), hovered_close)
end

return PlayerProfileOverlay
