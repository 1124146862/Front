local LobbyPageActionButton = require("src.features.lobby.components.lobby_page_action_button")
local LobbyPageTextInput = require("src.features.lobby.components.lobby_page_text_input")
local LobbyRoomSummaryRow = require("src.features.lobby.components.lobby_room_summary_row")

local LobbyView = {}
LobbyView.__index = LobbyView

function LobbyView.new(options)
    local self = setmetatable({}, LobbyView)

    self.fonts = assert(options and options.fonts, "LobbyView requires fonts")
    self.style = assert(options and options.style, "LobbyView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()

    return self
end

function LobbyView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function LobbyView:getControls(state)
    local layout = self.style.layout
    local base_y = layout.controls_y

    return {
        LobbyPageActionButton.new({
            id = "back",
            label = "返回主菜单",
            x = layout.panel_x,
            y = base_y,
            width = 160,
            height = layout.button_height,
            hovered = state.hovered_control == "back",
        }),
        LobbyPageActionButton.new({
            id = "refresh",
            label = "刷新",
            x = layout.panel_x + 180,
            y = base_y,
            width = layout.button_width,
            height = layout.button_height,
            hovered = state.hovered_control == "refresh",
            enabled = not state.loading and not state.submitting,
        }),
        LobbyPageActionButton.new({
            id = "prev_page",
            label = "上一页",
            x = layout.panel_x + 340,
            y = base_y,
            width = layout.button_width,
            height = layout.button_height,
            hovered = state.hovered_control == "prev_page",
            enabled = state.has_prev and not state.loading and not state.submitting,
        }),
        LobbyPageActionButton.new({
            id = "next_page",
            label = "下一页",
            x = layout.panel_x + 500,
            y = base_y,
            width = layout.button_width,
            height = layout.button_height,
            hovered = state.hovered_control == "next_page",
            enabled = state.has_next and not state.loading and not state.submitting,
        }),
        LobbyPageActionButton.new({
            id = "create_room",
            label = "创建房间",
            x = layout.panel_x + 820,
            y = base_y,
            width = 160,
            height = layout.button_height,
            hovered = state.hovered_control == "create_room",
            enabled = not state.loading and not state.submitting,
        }),
        LobbyPageActionButton.new({
            id = "join_room",
            label = "加入房间",
            x = layout.panel_x + 1000,
            y = base_y,
            width = 160,
            height = layout.button_height,
            hovered = state.hovered_control == "join_room",
            enabled = not state.loading and not state.submitting,
        }),
    }
end

function LobbyView:getInputs(state)
    local layout = self.style.layout
    local left_x = layout.panel_x + 24
    local right_x = layout.panel_x + 24 + layout.form_width + 32
    local start_y = layout.panel_y + 436

    return {
        LobbyPageTextInput.new({
            id = "create_title",
            label = "房间标题",
            value = state.create_title_input,
            placeholder = "请输入房间标题",
            x = left_x,
            y = start_y,
            width = layout.form_width,
            height = layout.input_height,
            focused = state.focused_field == "create_title",
        }),
        LobbyPageTextInput.new({
            id = "create_mode",
            label = "游戏模式",
            value = state.create_mode_input,
            placeholder = "classic",
            x = left_x,
            y = start_y + 74,
            width = layout.form_width,
            height = layout.input_height,
            focused = state.focused_field == "create_mode",
        }),
        LobbyPageTextInput.new({
            id = "create_password",
            label = "房间密码（可空）",
            value = state.create_password_input,
            placeholder = "留空表示无密码",
            x = left_x,
            y = start_y + 148,
            width = layout.form_width,
            height = layout.input_height,
            focused = state.focused_field == "create_password",
        }),
        LobbyPageTextInput.new({
            id = "join_room_id",
            label = "房间号",
            value = state.join_room_id_input,
            placeholder = "请输入房间号",
            x = right_x,
            y = start_y,
            width = layout.form_width,
            height = layout.input_height,
            focused = state.focused_field == "join_room_id",
        }),
        LobbyPageTextInput.new({
            id = "join_password",
            label = "房间密码（可空）",
            value = state.join_password_input,
            placeholder = "有密码房间需要填写",
            x = right_x,
            y = start_y + 74,
            width = layout.form_width,
            height = layout.input_height,
            focused = state.focused_field == "join_password",
        }),
    }
end

function LobbyView:getControlAt(x, y, state)
    for _, control in ipairs(self:getControls(state)) do
        if control:containsPoint(x, y) then
            return control.enabled and control.id or nil
        end
    end

    return nil
end

function LobbyView:getInputAt(x, y, state)
    for _, input in ipairs(self:getInputs(state)) do
        if input:containsPoint(x, y) then
            return input.id
        end
    end

    return nil
end

function LobbyView:draw(state)
    local colors = self.style.colors
    local layout = self.style.layout

    love.graphics.clear(colors.background)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf("联机大厅", 0, 32, self.window_width, "center")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf("房间列表", 0, 62, self.window_width, "center")

    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", layout.panel_x, layout.panel_y, layout.panel_width, layout.panel_height, 14, 14)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print("房间总数：" .. tostring(state.total or 0), layout.panel_x + 24, layout.panel_y + 20)
    love.graphics.print("当前页：" .. tostring(state.page or 1), layout.panel_x + 220, layout.panel_y + 20)
    love.graphics.print("每页：" .. tostring(state.page_size or 2), layout.panel_x + 380, layout.panel_y + 20)

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.print("ID", layout.panel_x + 20, layout.panel_y + 68)
    love.graphics.print("Title", layout.panel_x + 132, layout.panel_y + 68)
    love.graphics.print("GameMode", layout.panel_x + 432, layout.panel_y + 68)
    love.graphics.print("人数", layout.panel_x + 612, layout.panel_y + 68)
    love.graphics.print("密码", layout.panel_x + 772, layout.panel_y + 68)
    love.graphics.print("状态", layout.panel_x + 912, layout.panel_y + 68)

    local row_y = layout.panel_y + 96
    if #state.rooms == 0 and not state.loading and state.error_message == "" then
        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf("当前没有房间。请先创建房间。", layout.panel_x, row_y + 70, layout.panel_width, "center")
    else
        for index, room in ipairs(state.rooms) do
            LobbyRoomSummaryRow.new({
                room = room,
                index = index,
                x = layout.panel_x + 20,
                y = row_y + (index - 1) * (layout.row_height + layout.row_gap),
                width = layout.panel_width - 40,
                height = layout.row_height,
            }):draw(self.fonts, self.style)
        end
    end

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.print("创建房间", layout.panel_x + 24, layout.panel_y + 392)
    love.graphics.print("按房间号加入", layout.panel_x + 24 + layout.form_width + 32, layout.panel_y + 392)

    for _, input in ipairs(self:getInputs(state)) do
        input:draw(self.fonts, self.style)
    end

    for _, control in ipairs(self:getControls(state)) do
        control:draw(self.fonts, self.style)
    end

    love.graphics.setFont(self.fonts:get("Caption"))
    if state.error_message ~= "" then
        love.graphics.setColor(0.92, 0.48, 0.45, 1)
        love.graphics.printf(state.error_message, layout.panel_x, 778, layout.panel_width, "center")
    else
        love.graphics.setColor(colors.ok)
        love.graphics.printf(state.status_message or "", layout.panel_x, 778, layout.panel_width, "center")
    end
end

return LobbyView
