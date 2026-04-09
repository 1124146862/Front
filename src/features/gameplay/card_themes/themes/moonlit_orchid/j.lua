local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local J = {}

function J.draw(frame, context)
    local suit = context.suit_color or { 0.23, 0.20, 0.34, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 18, 15, { 0.95, 0.90, 0.98, 1 })
    Utils.drawRect(cx - 18, cy - 5, 36, 38, { 0.48, 0.40, 0.73, 0.98 }, 10, 10)
    Utils.drawCircle(cx - 10, cy + 2, 5, { 0.90, 0.70, 0.92, 1 })
    Utils.drawCircle(cx + 10, cy + 2, 5, { 0.69, 0.81, 0.94, 1 })
    Utils.drawCenteredText("J", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return J
