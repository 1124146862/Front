local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Q = {}

function Q.draw(frame, context)
    local suit = context.suit_color or { 0.18, 0.20, 0.18, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 16, { 0.96, 0.88, 0.78, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.60, 0.16, 0.18, 0.98 }, 10, 10)
    Utils.drawDiamond(cx, cy - 9, 7, { 0.92, 0.76, 0.34, 1 })
    Utils.drawCircle(cx - 11, cy + 4, 4, suit)
    Utils.drawCircle(cx + 11, cy + 4, 4, suit)
    Utils.drawCenteredText("Q", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return Q
