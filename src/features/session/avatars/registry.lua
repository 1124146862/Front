-- Old avatar files use bare requires like require("AvatarSkeleton").
-- Register aliases here so the runtime loader can resolve them without
-- changing the avatar files or the test entry points.
package.preload["AvatarSkeleton"] = package.preload["AvatarSkeleton"]
    or function()
        return require("src.features.session.avatars.AvatarSkeleton")
    end

package.preload["avatar_definitions"] = package.preload["avatar_definitions"]
    or function()
        return require("src.features.session.avatars.avatar_definitions")
    end

local avatars = {}

local function isValidAvatarModule(avatar)
    return type(avatar) == "table"
        and type(avatar.id) == "string"
        and type(avatar.draw) == "function"
end

local function makeFallbackAvatar(index)
    local hue = ((index - 1) % 6) + 1
    local palettes = {
        { bg = { 0.98, 0.94, 0.84, 1 }, primary = { 0.79, 0.50, 0.23, 1 }, secondary = { 0.92, 0.77, 0.43, 1 }, detail = { 0.39, 0.25, 0.12, 1 } },
        { bg = { 0.91, 0.96, 0.89, 1 }, primary = { 0.33, 0.59, 0.35, 1 }, secondary = { 0.63, 0.80, 0.49, 1 }, detail = { 0.16, 0.31, 0.16, 1 } },
        { bg = { 0.90, 0.95, 0.98, 1 }, primary = { 0.29, 0.48, 0.76, 1 }, secondary = { 0.58, 0.72, 0.92, 1 }, detail = { 0.14, 0.23, 0.39, 1 } },
        { bg = { 0.96, 0.90, 0.98, 1 }, primary = { 0.52, 0.39, 0.78, 1 }, secondary = { 0.74, 0.66, 0.92, 1 }, detail = { 0.28, 0.21, 0.46, 1 } },
        { bg = { 0.99, 0.92, 0.92, 1 }, primary = { 0.79, 0.37, 0.37, 1 }, secondary = { 0.93, 0.65, 0.65, 1 }, detail = { 0.42, 0.17, 0.17, 1 } },
        { bg = { 0.95, 0.95, 0.87, 1 }, primary = { 0.58, 0.54, 0.23, 1 }, secondary = { 0.82, 0.79, 0.46, 1 }, detail = { 0.31, 0.29, 0.12, 1 } },
    }

    return {
        id = ("avatar_%d"):format(index),
        seed = hue,
        colors = palettes[hue],
    }
end

local function tryLoadModule(module_name)
    local ok, avatar = pcall(require, module_name)
    if not ok then
        return nil, avatar
    end
    if isValidAvatarModule(avatar) then
        return avatar, nil
    end
    return nil, ("module '%s' returned %s, expected avatar table"):format(module_name, type(avatar))
end

local function loadAvatar(index)
    local lower_name = ("src.features.session.avatars.avatar_%d"):format(index)
    local upper_name = ("src.features.session.avatars.Avatar%d"):format(index)
    local avatar, lower_error = tryLoadModule(lower_name)
    if avatar then
        return avatar
    end

    avatar, upper_error = tryLoadModule(upper_name)
    if avatar then
        return avatar
    end

    print(("[avatars] fallback for avatar_%d | lower=%s | upper=%s"):format(
        index,
        tostring(lower_error),
        tostring(upper_error)
    ))
    return makeFallbackAvatar(index)
end

for index = 1, 45 do
    avatars[#avatars + 1] = loadAvatar(index)
end

return avatars
