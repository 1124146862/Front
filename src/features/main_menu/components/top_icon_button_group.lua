local TopIconButtonGroup = {}
TopIconButtonGroup.__index = TopIconButtonGroup

function TopIconButtonGroup.new(options)
    local self = setmetatable({}, TopIconButtonGroup)
    self.style = assert(options and options.style, "TopIconButtonGroup requires style")
    return self
end

local function contains(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height
end

function TopIconButtonGroup:getFrames(window_width, _profile_bounds)
    local layout = self.style.layout
    local size = layout.button_size
    local gap = layout.group_gap

    local group_w = size * 2 + gap
    local group_x = window_width - (layout.right_margin or 22) - group_w
    if group_x < 12 then
        group_x = 12
    end

    local y = layout.top_margin or 18

    return {
        mute = {
            x = group_x,
            y = y,
            width = size,
            height = size,
        },
        settings = {
            x = group_x + size + gap,
            y = y,
            width = size,
            height = size,
        },
    }
end

function TopIconButtonGroup:hitTest(window_width, _profile_bounds, x, y)
    local frames = self:getFrames(window_width, _profile_bounds)
    if contains(frames.mute, x, y) then
        return "mute"
    end
    if contains(frames.settings, x, y) then
        return "settings"
    end
    return nil
end

return TopIconButtonGroup
