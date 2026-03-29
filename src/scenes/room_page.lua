local Controller = require("src.features.room.controller")
local RoomService = require("src.features.room.service")
local State = require("src.features.room.state")
local Style = require("src.features.room.style")
local RoomView = require("src.features.room.views.room_view")
local HttpClient = require("src.infra.network.http_client")

local RoomPage = {}
RoomPage.__index = RoomPage

function RoomPage.new(options)
    local self = setmetatable({}, RoomPage)

    local fonts = assert(options and options.fonts, "RoomPage requires fonts")
    local room_id = assert(options and options.room_id, "RoomPage requires room_id")
    local user_profile = assert(options and options.user_profile, "RoomPage requires user_profile")
    local on_back_to_lobby = assert(options and options.on_back_to_lobby, "RoomPage requires on_back_to_lobby")
    local on_game_started = assert(options and options.on_game_started, "RoomPage requires on_game_started")

    self.state = State.create(room_id, user_profile)
    self.view = RoomView.new({
        fonts = fonts,
        style = Style,
    })
    self.controller = Controller.new({
        state = self.state,
        service = RoomService.new({
            http_client = HttpClient.new(),
        }),
        on_back_to_lobby = on_back_to_lobby,
        on_game_started = on_game_started,
    })

    return self
end

function RoomPage:draw()
    self.view:draw(self.state)
end

function RoomPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function RoomPage:mousepressed(x, y, button)
    self.controller:mousepressed(x, y, button, self.view)
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

return RoomPage
