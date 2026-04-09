local Controller = require("src.features.lobby.controller")
local LobbyService = require("src.features.lobby.service")
local State = require("src.features.lobby.state")
local Style = require("src.features.lobby.style")
local LobbyView = require("src.features.lobby.views.lobby_view")
local HttpClient = require("src.infra.network.http_client")
local LoadingOverlay = require("src.core.ui.loading_overlay")

local LobbyPage = {}
LobbyPage.__index = LobbyPage

function LobbyPage.new(options)
    local self = setmetatable({}, LobbyPage)

    local fonts = assert(options and options.fonts, "LobbyPage requires fonts")
    local on_back = assert(options and options.on_back, "LobbyPage requires on_back")
    local on_enter_room = assert(options and options.on_enter_room, "LobbyPage requires on_enter_room")
    local user_profile = assert(options and options.user_profile, "LobbyPage requires user_profile")

    self.backgrounds = options and options.backgrounds or nil
    self.state = State.create()
    self.view = LobbyView.new({
        fonts = fonts,
        style = Style,
    })
    self.loading_overlay = LoadingOverlay.new({
        fonts = fonts,
        message_key = "common.loading",
    })
    self.controller = Controller.new({
        state = self.state,
        service = LobbyService.new({
            http_client = HttpClient.new(),
        }),
        user_profile = user_profile,
        on_back = on_back,
        on_enter_room = on_enter_room,
    })

    return self
end

function LobbyPage:update(dt)
    self.controller:update(dt)
    local state = self.state
    local busy = state.server_loading_visible
        or state.loading
        or state.submitting
    if busy then
        self.loading_overlay:show(state.server_loading_message or state.status_message)
    else
        self.loading_overlay:hide()
    end
    self.loading_overlay:update(dt)
end

function LobbyPage:draw()
    self.view:draw(self.state)
    self.loading_overlay:draw(love.graphics.getWidth(), love.graphics.getHeight())
end

function LobbyPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function LobbyPage:mousepressed(x, y, button)
    return self.controller:mousepressed(x, y, button, self.view)
end

function LobbyPage:keypressed(key)
    self.controller:keypressed(key)
end

function LobbyPage:textinput(text)
    self.controller:appendText(text)
end

function LobbyPage:resize()
    self.view:resize()
end

return LobbyPage
