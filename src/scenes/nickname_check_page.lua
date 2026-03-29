local Controller = require("src.features.session.controller")
local SessionService = require("src.features.session.service")
local State = require("src.features.session.state")
local SteamIDProvider = require("src.features.session.steam_id_provider")
local Style = require("src.features.session.style")
local NicknameCheckView = require("src.features.session.views.nickname_check_view")
local HttpClient = require("src.infra.network.http_client")

local NicknameCheckPage = {}
NicknameCheckPage.__index = NicknameCheckPage

function NicknameCheckPage.new(options)
    local self = setmetatable({}, NicknameCheckPage)

    local fonts = assert(options and options.fonts, "NicknameCheckPage requires fonts")
    local on_session_ready = assert(options and options.on_session_ready, "NicknameCheckPage requires on_session_ready")

    self.state = State.create()
    self.view = NicknameCheckView.new({
        fonts = fonts,
        style = Style,
    })
    self.controller = Controller.new({
        state = self.state,
        service = SessionService.new({
            http_client = HttpClient.new(),
        }),
        steam_id_provider = SteamIDProvider.new(),
        on_session_ready = on_session_ready,
    })

    return self
end

function NicknameCheckPage:update(dt)
    self.controller:update(dt)
end

function NicknameCheckPage:draw()
    self.view:draw(self.state)
end

function NicknameCheckPage:mousemoved(x, y)
    self.controller:setHovered(x, y, self.view)
end

function NicknameCheckPage:mousepressed(x, y, button)
    self.controller:mousepressed(x, y, button, self.view)
end

function NicknameCheckPage:keypressed(key)
    self.controller:keypressed(key)
end

function NicknameCheckPage:textinput(text)
    self.controller:appendText(text)
end

function NicknameCheckPage:resize(width, height)
    self.view:resize(width, height)
end

return NicknameCheckPage
