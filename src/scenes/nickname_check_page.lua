local Controller = require("src.features.session.controller")
local SessionService = require("src.features.session.service")
local State = require("src.features.session.state")
local Style = require("src.features.session.style")
local NicknameCheckView = require("src.features.session.views.nickname_check_view")
local HttpClient = require("src.infra.network.http_client")
local LoadingOverlay = require("src.core.ui.loading_overlay")

local NicknameCheckPage = {}
NicknameCheckPage.__index = NicknameCheckPage

function NicknameCheckPage.new(options)
    local self = setmetatable({}, NicknameCheckPage)

    local fonts = assert(options and options.fonts, "NicknameCheckPage requires fonts")
    local on_session_ready = assert(options and options.on_session_ready, "NicknameCheckPage requires on_session_ready")
    local on_close = options and options.on_close or nil
    local backgrounds = options and options.backgrounds or nil

    self.state = State.create()
    self.view = NicknameCheckView.new({
        fonts = fonts,
        style = Style,
        backgrounds = backgrounds,
        show_close = on_close ~= nil,
    })
    self.controller = Controller.new({
        state = self.state,
        service = SessionService.new({
            http_client = HttpClient.new(),
        }),
        initial_steam_id = options and options.initial_steam_id or nil,
        initial_fetch_result = options and options.initial_fetch_result or nil,
        force_edit = options and options.force_edit or false,
        auto_randomize = options and options.auto_randomize or false,
        on_session_ready = on_session_ready,
    })
    self.on_close = on_close
    self.loading_overlay = LoadingOverlay.new({
        fonts = fonts,
        message_key = "common.loading",
    })

    return self
end

function NicknameCheckPage:update(dt)
    self.controller:update(dt)
    local busy = self.state.query_pending == true
        or self.state.submit_pending == true
        or self.state.phase == "checking"
    if busy then
        self.loading_overlay:show()
    else
        self.loading_overlay:hide()
    end
    self.loading_overlay:update(dt)
end

function NicknameCheckPage:draw()
    self.view:draw(self.state)
    self.loading_overlay:draw(love.graphics.getWidth(), love.graphics.getHeight())
end

function NicknameCheckPage:mousemoved(x, y)
    if self.loading_overlay:isVisible() then
        self.state.close_button_hovered = false
        self.controller:setHovered(-9999, -9999, self.view)
        return
    end
    self.state.close_button_hovered = self.on_close ~= nil and self.view:isCloseButtonHovered(x, y) or false
    self.controller:setHovered(x, y, self.view)
end

function NicknameCheckPage:mousepressed(x, y, button)
    if self.loading_overlay:isVisible() then
        return true
    end
    if button == 1 and self.on_close and self.view:isCloseButtonHovered(x, y) then
        self.on_close()
        return true
    end
    return self.controller:mousepressed(x, y, button, self.view)
end

function NicknameCheckPage:keypressed(key)
    if self.loading_overlay:isVisible() then
        return
    end
    self.controller:keypressed(key)
end

function NicknameCheckPage:textinput(text)
    if self.loading_overlay:isVisible() then
        return
    end
    self.controller:appendText(text)
end

function NicknameCheckPage:resize(width, height)
    self.view:resize(width, height)
end

return NicknameCheckPage
