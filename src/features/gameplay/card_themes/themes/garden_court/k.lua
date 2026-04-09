local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local K = {}

function K.draw(frame, context)
    local suit = context.suit_color or { 0.2, 0.2, 0.2, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 20, 16, { 0.95, 0.88, 0.76, 1 })
    Utils.drawCrown(cx, cy - 42, 30, 18, { 0.93, 0.76, 0.31, 1 })
    Utils.drawRect(cx - 20, cy - 2, 40, 34, { 0.48, 0.64, 0.37, 0.96 }, 9, 9)
    Utils.drawRect(cx - 3, cy + 4, 6, 30, suit, 4, 4)
    Utils.drawCenteredText("K", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return K
