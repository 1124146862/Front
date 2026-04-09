local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Q = {}

function Q.draw(frame, context)
    local suit = context.suit_color or { 0.24, 0.18, 0.14, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 16, { 0.98, 0.87, 0.74, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.73, 0.28, 0.29, 0.98 }, 7, 7)
    Utils.drawDiamond(cx, cy - 9, 7, { 0.98, 0.78, 0.28, 1 })
    Utils.drawRect(cx - 14, cy + 6, 10, 4, suit, 2, 2)
    Utils.drawRect(cx + 4, cy + 6, 10, 4, suit, 2, 2)
    Utils.drawCenteredText("Q", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return Q
