local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Q = {}

function Q.draw(frame, context)
    local suit = context.suit_color or { 0.2, 0.2, 0.2, 1 }
    local cx = frame.x + frame.width * 0.5
    local cy = frame.y + frame.height * 0.58
    Utils.drawCircle(cx, cy - 20, 16, { 0.95, 0.88, 0.76, 1 })
    Utils.drawRect(cx - 20, cy - 2, 40, 34, { 0.75, 0.35, 0.44, 0.96 }, 6, 6)
    Utils.drawDiamond(cx, cy - 8, 6, { 0.98, 0.84, 0.34, 1 })
    Utils.drawDiamond(cx - 10, cy + 6, 4, suit)
    Utils.drawDiamond(cx + 10, cy + 6, 4, suit)
    Utils.drawCenteredText("Q", frame.x, frame.y + frame.height * 0.68, frame.width, 26, 18, suit)
end

return Q
