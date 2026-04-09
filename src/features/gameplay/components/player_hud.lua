local PlayerHUD = {}
PlayerHUD.__index = PlayerHUD
local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local GamePlayTimerStyle = require("src.features.gameplay.components.gameplay_timer_style")
local I18n = require("src.core.i18n.i18n")

local TIMER_SEGMENTS = GamePlayTimerStyle.segmentMap
local TIMER_STYLE = GamePlayTimerStyle.getDefaultStyle()

function PlayerHUD.new(options)
    local self = setmetatable({}, PlayerHUD)

    self.fonts = assert(options and options.fonts, "PlayerHUD requires fonts")
    self.style = assert(options and options.style, "PlayerHUD requires style")
    self.avatars_by_id = {}
    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end

    return self
end

local function drawTimerSegment(x, y, w, h, active, color_on, color_off)
    local color = active and color_on or color_off
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle("fill", x, y, w, h, 1, 1)
end

local function drawTimerDigit(x, y, scale, digit, color_on, color_off)
    local seg = TIMER_SEGMENTS[tonumber(digit) or 0] or TIMER_SEGMENTS[0]
    local t = math.max(2, math.floor(TIMER_STYLE.seg_t * scale))
    local wh = math.max(4, math.floor(TIMER_STYLE.seg_w_h * scale))
    local wv = math.max(6, math.floor(TIMER_STYLE.seg_w_v * scale))

    drawTimerSegment(x + t, y, wh, t, seg[1], color_on, color_off)
    drawTimerSegment(x + t + wh, y + t, t, wv, seg[2], color_on, color_off)
    drawTimerSegment(x + t + wh, y + t * 2 + wv, t, wv, seg[3], color_on, color_off)
    drawTimerSegment(x + t, y + t * 2 + wv * 2, wh, t, seg[4], color_on, color_off)
    drawTimerSegment(x, y + t * 2 + wv, t, wv, seg[5], color_on, color_off)
    drawTimerSegment(x, y + t, t, wv, seg[6], color_on, color_off)
    drawTimerSegment(x + t, y + t + wv, wh, t, seg[7], color_on, color_off)
    return t * 2 + wh, t * 3 + wv * 2
end

local function getTimerDigitSize(scale)
    local t = math.max(2, math.floor(TIMER_STYLE.seg_t * scale))
    local wh = math.max(4, math.floor(TIMER_STYLE.seg_w_h * scale))
    local wv = math.max(6, math.floor(TIMER_STYLE.seg_w_v * scale))
    return t * 2 + wh, t * 3 + wv * 2
end

local function drawTimerFlip(bounds, colors, hovered, remaining, is_warning)
    local radius = 10
    local shadow = colors.avatar_shadow or { 0.31, 0.17, 0.08, 0.72 }
    local border = hovered and (colors.avatar_hover or colors.avatar_border) or (colors.avatar_border or { 0.49, 0.27, 0.13, 0.9 })
    local shell = is_warning and { 0.23, 0.31, 0.22, 1 } or { 0.26, 0.33, 0.30, 1 }
    local shell_light = is_warning and { 0.80, 0.92, 0.74, 1 } or { 0.72, 0.84, 0.76, 1 }
    local inner = is_warning and { 0.10, 0.14, 0.10, 1 } or { 0.11, 0.14, 0.12, 1 }
    local screen = is_warning and TIMER_STYLE.bgLitGreen or TIMER_STYLE.bgUnlit
    local screen_glow = {
        TIMER_STYLE.lightSourceGreen[1],
        TIMER_STYLE.lightSourceGreen[2],
        TIMER_STYLE.lightSourceGreen[3],
        is_warning and 0.30 or 0.00,
    }
    local digit_on = TIMER_STYLE.segmentOn
    local digit_off = TIMER_STYLE.segmentOff

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow[4] or 1)
    love.graphics.rectangle("fill", bounds.x, bounds.y + 2, bounds.w, bounds.h, radius, radius)

    love.graphics.setColor(shell[1], shell[2], shell[3], shell[4] or 1)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h, radius, radius)

    love.graphics.setColor(shell_light[1], shell_light[2], shell_light[3], 0.95)
    love.graphics.rectangle("fill", bounds.x + 3, bounds.y + 3, bounds.w - 6, 6, radius - 2, radius - 2)

    love.graphics.setColor(inner[1], inner[2], inner[3], inner[4] or 1)
    love.graphics.rectangle("fill", bounds.x + 4, bounds.y + 4, bounds.w - 8, bounds.h - 8, radius - 3, radius - 3)

    local screen_bounds = {
        x = bounds.x + 8,
        y = bounds.y + 10,
        w = bounds.w - 16,
        h = bounds.h - 20,
    }
    love.graphics.setColor(screen[1], screen[2], screen[3], screen[4] or 1)
    love.graphics.rectangle("fill", screen_bounds.x, screen_bounds.y, screen_bounds.w, screen_bounds.h, 8, 8)

    love.graphics.setColor(screen_glow[1], screen_glow[2], screen_glow[3], screen_glow[4] or 1)
    love.graphics.rectangle("fill", screen_bounds.x + 3, screen_bounds.y + 3, screen_bounds.w - 6, math.max(6, math.floor(screen_bounds.h * 0.22)), 6, 6)

    love.graphics.setColor((border[1] or 1), (border[2] or 1), (border[3] or 1), border[4] or 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", bounds.x + 0.5, bounds.y + 0.5, bounds.w - 1, bounds.h - 1, radius, radius)
    love.graphics.setLineWidth(1)

    local num = string.format("%02d", math.max(0, math.ceil(tonumber(remaining) or 0)))
    local scale = math.min(screen_bounds.w / 34, screen_bounds.h / 33)
    local digit_w, digit_h = getTimerDigitSize(scale)
    local gap = math.max(3, math.floor(TIMER_STYLE.digit_gap * scale))
    local total_w = digit_w * 2 + gap
    local start_x = math.floor(screen_bounds.x + (screen_bounds.w - total_w) * 0.5)
    local start_y = math.floor(screen_bounds.y + (screen_bounds.h - digit_h) * 0.5)
    drawTimerDigit(start_x, start_y, scale, num:sub(1, 1), digit_on, digit_off)
    drawTimerDigit(start_x + digit_w + gap, start_y, scale, num:sub(2, 2), digit_on, digit_off)
end

local function getAvatarId(player, my_steam_id, my_avatar_id)
    local explicit_avatar = tostring(player.avatar_id or "")
    if explicit_avatar ~= "" then
        return explicit_avatar
    end

    if tonumber(player.player_id) == tonumber(my_steam_id) and tostring(my_avatar_id or "") ~= "" then
        return tostring(my_avatar_id)
    end

    local seat_index = tonumber(player.seat_index) or 0
    local seed = player.is_bot and (seat_index + 13) or (seat_index + 1)
    local avatar_index = (seed % 32) + 1
    return ("avatar_%d"):format(avatar_index)
end

local function getAvatarAccessories(player, my_steam_id, my_accessories)
    if type((player or {}).accessories) == "table" then
        return player.accessories
    end
    if tonumber((player or {}).player_id) == tonumber(my_steam_id) and type(my_accessories) == "table" then
        return my_accessories
    end
    return nil
end

local function drawAutoPlayingBadge(self, bounds)
    local colors = self.style.colors or {}
    local font = self.fonts:get("Label")
    local label = I18n:t("gameplay.auto_playing_badge")
    local badge_padding_x = 10
    local badge_w = math.max(56, math.ceil(font:getWidth(label)) + badge_padding_x * 2)
    local badge_h = math.max(20, math.floor(bounds.h * 0.2))
    local badge_x = bounds.x + bounds.w - badge_w - 2
    if badge_x < bounds.x - 8 then
        badge_x = bounds.x - 8
    end
    local badge_y = bounds.y + bounds.h - badge_h - 2
    local radius = math.floor(badge_h * 0.5)

    local shadow = colors.hud_badge_shadow or { 0.28, 0.14, 0.07, 0.68 }
    local frame = colors.error or { 0.92, 0.48, 0.45, 1 }
    local fill = { 0.97, 0.82, 0.32, 0.98 }
    local border = colors.hud_badge_border or { 0.44, 0.22, 0.1, 1 }
    local text = { 0.42, 0.16, 0.08, 1 }

    love.graphics.setColor(shadow[1], shadow[2], shadow[3], shadow[4] or 1)
    love.graphics.rectangle("fill", badge_x, badge_y + 2, badge_w, badge_h, radius, radius)

    love.graphics.setColor(frame[1], frame[2], frame[3], frame[4] or 1)
    love.graphics.rectangle("fill", badge_x, badge_y, badge_w, badge_h, radius, radius)

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4] or 1)
    love.graphics.rectangle("fill", badge_x + 2, badge_y + 2, badge_w - 4, badge_h - 4, radius - 1, radius - 1)

    love.graphics.setColor(border[1], border[2], border[3], border[4] or 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", badge_x + 0.5, badge_y + 0.5, badge_w - 1, badge_h - 1, radius, radius)

    love.graphics.setFont(font)
    love.graphics.setColor(text[1], text[2], text[3], text[4] or 1)
    love.graphics.printf(
        label,
        badge_x,
        badge_y + math.floor((badge_h - font:getHeight()) * 0.5),
        badge_w,
        "center"
    )
end

function PlayerHUD:draw(player, role_label, frame, options)
    options = options or {}
    local frame_size = math.min(frame.width, frame.height)
    local avatar_size = math.max(48, math.floor(frame_size * 0.985))
    local avatar_bounds = {
        x = frame.x + math.floor((frame.width - avatar_size) * 0.5),
        y = frame.y + math.floor((frame.height - avatar_size) * 0.5),
        w = avatar_size,
        h = avatar_size,
    }
    local timer_active = options.show_timer == true
    local timer_remaining = tonumber(options.timer_remaining or 0) or 0
    local timer_warning = tonumber(options.timer_warning or 5) or 5
    if timer_active then
        drawTimerFlip(avatar_bounds, self.style.colors or {}, options.hovered == true, timer_remaining, timer_remaining <= timer_warning)
        return
    end
    local avatar_id = getAvatarId(player, options.my_steam_id, options.my_avatar_id)
    local accessories = getAvatarAccessories(player, options.my_steam_id, options.my_accessories)
    local avatar = self.avatars_by_id[avatar_id]
    if avatar then
        AvatarTile.draw(self.style, avatar, avatar_bounds, {
            hovered = options.hovered == true,
            selected = options.hovered == true,
            compact = true,
            content_padding_ratio = 0.015,
            pin_frame = true,
            accessories = accessories,
        })
    end
    if options.show_auto_playing == true then
        drawAutoPlayingBadge(self, avatar_bounds)
    end
end

return PlayerHUD
