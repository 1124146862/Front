local repo_root = "D:/DATA/Onedrive/GuanDan/Front"
package.path = table.concat({
    repo_root .. "/?.lua",
    repo_root .. "/?/init.lua",
    repo_root .. "/src/?.lua",
    repo_root .. "/src/?/init.lua",
    package.path,
}, ";")

local Platform = require("src.infra.system.platform")
local SteamIDProvider = require("src.features.session.steam_id_provider")

local function writeResult(text)
    local file = assert(io.open(repo_root .. "/__steamid_smoke/result.txt", "wb"))
    file:write(text or "")
    file:close()
end

local function readTextFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

function love.load()
    local provider = SteamIDProvider.new({
        source = "auto",
        bridge_path = repo_root .. "/src/infra/steam/bridge/steam_id_bridge.exe",
        fake_steam_id = "5000000000",
        random_for_test = true,
    })

    local steam_id = provider:getSteamID()
    writeResult(string.format("steam_id=%s\n", tostring(steam_id)))
    love.event.quit(0)
end
