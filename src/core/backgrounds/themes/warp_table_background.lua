local Base = require("src.core.backgrounds.themes.space_placeholder_background")

local WarpTableBackground = {}
for key, value in pairs(Base) do
    WarpTableBackground[key] = value
end

WarpTableBackground.displayName = "星际旅行"
WarpTableBackground.baseColor = { 5 / 255, 9 / 255, 18 / 255 }
WarpTableBackground.midColor = { 13 / 255, 21 / 255, 40 / 255 }
WarpTableBackground.topColor = { 26 / 255, 44 / 255, 70 / 255 }
WarpTableBackground.starCool = { 210 / 255, 224 / 255, 255 / 255 }
WarpTableBackground.starWarm = { 255 / 255, 244 / 255, 220 / 255 }
WarpTableBackground.dustColor = { 66 / 255, 168 / 255, 255 / 255 }
WarpTableBackground.accentDust = { 255 / 255, 112 / 255, 196 / 255 }
WarpTableBackground.accentGlow1 = { 72 / 255, 180 / 255, 255 / 255 }
WarpTableBackground.accentGlow2 = { 255 / 255, 116 / 255, 204 / 255 }

return WarpTableBackground
