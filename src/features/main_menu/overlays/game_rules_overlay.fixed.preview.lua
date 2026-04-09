local CardView = require("src.features.gameplay.components.card_view")
local ThemeCatalog = require("src.features.gameplay.card_themes.theme_catalog")
local IconCloseButton = require("src.core.ui.icon_close_button")
local I18n = require("src.core.i18n.i18n")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local GameRulesOverlay = {}
GameRulesOverlay.__index = GameRulesOverlay

local function contains(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height
end

local function resolveRuleText(path)
    local full_path = "main_menu.rules_overlay." .. tostring(path or "")
    local locale_code = tostring(I18n:getLocale() or "")
    local prefer_zh = locale_code:sub(1, 2) == "zh"
    return I18n:getValue(full_path, {
        fallback_locales = prefer_zh and { "zh-CN", "en-US" } or { "en-US", "zh-CN" },
    }) or full_path
end

local function getRulesPageText(index)
    local pages = resolveRuleText("pages")
    if type(pages) ~= "table" then
        return {}
    end
    local page = pages[index]
    if type(page) ~= "table" then
        return {}
    end
    return page
end

local function drawRoundedPanel(fill, border, frame, radius)
    love.graphics.setColor(0.28, 0.18, 0.09, 0.12)
    love.graphics.rectangle("fill", frame.x, frame.y + 5, frame.width, frame.height, radius, radius)

    love.graphics.setColor(fill)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.width, frame.height, radius, radius)

    love.graphics.setColor(1, 1, 1, 0.10)
    love.graphics.rectangle("fill", frame.x + 3, frame.y + 3, frame.width - 6, math.max(10, math.floor(frame.height * 0.18)), radius - 4, radius - 4)

    love.graphics.setLineWidth(2)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", frame.x + 1, frame.y + 1, frame.width - 2, frame.height - 2, radius, radius)
    love.graphics.setLineWidth(1)
end

local function drawFlowArrow(x1, y1, x2, y2, color)
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return
    end

    local ux = dx / length
    local uy = dy / length
    local head = 10
    local wing = 5

    love.graphics.setColor(color)
    love.graphics.setLineWidth(3)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setLineWidth(1)
    love.graphics.polygon(
        "fill",
        x2,
        y2,
        x2 - ux * head - uy * wing,
        y2 - uy * head + ux * wing,
        x2 - ux * head + uy * wing,
        y2 - uy * head - ux * wing
    )
end

local function drawGreaterThan(fonts, x, y, width, height, colors, caption)
    local primary = colors.text_primary or { 0.36, 0.16, 0.08, 1 }
    local secondary = colors.text_muted or { 0.55, 0.29, 0.15, 0.98 }

    love.graphics.setColor(primary)
    love.graphics.setFont(fonts:get("Title2"))
    love.graphics.printf(">", x, y + math.floor(height * 0.16), width, "center")

    if caption and caption ~= "" then
        love.graphics.setColor(secondary)
        love.graphics.setFont(fonts:get("Caption"))
        love.graphics.printf(caption, x, y + math.floor(height * 0.62), width, "center")
    end
end

local function formatPageCounter(page_index, total_pages)
    return I18n:t("main_menu.rules_page_counter", {
        page = tostring(page_index),
        total = tostring(total_pages),
    })
end

local function getWrapLineCount(font, text_value, width)
    local wrapped_lines, wrap_count = font:getWrap(text_value or "", width)
    if type(wrap_count) == "number" then
        return math.max(1, wrap_count)
    end
    if type(wrapped_lines) == "table" then
        return math.max(1, #wrapped_lines)
    end
    return 1
end

local function buildPages()
    local page_1 = getRulesPageText(1)
    local page_2 = getRulesPageText(2)
    local page_3 = getRulesPageText(3)
    local page_4 = getRulesPageText(4)
    local page_5 = getRulesPageText(5)
    local page_6 = getRulesPageText(6)

    local page_1_examples = page_1.examples or {}
    local page_2_examples = page_2.examples or {}
    local page_3_rows = page_3.rows or {}
    local page_4_examples = page_4.examples or {}
    local page_5_promotions = page_5.promotions or {}
    local page_5_tribute_rows = page_5.tribute_rows or {}

    local row_1 = page_3_rows[1] or {}
    local row_2 = page_3_rows[2] or {}
    local row_3 = page_3_rows[3] or {}
    local row_3_stages = row_3.stages or {}

    return {
        {
            title = page_1.title or "",
            subtitle = page_1.subtitle or "",
            rules = page_1.rules or {},
            examples = {
                {
                    title = (page_1_examples[1] or {}).title or "",
                    note = (page_1_examples[1] or {}).note or "",
                    cards = { "S-A-1" },
                },
                {
                    title = (page_1_examples[2] or {}).title or "",
                    note = (page_1_examples[2] or {}).note or "",
                    cards = { "H-10-1", "D-10-1" },
                },
                {
                    title = (page_1_examples[3] or {}).title or "",
                    note = (page_1_examples[3] or {}).note or "",
                    cards = { "S-8-1", "H-8-1", "C-8-1" },
                },
                {
                    title = (page_1_examples[4] or {}).title or "",
                    note = (page_1_examples[4] or {}).note or "",
                    cards = { "S-9-1", "H-9-1", "C-9-1", "S-5-1", "H-5-1" },
                },
            },
        },
        {
            title = page_2.title or "",
            subtitle = page_2.subtitle or "",
            rules = page_2.rules or {},
            examples = {
                {
                    title = (page_2_examples[1] or {}).title or "",
                    note = (page_2_examples[1] or {}).note or "",
                    cards = { "S-3-1", "H-4-1", "C-5-1", "D-6-1", "S-7-1" },
                },
                {
                    title = (page_2_examples[2] or {}).title or "",
                    note = (page_2_examples[2] or {}).note or "",
                    cards = { "S-4-1", "H-4-1", "S-5-1", "H-5-1", "S-6-1", "H-6-1" },
                },
                {
                    title = (page_2_examples[3] or {}).title or "",
                    note = (page_2_examples[3] or {}).note or "",
                    cards = { "S-7-1", "H-7-1", "C-7-1", "S-8-1", "H-8-1", "C-8-1" },
                },
                {
                    title = (page_2_examples[4] or {}).title or "",
                    note = (page_2_examples[4] or {}).note or "",
                    cards = { "S-A-1", "H-A-1", "C-A-1", "D-A-1" },
                },
                {
                    title = (page_2_examples[5] or {}).title or "",
                    note = (page_2_examples[5] or {}).note or "",
                    cards = { "S-7-1", "S-8-1", "S-9-1", "S-10-1", "S-J-1" },
                },
                {
                    title = (page_2_examples[6] or {}).title or "",
                    note = (page_2_examples[6] or {}).note or "",
                    cards = { "BJ-1", "RJ-1", "BJ-2", "RJ-2" },
                },
            },
        },
        {
            title = page_3.title or "",
            subtitle = page_3.subtitle or "",
            rules = page_3.rules or {},
            rows = {
                {
                    title = row_1.title or "",
                    note = row_1.note or "",
                    left_label = row_1.left_label or "",
                    right_label = row_1.right_label or "",
                    left_cards = { "S-8-1", "H-8-1" },
                    right_cards = { "S-9-1", "H-9-1" },
                    center_label = row_1.center_label or "",
                },
                {
                    title = row_2.title or "",
                    note = row_2.note or "",
                    left_label = row_2.left_label or "",
                    right_label = row_2.right_label or "",
                    left_cards = { "S-7-1", "H-7-1", "C-7-1", "S-5-1", "H-5-1" },
                    right_cards = { "S-A-1", "H-A-1", "C-A-1", "D-A-1" },
                    center_label = row_2.center_label or "",
                },
                {
                    title = row_3.title or "",
                    note = row_3.note or "",
                    stages = {
                        {
                            label = (row_3_stages[1] or {}).label or "",
                            cards = { "S-7-1", "S-8-1", "S-9-1", "S-10-1", "S-J-1" },
                        },
                        {
                            label = (row_3_stages[2] or {}).label or "",
                            cards = { "S-Q-1", "H-Q-1", "C-Q-1", "D-Q-1", "S-Q-2", "H-Q-2" },
                        },
                        {
                            label = (row_3_stages[3] or {}).label or "",
                            cards = { "BJ-1", "RJ-1", "BJ-2", "RJ-2" },
                        },
                    },
                },
            },
        },
        {
            title = page_4.title or "",
            subtitle = page_4.subtitle or "",
            rules = page_4.rules or {},
            hero = {
                title = ((page_4.hero or {}).title) or "",
                note = ((page_4.hero or {}).note) or "",
                card = "H-6-1",
            },
            examples = {
                {
                    title = (page_4_examples[1] or {}).title or "",
                    note = (page_4_examples[1] or {}).note or "",
                    cards = { "S-4-1", "C-5-1", "D-6-1", "S-7-1", "H-6-1" },
                },
                {
                    title = (page_4_examples[2] or {}).title or "",
                    note = (page_4_examples[2] or {}).note or "",
                    cards = { "H-6-1", "S-A-1", "D-Q-1" },
                },
            },
        },
        {
            title = page_5.title or "",
            subtitle = page_5.subtitle or "",
            rules = page_5.rules or {},
            promotions = {
                {
                    order = (page_5_promotions[1] or {}).order or "",
                    gain = (page_5_promotions[1] or {}).gain or "",
                    note = (page_5_promotions[1] or {}).note or "",
                },
                {
                    order = (page_5_promotions[2] or {}).order or "",
                    gain = (page_5_promotions[2] or {}).gain or "",
                    note = (page_5_promotions[2] or {}).note or "",
                },
                {
                    order = (page_5_promotions[3] or {}).order or "",
                    gain = (page_5_promotions[3] or {}).gain or "",
                    note = (page_5_promotions[3] or {}).note or "",
                },
            },
            tribute_rows = {
                {
                    title = (page_5_tribute_rows[1] or {}).title or "",
                    note = (page_5_tribute_rows[1] or {}).note or "",
                    left_cards = { "S-A-1" },
                    right_cards = { "C-3-1" },
                },
                {
                    title = (page_5_tribute_rows[2] or {}).title or "",
                    note = (page_5_tribute_rows[2] or {}).note or "",
                    left_cards = { "S-A-1", "D-K-1" },
                    right_cards = { "C-3-1", "D-4-1" },
                },
            },
            anti = {
                title = ((page_5.anti or {}).title) or "",
                note = ((page_5.anti or {}).note) or "",
                cards = { "RJ-1", "RJ-2" },
            },
        },
        {
            title = page_6.title or "",
            kind = "text",
            intro = page_6.intro or "",
            sections = page_6.sections or {},
            hint = page_6.hint or "",
        },
    }
end
function GameRulesOverlay.new(options)
    local self = setmetatable({}, GameRulesOverlay)
    self.fonts = assert(options and options.fonts, "GameRulesOverlay requires fonts")
    self.style = assert(options and options.style, "GameRulesOverlay requires style")
    self.wood_panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.card_view = CardView.new()
    return self
end

function GameRulesOverlay:_resolveThemeConfig(theme_config)
    local config = theme_config or self.current_card_theme_config or {}
    return {
        theme_id = ThemeCatalog.normalizeThemeId(config.theme_id),
        high_contrast = config.high_contrast == true,
        back_id = config.back_id or "classic_grid",
    }
end

function GameRulesOverlay:getPageCount()
    return #buildPages()
end

function GameRulesOverlay:getPanelFrame()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panel_width = math.min(width - 80, 1120)
    local panel_height = math.min(height - 60, 690)
    return {
        x = math.floor((width - panel_width) / 2),
        y = math.floor((height - panel_height) / 2),
        width = panel_width,
        height = panel_height,
    }
end

function GameRulesOverlay:getNavigationFrames()
    local panel = self:getPanelFrame()
    local button_width = 194
    local button_height = 58
    local counter_width = 228
    local gap = 18
    local total_width = button_width * 2 + counter_width + gap * 2
    local start_x = panel.x + math.floor((panel.width - total_width) / 2)
    local y = panel.y + panel.height - 74

    return {
        prev = {
            x = start_x,
            y = y,
            width = button_width,
            height = button_height,
        },
        counter = {
            x = start_x + button_width + gap,
            y = y,
            width = counter_width,
            height = button_height,
        },
        next = {
            x = start_x + button_width + gap + counter_width + gap,
            y = y,
            width = button_width,
            height = button_height,
        },
    }
end

function GameRulesOverlay:getCloseButtonFrame()
    local frame = self:getPanelFrame()
    return {
        x = frame.x + frame.width - 56,
        y = frame.y + 18,
        width = 38,
        height = 38,
    }
end

function GameRulesOverlay:getPrevButtonFrame()
    return self:getNavigationFrames().prev
end

function GameRulesOverlay:getNextButtonFrame()
    return self:getNavigationFrames().next
end

function GameRulesOverlay:getPageCounterFrame()
    return self:getNavigationFrames().counter
end

function GameRulesOverlay:getContentFrame()
    local panel = self:getPanelFrame()
    return {
        x = panel.x + 34,
        y = panel.y + 144,
        width = panel.width - 68,
        height = panel.height - 246,
    }
end

function GameRulesOverlay:isTextPage(page_index)
    local page = buildPages()[page_index]
    return page and page.kind == "text"
end

function GameRulesOverlay:getTextScrollFrame()
    local content = self:getContentFrame()
    return {
        x = content.x + 10,
        y = content.y + 6,
        width = content.width - 20,
        height = content.height - 12,
    }
end

function GameRulesOverlay:getTextScrollMax(page_index)
    if not self:isTextPage(page_index) then
        return 0
    end
    local frame = self:getTextScrollFrame()
    local page = buildPages()[page_index]
    local total_height = self:_measureTextPageHeight(page, frame.width)
    return math.max(0, total_height - frame.height)
end

function GameRulesOverlay:getTextScrollStep()
    local font = self.fonts:get("TextSmall")
    local height = 0
    if font and font.getHeight then
        height = font:getHeight()
    end
    return math.max(18, math.floor(height * 1.2 + 6))
end

function GameRulesOverlay:clampTextScroll(scroll_offset, page_index)
    local max_scroll = self:getTextScrollMax(page_index)
    local value = tonumber(scroll_offset) or 0
    if value < 0 then
        return 0
    end
    if value > max_scroll then
        return max_scroll
    end
    return value
end

function GameRulesOverlay:isTextScrollHit(x, y, page_index)
    if not self:isTextPage(page_index) then
        return false
    end
    return contains(self:getTextScrollFrame(), x, y)
end

function GameRulesOverlay:getControlAt(x, y, page_index)
    if contains(self:getCloseButtonFrame(), x, y) then
        return "rules_close"
    end

    if page_index > 1 and contains(self:getPrevButtonFrame(), x, y) then
        return "rules_prev"
    end

    if page_index < self:getPageCount() and contains(self:getNextButtonFrame(), x, y) then
        return "rules_next"
    end

    return nil
end

function GameRulesOverlay:_drawCardStrip(cards, frame)
    if not cards or #cards == 0 then
        return
    end

    local card_count = #cards
    local available_width = math.max(72, frame.width - 4)
    local available_height = math.max(92, frame.height - 4)
    local overlap_ratio = 0
    if card_count == 2 then
        overlap_ratio = 0.78
    elseif card_count == 3 then
        overlap_ratio = 0.68
    elseif card_count <= 5 then
        overlap_ratio = 0.48
    else
        overlap_ratio = 0.42
    end

    local aspect = 1.38
    local width_from_height = math.floor(available_height / aspect)
    local width_from_width = available_width
    if card_count > 1 then
        width_from_width = math.floor(available_width / (1 + overlap_ratio * (card_count - 1)))
    end

    local card_width = math.max(68, math.min(width_from_height, width_from_width, 168))
    local card_height = math.floor(card_width * aspect)
    if card_height > available_height then
        card_height = available_height
        card_width = math.max(54, math.floor(card_height / aspect))
    end
    local spacing = 0

    if card_count > 1 then
        spacing = math.floor(card_width * overlap_ratio)
        local max_spacing = math.floor((available_width - card_width) / (card_count - 1))
        spacing = math.max(12, math.min(spacing, max_spacing))
    end

    local total_width = card_width + math.max(0, card_count - 1) * spacing
    local start_x = frame.x + math.floor((frame.width - total_width) / 2)
    local y = frame.y + math.floor((frame.height - card_height) / 2)

    for index, card_id in ipairs(cards) do
        self.card_view:draw(
            card_id,
            {
                x = start_x + (index - 1) * spacing,
                y = y,
                width = card_width,
                height = card_height,
            },
            self:_resolveThemeConfig(),
            {
                selected = false,
                hovered = false,
                relation = "neutral",
            },
            self.fonts
        )
    end
end

function GameRulesOverlay:_drawBulletList(lines, frame)
    local colors = self.style.colors
    local font = self.fonts:get("Caption")
    local y = frame.y
    local max_lines = frame.max_lines or 2

    love.graphics.setFont(font)
    love.graphics.setColor(colors.text_secondary)
    for index, line in ipairs(lines or {}) do
        if index > max_lines then
            break
        end
        local text_line = tostring(line)
        local wrapped_lines, wrap_count = font:getWrap(text_line, frame.width)
        local line_count = wrap_count
        if type(line_count) ~= "number" then
            if type(wrapped_lines) == "table" then
                line_count = #wrapped_lines
            else
                line_count = 1
            end
        end
        line_count = math.max(1, line_count)
        love.graphics.printf(text_line, frame.x, y, frame.width, "left")
        y = y + line_count * font:getHeight() + 6
    end
    return y - frame.y
end

function GameRulesOverlay:_measureTextBlockHeight(font, text_value, width, line_gap)
    local line_count = getWrapLineCount(font, text_value, width)
    return line_count * font:getHeight() + (line_gap or 0)
end

function GameRulesOverlay:_measureTextPageHeight(page, width)
    if not page then
        return 0
    end
    local body_font = self.fonts:get("TextSmall")
    local title_font = self.fonts:get("Title3")
    local caption_font = self.fonts:get("Caption")
    local total = 0

    if page.intro and page.intro ~= "" then
        total = total + self:_measureTextBlockHeight(body_font, page.intro, width, 12)
    end

    for _, section in ipairs(page.sections or {}) do
        if section.title and section.title ~= "" then
            total = total + title_font:getHeight() + 6
        end
        for _, item in ipairs(section.items or {}) do
            local line = "- " .. tostring(item)
            total = total + self:_measureTextBlockHeight(body_font, line, width, 6)
        end
        total = total + 4
    end

    if page.hint and page.hint ~= "" then
        total = total + self:_measureTextBlockHeight(caption_font, page.hint, width, 0)
    end

    return total
end

function GameRulesOverlay:_drawTextScrollBar(frame, scroll_offset, max_scroll)
    if max_scroll <= 0 then
        return
    end
    local ratio = frame.height / (frame.height + max_scroll)
    local bar_height = math.max(36, math.floor(frame.height * ratio))
    local max_bar_y = frame.height - bar_height
    local bar_y = frame.y + math.floor(max_bar_y * (scroll_offset / max_scroll))

    love.graphics.setColor(0.62, 0.40, 0.20, 0.22)
    love.graphics.rectangle("fill", frame.x + frame.width - 6, frame.y + 2, 4, frame.height - 4, 2, 2)
    love.graphics.setColor(0.68, 0.44, 0.24, 0.72)
    love.graphics.rectangle("fill", frame.x + frame.width - 6, bar_y, 4, bar_height, 2, 2)
end

function GameRulesOverlay:_drawTextPage(content, page, scroll_offset)
    local colors = self.style.colors
    local frame = self:getTextScrollFrame()
    local body_font = self.fonts:get("TextSmall")
    local title_font = self.fonts:get("Title3")
    local caption_font = self.fonts:get("Caption")
    local total_height = self:_measureTextPageHeight(page, frame.width)
    local max_scroll = math.max(0, total_height - frame.height)
    local offset = math.max(0, math.min(max_scroll, scroll_offset or 0))

    love.graphics.setScissor(frame.x, frame.y, frame.width, frame.height)
    local y = frame.y - offset

    if page.intro and page.intro ~= "" then
        love.graphics.setFont(body_font)
        love.graphics.setColor(colors.text_secondary)
        love.graphics.printf(page.intro, frame.x, y, frame.width, "left")
        y = y + self:_measureTextBlockHeight(body_font, page.intro, frame.width, 12)
    end

    for _, section in ipairs(page.sections or {}) do
        if section.title and section.title ~= "" then
            love.graphics.setFont(title_font)
            love.graphics.setColor(colors.text_primary)
            love.graphics.printf(section.title, frame.x, y, frame.width, "left")
            y = y + title_font:getHeight() + 6
        end

        for _, item in ipairs(section.items or {}) do
            local line = "- " .. tostring(item)
            love.graphics.setFont(body_font)
            love.graphics.setColor(colors.text_secondary)
            love.graphics.printf(line, frame.x, y, frame.width, "left")
            y = y + self:_measureTextBlockHeight(body_font, line, frame.width, 6)
        end
        y = y + 4
    end

    if page.hint and page.hint ~= "" then
        love.graphics.setFont(caption_font)
        love.graphics.setColor(colors.text_muted or colors.text_secondary)
        love.graphics.printf(page.hint, frame.x, y, frame.width, "left")
    end

    love.graphics.setScissor()

    self:_drawTextScrollBar(frame, offset, max_scroll)
end

function GameRulesOverlay:_drawExamplePanel(frame, example)
    local colors = self.style.colors
    drawRoundedPanel({ 0.98, 0.94, 0.84, 0.98 }, { 0.72, 0.49, 0.25, 0.62 }, frame, 16)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(example.title or "", frame.x + 14, frame.y + 8, frame.width - 28, "left")

    local card_area = {
        x = frame.x + 6,
        y = frame.y + 36,
        width = frame.width - 12,
        height = frame.height - 42,
    }
    self:_drawCardStrip(example.cards or {}, card_area)
end

function GameRulesOverlay:_drawOverviewPage(content, page, columns)
    local grid_top = content.y + 4
    local gap = 18
    local rows = math.ceil(#(page.examples or {}) / columns)
    local cell_width = math.floor((content.width - gap * (columns - 1)) / columns)
    local cell_height = math.floor((content.height - (grid_top - content.y) - gap * (rows - 1)) / rows)

    for index, example in ipairs(page.examples or {}) do
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        self:_drawExamplePanel({
            x = content.x + col * (cell_width + gap),
            y = grid_top + row * (cell_height + gap),
            width = cell_width,
            height = cell_height,
        }, example)
    end
end

function GameRulesOverlay:_drawComparisonRow(frame, row)
    local colors = self.style.colors
    drawRoundedPanel({ 0.98, 0.94, 0.84, 0.98 }, { 0.72, 0.49, 0.25, 0.62 }, frame, 16)

    if row.stages then
        local stage_count = #row.stages
        local gap = 22
        local stage_width = math.floor((frame.width - 24 - gap * (stage_count - 1)) / stage_count)
        for index, stage in ipairs(row.stages) do
            local stage_frame = {
                x = frame.x + 12 + (index - 1) * (stage_width + gap),
                y = frame.y + 10,
                width = stage_width,
                height = frame.height - 20,
            }
            self:_drawExamplePanel(stage_frame, stage)
            if index < stage_count then
                drawGreaterThan(
                    self.fonts,
                    stage_frame.x + stage_frame.width,
                    stage_frame.y + math.floor(stage_frame.height * 0.22),
                    gap,
                    math.floor(stage_frame.height * 0.56),
                    colors,
                    nil
                )
            end
        end
        return
    end

    local left_frame = {
        x = frame.x + 14,
        y = frame.y + 10,
        width = math.floor(frame.width * 0.35),
        height = frame.height - 20,
    }
    local right_frame = {
        x = frame.x + frame.width - math.floor(frame.width * 0.35) - 14,
        y = left_frame.y,
        width = math.floor(frame.width * 0.35),
        height = left_frame.height,
    }

    self:_drawExamplePanel(left_frame, {
        title = row.left_label,
        note = "",
        cards = row.left_cards,
    })
    self:_drawExamplePanel(right_frame, {
        title = row.right_label,
        note = "",
        cards = row.right_cards,
    })

    local mid_x = math.floor(frame.x + frame.width * 0.5)
    drawGreaterThan(
        self.fonts,
        mid_x - 70,
        left_frame.y + math.floor(left_frame.height * 0.12),
        140,
        math.floor(left_frame.height * 0.76),
        colors,
        row.center_label or ""
    )
end

function GameRulesOverlay:_drawBeatPage(content, page)
    local gap = 10
    local start_y = content.y + 4
    local row_height = math.floor((content.height - (start_y - content.y) - gap * 2) / 3)
    for index, row in ipairs(page.rows or {}) do
        self:_drawComparisonRow({
            x = content.x,
            y = start_y + (index - 1) * (row_height + gap),
            width = content.width,
            height = row_height,
        }, row)
    end
end

function GameRulesOverlay:_drawWildcardPage(content, page)
    local colors = self.style.colors
    local hero_frame = {
        x = content.x,
        y = content.y,
        width = content.width,
        height = 136,
    }
    local example_top = hero_frame.y + hero_frame.height + 18
    local example_height = content.height - hero_frame.height - 18
    local left_frame = {
        x = content.x,
        y = example_top,
        width = math.floor((content.width - 18) * 0.56),
        height = example_height,
    }
    local right_frame = {
        x = left_frame.x + left_frame.width + 18,
        y = example_top,
        width = content.width - left_frame.width - 18,
        height = example_height,
    }

    drawRoundedPanel({ 0.98, 0.94, 0.84, 0.98 }, { 0.72, 0.49, 0.25, 0.62 }, hero_frame, 18)
    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print(page.hero.title or "", hero_frame.x + 134, hero_frame.y + 20)
    self.card_view:draw(
        page.hero.card,
        {
            x = hero_frame.x + 24,
            y = hero_frame.y + 14,
            width = 78,
            height = 108,
        },
        self:_resolveThemeConfig(),
        {
            selected = false,
            hovered = false,
            relation = "self",
        },
        self.fonts
    )

    self:_drawExamplePanel(left_frame, page.examples[1])
    self:_drawExamplePanel(right_frame, page.examples[2])
end

function GameRulesOverlay:_drawPromotionChip(frame, item)
    local colors = self.style.colors
    drawRoundedPanel({ 0.98, 0.94, 0.84, 0.98 }, { 0.72, 0.49, 0.25, 0.62 }, frame, 16)

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(item.order or "", frame.x, frame.y + 14, frame.width, "center")

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(item.gain or "", frame.x, frame.y + 48, frame.width, "center")
end

function GameRulesOverlay:_drawTributeFlowPanel(frame, title, note, left_cards, right_cards)
    local colors = self.style.colors
    drawRoundedPanel({ 0.98, 0.94, 0.84, 0.98 }, { 0.72, 0.49, 0.25, 0.62 }, frame, 16)

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(title or "", frame.x + 16, frame.y + 12, frame.width - 32, "left")

    local left_frame = {
        x = frame.x + 12,
        y = frame.y + 40,
        width = math.floor(frame.width * 0.38),
        height = frame.height - 52,
    }
    local right_frame = {
        x = frame.x + frame.width - math.floor(frame.width * 0.26) - 12,
        y = left_frame.y,
        width = math.floor(frame.width * 0.26),
        height = left_frame.height,
    }

    self:_drawCardStrip(left_cards or {}, left_frame)
    self:_drawCardStrip(right_cards or {}, right_frame)
    drawFlowArrow(left_frame.x + left_frame.width + 8, left_frame.y + left_frame.height * 0.5, right_frame.x - 8, right_frame.y + right_frame.height * 0.5, { 0.70, 0.42, 0.18, 0.98 })
end

function GameRulesOverlay:_drawLevelTributePage(content, page)
    local top_height = 138
    local top_gap = 16
    local promotion_width = math.floor((content.width - top_gap * 2) / 3)
    for index, item in ipairs(page.promotions or {}) do
        self:_drawPromotionChip({
            x = content.x + (index - 1) * (promotion_width + top_gap),
            y = content.y,
            width = promotion_width,
            height = top_height,
        }, item)
    end

    local lower_y = content.y + top_height + 18
    local lower_height = content.height - top_height - 18
    local left_width = math.floor(content.width * 0.68)
    local right_width = content.width - left_width - 18

    local top_row_height = math.floor((lower_height - 12) / 2)
    self:_drawTributeFlowPanel({
        x = content.x,
        y = lower_y,
        width = left_width,
        height = top_row_height,
    }, page.tribute_rows[1].title, page.tribute_rows[1].note, page.tribute_rows[1].left_cards, page.tribute_rows[1].right_cards)

    self:_drawTributeFlowPanel({
        x = content.x,
        y = lower_y + top_row_height + 12,
        width = left_width,
        height = lower_height - top_row_height - 12,
    }, page.tribute_rows[2].title, page.tribute_rows[2].note, page.tribute_rows[2].left_cards, page.tribute_rows[2].right_cards)

    self:_drawExamplePanel({
        x = content.x + left_width + 18,
        y = lower_y,
        width = right_width,
        height = lower_height,
    }, page.anti)
end

function GameRulesOverlay:_drawPageContent(page_index, text_scroll)
    local pages = buildPages()
    local page = pages[page_index] or pages[1]
    local colors = self.style.colors
    local content = self:getContentFrame()

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.printf(page.title or "", content.x, content.y - 48, content.width, "center")

    if page_index == 1 then
        self:_drawOverviewPage(content, page, 2)
        return
    end

    if page_index == 2 then
        self:_drawOverviewPage(content, page, 3)
        return
    end

    if page_index == 3 then
        self:_drawBeatPage(content, page)
        return
    end

    if page_index == 4 then
        self:_drawWildcardPage(content, page)
        return
    end

    if page.kind == "text" then
        self:_drawTextPage(content, page, text_scroll)
        return
    end

    self:_drawLevelTributePage(content, page)
end

function GameRulesOverlay:drawPageDots(panel, page_index, total_pages)
    local start_x = math.floor(panel.x + panel.width * 0.5 - ((total_pages - 1) * 22) * 0.5)
    local y = panel.y + 62
    for index = 1, total_pages do
        local active = index == page_index
        love.graphics.setColor(active and { 0.66, 0.39, 0.18, 0.96 } or { 0.65, 0.50, 0.34, 0.34 })
        love.graphics.circle("fill", start_x + (index - 1) * 22, y, active and 6 or 4)
    end
end

function GameRulesOverlay:draw(page_index, hovered_control, theme_config, text_scroll)
    local panel = self:getPanelFrame()
    local navigation = self:getNavigationFrames()
    local total_pages = self:getPageCount()
    local colors = self.style.colors
    self.current_card_theme_config = self:_resolveThemeConfig(theme_config)

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.wood_panel:draw(panel, { radius = 22, shadow_offset = 8 })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(I18n:t("main_menu.rules_title"), panel.x, panel.y + 18, panel.width, "center")
    self:drawPageDots(panel, page_index, total_pages)

    self:_drawPageContent(page_index, text_scroll)

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("lobby.prev_page"),
        x = navigation.prev.x,
        y = navigation.prev.y,
        width = navigation.prev.width,
        height = navigation.prev.height,
        hovered = hovered_control == "rules_prev",
        enabled = page_index > 1,
        variant = "secondary",
        font_token = "Text",
        radius = 14,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("lobby.next_page"),
        x = navigation.next.x,
        y = navigation.next.y,
        width = navigation.next.width,
        height = navigation.next.height,
        hovered = hovered_control == "rules_next",
        enabled = page_index < total_pages,
        variant = "primary",
        font_token = "Text",
        radius = 14,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(
        formatPageCounter(page_index, total_pages),
        navigation.counter.x,
        navigation.counter.y + math.floor((navigation.counter.height - self.fonts:get("TextSmall"):getHeight()) * 0.5) - 1,
        navigation.counter.width,
        "center"
    )

    self.close_button:draw(self:getCloseButtonFrame(), hovered_control == "rules_close")
end

return GameRulesOverlay
