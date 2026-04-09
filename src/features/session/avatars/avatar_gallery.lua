local I18n = require("src.core.i18n.i18n")
local AvatarGallery = {}
AvatarGallery.__index = AvatarGallery

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function ceilDiv(a, b)
    return math.floor((a + b - 1) / b)
end

local function isAvatarModule(value)
    return type(value) == "table" and type(value.draw) == "function"
end

local function normalizeAvatarList(source)
    if type(source) ~= "table" then
        return {}
    end

    local ordered = {}
    for key, value in pairs(source) do
        if isAvatarModule(value) then
            ordered[#ordered + 1] = {
                order = tonumber(key) or math.huge,
                key = key,
                avatar = value,
            }
        end
    end

    table.sort(ordered, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return tostring(a.key) < tostring(b.key)
    end)

    local avatars = {}
    for index, item in ipairs(ordered) do
        avatars[index] = item.avatar
    end
    return avatars
end

local function loadAvatars()
    local avatars = {}

    local okDefinitions, definitions = pcall(require, "src.features.session.avatars.avatar_definitions")
    if okDefinitions then
        avatars = normalizeAvatarList(definitions)
    end

    if #avatars > 0 then
        return avatars
    end

    local missCount = 0
    for i = 1, 99 do
        local okAvatar, avatar = pcall(require, string.format("src.features.session.avatars.avatar_%d", i))
        if okAvatar and isAvatarModule(avatar) then
            avatars[#avatars + 1] = avatar
            missCount = 0
        else
            missCount = missCount + 1
            if missCount >= 8 and #avatars > 0 then
                break
            end
        end
    end

    return avatars
end

local function pointInRect(px, py, rect)
    return px >= rect.x
        and px <= rect.x + rect.w
        and py >= rect.y
        and py <= rect.y + rect.h
end

function AvatarGallery.new(options)
    options = options or {}

    local self = setmetatable({}, AvatarGallery)
    self.title = options.title or "头像展示"
    self.avatars = options.avatars or loadAvatars()
    self.columns = options.columns or 4
    self.rows = options.rows or 2
    self.cardPadding = options.cardPadding or 14
    self.page = 1
    self.selectedIndex = 1
    self.hoveredIndex = nil
    self.prevButtonRect = nil
    self.nextButtonRect = nil
    self.avatarRects = {}
    self.backgroundAlpha = options.backgroundAlpha or 0.94
    return self
end

function AvatarGallery:getItemsPerPage()
    return self.columns * self.rows
end

function AvatarGallery:getAvatarCount()
    return #self.avatars
end

function AvatarGallery:getPageCount()
    local count = self:getAvatarCount()
    if count == 0 then
        return 1
    end
    return ceilDiv(count, self:getItemsPerPage())
end

function AvatarGallery:getSelectedAvatar()
    return self.avatars[self.selectedIndex], self.selectedIndex
end

function AvatarGallery:setPage(page)
    self.page = clamp(page, 1, self:getPageCount())
end

function AvatarGallery:nextPage()
    self:setPage(self.page + 1)
end

function AvatarGallery:prevPage()
    self:setPage(self.page - 1)
end

function AvatarGallery:selectAvatar(index)
    if index < 1 or index > #self.avatars then
        return
    end

    self.selectedIndex = index
    local targetPage = ceilDiv(index, self:getItemsPerPage())
    self:setPage(targetPage)
end

function AvatarGallery:keypressed(key)
    if key == "right" or key == "d" then
        self:nextPage()
        return true
    end

    if key == "left" or key == "a" then
        self:prevPage()
        return true
    end

    if key == "down" or key == "s" then
        self:selectAvatar(math.min(#self.avatars, self.selectedIndex + self.columns))
        return true
    end

    if key == "up" or key == "w" then
        self:selectAvatar(math.max(1, self.selectedIndex - self.columns))
        return true
    end

    if key == "pageup" then
        self:prevPage()
        return true
    end

    if key == "pagedown" then
        self:nextPage()
        return true
    end

    return false
end

function AvatarGallery:wheelmoved(_, y)
    if y > 0 then
        self:prevPage()
        return true
    end

    if y < 0 then
        self:nextPage()
        return true
    end

    return false
end

function AvatarGallery:mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end

    if self.prevButtonRect and pointInRect(x, y, self.prevButtonRect) then
        self:prevPage()
        return true
    end

    if self.nextButtonRect and pointInRect(x, y, self.nextButtonRect) then
        self:nextPage()
        return true
    end

    for _, item in ipairs(self.avatarRects) do
        if pointInRect(x, y, item.rect) then
            self:selectAvatar(item.index)
            return true
        end
    end

    return false
end

function AvatarGallery:mousemoved(x, y)
    self.hoveredIndex = nil
    for _, item in ipairs(self.avatarRects) do
        if pointInRect(x, y, item.rect) then
            self.hoveredIndex = item.index
            return true
        end
    end
    return false
end

local function drawRoundRect(mode, x, y, w, h, radius)
    love.graphics.rectangle(mode, x, y, w, h, radius, radius)
end

local function drawCenteredText(text, x, y, w)
    love.graphics.printf(text, x, y, w, "center")
end

function AvatarGallery:draw(bounds)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    bounds = bounds or {
        x = 24,
        y = 24,
        w = screenW - 48,
        h = screenH - 48,
    }

    self.avatarRects = {}

    local x = bounds.x
    local y = bounds.y
    local w = bounds.w
    local h = bounds.h

    love.graphics.setColor(0.08, 0.10, 0.14, self.backgroundAlpha)
    drawRoundRect("fill", x, y, w, h, 18)

    love.graphics.setColor(0.24, 0.28, 0.36, 1)
    drawRoundRect("line", x, y, w, h, 18)

    love.graphics.setColor(0.95, 0.97, 1.0, 1)
    love.graphics.print(self.title, x + 24, y + 20)

    local avatarCount = self:getAvatarCount()
    local pageCount = self:getPageCount()
    self.page = clamp(self.page, 1, pageCount)
    self.selectedIndex = clamp(self.selectedIndex, 1, math.max(1, avatarCount))

    local summaryText = string.format("第 %d / %d 页   共 %d 个头像", self.page, pageCount, avatarCount)
    love.graphics.setColor(0.78, 0.82, 0.90, 1)
    drawCenteredText(summaryText, x, y + 20, w)

    local topArea = 82
    local bottomArea = 72
    local innerPadding = 24
    local gridX = x + innerPadding
    local gridY = y + topArea
    local gridW = w - innerPadding * 2
    local gridH = h - topArea - bottomArea

    if avatarCount == 0 then
        love.graphics.setColor(0.88, 0.40, 0.40, 1)
        drawCenteredText("没有加载到头像，请检查 avatar_definitions 或 avatar_1~K 文件。", gridX, gridY + gridH / 2 - 8, gridW)
        return
    end

    local gap = 14
    local cardW = (gridW - gap * (self.columns - 1)) / self.columns
    local cardH = (gridH - gap * (self.rows - 1)) / self.rows

    local startIndex = (self.page - 1) * self:getItemsPerPage() + 1
    local endIndex = math.min(avatarCount, startIndex + self:getItemsPerPage() - 1)

    for index = startIndex, endIndex do
        local localIndex = index - startIndex
        local col = localIndex % self.columns
        local row = math.floor(localIndex / self.columns)

        local cardX = gridX + col * (cardW + gap)
        local cardY = gridY + row * (cardH + gap)
        local rect = { x = cardX, y = cardY, w = cardW, h = cardH }
        self.avatarRects[#self.avatarRects + 1] = { index = index, rect = rect }

        local isSelected = index == self.selectedIndex
        local isHovered = index == self.hoveredIndex

        -- 1. 绘制整个卡片的底色
        if isSelected then
            love.graphics.setColor(0.22, 0.42, 0.78, 0.32)
        elseif isHovered then
            love.graphics.setColor(0.24, 0.28, 0.34, 0.90)
        else
            love.graphics.setColor(0.16, 0.18, 0.22, 0.92)
        end
        drawRoundRect("fill", cardX, cardY, cardW, cardH, 14)

        -- 2. 绘制整个卡片的边框
        if isSelected then
            love.graphics.setColor(0.46, 0.72, 1.00, 1)
        else
            love.graphics.setColor(0.30, 0.34, 0.42, 1)
        end
        drawRoundRect("line", cardX, cardY, cardW, cardH, 14)

        local avatar = self.avatars[index]
        local previewPadding = self.cardPadding
        local labelHeight = 28
        local previewBounds = {
            x = cardX + previewPadding,
            y = cardY + previewPadding,
            w = cardW - previewPadding * 2,
            h = cardH - previewPadding * 2 - labelHeight,
        }

        -- =======================================================
        -- 新增：为真正显示头像的区域添加内部背景框和专属外边框
        -- =======================================================
        
        -- 头像区域的底色 (稍暗一些的背景框)
        love.graphics.setColor(0.10, 0.12, 0.16, 1)
        drawRoundRect("fill", previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h, 8)

        -- 头像区域的专属边框
        if isSelected then
            love.graphics.setColor(0.55, 0.80, 1.00, 0.8) -- 选中时头像框也跟着高亮
        else
            love.graphics.setColor(0.28, 0.32, 0.40, 1)   -- 正常的头像边框颜色
        end
        drawRoundRect("line", previewBounds.x, previewBounds.y, previewBounds.w, previewBounds.h, 8)
        
        -- =======================================================

        -- 3. 绘制头像
        if avatar and type(avatar.draw) == "function" then
            local ok = pcall(avatar.draw, previewBounds)
            if not ok then
                love.graphics.setColor(0.86, 0.36, 0.36, 1)
                drawCenteredText("draw 失败", cardX, cardY + cardH / 2 - 8, cardW)
            end
        end

        -- 4. 绘制文字标签
        local label = avatar.id or string.format("avatar_%d", index)
        love.graphics.setColor(0.90, 0.93, 0.98, 1)
        drawCenteredText(label, cardX, cardY + cardH - 28, cardW)
    end

    local buttonY = y + h - 52
    local buttonW = 120
    local buttonH = 36
    local centerX = x + w / 2

    self.prevButtonRect = {
        x = centerX - buttonW - 10,
        y = buttonY,
        w = buttonW,
        h = buttonH,
    }
    self.nextButtonRect = {
        x = centerX + 10,
        y = buttonY,
        w = buttonW,
        h = buttonH,
    }

    local function drawButton(rect, text, enabled)
        if enabled then
            love.graphics.setColor(0.20, 0.24, 0.30, 1)
        else
            love.graphics.setColor(0.12, 0.13, 0.16, 1)
        end
        drawRoundRect("fill", rect.x, rect.y, rect.w, rect.h, 10)

        if enabled then
            love.graphics.setColor(0.46, 0.52, 0.64, 1)
        else
            love.graphics.setColor(0.24, 0.26, 0.32, 1)
        end
        drawRoundRect("line", rect.x, rect.y, rect.w, rect.h, 10)

        if enabled then
            love.graphics.setColor(0.95, 0.97, 1.0, 1)
        else
            love.graphics.setColor(0.50, 0.54, 0.62, 1)
        end
        drawCenteredText(text, rect.x, rect.y + 10, rect.w)
    end

    drawButton(self.prevButtonRect, I18n:t("lobby.prev_page"), self.page > 1)
    drawButton(self.nextButtonRect, I18n:t("lobby.next_page"), self.page < pageCount)

    love.graphics.setColor(0.72, 0.76, 0.84, 1)
    drawCenteredText(I18n:t("session.avatar_gallery_hint"), x, y + h - 22, w)
end

return AvatarGallery
