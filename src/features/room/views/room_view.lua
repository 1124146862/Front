local RoomPageActionButton = require("src.features.room.components.room_page_action_button")
local RoomPageTextInput = require("src.features.room.components.room_page_text_input")
local RoomPlayerStatusCard = require("src.features.room.components.room_player_status_card")
local JoinRoomOverlay = require("src.features.lobby.overlays.join_room_overlay")
local WoodPanel = require("src.core.ui.wood_panel")
local PastelPatternBackground = require("src.core.ui.pastel_pattern_background")
local I18n = require("src.core.i18n.i18n")

local RoomView = {}
RoomView.__index = RoomView

local function sameSteamID(left, right)
    return tostring(left or "") == tostring(right or "")
end

local function roomText(key, fallback, params)
    local value = I18n:t(key, params)
    if value == key then
        return fallback
    end
    return value
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

local function translateRealtimeStatus(status)
    if status == "connected" then
        return I18n:t("common.connected")
    end
    if status == "connecting" then
        return I18n:t("common.connecting")
    end
    if status == "disconnected" then
        return I18n:t("common.disconnected")
    end
    if status == "error" then
        return I18n:t("common.error")
    end
    return I18n:t("common.unknown")
end

local function getPasswordDisplayValue(room, is_owner, state)
    if is_owner then
        return state.config_password_input
    end

    if room.has_password then
        return I18n:t("room.password_set")
    end

    return I18n:t("room.password_none")
end

function RoomView.new(options)
    local self = setmetatable({}, RoomView)

    self.fonts = assert(options and options.fonts, "RoomView requires fonts")
    self.style = assert(options and options.style, "RoomView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.wood_panel = WoodPanel.new(self.style)
    self.password_overlay = JoinRoomOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })

    return self
end

function RoomView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.password_overlay:resize()
end

local function resolveLayout(view)
    local base = view.style.layout
    local base_gap = base.right_x - (base.left_x + base.top_width)
    local base_total_width = base.top_width + base.right_width + base_gap
    local base_total_height = base.top_y + base.top_height + 60

    local max_width = view.window_width - 48
    local scale = math.min(1, max_width / base_total_width, view.window_height / base_total_height)
    scale = math.max(0.72, scale)

    local pad = math.max(12, math.floor(24 * scale))
    local gap_x = math.max(12, math.floor(base_gap * scale))
    local top_width = math.floor(base.top_width * scale)
    local right_width = math.floor(base.right_width * scale)
    local total_width = top_width + right_width + gap_x
    local left_x = math.floor((view.window_width - total_width) * 0.5)
    if left_x < pad then
        left_x = pad
    end
    if left_x + total_width > view.window_width - pad then
        left_x = math.max(pad, view.window_width - pad - total_width)
    end

    local top_height = math.floor(base.top_height * scale)
    local right_height = math.floor(base.right_height * scale)
    local panel_block_height = math.max(top_height, right_height)
    local top_y = math.floor((view.window_height - panel_block_height) * 0.5) - math.floor(14 * scale)
    local max_top = math.max(0, view.window_height - panel_block_height - pad)
    if top_y > max_top then top_y = max_top end
    if top_y < pad then top_y = pad end

    local hero_pad = math.floor(28 * scale)
    local hero_height = math.floor(72 * scale)
    local stat_height = 0
    local stat_gap = 0
    local board_gap = math.max(12, math.floor(20 * scale))
    local button_height = math.max(44, math.floor(base.button_height * scale))
    local bottom_board_height = math.max(math.floor(86 * scale), button_height + math.floor(28 * scale))
    local bottom_board_y = top_y + top_height - board_gap - bottom_board_height
    local players_board_y = top_y + hero_pad + hero_height + board_gap
    local available_height = bottom_board_y - board_gap - players_board_y
    local players_board_height = math.max(80, math.floor(available_height))

    local input_height = math.max(40, math.floor(base.input_height * scale))
    local player_card_height = math.max(48, math.floor(base.player_card_height * scale))
    local player_gap = math.max(6, math.floor(base.player_gap * scale))

    local right_x = left_x + top_width + gap_x
    local right_buttons_y = top_y + right_height - board_gap - button_height - math.max(10, math.floor(12 * scale))
    local left_buttons_y = bottom_board_y + math.floor((bottom_board_height - button_height) * 0.5) - math.max(6, math.floor(8 * scale))

    return {
        scale = scale,
        left_x = left_x,
        right_x = right_x,
        top_y = top_y,
        top_width = top_width,
        top_height = top_height,
        right_width = right_width,
        right_height = right_height,
        hero_pad = hero_pad,
        hero_height = hero_height,
        stat_height = stat_height,
        stat_gap = stat_gap,
        board_gap = board_gap,
        bottom_board_y = bottom_board_y,
        bottom_board_height = bottom_board_height,
        players_board_y = players_board_y,
        players_board_height = players_board_height,
        button_height = button_height,
        input_height = input_height,
        player_card_height = player_card_height,
        player_gap = player_gap,
        left_buttons_y = left_buttons_y,
        right_buttons_y = right_buttons_y,
        message_y = bottom_board_y - math.max(24, math.floor(28 * scale)),
    }
end

function RoomView:getButtons(state)
    local layout = resolveLayout(self)
    local room = state.room or {}
    local is_owner = sameSteamID(room.owner_steam_id, state.steam_id)
    local me_ready = false
    local scale = layout.scale
    local gap = math.floor(20 * scale)
    local mid_w = math.floor(160 * scale)
    local right_pad = math.floor(20 * scale)
    local left_area_x = layout.left_x + layout.hero_pad
    local left_area_width = layout.top_width - layout.hero_pad * 2
    local left_total_width = mid_w + gap + mid_w
    local left_start_x = left_area_x + math.floor((left_area_width - left_total_width) * 0.5)
    local right_start_x = layout.right_x + right_pad
    local right_button_width = layout.right_width - right_pad * 2

    if room.players then
        for _, player in ipairs(room.players) do
            if sameSteamID(player.steam_id, state.steam_id) then
                me_ready = player.is_ready == true
                break
            end
        end
    end

    return {
        RoomPageActionButton.new({
            id = "toggle_ready",
            label = me_ready and I18n:t("room.cancel_ready") or I18n:t("room.ready"),
            x = left_start_x,
            y = layout.left_buttons_y,
            width = mid_w,
            height = layout.button_height,
            hovered = state.hovered_control == "toggle_ready",
            enabled = state.realtime_status == "connected" and not state.loading and not state.saving and not state.leaving,
            variant = "primary",
        }),
        RoomPageActionButton.new({
            id = "leave_room",
            label = I18n:t("room.leave"),
            x = left_start_x + mid_w + gap,
            y = layout.left_buttons_y,
            width = mid_w,
            height = layout.button_height,
            hovered = state.hovered_control == "leave_room",
            enabled = not state.loading and not state.saving and not state.leaving,
            variant = "secondary",
        }),
        RoomPageActionButton.new({
            id = "add_bot",
            label = I18n:t("room.add_bot"),
            x = right_start_x,
            y = layout.right_buttons_y,
            width = right_button_width,
            height = layout.button_height,
            hovered = state.hovered_control == "add_bot",
            enabled = is_owner
                and (room.status or "waiting") ~= "in_game"
                and (room.player_count or 0) < (room.max_player_count or 4)
                and state.realtime_status == "connected"
                and not state.loading
                and not state.saving
                and not state.leaving,
            variant = "secondary",
        }),
    }
end

function RoomView:getInputs(state)
    local layout = resolveLayout(self)
    local room = state.room or {}
    local is_owner = sameSteamID(room.owner_steam_id, state.steam_id)
    local input_x = layout.right_x + math.floor(20 * layout.scale)
    local input_width = layout.right_width - math.floor(40 * layout.scale)
    local input_y = layout.top_y + math.floor(132 * layout.scale)
    local input_gap = math.max(16, math.floor(26 * layout.scale))

    return {
        RoomPageTextInput.new({
            id = "config_password",
            label = is_owner and I18n:t("room.input_password_owner") or I18n:t("room.input_password_guest"),
            value = getPasswordDisplayValue(room, is_owner, state),
            placeholder = is_owner and I18n:t("room.input_password_placeholder_owner") or I18n:t("room.input_password_placeholder_guest"),
            x = input_x,
            y = input_y + layout.input_height + input_gap + math.floor(52 * layout.scale),
            width = input_width,
            height = layout.input_height,
            focused = state.focused_field == "config_password",
            editable = is_owner,
            label_font_token = "TextBig",
            label_offset = math.floor(30 * layout.scale),
        }),
    }
end

function RoomView:getModeButtons(state)
    local layout = resolveLayout(self)
    local room = state.room or {}
    local is_owner = sameSteamID(room.owner_steam_id, state.steam_id)
    local input_x = layout.right_x + math.floor(20 * layout.scale)
    local input_width = layout.right_width - math.floor(40 * layout.scale)
    local input_y = layout.top_y + math.floor(132 * layout.scale)
    local button_gap = math.max(10, math.floor(14 * layout.scale))
    local button_height = math.max(38, math.floor(42 * layout.scale))
    local button_width = math.floor((input_width - button_gap) * 0.5)
    local current_mode = tostring(state.config_mode_input or room.game_mode or "classic")

    return {
        RoomPageActionButton.new({
            id = "config_mode_classic",
            label = roomText("room.mode_classic", "经典模式"),
            x = input_x,
            y = input_y + math.floor(28 * layout.scale),
            width = button_width,
            height = button_height,
            hovered = state.hovered_control == "config_mode_classic",
            enabled = is_owner and not state.loading and not state.saving and not state.leaving,
            variant = current_mode == "classic" and "primary" or "secondary",
        }),
        RoomPageActionButton.new({
            id = "config_mode_level",
            label = roomText("room.mode_level", "升级模式"),
            x = input_x + button_width + button_gap,
            y = input_y + math.floor(28 * layout.scale),
            width = button_width,
            height = button_height,
            hovered = state.hovered_control == "config_mode_level",
            enabled = is_owner and not state.loading and not state.saving and not state.leaving,
            variant = current_mode == "level" and "primary" or "secondary",
        }),
    }
end

function RoomView:getPlayerRows(state)
    local layout = resolveLayout(self)
    local room = state.room or {}
    local players_by_seat = {}
    local my_player = nil
    local is_owner = sameSteamID(room.owner_steam_id, state.steam_id)

    for _, player in ipairs(room.players or {}) do
        local seat_index = tonumber(player.seat_index)
        if seat_index ~= nil and seat_index >= 0 then
            players_by_seat[seat_index] = player
        end
        if sameSteamID(player.steam_id, state.steam_id) then
            my_player = player
        end
    end

    local hero_x = layout.left_x + layout.hero_pad
    local hero_width = layout.top_width - layout.hero_pad * 2
    local player_y = layout.players_board_y + math.floor(62 * layout.scale)
    local rows = {}

    for seat_index = 0, 3 do
        local player = players_by_seat[seat_index]
        local clickable = player == nil
            and my_player ~= nil
            and state.realtime_status == "connected"
            and not state.loading
            and not state.saving
            and not state.leaving
            and (room.status or "waiting") ~= "in_game"
        local remove_action = nil
        if player ~= nil and player.is_bot and is_owner then
            local remove_enabled = state.realtime_status == "connected"
                and not state.loading
                and not state.saving
                and not state.leaving
                and (room.status or "waiting") ~= "in_game"
            local remove_id = "remove_bot_" .. tostring(player.steam_id)
            remove_action = {
                id = remove_id,
                label = roomText("room.remove_bot", "删除"),
                hovered = remove_enabled and state.hovered_control == remove_id,
                enabled = remove_enabled,
            }
        end

        rows[#rows + 1] = {
            id = clickable and ("seat_row_" .. tostring(seat_index)) or nil,
            seat_index = seat_index,
            player = player,
            x = hero_x + 18,
            y = player_y + seat_index * (layout.player_card_height + layout.player_gap),
            width = hero_width - 36,
            height = layout.player_card_height,
            clickable = clickable,
            is_self = player ~= nil and sameSteamID(player.steam_id, state.steam_id),
            remove_action = remove_action,
        }
    end

    return rows
end

function RoomView:getControlAt(x, y, state)
    for _, button in ipairs(self:getButtons(state)) do
        if button:containsPoint(x, y) then
            return button.enabled and button.id or nil
        end
    end

    for _, button in ipairs(self:getModeButtons(state)) do
        if button:containsPoint(x, y) then
            return button.enabled and button.id or nil
        end
    end

    for _, row in ipairs(self:getPlayerRows(state)) do
        local remove_bounds = RoomPlayerStatusCard.getRemoveActionBounds(row)
        if remove_bounds
            and x >= remove_bounds.x and x <= remove_bounds.x + remove_bounds.width
            and y >= remove_bounds.y and y <= remove_bounds.y + remove_bounds.height
        then
            return row.remove_action.enabled and row.remove_action.id or nil
        end

        if row.clickable
            and x >= row.x and x <= row.x + row.width
            and y >= row.y and y <= row.y + row.height
        then
            return row.id
        end
    end
    return nil
end

function RoomView:getInputAt(x, y, state)
    local room = state.room or {}
    if not sameSteamID(room.owner_steam_id, state.steam_id) then
        return nil
    end

    for _, input in ipairs(self:getInputs(state)) do
        if input:containsPoint(x, y) then
            return input.id
        end
    end
    return nil
end

function RoomView:getOverlayActionAt(x, y, state)
    return self.password_overlay:getOverlayActionAt(x, y, state)
end

local function drawInsetBoard(self, x, y, width, height)
    local colors = self.style.colors

    love.graphics.setColor(colors.card_alt)
    love.graphics.rectangle("fill", x, y, width, height, 18, 18)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(colors.card_border)
    love.graphics.rectangle("line", x + 1, y + 1, width - 2, height - 2, 18, 18)
    love.graphics.setLineWidth(1)
end

function RoomView:draw(state)
    local colors = self.style.colors
    local layout = resolveLayout(self)
    local room = state.room or {}

    PastelPatternBackground.draw(self.window_width, self.window_height, {
        grid_size = 52,
        cell_size = 86,
    })

    self.wood_panel:draw({
        x = layout.left_x,
        y = layout.top_y,
        width = layout.top_width,
        height = layout.top_height,
    }, {
        radius = math.floor(24 * layout.scale),
        shadow_offset = math.floor(8 * layout.scale),
        inner_inset = math.floor(10 * layout.scale),
        border_width = 2,
        inner_border_width = 1.5,
    })
    self.wood_panel:draw({
        x = layout.right_x,
        y = layout.top_y,
        width = layout.right_width,
        height = layout.right_height,
    }, {
        radius = math.floor(24 * layout.scale),
        shadow_offset = math.floor(8 * layout.scale),
        inner_inset = math.floor(10 * layout.scale),
        border_width = 2,
        inner_border_width = 1.5,
    })

    local hero_x = layout.left_x + layout.hero_pad
    local hero_y = layout.top_y + layout.hero_pad
    local hero_width = layout.top_width - layout.hero_pad * 2
    local players_board_y = layout.players_board_y
    local players_board_height = layout.players_board_height
    local button_board_y = layout.bottom_board_y

    drawInsetBoard(self, hero_x, hero_y, hero_width, layout.hero_height)

    love.graphics.setColor(colors.text_primary)
    local title_pad = math.floor(18 * layout.scale)
    local title_width = hero_width - title_pad * 2
    local room_id_text = tostring(room.room_id or state.room_id or "-")
    local hero_title = roomText("room.room_number", "房间号 " .. room_id_text, { room_id = room_id_text })
    local hero_title_font = fitFont(self.fonts, hero_title, title_width, { "Title2", "Title3", "TextBig" })
    love.graphics.setFont(hero_title_font)
    love.graphics.printf(hero_title, hero_x + title_pad, hero_y + math.floor(14 * layout.scale), title_width, "left")

    drawInsetBoard(self, hero_x, players_board_y, hero_width, players_board_height)
    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print(I18n:t("room.players"), hero_x + math.floor(20 * layout.scale), players_board_y + math.floor(18 * layout.scale))

    for index, row in ipairs(self:getPlayerRows(state)) do
        RoomPlayerStatusCard.new({
            player = row.player,
            index = index,
            seat_index = row.seat_index,
            x = row.x,
            y = row.y,
            width = row.width,
            height = row.height,
            hovered = state.hovered_control == row.id,
            clickable = row.clickable,
            is_self = row.is_self,
            remove_action = row.remove_action,
        }):draw(self.fonts, self.style)
    end

    drawInsetBoard(self, hero_x, button_board_y, hero_width, layout.bottom_board_height)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print(I18n:t("room.config"), layout.right_x + math.floor(30 * layout.scale), layout.top_y + math.floor(32 * layout.scale))

    local input_x = layout.right_x + math.floor(20 * layout.scale)
    local input_y = layout.top_y + math.floor(132 * layout.scale)
    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print(I18n:t("room.input_mode"), input_x + 2, input_y - 18)

    for _, button in ipairs(self:getModeButtons(state)) do
        button:draw(self.fonts, self.style)
    end

    for _, input in ipairs(self:getInputs(state)) do
        input:draw(self.fonts, self.style)
    end

    for _, button in ipairs(self:getButtons(state)) do
        button:draw(self.fonts, self.style)
    end

    love.graphics.setFont(self.fonts:get("Caption"))
    if state.error_message ~= "" then
        love.graphics.setColor(colors.error)
        love.graphics.printf(state.error_message, layout.left_x + math.floor(30 * layout.scale), layout.message_y, layout.top_width - math.floor(60 * layout.scale), "center")
    end

    if state.overlay_visible then
        self.password_overlay:draw(state)
    end
end

return RoomView
