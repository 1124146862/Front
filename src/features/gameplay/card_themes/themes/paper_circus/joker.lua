local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Joker = {}

function Joker.draw(frame, context)
    local is_big = context.is_big_joker == true
    local main = is_big and { 0.86, 0.22, 0.22, 1 } or { 0.20, 0.22, 0.26, 1 }
    local accent = is_big and { 0.97, 0.82, 0.32, 1 } or { 0.60, 0.72, 0.92, 1 }
    Utils.drawFittedVerticalLabel("JOKER", frame.x + 3, frame.y + 6, math.max(14, math.floor(frame.width * 0.18)), frame.height - 12, 20, -3, main)
    Utils.drawDiamond(frame.x + frame.width * 0.62, frame.y + frame.height * 0.38, 9, accent)
    Utils.drawDiamond(frame.x + frame.width * 0.55, frame.y + frame.height * 0.50, 7, main)
    Utils.drawDiamond(frame.x + frame.width * 0.69, frame.y + frame.height * 0.52, 7, accent)
end

return Joker
