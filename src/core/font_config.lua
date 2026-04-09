local FontConfig = {
    ui_font_path = "assets/fonts/zpix.ttf",
    card_face_font_path = "assets/fonts/ZillaSlab-SemiBoldItalic.ttf",
    ui_locale_font_paths = {
        ["ko-KR"] = "assets/fonts/Pretendard-Regular.ttf",
    },
    card_face_locale_font_paths = {
        ["ko-KR"] = "assets/fonts/Pretendard-Regular.ttf",
    },
    tokens = {
        Title1 = 96,
        Title2 = 52,
        Title3 = 38,
        TextBig = 28,
        Text = 24,
        TextSmall = 20,
        Button = 30,
        Caption = 18,
        Label = 16,
    },
}

function FontConfig.resolveLocaleFontPath(default_path, locale_font_paths, locale)
    local locale_key = tostring(locale or "")
    return (locale_font_paths or {})[locale_key] or default_path
end

return FontConfig
