local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

local LobbyHallBackground = require("src.core.backgrounds.presets.lobby_hall_background")
local BackgroundThemeCatalog = require("src.core.backgrounds.themes.background_theme_catalog")
local SpringTableBackground = require("src.core.backgrounds.themes.spring_table_background")
local SummerTableBackground = require("src.core.backgrounds.themes.summer_table_background")
local AutumnTableBackground = require("src.core.backgrounds.themes.autumn_table_background")
local WinterTableBackground = require("src.core.backgrounds.themes.winter_table_background")
local CosmosTableBackground = require("src.core.backgrounds.themes.cosmos_table_background")
local NebulaTableBackground = require("src.core.backgrounds.themes.nebula_table_background")
local GalaxyTableBackground = require("src.core.backgrounds.themes.galaxy_table_background")
local WarpTableBackground = require("src.core.backgrounds.themes.warp_table_background")

local SEASON_THEME_IDS = {
    "spring",
    "summer",
    "autumn",
    "winter",
}

local PREVIEW_THEME_OPTIONS = {
    spring = { preview = true },
    summer = { preview = true },
    autumn = { preview = true },
    winter = { preview = true },
    cosmos = { preview = true },
    nebula = { preview = true },
    galaxy = { preview = true },
    warp = { preview = true },
}

local function drawDiagonalPattern(width, height, color, spacing, line_width, offset)
    love.graphics.setColor(color)
    love.graphics.setLineWidth(line_width or 1)

    local start = -height + (offset or 0)
    local finish = width + height
    local step = spacing or 80

    for x = start, finish, step do
        love.graphics.line(x, 0, x + height, height)
    end
end

local function drawDotGrid(width, height, color, spacing, radius)
    love.graphics.setColor(color)

    local step = spacing or 72
    local dot_radius = radius or 2
    for x = step * 0.5, width, step do
        for y = step * 0.5, height, step do
            love.graphics.circle("fill", x, y, dot_radius)
        end
    end
end

local function drawSoftBands(width, height, color, band_height)
    love.graphics.setColor(color)
    local size = band_height or 120
    for y = 0, height, size * 2 do
        love.graphics.rectangle("fill", 0, y, width, size)
    end
end

local function cloneTable(source, visited)
    if type(source) ~= "table" then
        return source
    end

    visited = visited or {}
    if visited[source] then
        return visited[source]
    end

    local target = {}
    visited[source] = target
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = cloneTable(value, visited)
        else
            target[key] = value
        end
    end

    return target
end

local function getThemeInitOptions(theme_id, context)
    if context == "preview" then
        return cloneTable(PREVIEW_THEME_OPTIONS[theme_id])
    end
    return nil
end

local function createThemeInstance(prototype, options)
    local instance = cloneTable(prototype)
    if instance.init then
        instance:init(cloneTable(options))
    end
    return instance
end

local function createThemeSnapshot(theme)
    if not theme then
        return nil
    end
    return cloneTable(theme)
end

local function ensureThemeCellLayout(theme, cell_w, cell_h)
    if not theme then
        return
    end

    local base_scale = theme._base_scale or theme.scale or 1
    theme._base_scale = base_scale

    local pattern_size = tonumber(theme.patternSize) or 480
    local required_scale = math.max(cell_w / pattern_size, cell_h / pattern_size)
    local safe_scale = math.max(base_scale, required_scale)

    local size_changed = (theme._menu_cell_w ~= cell_w) or (theme._menu_cell_h ~= cell_h)
    local scale_changed = theme.scale ~= safe_scale
    if scale_changed then
        theme.scale = safe_scale
    end

    if (size_changed or scale_changed) and theme.resize then
        theme:resize(cell_w, cell_h)
    end

    theme._menu_cell_w = cell_w
    theme._menu_cell_h = cell_h
end

local function ensureThemePreviewLayout(theme, cell_w, cell_h)
    if not theme then
        return
    end

    local base_scale = theme._base_scale or theme.scale or 1
    theme._base_scale = base_scale

    local pattern_size = tonumber(theme.patternSize) or 480
    local required_scale = math.min(cell_w / pattern_size, cell_h / pattern_size)
    local safe_scale = required_scale

    local size_changed = (theme._menu_cell_w ~= cell_w) or (theme._menu_cell_h ~= cell_h)
    local scale_changed = theme.scale ~= safe_scale
    if scale_changed then
        theme.scale = safe_scale
    end

    if (size_changed or scale_changed) and theme.resize then
        theme:resize(cell_w, cell_h)
    end

    theme._menu_cell_w = cell_w
    theme._menu_cell_h = cell_h
end

local function ensureThemeFullscreenLayout(theme, width, height)
    if not theme then
        return
    end

    local base_scale = theme._base_scale or theme.scale or 1
    theme._base_scale = base_scale

    local pattern_size = tonumber(theme.patternSize) or 480
    local required_scale = math.max(width / pattern_size, height / pattern_size)
    local safe_scale = math.max(base_scale, math.ceil(required_scale))

    local size_changed = (theme._fullscreen_w ~= width) or (theme._fullscreen_h ~= height)
    local scale_changed = theme.scale ~= safe_scale
    if scale_changed then
        theme.scale = safe_scale
    end

    if (size_changed or scale_changed) and theme.resize then
        theme:resize(width, height)
    end

    theme._fullscreen_w = width
    theme._fullscreen_h = height
end

local function buildSeasonCells(themes, width, height)
    local half_width = math.floor(width * 0.5)
    local half_height = math.floor(height * 0.5)

    return {
        { theme = themes[1], x = 0, y = 0, w = half_width, h = half_height },
        { theme = themes[2], x = half_width, y = 0, w = width - half_width, h = half_height },
        { theme = themes[3], x = 0, y = half_height, w = half_width, h = height - half_height },
        { theme = themes[4], x = half_width, y = half_height, w = width - half_width, h = height - half_height },
    }, half_width, half_height
end

local function resolveSeasonCellAt(width, height, x, y)
    local half_width = math.floor(width * 0.5)
    local half_height = math.floor(height * 0.5)
    local on_right = x >= half_width
    local on_bottom = y >= half_height

    if not on_right and not on_bottom then
        return 1
    end
    if on_right and not on_bottom then
        return 2
    end
    if not on_right and on_bottom then
        return 3
    end
    return 4
end

local function drawLayoutTransitionOverlay(manager, width, height)
    local transition_alpha = manager:getLayoutTransitionAlpha()
    if transition_alpha <= 0 then
        return
    end
    love.graphics.setColor(0, 0, 0, 0.55 * transition_alpha)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(1, 1, 1, 1)
end

function BackgroundManager.new()
    local self = setmetatable({}, BackgroundManager)

    self.background_theme_entries = {
        { id = "spring", prototype = SpringTableBackground },
        { id = "summer", prototype = SummerTableBackground },
        { id = "autumn", prototype = AutumnTableBackground },
        { id = "winter", prototype = WinterTableBackground },
        { id = "cosmos", prototype = CosmosTableBackground },
        { id = "nebula", prototype = NebulaTableBackground },
        { id = "galaxy", prototype = GalaxyTableBackground },
        { id = "warp", prototype = WarpTableBackground },
    }
    self.background_theme_prototypes = {}
    self.background_theme_by_id = {}
    self.preview_themes = {}
    self.fullscreen_preview_themes = {}
    for _, entry in ipairs(self.background_theme_entries) do
        self.background_theme_prototypes[#self.background_theme_prototypes + 1] = entry.prototype
        self.background_theme_by_id[entry.id] = entry.prototype
    end

    self.main_menu_themes = {
        createThemeInstance(SpringTableBackground),
        createThemeInstance(SummerTableBackground),
        createThemeInstance(AutumnTableBackground),
        createThemeInstance(WinterTableBackground),
    }
    self.main_menu_theme_ids = cloneTable(SEASON_THEME_IDS)
    self.background_layout_mode = "grid"
    self.layout_transition = {
        active = false,
        elapsed = 0,
        duration = 0.36,
        midpoint_applied = false,
        target_mode = nil,
        target_theme_id = nil,
    }
    self.gameplay_theme = nil
    self.gameplay_theme_id = nil

    self.presets = {
        GameWelcomeBG = function(width, height)
            -- Bright sky background for the welcome page.
            love.graphics.clear(0.35, 0.67, 0.93, 1)
            love.graphics.setColor(0.33, 0.66, 0.92, 1)
            love.graphics.rectangle("fill", 0, 0, width, height * 0.55)
            love.graphics.setColor(0.24, 0.58, 0.90, 1)
            love.graphics.rectangle("fill", 0, height * 0.55, width, height * 0.45)

            local t = 0
            if love.timer and love.timer.getTime then
                t = love.timer.getTime()
            end

            local function cloud(cx, cy, scale, phase, drift_amp, bob_amp)
                local r = 18 * scale
                local drift = math.sin(t * 0.15 + phase) * drift_amp
                local bob = math.sin(t * 0.52 + phase * 1.3) * bob_amp
                local x = cx + drift
                local y = cy + bob

                -- Soft shadow to add depth while keeping cloud body clean.
                love.graphics.setColor(0.74, 0.84, 0.94, 0.35)
                love.graphics.ellipse("fill", x + r * 0.25, y + r * 0.7, r * 2.0, r * 0.6)

                -- Opaque cloud body avoids visible overlap tint seams.
                love.graphics.setColor(0.98, 0.99, 1.0, 1.0)
                love.graphics.circle("fill", x - r * 0.9, y, r * 0.95)
                love.graphics.circle("fill", x, y - r * 0.45, r * 1.1)
                love.graphics.circle("fill", x + r, y, r)
                love.graphics.circle("fill", x + r * 1.9, y + r * 0.05, r * 0.82)
                love.graphics.rectangle("fill", x - r * 1.4, y, r * 3.2, r * 0.95, r * 0.25, r * 0.25)
            end

            cloud(width * 0.18, height * 0.18, 2.4, 0.4, 10, 4)
            cloud(width * 0.52, height * 0.12, 2.0, 1.9, 8, 3)
            cloud(width * 0.82, height * 0.22, 2.2, 3.2, 9, 4)
            cloud(width * 0.73, height * 0.45, 1.5, 4.5, 6, 2)
            cloud(width * 0.34, height * 0.40, 1.35, 5.8, 5, 2)

            love.graphics.setColor(1, 1, 1, 1)
        end,
        MainMenuBG = function(width, height)
            love.graphics.clear(0.08, 0.13, 0.18, 1)
        end,
        LobbyBG = function(width, height)
            LobbyHallBackground.draw(width, height)
        end,
        GamePlayBG = function(width, height)
            love.graphics.clear(0.05, 0.12, 0.08, 1)
            love.graphics.setColor(0.06, 0.21, 0.12, 1)
            love.graphics.rectangle("fill", 0, 0, width, height)
            love.graphics.setColor(0.09, 0.3, 0.17, 1)
            love.graphics.rectangle("fill", 48, 48, width - 96, height - 96, 32, 32)
            drawDiagonalPattern(width, height, { 0.56, 0.89, 0.49, 0.14 }, 112, 2, 0)
            drawDiagonalPattern(width, height, { 0.86, 0.95, 0.56, 0.08 }, 112, 2, 56)
        end,
    }

    return self
end

function BackgroundManager:getBackgroundLayoutMode()
    return self.background_layout_mode
end

function BackgroundManager:_startLayoutTransition(target_mode, target_theme_id)
    if target_mode ~= "grid" and target_mode ~= "single" then
        return false
    end

    self.layout_transition.active = true
    self.layout_transition.elapsed = 0
    self.layout_transition.midpoint_applied = false
    self.layout_transition.target_mode = target_mode
    self.layout_transition.target_theme_id = target_theme_id
    return true
end

function BackgroundManager:_applyLayoutTransitionMidpoint()
    local target_mode = self.layout_transition.target_mode
    local target_theme_id = self.layout_transition.target_theme_id
    if target_mode == "single" and target_theme_id then
        self:setGameplayTheme(target_theme_id)
    end
    self.background_layout_mode = target_mode or self.background_layout_mode
    self.layout_transition.midpoint_applied = true
end

function BackgroundManager:_finishLayoutTransition()
    self.layout_transition.active = false
    self.layout_transition.elapsed = 0
    self.layout_transition.midpoint_applied = false
    self.layout_transition.target_mode = nil
    self.layout_transition.target_theme_id = nil
end

function BackgroundManager:getLayoutTransitionAlpha()
    if not self.layout_transition.active then
        return 0
    end
    local elapsed = tonumber(self.layout_transition.elapsed) or 0
    local duration = math.max(0.001, tonumber(self.layout_transition.duration) or 0.36)
    local half = duration * 0.5
    if elapsed <= half then
        return math.max(0, math.min(1, elapsed / half))
    end
    return math.max(0, math.min(1, 1 - ((elapsed - half) / half)))
end

function BackgroundManager:toggleBackgroundLayoutMode()
    if self.background_layout_mode == "grid" then
        local fallback_id = self:getGameplayThemeId() or self.main_menu_theme_ids[1]
        self:_startLayoutTransition("single", fallback_id)
        return "single"
    end
    self:_startLayoutTransition("grid", nil)
    return "grid"
end

function BackgroundManager:handleMainMenuBackgroundClick(x, y)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    if self.background_layout_mode == "grid" then
        local cell_index = resolveSeasonCellAt(width, height, x, y)
        local theme_id = self.main_menu_theme_ids[cell_index] or self.main_menu_theme_ids[1]
        self:_startLayoutTransition("single", theme_id)
        return self.background_layout_mode
    end

    self:_startLayoutTransition("grid", nil)
    return self.background_layout_mode
end

function BackgroundManager:syncGameplayPreviewTheme()
    -- Keep preview themes isolated from live gameplay instances.
    -- This avoids fullscreen layout state polluting settings thumbnails.
    return
end

function BackgroundManager:selectRandomGameplayTheme(theme_ids)
    local pool = {}
    if type(theme_ids) == "table" then
        for _, theme_id in ipairs(theme_ids) do
            theme_id = BackgroundThemeCatalog.normalizeThemeId(theme_id)
            if self.background_theme_by_id[theme_id] then
                pool[#pool + 1] = theme_id
            end
        end
    else
        for _, entry in ipairs(self.background_theme_entries) do
            pool[#pool + 1] = entry.id
        end
    end

    local total = #pool
    if total <= 0 then
        self.gameplay_theme = nil
        self.gameplay_theme_id = nil
        return nil
    end

    local theme_id = pool[love.math.random(1, total)]
    self:setGameplayTheme(theme_id)
    return theme_id
end

function BackgroundManager:selectRandomSeasonalGameplayTheme()
    return self:selectRandomGameplayTheme(self.main_menu_theme_ids)
end

function BackgroundManager:getGameplayThemeId()
    if not self.gameplay_theme_id then
        return nil
    end
    return BackgroundThemeCatalog.normalizeThemeId(self.gameplay_theme_id)
end

function BackgroundManager:setGameplayTheme(theme_id)
    theme_id = BackgroundThemeCatalog.normalizeThemeId(theme_id)

    local prototype = self.background_theme_by_id[theme_id]
    if not prototype then
        return false
    end

    if theme_id == self.gameplay_theme_id and self.gameplay_theme then
        -- Keep repeated clicks idempotent; avoid rebuilding preview state repeatedly.
        ensureThemeFullscreenLayout(self.gameplay_theme, love.graphics.getWidth(), love.graphics.getHeight())
        return true
    end

    self.gameplay_theme = createThemeInstance(prototype)
    self.gameplay_theme_id = theme_id
    ensureThemeFullscreenLayout(self.gameplay_theme, love.graphics.getWidth(), love.graphics.getHeight())
    self:syncGameplayPreviewTheme()
    return true
end

function BackgroundManager:regenerateGameplayTheme()
    if not self.gameplay_theme then
        return self:selectRandomGameplayTheme() ~= nil
    end

    if self.gameplay_theme.regenerate then
        self.gameplay_theme:regenerate()
    elseif self.gameplay_theme.init then
        self.gameplay_theme:init()
    end
    ensureThemeFullscreenLayout(self.gameplay_theme, love.graphics.getWidth(), love.graphics.getHeight())
    self:syncGameplayPreviewTheme()
    return true
end

function BackgroundManager:drawThemePreview(theme_id, x, y, width, height, options)
    theme_id = BackgroundThemeCatalog.normalizeThemeId(theme_id)

    local w = math.max(1, math.floor(width or 0))
    local h = math.max(1, math.floor(height or 0))
    if w <= 1 or h <= 1 then
        return false
    end

    local prototype = self.background_theme_by_id[theme_id]
    if not prototype then
        return false
    end

    local preview_seed = options and (options.preview_seed or options.seed) or nil
    local mode = (options and options.mode) or "tile"
    local preview_cache = self.preview_themes
    if mode == "fullscreen" then
        preview_cache = self.fullscreen_preview_themes
    end

    local theme = preview_cache[theme_id]
    if not theme then
        local preview_options = getThemeInitOptions(theme_id, "preview") or {}
        preview_options.screenW = w
        preview_options.screenH = h
        preview_options.seed = preview_seed
        theme = createThemeInstance(prototype, preview_options)
        preview_cache[theme_id] = theme
        theme._preview_seed = preview_seed
    end

    local seed_changed = preview_seed ~= nil and theme._preview_seed ~= preview_seed
    if theme._preview_w ~= w or theme._preview_h ~= h or theme._preview_layout_mode ~= mode or seed_changed then
        local preview_options = getThemeInitOptions(theme_id, "preview") or {}
        preview_options.screenW = w
        preview_options.screenH = h
        preview_options.seed = preview_seed
        if theme.regenerate then
            theme:regenerate(preview_options)
        elseif theme.init then
            theme:init(preview_options)
        elseif theme.resize then
            theme:resize(w, h)
        end
        theme._preview_seed = preview_seed
    end
    if mode == "fullscreen" then
        ensureThemeFullscreenLayout(theme, w, h)
    else
        ensureThemePreviewLayout(theme, w, h)
    end
    theme._preview_w = w
    theme._preview_h = h
    theme._preview_layout_mode = mode

    love.graphics.setScissor(x, y, w, h)
    love.graphics.push()
    love.graphics.translate(x, y)
    -- Themes may not clear their background. Fill first so UI behind doesn't leak through.
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    theme:draw(w, h)
    love.graphics.pop()
    love.graphics.setScissor()
    return true
end

function BackgroundManager:drawMainMenuSeasonGrid(width, height)
    local cells, half_width, half_height = buildSeasonCells(self.main_menu_themes, width, height)

    for _, cell in ipairs(cells) do
        ensureThemeCellLayout(cell.theme, cell.w, cell.h)
        love.graphics.setScissor(cell.x, cell.y, cell.w, cell.h)
        love.graphics.push()
        love.graphics.translate(cell.x, cell.y)
        cell.theme:draw(cell.w, cell.h)
        love.graphics.pop()
        love.graphics.setScissor()
    end

    love.graphics.setColor(0.12, 0.07, 0.04, 0.30)
    love.graphics.setLineWidth(2)
    love.graphics.line(half_width, 0, half_width, height)
    love.graphics.line(0, half_height, width, half_height)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function BackgroundManager:update(dt)
    if self.layout_transition.active then
        self.layout_transition.elapsed = (tonumber(self.layout_transition.elapsed) or 0) + (tonumber(dt) or 0)
        local duration = math.max(0.001, tonumber(self.layout_transition.duration) or 0.36)
        if (not self.layout_transition.midpoint_applied) and self.layout_transition.elapsed >= duration * 0.5 then
            self:_applyLayoutTransitionMidpoint()
        end
        if self.layout_transition.elapsed >= duration then
            if not self.layout_transition.midpoint_applied then
                self:_applyLayoutTransitionMidpoint()
            end
            self:_finishLayoutTransition()
        end
    end

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local cells = buildSeasonCells(self.main_menu_themes, width, height)
    local updated = {}

    local function updateThemeOnce(theme, update_dt, w, h, layout_fn)
        if not theme or not theme.update or updated[theme] then
            return
        end
        if layout_fn then
            layout_fn(theme, w, h)
        end
        theme:update(update_dt, w, h)
        updated[theme] = true
    end

    for _, cell in ipairs(cells) do
        updateThemeOnce(cell.theme, dt, cell.w, cell.h, ensureThemeCellLayout)
    end

    if self.gameplay_theme then
        updateThemeOnce(self.gameplay_theme, dt, width, height, ensureThemeFullscreenLayout)
    end

    local preview_dt = math.min(dt, 1 / 30)
    local function updatePreviewCache(cache)
        for _, theme in pairs(cache or {}) do
            if theme and theme.update and theme._preview_w and theme._preview_h then
                local layout_fn = ensureThemePreviewLayout
                if theme._preview_layout_mode == "fullscreen" then
                    layout_fn = ensureThemeFullscreenLayout
                end
                updateThemeOnce(theme, preview_dt, theme._preview_w, theme._preview_h, layout_fn)
            end
        end
    end

    updatePreviewCache(self.preview_themes)
    updatePreviewCache(self.fullscreen_preview_themes)
end

function BackgroundManager:onDisplayChanged()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local cells = buildSeasonCells(self.main_menu_themes, width, height)

    for _, cell in ipairs(cells) do
        local theme = cell.theme
        if theme then
            if theme.regenerate then
                theme:regenerate()
            elseif theme.init then
                theme:init()
            end
            ensureThemeCellLayout(theme, cell.w, cell.h)
        end
    end

    if self.gameplay_theme then
        if self.gameplay_theme.regenerate then
            self.gameplay_theme:regenerate()
        elseif self.gameplay_theme.init then
            self.gameplay_theme:init()
        end
        ensureThemeFullscreenLayout(self.gameplay_theme, width, height)
        self:syncGameplayPreviewTheme()
    end
end

function BackgroundManager:draw(background_id)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    if background_id == "MainMenuBG" then
        if self.background_layout_mode == "single" then
            if not self.gameplay_theme then
                self:selectRandomSeasonalGameplayTheme()
            end
            if self.gameplay_theme then
                ensureThemeFullscreenLayout(self.gameplay_theme, width, height)
                self.gameplay_theme:draw(width, height)
                drawLayoutTransitionOverlay(self, width, height)
                return
            end
        end
        self:drawMainMenuSeasonGrid(width, height)
        drawLayoutTransitionOverlay(self, width, height)
        return
    end

    if background_id == "GamePlayBG" then
        if not self.gameplay_theme then
            if self.background_layout_mode == "grid" then
                self:selectRandomSeasonalGameplayTheme()
            else
                self:selectRandomGameplayTheme()
            end
        end
        if self.gameplay_theme then
            ensureThemeFullscreenLayout(self.gameplay_theme, width, height)
            self.gameplay_theme:draw(width, height)
            drawLayoutTransitionOverlay(self, width, height)
            return
        end
    end

    local preset = self.presets[background_id]
    if preset then
        preset(width, height)
        return
    end

    love.graphics.clear(0.05, 0.07, 0.09, 1)
end

return BackgroundManager
