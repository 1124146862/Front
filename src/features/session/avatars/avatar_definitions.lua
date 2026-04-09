local function clamp(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function tint(color, amount)
    return {
        clamp(color[1] * amount),
        clamp(color[2] * amount),
        clamp(color[3] * amount),
        1,
    }
end

local palettes = {
    { bg = { 0.96, 0.83, 0.78 }, primary = { 0.83, 0.35, 0.29 }, secondary = { 0.99, 0.67, 0.45 }, detail = { 0.36, 0.18, 0.13 } },
    { bg = { 0.98, 0.86, 0.72 }, primary = { 0.82, 0.51, 0.18 }, secondary = { 0.99, 0.79, 0.37 }, detail = { 0.42, 0.23, 0.09 } },
    { bg = { 0.93, 0.9, 0.72 }, primary = { 0.57, 0.64, 0.19 }, secondary = { 0.83, 0.8, 0.36 }, detail = { 0.28, 0.31, 0.1 } },
    { bg = { 0.8, 0.93, 0.77 }, primary = { 0.24, 0.61, 0.34 }, secondary = { 0.56, 0.81, 0.46 }, detail = { 0.11, 0.29, 0.14 } },
    { bg = { 0.76, 0.92, 0.91 }, primary = { 0.18, 0.56, 0.58 }, secondary = { 0.41, 0.79, 0.73 }, detail = { 0.08, 0.24, 0.25 } },
    { bg = { 0.78, 0.88, 0.97 }, primary = { 0.26, 0.48, 0.8 }, secondary = { 0.54, 0.72, 0.95 }, detail = { 0.13, 0.22, 0.43 } },
    { bg = { 0.84, 0.82, 0.97 }, primary = { 0.5, 0.38, 0.82 }, secondary = { 0.75, 0.63, 0.97 }, detail = { 0.24, 0.17, 0.44 } },
    { bg = { 0.97, 0.82, 0.9 }, primary = { 0.84, 0.34, 0.63 }, secondary = { 0.97, 0.63, 0.79 }, detail = { 0.42, 0.14, 0.29 } },
}

local tone_steps = { 1.0, 0.94, 0.88, 0.82 }
local avatars = {}

for index = 1, 32 do
    local palette_index = ((index - 1) % #palettes) + 1
    local tone_index = math.floor((index - 1) / #palettes) + 1
    local tone = tone_steps[tone_index]
    local palette = palettes[palette_index]

    avatars[index] = {
        id = ("avatar_%d"):format(index),
        seed = ((index - 1) % 8) + 1,
        colors = {
            bg = tint(palette.bg, 1.02 - (tone_index - 1) * 0.03),
            primary = tint(palette.primary, tone),
            secondary = tint(palette.secondary, tone + 0.04),
            detail = tint(palette.detail, 1.0),
        },
    }
end

return avatars
