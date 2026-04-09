local Json = require("src.infra.network.json")
local Platform = require("src.infra.system.platform")
local RuntimeConfig = require("src.infra.network.runtime_config")
local Support = require("src.infra.network.http_client_support")
local I18n = require("src.core.i18n.i18n")
local bit = require("bit")

local HttpClient = {}
HttpClient.__index = HttpClient

local ffi_ok, ffi = pcall(require, "ffi")
local ffi_defs_loaded = false
local winhttp_lib = nil

local CP_UTF8 = 65001
local WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0
local WINHTTP_FLAG_SECURE = 0x00800000
local WINHTTP_QUERY_STATUS_CODE = 19
local WINHTTP_QUERY_FLAG_NUMBER = 0x20000000
local WINHTTP_AUTO_HEADER_LENGTH = 0xFFFFFFFF

local DEFAULT_CONNECT_TIMEOUT_MS = 3000
local DEFAULT_SEND_TIMEOUT_MS = 10000
local DEFAULT_RECEIVE_TIMEOUT_MS = 10000
local READ_CHUNK_SIZE = 8192

local function errorResponse(message)
    return {
        ok = false,
        status = 0,
        error = tostring(message or I18n:t("network.http_failed", { status = 0 })),
    }
end

local function ensureWindowsBindings()
    if not Platform.isWindows() then
        return false, "WinHTTP is only available on Windows"
    end
    if not ffi_ok then
        return false, "LuaJIT FFI is unavailable"
    end
    if not ffi_defs_loaded then
        local ok, err = pcall(function()
            ffi.cdef([[
                typedef void* HINTERNET;
                typedef unsigned long DWORD;
                typedef int BOOL;
                typedef unsigned short WORD;
                typedef unsigned short WCHAR;
                typedef const WCHAR* LPCWSTR;
                typedef void* LPVOID;
                typedef size_t ULONG_PTR;

                int MultiByteToWideChar(
                    unsigned int CodePage,
                    DWORD dwFlags,
                    const char* lpMultiByteStr,
                    int cbMultiByte,
                    WCHAR* lpWideCharStr,
                    int cchWideChar
                );

                DWORD GetLastError(void);

                HINTERNET WinHttpOpen(
                    LPCWSTR pszAgentW,
                    DWORD dwAccessType,
                    LPCWSTR pszProxyW,
                    LPCWSTR pszProxyBypassW,
                    DWORD dwFlags
                );

                BOOL WinHttpCloseHandle(HINTERNET hInternet);

                BOOL WinHttpSetTimeouts(
                    HINTERNET hInternet,
                    int nResolveTimeout,
                    int nConnectTimeout,
                    int nSendTimeout,
                    int nReceiveTimeout
                );

                HINTERNET WinHttpConnect(
                    HINTERNET hSession,
                    LPCWSTR pswzServerName,
                    WORD nServerPort,
                    DWORD dwReserved
                );

                HINTERNET WinHttpOpenRequest(
                    HINTERNET hConnect,
                    LPCWSTR pwszVerb,
                    LPCWSTR pwszObjectName,
                    LPCWSTR pwszVersion,
                    LPCWSTR pwszReferrer,
                    LPCWSTR* ppwszAcceptTypes,
                    DWORD dwFlags
                );

                BOOL WinHttpSendRequest(
                    HINTERNET hRequest,
                    LPCWSTR pwszHeaders,
                    DWORD dwHeadersLength,
                    LPVOID lpOptional,
                    DWORD dwOptionalLength,
                    DWORD dwTotalLength,
                    ULONG_PTR dwContext
                );

                BOOL WinHttpReceiveResponse(
                    HINTERNET hRequest,
                    LPVOID lpReserved
                );

                BOOL WinHttpQueryHeaders(
                    HINTERNET hRequest,
                    DWORD dwInfoLevel,
                    LPCWSTR pwszName,
                    LPVOID lpBuffer,
                    DWORD* lpdwBufferLength,
                    DWORD* lpdwIndex
                );

                BOOL WinHttpReadData(
                    HINTERNET hRequest,
                    LPVOID lpBuffer,
                    DWORD dwNumberOfBytesToRead,
                    DWORD* lpdwNumberOfBytesRead
                );
            ]])
        end)
        if not ok then
            return false, tostring(err)
        end
        ffi_defs_loaded = true
    end
    if not winhttp_lib then
        local ok, lib_or_err = pcall(ffi.load, "winhttp")
        if not ok then
            return false, tostring(lib_or_err)
        end
        winhttp_lib = lib_or_err
    end
    return true
end

local function utf8ToWideBuffer(value)
    local text = tostring(value or "")
    local required = ffi.C.MultiByteToWideChar(CP_UTF8, 0, text, #text, nil, 0)
    if required <= 0 then
        return nil
    end

    local buffer = ffi.new("WCHAR[?]", required + 1)
    local converted = ffi.C.MultiByteToWideChar(CP_UTF8, 0, text, #text, buffer, required)
    if converted <= 0 then
        return nil
    end

    buffer[converted] = 0
    return buffer
end

local function closeHandle(handle)
    if handle ~= nil and handle ~= ffi.NULL and winhttp_lib then
        winhttp_lib.WinHttpCloseHandle(handle)
    end
end

local function lastWinError(context)
    local code = tonumber(ffi.C.GetLastError() or 0)
    if code <= 0 then
        return tostring(context or "WinHTTP request failed")
    end
    return string.format("%s (winerr=%d)", tostring(context or "WinHTTP request failed"), code)
end

local function buildUrl(base_url, method, path, payload)
    local url = tostring(base_url or "") .. tostring(path or "")
    if method == "GET" and payload and next(payload) then
        url = url .. "?" .. Support.buildQuery(payload)
    end
    return url
end

local function parseAuthority(authority)
    local host = tostring(authority or "")
    local port = nil

    if host:sub(1, 1) == "[" then
        local bracket_end = host:find("]", 2, true)
        if bracket_end then
            local ipv6_host = host:sub(2, bracket_end - 1)
            local suffix = host:sub(bracket_end + 1)
            if suffix:sub(1, 1) == ":" then
                port = tonumber(suffix:sub(2))
            end
            return ipv6_host, port
        end
    end

    local parsed_host, parsed_port = host:match("^(.-):(%d+)$")
    if parsed_host and parsed_host ~= "" then
        return parsed_host, tonumber(parsed_port)
    end

    return host, nil
end

local function parseUrl(url)
    local scheme, rest = tostring(url or ""):match("^(https?)://(.+)$")
    if not scheme then
        return nil, "invalid base url"
    end

    local authority, resource = rest:match("^([^/]+)(/.*)$")
    if not authority then
        authority = rest
        resource = "/"
    end

    local host, port = parseAuthority(authority)
    if not host or host == "" then
        return nil, "missing host"
    end

    if not port then
        port = scheme == "https" and 443 or 80
    end

    return {
        scheme = scheme,
        host = host,
        port = port,
        resource = resource,
        secure = scheme == "https",
    }
end

local function buildRequestHeaders(method, payload)
    local lines = {
        "Accept: application/json",
    }
    if (method == "POST" or method == "PATCH") and payload ~= nil then
        lines[#lines + 1] = "Content-Type: application/json; charset=utf-8"
    end
    return table.concat(lines, "\r\n")
end

local function executeRequest(base_url, method, path, payload)
    local bindings_ok, bindings_err = ensureWindowsBindings()
    if not bindings_ok then
        return nil, bindings_err
    end

    local url = buildUrl(base_url, method, path, payload)
    local endpoint, parse_err = parseUrl(url)
    if not endpoint then
        return nil, parse_err
    end

    local method_wide = utf8ToWideBuffer(method)
    local host_wide = utf8ToWideBuffer(endpoint.host)
    local resource_wide = utf8ToWideBuffer(endpoint.resource)
    local agent_wide = utf8ToWideBuffer("GuanDan/WinHTTP")
    if not method_wide or not host_wide or not resource_wide or not agent_wide then
        return nil, "failed to encode WinHTTP request strings"
    end

    local headers_text = buildRequestHeaders(method, payload)
    local headers_wide = utf8ToWideBuffer(headers_text)
    if not headers_wide then
        return nil, "failed to encode WinHTTP headers"
    end

    local body_text = nil
    local body_buffer = nil
    local body_length = 0
    if method == "POST" or method == "PATCH" then
        body_text = Json.encodeObject(payload or {})
        body_length = #body_text
        body_buffer = ffi.new("uint8_t[?]", math.max(body_length, 1))
        if body_length > 0 then
            ffi.copy(body_buffer, body_text, body_length)
        end
    end

    local session = nil
    local connection = nil
    local request = nil

    local ok, result_or_err = pcall(function()
        session = winhttp_lib.WinHttpOpen(agent_wide, WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nil, nil, 0)
        if session == nil or session == ffi.NULL then
            error(lastWinError("WinHttpOpen failed"))
        end

        if winhttp_lib.WinHttpSetTimeouts(
            session,
            0,
            DEFAULT_CONNECT_TIMEOUT_MS,
            DEFAULT_SEND_TIMEOUT_MS,
            DEFAULT_RECEIVE_TIMEOUT_MS
        ) == 0 then
            error(lastWinError("WinHttpSetTimeouts failed"))
        end

        connection = winhttp_lib.WinHttpConnect(session, host_wide, tonumber(endpoint.port), 0)
        if connection == nil or connection == ffi.NULL then
            error(lastWinError("WinHttpConnect failed"))
        end

        local request_flags = endpoint.secure and WINHTTP_FLAG_SECURE or 0
        request = winhttp_lib.WinHttpOpenRequest(connection, method_wide, resource_wide, nil, nil, nil, request_flags)
        if request == nil or request == ffi.NULL then
            error(lastWinError("WinHttpOpenRequest failed"))
        end

        if winhttp_lib.WinHttpSendRequest(
            request,
            headers_wide,
            WINHTTP_AUTO_HEADER_LENGTH,
            body_buffer,
            body_length,
            body_length,
            0
        ) == 0 then
            error(lastWinError("WinHttpSendRequest failed"))
        end

        if winhttp_lib.WinHttpReceiveResponse(request, nil) == 0 then
            error(lastWinError("WinHttpReceiveResponse failed"))
        end

        local status_value = ffi.new("DWORD[1]", 0)
        local status_size = ffi.new("DWORD[1]", ffi.sizeof(status_value))
        if winhttp_lib.WinHttpQueryHeaders(
            request,
            bit.bor(WINHTTP_QUERY_STATUS_CODE, WINHTTP_QUERY_FLAG_NUMBER),
            nil,
            status_value,
            status_size,
            nil
        ) == 0 then
            error(lastWinError("WinHttpQueryHeaders failed"))
        end

        local chunks = {}
        while true do
            local chunk = ffi.new("uint8_t[?]", READ_CHUNK_SIZE)
            local bytes_read = ffi.new("DWORD[1]", 0)
            if winhttp_lib.WinHttpReadData(request, chunk, READ_CHUNK_SIZE, bytes_read) == 0 then
                error(lastWinError("WinHttpReadData failed"))
            end
            local count = tonumber(bytes_read[0] or 0)
            if count <= 0 then
                break
            end
            chunks[#chunks + 1] = ffi.string(chunk, count)
        end

        return {
            url = url,
            status = tonumber(status_value[0] or 0),
            raw_body = table.concat(chunks),
        }
    end)

    closeHandle(request)
    closeHandle(connection)
    closeHandle(session)

    if not ok then
        return nil, tostring(result_or_err)
    end

    return result_or_err, nil
end

function HttpClient.new(options)
    local self = setmetatable({}, HttpClient)
    self.base_url = (options and options.base_url) or RuntimeConfig.getHttpBaseUrl()
    self.mode = "winhttp"
    return self
end

function HttpClient:request(method, path, payload)
    local request_method = tostring(method or "GET"):upper()
    local details, err = executeRequest(self.base_url, request_method, path, payload)

    Support.appendDebugLog({
        string.rep("=", 80),
        os.date("[%Y-%m-%d %H:%M:%S]") .. " REQUEST",
        "client_mode: " .. tostring(self.mode),
        "method: " .. tostring(request_method),
        "url: " .. tostring(details and details.url or (tostring(self.base_url or "") .. tostring(path or ""))),
        "status: " .. tostring(details and details.status or 0),
        "transport_error: " .. tostring(err or ""),
        "raw_body:",
        tostring(details and details.raw_body or ""),
        "",
    })

    if not details then
        return errorResponse(err)
    end

    return Support.parseResponse("", details.raw_body, tostring(details.status))
end

function HttpClient:get(path, params)
    return self:request("GET", path, params)
end

function HttpClient:post(path, body)
    return self:request("POST", path, body)
end

function HttpClient:patch(path, body)
    return self:request("PATCH", path, body)
end

return HttpClient
