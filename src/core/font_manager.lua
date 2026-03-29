local FontManager = {}
FontManager.__index = FontManager

FontManager.tokens = {
    Title1 = 96,
    Title2 = 52,
    Title3 = 38,
    TextBig = 28,
    Text = 24,
    TextSmall = 20,
    Button = 30,
    Caption = 18,
    Label = 16,
}

local function loadFont(path, size)
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok then
        return font
    end

    return love.graphics.newFont(size)
end

function FontManager.new(options)
    local self = setmetatable({}, FontManager)

    self.font_path = (options and options.font_path) or "assets/fonts/zh.otf"
    self.cache = {}

    return self
end

function FontManager:get(token)
    local key = token
    local size = token

    if type(token) == "string" then
        size = self.tokens[token]
    end

    if type(size) ~= "number" then
        error("Unknown font token: " .. tostring(token))
    end

    if not self.cache[key] then
        self.cache[key] = loadFont(self.font_path, size)
    end

    return self.cache[key]
end

function FontManager:getSize(token)
    return self.tokens[token]
end

function FontManager:listTokens()
    return self.tokens
end

return FontManager
