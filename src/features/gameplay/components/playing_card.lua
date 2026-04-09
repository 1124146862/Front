local PlayingCard = {}
PlayingCard.__index = PlayingCard

function PlayingCard.new(options)
    local self = setmetatable({}, PlayingCard)

    self.card_id = assert(options and options.card_id, "PlayingCard requires card_id")
    self.card_view = assert(options and options.card_view, "PlayingCard requires card_view")
    self.animator = assert(options and options.animator, "PlayingCard requires animator")
    self.fonts = assert(options and options.fonts, "PlayingCard requires fonts")
    self.theme_config = options.theme_config or {}
    self.width = options.width or 92
    self.height = options.height or 128
    self.position = {
        x = options.x or 0,
        y = options.y or 0,
    }
    self.target = {
        x = options.x or 0,
        y = options.y or 0,
    }
    self.display_state = {
        selected = false,
        hovered = false,
    }

    return self
end

function PlayingCard:updateTarget(anchor, options)
    local selected = options and options.selected == true
    local hovered = options and options.hovered == true

    self.width = anchor.width or self.width
    self.height = anchor.height or self.height
    self.target.x = anchor.x
    self.target.y = anchor.y - (selected and 12 or 0)
    self.display_state.selected = selected
    self.display_state.hovered = hovered
    self.theme_config = (options and options.theme_config) or self.theme_config
end

function PlayingCard:update(dt)
    self.position = self.animator:update(self.position, self.target, dt)
end

function PlayingCard:containsPoint(x, y)
    return x >= self.position.x
        and x <= self.position.x + self.width
        and y >= self.position.y
        and y <= self.position.y + self.height
end

function PlayingCard:draw()
    self.card_view:draw(
        self.card_id,
        {
            x = self.position.x,
            y = self.position.y,
            width = self.width,
            height = self.height,
        },
        self.theme_config,
        self.display_state,
        self.fonts
    )
end

return PlayingCard
