local source_base = love and love.filesystem and love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or "."
source_base = (source_base:gsub("\\", "/"))

local path_entries = {}
for _, suffix in ipairs({
    "",
    "/..",
    "/../..",
    "/../../..",
    "/../../../..",
}) do
    path_entries[#path_entries + 1] = source_base .. suffix .. "/?.lua"
    path_entries[#path_entries + 1] = source_base .. suffix .. "/?/init.lua"
end

package.path = package.path .. ";" .. table.concat(path_entries, ";")

local CardThemeManager = require("card_theme_manager")
local SteamIDTest = require("steam_id_test")

local PREVIEW_THEMES = {
    {
        id = "jade_lacquer",
        name = "Jade Lacquer",
        accent = { 0.26, 0.61, 0.50, 1 },
        suit_color = { 0.18, 0.20, 0.18, 1 },
    },
    {
        id = "garden_court",
        name = "Garden Court",
        accent = { 0.35, 0.64, 0.44, 1 },
        suit_color = { 0.19, 0.28, 0.20, 1 },
    },
    {
        id = "paper_circus",
        name = "Paper Circus",
        accent = { 0.80, 0.48, 0.24, 1 },
        suit_color = { 0.25, 0.20, 0.16, 1 },
    },
    {
        id = "sunset_deco",
        name = "Sunset Deco",
        accent = { 0.92, 0.55, 0.22, 1 },
        suit_color = { 0.27, 0.18, 0.14, 1 },
    },
    {
        id = "moonlit_orchid",
        name = "Moonlit Orchid",
        accent = { 0.67, 0.56, 0.92, 1 },
        suit_color = { 0.24, 0.21, 0.33, 1 },
    },
}

local CARD_SPECS = {
    { kind = "face", rank = "J", label = "J" },
    { kind = "face", rank = "Q", label = "Q" },
    { kind = "face", rank = "K", label = "K" },
    { kind = "joker", big = false, label = "Joker / Small" },
    { kind = "joker", big = true, label = "Joker / Big" },
}

local manager = CardThemeManager.new()
local steam_test = SteamIDTest.new()
local current_mode = "preview"
local title_font
local header_font
local label_font

local function rgb(color, alpha)
    return color[1], color[2], color[3], alpha or color[4] or 1
end

local function drawRoundedPanel(x, y, w, h, fill, line)
    love.graphics.setColor(rgb(fill))
    love.graphics.rectangle("fill", x, y, w, h, 20, 20)
    love.graphics.setColor(rgb(line))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 20, 20)
end

local function drawCardShell(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", x + 6, y + 8, w, h, 18, 18)
    love.graphics.setColor(0.97, 0.96, 0.94, 1)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(0.80, 0.77, 0.72, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
end

local function drawCardContent(theme, spec, x, y, w, h)
    local frame = {
        x = x + 8,
        y = y + 8,
        width = w - 16,
        height = h - 16,
    }
    local context = {
        suit_color = theme.suit_color,
        is_big_joker = spec.kind == "joker" and spec.big == true,
    }

    if spec.kind == "joker" then
        manager:drawJoker(theme.id, frame, context)
    else
        manager:drawFace(theme.id, spec.rank, frame, context)
    end
end

local function drawTopBar(w)
    local margin = 28
    drawRoundedPanel(margin, 20, w - margin * 2, 92, { 0.11, 0.12, 0.15, 0.78 }, { 0.30, 0.34, 0.40, 0.90 })
    love.graphics.setFont(title_font)
    love.graphics.setColor(0.98, 0.98, 0.96, 1)
    love.graphics.print("Card Theme Preview", 52, 36)

    love.graphics.setFont(header_font)
    love.graphics.setColor(0.82, 0.86, 0.90, 1)
    love.graphics.print("J / Q / K / Joker", 54, 72)

    love.graphics.setFont(label_font)
    love.graphics.setColor(0.75, 0.80, 0.86, 1)
    love.graphics.print("Standalone preview entry for the current theme modules", 54, 98)
end

function love.load()
    love.window.setTitle("Card Theme Preview")
    love.window.setMode(1480, 980, {
        resizable = true,
        minwidth = 1100,
        minheight = 760,
    })

    title_font = love.graphics.newFont(30)
    header_font = love.graphics.newFont(18)
    label_font = love.graphics.newFont(14)
    steam_test:load()
end

function love.keypressed(key)
    if key == "f3" then
        current_mode = current_mode == "preview" and "steam_test" or "preview"
        return
    end

    if current_mode == "steam_test" then
        steam_test:keypressed(key)
        return
    end

    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    if current_mode == "steam_test" then
        steam_test:draw()
        return
    end

    local w, h = love.graphics.getDimensions()

    love.graphics.setBackgroundColor(0.07, 0.08, 0.10, 1)
    love.graphics.setColor(0.11, 0.14, 0.18, 0.95)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(0.15, 0.18, 0.23, 0.55)
    love.graphics.rectangle("fill", 0, h * 0.56, w, h * 0.44)

    drawTopBar(w)

    local rows = #PREVIEW_THEMES
    local cols = #CARD_SPECS
    local left = 38
    local right = 38
    local top = 140
    local bottom = 34
    local gap_x = 18
    local gap_y = 26

    local card_w = math.floor((w - left - right - gap_x * (cols - 1)) / cols)
    local row_h = math.floor((h - top - bottom - gap_y * (rows - 1)) / rows)
    local card_h = math.min(240, math.floor(row_h * 0.82))
    local row_offset = math.floor((row_h - card_h) * 0.5)

    for row_index, theme in ipairs(PREVIEW_THEMES) do
        local y = top + (row_index - 1) * (row_h + gap_y)
        local panel_y = y + 4
        local panel_h = row_h - 8

        drawRoundedPanel(left, panel_y, w - left - right, panel_h, { 0.09, 0.10, 0.12, 0.50 }, { theme.accent[1], theme.accent[2], theme.accent[3], 0.55 })

        love.graphics.setFont(header_font)
        love.graphics.setColor(theme.accent[1], theme.accent[2], theme.accent[3], 1)
        love.graphics.print(theme.name, left + 20, panel_y + 10)

        love.graphics.setFont(label_font)
        love.graphics.setColor(0.74, 0.78, 0.83, 1)
        love.graphics.print(theme.id, left + 20, panel_y + 34)

        for col_index, spec in ipairs(CARD_SPECS) do
            local x = left + (col_index - 1) * (card_w + gap_x)
            local card_y = y + row_offset

            drawCardShell(x, card_y, card_w, card_h)
            drawCardContent(theme, spec, x, card_y, card_w, card_h)

            love.graphics.setFont(label_font)
            love.graphics.setColor(0.18, 0.20, 0.24, 1)
            love.graphics.printf(spec.label, x, card_y + card_h + 8, card_w, "center")
        end
    end

    love.graphics.setFont(label_font)
    love.graphics.setColor(0.70, 0.74, 0.78, 1)
    love.graphics.print("Press F3 for SteamID test, ESC to quit", 40, h - 24)
end

function love.update(dt)
    if current_mode == "steam_test" then
        steam_test:update(dt)
    end
end

function love.resize(width, height)
    if current_mode == "steam_test" then
        steam_test:resize(width, height)
    end
end
