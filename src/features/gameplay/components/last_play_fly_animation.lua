local CardView = require("src.features.gameplay.components.card_view")

local LastPlayFlyAnimation = {}
LastPlayFlyAnimation.__index = LastPlayFlyAnimation

local function clamp(value, lower, upper)
    if value < lower then
        return lower
    end
    if value > upper then
        return upper
    end
    return value
end

local function lerp(from_value, to_value, t)
    return from_value + (to_value - from_value) * t
end

local function easeOutCubic(t)
    local one_minus_t = 1 - t
    return 1 - one_minus_t * one_minus_t * one_minus_t
end

function LastPlayFlyAnimation.new(options)
    local self = setmetatable({}, LastPlayFlyAnimation)
    self.fonts = assert(options and options.fonts, "LastPlayFlyAnimation requires fonts")
    self.card_view = CardView.new()
    self.entries = {}
    self.active = false
    self.elapsed = 0
    self.duration = 0.22
    self.stagger = 0.028
    self.display_state = {}
    return self
end

function LastPlayFlyAnimation:isActive()
    return self.active == true
end

function LastPlayFlyAnimation:reset()
    self.entries = {}
    self.active = false
    self.elapsed = 0
end

function LastPlayFlyAnimation:start(options)
    local target_frames = (options and options.target_frames) or {}
    local origin = (options and options.origin) or {}
    local origin_x = tonumber(origin.x) or 0
    local origin_y = tonumber(origin.y) or 0
    local start_width = tonumber(options and options.start_width) or 44
    local start_height = tonumber(options and options.start_height) or 62

    if #target_frames == 0 then
        self:reset()
        return
    end

    self.entries = {}
    self.elapsed = 0
    self.duration = tonumber(options and options.duration) or 0.22
    self.stagger = tonumber(options and options.stagger) or 0.028
    self.display_state = (options and options.display_state) or {}

    local center_bias = (#target_frames + 1) / 2
    for index, target in ipairs(target_frames) do
        local offset = (index - center_bias) * 10
        self.entries[#self.entries + 1] = {
            card_id = target.card_id,
            start_x = origin_x + offset - start_width * 0.5,
            start_y = origin_y + ((index % 2 == 0) and 4 or -4) - start_height * 0.5,
            start_width = start_width,
            start_height = start_height,
            target_x = target.x,
            target_y = target.y,
            target_width = target.width,
            target_height = target.height,
            delay = (index - 1) * self.stagger,
        }
    end

    self.active = true
end

function LastPlayFlyAnimation:update(dt)
    if not self.active then
        return
    end
    self.elapsed = self.elapsed + dt

    local total_duration = self.duration + math.max(0, (#self.entries - 1) * self.stagger) + 0.08
    if self.elapsed >= total_duration then
        self.active = false
    end
end

function LastPlayFlyAnimation:draw(theme_config)
    if not self.active then
        return
    end

    for _, entry in ipairs(self.entries) do
        local t = clamp((self.elapsed - entry.delay) / self.duration, 0, 1)
        if t > 0 then
            local eased = easeOutCubic(t)
            local width = lerp(entry.start_width, entry.target_width, eased)
            local height = lerp(entry.start_height, entry.target_height, eased)
            local x = lerp(entry.start_x, entry.target_x, eased)
            local y = lerp(entry.start_y, entry.target_y, eased)

            -- Small arc to simulate "flying from seat".
            y = y - math.sin(t * math.pi) * 14

            self.card_view:draw(
                entry.card_id,
                {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                },
                theme_config,
                {
                    selected = false,
                    hovered = false,
                    relation = "neutral",
                },
                self.fonts
            )
        end
    end
end

return LastPlayFlyAnimation
