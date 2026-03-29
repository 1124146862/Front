local WelcomePage = {}
WelcomePage.__index = WelcomePage

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function pointInRect(x, y, rect)
    return x >= rect.x
        and x <= rect.x + rect.w
        and y >= rect.y
        and y <= rect.y + rect.h
end

function WelcomePage.new(options)
    local self = setmetatable({}, WelcomePage)

    self.options = options or {}
    self.hover_button = false
    self.toast_timer = 0
    self.toast_duration = 2.4
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.fonts = assert(self.options.fonts, "WelcomePage requires a font manager")

    self.button = {}
    self:layout()

    return self
end

function WelcomePage:layout()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()

    local button_width = clamp(self.window_width * 0.21, 280, 360)
    local button_height = clamp(self.window_height * 0.1, 72, 94)

    self.button = {
        w = button_width,
        h = button_height,
        x = (self.window_width - button_width) * 0.5,
        y = self.window_height * 0.72,
    }
end

function WelcomePage:update(dt)
    self.toast_timer = math.max(0, self.toast_timer - dt)
end

function WelcomePage:resize()
    self:layout()
end

function WelcomePage:showComingSoon()
    self.toast_timer = self.toast_duration
end

function WelcomePage:isButtonHovered(x, y)
    return pointInRect(x, y, self.button)
end

function WelcomePage:mousemoved(x, y)
    self.hover_button = self:isButtonHovered(x, y)
end

function WelcomePage:activate()
    if self.options.on_continue then
        self.options.on_continue()
    end
end

function WelcomePage:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if self:isButtonHovered(x, y) then
        self:activate()
    end
end

function WelcomePage:keypressed(key)
    if key == "return" or key == "kpenter" or key == "space" then
        self:activate()
    end
end

function WelcomePage:drawBackground()
    local w = self.window_width
    local h = self.window_height

    love.graphics.clear(0.05, 0.07, 0.09, 1)

    love.graphics.setColor(0.07, 0.1, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
end

function WelcomePage:drawHero()
    local w = self.window_width
    local h = self.window_height
    local panel_width = clamp(w * 0.52, 640, 820)
    local panel_height = clamp(h * 0.3, 220, 300)
    local panel_x = (w - panel_width) * 0.5
    local panel_y = h * 0.24

    love.graphics.setColor(0.09, 0.13, 0.16, 1)
    love.graphics.rectangle("fill", panel_x, panel_y, panel_width, panel_height, 34, 34)

    love.graphics.setColor(0.2, 0.26, 0.3, 1)
    love.graphics.rectangle("line", panel_x, panel_y, panel_width, panel_height, 34, 34)

    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(0.72, 0.79, 0.84, 1)
    love.graphics.printf("欢迎进入掼蛋", panel_x, panel_y + 30, panel_width, "center")

    love.graphics.setFont(self.fonts:get("Title1"))
    love.graphics.setColor(0.95, 0.96, 0.97, 1)
    love.graphics.printf("掼蛋", panel_x, panel_y + 72, panel_width, "center")

    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.setColor(0.74, 0.79, 0.82, 1)
    love.graphics.printf(
        "当前先实现页面流程与基础交互。\n点击下方按钮进入下一步。",
        panel_x + 54,
        panel_y + 192,
        panel_width - 108,
        "center"
    )
end

function WelcomePage:drawButton()
    local fill = self.hover_button and { 0.24, 0.34, 0.42, 1 } or { 0.18, 0.26, 0.33, 1 }
    local border = self.hover_button and { 0.58, 0.72, 0.82, 1 } or { 0.34, 0.45, 0.52, 1 }

    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", self.button.x, self.button.y, self.button.w, self.button.h, 26, 26)

    love.graphics.setColor(border)
    love.graphics.rectangle("line", self.button.x, self.button.y, self.button.w, self.button.h, 26, 26)

    love.graphics.setFont(self.fonts:get("Button"))
    love.graphics.setColor(0.96, 0.97, 0.98, 1)
    love.graphics.printf("进入游戏", self.button.x, self.button.y + 22, self.button.w, "center")

    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(0.62, 0.69, 0.74, 1)
    love.graphics.printf("按回车键或点击按钮继续", self.button.x, self.button.y + self.button.h + 18, self.button.w, "center")
end

function WelcomePage:drawToast()
    if self.toast_timer <= 0 then
        return
    end

    local alpha = math.min(1, self.toast_timer / self.toast_duration)
    local width = clamp(self.window_width * 0.34, 360, 520)
    local height = 56
    local x = (self.window_width - width) * 0.5
    local y = self.window_height * 0.88

    love.graphics.setColor(0.09, 0.13, 0.16, 0.92 * alpha)
    love.graphics.rectangle("fill", x, y, width, height, 18, 18)

    love.graphics.setColor(0.36, 0.47, 0.55, alpha)
    love.graphics.rectangle("line", x, y, width, height, 18, 18)

    love.graphics.setFont(self.fonts:get("Text"))
    love.graphics.setColor(0.95, 0.96, 0.97, alpha)
    love.graphics.printf("下一页昵称检查页还没接入，这里先占位。", x, y + 14, width, "center")
end

function WelcomePage:drawFooter()
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(0.47, 0.55, 0.6, 1)
    love.graphics.printf(
        "当前页面：欢迎页原型",
        0,
        self.window_height - 42,
        self.window_width,
        "center"
    )
end

function WelcomePage:draw()
    self:drawBackground()
    self:drawHero()
    self:drawButton()
    self:drawToast()
    self:drawFooter()
end

return WelcomePage
