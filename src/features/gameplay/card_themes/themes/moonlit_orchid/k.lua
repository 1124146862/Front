local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local K = {}

function K.draw(frame, context)
    local suit = context.suit_color or { 0.23, 0.20, 0.34, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 16, { 0.95, 0.90, 0.98, 1 })
    Utils.drawCrown(cx, cy - 43, 30, 18, { 0.77, 0.71, 0.95, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.30, 0.29, 0.46, 0.98 }, 10, 10)
    Utils.drawRect(cx - 3, cy, 6, 30, { 0.86, 0.78, 0.97, 1 }, 4, 4)
    Utils.drawCenteredText("K", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return K
