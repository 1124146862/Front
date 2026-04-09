local JoinRoomOverlay = require("src.features.lobby.overlays.join_room_overlay")
local LobbyPageActionButton = require("src.features.lobby.components.lobby_page_action_button")
local LobbyRoomSummaryRow = require("src.features.lobby.components.lobby_room_summary_row")
local I18n = require("src.core.i18n.i18n")
local PastelPatternBackground = require("src.core.ui.pastel_pattern_background")
local WoodPanel = require("src.core.ui.wood_panel")

local LobbyView = {}
LobbyView.__index = LobbyView

function LobbyView.new(options)
    local self = setmetatable({}, LobbyView)

    self.fonts = assert(options and options.fonts, "LobbyView requires fonts")
    self.style = assert(options and options.style, "LobbyView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.join_overlay = JoinRoomOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.wood_panel = WoodPanel.new(self.style)

    return self
end

function LobbyView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.join_overlay:resize()
end

local function resolveLayout(view, state)
    local layout = view.style.layout
    local side_margin = 56
    local fit_width = math.max(640, view.window_width - side_margin * 2)
    local panel_width = math.min(layout.panel_width, fit_width)
    panel_width = math.min(panel_width, math.max(320, view.window_width - 20))
    local panel_x = math.floor((view.window_width - panel_width) * 0.5)
    local fixed_rows = 5
    local visible_room_count = math.max(fixed_rows, #(state.rooms or {}))
    local base_row_height = 96
    local base_row_gap = 14
    local header_height = 96
    local panel_y = layout.panel_y
    local board_y = panel_y + header_height
    local max_panel_height = math.max(360, view.window_height - panel_y - layout.controls_panel_height - 28)
    local max_board_height = math.max(180, max_panel_height - header_height - 24)
    local desired_rows_height = visible_room_count * base_row_height + math.max(0, visible_room_count - 1) * base_row_gap
    local available_rows_height = math.max(1, max_board_height - 30)
    local scale = math.min(1, available_rows_height / math.max(desired_rows_height, 1))
    scale = math.max(0.7, scale)
    local row_height = math.max(72, math.floor(base_row_height * scale))
    local row_gap = math.max(10, math.floor(base_row_gap * scale))
    local desired_board_height = visible_room_count * row_height + math.max(0, visible_room_count - 1) * row_gap + 30
    local board_height = math.min(max_board_height, math.max(200, desired_board_height))
    local panel_height = header_height + board_height + 24
    local total_block_height = panel_height + 18 + layout.controls_panel_height
    panel_y = math.max(34, math.floor((view.window_height - total_block_height) * 0.5))
    board_y = panel_y + header_height
    local controls_panel_y = panel_y + panel_height + 18

    return {
        panel_x = panel_x,
        panel_y = panel_y,
        panel_width = panel_width,
        panel_height = panel_height,
        row_height = row_height,
        row_gap = row_gap,
        rows_offset = (board_y - panel_y) + 16,
        board_y = board_y,
        board_height = board_height,
        controls_panel_y = controls_panel_y,
        controls_panel_height = layout.controls_panel_height,
        controls_y = controls_panel_y + 26,
        button_width = layout.button_width,
        button_height = layout.button_height,
    }
end

function LobbyView:getControls(state)
    local layout = resolveLayout(self, state)
    local top_y = layout.panel_y + 18
    local base_y = layout.controls_y
    local left_gap = 14
    local top_back_width = 170
    local top_refresh_width = 130
    local right_gap = 18
    local join_width = 160
    local create_width = 160
    local secondary_width = math.min(layout.button_width, math.max(118, layout.button_width))
    local join_x = layout.panel_x + layout.panel_width - 24 - join_width
    local create_x = join_x - right_gap - create_width
    local pager_x = layout.panel_x + 24
    local controls = {
        LobbyPageActionButton.new({
            id = "back",
            label = I18n:t("lobby.back"),
            x = layout.panel_x + 24,
            y = top_y,
            width = top_back_width,
            height = layout.button_height,
            hovered = state.hovered_control == "back",
            variant = "secondary",
        }),
        LobbyPageActionButton.new({
            id = "refresh",
            label = I18n:t("lobby.refresh"),
            x = layout.panel_x + layout.panel_width - 24 - top_refresh_width,
            y = top_y,
            width = top_refresh_width,
            height = layout.button_height,
            hovered = state.hovered_control == "refresh",
            enabled = not state.loading and not state.submitting,
            variant = "secondary",
        }),
    }

    controls[#controls + 1] = LobbyPageActionButton.new({
        id = "prev_page",
        label = I18n:t("lobby.prev_page"),
        x = pager_x,
        y = base_y,
        width = secondary_width,
        height = layout.button_height,
        hovered = state.hovered_control == "prev_page",
        enabled = state.has_prev and not state.loading and not state.submitting,
        variant = "secondary",
    })
    pager_x = pager_x + secondary_width + left_gap

    controls[#controls + 1] = LobbyPageActionButton.new({
        id = "next_page",
        label = I18n:t("lobby.next_page"),
        x = pager_x,
        y = base_y,
        width = secondary_width,
        height = layout.button_height,
        hovered = state.hovered_control == "next_page",
        enabled = state.has_next and not state.loading and not state.submitting,
        variant = "secondary",
    })

    controls[#controls + 1] = LobbyPageActionButton.new({
            id = "create_room",
            label = I18n:t("lobby.create_room"),
            x = create_x,
            y = base_y,
            width = create_width,
            height = layout.button_height,
            hovered = state.hovered_control == "create_room",
            enabled = not state.loading and not state.submitting,
            variant = "primary",
        })
    controls[#controls + 1] = LobbyPageActionButton.new({
            id = "join_room",
            label = I18n:t("lobby.join_room"),
            x = join_x,
            y = base_y,
            width = join_width,
            height = layout.button_height,
            hovered = state.hovered_control == "join_room",
            enabled = not state.loading and not state.submitting,
            variant = "primary",
        })

    return controls
end

function LobbyView:getControlAt(x, y, state)
    for _, control in ipairs(self:getControls(state)) do
        if control:containsPoint(x, y) then
            return control.enabled and control.id or nil
        end
    end

    return nil
end

function LobbyView:getRoomJoinActionAt(x, y, state)
    local layout = resolveLayout(self, state)
    local row_y = layout.panel_y + layout.rows_offset

    for index, room in ipairs(state.rooms or {}) do
        local row = LobbyRoomSummaryRow.new({
            room = room,
            index = index,
            x = layout.panel_x + 20,
            y = row_y + (index - 1) * (layout.row_height + layout.row_gap),
            width = layout.panel_width - 40,
            height = layout.row_height,
        })

        if row:isJoinButtonHovered(x, y) then
            return room
        end
    end

    return nil
end

function LobbyView:getOverlayActionAt(x, y, state)
    return self.join_overlay:getOverlayActionAt(x, y, state)
end

local function drawInsetBoard(self, x, y, width, height)
    local colors = self.style.colors

    love.graphics.setColor(colors.card_alt)
    love.graphics.rectangle("fill", x, y, width, height, 18, 18)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(colors.card_border)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, width - 1, height - 1, 18, 18)
    love.graphics.setLineWidth(1)
end

function LobbyView:draw(state)
    local colors = self.style.colors
    local layout = resolveLayout(self, state)
    PastelPatternBackground.draw(self.window_width, self.window_height, {
        grid_size = 52,
        cell_size = 86,
    })

    love.graphics.setColor(colors.text_inverse)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("lobby.title"), 0, 48, self.window_width, "center")

    self.wood_panel:draw({
        x = layout.panel_x,
        y = layout.panel_y,
        width = layout.panel_width,
        height = layout.panel_height,
    }, {
        radius = 22,
        shadow_offset = 6,
        inner_inset = 10,
        border_width = 2,
        inner_border_width = 1.5,
    })

    drawInsetBoard(self, layout.panel_x + 20, layout.board_y, layout.panel_width - 40, layout.board_height)

    local row_y = layout.panel_y + layout.rows_offset
    local fixed_rows = 5
    for index = 1, fixed_rows do
        local y = row_y + (index - 1) * (layout.row_height + layout.row_gap)
        local room = state.rooms[index]
        if room then
            LobbyRoomSummaryRow.new({
                room = room,
                index = index,
                x = layout.panel_x + 20,
                y = y,
                width = layout.panel_width - 40,
                height = layout.row_height,
                join_hovered = state.hovered_join_room_id == room.room_id,
            }):draw(self.fonts, self.style)
        else
            love.graphics.setColor(colors.row_alt[1], colors.row_alt[2], colors.row_alt[3], 0.55)
            love.graphics.rectangle("fill", layout.panel_x + 20, y, layout.panel_width - 40, layout.row_height, 14, 14)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(colors.card_border[1], colors.card_border[2], colors.card_border[3], 0.35)
            love.graphics.rectangle("line", layout.panel_x + 20 + 0.5, y + 0.5, layout.panel_width - 41, layout.row_height - 1, 14, 14)
            love.graphics.setLineWidth(1)
        end
    end

    if #state.rooms == 0 and not state.loading and state.error_message == "" then
        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf(I18n:t("lobby.no_rooms"), layout.panel_x, row_y + layout.row_height * 2, layout.panel_width, "center")
    end

    self.wood_panel:draw({
        x = layout.panel_x + 20,
        y = layout.controls_panel_y,
        width = layout.panel_width - 40,
        height = layout.controls_panel_height,
    }, {
        radius = 16,
        shadow_offset = 5,
        inner_inset = 8,
        border_width = 2,
        inner_border = false,
    })

    love.graphics.setFont(self.fonts:get("Caption"))
    if state.error_message ~= "" then
        love.graphics.setColor(colors.error)
        love.graphics.printf(state.error_message, layout.panel_x + 34, layout.controls_panel_y + 14, layout.panel_width - 68, "center")
    end

    for _, control in ipairs(self:getControls(state)) do
        control:draw(self.fonts, self.style)
    end

    if state.overlay_visible then
        self.join_overlay:draw(state)
        return
    end
end

return LobbyView
