local LobbyHallBackground = {}

local function drawSoftGlow(x, y, radius, color, layers)
    for index = 1, layers do
        local alpha = (color[4] or 1) * (1 - (index - 1) / layers) * 0.9
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, radius * (0.45 + index * 0.22))
    end
end

function LobbyHallBackground.draw(width, height)
    love.graphics.clear(0.07, 0.10, 0.14, 1)

    love.graphics.setColor(0.09, 0.12, 0.17, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(0.12, 0.16, 0.22, 0.96)
    love.graphics.rectangle("fill", 0, 0, width, math.floor(height * 0.34))

    love.graphics.setColor(0.06, 0.09, 0.13, 0.96)
    love.graphics.rectangle("fill", 0, math.floor(height * 0.74), width, height - math.floor(height * 0.74))

    drawSoftGlow(width * 0.5, height * 0.12, math.min(width, height) * 0.12, { 0.38, 0.56, 0.82, 0.045 }, 5)
    drawSoftGlow(width * 0.22, height * 0.30, math.min(width, height) * 0.09, { 0.24, 0.38, 0.58, 0.025 }, 4)
    drawSoftGlow(width * 0.78, height * 0.30, math.min(width, height) * 0.09, { 0.24, 0.38, 0.58, 0.025 }, 4)

    local line_color = { 1, 1, 1, 0.035 }
    for _, ratio in ipairs({ 0.18, 0.46, 0.74 }) do
        local y = math.floor(height * ratio)
        love.graphics.setColor(line_color)
        love.graphics.rectangle("fill", 36, y, width - 72, 2)
    end

    local vignette_alpha = 0.12
    love.graphics.setColor(0.02, 0.03, 0.05, vignette_alpha)
    love.graphics.rectangle("fill", 0, 0, width, 28)
    love.graphics.rectangle("fill", 0, height - 36, width, 36)
    love.graphics.rectangle("fill", 0, 0, 28, height)
    love.graphics.rectangle("fill", width - 28, 0, 28, height)
end

return LobbyHallBackground
