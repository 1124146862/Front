local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local J = {}

function J.draw(frame, context)
    local suit = context.suit_color or { 0.18, 0.20, 0.18, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 18, 15, { 0.96, 0.88, 0.76, 1 })
    Utils.drawRect(cx - 18, cy - 6, 36, 38, { 0.16, 0.42, 0.34, 0.98 }, 10, 10)
    Utils.drawRect(cx - 13, cy - 1, 8, 20, { 0.91, 0.76, 0.36, 1 }, 4, 4)
    Utils.drawRect(cx - 1, cy - 4, 8, 24, { 0.91, 0.76, 0.36, 1 }, 4, 4)
    Utils.drawCircle(cx + 11, cy + 2, 5, suit)
    Utils.drawCenteredText("J", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return J
