local GameplayPage = {}
GameplayPage.__index = GameplayPage

function GameplayPage.new(options)
    local self = setmetatable({}, GameplayPage)

    self.fonts = assert(options and options.fonts, "GameplayPage requires fonts")
    self.room = (options and options.room) or {}

    return self
end

function GameplayPage:draw()
    love.graphics.clear(0.05, 0.07, 0.09, 1)

    love.graphics.setColor(0.72, 0.79, 0.84, 1)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf("对局界面", 0, 120, love.graphics.getWidth(), "center")

    love.graphics.setColor(0.95, 0.96, 0.97, 1)
    love.graphics.setFont(self.fonts:get("Title2"))
    love.graphics.printf("游戏已开始", 0, 160, love.graphics.getWidth(), "center")

    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf("房间号：" .. tostring(self.room.room_id or "-"), 0, 280, love.graphics.getWidth(), "center")
    love.graphics.printf("房间标题：" .. tostring(self.room.title or "-"), 0, 330, love.graphics.getWidth(), "center")
    love.graphics.printf("游戏模式：" .. tostring(self.room.game_mode or "-"), 0, 380, love.graphics.getWidth(), "center")

    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(0.48, 0.56, 0.62, 1)
    love.graphics.printf("后续这里接真正的对局桌面和手牌逻辑。", 0, 470, love.graphics.getWidth(), "center")
end

return GameplayPage
