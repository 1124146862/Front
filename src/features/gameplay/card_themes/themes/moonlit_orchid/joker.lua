local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Joker = {}

function Joker.draw(frame, context)
    local is_big = context.is_big_joker == true
    local ink = is_big and { 0.58, 0.22, 0.52, 1 } or { 0.26, 0.28, 0.46, 1 }
    local petal = is_big and { 0.94, 0.72, 0.88, 1 } or { 0.77, 0.82, 0.98, 1 }
    Utils.drawFittedVerticalLabel("JOKER", frame.x + 3, frame.y + 6, math.max(14, math.floor(frame.width * 0.18)), frame.height - 12, 20, -3, ink)
    Utils.drawCircle(frame.x + frame.width * 0.58, frame.y + frame.height * 0.38, 7, petal)
    Utils.drawCircle(frame.x + frame.width * 0.52, frame.y + frame.height * 0.46, 7, petal)
    Utils.drawCircle(frame.x + frame.width * 0.64, frame.y + frame.height * 0.46, 7, petal)
    Utils.drawDiamond(frame.x + frame.width * 0.58, frame.y + frame.height * 0.56, 6, ink)
end

return Joker
