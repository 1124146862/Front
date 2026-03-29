local MainMenuEntryActionButton = require("src.features.main_menu.components.main_menu_entry_action_button")

local MainMenuView = {}
MainMenuView.__index = MainMenuView

local ACTIONS = {
    { id = "single_player", label = "单人游戏", enabled = true },
    { id = "online_lobby", label = "联机大厅", enabled = true },
    { id = "matchmaking", label = "匹配模式", enabled = true },
    { id = "game_settings", label = "游戏设置", enabled = true },
}

function MainMenuView.new(options)
    local self = setmetatable({}, MainMenuView)

    self.fonts = assert(options and options.fonts, "MainMenuView requires fonts")
    self.style = assert(options and options.style, "MainMenuView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()

    return self
end

function MainMenuView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function MainMenuView:getButtons(hovered_action)
    local layout = self.style.layout
    local panel_x = math.floor((self.window_width - layout.panel_width) / 2)
    local buttons_x = math.floor((self.window_width - layout.button_width) / 2)
    local start_y = 290
    local buttons = {}

    for index, action in ipairs(ACTIONS) do
        local y = start_y + (index - 1) * (layout.button_height + layout.button_gap)
        buttons[#buttons + 1] = MainMenuEntryActionButton.new({
            id = action.id,
            label = action.label,
            enabled = action.enabled,
            hovered = hovered_action == action.id,
            x = buttons_x,
            y = y,
            width = layout.button_width,
            height = layout.button_height,
            panel_x = panel_x,
        })
    end

    return buttons
end

function MainMenuView:getActionAt(x, y, hovered_action)
    local buttons = self:getButtons(hovered_action)
    for _, button in ipairs(buttons) do
        if button:containsPoint(x, y) then
            return button.id
        end
    end

    return nil
end

function MainMenuView:draw(state, user_profile)
    local colors = self.style.colors
    local layout = self.style.layout
    local panel_x = math.floor((self.window_width - layout.panel_width) / 2)

    love.graphics.clear(colors.background)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf("游戏主界面", 0, 108, self.window_width, "center")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf("主菜单", 0, 142, self.window_width, "center")

    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", panel_x, 210, layout.panel_width, 430, 14, 14)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf("昵称：" .. tostring((user_profile or {}).nickname or "-"), panel_x, 228, layout.panel_width, "center")

    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.printf("SteamID：" .. tostring((user_profile or {}).steam_id or "-"), panel_x, 266, layout.panel_width, "center")

    for _, button in ipairs(self:getButtons(state.hovered_action)) do
        button:draw(self.fonts, self.style)
    end

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(state.status_message or "", panel_x, 600, layout.panel_width, "center")
end

return MainMenuView
