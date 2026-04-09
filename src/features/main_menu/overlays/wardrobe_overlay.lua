local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local AccessoryRenderer = require("src.features.session.accessories.renderer")
local Catalog = require("src.features.session.accessories.catalog")
local I18n = require("src.core.i18n.i18n")
local IconCloseButton = require("src.core.ui.icon_close_button")
local WoodButton = require("src.core.ui.wood_button")
local WoodPanel = require("src.core.ui.wood_panel")

local WardrobeOverlay = {}
WardrobeOverlay.__index = WardrobeOverlay

local PAGE_SIZE = 8
local GRID_COLUMNS = 4
local GRID_ROWS = 2

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function contains(bounds, x, y)
    return x >= bounds.x and x <= bounds.x + bounds.width and y >= bounds.y and y <= bounds.y + bounds.height
end

local function safeText(value)
    if value == nil then
        return ""
    end
    return tostring(value)
end

local function copyEquipped(accessories)
    local equipped = ((accessories or {}).equipped) or accessories or {}
    return {
        frame = equipped.frame,
    }
end

local function copyAccessoriesWithFrame(accessories, marker)
    local owned_item_ids = {}
    for _, item_id in ipairs(((accessories or {}).owned_item_ids) or {}) do
        owned_item_ids[#owned_item_ids + 1] = item_id
    end

    local equipped = copyEquipped(accessories)
    equipped.frame = marker
    if marker == Catalog.NONE_MARKER then
        equipped.frame = nil
    end

    return {
        owned_item_ids = owned_item_ids,
        equipped = equipped,
    }
end

local function drawCoinPill(fonts, bounds, coins)
    love.graphics.setColor(0.44, 0.26, 0.13, 0.20)
    love.graphics.rectangle("fill", bounds.x + 2, bounds.y + 3, bounds.width, bounds.height, 14, 14)
    love.graphics.setColor(0.98, 0.93, 0.77, 0.98)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height, 14, 14)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.74, 0.48, 0.24, 0.86)
    love.graphics.rectangle("line", bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2, 14, 14)
    love.graphics.setLineWidth(1)

    local cx = bounds.x + 18
    local cy = bounds.y + 18
    love.graphics.setColor(0.98, 0.79, 0.24, 1)
    love.graphics.circle("fill", cx, cy, 10)
    love.graphics.setColor(1.0, 0.92, 0.56, 0.88)
    love.graphics.circle("fill", cx - 2, cy - 2, 4)

    love.graphics.setColor(0.46, 0.24, 0.14, 1)
    love.graphics.setFont(fonts:get("TextSmall"))
    love.graphics.printf(
        safeText(I18n:t("main_menu.wardrobe_coin_value", { coins = tonumber(coins) or 300 })),
        bounds.x + 34,
        bounds.y + 7,
        bounds.width - 42,
        "left"
    )
end

local function drawSoftPanel(bounds)
    love.graphics.setColor(0.98, 0.95, 0.86, 0.98)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height, 16, 16)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.82, 0.57, 0.32, 0.55)
    love.graphics.rectangle("line", bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2, 16, 16)
    love.graphics.setLineWidth(1)
end

local function drawFrameOnly(bounds, marker)
    local inner = {
        x = bounds.x + 8,
        y = bounds.y + 8,
        width = bounds.width - 16,
        height = bounds.height - 16,
    }
    local radius = 18

    love.graphics.setColor(1.0, 0.98, 0.93, 0.98)
    love.graphics.rectangle("fill", inner.x, inner.y, inner.width, inner.height, radius, radius)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.86, 0.72, 0.52, 0.34)
    love.graphics.rectangle("line", inner.x + 1, inner.y + 1, inner.width - 2, inner.height - 2, radius, radius)
    love.graphics.setLineWidth(1)

    if marker == Catalog.NONE_MARKER or marker == nil then
        love.graphics.setColor(0.70, 0.54, 0.33, 0.68)
        love.graphics.setLineWidth(2)
        for offset = 0, inner.width - 14, 12 do
            love.graphics.line(inner.x + 6 + offset, inner.y + 6, math.min(inner.x + 12 + offset, inner.x + inner.width - 6), inner.y + 6)
            love.graphics.line(inner.x + 6 + offset, inner.y + inner.height - 6, math.min(inner.x + 12 + offset, inner.x + inner.width - 6), inner.y + inner.height - 6)
        end
        for offset = 0, inner.height - 14, 12 do
            love.graphics.line(inner.x + 6, inner.y + 6 + offset, inner.x + 6, math.min(inner.y + 12 + offset, inner.y + inner.height - 6))
            love.graphics.line(inner.x + inner.width - 6, inner.y + 6 + offset, inner.x + inner.width - 6, math.min(inner.y + 12 + offset, inner.y + inner.height - 6))
        end
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.55, 0.36, 0.19, 0.84)
        love.graphics.setFont(love.graphics.getFont())
        return
    end

    AccessoryRenderer.drawFrame({
        x = inner.x + 2,
        y = inner.y + 2,
        w = inner.width - 4,
        h = inner.height - 4,
    }, marker)
end

local function drawCornerPill(fonts, bounds, label, variant)
    local palette = variant or "neutral"
    local fill = { 0.99, 0.93, 0.80, 0.96 }
    local line = { 0.74, 0.48, 0.24, 0.76 }
    local text = { 0.45, 0.27, 0.12, 1 }
    if palette == "primary" then
        fill = { 0.99, 0.89, 0.63, 0.98 }
        line = { 0.80, 0.38, 0.14, 0.92 }
    elseif palette == "price" then
        fill = { 0.95, 0.76, 0.28, 0.98 }
        line = { 0.78, 0.46, 0.10, 0.92 }
    end

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4])
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(line[1], line[2], line[3], line[4])
    love.graphics.rectangle("line", bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(text[1], text[2], text[3], text[4])
    love.graphics.setFont(fonts:get("TextSmall"))
    love.graphics.printf(safeText(label), bounds.x, bounds.y + 6, bounds.width, "center")
end

function WardrobeOverlay.new(options)
    local self = setmetatable({}, WardrobeOverlay)

    self.fonts = assert(options and options.fonts, "WardrobeOverlay requires fonts")
    self.style = assert(options and options.style, "WardrobeOverlay requires style")
    self.wood_panel = WoodPanel.new(self.style)
    self.close_button = IconCloseButton.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.avatars_by_id = {}

    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end

    return self
end

function WardrobeOverlay:getFrame()
    local width = clamp(love.graphics.getWidth() - 80, 1020, 1260)
    local height = clamp(love.graphics.getHeight() - 92, 620, 760)
    return {
        x = math.floor((love.graphics.getWidth() - width) * 0.5),
        y = math.floor((love.graphics.getHeight() - height) * 0.5),
        width = width,
        height = height,
    }
end

function WardrobeOverlay:getCloseBounds()
    local frame = self:getFrame()
    return {
        x = frame.x + frame.width - 56,
        y = frame.y + 16,
        width = 38,
        height = 38,
    }
end

function WardrobeOverlay:getCoinBounds()
    local frame = self:getFrame()
    return {
        x = frame.x + frame.width - 236,
        y = frame.y + 18,
        width = 156,
        height = 36,
    }
end

function WardrobeOverlay:getTabBounds(tab_id)
    local frame = self:getFrame()
    local width = 182
    local gap = 14
    local start_x = frame.x + 28
    local y = frame.y + 72
    if tab_id == "shop" then
        start_x = start_x + width + gap
    end
    return {
        x = start_x,
        y = y,
        width = width,
        height = 48,
    }
end

function WardrobeOverlay:getPreviewPanel()
    local frame = self:getFrame()
    local y = frame.y + 132
    return {
        x = frame.x + 28,
        y = y,
        width = 286,
        height = frame.height - (y - frame.y) - 28,
    }
end

function WardrobeOverlay:getGridPanel()
    local frame = self:getFrame()
    local preview = self:getPreviewPanel()
    local x = preview.x + preview.width + 18
    return {
        x = x,
        y = preview.y,
        width = frame.x + frame.width - x - 28,
        height = preview.height,
    }
end

function WardrobeOverlay:getActionBounds()
    local panel = self:getPreviewPanel()
    return {
        x = panel.x + 24,
        y = panel.y + panel.height - 70,
        width = panel.width - 48,
        height = 48,
    }
end

function WardrobeOverlay:getPageButtonBounds(direction)
    local panel = self:getGridPanel()
    local width = 124
    local gap = 14
    local y = panel.y + panel.height - 70
    if direction == "prev" then
        return {
            x = panel.x + panel.width - width * 2 - gap - 20,
            y = y,
            width = width,
            height = 46,
        }
    end
    return {
        x = panel.x + panel.width - width - 20,
        y = y,
        width = width,
        height = 46,
    }
end

function WardrobeOverlay:getCardBounds(index_on_page)
    local panel = self:getGridPanel()
    local content_x = panel.x + 18
    local content_y = panel.y + 18
    local content_w = panel.width - 36
    local content_h = panel.height - 108
    local gap_x = 16
    local gap_y = 16
    local card_w = math.floor((content_w - gap_x * (GRID_COLUMNS - 1)) / GRID_COLUMNS)
    local card_h = math.floor((content_h - gap_y * (GRID_ROWS - 1)) / GRID_ROWS)
    local col = (index_on_page - 1) % GRID_COLUMNS
    local row = math.floor((index_on_page - 1) / GRID_COLUMNS)
    return {
        x = content_x + col * (card_w + gap_x),
        y = content_y + row * (card_h + gap_y),
        width = card_w,
        height = card_h,
    }
end

function WardrobeOverlay:buildRows(state, user_profile)
    local tab = state.wardrobe_tab or "equipment"
    local items = Catalog:getSlotItems("frame")
    local accessories = (user_profile and user_profile.accessories) or { owned_item_ids = {}, equipped = {} }
    local owned_lookup = {}
    for _, item_id in ipairs(accessories.owned_item_ids or {}) do
        owned_lookup[item_id] = true
    end
    local equipped = copyEquipped(accessories)
    local rows = {}

    if tab == "equipment" then
        rows[#rows + 1] = {
            marker = Catalog.NONE_MARKER,
            item_id = nil,
            title = I18n:t("main_menu.wardrobe_item_none"),
            desc = I18n:t("main_menu.wardrobe_desc_none"),
            price = nil,
            owned = true,
            equipped = equipped.frame == nil,
            animated = false,
        }
        for _, item in ipairs(items) do
            if owned_lookup[item.item_id] then
                rows[#rows + 1] = {
                    marker = item.item_id,
                    item_id = item.item_id,
                    title = item.title,
                    desc = item.desc,
                    price = item.price,
                    owned = true,
                    equipped = equipped.frame == item.item_id,
                    animated = item.animated == true,
                }
            end
        end
    else
        for _, item in ipairs(items) do
            rows[#rows + 1] = {
                marker = item.item_id,
                item_id = item.item_id,
                title = item.title,
                desc = item.desc,
                price = item.price,
                owned = owned_lookup[item.item_id] == true,
                equipped = equipped.frame == item.item_id,
                animated = item.animated == true,
            }
        end
    end

    return rows
end

function WardrobeOverlay:getPagedRows(state, user_profile)
    local rows = self:buildRows(state, user_profile)
    local total = #rows
    local page_count = math.max(1, math.ceil(total / PAGE_SIZE))
    local page_index = clamp(tonumber(state.wardrobe_page_index) or 1, 1, page_count)
    local start_index = (page_index - 1) * PAGE_SIZE + 1
    local visible = {}
    for index = start_index, math.min(total, start_index + PAGE_SIZE - 1) do
        visible[#visible + 1] = rows[index]
    end
    return visible, page_count, page_index, rows
end

function WardrobeOverlay:getSelectedRow(state, user_profile)
    local selected = state.wardrobe_selected_item_id
    for _, row in ipairs(self:buildRows(state, user_profile)) do
        if row.marker == selected then
            return row
        end
    end
    return nil
end

function WardrobeOverlay:getControlAt(x, y, state, user_profile)
    if contains(self:getCloseBounds(), x, y) then
        return "wardrobe_close"
    end
    if contains(self:getTabBounds("equipment"), x, y) then
        return "wardrobe_tab_equipment"
    end
    if contains(self:getTabBounds("shop"), x, y) then
        return "wardrobe_tab_shop"
    end
    if contains(self:getPageButtonBounds("prev"), x, y) then
        return "wardrobe_prev_page"
    end
    if contains(self:getPageButtonBounds("next"), x, y) then
        return "wardrobe_next_page"
    end
    local visible_rows = self:getPagedRows(state, user_profile)
    for index, row in ipairs(visible_rows) do
        if contains(self:getCardBounds(index), x, y) then
            return "wardrobe_card_" .. row.marker
        end
    end
    if contains(self:getActionBounds(), x, y) then
        return "wardrobe_action"
    end
    return nil
end

function WardrobeOverlay:getActionState(state, user_profile)
    local selected = self:getSelectedRow(state, user_profile)
    if not selected then
        return I18n:t("main_menu.wardrobe_pick_hint"), false
    end

    if (state.wardrobe_tab or "equipment") == "shop" then
        if selected.equipped then
            return I18n:t("main_menu.wardrobe_badge_equipped"), false
        end
        if selected.owned then
            return I18n:t("main_menu.wardrobe_equip"), true
        end
        return I18n:t("main_menu.wardrobe_buy"), true
    end

    if selected.marker == Catalog.NONE_MARKER then
        if selected.equipped then
            return I18n:t("main_menu.wardrobe_badge_equipped"), false
        end
        return I18n:t("main_menu.wardrobe_unequip"), true
    end

    if selected.equipped then
        return I18n:t("main_menu.wardrobe_badge_equipped"), false
    end
    return I18n:t("main_menu.wardrobe_equip"), true
end

local function drawPreviewCard(style, fonts, colors, row, bounds, avatar, accessories)
    drawSoftPanel(bounds)

    local preview_h = math.floor(bounds.height * 0.68)
    local preview_bounds = {
        x = bounds.x + 22,
        y = bounds.y + 14,
        width = bounds.width - 44,
        height = preview_h - 18,
    }

    if avatar then
        AvatarTile.draw(style, avatar, {
            x = preview_bounds.x,
            y = preview_bounds.y,
            w = preview_bounds.width,
            h = preview_bounds.height,
        }, {
            preview = true,
            selected = true,
            accessories = accessories,
            content_padding_ratio = 0.03,
        })
    else
        drawFrameOnly(preview_bounds, row.marker)
    end

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(fonts:get("Text"))
    love.graphics.printf(safeText(row.title), bounds.x + 14, bounds.y + preview_h + 2, bounds.width - 28, "center")

    love.graphics.setColor(colors.text_muted)
    love.graphics.setFont(fonts:get("Caption"))
    love.graphics.printf(safeText(row.desc), bounds.x + 16, bounds.y + preview_h + 26, bounds.width - 32, "center")
end

function WardrobeOverlay:draw(state, user_profile)
    local colors = self.style.colors
    local frame = self:getFrame()
    local preview_panel = self:getPreviewPanel()
    local grid_panel = self:getGridPanel()
    local visible_rows, page_count, page_index = self:getPagedRows(state, user_profile)
    local selected_row = self:getSelectedRow(state, user_profile)
    local action_label, action_enabled = self:getActionState(state, user_profile)
    local preview_avatar = self.avatars_by_id[(user_profile and user_profile.avatar_id) or "avatar_1"] or AvatarRegistry[1]

    love.graphics.setColor(colors.overlay)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    self.wood_panel:draw(frame, { radius = 22, shadow_offset = 10 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.printf(safeText(I18n:t("main_menu.wardrobe_title")), frame.x, frame.y + 14, frame.width, "center")

    drawCoinPill(self.fonts, self:getCoinBounds(), (user_profile and user_profile.coins) or 300)

    for _, tab_id in ipairs({ "equipment", "shop" }) do
        local active = (state.wardrobe_tab or "equipment") == tab_id
        local key = tab_id == "equipment" and "main_menu.wardrobe_tab_equipment" or "main_menu.wardrobe_tab_shop"
        local bounds = self:getTabBounds(tab_id)
        WoodButton.draw(self.fonts, self.style, {
            label = safeText(I18n:t(key)),
            x = bounds.x,
            y = bounds.y,
            width = bounds.width,
            height = bounds.height,
            hovered = state.hovered_wardrobe_control == ("wardrobe_tab_" .. tab_id),
            enabled = true,
            variant = active and "primary" or "secondary",
            font_token = "Text",
            radius = 12,
        })
    end

    self.wood_panel:draw(preview_panel, { radius = 18, shadow_offset = 6, inner_inset = 8 })
    self.wood_panel:draw(grid_panel, { radius = 18, shadow_offset = 6, inner_inset = 8 })

    love.graphics.setColor(colors.text_primary)
    love.graphics.setFont(self.fonts:get("TextBig"))
    love.graphics.print(safeText(I18n:t("main_menu.wardrobe_preview_title")), preview_panel.x + 20, preview_panel.y + 18)

    if selected_row then
        local preview_bounds = {
            x = preview_panel.x + 32,
            y = preview_panel.y + 58,
            width = preview_panel.width - 64,
            height = 286,
        }
        drawPreviewCard(
            self.style,
            self.fonts,
            colors,
            selected_row,
            preview_bounds,
            preview_avatar,
            copyAccessoriesWithFrame((user_profile or {}).accessories, selected_row.marker)
        )

        if (state.wardrobe_tab or "equipment") == "shop" and not selected_row.owned and selected_row.price then
            drawCornerPill(self.fonts, {
                x = preview_panel.x + 92,
                y = preview_panel.y + 362,
                width = preview_panel.width - 184,
                height = 34,
            }, I18n:t("main_menu.wardrobe_price_short", { price = selected_row.price }), "price")
        elseif selected_row.equipped then
            drawCornerPill(self.fonts, {
                x = preview_panel.x + 104,
                y = preview_panel.y + 362,
                width = preview_panel.width - 208,
                height = 34,
            }, I18n:t("main_menu.wardrobe_badge_equipped"), "primary")
        end
    else
        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Text"))
        love.graphics.printf(safeText(I18n:t("main_menu.wardrobe_empty")), preview_panel.x + 24, preview_panel.y + 110, preview_panel.width - 48, "center")
    end

    for index, row in ipairs(visible_rows) do
        local bounds = self:getCardBounds(index)
        local selected = state.wardrobe_selected_item_id == row.marker

        love.graphics.setColor(selected and 0.995 or 0.985, selected and 0.91 or 0.955, selected and 0.78 or 0.89, 0.98)
        love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height, 16, 16)
        love.graphics.setLineWidth(selected and 3 or 2)
        if selected then
            love.graphics.setColor(0.82, 0.36, 0.14, 0.95)
        else
            love.graphics.setColor(0.74, 0.48, 0.24, 0.44)
        end
        love.graphics.rectangle("line", bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2, 16, 16)
        love.graphics.setLineWidth(1)

        local preview_h = math.floor(bounds.height * 0.66)
        local preview_bounds = {
            x = bounds.x + 12,
            y = bounds.y + 12,
            width = bounds.width - 24,
            height = preview_h - 10,
        }
        drawFrameOnly(preview_bounds, row.marker)

        love.graphics.setColor(colors.text_primary)
        love.graphics.setFont(self.fonts:get("TextSmall"))
        love.graphics.printf(safeText(row.title), bounds.x + 12, bounds.y + preview_h + 2, bounds.width - 24, "center")

        love.graphics.setColor(colors.text_muted)
        love.graphics.setFont(self.fonts:get("Label"))
        love.graphics.printf(safeText(row.desc), bounds.x + 16, bounds.y + preview_h + 22, bounds.width - 32, "center")

        if row.equipped then
            drawCornerPill(self.fonts, {
                x = bounds.x + bounds.width - 78,
                y = bounds.y + 12,
                width = 66,
                height = 28,
            }, I18n:t("main_menu.wardrobe_badge_equipped"), "primary")
        elseif (state.wardrobe_tab or "equipment") == "shop" and not row.owned and row.price then
            drawCornerPill(self.fonts, {
                x = bounds.x + bounds.width - 68,
                y = bounds.y + 12,
                width = 56,
                height = 28,
            }, tostring(row.price), "price")
        end
    end

    local prev_bounds = self:getPageButtonBounds("prev")
    local next_bounds = self:getPageButtonBounds("next")
    WoodButton.draw(self.fonts, self.style, {
        label = safeText(I18n:t("main_menu.wardrobe_prev_page")),
        x = prev_bounds.x,
        y = prev_bounds.y,
        width = prev_bounds.width,
        height = prev_bounds.height,
        hovered = state.hovered_wardrobe_control == "wardrobe_prev_page",
        enabled = page_index > 1,
        variant = "secondary",
        font_token = "TextSmall",
        radius = 12,
    })
    WoodButton.draw(self.fonts, self.style, {
        label = safeText(I18n:t("main_menu.wardrobe_next_page")),
        x = next_bounds.x,
        y = next_bounds.y,
        width = next_bounds.width,
        height = next_bounds.height,
        hovered = state.hovered_wardrobe_control == "wardrobe_next_page",
        enabled = page_index < page_count,
        variant = "secondary",
        font_token = "TextSmall",
        radius = 12,
    })

    WoodButton.draw(self.fonts, self.style, {
        label = safeText(action_label),
        x = self:getActionBounds().x,
        y = self:getActionBounds().y,
        width = self:getActionBounds().width,
        height = self:getActionBounds().height,
        hovered = state.hovered_wardrobe_control == "wardrobe_action",
        enabled = action_enabled and state.wardrobe_busy ~= true,
        variant = "primary",
        font_token = "Text",
        radius = 12,
    })

    love.graphics.setColor(colors.text_secondary)
    love.graphics.setFont(self.fonts:get("TextSmall"))
    love.graphics.printf(
        tostring(state.wardrobe_message or ""),
        preview_panel.x + 18,
        preview_panel.y + preview_panel.height - 110,
        preview_panel.width - 36,
        "center"
    )

    self.close_button:draw(self:getCloseBounds(), state.hovered_wardrobe_control == "wardrobe_close")
end

return WardrobeOverlay
