local RoomPlayerStatusCard = {}
RoomPlayerStatusCard.__index = RoomPlayerStatusCard

local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")

local AVATARS_BY_ID = {}
for _, avatar in ipairs(AvatarRegistry) do
    AVATARS_BY_ID[avatar.id] = avatar
end

local function fitFont(fonts, text, width, candidates)
    local safe_text = tostring(text or "")
    for _, token in ipairs(candidates) do
        local font = fonts:get(token)
        if font:getWidth(safe_text) <= width then
            return font
        end
    end
    return fonts:get(candidates[#candidates])
end

local function roomText(key, fallback, params)
    local value = I18n:t(key, params)
    if value == key then
        return fallback
    end
    return value
end

local function resolveSeatTeam(seat_index)
    local numeric_seat_index = tonumber(seat_index) or 0
    if numeric_seat_index % 2 == 0 then
        return 1
    end
    return 2
end

local function resolveRoleText(player)
    if player and player.is_owner then
        return I18n:t("room.role_owner")
    end
    if player and player.is_bot then
        return I18n:t("room.role_bot")
    end
    return nil
end

local function resolveBadgeLayout(card)
    local right_pad = 16
    local badge_gap = 10
    local action_gap = 8
    local badge_height = 34
    local role_text = resolveRoleText(card.player)
    local role_badge_width = role_text and 82 or 0
    local ready_badge_width = 0
    if card.player then
        ready_badge_width = 104
    elseif card.clickable then
        ready_badge_width = 120
    end
    local remove_button_width = card.remove_action and 92 or 0
    local cursor_x = card.x + card.width - right_pad
    local remove_x = nil
    if remove_button_width > 0 then
        remove_x = cursor_x - remove_button_width
        cursor_x = remove_x - action_gap
    end

    local ready_x = nil
    if ready_badge_width > 0 then
        ready_x = cursor_x - ready_badge_width
        cursor_x = ready_x
    end

    local role_x = nil
    if role_badge_width > 0 then
        role_x = cursor_x - badge_gap - role_badge_width
        cursor_x = role_x
    end

    return {
        badge_y = card.y + math.floor((card.height - badge_height) * 0.5),
        badge_height = badge_height,
        text_right = cursor_x,
        role_text = role_text,
        role_badge_width = role_badge_width,
        ready_badge_width = ready_badge_width,
        role_x = role_x,
        ready_x = ready_x,
        remove_x = remove_x,
        remove_button_width = remove_button_width,
    }
end

local function resolveDangerPalette(colors, hovered)
    local face = hovered and { 0.96, 0.82, 0.74, 1 } or { 0.93, 0.80, 0.72, 1 }
    return {
        frame = { 0.66, 0.34, 0.25, 1 },
        face = face,
        shadow = { 0.36, 0.18, 0.08, 0.82 },
        highlight = { 1.0, 0.92, 0.88, 0.18 },
        border = { colors.error[1], colors.error[2], colors.error[3], 0.96 },
        grain = { 0.74, 0.46, 0.38, 0.12 },
        text = { 0.60, 0.22, 0.16, 1 },
    }
end

local function drawBadge(fonts, colors, x, y, width, label, palette)
    local height = 34
    love.graphics.setColor(palette.fill)
    love.graphics.rectangle("fill", x, y, width, height, 12, 12)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(palette.border)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 12, 12)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(palette.text)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(label, x, y + 7, width, "center")
end

local function resolveAvatar(player)
    local avatar_id = tostring((player or {}).avatar_id or "")
    if avatar_id ~= "" and AVATARS_BY_ID[avatar_id] then
        return AVATARS_BY_ID[avatar_id]
    end
    return AVATARS_BY_ID.avatar_1 or AvatarRegistry[1]
end

local function drawEmptyAvatar(colors, x, y, size)
    local radius = math.floor(size * 0.18)
    local border = colors.button_secondary_border
    local fill = colors.button_secondary_face

    love.graphics.setColor(fill[1], fill[2], fill[3], 0.7)
    love.graphics.rectangle("fill", x, y, size, size, radius, radius)

    love.graphics.setColor(border[1], border[2], border[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x + 1, y + 1, size - 2, size - 2, radius, radius)

    local center_x = x + size * 0.5
    local center_y = y + size * 0.5
    local cross = math.max(8, math.floor(size * 0.18))
    love.graphics.line(center_x - cross, center_y, center_x + cross, center_y)
    love.graphics.line(center_x, center_y - cross, center_x, center_y + cross)
    love.graphics.setLineWidth(1)
end

function RoomPlayerStatusCard.new(options)
    local self = setmetatable({}, RoomPlayerStatusCard)

    self.player = options and options.player or nil
    self.index = options.index or 1
    self.seat_index = options and options.seat_index or 0
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 720
    self.height = options.height or 74
    self.hovered = options and options.hovered == true
    self.clickable = options and options.clickable == true
    self.is_self = options and options.is_self == true
    self.remove_action = options and options.remove_action or nil

    return self
end

function RoomPlayerStatusCard.getRemoveActionBounds(options)
    local probe = {
        player = options and options.player or nil,
        x = options and options.x or 0,
        y = options and options.y or 0,
        width = options and options.width or 720,
        height = options and options.height or 74,
        clickable = options and options.clickable == true,
        remove_action = options and options.remove_action or nil,
    }
    local layout = resolveBadgeLayout(probe)
    if layout.remove_button_width <= 0 or layout.remove_x == nil then
        return nil
    end
    return {
        x = layout.remove_x,
        y = layout.badge_y,
        width = layout.remove_button_width,
        height = layout.badge_height,
    }
end

function RoomPlayerStatusCard:draw(fonts, style)
    local colors = style.colors
    local team_index = resolveSeatTeam(self.seat_index)
    local seat_text = roomText("room.team", "队伍 {team}", { team = tostring(team_index) })
    local background = (self.index % 2 == 1) and colors.card or colors.card_alt
    if self.clickable then
        background = colors.card_alt
    end
    if self.is_self then
        background = colors.card_highlight
    end

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 14, 14)

    if self.hovered and self.clickable then
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 14, 14)
    end

    love.graphics.setLineWidth(1)
    if self.hovered and self.clickable then
        love.graphics.setColor(colors.button_primary_border)
    elseif self.is_self then
        love.graphics.setColor(colors.button_secondary_border)
    else
        love.graphics.setColor(colors.card_border)
    end
    love.graphics.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2, 14, 14)
    love.graphics.setLineWidth(1)

    local avatar_size = math.max(42, self.height - 22)
    local avatar_x = self.x + 14
    local avatar_y = self.y + math.floor((self.height - avatar_size) * 0.5)
    if self.player then
        local avatar = resolveAvatar(self.player)
        AvatarTile.draw(style, avatar, {
            x = avatar_x,
            y = avatar_y,
            w = avatar_size,
            h = avatar_size,
        }, {
            compact = true,
            pin_frame = true,
            hovered = self.hovered,
            accessories = self.player.accessories,
            content_padding_ratio = 0.02,
        })
    else
        drawEmptyAvatar(colors, avatar_x, avatar_y, avatar_size)
    end

    local layout = resolveBadgeLayout(self)
    local text_x = avatar_x + avatar_size + 16
    local text_width = math.max(120, layout.text_right - text_x)
    local seat_font = fonts:get("TextSmall")
    local nickname_text = self.player and tostring(self.player.nickname or "-")
        or (self.clickable and roomText("room.empty_seat_clickable", "空位，可换位") or roomText("room.empty_seat", "空位"))
    local seat_width = seat_font:getWidth(seat_text)
    local nickname_width = math.max(64, text_width - seat_width - 12)
    local nickname_font = fitFont(fonts, nickname_text, nickname_width, { "Text", "TextSmall", "Caption" })
    local line_height = math.max(seat_font:getHeight(), nickname_font:getHeight())
    local line_y = self.y + math.floor((self.height - line_height) * 0.5) - 1

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(seat_font)
    love.graphics.print(seat_text, text_x, line_y + math.floor((line_height - seat_font:getHeight()) * 0.5))

    love.graphics.setColor(self.player and colors.text_primary or colors.text_muted)
    love.graphics.setFont(nickname_font)
    love.graphics.printf(
        nickname_text,
        text_x + seat_width + 12,
        line_y + math.floor((line_height - nickname_font:getHeight()) * 0.5),
        nickname_width,
        "left"
    )

    local badge_x = layout.ready_x
    local badge_y = layout.badge_y
    local ready_badge_width = layout.ready_badge_width

    if layout.role_text then
        drawBadge(fonts, colors, layout.role_x, layout.badge_y, layout.role_badge_width, layout.role_text, {
            fill = colors.button_secondary_face,
            border = colors.button_secondary_border,
            text = colors.button_secondary_text,
        })
    end

    if self.player then
        local ready_text = self.player.is_ready and I18n:t("room.player_ready") or I18n:t("room.player_not_ready")
        local ready_color = self.player.is_ready and colors.ok or colors.warning
        drawBadge(fonts, colors, layout.ready_x, layout.badge_y, layout.ready_badge_width, ready_text, {
            fill = self.player.is_ready and { ready_color[1], ready_color[2], ready_color[3], 0.18 } or { ready_color[1], ready_color[2], ready_color[3], 0.16 },
            border = ready_color,
            text = ready_color,
        })
    elseif self.clickable then
        drawBadge(fonts, colors, badge_x, badge_y, ready_badge_width, roomText("room.choose_seat", "换位"), {
            fill = { colors.button_primary_face[1], colors.button_primary_face[2], colors.button_primary_face[3], 0.26 },
            border = colors.button_primary_border,
            text = colors.button_primary_text,
        })
    end

    if self.remove_action and layout.remove_x ~= nil then
        WoodButton.draw(fonts, style, {
            label = self.remove_action.label or roomText("room.remove_bot", "删除"),
            x = layout.remove_x,
            y = layout.badge_y,
            width = layout.remove_button_width,
            height = layout.badge_height,
            hovered = self.remove_action.hovered == true,
            enabled = self.remove_action.enabled ~= false,
            variant = "secondary",
            palette_override = self.remove_action.enabled ~= false and resolveDangerPalette(colors, self.remove_action.hovered == true) or nil,
            font_token = "Caption",
            radius = 10,
            shadow_offset = 3,
            inner_inset = 4,
            light_chrome = true,
        })
    end
end

return RoomPlayerStatusCard
