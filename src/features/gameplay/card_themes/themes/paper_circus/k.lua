local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local K = {}

function K.draw(frame, context)
    local suit = context.suit_color or { 0.2, 0.2, 0.2, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 20, 16, { 0.95, 0.88, 0.76, 1 })
    Utils.drawCrown(cx, cy - 42, 30, 18, { 0.96, 0.79, 0.30, 1 })
    Utils.drawRect(cx - 20, cy - 2, 40, 34, { 0.40, 0.30, 0.56, 0.96 }, 6, 6)
    Utils.drawDiamond(cx, cy + 4, 6, suit)
    Utils.drawCenteredText("K", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return K
