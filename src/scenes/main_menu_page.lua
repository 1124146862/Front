local Controller = require("src.features.main_menu.controller")
local Style = require("src.features.main_menu.style")
local MainMenuView = require("src.features.main_menu.views.main_menu_view")

local MainMenuPage = {}
MainMenuPage.__index = MainMenuPage

function MainMenuPage.new(options)
    local self = setmetatable({}, MainMenuPage)

    local fonts = assert(options and options.fonts, "MainMenuPage requires fonts")
    local on_open_lobby = assert(options and options.on_open_lobby, "MainMenuPage requires on_open_lobby")

    self.user_profile = (options and options.user_profile) or {}
    self.state = {
        hovered_action = nil,
        status_message = "请选择要进入的模式。",
    }
    self.view = MainMenuView.new({
        fonts = fonts,
        style = Style,
    })
    self.controller = Controller.new({
        state = self.state,
        on_open_lobby = on_open_lobby,
    })

    return self
end

function MainMenuPage:draw()
    self.view:draw(self.state, self.user_profile)
end

function MainMenuPage:mousemoved(x, y)
    self.controller:mousemoved(x, y, self.view)
end

function MainMenuPage:mousepressed(x, y, button)
    self.controller:mousepressed(x, y, button, self.view)
end

function MainMenuPage:resize()
    self.view:resize()
end

return MainMenuPage
