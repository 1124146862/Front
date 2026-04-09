local Json = require("src.infra.network.json")
local I18n = require("src.core.i18n.i18n")
local Platform = require("src.infra.system.platform")

local Support = {
    DEBUG_LOG_FILE = "guandan_http_debug.log",
}

function Support.trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

function Support.urlEncode(value)
    return tostring(value)
        :gsub("\n", "\r\n")
        :gsub("([^%w%-_%.~])", function(char)
            return string.format("%%%02X", string.byte(char))
        end)
end

function Support.buildQuery(params)
    if not params then
        return ""
    end

    local parts = {}
    for key, value in pairs(params) do
        parts[#parts + 1] = Support.urlEncode(key) .. "=" .. Support.urlEncode(value)
    end

    return table.concat(parts, "&")
end

function Support.resolveDebugLogPath()
    if Platform.isWindows() then
        local temp_dir = os.getenv("TEMP") or os.getenv("TMP")
        if temp_dir and temp_dir ~= "" then
            return Platform.joinPath(temp_dir, Support.DEBUG_LOG_FILE)
        end
    end

    if love and love.filesystem and love.filesystem.getSaveDirectory then
        local save_dir = love.filesystem.getSaveDirectory()
        if save_dir and save_dir ~= "" then
            return Platform.joinPath(save_dir, Support.DEBUG_LOG_FILE)
        end
    end

    return Support.DEBUG_LOG_FILE
end

function Support.resolveTempDir()
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP")
    if temp_dir and temp_dir ~= "" then
        return temp_dir
    end
    return "."
end

function Support.writeTextFile(path, content)
    local file = io.open(path, "wb")
    if not file then
        return false
    end
    file:write(content or "")
    file:close()
    return true
end

function Support.readTextFile(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

function Support.nextTempPath(stem, extension, counter)
    local file_name = string.format(
        "%s_%d_%d%s",
        tostring(stem or "tmp"),
        os.time(),
        tonumber(counter) or 0,
        tostring(extension or "")
    )
    return Platform.joinPath(Support.resolveTempDir(), file_name)
end

function Support.cleanupPaths(paths)
    for _, path_to_remove in ipairs(paths or {}) do
        if path_to_remove and path_to_remove ~= "" then
            pcall(os.remove, path_to_remove)
        end
    end
end

function Support.appendDebugLog(lines)
    local payload = table.concat(lines, "\n") .. "\n"
    local log_path = Support.resolveDebugLogPath()

    if Platform.isWindows() then
        local file = io.open(log_path, "a")
        if file then
            file:write(payload)
            file:close()
            return
        end
    end

    if love and love.filesystem and love.filesystem.append then
        pcall(love.filesystem.append, Support.DEBUG_LOG_FILE, payload)
    end
end

function Support.parseResponse(raw_result, raw_body, raw_status)
    local resolved_body = raw_body
    local resolved_status = raw_status

    if not resolved_status or resolved_status == "" then
        local status_from_result = tostring(raw_result or ""):match("__STATUS__:(%d%d%d)%s*$")
        if status_from_result and status_from_result ~= "" then
            resolved_status = status_from_result
        else
            resolved_body, resolved_status = tostring(raw_result or ""):match("^(.*)__STATUS__:(%d%d%d)%s*$")
        end
    end

    if not resolved_status or resolved_status == "" then
        local error_message = Support.trim(raw_result)
        if error_message == "" then
            error_message = I18n:t("network.missing_status")
        end
        return {
            ok = false,
            status = 0,
            error = error_message,
            raw_body = raw_result,
        }
    end

    local numeric_status = tonumber(resolved_status) or 0
    if numeric_status == 0 then
        local error_message = Support.trim(resolved_body)
        if error_message == "" then
            error_message = I18n:t("network.http_failed", {
                status = numeric_status,
            })
        end
        return {
            ok = false,
            status = numeric_status,
            error = error_message,
            raw_body = resolved_body,
        }
    end

    local response_data = nil
    if resolved_body and resolved_body ~= "" then
        local decoded, decode_error = Json.decode(resolved_body)
        if decode_error then
            local error_message = I18n:t("network.invalid_json")
            if numeric_status >= 400 then
                error_message = Support.trim(resolved_body)
                if error_message == "" then
                    error_message = I18n:t("network.http_failed", {
                        status = numeric_status,
                    })
                end
            end
            return {
                ok = false,
                status = numeric_status,
                error = error_message,
                raw_body = resolved_body,
                decode_error = decode_error,
            }
        end
        response_data = decoded
    end

    local ok = numeric_status >= 200 and numeric_status < 300
    local error_code = nil
    local error_message = nil

    if not ok then
        local detail = response_data and response_data.detail or nil
        if type(detail) == "table" then
            error_code = detail.code
            error_message = detail.message or detail.code or I18n:t("network.http_failed", {
                status = numeric_status,
            })
        else
            error_message = detail or I18n:t("network.http_failed", {
                status = numeric_status,
            })
        end
    end

    return {
        ok = ok,
        status = numeric_status,
        data = response_data,
        error = error_message,
        error_code = error_code,
        raw_body = resolved_body,
    }
end

return Support
