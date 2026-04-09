local AppConfig = require("src.core.config.app_config")

local Resolver = {}

function Resolver.resolveDefaultNetwork()
    return AppConfig.getDefaultNetwork()
end

return Resolver
