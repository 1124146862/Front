local LobbyRoomSummaryRow = {}
LobbyRoomSummaryRow.__index = LobbyRoomSummaryRow

function LobbyRoomSummaryRow.new(options)
    local self = setmetatable({}, LobbyRoomSummaryRow)

    self.room = assert(options and options.room, "LobbyRoomSummaryRow requires room")
    self.index = options.index or 1
    self.x = options.x or 0
    self.y = options.y or 0
    self.width = options.width or 1000
    self.height = options.height or 56

    return self
end

function LobbyRoomSummaryRow:draw(fonts, style)
    local colors = style.colors
    local background = (self.index % 2 == 1) and colors.row or colors.row_alt

    love.graphics.setColor(background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("TextSmall"))

    local columns = {
        { x = 18, width = 100, text = tostring(self.room.room_id or "-") },
        { x = 130, width = 280, text = tostring(self.room.title or "-") },
        { x = 430, width = 160, text = tostring(self.room.game_mode or "-") },
        {
            x = 610,
            width = 140,
            text = string.format("%s/%s", tostring(self.room.player_count or 0), tostring(self.room.max_player_count or 4)),
        },
        { x = 770, width = 120, text = (self.room.has_password and "有密码") or "无密码" },
        { x = 910, width = 150, text = tostring(self.room.status or "-") },
    }

    for _, column in ipairs(columns) do
        love.graphics.printf(column.text, self.x + column.x, self.y + 16, column.width, "left")
    end
end

return LobbyRoomSummaryRow
