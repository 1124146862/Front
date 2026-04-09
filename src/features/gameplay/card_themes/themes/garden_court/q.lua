local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Q = {}

function Q.draw(frame, context)
    local suit = context.suit_color or { 0.2, 0.2, 0.2, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 20, 16, { 0.95, 0.88, 0.76, 1 })
    Utils.drawRect(cx - 20, cy - 2, 40, 34, { 0.78, 0.49, 0.66, 0.96 }, 9, 9)
    Utils.drawDiamond(cx, cy - 10, 7, suit)
    Utils.drawCircle(cx - 10, cy + 2, 4, { 0.97, 0.88, 0.42, 1 })
    Utils.drawCircle(cx + 10, cy + 2, 4, { 0.97, 0.88, 0.42, 1 })
    Utils.drawCenteredText("Q", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return Q
