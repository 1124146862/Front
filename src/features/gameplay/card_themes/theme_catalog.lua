local ThemeCatalog = {}

ThemeCatalog.DEFAULT_THEME_ID = "jade_lacquer"
ThemeCatalog.OPTIONS = {
    "jade_lacquer",
    "garden_court",
    "paper_circus",
    "sunset_deco",
    "moonlit_orchid",
}

local LABEL_KEYS = {
    jade_lacquer = "gameplay.settings_cards_theme_jade_lacquer",
    garden_court = "gameplay.settings_cards_theme_garden_court",
    paper_circus = "gameplay.settings_cards_theme_paper_circus",
    sunset_deco = "gameplay.settings_cards_theme_sunset_deco",
    moonlit_orchid = "gameplay.settings_cards_theme_moonlit_orchid",
}

local LOOKUP = {}
for _, theme_id in ipairs(ThemeCatalog.OPTIONS) do
    LOOKUP[theme_id] = true
end

function ThemeCatalog.contains(theme_id)
    return LOOKUP[theme_id] == true
end

function ThemeCatalog.normalizeThemeId(theme_id)
    if ThemeCatalog.contains(theme_id) then
        return theme_id
    end
    return ThemeCatalog.DEFAULT_THEME_ID
end

function ThemeCatalog.getLabelKey(theme_id)
    return LABEL_KEYS[ThemeCatalog.normalizeThemeId(theme_id)] or LABEL_KEYS[ThemeCatalog.DEFAULT_THEME_ID]
end

return ThemeCatalog
