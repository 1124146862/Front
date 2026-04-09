local AvatarRegistry = require("src.features.session.avatars.registry")
local AvatarTile = require("src.features.session.components.avatar_tile")
local NicknameCheckButton = require("src.features.session.components.nickname_check_button")
local NicknameCheckInput = require("src.features.session.components.nickname_check_input")
local NicknameCheckChrome = require("src.features.session.components.nickname_check_chrome")
local NicknameCheckLayout = require("src.features.session.layouts.nickname_check_layout")
local WoodPanel = require("src.core.ui.wood_panel")
local WoodButton = require("src.core.ui.wood_button")
local ButtonText = require("src.core.ui.button_text")
local I18n = require("src.core.i18n.i18n")

local NicknameCheckView = {}
NicknameCheckView.__index = NicknameCheckView

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function inside(frame, x, y)
    return x >= frame.x and x <= frame.x + frame.w and y >= frame.y and y <= frame.y + frame.h
end

function NicknameCheckView.new(options)
    local self = setmetatable({}, NicknameCheckView)

    self.fonts = assert(options and options.fonts, "NicknameCheckView requires fonts")
    self.style = assert(options and options.style, "NicknameCheckView requires style")
    self.backgrounds = options and options.backgrounds or nil
    self.show_close = options and options.show_close == true
    self.avatars_by_id = {}
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.input = NicknameCheckInput.new(self.style)
    self.button = NicknameCheckButton.new(self.style)
    self.wood_panel = WoodPanel.new(self.style)
    self.layout = {}

    for _, avatar in ipairs(AvatarRegistry) do
        self.avatars_by_id[avatar.id] = avatar
    end

    self:resize(self.window_width, self.window_height)

    return self
end

function NicknameCheckView:resize(width, height, state)
    self.window_width = width
    self.window_height = height
    self.layout = NicknameCheckLayout.compute(
        self.style,
        width,
        height,
        self.show_close,
        state and #(state.avatar_visible_ids or {}) or (self.style.avatar.columns * self.style.avatar.rows)
    )

    self.input:setBounds(
        self.layout.input.x,
        self.layout.input.y,
        self.layout.input.w,
        self.layout.input.h
    )
    self.button:setBounds(
        self.layout.button.x,
        self.layout.button.y,
        self.layout.button.w,
        self.layout.button.h
    )
end

function NicknameCheckView:isInputHovered(x, y)
    return self.input:contains(x, y)
end

function NicknameCheckView:isButtonHovered(x, y)
    return self.button:contains(x, y)
end

function NicknameCheckView:isRandomButtonHovered(x, y)
    local bounds = self.layout.random_button
    return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

function NicknameCheckView:isAvatarPrevHovered(x, y)
    local bounds = self.layout.avatar_pager_prev
    return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

function NicknameCheckView:isAvatarNextHovered(x, y)
    local bounds = self.layout.avatar_pager_next
    return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

function NicknameCheckView:isCloseButtonHovered(x, y)
    return self.layout.close_button and inside(self.layout.close_button, x, y)
end

function NicknameCheckView:getAvatarFrames(state)
    local frames = {}
    local tile = self.style.avatar.tile
    local gap = self.style.avatar.gap
    local grid = self.layout.avatar_grid
    local columns = self.style.avatar.columns

    for index, avatar_id in ipairs(state.avatar_visible_ids or {}) do
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        frames[#frames + 1] = {
            avatar_id = avatar_id,
            x = grid.x + col * (tile + gap),
            y = grid.y + row * (tile + gap),
            w = tile,
            h = tile,
        }
    end

    return frames
end

function NicknameCheckView:getAvatarAt(x, y, state)
    for _, frame in ipairs(self:getAvatarFrames(state)) do
        if x >= frame.x and x <= frame.x + frame.w and y >= frame.y and y <= frame.y + frame.h then
            return frame.avatar_id
        end
    end

    return nil
end

function NicknameCheckView:draw(state)
    local colors = self.style.colors
    self:resize(self.window_width, self.window_height, state)

    local panel = self.layout.panel
    local effective_avatar_id = state.selected_avatar_id or state.avatar_visible_ids[1]

    if self.backgrounds then
        self.backgrounds:draw("MainMenuBG")
    else
        love.graphics.clear(0.28, 0.66, 0.95, 1)
    end

    self.wood_panel:draw({
        x = panel.x,
        y = panel.y,
        width = panel.w,
        height = panel.h,
    }, {
        radius = self.style.panel.radius,
        shadow_offset = 8,
    })

    love.graphics.setFont(self.fonts:get("Title3"))
    love.graphics.setColor(colors.text_primary[1], colors.text_primary[2], colors.text_primary[3], colors.text_primary[4])
    local title_text = I18n:t("session.set_nickname")
    love.graphics.printf(title_text, self.layout.title.x, self.layout.title.y, self.layout.title.w, "center")
    love.graphics.printf(title_text, self.layout.title.x + 1, self.layout.title.y, self.layout.title.w, "center")
    if self.layout.close_button then
        NicknameCheckChrome.drawCloseButton(self.fonts, self.style, self.layout.close_button, state.close_button_hovered)
    end

    local press_feedback = state.press_feedback or {}
    local steam_id_value = tostring(state.steam_id or "")

    if steam_id_value ~= "" then
        local steam_id_text = string.format("%s: %s", I18n:t("session.steam_id"), steam_id_value)
        local steam_id_font = self.fonts:get("Caption")
        local steam_id_y = self.layout.steam_id.y + math.floor((self.layout.steam_id.h - steam_id_font:getHeight()) * 0.5) - 1
        ButtonText.draw(
            steam_id_font,
            steam_id_text,
            self.layout.steam_id.x,
            steam_id_y,
            self.layout.steam_id.w,
            "left",
            { 0.08, 0.08, 0.08, 1 },
            {
                bold = true,
                bold_offset = 1,
            }
        )
    end

    self.input:draw(self.fonts, state.nickname_input, I18n:t("session.input_placeholder"), state.input_focused)
    local random_pressed = (press_feedback.random or 0) > 0
    local random_offset = random_pressed and 2 or 0
    WoodButton.draw(self.fonts, self.style, {
        label = I18n:t("session.random_short"),
        x = self.layout.random_button.x,
        y = self.layout.random_button.y + random_offset,
        width = self.layout.random_button.w,
        height = self.layout.random_button.h,
        hovered = state.random_button_hovered,
        enabled = true,
        variant = "secondary",
        font_token = "TextSmall",
        radius = self.style.small_button.radius,
        shadow_offset = random_pressed and 2 or 6,
        light_chrome = false,
    })

    NicknameCheckChrome.drawSoftPanel(self.layout.avatar_section, self.style.avatar.section_radius + 4, "section")
    for _, frame in ipairs(self:getAvatarFrames(state)) do
        AvatarTile.draw(self.style, self.avatars_by_id[frame.avatar_id], frame, {
            hovered = state.hovered_avatar_id == frame.avatar_id,
            selected = effective_avatar_id == frame.avatar_id,
            compact = true,
            candidate_grid = true,
            content_padding_ratio = 0.01,
        })
    end

    if effective_avatar_id and self.avatars_by_id[effective_avatar_id] then
        AvatarTile.draw(self.style, self.avatars_by_id[effective_avatar_id], self.layout.avatar_preview, {
            hovered = false,
            selected = true,
            preview = true,
            content_padding_ratio = 0.035,
        })
    end

    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.setColor(colors.text_secondary[1], colors.text_secondary[2], colors.text_secondary[3], 0.88)
    love.graphics.printf(
        I18n:t("session.selected_avatar"),
        self.layout.avatar_preview_label.x,
        self.layout.avatar_preview_label.y,
        self.layout.avatar_preview_label.w,
        "center"
    )

    NicknameCheckChrome.drawSoftButton(self.fonts, self.style, self.layout.avatar_pager_prev, I18n:t("lobby.prev_page"), state.hovered_avatar_prev, {
        font_token = "Caption",
        radius = 14,
        pressed = (press_feedback.avatar_prev or 0) > 0,
    })
    NicknameCheckChrome.drawSoftButton(self.fonts, self.style, self.layout.avatar_pager_next, I18n:t("lobby.next_page"), state.hovered_avatar_next, {
        font_token = "Caption",
        radius = 14,
        pressed = (press_feedback.avatar_next or 0) > 0,
    })

    if state.error_message ~= "" then
        love.graphics.setColor(colors.error[1], colors.error[2], colors.error[3], colors.error[4])
        love.graphics.print(state.error_message, self.layout.error.x, self.layout.error.y)
    end

    local button_label = state.submit_pending and I18n:t("session.submitting") or I18n:t("session.submit")
    NicknameCheckChrome.drawSoftButton(self.fonts, self.style, self.layout.button, button_label, state.button_hovered, {
        font_token = "Text",
        radius = 18,
        pressed = (press_feedback.submit or 0) > 0,
    })
end

return NicknameCheckView
