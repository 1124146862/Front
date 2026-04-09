local LocaleUtils = {}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copied = {}
    for key, item in pairs(value) do
        copied[key] = deepCopy(item)
    end
    return copied
end

local function deepMerge(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        else
            target[key] = deepCopy(value)
        end
    end
    return target
end

function LocaleUtils.extend(base_locale, overrides)
    return deepMerge(deepCopy(base_locale or {}), overrides or {})
end

return LocaleUtils
