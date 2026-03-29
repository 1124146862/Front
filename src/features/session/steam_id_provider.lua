local SteamIDProvider = {}
SteamIDProvider.__index = SteamIDProvider

local cached_steam_id = nil

local function generateSteamID()
    local min_value = 1000000000
    local max_value = 9999999999

    love.math.setRandomSeed(os.time())

    return love.math.random(min_value, max_value)
end

function SteamIDProvider.new()
    local self = setmetatable({}, SteamIDProvider)
    return self
end

function SteamIDProvider:getSteamID()
    if not cached_steam_id then
        cached_steam_id = generateSteamID()
    end

    return cached_steam_id
end

return SteamIDProvider
