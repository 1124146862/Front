local NicknameCheckButton = require("src.features.session.components.nickname_check_button")
local NicknameCheckInput = require("src.features.session.components.nickname_check_input")

local NicknameCheckView = {}
NicknameCheckView.__index = NicknameCheckView

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

function NicknameCheckView.new(options)
    local self = setmetatable({}, NicknameCheckView)

    self.fonts = assert(options and options.fonts, "NicknameCheckView requires fonts")
    self.style = assert(options and options.style, "NicknameCheckView requires style")
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.input = NicknameCheckInput.new(self.style)
    self.button = NicknameCheckButton.new(self.style)
    self.layout = {}

    self:resize(self.window_width, self.window_height)

    return self
end

function NicknameCheckView:resize(width, height)
    self.window_width = width
    self.window_height = height

    local panel_width = clamp(self.style.panel.width, 620, width - 120)
    local panel_height = self.style.panel.height
    local panel_x = (width - panel_width) * 0.5
    local panel_y = (height - panel_height) * 0.5 - 24
    local input_x = panel_x + 54
    local input_y = panel_y + 212
    local input_width = panel_width - 108
    local button_width = self.style.button.width
    local button_x = panel_x + panel_width - 54 - button_width
    local button_y = input_y + self.style.input.height + 34

    self.layout = {
        panel = {
            x = panel_x,
            y = panel_y,
            w = panel_width,
            h = panel_height,
        },
        input = {
            x = input_x,
            y = input_y,
            w = input_width,
            h = self.style.input.height,
        },
        button = {
            x = button_x,
            y = button_y,
            w = button_width,
            h = self.style.button.height,
        },
    }

    self.input:setBounds(input_x, input_y, input_width, self.style.input.height)
    self.button:setBounds(button_x, button_y, button_width, self.style.button.height)
end

function NicknameCheckView:isInputHovered(x, y)
    return self.input:contains(x, y)
end

function NicknameCheckView:isButtonHovered(x, y)
    return self.button:contains(x, y)
end

function NicknameCheckView:draw(state)
    local colors = self.style.colors
    local panel = self.layout.panel
    local input = self.layout.input
    local text_y = panel.y + 34

    love.graphics.clear(colors.background[1], colors.background[2], colors.background[3], colors.background[4])

    love.graphics.setColor(colors.panel[1], colors.panel[2], colors.panel[3], colors.panel[4])
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, self.style.panel.radius, self.style.panel.radius)

    love.graphics.setColor(colors.panel_border[1], colors.panel_border[2], colors.panel_border[3], colors.panel_border[4])
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, self.style.panel.radius, self.style.panel.radius)

    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(colors.text_secondary[1], colors.text_secondary[2], colors.text_secondary[3], colors.text_secondary[4])
    love.graphics.printf("账号初始化", panel.x, text_y, panel.w, "center")

    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.setColor(colors.text_primary[1], colors.text_primary[2], colors.text_primary[3], colors.text_primary[4])
    love.graphics.printf("设置昵称", panel.x, text_y + 32, panel.w, "center")

    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.setColor(colors.text_secondary[1], colors.text_secondary[2], colors.text_secondary[3], colors.text_secondary[4])
    love.graphics.printf(
        "当前先模拟通过 SteamID 查询昵称。\n默认返回未设置昵称，请输入后继续。",
        panel.x + 54,
        text_y + 104,
        panel.w - 108,
        "center"
    )

    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.setColor(colors.text_secondary[1], colors.text_secondary[2], colors.text_secondary[3], colors.text_secondary[4])
    love.graphics.print("SteamID: " .. tostring(state.steam_id or "-"), input.x, input.y - 34)

    self.input:draw(self.fonts, state.nickname_input, "请输入昵称", state.input_focused)

    love.graphics.setFont(self.fonts:get("Caption"))
    if state.error_message ~= "" then
        love.graphics.setColor(colors.error[1], colors.error[2], colors.error[3], colors.error[4])
        love.graphics.print(state.error_message, input.x, input.y + input.h + 12)
    else
        love.graphics.setColor(colors.text_secondary[1], colors.text_secondary[2], colors.text_secondary[3], colors.text_secondary[4])
        love.graphics.print(state.status_message, input.x, input.y + input.h + 12)
    end

    local button_label = state.submit_pending and "提交中..." or "确认昵称"
    self.button:draw(self.fonts, button_label, state.button_hovered, state.submit_pending or state.query_pending)
end

return NicknameCheckView
