local AppConfig = require("src.core.config.app_config")

local default_network = AppConfig.getDefaultNetwork()
local default_urls = AppConfig.buildBaseUrls(default_network)

return {
    language = "zh-CN",
    steam_id_source = "auto",
    cached_player_id = nil,
    cached_player_id_source = nil,
    server_host = default_network.host,
    server_port = default_network.port,
    server_use_tls = default_network.use_tls,
    server_http_base_url = default_urls.http,
    server_ws_base_url = default_urls.ws,
    window_mode = "windowed",
    window_width = 1600,
    window_height = 900,
    target_fps = 60,
    audio_master_volume = 1.0,
    audio_bgm_volume = 0.3,
    audio_sfx_volume = 0.9,
    audio_mute_master = false,
    audio_mute_bgm = false,
    audio_mute_sfx = false,
    preferred_game_bgm_id = "game_default",
    preferred_gameplay_background_theme = "summer",
    cards_high_contrast = true,
}
