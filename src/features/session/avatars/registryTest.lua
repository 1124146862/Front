local avatars = {}
local definitions = require("avatar_definitions")

local function safeRequire(module_name)
    local ok, result = pcall(require, module_name)
    if ok then
        return result
    end
    return nil
end

for index = 1, #definitions do
    avatars[index] = safeRequire(("avatar_%d"):format(index)) or definitions[index]
end

return avatars