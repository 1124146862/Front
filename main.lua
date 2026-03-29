local FontManager = require("src.core.font_manager")
local GameplayPage = require("src.scenes.gameplay_page")
local LobbyPage = require("src.scenes.lobby_page")
local MainMenuPage = require("src.scenes.main_menu_page")
local NicknameCheckPage = require("src.scenes.nickname_check_page")
local RoomPage = require("src.scenes.room_page")
local WelcomePage = require("src.scenes.welcome_page")

local app = {
    fonts = nil,
    scene = nil,
    user_profile = {},
}

local showMainMenuPage
local showRoomPage
local showGameplayPage

showGameplayPage = function(room)
    app.scene = GameplayPage.new({
        fonts = app.fonts,
        room = room,
    })
end

showRoomPage = function(room_id)
    app.scene = RoomPage.new({
        fonts = app.fonts,
        room_id = room_id,
        user_profile = app.user_profile,
        on_back_to_lobby = function()
            app.scene = LobbyPage.new({
                fonts = app.fonts,
                user_profile = app.user_profile,
                on_back = function()
                    showMainMenuPage()
                end,
                on_enter_room = function(next_room_id)
                    showRoomPage(next_room_id)
                end,
            })
        end,
        on_game_started = function(room)
            showGameplayPage(room)
        end,
    })
end

showMainMenuPage = function(user_profile)
    app.user_profile = user_profile or app.user_profile or {}
    app.scene = MainMenuPage.new({
        fonts = app.fonts,
        user_profile = app.user_profile,
        on_open_lobby = function()
            app.scene = LobbyPage.new({
                fonts = app.fonts,
                user_profile = app.user_profile,
                on_back = function()
                    showMainMenuPage()
                end,
                on_enter_room = function(room_id)
                    showRoomPage(room_id)
                end,
            })
        end,
    })
end

local function showNicknameCheckPage()
    app.scene = NicknameCheckPage.new({
        fonts = app.fonts,
        on_session_ready = function(user_profile)
            showMainMenuPage(user_profile)
        end,
    })
end

local function showWelcomePage()
    app.scene = WelcomePage.new({
        fonts = app.fonts,
        on_continue = function()
            showNicknameCheckPage()
        end,
    })
end

function love.load()
    love.graphics.setBackgroundColor(0.05, 0.07, 0.09, 1)
    love.keyboard.setKeyRepeat(false)

    app.fonts = FontManager.new({
        font_path = "assets/fonts/zh.otf",
    })

    showWelcomePage()
end

function love.update(dt)
    if app.scene and app.scene.update then
        app.scene:update(dt)
    end
end

function love.draw()
    if app.scene and app.scene.draw then
        app.scene:draw()
    end
end

function love.mousemoved(x, y, dx, dy)
    if app.scene and app.scene.mousemoved then
        app.scene:mousemoved(x, y, dx, dy)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if app.scene and app.scene.mousepressed then
        app.scene:mousepressed(x, y, button, istouch, presses)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if app.scene and app.scene.keypressed then
        app.scene:keypressed(key, scancode, isrepeat)
    end
end

function love.textinput(text)
    if app.scene and app.scene.textinput then
        app.scene:textinput(text)
    end
end

function love.resize(width, height)
    if app.scene and app.scene.resize then
        app.scene:resize(width, height)
    end
end
