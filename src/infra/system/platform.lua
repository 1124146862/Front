local Platform = {}
local bit = require("bit")

local ffi_ok, ffi = pcall(require, "ffi")
local ffi_defs_loaded = false

local CREATE_NO_WINDOW = 0x08000000
local DETACHED_PROCESS = 0x00000008
local STARTF_USESHOWWINDOW = 0x00000001
local SW_HIDE = 0

local function ensureWindowsFFI()
    if not ffi_ok then
        return false
    end
    if ffi_defs_loaded then
        return true
    end

    local ok = pcall(function()
        ffi.cdef([[
            typedef int BOOL;
            typedef unsigned long DWORD;
            typedef unsigned short WORD;
            typedef void* HANDLE;
            typedef unsigned short WCHAR;
            typedef const WCHAR* LPCWSTR;
            typedef WCHAR* LPWSTR;
            typedef void* LPVOID;
            typedef unsigned long ULONG_PTR;

            typedef struct _STARTUPINFOW {
                DWORD cb;
                LPWSTR lpReserved;
                LPWSTR lpDesktop;
                LPWSTR lpTitle;
                DWORD dwX;
                DWORD dwY;
                DWORD dwXSize;
                DWORD dwYSize;
                DWORD dwXCountChars;
                DWORD dwYCountChars;
                DWORD dwFillAttribute;
                DWORD dwFlags;
                WORD wShowWindow;
                WORD cbReserved2;
                unsigned char* lpReserved2;
                HANDLE hStdInput;
                HANDLE hStdOutput;
                HANDLE hStdError;
            } STARTUPINFOW;

            typedef struct _PROCESS_INFORMATION {
                HANDLE hProcess;
                HANDLE hThread;
                DWORD dwProcessId;
                DWORD dwThreadId;
            } PROCESS_INFORMATION;

            int MultiByteToWideChar(
                unsigned int CodePage,
                DWORD dwFlags,
                const char* lpMultiByteStr,
                int cbMultiByte,
                WCHAR* lpWideCharStr,
                int cchWideChar
            );

            BOOL CreateProcessW(
                LPCWSTR lpApplicationName,
                LPWSTR lpCommandLine,
                LPVOID lpProcessAttributes,
                LPVOID lpThreadAttributes,
                BOOL bInheritHandles,
                DWORD dwCreationFlags,
                LPVOID lpEnvironment,
                LPCWSTR lpCurrentDirectory,
                STARTUPINFOW* lpStartupInfo,
                PROCESS_INFORMATION* lpProcessInformation
            );

            BOOL CloseHandle(HANDLE hObject);
            DWORD GetLastError(void);
        ]])
    end)

    ffi_defs_loaded = ok
    return ok
end

local function utf8ToWideBuffer(value)
    local text = tostring(value or "")
    if not ffi_ok then
        return nil
    end

    local utf8_cp = 65001
    local required = ffi.C.MultiByteToWideChar(utf8_cp, 0, text, #text, nil, 0)
    if required <= 0 then
        return nil
    end

    local buffer = ffi.new("WCHAR[?]", required + 1)
    local converted = ffi.C.MultiByteToWideChar(utf8_cp, 0, text, #text, buffer, required)
    if converted <= 0 then
        return nil
    end

    buffer[converted] = 0
    return buffer
end

local function detectOSName()
    if love and love.system and love.system.getOS then
        return love.system.getOS() or "Unknown"
    end
    return "Unknown"
end

local function escapePattern(value)
    return tostring(value or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

function Platform.getOS()
    return detectOSName()
end

function Platform.isWindows()
    return detectOSName() == "Windows"
end

function Platform.pathSeparator()
    if Platform.isWindows() then
        return "\\"
    end
    return "/"
end

function Platform.toSystemPath(path)
    local value = tostring(path or "")
    if Platform.isWindows() then
        return value:gsub("/", "\\")
    end
    return value
end

function Platform.joinPath(...)
    local separator = Platform.pathSeparator()
    local separator_pattern = escapePattern(separator)
    local parts = {}
    for index = 1, select("#", ...) do
        local value = tostring(select(index, ...) or "")
        if value ~= "" then
            local normalized = Platform.toSystemPath(value)
            if #parts == 0 then
                normalized = normalized:gsub(separator_pattern .. "+$", "")
            else
                normalized = normalized:gsub("^" .. separator_pattern .. "+", ""):gsub(separator_pattern .. "+$", "")
            end
            parts[#parts + 1] = normalized
        end
    end
    return table.concat(parts, separator)
end

function Platform.quoteArg(value)
    local text = tostring(value or "")
    if Platform.isWindows() then
        return '"' .. text:gsub('"', '""') .. '"'
    end
    return "'" .. text:gsub("'", "'\"'\"'") .. "'"
end

function Platform.joinArgs(args)
    local parts = {}
    for _, value in ipairs(args or {}) do
        parts[#parts + 1] = Platform.quoteArg(value)
    end
    return table.concat(parts, " ")
end

function Platform.formatCurlWriteOut(value)
    local text = tostring(value or "")
    if Platform.isWindows() then
        return text:gsub("\r", ""):gsub("\n", "")
    end
    return text
end

function Platform.quotePowerShellLiteral(value)
    local text = tostring(value or "")
    return "'" .. text:gsub("'", "''") .. "'"
end

function Platform.buildHiddenPowerShellCommand(script)
    local text = tostring(script or "")
    return table.concat({
        "powershell.exe",
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy",
        "Bypass",
        "-WindowStyle",
        "Hidden",
        "-Command",
        Platform.quoteArg(text),
    }, " ")
end

function Platform.buildDetachedCommand(args)
    if Platform.isWindows() then
        local command_args = args or {}
        local file_path = tostring(command_args[1] or "")
        if file_path == "" then
            return ""
        end

        local ps_parts = {}
        for index = 2, #command_args do
            ps_parts[#ps_parts + 1] = Platform.quotePowerShellLiteral(command_args[index])
        end

        local ps_command = ""
        if #ps_parts > 0 then
            ps_command = string.format(
                "Start-Process -WindowStyle Hidden -FilePath %s -ArgumentList @(%s)",
                Platform.quotePowerShellLiteral(file_path),
                table.concat(ps_parts, ", ")
            )
        else
            ps_command = string.format(
                "Start-Process -WindowStyle Hidden -FilePath %s",
                Platform.quotePowerShellLiteral(file_path)
            )
        end

        return Platform.buildHiddenPowerShellCommand(ps_command)
    end
    local joined = Platform.joinArgs(args)
    return joined .. " > /dev/null 2>&1 &"
end

function Platform.buildKillCommand(pid)
    local safe_pid = tostring(pid or ""):match("^(%d+)$")
    if not safe_pid then
        return nil
    end

    if Platform.isWindows() then
        return "taskkill /PID " .. safe_pid .. " /T /F > NUL 2>&1"
    end
    return "kill " .. safe_pid .. " > /dev/null 2>&1"
end

function Platform.spawnDetached(args)
    if Platform.isWindows() and ensureWindowsFFI() then
        local command_line = Platform.joinArgs(args or {})
        if command_line == "" then
            return false, "empty command line"
        end

        local cmd_wide = utf8ToWideBuffer(command_line)
        if cmd_wide == nil then
            return false, "failed to convert command line to utf16"
        end

        local startup_info = ffi.new("STARTUPINFOW")
        startup_info.cb = ffi.sizeof(startup_info)
        startup_info.dwFlags = STARTF_USESHOWWINDOW
        startup_info.wShowWindow = SW_HIDE

        local process_info = ffi.new("PROCESS_INFORMATION")

        local created = ffi.C.CreateProcessW(
            nil,
            cmd_wide,
            nil,
            nil,
            0,
            bit.bor(CREATE_NO_WINDOW, DETACHED_PROCESS),
            nil,
            nil,
            startup_info,
            process_info
        )

        if created == 0 then
            return false, string.format("CreateProcessW failed with error=%d", tonumber(ffi.C.GetLastError()))
        end

        ffi.C.CloseHandle(process_info.hThread)
        ffi.C.CloseHandle(process_info.hProcess)
        return true
    end

    local command = Platform.buildDetachedCommand(args)
    if command == "" then
        return false, "empty command"
    end
    os.execute(command)
    return true
end

function Platform.killProcess(pid)
    local safe_pid = tostring(pid or ""):match("^(%d+)$")
    if not safe_pid then
        return false
    end

    if Platform.isWindows() then
        return Platform.spawnDetached({ "taskkill", "/PID", safe_pid, "/T", "/F" })
    end

    os.execute("kill " .. safe_pid .. " > /dev/null 2>&1")
    return true
end

return Platform
