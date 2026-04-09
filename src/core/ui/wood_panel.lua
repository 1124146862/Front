local WoodPanel = {}
WoodPanel.__index = WoodPanel

function WoodPanel.new(style)
    local self = setmetatable({}, WoodPanel)
    self.style = assert(style, "WoodPanel requires style")
    return self
end

function WoodPanel:draw(frame, options)
    local colors = self.style.colors or {}
    local panel_shadow = colors.panel_shadow or { 0, 0, 0, 0.22 }
    local panel_fill = colors.panel or { 0.96, 0.89, 0.75, 1 }
    local panel_inner = colors.panel_inner or { 0.98, 0.91, 0.78, 1 }
    local panel_grain = colors.panel_grain or { 0.68, 0.48, 0.28, 0.16 }
    local panel_border = colors.panel_border or { 0.42, 0.24, 0.12, 1 }
    local radius = (options and options.radius) or 20
    local shadow_offset = (options and options.shadow_offset) or 8
    local inset = (options and options.inner_inset) or 10
    local border_width = (options and options.border_width) or 3
    local inner_border_width = (options and options.inner_border_width) or border_width
    local draw_inner_border = options == nil or options.inner_border ~= false

    love.graphics.setColor(panel_shadow)
    love.graphics.rectangle("fill", frame.x, frame.y + shadow_offset, frame.width, frame.height, radius, radius)

    love.graphics.setColor(panel_fill)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, radius, radius)

    love.graphics.setColor(panel_inner)
    love.graphics.rectangle(
        "fill",
        frame.x + inset,
        frame.y + inset,
        frame.width - inset * 2,
        frame.height - inset * 2,
        radius - 4,
        radius - 4
    )

    love.graphics.setColor(panel_grain)
    for index = 0, 7 do
        local grain_y = math.floor(frame.y + 26 + index * ((frame.height - 52) / 7))
        love.graphics.rectangle("fill", frame.x + 18, grain_y, frame.width - 36, 2, 1, 1)
    end

    love.graphics.setLineWidth(border_width)
    love.graphics.setColor(panel_border)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, radius, radius)
    if draw_inner_border then
        love.graphics.setLineWidth(inner_border_width)
        love.graphics.rectangle(
            "line",
            frame.x + inset,
            frame.y + inset,
            frame.width - inset * 2,
            frame.height - inset * 2,
            radius - 4,
            radius - 4
        )
    end
    love.graphics.setLineWidth(1)
end

return WoodPanel
