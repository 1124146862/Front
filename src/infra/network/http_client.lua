local RuntimeFlags = require("src.infra.system.runtime_flags")
local Platform = require("src.infra.system.platform")

if Platform.isWindows() or RuntimeFlags.isWindowsPackagedMode() then
    return require("src.infra.network.http_client_winhttp")
end

return require("src.infra.network.http_client_default")
