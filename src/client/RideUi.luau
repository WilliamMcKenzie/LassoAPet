-- The riding UI (QM, Oct 9: the new look, assets/ui/ride_hud/), in place of the old
-- riding HUD (Config.RideHud off). Hud hands its riding calls on to this.
--   Top centre: the stamina bar: the grey bar, and the green one over it cut off at
--     your stamina left (both have the bicep drawn in the same spot, so it always
--     shows); your stamina level beside the bicep.
--   Bottom left: Sprint, in its corner; 1.1x while you sprint (Shift, holding it, or
--     the run home). Holding it keeps you sprinting through lassoing and landing.
--   Bottom right: the ability, in its corner. Used: 1.1x, and its active art for as long
--     as it lasts; then the grey art with the pink filling up from the bottom till it's
--     ready, when it bounces (1.1x and back) and shows its usual art.
--   Bottom centre: LASSO, grey while there's nothing to lasso.
-- On a phone the ability's usual art is its fill art (no "[SPACE]" on it: QM), and
-- there's no Sprint button (pushing the stick far out sprints there: Ride).
-- Laid out on a RefWidth-wide screen (Config.BaseUi, QM's Figma; the art's drawn at it).
--
--   RideUi.show(visible)
--   RideUi.setHold(fraction, tired, level) / setSprint(visible, active)
--   RideUi.setAbility(ready, seconds, active) / setAction(text, ready)
--   RideUi.sprintHeld() / abilityPressed()
--   RideUi.onAction = fn                -- LASSO pressed

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local ART = { -- assets/ui/ride_hud/*.png (QM, Oct 9), drawn at the RefWidth screen's size
	progress = { id = "rbxassetid://86921556071460", size = Vector2.new(698, 96) }, -- Progress.png
	progressGrey = { id = "rbxassetid://76578450659995", size = Vector2.new(698, 96) }, -- ProgressDisabled.png
	sprint = { id = "rbxassetid://109639882860064", size = Vector2.new(309, 262) }, -- Sprint.png
	ability = { id = "rbxassetid://88075614762733", size = Vector2.new(309, 262) }, -- Ability.png
	abilityActive = { id = "rbxassetid://104085750641497", size = Vector2.new(309, 262) }, -- AbilityActive.png
	abilityGrey = { id = "rbxassetid://115361393403366", size = Vector2.new(309, 262) }, -- AbilityDisabled.png
	abilityFill = { id = "rbxassetid://138465717992479", size = Vector2.new(309, 262) }, -- AbilityFill.png
	lasso = { id = "rbxassetid://131980018378422", size = Vector2.new(440, 176) }, -- Lasso.png
	lassoGrey = { id = "rbxassetid://124076174344578", size = Vector2.new(440, 176) }, -- LassoDisabled.png
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
-- (RefWidth px, from QM's mockup)
local TOP = 22 -- the bar off the top
local CORNER = 36 -- Sprint and the ability in from their corners
local LASSO_BOTTOM = 30
local FILL_FROM, FILL_TO = 0.010, 0.989 -- the bar's inner fill, of its width
local LEVEL_AT = 0.465 -- the stamina number's left edge, of the bar's width (right of the bicep)
local LEVEL_TEXT, LEVEL_STROKE = 50, 5 -- (QM's Figma)
local GROW = 1.1
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local RideUi = {}

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RideUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local uiScale = Instance.new("UIScale")
uiScale.Parent = root
local function resize()
	local view = gui.AbsoluteSize
	uiScale.Scale = view.X / Config.BaseUi.RefWidth * (Config.HudScale or 1)
	root.Size = UDim2.fromOffset(view.X / uiScale.Scale, view.Y / uiScale.Scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()

local function picture(class, parent, art, anchor, position)
	local p = Instance.new(class)
	p.BackgroundTransparency = 1
	p.Image = art.id
	p.Size = UDim2.fromOffset(art.size.X, art.size.Y)
	p.AnchorPoint = anchor
	p.Position = position
	p.Parent = parent
	return p
end

-- A scale on a button, tweened (grows about its AnchorPoint: a corner button grows outward).
local function scaler(button)
	local s = Instance.new("UIScale")
	s.Parent = button
	local tween
	return function(to, info)
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(s, info or QUICK, { Scale = to })
		tween:Play()
		return tween
	end
end

-- The stamina bar.
local bar = picture("ImageLabel", root, ART.progressGrey, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, TOP))
bar.Name = "Stamina"
local clip = Instance.new("Frame")
clip.Name = "Fill"
clip.BackgroundTransparency = 1
clip.ClipsDescendants = true
clip.Size = UDim2.fromScale(1, 1)
clip.Parent = bar
local green = picture("ImageLabel", clip, ART.progress, Vector2.zero, UDim2.new())
green.Size = UDim2.fromOffset(ART.progress.size.X, ART.progress.size.Y)
local level = Instance.new("TextLabel")
level.BackgroundTransparency = 1
level.FontFace = FONT
level.TextSize = LEVEL_TEXT
level.TextColor3 = Color3.new(1, 1, 1)
level.TextXAlignment = Enum.TextXAlignment.Left
level.AnchorPoint = Vector2.new(0, 0.5)
level.Position = UDim2.fromScale(LEVEL_AT, 0.5)
level.Size = UDim2.fromOffset(200, LEVEL_TEXT)
level.ZIndex = 2
local levelStroke = Instance.new("UIStroke")
levelStroke.Thickness = LEVEL_STROKE
levelStroke.Color = Color3.new(0, 0, 0)
levelStroke.LineJoinMode = Enum.LineJoinMode.Round
levelStroke.Parent = level
level.Parent = bar

-- Sprint, bottom left.
local sprint = picture("ImageButton", root, ART.sprint, Vector2.new(0, 1), UDim2.new(0, CORNER, 1, -CORNER))
sprint.Name = "Sprint"
sprint.AutoButtonColor = false
local sprintScale = scaler(sprint)
local sprintInput -- the touch or click holding it down
sprint.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		sprintInput = input
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input == sprintInput then
		sprintInput = nil -- (only when that finger or button lets go: not on hiding, so it carries on through a lasso)
	end
end)

-- The ability, bottom right.
local ability = picture("ImageButton", root, ART.ability, Vector2.new(1, 1), UDim2.new(1, -CORNER, 1, -CORNER))
ability.Name = "Ability"
ability.AutoButtonColor = false
local abilityScale = scaler(ability)
local fillClip = Instance.new("Frame") -- the pink, filling up from the bottom
fillClip.Name = "Fill"
fillClip.BackgroundTransparency = 1
fillClip.ClipsDescendants = true
fillClip.AnchorPoint = Vector2.new(0, 1)
fillClip.Position = UDim2.fromScale(0, 1)
fillClip.Size = UDim2.fromScale(1, 0)
fillClip.Parent = ability
local fill = picture("ImageLabel", fillClip, ART.abilityFill, Vector2.new(0, 1), UDim2.fromScale(0, 1))
local pressed = false
ability.Activated:Connect(function()
	pressed = true
end)

-- LASSO, bottom centre.
local lasso = picture("ImageButton", root, ART.lasso, Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -LASSO_BOTTOM))
lasso.Name = "Lasso"
lasso.AutoButtonColor = false
lasso.Activated:Connect(function()
	if RideUi.onAction then
		RideUi.onAction()
	end
end)

function RideUi.show(visible)
	gui.Enabled = visible
end

function RideUi.setHold(fraction, _tired, stamina)
	bar.Visible = fraction ~= nil
	if fraction then
		local f = math.clamp(fraction, 0, 1)
		clip.Size = UDim2.fromScale(if f <= 0 then 0 else FILL_FROM + (FILL_TO - FILL_FROM) * f, 1)
		level.Visible = stamina ~= nil
		if stamina then
			level.Text = tostring(stamina)
		end
	end
end

-- On a touch screen (the last input was a touch, or there's no keyboard): no keys to show.
local function touching()
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch then
		return true
	end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local sprinting = false
function RideUi.setSprint(visible, active)
	sprint.Visible = visible and not touching()
	active = visible and active == true
	if active ~= sprinting then
		sprinting = active
		sprintScale(if active then GROW else 1)
	end
end

function RideUi.sprintHeld()
	return sprintInput ~= nil
end

local abilityState -- "ready", "active", "cooldown"
function RideUi.setAbility(ready, _seconds, active)
	ability.Visible = ready ~= nil
	if ready == nil then
		pressed, abilityState = false, nil
		return
	end
	local state = if active then "active" elseif ready >= 1 then "ready" else "cooldown"
	if state ~= abilityState then
		local was = abilityState
		abilityState = state
		if state == "active" then
			abilityScale(GROW) -- used: big while it lasts
		elseif state == "cooldown" then
			if was == "ready" then -- (used, but it doesn't last: a quick grow and back)
				abilityScale(GROW).Completed:Once(function()
					if abilityState == "cooldown" then
						abilityScale(1)
					end
				end)
			else
				abilityScale(1)
			end
		elseif state == "ready" and was == "cooldown" then
			abilityScale(GROW).Completed:Once(function() -- ready again: one bounce
				abilityScale(1)
			end)
		end
	end
	ability.Image = if state == "active" then ART.abilityActive.id
		elseif state == "cooldown" then ART.abilityGrey.id
		elseif touching() then ART.abilityFill.id
		else ART.ability.id
	fillClip.Visible = state == "cooldown"
	if state == "cooldown" then
		local f = math.clamp(ready, 0, 1)
		fillClip.Size = UDim2.fromScale(1, f)
		fill.Position = UDim2.fromScale(0, 1)
		fill.Size = UDim2.fromScale(1, if f > 0 then 1 / f else 0) -- (the whole picture, its bottom f showing)
	end
end

function RideUi.abilityPressed()
	local was = pressed
	pressed = false
	return was
end

function RideUi.setAction(text, ready)
	lasso.Visible = text ~= nil
	if text then
		local grey = not ready
		lasso.Image = if grey and ART.lassoGrey.id ~= "" then ART.lassoGrey.id else ART.lasso.id
		lasso.ImageColor3 = if grey and ART.lassoGrey.id == "" then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1)
	end
end

return RideUi
