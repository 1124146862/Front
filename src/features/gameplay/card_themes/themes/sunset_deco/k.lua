local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local K = {}

function K.draw(frame, context)
    local suit = context.suit_color or { 0.24, 0.18, 0.14, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 16, { 0.98, 0.87, 0.74, 1 })
    Utils.drawCrown(cx, cy - 43, 31, 18, { 0.98, 0.77, 0.27, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.31, 0.26, 0.48, 0.98 }, 7, 7)
    Utils.drawRect(cx - 3, cy - 1, 6, 30, { 0.98, 0.60, 0.21, 1 }, 3, 3)
    Utils.drawCenteredText("K", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return K
