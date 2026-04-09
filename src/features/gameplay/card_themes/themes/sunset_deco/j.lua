local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local J = {}

function J.draw(frame, context)
    local suit = context.suit_color or { 0.24, 0.18, 0.14, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 19, 15, { 0.98, 0.87, 0.72, 1 })
    Utils.drawRect(cx - 18, cy - 5, 36, 38, { 0.20, 0.49, 0.63, 0.98 }, 7, 7)
    Utils.drawDiamond(cx - 10, cy + 2, 5, { 0.98, 0.78, 0.28, 1 })
    Utils.drawDiamond(cx + 10, cy + 2, 5, { 0.98, 0.56, 0.22, 1 })
    Utils.drawCenteredText("J", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return J
