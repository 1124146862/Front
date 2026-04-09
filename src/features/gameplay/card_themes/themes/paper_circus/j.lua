local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local J = {}

function J.draw(frame, context)
    local suit = context.suit_color or { 0.2, 0.2, 0.2, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 18, 15, { 0.95, 0.87, 0.76, 1 })
    Utils.drawRect(cx - 18, cy - 4, 36, 34, { 0.32, 0.56, 0.78, 0.96 }, 6, 6)
    Utils.drawDiamond(cx - 10, cy + 2, 4, suit)
    Utils.drawDiamond(cx + 10, cy + 2, 4, suit)
    Utils.drawCenteredText("J", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return J
