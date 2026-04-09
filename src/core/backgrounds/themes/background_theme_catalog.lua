local I18n = require("src.core.i18n.i18n")

local BackgroundThemeCatalog = {}

BackgroundThemeCatalog.DEFAULT_THEME_ID = "summer"
BackgroundThemeCatalog.OPTIONS = {
    "spring",
    "summer",
    "autumn",
    "winter",
    "cosmos",
    "nebula",
    "galaxy",
    "warp",
}

BackgroundThemeCatalog.LABEL_KEYS = {
    spring = "gameplay.settings_background_spring",
    summer = "gameplay.settings_background_summer",
    autumn = "gameplay.settings_background_autumn",
    winter = "gameplay.settings_background_winter",
    cosmos = "gameplay.settings_background_cosmos",
    nebula = "gameplay.settings_background_nebula",
    galaxy = "gameplay.settings_background_galaxy",
    warp = "gameplay.settings_background_warp",
}

local LOOKUP = {}
for _, theme_id in ipairs(BackgroundThemeCatalog.OPTIONS) do
    LOOKUP[theme_id] = true
end

function BackgroundThemeCatalog.normalizeThemeId(theme_id)
    if LOOKUP[theme_id] then
        return theme_id
    end
    return BackgroundThemeCatalog.DEFAULT_THEME_ID
end

function BackgroundThemeCatalog.contains(theme_id)
    return LOOKUP[theme_id] == true
end

function BackgroundThemeCatalog.getLabel(theme_id)
    local normalized = BackgroundThemeCatalog.normalizeThemeId(theme_id)
    local label_key = BackgroundThemeCatalog.LABEL_KEYS[normalized]
        or BackgroundThemeCatalog.LABEL_KEYS[BackgroundThemeCatalog.DEFAULT_THEME_ID]
    return I18n:t(label_key)
end

return BackgroundThemeCatalog
