local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Joker = {}

function Joker.draw(frame, context)
    local is_big = context.is_big_joker == true
    local ink = is_big and { 0.60, 0.12, 0.16, 1 } or { 0.14, 0.23, 0.21, 1 }
    local accent = is_big and { 0.93, 0.76, 0.33, 1 } or { 0.33, 0.63, 0.55, 1 }
    Utils.drawFittedVerticalLabel("JOKER", frame.x + 3, frame.y + 6, math.max(14, math.floor(frame.width * 0.18)), frame.height - 12, 20, -3, ink)
    Utils.drawRect(frame.x + frame.width * 0.48, frame.y + frame.height * 0.33, 24, 44, accent, 8, 8)
    Utils.drawCircle(frame.x + frame.width * 0.60, frame.y + frame.height * 0.30, 7, accent)
    Utils.drawDiamond(frame.x + frame.width * 0.60, frame.y + frame.height * 0.47, 6, ink)
    Utils.drawCircle(frame.x + frame.width * 0.60, frame.y + frame.height * 0.63, 5, ink)
end

return Joker
