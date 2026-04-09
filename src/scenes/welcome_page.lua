local WelcomePage = {}
WelcomePage.__index = WelcomePage

local I18n = require("src.core.i18n.i18n")
local IconCloseButton = require("src.core.ui.icon_close_button")
local MuteButton = require("src.core.ui.mute_button")
local Style = require("src.features.main_menu.style")
local IconButtonsStyle = require("src.features.main_menu.icon_buttons_style")
local WoodPanel = require("src.core.ui.wood_panel")
local WoodButton = require("src.core.ui.wood_button")
local ButtonText = require("src.core.ui.button_text")
local LoadingOverlay = require("src.core.ui.loading_overlay")
local PRESS_FEEDBACK_DURATION = 0.10

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function sumValues(values)
    local total = 0
    for _, value in ipairs(values) do
        total = total + value
    end
    return total
end

local function getAnimTime()
    if love.timer and love.timer.getTime then
        return love.timer.getTime()
    end
    return 0
end

local function pointInRect(x, y, rect)
    local w = rect.w or rect.width
    local h = rect.h or rect.height
    return x >= rect.x
        and x <= rect.x + w
        and y >= rect.y
        and y <= rect.y + h
end

local function drawRect(color, x, y, w, h, r)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, w, h, r or 0, r or 0)
end

local function fillRect(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function drawPixel(base_x, base_y, size, gx, gy, color)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", base_x + gx * size, base_y + gy * size, size, size)
end

local function drawPixelCells(base_x, base_y, size, cells, color)
    for _, cell in ipairs(cells) do
        drawPixel(base_x, base_y, size, cell[1], cell[2], color)
    end
end

local function drawDarkPixelIconFrame(frame, hovered, pressed)
    local bg = { 0.08, 0.08, 0.08, 0.86 }
    local border = { 1, 1, 1, 0.18 }

    if hovered then
        bg = { 0.14, 0.14, 0.14, 0.94 }
        border = { 1, 1, 1, 0.28 }
    end

    if pressed then
        bg = { 0.05, 0.05, 0.05, 0.98 }
    end

    love.graphics.setColor(0, 0, 0, 0.22)
    fillRect(frame.x + 2, frame.y + 2, frame.width, frame.height)

    love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
    fillRect(frame.x, frame.y, frame.width, frame.height)

    love.graphics.setColor(border[1], border[2], border[3], border[4])
    love.graphics.rectangle("line", frame.x, frame.y, frame.width, frame.height)
end

local function drawPrimaryActionButton(bounds, hovered, pressed, label, fonts)
    local colors = Style.colors
    local radius = 18
    local outer_inset = 8
    local inner_inset = 15
    local shadow_y = pressed and 4 or 8
    local glow_alpha = hovered and 0.18 or 0.08
    local glow_pad = hovered and 14 or 8

    local frame = { 0.56, 0.29, 0.12, 1 }
    local frame_dark = { 0.38, 0.18, 0.07, 1 }
    local face = { 0.90, 0.60, 0.24, 1 }
    local face_hover = { 0.96, 0.68, 0.28, 1 }
    local face_pressed = { 0.82, 0.50, 0.18, 1 }
    local plaque = { 0.98, 0.90, 0.72, 1 }
    local plaque_glow = { 1.00, 0.97, 0.84, hovered and 0.34 or 0.22 }
    local edge = { 0.30, 0.14, 0.05, 0.96 }
    local grain = { 0.66, 0.39, 0.16, 0.22 }
    local text = { 0.47, 0.20, 0.08, 1 }
    local text_shadow = { 0.98, 0.91, 0.76, 0.72 }

    local current_face = face
    if pressed then
        current_face = face_pressed
    elseif hovered then
        current_face = face_hover
    end

    local plaque_x = bounds.x + inner_inset
    local plaque_y = bounds.y + inner_inset - (pressed and 0 or 1)
    local plaque_w = bounds.w - inner_inset * 2
    local plaque_h = bounds.h - inner_inset * 2

    love.graphics.setColor(1.0, 0.83, 0.47, glow_alpha)
    love.graphics.rectangle(
        "fill",
        bounds.x - glow_pad,
        bounds.y - glow_pad * 0.45,
        bounds.w + glow_pad * 2,
        bounds.h + glow_pad * 1.4,
        radius + 8,
        radius + 8
    )

    love.graphics.setColor(colors.panel_shadow[1], colors.panel_shadow[2], colors.panel_shadow[3], 0.42)
    love.graphics.rectangle("fill", bounds.x + 2, bounds.y + shadow_y, bounds.w, bounds.h, radius + 2, radius + 2)

    love.graphics.setColor(frame_dark)
    love.graphics.rectangle("fill", bounds.x, bounds.y + 2, bounds.w, bounds.h, radius + 2, radius + 2)

    love.graphics.setColor(frame)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h, radius, radius)

    love.graphics.setColor(current_face)
    love.graphics.rectangle(
        "fill",
        bounds.x + outer_inset,
        bounds.y + outer_inset,
        bounds.w - outer_inset * 2,
        bounds.h - outer_inset * 2,
        radius - 6,
        radius - 6
    )

    love.graphics.setColor(plaque)
    love.graphics.rectangle("fill", plaque_x, plaque_y, plaque_w, plaque_h, radius - 10, radius - 10)

    love.graphics.setColor(plaque_glow)
    love.graphics.rectangle(
        "fill",
        plaque_x + 4,
        plaque_y + 4,
        plaque_w - 8,
        math.max(10, math.floor(plaque_h * 0.28)),
        radius - 14,
        radius - 14
    )

    love.graphics.setColor(grain)
    for index = 0, 2 do
        local grain_y = math.floor(plaque_y + 14 + index * math.max(10, plaque_h * 0.2))
        love.graphics.rectangle("fill", plaque_x + 16, grain_y, plaque_w - 32, 2, 1, 1)
    end

    local notch_w = 18
    local notch_h = math.max(16, math.floor(bounds.h * 0.24))
    local notch_y = bounds.y + math.floor((bounds.h - notch_h) * 0.5)
    love.graphics.setColor(frame_dark[1], frame_dark[2], frame_dark[3], 0.82)
    love.graphics.rectangle("fill", bounds.x + 10, notch_y, notch_w, notch_h, 6, 6)
    love.graphics.rectangle("fill", bounds.x + bounds.w - notch_w - 10, notch_y, notch_w, notch_h, 6, 6)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(edge)
    love.graphics.rectangle("line", bounds.x + 1.5, bounds.y + 1.5, bounds.w - 3, bounds.h - 3, radius, radius)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
        "line",
        bounds.x + outer_inset + 1,
        bounds.y + outer_inset + 1,
        bounds.w - (outer_inset + 1) * 2,
        bounds.h - (outer_inset + 1) * 2,
        radius - 7,
        radius - 7
    )
    love.graphics.setLineWidth(1)

    local font = fonts:get("Button")
    local text_y = bounds.y + math.floor((bounds.h - font:getHeight()) * 0.5) - 2
    ButtonText.draw(font, label, bounds.x, text_y + 2, bounds.w, "center", text_shadow, {
        bold = false,
        bold_offset = 1,
    })
    ButtonText.draw(font, label, bounds.x, text_y, bounds.w, "center", text, {
        bold = true,
        bold_offset = 1,
    })
end

local function drawGlobeIcon(inner, hovered)
    local cx = inner.x + math.floor(inner.width * 0.5)
    local cy = inner.y + math.floor(inner.height * 0.5)
    local radius = math.floor(math.min(inner.width, inner.height) * 0.26)

    local stroke = hovered and 3 or 2
    love.graphics.setLineWidth(stroke)
    love.graphics.setColor(0.44, 0.25, 0.14, 1)
    love.graphics.circle("line", cx, cy, radius)

    love.graphics.arc("line", "open", cx, cy, radius - 2, math.rad(200), math.rad(340))
    love.graphics.arc("line", "open", cx, cy, radius - 2, math.rad(20), math.rad(160))

    love.graphics.line(cx, cy - radius + 3, cx, cy + radius - 3)
    love.graphics.arc("line", "open", cx, cy, math.max(6, math.floor(radius * 0.48)), math.rad(90), math.rad(270))
    love.graphics.arc("line", "open", cx, cy, math.max(6, math.floor(radius * 0.48)), math.rad(-90), math.rad(90))

    love.graphics.line(cx - radius + 3, cy, cx + radius - 3, cy)
    love.graphics.line(cx - radius + 5, cy - math.floor(radius * 0.45), cx + radius - 5, cy - math.floor(radius * 0.45))
    love.graphics.line(cx - radius + 5, cy + math.floor(radius * 0.45), cx + radius - 5, cy + math.floor(radius * 0.45))
    love.graphics.setLineWidth(1)
end

local function drawFullscreenEnterIcon(ox, oy, pixel)
    local cells = {
        {1, 1}, {2, 1}, {3, 1}, {4, 1},
        {1, 2}, {2, 2},
        {1, 3}, {2, 3},
        {1, 4}, {2, 4},

        {9, 1}, {10, 1}, {11, 1}, {12, 1},
        {11, 2}, {12, 2},
        {11, 3}, {12, 3},
        {11, 4}, {12, 4},

        {1, 9}, {2, 9},
        {1, 10}, {2, 10},
        {1, 11}, {2, 11},
        {1, 12}, {2, 12}, {3, 12}, {4, 12},

        {11, 9}, {12, 9},
        {11, 10}, {12, 10},
        {11, 11}, {12, 11},
        {9, 12}, {10, 12}, {11, 12}, {12, 12},
    }

    drawPixelCells(ox, oy, pixel, cells, { 0.96, 0.96, 0.96, 1 })
    return 14 * pixel, 14 * pixel
end

local function drawFullscreenExitIcon(ox, oy, pixel)
    local back = {
        {2, 1}, {3, 1}, {4, 1}, {5, 1}, {6, 1}, {7, 1},
        {2, 2}, {7, 2},
        {2, 3}, {7, 3},
        {2, 4}, {7, 4},
        {2, 5}, {7, 5},
        {2, 6}, {7, 6},
        {2, 7}, {3, 7}, {4, 7}, {5, 7}, {6, 7}, {7, 7},
    }
    local front = {
        {6, 5}, {7, 5}, {8, 5}, {9, 5}, {10, 5}, {11, 5},
        {6, 6}, {11, 6},
        {6, 7}, {11, 7},
        {6, 8}, {11, 8},
        {6, 9}, {11, 9},
        {6, 10}, {7, 10}, {8, 10}, {9, 10}, {10, 10}, {11, 10},
    }

    drawPixelCells(ox, oy, pixel, back, { 0.96, 0.96, 0.96, 0.72 })
    drawPixelCells(ox, oy, pixel, front, { 0.96, 0.96, 0.96, 1 })
    return 14 * pixel, 14 * pixel
end

function WelcomePage.new(options)
    local self = setmetatable({}, WelcomePage)

    self.options = options or {}
    self.hover_button = false
    self.toast_timer = 0
    self.toast_duration = 2.4
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.fonts = assert(self.options.fonts, "WelcomePage requires a font manager")
    self.backgrounds = self.options.backgrounds
    self.style = Style
    self.wood_panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.icon_style = IconButtonsStyle
    self.mute_button = MuteButton.new()

    self.button = {}
    self.hover_language_button = false
    self.hover_server_button = nil
    self.hover_mute_icon = false
    self.hover_fullscreen_icon = false
    self.language_overlay_visible = options and options.language_overlay_visible == true or false
    self.hovered_language_option = nil
    self.hovered_language_close = false
    self.loading_overlay = LoadingOverlay.new({
        fonts = self.fonts,
        message_key = "common.loading",
    })
    self.pending_continue = false
    self.pending_continue_delay_frames = 0
    self.press_enter_timer = 0
    self.press_language_timer = 0
    self.press_server_timer = 0
    self.pressed_server_key = nil
    self.press_mute_timer = 0
    self.press_fullscreen_timer = 0
    self:layout()

    return self
end

function WelcomePage:layout()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()

    local button_width = clamp(self.window_width * 0.18, 260, 332)
    local button_height = clamp(self.window_height * 0.095, 78, 92)
    local preferred_y = self.window_height * 0.735
    local language_bounds = self:getLanguageButtonBounds()
    local max_button_y = language_bounds.y - button_height - 54

    self.button = {
        w = button_width,
        h = button_height,
        x = (self.window_width - button_width) * 0.5,
        y = math.min(preferred_y, max_button_y),
    }
end

function WelcomePage:update(dt)
    self.toast_timer = math.max(0, self.toast_timer - dt)
    self.loading_overlay:update(dt)
    self.press_enter_timer = math.max(0, (self.press_enter_timer or 0) - dt)
    self.press_language_timer = math.max(0, (self.press_language_timer or 0) - dt)
    self.press_server_timer = math.max(0, (self.press_server_timer or 0) - dt)
    if self.press_server_timer <= 0 then
        self.pressed_server_key = nil
    end
    self.press_mute_timer = math.max(0, (self.press_mute_timer or 0) - dt)
    self.press_fullscreen_timer = math.max(0, (self.press_fullscreen_timer or 0) - dt)

    if not self.pending_continue then
        return
    end

    if self.pending_continue_delay_frames > 0 then
        self.pending_continue_delay_frames = self.pending_continue_delay_frames - 1
        return
    end

    self.pending_continue = false
    local ok = pcall(function()
        if self.options.on_continue then
            self.options.on_continue()
        end
    end)
    if not ok then
        self.loading_overlay:hide()
    end
end

function WelcomePage:resize()
    self:layout()
end

function WelcomePage:showComingSoon()
    self.toast_timer = self.toast_duration
end

function WelcomePage:isButtonHovered(x, y)
    return pointInRect(x, y, self.button)
end

function WelcomePage:getLanguageButtonBounds()
    local width = clamp(self.window_width * 0.22, 240, 320)
    local height = 56
    local margin = 24
    return {
        x = math.floor((self.window_width - width) * 0.5),
        y = self.window_height - margin - height,
        w = width,
        h = height,
    }
end

function WelcomePage:getOverlayServerButtons()
    local definitions = self.options.get_server_options and self.options.get_server_options() or {
        { id = "domestic", label_key = "welcome.server_domestic" },
        { id = "overseas", label_key = "welcome.server_overseas" },
    }
    local frame = self:getLanguageOverlayFrame()
    local layout = self:getLanguageOverlayLayout()
    local count = math.max(#definitions, 1)
    local total_gap = layout.server_gap_x * math.max(count - 1, 0)
    local available_width = layout.width - layout.padding_x * 2
    local font = self.fonts:getForLocale("TextSmall", I18n:getLocale())
    local min_button_width = 120
    local max_button_width = math.max(min_button_width, available_width - total_gap)
    local text_padding = 40
    local button_height = layout.server_button_height
    local y = frame.y + layout.server_y
    local widths = {}
    local buttons = {}

    for index, definition in ipairs(definitions) do
        local label = definition.label or I18n:t(definition.label_key or "")
        widths[index] = clamp(math.ceil(font:getWidth(label) + text_padding), min_button_width, max_button_width)
    end

    local total_width = sumValues(widths) + total_gap
    if total_width > available_width then
        local min_total_width = min_button_width * count + total_gap
        if min_total_width <= available_width then
            local overflow = total_width - available_width
            local shrinkable = sumValues(widths) - min_button_width * count
            if shrinkable > 0 then
                for index = 1, count do
                    local extra = widths[index] - min_button_width
                    if extra > 0 then
                        local reduction = math.min(extra, math.ceil(overflow * (extra / shrinkable)))
                        widths[index] = widths[index] - reduction
                    end
                end
            end
        else
            local shared_width = math.floor((available_width - total_gap) / count)
            for index = 1, count do
                widths[index] = shared_width
            end
        end
        total_width = sumValues(widths) + total_gap
    end

    local start_x = frame.x + math.floor((layout.width - total_width) * 0.5)
    local current_x = start_x

    for index, definition in ipairs(definitions) do
        local label = definition.label or I18n:t(definition.label_key or "")
        buttons[#buttons + 1] = {
            id = definition.id,
            label = label,
            x = current_x,
            y = y,
            width = widths[index],
            height = button_height,
        }
        current_x = current_x + widths[index] + layout.server_gap_x
    end

    return buttons
end

function WelcomePage:getOverlayServerButtonAt(x, y)
    for _, button in ipairs(self:getOverlayServerButtons()) do
        if pointInRect(x, y, {
            x = button.x,
            y = button.y,
            w = button.width,
            h = button.height,
        }) then
            return button.id
        end
    end

    return nil
end

function WelcomePage:getMuteIconFrame()
    local icon_layout = self.icon_style.layout
    local size = icon_layout.button_size or 64
    local margin = icon_layout.right_margin or 22
    local top = icon_layout.top_margin or 18
    return {
        x = margin,
        y = top,
        width = size,
        height = size,
    }
end

function WelcomePage:getFullscreenIconFrame()
    local icon_layout = self.icon_style.layout
    local size = icon_layout.button_size or 64
    local margin = icon_layout.right_margin or 22
    local top = icon_layout.top_margin or 18
    return {
        x = self.window_width - margin - size,
        y = top,
        width = size,
        height = size,
    }
end

function WelcomePage:getLanguageOverlayLayout()
    local columns = 4
    local rows = 3
    local button_width = 132
    local button_height = 46
    local gap_x = 14
    local gap_y = 14
    local padding_x = 24
    local padding_top = 72
    local server_button_height = 44
    local server_gap_x = 16
    local server_gap_bottom = 18
    local padding_bottom = 24

    local grid_width = columns * button_width + (columns - 1) * gap_x
    local grid_height = rows * button_height + (rows - 1) * gap_y

    local width = grid_width + padding_x * 2
    local height = padding_top + server_button_height + server_gap_bottom + grid_height + padding_bottom

    local max_width = self.window_width - 120
    if width > max_width then
        width = max_width
        button_width = math.floor((width - padding_x * 2 - (columns - 1) * gap_x) / columns)
    end

    return {
        columns = columns,
        rows = rows,
        button_width = button_width,
        button_height = button_height,
        gap_x = gap_x,
        gap_y = gap_y,
        padding_x = padding_x,
        padding_top = padding_top,
        server_y = padding_top,
        server_button_height = server_button_height,
        server_gap_x = server_gap_x,
        server_gap_bottom = server_gap_bottom,
        width = width,
        height = height,
    }
end

function WelcomePage:getLanguageOverlayFrame()
    local layout = self:getLanguageOverlayLayout()
    return {
        x = math.floor((self.window_width - layout.width) * 0.5),
        y = math.floor((self.window_height - layout.height) * 0.5),
        width = layout.width,
        height = layout.height,
    }
end

function WelcomePage:getLanguageOptionButtons()
    local frame = self:getLanguageOverlayFrame()
    local layout = self:getLanguageOverlayLayout()
    local start_x = frame.x + layout.padding_x
    local start_y = frame.y + layout.padding_top + layout.server_button_height + layout.server_gap_bottom
    local buttons = {}
    local max_buttons = layout.columns * layout.rows

    for index, locale in ipairs(I18n:getOrderedLocales()) do
        if index > max_buttons then
            break
        end
        local col = (index - 1) % layout.columns
        local row = math.floor((index - 1) / layout.columns)
        buttons[#buttons + 1] = {
            id = locale,
            label = I18n:getLocaleShortLabel(locale),
            x = start_x + col * (layout.button_width + layout.gap_x),
            y = start_y + row * (layout.button_height + layout.gap_y),
            width = layout.button_width,
            height = layout.button_height,
        }
    end

    return buttons
end

function WelcomePage:getLanguageOptionAt(x, y)
    for _, button in ipairs(self:getLanguageOptionButtons()) do
        if pointInRect(x, y, {
            x = button.x,
            y = button.y,
            w = button.width,
            h = button.height,
        }) then
            return button.id
        end
    end

    return nil
end

function WelcomePage:getLanguageOverlayCloseBounds()
    local frame = self:getLanguageOverlayFrame()
    return {
        x = frame.x + frame.width - 58,
        y = frame.y + 16,
        width = 38,
        height = 38,
    }
end

function WelcomePage:mousemoved(x, y)
    if self.loading_overlay:isVisible() then
        self.hover_button = false
        self.hover_language_button = false
        self.hover_server_button = nil
        self.hover_mute_icon = false
        self.hover_fullscreen_icon = false
        self.hovered_language_option = nil
        self.hovered_language_close = false
        return
    end

    if self.language_overlay_visible then
        self.hovered_language_option = self:getLanguageOptionAt(x, y)
        self.hover_server_button = self:getOverlayServerButtonAt(x, y)
        self.hovered_language_close = self.close_button:contains(self:getLanguageOverlayCloseBounds(), x, y)
        self.hover_button = false
        self.hover_language_button = false
        self.hover_mute_icon = false
        self.hover_fullscreen_icon = false
        return
    end

    self.hover_button = self:isButtonHovered(x, y)
    self.hover_language_button = pointInRect(x, y, self:getLanguageButtonBounds())
    self.hover_server_button = nil
    self.hover_mute_icon = self.mute_button:contains(self:getMuteIconFrame(), x, y)
    self.hover_fullscreen_icon = pointInRect(x, y, self:getFullscreenIconFrame())
end

function WelcomePage:activate()
    if self.loading_overlay:isVisible() then
        return
    end
    self.press_enter_timer = PRESS_FEEDBACK_DURATION
    self.loading_overlay:show()
    self.pending_continue = true
    self.pending_continue_delay_frames = 1
end

function WelcomePage:mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end

    if self.loading_overlay:isVisible() then
        return true
    end

    if self.language_overlay_visible then
        if self.close_button:contains(self:getLanguageOverlayCloseBounds(), x, y) then
            self.language_overlay_visible = false
            self.hovered_language_close = false
            self.hovered_language_option = nil
            return true
        end

        local locale = self:getLanguageOptionAt(x, y)
        if locale and self.options.on_change_language then
            self.options.on_change_language(locale)
            return true
        end

        local server_key = self:getOverlayServerButtonAt(x, y)
        if server_key then
            self.press_server_timer = PRESS_FEEDBACK_DURATION
            self.pressed_server_key = server_key
            if self.options.on_change_server then
                self.options.on_change_server(server_key)
            end
            return true
        end
        return false
    end

    if self.mute_button:contains(self:getMuteIconFrame(), x, y) then
        self.press_mute_timer = PRESS_FEEDBACK_DURATION
        if self.options.on_toggle_mute then
            self.options.on_toggle_mute()
        end
        return true
    end

    if pointInRect(x, y, self:getFullscreenIconFrame()) then
        self.press_fullscreen_timer = PRESS_FEEDBACK_DURATION
        if self.options.on_toggle_fullscreen then
            self.options.on_toggle_fullscreen()
        end
        return true
    end

    if pointInRect(x, y, self:getLanguageButtonBounds()) then
        self.press_language_timer = PRESS_FEEDBACK_DURATION
        self.language_overlay_visible = true
        self.hovered_language_option = nil
        self.hovered_language_close = false
        return true
    end

    if self:isButtonHovered(x, y) then
        self:activate()
        return true
    end
    return false
end

function WelcomePage:keypressed(key)
    if self.loading_overlay:isVisible() then
        return
    end

    if self.language_overlay_visible then
        if key == "escape" then
            self.language_overlay_visible = false
            self.hovered_language_close = false
            self.hovered_language_option = nil
        end
        return
    end

    if key == "return" or key == "kpenter" or key == "space" then
        self:activate()
    end
end

function WelcomePage:drawBackground()
    if self.backgrounds then
        self.backgrounds:draw("GameWelcomeBG")
        return
    end

    love.graphics.clear(0.28, 0.66, 0.95, 1)
end

function WelcomePage:drawHero()
    local w = self.window_width
    local h = self.window_height
    local time = getAnimTime()
    local panel_width = clamp(w * 0.62, 760, 1040)
    local panel_height = clamp(h * 0.26, 180, 260)
    local panel_x = (w - panel_width) * 0.5
    local panel_y = h * 0.08 + math.sin(time * 1.35) * 4

    self.wood_panel:draw({
        x = panel_x,
        y = panel_y,
        width = panel_width,
        height = panel_height,
    }, {
        radius = 22,
        shadow_offset = 8,
    })

    local title_font = self.fonts:get("Title1")
    local title_y = panel_y + math.floor((panel_height - title_font:getHeight()) * 0.5)

    love.graphics.setFont(title_font)
    love.graphics.setColor(
        Style.colors.text_primary[1],
        Style.colors.text_primary[2],
        Style.colors.text_primary[3],
        Style.colors.text_primary[4]
    )
    love.graphics.printf(I18n:t("welcome.hero_title"), panel_x, title_y, panel_width, "center")
end

function WelcomePage:drawButton()
    local time = getAnimTime()
    local pressed = (self.press_enter_timer or 0) > 0
    local pulse = pressed and 0 or (0.5 + 0.5 * math.sin(time * 1.85))
    local lift = pressed and 2 or (math.sin(time * 1.85) * 3)
    local grow = 2 + pulse * 2
    local button_x = self.button.x - grow * 0.5
    local button_y = self.button.y - grow * 0.18 + lift
    local button_w = self.button.w + grow
    local button_h = self.button.h + grow * 0.36

    drawPrimaryActionButton({
        x = button_x,
        y = button_y,
        w = button_w,
        h = button_h,
    }, self.hover_button, pressed, I18n:t("welcome.enter_game"), self.fonts)
end

function WelcomePage:drawOverlayServerButtons()
    local buttons = self:getOverlayServerButtons()
    local selected_server = self.options.get_selected_server_key
        and self.options.get_selected_server_key()
        or nil

    for _, button in ipairs(buttons) do
        local pressed = self.pressed_server_key == button.id and (self.press_server_timer or 0) > 0
        WoodButton.draw(self.fonts, self.style, {
            label = button.label,
            locale = I18n:getLocale(),
            x = button.x,
            y = button.y + (pressed and 2 or 0),
            width = button.width,
            height = button.height,
            hovered = self.hover_server_button == button.id,
            enabled = true,
            variant = selected_server == button.id and "primary" or "secondary",
            font_token = "TextSmall",
            radius = 12,
        })
    end
end

function WelcomePage:drawOverlaySectionDivider(frame, layout)
    local x = frame.x + layout.padding_x
    local width = frame.width - layout.padding_x * 2
    local y = frame.y + layout.padding_top + layout.server_button_height + math.floor(layout.server_gap_bottom * 0.5)
    local colors = self.style.colors

    love.graphics.setColor(colors.panel_shadow[1], colors.panel_shadow[2], colors.panel_shadow[3], 0.18)
    love.graphics.rectangle("fill", x, y + 1, width, 2, 1, 1)

    love.graphics.setColor(colors.button_secondary_highlight[1], colors.button_secondary_highlight[2], colors.button_secondary_highlight[3], 0.45)
    love.graphics.rectangle("fill", x, y, width, 1, 1, 1)

    love.graphics.setColor(colors.button_secondary_border[1], colors.button_secondary_border[2], colors.button_secondary_border[3], 0.35)
    love.graphics.rectangle("fill", x, y + 3, width, 1, 1, 1)
end

function WelcomePage:drawLanguageButton()
    local bounds = self:getLanguageButtonBounds()
    local radius = 12
    local inset = self.style.layout.button_inner_inset or 6
    local colors = self.style.colors
    local hovered = self.hover_language_button == true
    local pressed = (self.press_language_timer or 0) > 0
    local frame = colors.button_secondary_frame
    local face = hovered and colors.button_secondary_hover_face or colors.button_secondary_face
    local shadow = colors.button_secondary_shadow
    local highlight = colors.button_secondary_highlight
    local border = colors.button_secondary_border
    local grain = colors.button_secondary_grain
    local text = colors.button_secondary_text

    local offset_y = pressed and 2 or 0
    if pressed then
        face = {
            face[1] * 0.9,
            face[2] * 0.9,
            face[3] * 0.9,
            face[4],
        }
    end

    drawRect(shadow, bounds.x, bounds.y + 6 + offset_y, bounds.w, bounds.h, radius)
    drawRect(frame, bounds.x, bounds.y + offset_y, bounds.w, bounds.h, radius)

    local inner_x = bounds.x + inset
    local inner_y = bounds.y + inset + offset_y
    local inner_w = bounds.w - inset * 2
    local inner_h = bounds.h - inset * 2
    drawRect(face, inner_x, inner_y, inner_w, inner_h, radius - 4)
    if not pressed then
        drawRect(highlight, inner_x + 2, inner_y + 2, inner_w - 4, math.max(8, math.floor(inner_h * 0.24)), radius - 6)
    end

    love.graphics.setColor(grain)
    for index = 0, 1 do
        local grain_y = math.floor(inner_y + 11 + index * 12)
        love.graphics.rectangle("fill", inner_x + 10, grain_y, inner_w - 20, 2, 1, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", bounds.x + 1, bounds.y + 1, bounds.w - 2, bounds.h - 2, radius, radius)
    love.graphics.rectangle("line", inner_x + 1, inner_y + 1, inner_w - 2, inner_h - 2, radius - 4, radius - 4)
    love.graphics.setLineWidth(1)

    drawGlobeIcon({
        x = inner_x + 4,
        y = inner_y + 1,
        width = 30,
        height = inner_h - 2,
    }, hovered)

    local font = self.fonts:getForLocale("TextSmall", I18n:getLocale())
    local text_y = bounds.y + math.floor((bounds.h - font:getHeight()) * 0.5) - 1 + offset_y
    ButtonText.draw(font, I18n:t("welcome.language_server_button"), bounds.x + 34, text_y, bounds.w - 44, "center", text, {
        bold = true,
        bold_offset = 1,
    })
end

function WelcomePage:drawLanguageOverlay()
    local frame = self:getLanguageOverlayFrame()
    local layout = self:getLanguageOverlayLayout()

    love.graphics.setColor(self.style.colors.overlay)
    love.graphics.rectangle("fill", 0, 0, self.window_width, self.window_height)

    self.wood_panel:draw(frame, { radius = 20, shadow_offset = 8 })

    love.graphics.setColor(self.style.colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(I18n:t("welcome.language_server_title"), frame.x, frame.y + 24, frame.width, "center")

    self:drawOverlayServerButtons()
    self:drawOverlaySectionDivider(frame, layout)

    for _, button in ipairs(self:getLanguageOptionButtons()) do
        WoodButton.draw(self.fonts, self.style, {
            label = button.label,
            locale = button.id,
            x = button.x,
            y = button.y,
            width = button.width,
            height = button.height,
            hovered = self.hovered_language_option == button.id,
            enabled = true,
            variant = I18n:getLocale() == button.id and "primary" or "secondary",
            font_token = "Text",
            radius = 12,
        })
    end

    self.close_button:draw(self:getLanguageOverlayCloseBounds(), self.hovered_language_close)
end

function WelcomePage:drawMuteIcon()
    local frame = self:getMuteIconFrame()
    local muted = self.options.is_muted and self.options.is_muted() == true or false

    self.mute_button:draw(frame, {
        muted = muted,
        hovered = self.hover_mute_icon,
        pressed = (self.press_mute_timer or 0) > 0,
    })
end

function WelcomePage:drawFullscreenIcon()
    local icon_style = self.icon_style
    local frame = self:getFullscreenIconFrame()
    local fullscreen = self.options.is_fullscreen and self.options.is_fullscreen() == true or false

    local pressed = (self.press_fullscreen_timer or 0) > 0
    local draw_frame = {
        x = frame.x,
        y = frame.y + (pressed and 2 or 0),
        width = frame.width,
        height = frame.height,
    }

    drawDarkPixelIconFrame(draw_frame, self.hover_fullscreen_icon, pressed)

    local pixel = math.max(icon_style.icon.pixel, 4)
    local icon_w, icon_h
    if fullscreen then
        icon_w, icon_h = 14 * pixel, 14 * pixel
    else
        icon_w, icon_h = 14 * pixel, 14 * pixel
    end

    local ox = draw_frame.x + math.floor((draw_frame.width - icon_w) / 2)
    local oy = draw_frame.y + math.floor((draw_frame.height - icon_h) / 2)

    if fullscreen then
        drawFullscreenExitIcon(ox, oy, pixel)
    else
        drawFullscreenEnterIcon(ox, oy, pixel)
    end
end

function WelcomePage:draw()
    self:drawBackground()
    self:drawMuteIcon()
    self:drawFullscreenIcon()
    self:drawHero()
    self:drawButton()
    self:drawLanguageButton()
    if self.language_overlay_visible then
        self:drawLanguageOverlay()
    end
    self.loading_overlay:draw(self.window_width, self.window_height)
end

return WelcomePage
