local Controller = {}
Controller.__index = Controller

function Controller.new(options)
    local self = setmetatable({}, Controller)

    self.state = assert(options and options.state, "MainMenuController requires state")
    self.on_open_lobby = assert(options and options.on_open_lobby, "MainMenuController requires on_open_lobby")

    return self
end

function Controller:mousemoved(x, y, view)
    self.state.hovered_action = view:getActionAt(x, y, self.state.hovered_action)
end

function Controller:mousepressed(x, y, button, view)
    if button ~= 1 then
        return
    end

    local action = view:getActionAt(x, y, self.state.hovered_action)
    if not action then
        return
    end

    if action == "online_lobby" then
        self.state.status_message = ""
        self.on_open_lobby()
        return
    end

    self.state.status_message = "该功能暂未开放。"
end

return Controller
