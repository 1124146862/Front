local RoomPlayerStatusCard = {}
RoomPlayerStatusCard.__index = RoomPlayerStatusCard

function RoomPlayerStatusCard.new(options)
    local self = setmetatable({}, RoomPlayerStatusCard)

    self.player = assert(options and options.player, "RoomPlayerStatusCard requires player")
    self.index = options.index or 1
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 720
    self.height = options.height or 74

    return self
end

function RoomPlayerStatusCard:draw(fonts, style)
    local colors = style.colors
    local background = (self.index % 2 == 1) and colors.card or colors.card_alt
    local ready_text = self.player.is_ready and "已准备" or "未准备"
    local owner_text = self.player.is_owner and "房主" or "玩家"

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("TextSmall"))
    love.graphics.print(owner_text, self.x + 18, self.y + 16)
    love.graphics.print(self.player.nickname or "-", self.x + 110, self.y + 16)
    love.graphics.print("SteamID: " .. tostring(self.player.steam_id or "-"), self.x + 310, self.y + 16)
    love.graphics.print(ready_text, self.x + 560, self.y + 16)
end

return RoomPlayerStatusCard
