local ButtonText = {}

function ButtonText.draw(font, text, x, y, width, align, color, options)
    options = options or {}
    local bold = options.bold ~= false
    local bold_offset = tonumber(options.bold_offset) or 1
    local shadow_color = options.shadow_color

    love.graphics.setFont(font)

    if shadow_color then
        love.graphics.setColor(shadow_color[1], shadow_color[2], shadow_color[3], shadow_color[4] or 1)
        love.graphics.printf(text, x + bold_offset, y + bold_offset, width, align)
    end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    if bold then
        local offsets = {
            { bold_offset, 0 },
            { 0, bold_offset },
        }
        for _, offset in ipairs(offsets) do
            love.graphics.printf(text, x + offset[1], y + offset[2], width, align)
        end
    end

    love.graphics.printf(text, x, y, width, align)
end

return ButtonText
