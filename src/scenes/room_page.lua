local Controller = require("src.features.room.controller")
local RoomService = require("src.features.room.service")
local State = require("src.features.room.state")
local Style = require("src.features.room.style")
local RoomView = require("src.features.room.views.room_view")
local HttpClient = require("src.infra.network.http_client")
local RoomWebSocketClient = require("src.infra.network.room_ws_client")
local LoadingOverlay = require("src.core.ui.loading_overlay")

local RoomPage = {}
RoomPage.__index = RoomPage

function RoomPage.new(options)
    local self = setmetatable({}, RoomPage)

    local fonts = assert(options and options.fonts, "RoomPage requires fonts")
    local room_id = assert(options and options.room_id, "RoomPage requires room_id")
    local user_profile = assert(options and options.user_profile, "RoomPage requires user_profile")
    local on_back_to_lobby = assert(options and options.on_back_to_lobby, "RoomPage requires on_back_to_lobby")
    local on_game_started = assert(options and options.on_game_started, "RoomPage requires on_game_started")
    local auto_single_player_bootstrap = options and options.auto_single_player_bootstrap == true

    self.backgrounds = options and options.backgrounds or nil
    self.state = State.create(room_id, user_profile, {
        auto_single_player_bootstrap = auto_single_player_bootstrap,
    })
    self.view = RoomView.new({
        fonts = fonts,
        style = Style,
    })
    self.loading_overlay = LoadingOverlay.new({
        fonts = fonts,
        message_key = "common.loading",
    })
    self.controller = Controller.new({
        state = self.state,
        service = RoomService.new({
            http_client = HttpClient.new(),
            ws_client = RoomWebSocketClient.new(),
        }),
        on_back_to_lobby = on_back_to_lobby,
        on_game_started = on_game_started,
        auto_single_player_bootstrap = auto_single_player_bootstrap,
    })

    return self
end

function RoomPage:update(dt)
    self.controller:update(dt)
    local state = self.state
    local busy = state.server_loading_visible
        or state.loading
        or state.saving
        or state.leaving
    if busy then
        self.loading_overlay:show(state.server_loading_message or state.status_message)
    else
        self.loading_overlay:hide()
    end
    self.loading_overlay:update(dt)
end

function RoomPage:draw()
    self.view:draw(self.state)
    self.loading_overlay:draw(love.graphics.getWidth(), love.graphics.getHeight())
end

function RoomPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function RoomPage:mousepressed(x, y, button)
    return self.controller:mousepressed(x, y, button, self.view)
end

function RoomPage:keypressed(key)
    self.controller:keypressed(key)
end

function RoomPage:textinput(text)
    self.controller:appendText(text)
end

function RoomPage:resize()
    self.view:resize()
end

function RoomPage:shutdown()
    self.controller:shutdown()
end

return RoomPage
