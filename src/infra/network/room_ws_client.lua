local Platform = require("src.infra.system.platform")

if Platform.isWindows() then
    return require("src.infra.network.room_ws_client_winhttp")
end

return require("src.infra.network.room_ws_client_bridge")
