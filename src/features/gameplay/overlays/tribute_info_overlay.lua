local I18n = require("src.core.i18n.i18n")
local WoodPanel = require("src.core.ui.wood_panel")
local IconCloseButton = require("src.core.ui.icon_close_button")
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local CardView = require("src.features.gameplay.components.card_view")

local utf8lib = rawget(_G, "utf8")
if not utf8lib then
    local ok, loaded = pcall(require, "utf8")
    if ok and type(loaded) == "table" then
        utf8lib = loaded
    end
end

local TributeInfoOverlay = {}
TributeInfoOverlay.__index = TributeInfoOverlay

local TEAM_ACCENTS = {
    [0] = { 0.62, 0.82, 0.68, 1 },
    [1] = { 0.96, 0.73, 0.40, 1 },
}

local ROUTE_ACCENTS = {
    [0] = { 0.23, 0.65, 0.30, 1 },
    [1] = { 0.94, 0.50, 0.12, 1 },
}

local ROUTE_OUTLINE = { 0.48, 0.27, 0.09, 0.34 }

local AVATAR_FALLBACKS = {
    "avatar_9",
    "avatar_15",
    "avatar_21",
    "avatar_27",
}

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function isContinuationByte(byte)
    return byte ~= nil and byte >= 0x80 and byte <= 0xBF
end

local function sanitizeUtf8(text)
    local value = tostring(text or "")
    if value == "" then
        return value
    end
    if utf8lib and utf8lib.len and pcall(utf8lib.len, value) then
        return value
    end

    local cleaned = {}
    local index = 1
    while index <= #value do
        local byte1 = string.byte(value, index)
        if not byte1 then
            break
        end
        if byte1 < 0x80 then
            cleaned[#cleaned + 1] = string.char(byte1)
            index = index + 1
        elseif byte1 >= 0xC2 and byte1 <= 0xDF then
            local byte2 = string.byte(value, index + 1)
            if isContinuationByte(byte2) then
                cleaned[#cleaned + 1] = value:sub(index, index + 1)
                index = index + 2
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        elseif byte1 >= 0xE0 and byte1 <= 0xEF then
            local byte2 = string.byte(value, index + 1)
            local byte3 = string.byte(value, index + 2)
            local valid = isContinuationByte(byte2) and isContinuationByte(byte3)
            if valid and byte1 == 0xE0 then
                valid = byte2 >= 0xA0
            elseif valid and byte1 == 0xED then
                valid = byte2 <= 0x9F
            end
            if valid then
                cleaned[#cleaned + 1] = value:sub(index, index + 2)
                index = index + 3
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        elseif byte1 >= 0xF0 and byte1 <= 0xF4 then
            local byte2 = string.byte(value, index + 1)
            local byte3 = string.byte(value, index + 2)
            local byte4 = string.byte(value, index + 3)
            local valid = isContinuationByte(byte2) and isContinuationByte(byte3) and isContinuationByte(byte4)
            if valid and byte1 == 0xF0 then
                valid = byte2 >= 0x90
            elseif valid and byte1 == 0xF4 then
                valid = byte2 <= 0x8F
            end
            if valid then
                cleaned[#cleaned + 1] = value:sub(index, index + 3)
                index = index + 4
            else
                cleaned[#cleaned + 1] = "?"
                index = index + 1
            end
        else
            cleaned[#cleaned + 1] = "?"
            index = index + 1
        end
    end
    return table.concat(cleaned)
end

local function utf8Length(text)
    local value = sanitizeUtf8(text)
    if value == "" then
        return 0
    end
    if utf8lib and utf8lib.len then
        local ok, length = pcall(utf8lib.len, value)
        if ok and type(length) == "number" then
            return length
        end
    end
    local _, count = string.gsub(value, "[^\128-\193]", "")
    return count
end

local function utf8Sub(text, start_char, end_char)
    local value = sanitizeUtf8(text)
    if value == "" then
        return value
    end
    start_char = math.max(tonumber(start_char) or 1, 1)
    end_char = end_char or -1
    local length = utf8Length(value)
    if end_char < 0 then
        end_char = length + end_char + 1
    end
    end_char = math.min(tonumber(end_char) or length, length)
    if start_char > end_char then
        return ""
    end
    if utf8lib and utf8lib.offset then
        local start_byte = utf8lib.offset(value, start_char)
        local end_byte = utf8lib.offset(value, end_char + 1)
        if not start_byte then
            return ""
        end
        if not end_byte then
            return value:sub(start_byte)
        end
        return value:sub(start_byte, end_byte - 1)
    end

    local start_byte = 1
    local current_char = 1
    while current_char < start_char and start_byte <= #value do
        local byte = string.byte(value, start_byte)
        if byte < 0x80 then
            start_byte = start_byte + 1
        elseif byte < 0xE0 then
            start_byte = start_byte + 2
        elseif byte < 0xF0 then
            start_byte = start_byte + 3
        else
            start_byte = start_byte + 4
        end
        current_char = current_char + 1
    end

    local end_byte = start_byte
    while current_char <= end_char and end_byte <= #value do
        local byte = string.byte(value, end_byte)
        if byte < 0x80 then
            end_byte = end_byte + 1
        elseif byte < 0xE0 then
            end_byte = end_byte + 2
        elseif byte < 0xF0 then
            end_byte = end_byte + 3
        else
            end_byte = end_byte + 4
        end
        current_char = current_char + 1
    end
    return value:sub(start_byte, end_byte - 1)
end

local function toRenderableText(font, text)
    local value = sanitizeUtf8(text)
    if value == "" then
        return value
    end

    local ok = pcall(font.getWidth, font, value)
    if ok then
        return value
    end

    local fallback = value:gsub("[\128-\255]", "?")
    ok = pcall(font.getWidth, font, fallback)
    if ok then
        return fallback
    end

    return "..."
end

local function safeFontWidth(font, text)
    local renderable = toRenderableText(font, text)
    local ok, width = pcall(font.getWidth, font, renderable)
    if ok and type(width) == "number" then
        return width, renderable
    end
    return 0, ""
end

local function textWidth(fonts, token, text)
    local width = safeFontWidth(fonts:get(token), text)
    return width
end

local function truncateText(fonts, token, text, max_width)
    local font = fonts:get(token)
    local value = toRenderableText(font, text)
    if value == "" then
        return value
    end
    if safeFontWidth(font, value) <= max_width then
        return value
    end
    local ellipsis = "..."
    local result = value
    local char_count = utf8Length(value)
    while char_count > 0 and safeFontWidth(font, result .. ellipsis) > max_width do
        char_count = char_count - 1
        result = utf8Sub(value, 1, char_count)
    end
    if result == "" then
        return ellipsis
    end
    return result .. ellipsis
end

local function getWildcardLabel(card_code)
    local suit, rank = tostring(card_code or ""):match("^([SHCD])%-(%w+)$")
    if suit and rank then
        local suit_label = I18n:t("gameplay.suit_" .. ({
            S = "spade",
            H = "heart",
            C = "club",
            D = "diamond",
        })[suit])
        return string.format("%s%s", suit_label, rank)
    end
    return tostring(card_code or I18n:t("common.none"))
end

local function getRelativePositionKey(my_seat_index, other_seat_index)
    local relative = (other_seat_index - my_seat_index + 4) % 4
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

local function getRelativePositionText(role_key)
    if role_key == "self" then
        return I18n:t("gameplay.self")
    end
    if role_key == "next" then
        return I18n:t("gameplay.next")
    end
    if role_key == "opposite" then
        return I18n:t("gameplay.opposite")
    end
    return I18n:t("gameplay.previous")
end

local function resolveAvatarId(player)
    local avatar_id = tostring((player or {}).avatar_id or "")
    if avatar_id ~= "" then
        return avatar_id
    end
    local seat_index = tonumber((player or {}).seat_index) or 0
    return AVATAR_FALLBACKS[(seat_index % #AVATAR_FALLBACKS) + 1]
end

local function parseTributeReceiverSeat(entry)
    local explicit = tonumber((entry or {}).receiver_seat)
    if explicit ~= nil then
        return explicit
    end
    local summary = tostring((entry or {}).summary or "")
    local giver_seat, receiver_seat = summary:match("^Seat(%d+)%b[] 向 Seat(%d+)%b[] 贡牌")
    if giver_seat and receiver_seat then
        return tonumber(receiver_seat)
    end
    local receiver_only = summary:match("向 Seat(%d+)%b[] 贡牌")
    return receiver_only and tonumber(receiver_only) or nil
end

local function normalizeSeatList(raw_seats)
    local seats = {}
    for _, seat in ipairs(raw_seats or {}) do
        local numeric = tonumber(seat)
        if numeric ~= nil then
            seats[#seats + 1] = numeric
        end
    end
    return seats
end

local function collectTributeRoutes(game, history)
    local routes = {}
    local anti_tribute = false
    local anti_tribute_big_joker_seats = normalizeSeatList((((game or {}).tribute) or {}).anti_tribute_big_joker_seats)
    for _, entry in ipairs(history or {}) do
        local action_type = tostring((entry or {}).action_type or "")
        if action_type == "anti_tribute" then
            anti_tribute = true
            if #anti_tribute_big_joker_seats == 0 then
                anti_tribute_big_joker_seats = normalizeSeatList((entry or {}).anti_tribute_big_joker_seats)
            end
        elseif action_type == "tribute" then
            routes[#routes + 1] = {
                giver_seat = tonumber(entry.seat_index),
                receiver_seat = parseTributeReceiverSeat(entry),
                card_id = ((entry.cards or {})[1]),
                summary = tostring(entry.summary or ""),
            }
        end
    end
    return routes, anti_tribute, anti_tribute_big_joker_seats
end

local function buildSeatJokerCounts(seats)
    local counts = {}
    for _, seat in ipairs(seats or {}) do
        local numeric = tonumber(seat)
        if numeric ~= nil then
            counts[numeric] = (counts[numeric] or 0) + 1
        end
    end
    return counts
end

local function resolveAccessories(player, my_seat_index, my_accessories)
    if player and player.accessories then
        return player.accessories
    end
    if tonumber((player or {}).seat_index) == tonumber(my_seat_index) then
        return my_accessories
    end
    return nil
end

function TributeInfoOverlay.new(options)
    local self = setmetatable({}, TributeInfoOverlay)
    self.fonts = assert(options and options.fonts, "TributeInfoOverlay requires fonts")
    self.style = assert(options and options.style, "TributeInfoOverlay requires style")
    self.panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.card_view = CardView.new()
    self.avatars_by_id = {}
    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end
    return self
end

function TributeInfoOverlay:getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_w = math.max(820, math.min(960, width - 84))
    local panel_h = math.max(520, math.min(620, height - 84))
    return {
        x = math.floor((width - panel_w) / 2),
        y = math.floor((height - panel_h) / 2),
        width = panel_w,
        height = panel_h,
    }
end

function TributeInfoOverlay:getCloseButtonFrame()
    local panel = self:getPanelFrame()
    return {
        x = panel.x + panel.width - 64,
        y = panel.y + 18,
        width = 36,
        height = 36,
    }
end

function TributeInfoOverlay:getControlAt(x, y)
    if contains(self:getCloseButtonFrame(), x, y) then
        return "close_tribute_info"
    end
    return nil
end

function TributeInfoOverlay:_drawSection(frame)
    local colors = self.style.colors
    love.graphics.setColor(colors.panel_shadow[1], colors.panel_shadow[2], colors.panel_shadow[3], 0.28)
    love.graphics.rectangle("fill", frame.x, frame.y + 4, frame.width, frame.height, 18, 18)
    love.graphics.setColor(colors.panel_inner)
    love.graphics.rectangle("fill", frame.x + 2, frame.y + 2, frame.width - 4, frame.height - 4, 16, 16)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(colors.panel_border)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, 17, 17)
    love.graphics.setLineWidth(1)
end

function TributeInfoOverlay:_drawPill(x, y, text, options)
    local colors = self.style.colors
    options = options or {}
    local font_token = options.font_token or "Caption"
    local font = self.fonts:get(font_token)
    local safe_text = toRenderableText(font, text)
    local width = options.width or (safeFontWidth(font, safe_text) + 24)
    local height = options.height or 26
    local fill = options.fill or colors.hud_badge_fill
    local border = options.border or colors.hud_badge_border
    local text_color = options.text_color or colors.hud_badge_text

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4] or 1)
    love.graphics.rectangle("fill", x, y, width, height, 13, 13)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(border[1], border[2], border[3], border[4] or 1)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 13, 13)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4] or 1)
    love.graphics.setFont(font)
    love.graphics.printf(safe_text, x, y + math.floor((height - self.fonts:getSize(font_token)) * 0.5) - 1, width, "center")
end

function TributeInfoOverlay:_buildPlayers(game)
    local by_role = {}
    local my_seat_index = tonumber((game or {}).my_seat_index) or 0
    for _, player in ipairs((game or {}).players or {}) do
        local seat_index = tonumber(player.seat_index) or 0
        local role_key = getRelativePositionKey(my_seat_index, seat_index)
        by_role[role_key] = player
    end
    return by_role
end

function TributeInfoOverlay:_getSeatNodes(board, game)
    local players = self:_buildPlayers(game)
    local node_size = clamp(math.floor(math.min(board.width, board.height) * 0.17), 70, 82)
    local horizontal_inset = math.max(34, math.floor(board.width * 0.085))
    local vertical_inset = math.max(26, math.floor(board.height * 0.075))
    local nodes = {
        opposite = {
            player = players.opposite,
            x = board.x + math.floor((board.width - node_size) * 0.5),
            y = board.y + vertical_inset + 6,
            size = node_size,
        },
        previous = {
            player = players.previous,
            x = board.x + horizontal_inset + 10,
            y = board.y + math.floor((board.height - node_size) * 0.5),
            size = node_size,
        },
        next = {
            player = players.next,
            x = board.x + board.width - node_size - horizontal_inset - 10,
            y = board.y + math.floor((board.height - node_size) * 0.5),
            size = node_size,
        },
        self = {
            player = players.self,
            x = board.x + math.floor((board.width - node_size) * 0.5),
            y = board.y + board.height - node_size - math.max(34, vertical_inset + 16),
            size = node_size,
        },
    }
    for _, node in pairs(nodes) do
        node.cx = node.x + math.floor(node.size * 0.5)
        node.cy = node.y + math.floor(node.size * 0.5)
    end
    return nodes
end

function TributeInfoOverlay:_getRoleBySeat(game, seat_index)
    local my_seat_index = tonumber((game or {}).my_seat_index) or 0
    return getRelativePositionKey(my_seat_index, tonumber(seat_index) or 0)
end

function TributeInfoOverlay:_drawSeatNode(node, role_key, options)
    if not node or not node.player then
        return
    end
    options = options or {}
    local colors = self.style.colors
    local player = node.player
    local accent = TEAM_ACCENTS[tonumber(player.team_id) or 0] or colors.accent
    local avatar = self.avatars_by_id[resolveAvatarId(player)]
    local avatar_bounds = {
        x = node.x,
        y = node.y,
        w = node.size,
        h = node.size,
    }

    love.graphics.setColor(accent[1], accent[2], accent[3], 0.24)
    love.graphics.rectangle("fill", avatar_bounds.x - 4, avatar_bounds.y - 4, avatar_bounds.w + 8, avatar_bounds.h + 8, 16, 16)

    if avatar then
        AvatarTile.draw(self.style, avatar, avatar_bounds, {
            compact = true,
            content_padding_ratio = 0.05,
            selected = true,
            pin_frame = true,
            accessories = resolveAccessories(player, options.my_seat_index, options.my_accessories),
        })
    end

    local name_y = avatar_bounds.y + avatar_bounds.h + 8
    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(getRelativePositionText(role_key), avatar_bounds.x - 8, name_y, avatar_bounds.w + 16, "center")

    love.graphics.setColor(colors.hud_text)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(
        truncateText(self.fonts, "TextSmall", tostring(player.nickname or "-"), avatar_bounds.w + 28),
        avatar_bounds.x - 14,
        name_y + 16,
        avatar_bounds.w + 28,
        "center"
    )

    self:_drawPill(avatar_bounds.x + 8, avatar_bounds.y - 16, string.format("S%d", (tonumber(player.seat_index) or 0) + 1), {
        width = avatar_bounds.w - 16,
        height = 20,
        fill = accent,
        border = self.style.colors.panel_border,
        text_color = self.style.colors.hud_text,
    })

    self:_drawSeatJokers(node, role_key, tonumber((options or {}).joker_count) or 0, (options or {}).theme_config or {})
end

function TributeInfoOverlay:_drawSeatJokers(node, role_key, joker_count, theme_config)
    if not node or joker_count <= 0 then
        return
    end

    -- Keep anti-tribute jokers visually close to the wildcard reference card,
    -- but slightly smaller so the seat layout still fits comfortably.
    local card_w = clamp(math.floor(node.size * 0.98), 80, 88)
    local card_h = math.floor(card_w * 1.4)
    local overlap = math.max(18, math.floor(card_w * 0.24))
    local avatar_overlap = math.max(12, math.floor(card_w * 0.18))
    local anchor_left = role_key == "next"
    local base_x = anchor_left
        and (node.x - card_w + avatar_overlap)
        or (node.x + node.size - avatar_overlap)
    local base_y = node.y + math.floor((node.size - card_h) * 0.5)

    for index = 1, joker_count do
        local offset = (index - 1) * overlap
        local card_x = anchor_left and (base_x - offset) or (base_x + offset)
        local card_y = base_y + (index - 1) * 6
        love.graphics.setColor(0, 0, 0, 0.18)
        love.graphics.rectangle("fill", card_x + 3, card_y + 4, card_w, card_h, 9, 9)
        self.card_view:draw(
            index == 1 and "RJ-1" or "RJ-2",
            {
                x = card_x,
                y = card_y,
                width = card_w,
                height = card_h,
            },
            theme_config or {},
            { selected = true },
            self.fonts
        )
    end
end

function TributeInfoOverlay:_drawArrowLine(start_x, start_y, end_x, end_y, color)
    love.graphics.setColor(ROUTE_OUTLINE[1], ROUTE_OUTLINE[2], ROUTE_OUTLINE[3], ROUTE_OUTLINE[4])
    love.graphics.setLineWidth(10)
    love.graphics.line(start_x, start_y, end_x, end_y)

    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.setLineWidth(6)
    love.graphics.line(start_x, start_y, end_x, end_y)
    love.graphics.setLineWidth(1)

    local dx = end_x - start_x
    local dy = end_y - start_y
    local angle = 0
    if math.abs(dx) < 0.0001 then
        angle = dy >= 0 and (math.pi * 0.5) or (-math.pi * 0.5)
    else
        angle = math.atan(dy / dx)
        if dx < 0 then
            angle = angle + math.pi
        end
    end
    local outline_head = 26
    local head = 20
    local head_spread = 0.62
    love.graphics.setColor(ROUTE_OUTLINE[1], ROUTE_OUTLINE[2], ROUTE_OUTLINE[3], ROUTE_OUTLINE[4])
    love.graphics.polygon(
        "fill",
        end_x,
        end_y,
        end_x - math.cos(angle - head_spread) * outline_head,
        end_y - math.sin(angle - head_spread) * outline_head,
        end_x - math.cos(angle + head_spread) * outline_head,
        end_y - math.sin(angle + head_spread) * outline_head
    )

    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.polygon(
        "fill",
        end_x,
        end_y,
        end_x - math.cos(angle - head_spread) * head,
        end_y - math.sin(angle - head_spread) * head,
        end_x - math.cos(angle + head_spread) * head,
        end_y - math.sin(angle + head_spread) * head
    )
end

function TributeInfoOverlay:_drawRoute(board, game, nodes, route, index, count, theme_config)
    if not route or route.giver_seat == nil or route.receiver_seat == nil then
        return
    end
    local giver_role = self:_getRoleBySeat(game, route.giver_seat)
    local receiver_role = self:_getRoleBySeat(game, route.receiver_seat)
    local giver = nodes[giver_role]
    local receiver = nodes[receiver_role]
    if not giver or not giver.player or not receiver or not receiver.player then
        return
    end

    local color = ROUTE_ACCENTS[tonumber((giver.player or {}).team_id) or 0] or self.style.colors.accent
    local dx = receiver.cx - giver.cx
    local dy = receiver.cy - giver.cy
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= 0.001 then
        return
    end
    local nx = dx / distance
    local ny = dy / distance
    local px = -ny
    local py = nx
    local lane_offset = ((index - 1) - (count - 1) * 0.5) * 18
    local trim = 54
    local start_x = giver.cx + nx * trim + px * lane_offset
    local start_y = giver.cy + ny * trim + py * lane_offset
    local end_x = receiver.cx - nx * trim + px * lane_offset
    local end_y = receiver.cy - ny * trim + py * lane_offset

    self:_drawArrowLine(start_x, start_y, end_x, end_y, color)

    local card_w = 104
    local card_h = 144
    local mid_x = math.floor((start_x + end_x) * 0.5 + px * 10 - card_w * 0.5)
    local mid_y = math.floor((start_y + end_y) * 0.5 + py * 10 - card_h * 0.5)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", mid_x - 4, mid_y + 4, card_w + 8, card_h + 8, 10, 10)
    self.card_view:draw(route.card_id or "S-3-1", {
        x = mid_x,
        y = mid_y,
        width = card_w,
        height = card_h,
    }, theme_config or {}, {}, self.fonts)
end

local function drawAntiBanner(self, frame, text, colors, options)
    options = options or {}
    local font_token = options.font_token or "Text"
    local font = self.fonts:get(font_token)
    local safe_text = toRenderableText(font, text)
    local text_width = safeFontWidth(font, safe_text)
    local width = options.width or math.min(math.max(text_width + 72, 300), frame.width - 40)
    local height = options.height or 40
    local x = options.x or math.floor(frame.x + (frame.width - width) * 0.5)
    local y = options.y or math.floor(frame.y + (frame.height - height) * 0.5)
    local fill = options.fill or colors.card_alt or { 0.96, 0.91, 0.78, 1 }
    local border = options.border or colors.panel_border or { 0.56, 0.33, 0.14, 1 }
    local text_color = options.text_color or colors.hud_title or { 0.38, 0.20, 0.07, 1 }
    local shadow = options.shadow or { 0, 0, 0, 0.16 }
    local accent = options.accent or colors.accent or { 0.72, 0.46, 0.17, 1 }

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow[4] or 0.16)
    love.graphics.rectangle("fill", x + 4, y + 5, width, height, 18, 18)

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4] or 1)
    love.graphics.rectangle("fill", x, y, width, height, 18, 18)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(border[1], border[2], border[3], border[4] or 1)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 18, 18)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(accent[1], accent[2], accent[3], 0.16)
    love.graphics.rectangle("fill", x + 5, y + 4, width - 10, math.max(6, math.floor(height * 0.18)), 12, 12)

    love.graphics.setColor(text_color[1], text_color[2], text_color[3], text_color[4] or 1)
    love.graphics.setFont(font)
    love.graphics.printf(
        safe_text,
        x,
        y + math.floor((height - self.fonts:getSize(font_token)) * 0.5) - 1,
        width,
        "center"
    )
end

function TributeInfoOverlay:_drawAntiTributeBoard(board, game, nodes, anti_tribute_big_joker_seats, theme_config, options)
    local colors = self.style.colors
    local joker_counts = buildSeatJokerCounts(anti_tribute_big_joker_seats)

    for _, role_key in ipairs({ "opposite", "previous", "next", "self" }) do
        local node = nodes[role_key]
        local seat_index = tonumber((((node or {}).player) or {}).seat_index)
        self:_drawSeatNode(node, role_key, {
            my_seat_index = options.my_seat_index,
            my_accessories = options.my_accessories,
            theme_config = theme_config,
            joker_count = seat_index ~= nil and (joker_counts[seat_index] or 0) or 0,
        })
    end

    drawAntiBanner(self, board, I18n:t("gameplay.tribute_info_anti_banner"), colors, {
        font_token = "Text",
        width = math.min(math.max(320, safeFontWidth(self.fonts:get("Text"), I18n:t("gameplay.tribute_info_anti_banner")) + 72), board.width - 40),
        height = 40,
        y = board.y + math.floor((board.height - 40) * 0.5),
    })
end

function TributeInfoOverlay:_drawWildcardPanel(frame, game, theme_config)
    local colors = self.style.colors
    local wildcard_card = (game or {}).wildcard_card

    self:_drawSection(frame)

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("gameplay.tribute_info_wildcard_panel_title"), frame.x + 16, frame.y + 14)

    if not wildcard_card then
        self:_drawPill(
            frame.x + 16,
            frame.y + math.floor((frame.height - 28) * 0.5),
            I18n:t("common.none"),
            {
                width = frame.width - 32,
                height = 28,
                fill = colors.card_alt,
                border = colors.panel_border,
                text_color = colors.text_primary,
            }
        )
        return
    end

    local card_w = clamp(math.floor(frame.width * 0.62), 90, 118)
    local card_h = math.floor(card_w * 1.4)
    local card_x = frame.x + math.floor((frame.width - card_w) * 0.5)
    local card_y = frame.y + math.max(44, math.floor((frame.height - card_h) * 0.34))

    love.graphics.setColor(0, 0, 0, 0.16)
    love.graphics.rectangle("fill", card_x - 6, card_y + 6, card_w + 12, card_h + 12, 14, 14)
    self.card_view:draw(wildcard_card, {
        x = card_x,
        y = card_y,
        width = card_w,
        height = card_h,
    }, theme_config or {}, {}, self.fonts)
end

function TributeInfoOverlay:_drawBoard(board, game, theme_config, options)
    local colors = self.style.colors
    local routes, anti_tribute, anti_tribute_big_joker_seats = collectTributeRoutes(game, (game or {}).history or {})
    local nodes = self:_getSeatNodes(board, game)

    self:_drawSection(board)

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print(I18n:t("gameplay.tribute_info_route_title"), board.x + 18, board.y + 14)

    love.graphics.setColor(colors.panel_grain[1], colors.panel_grain[2], colors.panel_grain[3], 0.18)
    love.graphics.rectangle("fill", board.x + 20, board.y + math.floor(board.height * 0.5), board.width - 40, 2)
    love.graphics.rectangle("fill", board.x + math.floor(board.width * 0.5), board.y + 26, 2, board.height - 52)

    if anti_tribute and #anti_tribute_big_joker_seats > 0 then
        self:_drawAntiTributeBoard(board, game, nodes, anti_tribute_big_joker_seats, theme_config, options)
    else
        for _, role_key in ipairs({ "opposite", "previous", "next", "self" }) do
            self:_drawSeatNode(nodes[role_key], role_key, options)
        end
    end

    if anti_tribute and #anti_tribute_big_joker_seats > 0 then
        return
    end

    if #routes > 0 then
        for index, route in ipairs(routes) do
            self:_drawRoute(board, game, nodes, route, index, #routes, theme_config)
        end
    else
        local message = anti_tribute and I18n:t("gameplay.tribute_info_anti_banner") or I18n:t("gameplay.tribute_info_none")
        drawAntiBanner(self, board, message, colors, {
            font_token = "Text",
            width = math.min(math.max(320, safeFontWidth(self.fonts:get("Text"), message) + 72), board.width - 40),
            height = 40,
        })
    end
end

function TributeInfoOverlay:drawEmbedded(frame, game, options)
    options = options or {}
    local content_gap = 14
    local wildcard = {
        x = frame.x,
        y = frame.y,
        width = math.max(138, math.floor((frame.width - content_gap) * 0.2)),
        height = frame.height,
    }
    local board = {
        x = wildcard.x + wildcard.width + content_gap,
        y = frame.y,
        width = frame.width - wildcard.width - content_gap,
        height = frame.height,
    }

    self:_drawWildcardPanel(wildcard, game, options.card_theme_config or {})
    self:_drawBoard(board, game, options.card_theme_config or {}, options)
end

function TributeInfoOverlay:draw(game, options)
    options = options or {}
    local colors = self.style.colors
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel = self:getPanelFrame()
    local close = self:getCloseButtonFrame()

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, width, height)

    self.panel:draw(panel, {
        radius = 22,
        shadow_offset = 8,
        inner_inset = 12,
    })

    love.graphics.setColor(colors.hud_title)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("gameplay.tribute_info_title"), panel.x, panel.y + 28, panel.width, "center")

    self.close_button:draw(close, false)
    self:drawEmbedded({
        x = panel.x + 26,
        y = panel.y + 78,
        width = panel.width - 52,
        height = panel.height - 104,
    }, game, options)
end

return TributeInfoOverlay
