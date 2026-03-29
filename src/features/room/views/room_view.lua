local RoomPageActionButton = require("src.features.room.components.room_page_action_button")
local RoomPageTextInput = require("src.features.room.components.room_page_text_input")
local RoomPlayerStatusCard = require("src.features.room.components.room_player_status_card")

local RoomView = {}
RoomView.__index = RoomView

function RoomView.new(options)
    local self = setmetatable({}, RoomView)

    self.fonts = assert(options and options.fonts, "RoomView requires fonts")
    self.style = assert(options and options.style, "RoomView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()

    return self
end

function RoomView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function RoomView:getButtons(state)
    local layout = self.style.layout
    local room = state.room or {}
    local is_owner = room.owner_steam_id == state.steam_id
    local me_ready = false

    if room.players then
        for _, player in ipairs(room.players) do
            if player.steam_id == state.steam_id then
                me_ready = player.is_ready == true
                break
            end
        end
    end

    return {
        RoomPageActionButton.new({
            id = "refresh_room",
            label = "刷新房间",
            x = layout.left_x,
            y = 698,
            width = 140,
            height = layout.button_height,
            hovered = state.hovered_control == "refresh_room",
            enabled = not state.loading and not state.saving and not state.leaving,
        }),
        RoomPageActionButton.new({
            id = "toggle_ready",
            label = me_ready and "取消准备" or "准备",
            x = layout.left_x + 160,
            y = 698,
            width = 160,
            height = layout.button_height,
            hovered = state.hovered_control == "toggle_ready",
            enabled = not state.loading and not state.saving and not state.leaving,
        }),
        RoomPageActionButton.new({
            id = "leave_room",
            label = "离开房间",
            x = layout.left_x + 340,
            y = 698,
            width = 160,
            height = layout.button_height,
            hovered = state.hovered_control == "leave_room",
            enabled = not state.loading and not state.saving and not state.leaving,
        }),
        RoomPageActionButton.new({
            id = "save_config",
            label = "保存配置",
            x = layout.right_x + 190,
            y = 472,
            width = 140,
            height = layout.button_height,
            hovered = state.hovered_control == "save_config",
            enabled = is_owner and not state.loading and not state.saving and not state.leaving,
        }),
    }
end

function RoomView:getInputs(state)
    local layout = self.style.layout
    local room = state.room or {}
    local is_owner = room.owner_steam_id == state.steam_id
    if not is_owner then
        return {}
    end

    return {
        RoomPageTextInput.new({
            id = "config_title",
            label = "房间标题",
            value = state.config_title_input,
            placeholder = "请输入房间标题",
            x = layout.right_x + 20,
            y = 220,
            width = layout.right_width - 40,
            height = layout.input_height,
            focused = state.focused_field == "config_title",
        }),
        RoomPageTextInput.new({
            id = "config_mode",
            label = "游戏模式",
            value = state.config_mode_input,
            placeholder = "classic",
            x = layout.right_x + 20,
            y = 296,
            width = layout.right_width - 40,
            height = layout.input_height,
            focused = state.focused_field == "config_mode",
        }),
        RoomPageTextInput.new({
            id = "config_password",
            label = "房间密码（可空）",
            value = state.config_password_input,
            placeholder = "留空表示无密码",
            x = layout.right_x + 20,
            y = 372,
            width = layout.right_width - 40,
            height = layout.input_height,
            focused = state.focused_field == "config_password",
        }),
    }
end

function RoomView:getControlAt(x, y, state)
    for _, button in ipairs(self:getButtons(state)) do
        if button:containsPoint(x, y) then
            return button.enabled and button.id or nil
        end
    end
    return nil
end

function RoomView:getInputAt(x, y, state)
    for _, input in ipairs(self:getInputs(state)) do
        if input:containsPoint(x, y) then
            return input.id
        end
    end
    return nil
end

function RoomView:draw(state)
    local colors = self.style.colors
    local layout = self.style.layout
    local room = state.room or {}

    love.graphics.clear(colors.background)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf("房间等待页", 0, 32, self.window_width, "center")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf("房间 " .. tostring(room.room_id or state.room_id or "-"), 0, 62, self.window_width, "center")

    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", layout.left_x, layout.top_y, layout.top_width, 580, 14, 14)
    love.graphics.rectangle("fill", layout.right_x, layout.top_y, layout.right_width, layout.right_height, 14, 14)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.print("标题：" .. tostring(room.title or "-"), layout.left_x + 24, layout.top_y + 22)
    love.graphics.print("模式：" .. tostring(room.game_mode or "-"), layout.left_x + 24, layout.top_y + 60)
    love.graphics.print("人数：" .. tostring(room.player_count or 0) .. "/" .. tostring(room.max_player_count or 4), layout.left_x + 24, layout.top_y + 98)
    love.graphics.print("状态：" .. tostring(room.status or "-"), layout.left_x + 24, layout.top_y + 136)
    love.graphics.print("全员准备：" .. ((room.all_ready and "是") or "否"), layout.left_x + 24, layout.top_y + 174)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print("玩家列表", layout.left_x + 24, layout.top_y + 236)

    local player_y = layout.top_y + 286
    local players = room.players or {}
    if #players == 0 then
        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf("当前房间还没有玩家。", layout.left_x, player_y + 80, layout.top_width, "center")
    else
        for index, player in ipairs(players) do
            RoomPlayerStatusCard.new({
                player = player,
                index = index,
                x = layout.left_x + 20,
                y = player_y + (index - 1) * (layout.player_card_height + layout.player_gap),
                width = layout.top_width - 40,
                height = layout.player_card_height,
            }):draw(self.fonts, self.style)
        end
    end

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print("房间配置", layout.right_x + 20, layout.top_y + 22)

    local is_owner = room.owner_steam_id == state.steam_id
    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(
        is_owner and "你是房主，可以修改标题、模式和密码。" or "只有房主可以修改房间配置。",
        layout.right_x + 20,
        layout.top_y + 60,
        layout.right_width - 40,
        "left"
    )

    for _, input in ipairs(self:getInputs(state)) do
        input:draw(self.fonts, self.style)
    end

    for _, button in ipairs(self:getButtons(state)) do
        button:draw(self.fonts, self.style)
    end

    love.graphics.setFont(self.fonts:get("Caption"))
    if state.error_message ~= "" then
        love.graphics.setColor(0.92, 0.48, 0.45, 1)
        love.graphics.printf(state.error_message, layout.left_x, 772, 1120, "center")
    else
        love.graphics.setColor(colors.ok)
        love.graphics.printf(state.status_message or "", layout.left_x, 772, 1120, "center")
    end
end

return RoomView
