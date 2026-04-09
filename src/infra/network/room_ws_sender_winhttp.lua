local ws_url, command_channel_name, event_channel_name = ...

local source_root = love.filesystem.getSource()
if source_root and source_root ~= "" then
    local lua_paths = table.concat({
        source_root .. "/?.lua",
        source_root .. "/?/init.lua",
    }, ";")
    if not string.find(package.path or "", source_root, 1, true) then
        package.path = lua_paths .. ";" .. package.path
    end
end

local Json = require("src.infra.network.json")
local bit = require("bit")

local command_channel = love.thread.getChannel(command_channel_name)
local event_channel = love.thread.getChannel(event_channel_name)

local ffi_ok, ffi = pcall(require, "ffi")
local ffi_defs_loaded = false
local winhttp_lib = nil

local CP_UTF8 = 65001
local NO_ERROR = 0

local WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0
local WINHTTP_FLAG_SECURE = 0x00800000
local WINHTTP_QUERY_STATUS_CODE = 19
local WINHTTP_QUERY_FLAG_NUMBER = 0x20000000
local WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET = 114
local WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE = 2
local NORMAL_CLOSE_STATUS = 1000

local CONNECT_TIMEOUT_MS = 5000
local SEND_TIMEOUT_MS = 10000
local RECEIVE_TIMEOUT_MS = 10000

local function pushPacket(packet)
    event_channel:push(Json.encodeObject(packet))
end

local function pushError(message)
    pushPacket({
        type = "bridge_status",
        payload = {
            status = "error",
            message = tostring(message or "room ws send failed"),
        },
    })
end

local function ensureBindings()
    if not ffi_ok then
        return false, "LuaJIT FFI is unavailable in room WS sender"
    end

    if not ffi_defs_loaded then
        local ok, err = pcall(function()
            ffi.cdef([[
                typedef void* HINTERNET;
                typedef unsigned long DWORD;
                typedef unsigned short WORD;
                typedef unsigned short USHORT;
                typedef unsigned short WCHAR;
                typedef const WCHAR* LPCWSTR;
                typedef void* LPVOID;
                typedef size_t DWORD_PTR;
                typedef int BOOL;

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

                BOOL WinHttpSetOption(
                    HINTERNET hInternet,
                    DWORD dwOption,
                    LPVOID lpBuffer,
                    DWORD dwBufferLength
                );

                BOOL WinHttpSendRequest(
                    HINTERNET hRequest,
                    LPCWSTR pwszHeaders,
                    DWORD dwHeadersLength,
                    LPVOID lpOptional,
                    DWORD dwOptionalLength,
                    DWORD dwTotalLength,
                    DWORD_PTR dwContext
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

                HINTERNET WinHttpWebSocketCompleteUpgrade(
                    HINTERNET hRequest,
                    DWORD_PTR pContext
                );

                DWORD WinHttpWebSocketSend(
                    HINTERNET hWebSocket,
                    DWORD eBufferType,
                    LPVOID pvBuffer,
                    DWORD dwBufferLength
                );

                DWORD WinHttpWebSocketClose(
                    HINTERNET hWebSocket,
                    USHORT usStatus,
                    LPVOID pvReason,
                    DWORD dwReasonLength
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

local function lastWinError(context)
    local code = tonumber(ffi.C.GetLastError() or 0)
    if code <= 0 then
        return tostring(context or "WinHTTP WebSocket failed")
    end
    return string.format("%s (winerr=%d)", tostring(context or "WinHTTP WebSocket failed"), code)
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

local function parseWsUrl(url)
    local scheme, rest = tostring(url or ""):match("^(wss?)://(.+)$")
    if not scheme then
        return nil, "invalid websocket url"
    end

    local authority, resource = rest:match("^([^/]+)(/.*)$")
    if not authority then
        authority = rest
        resource = "/"
    end

    local host, port = parseAuthority(authority)
    if not host or host == "" then
        return nil, "missing websocket host"
    end

    if not port then
        port = scheme == "wss" and 443 or 80
    end

    return {
        host = host,
        port = port,
        secure = scheme == "wss",
        resource = resource,
    }
end

local function closeConnection(connection)
    if connection.websocket and connection.websocket ~= ffi.NULL then
        winhttp_lib.WinHttpWebSocketClose(connection.websocket, NORMAL_CLOSE_STATUS, nil, 0)
        winhttp_lib.WinHttpCloseHandle(connection.websocket)
    end
    if connection.request and connection.request ~= ffi.NULL then
        winhttp_lib.WinHttpCloseHandle(connection.request)
    end
    if connection.connect and connection.connect ~= ffi.NULL then
        winhttp_lib.WinHttpCloseHandle(connection.connect)
    end
    if connection.session and connection.session ~= ffi.NULL then
        winhttp_lib.WinHttpCloseHandle(connection.session)
    end
end

local function connectWebSocket(url)
    local bindings_ok, bindings_error = ensureBindings()
    if not bindings_ok then
        return nil, bindings_error
    end

    local endpoint, parse_error = parseWsUrl(url)
    if not endpoint then
        return nil, parse_error
    end

    local session = nil
    local connection = nil
    local request = nil
    local websocket = nil

    local ok, result_or_error = pcall(function()
        local agent_wide = assert(utf8ToWideBuffer("GuanDan/RoomWSSend"), "agent")
        local host_wide = assert(utf8ToWideBuffer(endpoint.host), "host")
        local resource_wide = assert(utf8ToWideBuffer(endpoint.resource), "resource")
        local get_wide = assert(utf8ToWideBuffer("GET"), "verb")

        session = winhttp_lib.WinHttpOpen(agent_wide, WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nil, nil, 0)
        if session == nil or session == ffi.NULL then
            error(lastWinError("WinHttpOpen failed"))
        end

        if winhttp_lib.WinHttpSetTimeouts(session, 0, CONNECT_TIMEOUT_MS, SEND_TIMEOUT_MS, RECEIVE_TIMEOUT_MS) == 0 then
            error(lastWinError("WinHttpSetTimeouts failed"))
        end

        connection = winhttp_lib.WinHttpConnect(session, host_wide, tonumber(endpoint.port), 0)
        if connection == nil or connection == ffi.NULL then
            error(lastWinError("WinHttpConnect failed"))
        end

        request = winhttp_lib.WinHttpOpenRequest(
            connection,
            get_wide,
            resource_wide,
            nil,
            nil,
            nil,
            endpoint.secure and WINHTTP_FLAG_SECURE or 0
        )
        if request == nil or request == ffi.NULL then
            error(lastWinError("WinHttpOpenRequest failed"))
        end

        if winhttp_lib.WinHttpSetOption(request, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nil, 0) == 0 then
            error(lastWinError("WinHttpSetOption upgrade failed"))
        end

        if winhttp_lib.WinHttpSendRequest(request, nil, 0, nil, 0, 0, 0) == 0 then
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

        if tonumber(status_value[0] or 0) ~= 101 then
            error(string.format("websocket upgrade rejected with status=%d", tonumber(status_value[0] or 0)))
        end

        websocket = winhttp_lib.WinHttpWebSocketCompleteUpgrade(request, 0)
        if websocket == nil or websocket == ffi.NULL then
            error(lastWinError("WinHttpWebSocketCompleteUpgrade failed"))
        end

        if request ~= nil and request ~= ffi.NULL then
            winhttp_lib.WinHttpCloseHandle(request)
            request = nil
        end

        return {
            session = session,
            connect = connection,
            request = request,
            websocket = websocket,
        }
    end)

    if not ok then
        closeConnection({
            session = session,
            connect = connection,
            request = request,
            websocket = websocket,
        })
        return nil, tostring(result_or_error)
    end

    return result_or_error
end

local function sendText(connection, payload)
    local text = tostring(payload or "")
    local size = #text
    local buffer = ffi.new("uint8_t[?]", math.max(size, 1))
    if size > 0 then
        ffi.copy(buffer, text, size)
    end

    local result = winhttp_lib.WinHttpWebSocketSend(
        connection.websocket,
        WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE,
        buffer,
        size
    )
    if result ~= NO_ERROR then
        return false, string.format("WinHttpWebSocketSend failed (code=%d)", tonumber(result or 0))
    end
    return true
end

local function runSenderLoop()
    local connection, connect_error = connectWebSocket(ws_url)
    if not connection then
        pushError(connect_error)
        return
    end

    while true do
        local raw = command_channel:demand()
        local decoded, decode_error = Json.decode(tostring(raw or ""))
        if decode_error or not decoded then
            pushError("invalid sender command payload")
        elseif decoded.type == "stop" then
            break
        elseif decoded.type == "send" and decoded.payload then
            local sent, send_error = sendText(connection, tostring(decoded.payload))
            if not sent then
                pushError(send_error)
                break
            end
        end
    end

    closeConnection(connection)
end

local ok, err = pcall(runSenderLoop)
if not ok then
    pushError(err)
end
