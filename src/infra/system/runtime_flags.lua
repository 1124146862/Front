local Platform = require("src.infra.system.platform")

local RuntimeFlags = {
    ENV_VAR_NAME = "APP_RUNTIME",
    MODES = {
        DEFAULT = "default",
        WINDOWS_PACKAGED = "windows_packaged",
    },
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function normalizeMode(value)
    local normalized = trim(value):lower():gsub("%s+", "_"):gsub("%-+", "_")
    if normalized == "" then
        return nil
    end
    if normalized == RuntimeFlags.MODES.DEFAULT then
        return RuntimeFlags.MODES.DEFAULT
    end
    if normalized == RuntimeFlags.MODES.WINDOWS_PACKAGED or normalized == "windows" then
        return RuntimeFlags.MODES.WINDOWS_PACKAGED
    end
    return nil
end

function RuntimeFlags.getEnvVarName()
    return RuntimeFlags.ENV_VAR_NAME
end

function RuntimeFlags.isFused()
    if love and love.filesystem and love.filesystem.isFused then
        return love.filesystem.isFused() == true
    end
    return false
end

function RuntimeFlags.getOverrideMode()
    return normalizeMode(os.getenv(RuntimeFlags.ENV_VAR_NAME))
end

function RuntimeFlags.getDetectedMode()
    if Platform.isWindows() and RuntimeFlags.isFused() then
        return RuntimeFlags.MODES.WINDOWS_PACKAGED
    end
    return RuntimeFlags.MODES.DEFAULT
end

function RuntimeFlags.getActiveMode()
    return RuntimeFlags.getOverrideMode() or RuntimeFlags.getDetectedMode()
end

function RuntimeFlags.isMode(mode)
    local normalized = normalizeMode(mode)
    if not normalized then
        return false
    end
    return RuntimeFlags.getActiveMode() == normalized
end

function RuntimeFlags.isWindowsPackagedMode()
    return RuntimeFlags.getActiveMode() == RuntimeFlags.MODES.WINDOWS_PACKAGED
end

function RuntimeFlags.snapshot()
    return {
        os_name = Platform.getOS(),
        is_windows = Platform.isWindows(),
        is_fused = RuntimeFlags.isFused(),
        env_var_name = RuntimeFlags.ENV_VAR_NAME,
        runtime_override = RuntimeFlags.getOverrideMode(),
        detected_mode = RuntimeFlags.getDetectedMode(),
        active_mode = RuntimeFlags.getActiveMode(),
    }
end

return RuntimeFlags
