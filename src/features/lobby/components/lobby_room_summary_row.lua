local LobbyRoomSummaryRow = {}
LobbyRoomSummaryRow.__index = LobbyRoomSummaryRow

local I18n = require("src.core.i18n.i18n")

local function drawPill(fonts, colors, x, y, width, label, palette)
    local height = 24
    local radius = 12
    love.graphics.setColor(palette.fill)
    love.graphics.rectangle("fill", x, y, width, height, radius, radius)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(palette.border)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1, radius, radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(palette.text)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(label, x, y + 4, width, "center")
end

local function drawIOSButton(fonts, style, options)
    local colors = style.colors
    local enabled = options.enabled ~= false
    local hovered = options.hovered == true
    local variant = options.variant or "secondary"
    local radius = options.radius or 12

    local face
    local border
    local text_color
    if not enabled then
        face = colors.button_disabled_face
        border = colors.button_disabled_border
        text_color = colors.button_disabled_text
    elseif variant == "primary" then
        face = hovered and colors.button_primary_hover_face or colors.button_primary_face
        border = colors.button_primary_border
        text_color = colors.button_primary_text
    else
        face = hovered and colors.button_secondary_hover_face or colors.button_secondary_face
        border = colors.button_secondary_border
        text_color = colors.button_secondary_text
    end

    love.graphics.setColor(colors.button_primary_shadow or { 0, 0, 0, 0.2 })
    love.graphics.rectangle("fill", options.x, options.y + 2, options.width, options.height, radius, radius)

    love.graphics.setColor(face)
    love.graphics.rectangle("fill", options.x, options.y, options.width, options.height, radius, radius)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", options.x + 0.5, options.y + 0.5, options.width - 1, options.height - 1, radius, radius)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(text_color)
    love.graphics.setFont(fonts:get(options.font_token or "Caption"))
    love.graphics.printf(options.label, options.x, options.y + math.floor(options.height * 0.26), options.width, "center")
end

local function translateRoomMode(game_mode)
    if game_mode == "classic" then
        return I18n:t("room.mode_classic")
    end
    if game_mode == "level" then
        local translated = I18n:t("room.mode_level")
        if translated ~= "room.mode_level" then
            return translated
        end
        return "level"
    end
    return tostring(game_mode or "-")
end

local function translateRoomStatus(status)
    if status == "waiting" then
        return I18n:t("room.status_waiting")
    end
    if status == "in_game" then
        return I18n:t("room.status_in_game")
    end
    return tostring(status or "-")
end

function LobbyRoomSummaryRow.new(options)
    local self = setmetatable({}, LobbyRoomSummaryRow)

    self.room = assert(options and options.room, "LobbyRoomSummaryRow requires room")
    self.index = options.index or 1
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 1000
    self.height = options.height or 56
    self.join_hovered = options.join_hovered == true
    self.join_enabled = (self.room.status == "waiting") and tonumber(self.room.player_count or 0) < tonumber(self.room.max_player_count or 4)

    return self
end

function LobbyRoomSummaryRow:getJoinButtonBounds()
    local height = math.max(36, self.height - 28)
    return {
        x = self.x + self.width - 156,
        y = self.y + math.floor((self.height - height) * 0.5),
        width = 126,
        height = height,
    }
end

function LobbyRoomSummaryRow:isJoinButtonHovered(x, y)
    if not self.join_enabled then
        return false
    end
    local bounds = self:getJoinButtonBounds()
    return x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height
end

function LobbyRoomSummaryRow:draw(fonts, style)
    local colors = style.colors
    local background = (self.index % 2 == 1) and colors.row or colors.row_alt
    local join_bounds = self:getJoinButtonBounds()
    local meta_y = self.y + math.floor(self.height * 0.62)
    local content_right = join_bounds.x - 16
    local meta_text = table.concat({
        translateRoomMode(self.room.game_mode),
        (self.room.has_password and I18n:t("lobby.row_password_yes")) or I18n:t("lobby.row_password_no"),
        I18n:t("lobby.header_id") .. " " .. tostring(self.room.room_id or "-"),
    }, "  ·  ")

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 14, 14)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(self.join_hovered and colors.button_primary_border or colors.card_border)
    love.graphics.rectangle("line", self.x + 0.5, self.y + 0.5, self.width - 1, self.height - 1, 14, 14)
    love.graphics.setLineWidth(1)

    local pill_y = self.y + math.floor(self.height * 0.18)
    drawPill(fonts, colors, self.x + 18, pill_y, 92, tostring(self.room.room_id or "-"), {
        fill = colors.button_secondary_face,
        border = colors.button_secondary_border,
        text = colors.button_secondary_text,
        shadow = colors.button_secondary_shadow,
    })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("TextBig"))
    love.graphics.printf(tostring(self.room.title or "-"), self.x + 124, self.y + math.floor(self.height * 0.16), content_right - (self.x + 124), "left")

    drawPill(fonts, colors, content_right - 188, pill_y, 72, string.format("%s/%s", tostring(self.room.player_count or 0), tostring(self.room.max_player_count or 4)), {
        fill = colors.button_primary_face,
        border = colors.button_primary_border,
        text = colors.button_primary_text,
        shadow = colors.button_primary_shadow,
    })
    drawPill(fonts, colors, content_right - 108, pill_y, 92, translateRoomStatus(self.room.status), {
        fill = (self.room.status == "waiting") and colors.card_alt or colors.button_secondary_face,
        border = (self.room.status == "waiting") and colors.card_border or colors.button_secondary_border,
        text = (self.room.status == "waiting") and colors.text_secondary or colors.button_secondary_text,
        shadow = colors.card_shadow,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(meta_text, self.x + 22, meta_y, content_right - (self.x + 22), "left")

    drawIOSButton(fonts, style, {
        label = I18n:t("lobby.row_join"),
        x = join_bounds.x,
        y = join_bounds.y,
        width = join_bounds.width,
        height = join_bounds.height,
        hovered = self.join_hovered and self.join_enabled,
        enabled = self.join_enabled,
        variant = "primary",
        font_token = "Caption",
        radius = 12,
    })
end

return LobbyRoomSummaryRow
