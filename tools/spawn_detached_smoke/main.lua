package.path = package.path
    .. ";../../?.lua"
    .. ";../../?/init.lua"
    .. ";../../Front/?.lua"
    .. ";../../Front/?/init.lua"

local Platform = require("src.infra.system.platform")

function love.load()
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "."
    local output_path = Platform.joinPath(temp_dir, "guandan_spawn_detached_smoke.txt")
    pcall(os.remove, output_path)

    local started = Platform.spawnDetached({
        "powershell.exe",
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        string.format("Set-Content -LiteralPath '%s' -Value smoke_ok", output_path),
    })

    local deadline = os.clock() + 5
    while os.clock() < deadline do
        local handle = io.open(output_path, "r")
        if handle then
            local content = handle:read("*a") or ""
            handle:close()
            print("started=" .. tostring(started))
            print("content=" .. tostring(content))
            love.event.quit(0)
            return
        end
        love.timer.sleep(0.1)
    end

    print("started=" .. tostring(started))
    print("content=<missing>")
    love.event.quit(1)
end
