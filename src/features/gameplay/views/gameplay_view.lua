local PlayerHUD = require("src.features.gameplay.components.player_hud")
local PlayerHandCount = require("src.features.gameplay.components.player_hand_count")
local GamePlayTimer = require("src.features.gameplay.components.gameplay_timer")
local ActionBar = require("src.features.gameplay.components.action_bar")
local LastPlayFlyAnimation = require("src.features.gameplay.components.last_play_fly_animation")
local DealAnimationOverlay = require("src.features.gameplay.overlays.deal_animation_overlay")
local HandAreaOverlay = require("src.features.gameplay.overlays.hand_area_overlay")
local LastPlayRegion = require("src.features.gameplay.components.last_play_region")
local PassRegion = require("src.features.gameplay.components.pass_region")
local VisibilityManager = require("src.features.gameplay.visibility_manager")
local TributeOverlay = require("src.features.gameplay.overlays.tribute_overlay")
local RoundInfoOverlay = require("src.features.gameplay.overlays.round_info_overlay")
local WildcardInfoOverlay = require("src.features.gameplay.overlays.wildcard_info_overlay")
local SettlementOverlay = require("src.features.gameplay.overlays.settlement_overlay")
local RemainingCardsOverlay = require("src.features.gameplay.overlays.remaining_cards_overlay")
local Helpers = require("src.features.gameplay.controllers.helpers")
local RematchOverlay = require("src.features.gameplay.overlays.rematch_overlay_wood")
local GameplaySettingsOverlay = require("src.features.gameplay.overlays.gameplay_settings_overlay")
local PlayerProfileOverlay = require("src.features.gameplay.overlays.player_profile_overlay")
local GameplayLayout = require("src.features.gameplay.layouts.gameplay_layout")
local ConfirmationDialog = require("src.core.ui.confirmation_dialog")
local MuteButton = require("src.core.ui.mute_button")
local Toast = require("src.core.ui.toast")
local LoadingOverlay = require("src.core.ui.loading_overlay")
local I18n = require("src.core.i18n.i18n")
local AppConfig = require("src.core.config.app_config")

local GameplayView = {}
GameplayView.__index = GameplayView

local SHOW_DEBUG_AUTOPLAY_BUTTON = AppConfig.isDevMode()

local function contains(bounds, x, y)
    return x >= bounds.x
        and x <= bounds.x + bounds.width
        and y >= bounds.y
        and y <= bounds.y + bounds.height
end

local function measureTextWidth(fonts, token, text)
    return fonts:get(token):getWidth(tostring(text or ""))
end

local function getRoundInfoLabel()
    return I18n:t("gameplay.round_info_button")
end

local function getRelativePositionLabel(my_seat_index, other_seat_index)
    local relative = (other_seat_index - my_seat_index + 4) % 4
    if relative == 0 then
        return "self"
    end
    if relative == 1 then
        return "next"
    end
    if relative == 2 then
        return "opposite"
    end
    return "previous"
end

local function getRelativePositionText(role_key)
    if role_key == "self" then
        return I18n:t("gameplay.self")
    end
    if role_key == "next" then
        return I18n:t("gameplay.next")
    end
    if role_key == "opposite" then
        return I18n:t("gameplay.opposite")
    end
    return I18n:t("gameplay.previous")
end

local function hasOpeningPlayStarted(state)
    local last_play = (state or {}).last_play or {}
    return type(last_play.cards) == "table" and #last_play.cards > 0
end

local function isArrangeCountdownActive(state)
    state = state or {}
    local arrange_remaining = tonumber(state.arrange_remaining) or 0
    local turn_countdown_remaining = tonumber(state.turn_countdown_remaining) or 0
    local arrange_visible = state.arrange_hold_visible == true or arrange_remaining > 0
    return arrange_visible
        and state.reveal_cards == true
        and (turn_countdown_remaining <= 0)
end

local function buildArrangeHint(state)
    state = state or {}
    if not isArrangeCountdownActive(state) then
        return nil
    end

    local arrange_remaining = tonumber(state.arrange_remaining) or 0
    local remaining = arrange_remaining
    if state.arrange_zero_hold == true and (tonumber(state.turn_countdown_remaining) or 0) <= 0 then
        remaining = 0
    end
    local duration = math.max(tonumber(state.arrange_duration) or 0, remaining, 1)

    return {
        remaining = remaining,
        duration = duration,
        label = I18n:t("gameplay.arrange_time"),
    }
end

local function resolveOpeningActorSeat(state)
    local game = (state or {}).game or {}
    if not hasOpeningPlayStarted(state) then
        local opening_actor_seat = tonumber(game.opening_actor_seat)
        if opening_actor_seat ~= nil then
            return opening_actor_seat
        end
        local open_card_seat = tonumber(game.open_card_seat)
        if open_card_seat ~= nil then
            return open_card_seat
        end
    end
    return tonumber(game.current_actor_seat)
end

local function getOpeningLeadRole(state, arrange_hint)
    if not arrange_hint then
        return nil
    end

    local game = (state or {}).game or {}
    local my_seat_index = tonumber(game.my_seat_index) or 0
    local opening_seat = resolveOpeningActorSeat(state)
    if opening_seat == nil then
        return nil
    end

    return getRelativePositionLabel(my_seat_index, opening_seat)
end

local function drawArrangeHint(self, layout, hint)
    if not hint then
        return
    end

    local label = tostring(hint.label or "")
    local timer_style = self.arrange_timer.style or {}
    local timer_x = math.floor(self.window_width * 0.5 - (timer_style.w or 56) * 0.5)
    local timer_y = math.floor(self.window_height * 0.33 - (timer_style.h or 56) * 0.5)
    local duration = math.max(tonumber(hint.duration) or 0, tonumber(hint.remaining) or 0, 1)

    self.arrange_timer:setVisible(true)
    self.arrange_timer:setSeatAnchor("center", timer_x, timer_y)
    if (tonumber(hint.remaining) or 0) > 0 then
        self.arrange_timer:syncTurn("center", hint.remaining, duration)
    else
        self.arrange_timer:startTurn("center", math.max(duration, 1))
        self.arrange_timer.remaining = 0
        self.arrange_timer.running = false
    end
    self.arrange_timer:draw()

    local text_y = timer_y + (timer_style.h or 56) + 18
    local label_font_token = "Text"
    local label_font = self.fonts:get(label_font_token)
    local text_padding_x = 18
    local text_padding_y = 5
    local text_w = math.max(0, math.ceil(measureTextWidth(self.fonts, label_font_token, label)) + text_padding_x * 2)
    local text_h = math.max(32, math.ceil(label_font:getHeight()) + text_padding_y * 2)
    local text_x = math.floor((self.window_width - text_w) * 0.5)

    love.graphics.setColor(0, 0, 0, 0.28)
    love.graphics.rectangle("fill", text_x, text_y + 3, text_w, text_h, 10, 10)
    love.graphics.setColor(0.03, 0.03, 0.04, 0.88)
    love.graphics.rectangle("fill", text_x, text_y, text_w, text_h, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.16)
    love.graphics.rectangle("fill", text_x + 4, text_y + 4, text_w - 8, 8, 6, 6)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(1, 1, 1, 0.22)
    love.graphics.rectangle("line", text_x + 0.5, text_y + 0.5, text_w - 1, text_h - 1, 10, 10)
    love.graphics.setLineWidth(1)

    local text_baseline_y = text_y + math.floor((text_h - label_font:getHeight()) * 0.5) - 1
    love.graphics.setFont(label_font)
    love.graphics.setColor(0, 0, 0, 0.58)
    love.graphics.printf(label, text_x + 1, text_baseline_y + 2, text_w, "center")
    love.graphics.printf(label, text_x, text_baseline_y + 2, text_w, "center")
    love.graphics.setColor(1, 1, 1, 0.22)
    love.graphics.printf(label, text_x, text_baseline_y - 1, text_w, "center")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(label, text_x + 1, text_baseline_y, text_w, "center")
    love.graphics.printf(label, text_x, text_baseline_y, text_w, "center")
end

local function resolveMyTeamId(game)
    local my_team_id = nil
    if game.players then
        for _, player in ipairs(game.players) do
            if game.my_seat_index ~= nil and tonumber(player.seat_index) == tonumber(game.my_seat_index) then
                my_team_id = tonumber(player.team_id)
                break
            end
        end
        if my_team_id == nil and game.my_player_id ~= nil then
            for _, player in ipairs(game.players) do
                if tonumber(player.player_id) == tonumber(game.my_player_id) then
                    my_team_id = tonumber(player.team_id)
                    break
                end
            end
        end
    end
    if my_team_id == nil and game.my_seat_index ~= nil then
        my_team_id = tonumber(game.my_seat_index) and (tonumber(game.my_seat_index) % 2) or nil
    end
    return my_team_id
end

function GameplayView.new(options)
    local self = setmetatable({}, GameplayView)

    self.fonts = assert(options and options.fonts, "GameplayView requires fonts")
    self.style = assert(options and options.style, "GameplayView requires style")
    self.backgrounds = options and options.backgrounds or nil
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
    self.player_hud = PlayerHUD.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.player_hand_count = PlayerHandCount.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.turn_timer = GamePlayTimer.new({
        fonts = self.fonts,
    })
    self.arrange_timer = GamePlayTimer.new({
        style = {
            w = 84,
            h = 84,
            frameRadius = 12,
            seg_t = 6,
            seg_w_h = 12,
            seg_w_v = 18,
            digit_gap = 7,
        },
    })
    self.action_bar = ActionBar.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.last_play_region = LastPlayRegion.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.pass_regions = {
        opposite = PassRegion.new({
            fonts = self.fonts,
            style = self.style,
        }),
        previous = PassRegion.new({
            fonts = self.fonts,
            style = self.style,
        }),
        next = PassRegion.new({
            fonts = self.fonts,
            style = self.style,
        }),
        self = PassRegion.new({
            fonts = self.fonts,
            style = self.style,
        }),
    }
    self.hand_area_overlay = HandAreaOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.deal_overlay = DealAnimationOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.tribute_overlay = TributeOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.wildcard_overlay = WildcardInfoOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.round_info_overlay = RoundInfoOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.settlement_overlay = SettlementOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.remaining_cards_overlay = RemainingCardsOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.rematch_overlay = RematchOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.settings_overlay = GameplaySettingsOverlay.new({
        fonts = self.fonts,
        style = self.style,
        background_preview_drawer = function(theme_id, bounds)
            if self.backgrounds and self.backgrounds.drawThemePreview then
                return self.backgrounds:drawThemePreview(
                    theme_id,
                    bounds.x,
                    bounds.y,
                    bounds.width,
                    bounds.height,
                    bounds
                )
            end
            return false
        end,
    })
    self.player_profile_overlay = PlayerProfileOverlay.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.confirmation_dialog = ConfirmationDialog.new({
        fonts = self.fonts,
        style = self.style,
    })
    self.toast = Toast.new({
        fonts = self.fonts,
        colors = self.style.colors,
    })
    self.loading_overlay = LoadingOverlay.new({
        fonts = self.fonts,
        message_key = "common.loading",
    })
    self.mute_button = MuteButton.new()
    self.last_play_fly_animation = LastPlayFlyAnimation.new({
        fonts = self.fonts,
    })
    self.last_play_signature = ""

    return self
end

function GameplayView:resize()
    self.window_width = love.graphics.getWidth()
    self.window_height = love.graphics.getHeight()
end

function GameplayView:_getLayout()
    return GameplayLayout.build(self.window_width, self.window_height)
end

function GameplayView:_getPlayerFrames()
    return self:_getLayout().players
end

function GameplayView:_buildPositionedPlayers(state)
    local game = state.game or {}
    local players = game.players or {}
    local my_seat_index = game.my_seat_index or 0
    local positioned_players = {}
    for _, player in ipairs(players) do
        positioned_players[getRelativePositionLabel(my_seat_index, player.seat_index)] = player
    end
    return positioned_players
end

function GameplayView:getHudRoleAt(x, y, state)
    local visibility = VisibilityManager.resolve(state)
    if not visibility.show_player_huds then
        return nil
    end

    local frames = self:_getPlayerFrames()
    local players = self:_buildPositionedPlayers(state)
    for _, role_key in ipairs({ "opposite", "previous", "next", "self" }) do
        if players[role_key] and contains(frames[role_key], x, y) then
            return role_key
        end
    end
    return nil
end

function GameplayView:_getLastPlayFrame()
    return self:_getLayout().last_play_frame
end

function GameplayView:_getActionBarFrame()
    return self:_getLayout().action_bar
end

function GameplayView:_syncTurnTimer(layout, state, positioned_players, visibility)
    local arrange_active = isArrangeCountdownActive(state)
    self.turn_timer:setVisible(visibility.show_player_huds and state.ui_phase == "playing" and not arrange_active)
    self.turn_timer:clearAllSeatAlias()

    for _, role_key in ipairs({ "opposite", "previous", "next", "self" }) do
        local player = positioned_players[role_key]
        if player and player.seat_index ~= nil then
            self.turn_timer:setSeatAlias(player.seat_index, role_key)
        end
    end

    local timer_style = self.turn_timer.style
    local frames = layout.players
    self.turn_timer:setSeatRect("self", frames.self.x, frames.self.y, frames.self.width, frames.self.height)
    self.turn_timer:setSeatAnchor(
        "opposite",
        frames.opposite.x - timer_style.offsetY - timer_style.w,
        frames.opposite.y + math.floor((frames.opposite.height - timer_style.h) * 0.5)
    )
    self.turn_timer:setSeatAnchor(
        "previous",
        frames.previous.x - timer_style.offsetY - timer_style.w,
        frames.previous.y + math.floor((frames.previous.height - timer_style.h) * 0.5)
    )
    self.turn_timer:setSeatAnchor(
        "next",
        frames.next.x + frames.next.width + timer_style.offsetY,
        frames.next.y + math.floor((frames.next.height - timer_style.h) * 0.5)
    )

    self.turn_timer:syncTurn(
        resolveOpeningActorSeat(state),
        state.turn_countdown_remaining,
        state.turn_countdown_duration
    )
end

function GameplayView:_getMuteButtonFrame()
    return self:_getLayout().mute_button
end

function GameplayView:getMuteControlAt(x, y)
    if contains(self:_getMuteButtonFrame(), x, y) then
        return "toggle_mute_button"
    end
    return nil
end

function GameplayView:_hasTributeInfo(game)
    if tostring(((game or {}).game_config or {}).game_mode or "classic") ~= "level" then
        return false
    end
    for _, entry in ipairs((game or {}).history or {}) do
        if entry.action_type == "tribute" or entry.action_type == "return_tribute" or entry.action_type == "anti_tribute" then
            return true
        end
    end
    return false
end

function GameplayView:_shouldShowHandHistoryButton(state)
    state = state or {}
    return state.reveal_cards and state.ui_phase == "playing" and not isArrangeCountdownActive(state)
end

function GameplayView:_shouldShowRoundInfoButton(state)
    state = state or {}
    local game = state.game or {}
    return self:_shouldShowHandHistoryButton(state) or (
        state.reveal_cards and state.ui_phase == "playing" and self:_hasTributeInfo(game)
    )
end

function GameplayView:_getTopInfoButtons(state)
    state = state or {}
    local buttons = {}
    if not self:_shouldShowRoundInfoButton(state) then
        return buttons
    end

    local label = getRoundInfoLabel()
    local width = math.max(152, measureTextWidth(self.fonts, "Text", label) + 38)
    buttons.round_info = {
        id = "round_info",
        label = label,
        x = math.floor((self.window_width - width) * 0.5),
        y = 6,
        width = width,
        height = 38,
    }

    return buttons
end

function GameplayView:_getTopInfoButtonFrame(button_id, state)
    local buttons = self:_getTopInfoButtons(state or {})
    return buttons[button_id]
end

function GameplayView:_getDebugButtonFrame()
    return self:_getLayout().debug_button
end

function GameplayView:_shouldShowDebugButton(state)
    if not SHOW_DEBUG_AUTOPLAY_BUTTON then
        return false
    end

    local game = (state or {}).game or {}
    if tostring(game.phase or "") ~= "playing" then
        return false
    end

    local ui_phase = tostring((state or {}).ui_phase or "")
    return ui_phase == "playing" or ui_phase == "tribute"
end

function GameplayView:_drawDebugButton(state)
    if not self:_shouldShowDebugButton(state) then
        return
    end

    local colors = self.style.colors
    local button = self:_getDebugButtonFrame()
    local hovered = state.hovered_debug_button == true
    local waiting = state.action_waiting == true

    if hovered and not waiting then
        love.graphics.setColor(colors.accent)
    elseif waiting then
        love.graphics.setColor(0.26, 0.30, 0.40, 0.88)
    else
        love.graphics.setColor(0.16, 0.19, 0.28, 0.86)
    end
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(1, 1, 1, hovered and 0.34 or 0.20)
    love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.width - 1, button.height - 1, 10, 10)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(waiting and 0.76 or 1, waiting and 0.79 or 1, waiting and 0.86 or 1, 1)
    love.graphics.setFont(self.fonts:get("Caption"))
    love.graphics.printf(I18n:t("gameplay.debug_autoplay"), button.x, button.y + 10, button.width, "center")
end

function GameplayView:_drawTopInfoButton(button, hovered)
    local fill = hovered and { 0.16, 0.17, 0.20, 0.94 } or { 0.10, 0.11, 0.13, 0.92 }
    local text = tostring((button or {}).label or "")
    local font = self.fonts:get("Text")
    local text_y = button.y + math.floor((button.height - self.fonts:getSize("Text")) * 0.5) - 2

    love.graphics.setColor(0, 0, 0, hovered and 0.22 or 0.18)
    love.graphics.rectangle("fill", button.x, button.y + 3, button.width, button.height, 11, 11)

    love.graphics.setColor(fill[1], fill[2], fill[3], fill[4] or 1)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 11, 11)

    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(1, 1, 1, hovered and 0.42 or 0.22)
    love.graphics.rectangle("line", button.x + 0.5, button.y + 0.5, button.width - 1, button.height - 1, 11, 11)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(font)
    love.graphics.setColor(0.16, 0.10, 0.06, hovered and 0.65 or 0.72)
    love.graphics.printf(text, button.x + 1, text_y, button.width, "center")
    love.graphics.setColor(1, 0.97, 0.90, 1)
    love.graphics.printf(text, button.x, text_y, button.width, "center")
end

function GameplayView:_drawTopInfoButtons(state)
    local buttons = self:_getTopInfoButtons(state)
    if buttons.round_info then
        self:_drawTopInfoButton(buttons.round_info, state.hovered_round_info_button == true)
    end
end

function GameplayView:getHoveredCardId(x, y, state)
    local layout = self:_getLayout()
    return self.hand_area_overlay:getHoveredCardId(x, y, state, {
        hand_frame = layout.hand_frame,
        self_frame = layout.players.self,
        hand_buttons = layout.hand_buttons,
    })
end

function GameplayView:getClickedCardId(x, y, state)
    local layout = self:_getLayout()
    return self.hand_area_overlay:getHoveredCardId(x, y, state, {
        hand_frame = layout.hand_frame,
        self_frame = layout.players.self,
        hand_buttons = layout.hand_buttons,
    })
end

function GameplayView:getControlAt(x, y, state)
    local game = state.game or {}
    local layout = self:_getLayout()
    local selected_count = 0
    local can_interact_hand = state.reveal_cards and (state.ui_phase == "playing" or state.ui_phase == "hand_loading")
    local arrange_active = isArrangeCountdownActive(state)
    for _ in pairs(state.selected_card_ids or {}) do
        selected_count = selected_count + 1
    end

    if self:getMuteControlAt(x, y) == "toggle_mute_button" then
        return "toggle_mute_button"
    end

    if can_interact_hand then
        local hand_control = self.hand_area_overlay:getControlAt(x, y, state, {
            hand_frame = layout.hand_frame,
            self_frame = layout.players.self,
            hand_buttons = layout.hand_buttons,
        })
        if hand_control then
            return hand_control
        end
    end

    local hud_role = self:getHudRoleAt(x, y, state)
    if hud_role then
        return "open_player_profile:" .. hud_role
    end

    return self.action_bar:getControlAt(x, y, self:_getActionBarFrame(), {
        is_my_turn = game.phase == "playing" and game.current_actor_seat == game.my_seat_index,
        has_play_control = game.has_play_control == true,
        can_play = selected_count > 0,
        action_waiting = state.action_waiting == true
            or not state.reveal_cards
            or arrange_active
            or state.ui_phase ~= "playing"
            or tostring(game.phase or "") ~= "playing",
        hovered_control = state.hovered_control,
        pending_action = state.pending_button_action,
        pending_action_timer = state.pending_button_action_timer or 0,
        pending_action_progress = state.pending_button_action_progress or 0,
    })
end

function GameplayView:getPlayerProfileControlAt(x, y, state)
    if not state.show_player_profile_overlay then
        return nil
    end
    return self.player_profile_overlay:getControlAt(x, y, self.window_width, self.window_height)
end

function GameplayView:getSettingsControlAt(x, y, state)
    local layout = self:_getLayout()
    return self.settings_overlay:getControlAt(
        x,
        y,
        state,
        self.window_width,
        self.window_height,
        layout.settings_button
    )
end

function GameplayView:getConfirmDialogControlAt(x, y, state)
    if not state.confirm_dialog_visible then
        return nil
    end
    return self.confirmation_dialog:getControlAt(x, y, self.window_width, self.window_height)
end

function GameplayView:getTributeControlAt(x, y, state)
    return self.tribute_overlay:getControlAt(x, y, state)
end

function GameplayView:getTributeHoveredCardId(x, y, state)
    return self.tribute_overlay:getHoveredCardId(x, y, state)
end

function GameplayView:getSettlementControlAt(x, y, state)
    local game = state.game or {}
    return self.settlement_overlay:getControlAt(x, y, {
        is_single_player = ((game.game_config or {}).is_single_player == true),
    })
end

function GameplayView:getRemainingCardsControlAt(x, y, state)
        local remaining_cards = ((state.game or {}).remaining_cards) or {}
        return self.remaining_cards_overlay:getControlAt(x, y, {
            can_skip = remaining_cards.can_skip == true,
            reveal_remaining = state.remaining_cards_reveal_remaining,
            intro_remaining = state.remaining_cards_intro_remaining,
            intro_duration = state.remaining_cards_intro_duration,
            countdown_remaining = state.remaining_cards_countdown_remaining,
            countdown_duration = state.remaining_cards_countdown_duration,
        })
end

function GameplayView:getRematchControlAt(x, y, state)
    return self.rematch_overlay:getControlAt(x, y, {
        rematch = (state.game or {}).rematch or {},
    })
end

function GameplayView:getRoundInfoControlAt(x, y, state)
    local game = state.game or {}
    if state.show_round_info_overlay then
        return self.round_info_overlay:getControlAt(x, y, {
            tribute_available = self:_hasTributeInfo(game),
        })
    end
    if not self:_shouldShowRoundInfoButton(state) then
        return nil
    end
    local frame = self:_getTopInfoButtonFrame("round_info", state)
    if frame and contains(frame, x, y) then
        return "open_round_info"
    end
    return nil
end

function GameplayView:getDebugControlAt(x, y, state)
    if not self:_shouldShowDebugButton(state) then
        return nil
    end

    local frame = self:_getDebugButtonFrame()
    if x >= frame.x and x <= frame.x + frame.width and y >= frame.y and y <= frame.y + frame.height then
        return "debug_autoplay_hand"
    end
    return nil
end

function GameplayView:_buildRemainingCardsRows(state)
    local game = state.game or {}
    local my_seat_index = tonumber(game.my_seat_index) or 0
    local wildcard_card = tostring(game.wildcard_card or "")
    local function getFinishTagKey(order)
        local normalized = tonumber(order)
        if normalized == 1 then
            return "first"
        end
        if normalized == 2 then
            return "second"
        end
        if normalized == 3 then
            return "third"
        end
        if normalized == 4 then
            return "last"
        end
        return nil
    end
    local remaining_cards = (game.remaining_cards or {}).revealed_hands or state.result_revealed_hands or {}
    local cards_by_seat = {}
    for _, seat_info in ipairs(remaining_cards) do
        cards_by_seat[tonumber(seat_info.seat_index)] = Helpers.sortPinnedGroupCards(seat_info.hand_cards or {}, {
            wildcard_card = wildcard_card,
        })
    end

    local by_role = {}
    for _, player in ipairs(game.players or {}) do
        local role_key = getRelativePositionLabel(my_seat_index, tonumber(player.seat_index) or 0)
        by_role[role_key] = {
            role_key = role_key,
            role_label = getRelativePositionText(role_key),
            seat_index = tonumber(player.seat_index) or 0,
            nickname = tostring(player.nickname or "-"),
            avatar_id = tostring(player.avatar_id or "avatar_1"),
            accessories = player.accessories or (role_key == "self" and state.accessories or nil),
            finish_tag_key = getFinishTagKey(player.finish_order),
            cards = cards_by_seat[tonumber(player.seat_index)] or {},
        }
    end

    local rows = {}
    for _, role_key in ipairs({ "self", "opposite", "next", "previous" }) do
        if by_role[role_key] then
            rows[#rows + 1] = by_role[role_key]
        end
    end
    return rows
end

function GameplayView:_findLastPlayTurnMarker(state)
    local explicit_turn_index = tonumber((((state or {}).game) or {}).leading_play_turn_index)
    if explicit_turn_index and explicit_turn_index > 0 then
        return tostring(explicit_turn_index)
    end

    local history = (((state or {}).game) or {}).history or {}
    for index = #history, 1, -1 do
        local entry = history[index] or {}
        if tostring(entry.action_type or "") == "play" then
            return tostring(entry.turn_index or index)
        end
    end
    return "0"
end

function GameplayView:_buildLastPlaySignature(state)
    local last_play = state.last_play
    if not last_play or not last_play.cards or #last_play.cards == 0 then
        return ""
    end

    local game = state.game or {}
    return table.concat({
        tostring(game.hand_no or 0),
        tostring(last_play.seat_index or -1),
        table.concat(last_play.cards, ","),
        self:_findLastPlayTurnMarker(state),
    }, "|")
end

function GameplayView:_resolveLastPlaySource(state, player_frames)
    local last_play = state.last_play or {}
    local game = state.game or {}
    local role_key = tostring(last_play.actor_role_key or getRelativePositionLabel(game.my_seat_index or 0, last_play.seat_index or 0))
    local source_frame = player_frames[role_key] or player_frames.self
    if not source_frame then
        return {
            x = self.window_width * 0.5,
            y = self.window_height * 0.5,
        }
    end

    if role_key == "self" then
        return {
            x = source_frame.x + source_frame.width * 0.5,
            y = source_frame.y + source_frame.height + 26,
        }
    end
    if role_key == "previous" then
        return {
            x = source_frame.x + source_frame.width + 14,
            y = source_frame.y + source_frame.height * 0.5,
        }
    end
    if role_key == "next" then
        return {
            x = source_frame.x - 14,
            y = source_frame.y + source_frame.height * 0.5,
        }
    end
    return {
        x = source_frame.x + source_frame.width * 0.5,
        y = source_frame.y + source_frame.height + 16,
    }
end

function GameplayView:_syncLastPlayAnimation(state)
    local signature = self:_buildLastPlaySignature(state)
    if signature == self.last_play_signature then
        return
    end

    self.last_play_signature = signature
    if signature == "" then
        self.last_play_fly_animation:reset()
        return
    end

    local player_frames = self:_getPlayerFrames()
    local source = self:_resolveLastPlaySource(state, player_frames)
    local target_frames = self.last_play_region:getCardFrames(self:_getLastPlayFrame(), state.last_play)
    self.last_play_fly_animation:start({
        origin = source,
        target_frames = target_frames,
        duration = 0.2,
        stagger = 0.024,
        start_width = 44,
        start_height = 62,
    })
end

function GameplayView:update(dt, state)
    if state and state.server_loading_visible then
        self.loading_overlay:show(state.server_loading_message)
    else
        self.loading_overlay:hide()
    end
    self.loading_overlay:update(dt)

    local visibility = VisibilityManager.resolve(state)
    local layout = self:_getLayout()
    local positioned_players = self:_buildPositionedPlayers(state)
    self:_syncTurnTimer(layout, state, positioned_players, visibility)
    self.arrange_timer:setVisible(false)
    local pass_markers = state.pass_markers or {}
    for _, role_key in ipairs({ "opposite", "previous", "next" }) do
        local player = positioned_players[role_key]
        local is_visible = visibility.show_player_huds
            and player ~= nil
            and pass_markers[tonumber(player.seat_index)] == true
            and tonumber(player.seat_index) ~= tonumber((state.game or {}).current_actor_seat)
        self.pass_regions[role_key]:update(dt, is_visible)
    end
    self:_syncLastPlayAnimation(state)
    self.last_play_fly_animation:update(dt)

    if not visibility.show_hand_area then
        self.last_play_fly_animation:reset()
    end

    if visibility.show_tribute_overlay then
        self.tribute_overlay:update(dt, state)
        return
    end
    if visibility.show_hand_area then
        self.hand_area_overlay:update(dt, state, {
            hand_frame = layout.hand_frame,
            self_frame = layout.players.self,
            hand_buttons = layout.hand_buttons,
        })
    end
end

function GameplayView:drawServerLoadingOverlay(state)
    if state and state.server_loading_visible then
        self.loading_overlay:draw(self.window_width, self.window_height)
    end
end

function GameplayView:_drawSettingsOverlay(state)
    if not state.settings_overlay_visible then
        return
    end
    self.settings_overlay:draw(state, self.window_width, self.window_height)
    if state.settings_background_preview_theme_id then
        self.settings_overlay:drawBackgroundPreviewOverlay(state, self.window_width, self.window_height)
    end
    if state.confirm_dialog_visible then
        local message_key = "common.confirm_exit_game"
        if state.confirm_dialog_action == "back_to_main_menu" then
            message_key = "common.confirm_back_to_main_menu"
        end
        self.confirmation_dialog:draw({
            title = I18n:t("common.confirm"),
            message = I18n:t(message_key),
            cancel_label = I18n:t("common.cancel"),
            confirm_label = I18n:t("common.confirm"),
        }, self.window_width, self.window_height, state.hovered_confirm_dialog_control)
    end
end

function GameplayView:draw(state)
    local colors = self.style.colors
    local visibility = VisibilityManager.resolve(state)
    local layout = self:_getLayout()

    if state.loading then
        love.graphics.setColor(colors.text_primary)
        love.graphics.setFont(self.fonts:get("Title2"))
        love.graphics.printf(I18n:t("gameplay.loading"), 0, 200, self.window_width, "center")
        self:drawServerLoadingOverlay(state)
        return
    end

    if state.fatal_error_message ~= "" then
        love.graphics.setColor(colors.error)
        love.graphics.setFont(self.fonts:get("Title2"))
        love.graphics.printf(state.fatal_error_message, 0, 200, self.window_width, "center")
        self:drawServerLoadingOverlay(state)
        return
    end

    self.mute_button:draw(layout.mute_button, {
        muted = state.audio_mute_master == true,
        hovered = state.hovered_control == "toggle_mute_button",
    })
    self.settings_overlay:drawSettingsButton(state, self.window_width, layout.settings_button)

    local game = state.game or {}
    if visibility.show_remaining_cards_overlay then
        local my_team_id = resolveMyTeamId(game)
        self.remaining_cards_overlay:draw({
            rows = self:_buildRemainingCardsRows(state),
            reveal_remaining = state.remaining_cards_reveal_remaining,
            intro_remaining = state.remaining_cards_intro_remaining,
            intro_duration = state.remaining_cards_intro_duration,
            countdown_remaining = state.remaining_cards_countdown_remaining,
            countdown_duration = state.remaining_cards_countdown_duration,
            can_skip = ((((game or {}).remaining_cards) or {}).can_skip == true)
                or (
                    tostring(game.phase or "") == "settlement"
                    and ((game.game_config or {}).is_single_player == true)
                    and ((((game or {}).settlement) or {}).is_match_won ~= true)
                ),
            button_hovered = state.remaining_cards_button_hovered == true,
            card_theme_config = state.card_theme_config,
            settlement = game.settlement,
            my_team_id = my_team_id,
            game_mode = tostring((game.game_config or {}).game_mode or "classic"),
            wildcard_card = game.wildcard_card,
            next_level_rank = (game.game_config or {}).current_level_rank,
            team_levels = (game.game_config or {}).team_levels,
        })
        self:_drawSettingsOverlay(state)
        self.toast:draw(state.toast_message, {
            y = 620,
            width = 500,
        })
        self:drawServerLoadingOverlay(state)
        return
    end

    if visibility.show_settlement_overlay then
        local my_team_id = resolveMyTeamId(game)
        self.settlement_overlay:draw(game.settlement, {
            is_single_player = ((game.game_config or {}).is_single_player == true),
            game_mode = tostring((game.game_config or {}).game_mode or "classic"),
            countdown_remaining = state.settlement_countdown_remaining,
            countdown_duration = state.settlement_countdown_duration,
            button_hovered = state.settlement_button_hovered == true,
            card_theme_config = state.card_theme_config,
            my_team_id = my_team_id,
            wildcard_card = game.wildcard_card,
            next_level_rank = (game.game_config or {}).current_level_rank,
            team_levels = (game.game_config or {}).team_levels,
        })
        self:_drawSettingsOverlay(state)
        self.toast:draw(state.toast_message, {
            y = 620,
            width = 500,
        })
        self:drawServerLoadingOverlay(state)
        return
    end

    if visibility.show_rematch_overlay then
        local my_team_id = resolveMyTeamId(game)
        self.rematch_overlay:draw(game.settlement, game.rematch, {
            confirm_hovered = state.rematch_confirm_button_hovered == true,
            leave_hovered = state.rematch_leave_button_hovered == true,
            card_theme_config = state.card_theme_config,
            my_team_id = my_team_id,
        })
        self:_drawSettingsOverlay(state)
        self.toast:draw(state.toast_message, {
            y = 620,
            width = 500,
        })
        self:drawServerLoadingOverlay(state)
        return
    end

    if visibility.show_tribute_overlay then
        self.tribute_overlay:draw(state)
        self:_drawDebugButton(state)
        self:_drawSettingsOverlay(state)
        self.toast:draw(state.toast_message, {
            y = 640,
            width = 500,
        })
        self:drawServerLoadingOverlay(state)
        return
    end

    local arrange_hint = buildArrangeHint(state)
    local opening_lead_role = getOpeningLeadRole(state, arrange_hint)
    local arrange_active = arrange_hint ~= nil
    local positioned_players = self:_buildPositionedPlayers(state)
    local pass_markers = state.pass_markers or {}
    local timer_active_role = self.turn_timer:getCurrentSeat()
    local timer_running = self.turn_timer:isRunning()
    local timer_remaining = self.turn_timer:getRemaining()
    local timer_warning = tonumber((self.turn_timer.style or {}).sfxThreshold or 5) or 5
    if visibility.show_player_huds then
        local frames = layout.players
        for _, role_key in ipairs({ "opposite", "previous", "next", "self" }) do
            local player = positioned_players[role_key] or {}
            local hand_count = tonumber(player.hand_count) or 0
            if role_key == "self" then
                hand_count = #((game.my_hand_cards) or {})
            end
            self.player_hud:draw(
                player,
                getRelativePositionText(role_key),
                frames[role_key],
                {
                    is_self = role_key == "self",
                    my_steam_id = state.steam_id,
                    my_avatar_id = state.avatar_id,
                    my_accessories = state.accessories,
                    hovered = state.hovered_player_hud_role == role_key,
                    hand_count = hand_count,
                    show_auto_playing = player.is_auto_playing == true,
                    show_timer = timer_running and timer_active_role == role_key,
                    timer_remaining = timer_remaining,
                    timer_warning = timer_warning,
                }
            )
        end

        for _, role_key in ipairs({ "opposite", "previous", "next" }) do
            local player = positioned_players[role_key]
            if player and pass_markers[tonumber(player.seat_index)] == true then
                self.pass_regions[role_key]:draw(frames[role_key])
            end
        end

        if opening_lead_role and positioned_players[opening_lead_role] and frames[opening_lead_role] then
            self.pass_regions[opening_lead_role]:draw(frames[opening_lead_role], {
                label = I18n:t("gameplay.lead"),
                alpha_override = 1,
                rise_override = 8,
                anchor = opening_lead_role == "self" and "right" or "below",
            })
        end

        if visibility.show_player_hand_counts then
            for _, role_key in ipairs({ "opposite", "previous", "next" }) do
                local anchor = "right"
                if role_key == "next" then
                    anchor = "left"
                end
                self.player_hand_count:draw(
                    positioned_players[role_key] or {},
                    frames[role_key],
                    {
                        anchor = anchor,
                        back_id = ((state.card_theme_config or {}).back_id) or "classic_grid",
                        alert = (state.hand_count_alerts or {})[tonumber(((positioned_players[role_key] or {}).seat_index))],
                    }
                )
            end
        end
    end

    if visibility.show_hand_area then
        local hide_cards = self.last_play_fly_animation:isActive()
        self.last_play_region:draw(
            self:_getLastPlayFrame(),
            state.last_play,
            state.card_theme_config,
            {
                hide_cards = hide_cards,
            }
        )
    end

    if visibility.show_hand_area then
        self.hand_area_overlay:draw(state, {
            hand_frame = layout.hand_frame,
            self_frame = layout.players.self,
            hand_buttons = layout.hand_buttons,
        })
    end

    drawArrangeHint(self, layout, arrange_hint)

    if visibility.show_hand_area then
        self.last_play_fly_animation:draw(state.card_theme_config)
    end

    local selected_count = 0
    for _ in pairs(state.selected_card_ids or {}) do
        selected_count = selected_count + 1
    end

    self.action_bar:draw(self:_getActionBarFrame(), {
        is_my_turn = game.phase == "playing" and game.current_actor_seat == game.my_seat_index,
        has_play_control = game.has_play_control == true,
        can_play = selected_count > 0,
        action_waiting = state.action_waiting == true
            or not state.reveal_cards
            or arrange_active
            or state.ui_phase ~= "playing"
            or tostring(game.phase or "") ~= "playing",
        hovered_control = state.hovered_control,
        pressed_controls = state.button_press_feedback or {},
        pending_action = state.pending_button_action,
        pending_action_timer = state.pending_button_action_timer or 0,
        pending_action_progress = state.pending_button_action_progress or 0,
    })

    self:_drawDebugButton(state)

    self:_drawTopInfoButtons(state)

    if visibility.show_wildcard_overlay then
        self.wildcard_overlay:draw(game.wildcard_card, state.card_theme_config)
    elseif visibility.show_deal_overlay then
        local open_card_id = game.open_card_id
        self.deal_overlay:draw(
            state.deal_overlay_remaining,
            state.deal_overlay_duration,
            state.card_theme_config,
            layout.deal_targets,
            {
                open_card_id = open_card_id,
                open_card_seat = game.open_card_seat,
                open_card_cut_count = game.open_card_cut_count,
                open_card_deal_index = game.open_card_deal_index,
                deal_start_seat = game.deal_start_seat,
                my_seat_index = game.my_seat_index,
            }
        )
    end

    if state.show_round_info_overlay then
        self.round_info_overlay:draw(game, {
            active_tab = state.round_info_active_tab,
            hovered_control = state.hovered_round_info_overlay_control,
            tribute_available = self:_hasTributeInfo(game),
            history_rows = state.play_history_entries or {},
            history_scroll = state.hand_history_scroll,
            card_theme_config = state.card_theme_config,
            my_seat_index = game.my_seat_index,
            my_accessories = state.accessories,
        })
    end

    self:_drawSettingsOverlay(state)

    if state.show_player_profile_overlay and state.profile_overlay_player then
        self.player_profile_overlay:draw(state.profile_overlay_player, {
            window_width = self.window_width,
            window_height = self.window_height,
            my_steam_id = state.steam_id,
            my_avatar_id = state.avatar_id,
            my_accessories = state.accessories,
            my_seat_index = game.my_seat_index,
            hovered_close = state.hovered_player_profile_control == "close_player_profile",
        })
    end

    local toast_progress = 1
    if (tonumber(state.toast_duration) or 0) > 0 then
        toast_progress = 1 - ((tonumber(state.toast_remaining) or 0) / state.toast_duration)
    end

    self.toast:draw(state.toast_message, {
        y = 620,
        min_width = 220,
        max_width = 420,
        auto_width = true,
        auto_height = true,
        height = 64,
        radius = 20,
        enter_drop = 58,
        enter_progress = toast_progress,
        variant = "wood_notice",
    })
    self:drawServerLoadingOverlay(state)
end

return GameplayView
