local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Q = {}

function Q.draw(frame, context)
    local suit = context.suit_color or { 0.23, 0.20, 0.34, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 16, { 0.95, 0.90, 0.98, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.74, 0.47, 0.70, 0.98 }, 10, 10)
    Utils.drawDiamond(cx, cy - 9, 7, { 0.88, 0.77, 0.98, 1 })
    Utils.drawCircle(cx - 10, cy + 4, 4, { 0.72, 0.83, 0.95, 1 })
    Utils.drawCircle(cx + 10, cy + 4, 4, { 0.72, 0.83, 0.95, 1 })
    Utils.drawCenteredText("Q", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return Q
