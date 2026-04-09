local avatars = require("registryTest")

local state = {
    page = 1,
    per_page = 8,
    selected = 1,
    hover_index = nil,
    cards = {},
}

local function setColor(color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function totalPages()
    return math.max(1, math.ceil(#avatars / state.per_page))
end

local function goToPage(page)
    state.page = clamp(page, 1, totalPages())
end

local function nextPage()
    goToPage(state.page + 1)
end

local function prevPage()
    goToPage(state.page - 1)
end

local function darken(color, factor)
    return {
        clamp(color[1] * factor, 0, 1),
        clamp(color[2] * factor, 0, 1),
        clamp(color[3] * factor, 0, 1),
    }
end

local function lighten(color, amount)
    return {
        clamp(color[1] + amount, 0, 1),
        clamp(color[2] + amount, 0, 1),
        clamp(color[3] + amount, 0, 1),
    }
end

local function drawGeneratedAvatar(avatar, bounds)
    local colors = avatar.colors or {
        bg = { 0.85, 0.88, 0.93 },
        primary = { 0.35, 0.55, 0.80 },
        secondary = { 0.75, 0.82, 0.92 },
        detail = { 0.12, 0.16, 0.22 },
    }

    local seed = avatar.seed or 1
    local x = bounds.x
    local y = bounds.y
    local w = bounds.w
    local h = bounds.h
    local cx = x + w * 0.5
    local head_r = math.floor(math.min(w, h) * 0.23)
    local head_y = y + h * 0.38
    local body_y = y + h * 0.66

    setColor(colors.bg)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)

    setColor(lighten(colors.bg, 0.05), 0.9)
    love.graphics.circle("fill", cx, head_y, head_r + 8)

    setColor(colors.secondary)
    love.graphics.rectangle("fill", cx - w * 0.18, body_y - h * 0.02, w * 0.36, h * 0.22, 16, 16)

    local skin = { 0.95, 0.84, 0.74 }
    setColor(skin)
    love.graphics.circle("fill", cx, head_y, head_r)

    setColor(colors.primary)
    if seed == 1 then
        love.graphics.arc("fill", "pie", cx, head_y - 2, head_r + 2, math.rad(180), math.rad(360))
    elseif seed == 2 then
        love.graphics.arc("fill", "pie", cx, head_y - 4, head_r + 3, math.rad(160), math.rad(380))
        love.graphics.rectangle("fill", cx - head_r - 2, head_y - 2, head_r * 0.6, head_r * 1.2, 8, 8)
    elseif seed == 3 then
        love.graphics.arc("fill", "pie", cx, head_y - 5, head_r + 4, math.rad(170), math.rad(370))
        love.graphics.rectangle("fill", cx - head_r * 0.9, head_y - head_r * 0.2, head_r * 1.8, head_r * 0.55, 8, 8)
    elseif seed == 4 then
        love.graphics.arc("fill", "pie", cx, head_y - 4, head_r + 3, math.rad(150), math.rad(390))
    elseif seed == 5 then
        love.graphics.arc("fill", "pie", cx, head_y - 5, head_r + 4, math.rad(190), math.rad(350))
        love.graphics.circle("fill", cx - head_r * 0.7, head_y - head_r * 0.6, head_r * 0.28)
        love.graphics.circle("fill", cx + head_r * 0.7, head_y - head_r * 0.6, head_r * 0.28)
    elseif seed == 6 then
        love.graphics.arc("fill", "pie", cx, head_y - 6, head_r + 4, math.rad(180), math.rad(360))
        setColor(colors.secondary)
        love.graphics.rectangle("fill", cx - head_r * 1.1, head_y - head_r * 0.2, head_r * 2.2, head_r * 0.22, 6, 6)
        setColor(colors.primary)
    elseif seed == 7 then
        love.graphics.arc("fill", "pie", cx, head_y - 4, head_r + 3, math.rad(165), math.rad(375))
        love.graphics.polygon("fill",
            cx - head_r * 0.4, head_y - head_r * 0.9,
            cx, head_y - head_r * 1.35,
            cx + head_r * 0.4, head_y - head_r * 0.9
        )
    else
        love.graphics.arc("fill", "pie", cx, head_y - 4, head_r + 3, math.rad(175), math.rad(365))
        setColor(colors.detail)
        love.graphics.circle("fill", cx - head_r * 0.55, head_y - head_r * 0.2, head_r * 0.12)
        love.graphics.circle("fill", cx + head_r * 0.55, head_y - head_r * 0.2, head_r * 0.12)
        setColor(colors.primary)
    end

    setColor(colors.detail)
    local eye_y = head_y + head_r * 0.05
    love.graphics.circle("fill", cx - head_r * 0.42, eye_y, math.max(2, head_r * 0.08))
    love.graphics.circle("fill", cx + head_r * 0.42, eye_y, math.max(2, head_r * 0.08))
    love.graphics.arc("line", "open", cx, head_y + head_r * 0.33, head_r * 0.32, math.rad(15), math.rad(165))

    setColor(darken(colors.secondary, 0.92))
    if seed % 2 == 0 then
        love.graphics.rectangle("fill", cx - w * 0.09, body_y + h * 0.02, w * 0.18, h * 0.1, 12, 12)
    else
        love.graphics.arc("fill", "pie", cx, body_y + h * 0.06, w * 0.11, math.rad(180), math.rad(360))
    end

    if seed == 3 or seed == 6 then
        setColor(colors.detail)
        love.graphics.circle("line", cx - head_r * 0.45, eye_y, head_r * 0.24)
        love.graphics.circle("line", cx + head_r * 0.45, eye_y, head_r * 0.24)
        love.graphics.line(cx - head_r * 0.21, eye_y, cx + head_r * 0.21, eye_y)
    end

    setColor(darken(colors.bg, 0.78), 0.22)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
end

local function drawAvatar(avatar, bounds)
    if type(avatar.draw) == "function" then
        avatar.draw(bounds)
        return
    end
    drawGeneratedAvatar(avatar, bounds)
end

local function updateCards()
    state.cards = {}

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local margin_x = 48
    local top_y = 110
    local bottom_space = 96
    local gap_x = 22
    local gap_y = 22
    local cols = 4
    local rows = 2

    local grid_w = width - margin_x * 2
    local grid_h = height - top_y - bottom_space
    local card_w = math.floor((grid_w - gap_x * (cols - 1)) / cols)
    local card_h = math.floor((grid_h - gap_y * (rows - 1)) / rows)

    local start_index = (state.page - 1) * state.per_page + 1

    for offset = 0, state.per_page - 1 do
        local index = start_index + offset
        local avatar = avatars[index]
        if avatar then
            local col = offset % cols
            local row = math.floor(offset / cols)
            local x = margin_x + col * (card_w + gap_x)
            local y = top_y + row * (card_h + gap_y)
            state.cards[#state.cards + 1] = {
                index = index,
                avatar = avatar,
                x = x,
                y = y,
                w = card_w,
                h = card_h,
            }
        end
    end
end

function love.load()
    love.window.setTitle("Avatar Visual Test")
    love.window.setMode(1280, 820, {
        resizable = true,
        minwidth = 960,
        minheight = 680,
    })
    updateCards()
end

function love.resize()
    updateCards()
end

function love.update()
end

function love.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    love.graphics.clear(0.96, 0.97, 0.99, 1)

    love.graphics.setColor(0.12, 0.16, 0.22, 1)
    love.graphics.setNewFont(28)
    love.graphics.print("Avatar 可视化测试", 48, 28)

    love.graphics.setColor(0.38, 0.44, 0.52, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("左右方向键 / A D 翻页，鼠标点击卡片选中", 48, 66)

    for _, card in ipairs(state.cards) do
        local is_selected = state.selected == card.index
        local is_hover = state.hover_index == card.index

        if is_selected then
            love.graphics.setColor(0.22, 0.52, 0.95, 0.16)
        elseif is_hover then
            love.graphics.setColor(0.22, 0.52, 0.95, 0.08)
        else
            love.graphics.setColor(1, 1, 1, 0.92)
        end
        love.graphics.rectangle("fill", card.x, card.y, card.w, card.h, 18, 18)

        if is_selected then
            love.graphics.setColor(0.22, 0.52, 0.95, 1)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.84, 0.87, 0.92, 1)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", card.x, card.y, card.w, card.h, 18, 18)

        local avatar_bounds = {
            x = card.x + 22,
            y = card.y + 18,
            w = card.w - 44,
            h = card.h - 78,
        }
        drawAvatar(card.avatar, avatar_bounds)

        love.graphics.setColor(0.14, 0.17, 0.24, 1)
        love.graphics.setNewFont(15)
        love.graphics.printf(card.avatar.id or ("avatar_" .. card.index), card.x + 10, card.y + card.h - 48, card.w - 20, "center")

        love.graphics.setColor(0.45, 0.50, 0.58, 1)
        love.graphics.setNewFont(13)
        love.graphics.printf("#" .. tostring(card.index), card.x + 10, card.y + card.h - 26, card.w - 20, "center")
    end

    local footer_y = height - 54
    love.graphics.setColor(0.12, 0.16, 0.22, 1)
    love.graphics.setNewFont(16)
    love.graphics.print(("第 %d / %d 页"):format(state.page, totalPages()), 48, footer_y)
    love.graphics.print(("总数: %d"):format(#avatars), 160, footer_y)

    local selected = avatars[state.selected]
    if selected then
        love.graphics.printf("当前选中: " .. (selected.id or ("avatar_" .. state.selected)), width - 320, footer_y, 272, "right")
    end
end

function love.mousemoved(x, y)
    state.hover_index = nil
    for _, card in ipairs(state.cards) do
        if pointInRect(x, y, card) then
            state.hover_index = card.index
            return
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    for _, card in ipairs(state.cards) do
        if pointInRect(x, y, card) then
            state.selected = card.index
            return
        end
    end
end

function love.wheelmoved(_, y)
    if y > 0 then
        prevPage()
        updateCards()
    elseif y < 0 then
        nextPage()
        updateCards()
    end
end

function love.keypressed(key)
    if key == "right" or key == "d" then
        nextPage()
        updateCards()
    elseif key == "left" or key == "a" then
        prevPage()
        updateCards()
    elseif key == "escape" then
        love.event.quit()
    end
end
