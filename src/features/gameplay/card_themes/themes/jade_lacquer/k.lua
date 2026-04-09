local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local K = {}

function K.draw(frame, context)
    local suit = context.suit_color or { 0.18, 0.20, 0.18, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 18, 15, { 0.96, 0.88, 0.77, 1 })
    Utils.drawCrown(cx, cy - 42, 30, 18, { 0.92, 0.77, 0.33, 1 })
    Utils.drawRect(cx - 20, cy - 4, 40, 38, { 0.13, 0.28, 0.26, 0.98 }, 10, 10)
    Utils.drawRect(cx - 3, cy + 1, 6, 30, { 0.92, 0.77, 0.33, 1 }, 4, 4)
    Utils.drawCenteredText("K", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return K
