local HandCardAnimator = {}
HandCardAnimator.__index = HandCardAnimator

function HandCardAnimator.new()
    return setmetatable({}, HandCardAnimator)
end

local function stepTowards(current_value, target_value, dt, speed)
    local smoothing = math.min(1, dt * speed)
    return current_value + (target_value - current_value) * smoothing
end

function HandCardAnimator:update(position, target, dt)
    return {
        x = stepTowards(position.x, target.x, dt, 14),
        y = stepTowards(position.y, target.y, dt, 18),
    }
end

return HandCardAnimator
