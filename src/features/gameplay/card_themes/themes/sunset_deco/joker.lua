local Utils = require("src.features.gameplay.card_themes.theme_draw_utils")

local Joker = {}

function Joker.draw(frame, context)
    local is_big = context.is_big_joker == true
    local ink = is_big and { 0.73, 0.22, 0.18, 1 } or { 0.18, 0.28, 0.39, 1 }
    local glow = is_big and { 0.98, 0.76, 0.26, 1 } or { 0.37, 0.66, 0.80, 1 }
    Utils.drawFittedVerticalLabel("JOKER", frame.x + 3, frame.y + 6, math.max(14, math.floor(frame.width * 0.18)), frame.height - 12, 20, -3, ink)
    Utils.drawDiamond(frame.x + frame.width * 0.58, frame.y + frame.height * 0.36, 8, glow)
    Utils.drawDiamond(frame.x + frame.width * 0.50, frame.y + frame.height * 0.48, 8, glow)
    Utils.drawDiamond(frame.x + frame.width * 0.66, frame.y + frame.height * 0.48, 8, glow)
    Utils.drawRect(frame.x + frame.width * 0.54, frame.y + frame.height * 0.54, 18, 18, ink, 4, 4)
end

return Joker
