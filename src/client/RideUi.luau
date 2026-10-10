-- The riding UI (QM, Oct 10: v3, no buttons: E on the lasso's prompt is the only
-- control, LassoPrompt; Shift or the stick pushed far out sprints, Ride), in place of the
-- old riding HUD (Config.RideHud off). Hud hands its riding calls on to this.
--   Top centre: the stamina bar: the grey bar, and the green one over it cut off at
--     your stamina left; the trophy at its left end; how far you've come ("500m") in
--     the middle.
--   Top left, under Roblox's buttons: "Sprint" and the SHIFT keycap, a hint (no button),
--     the keycap pressed while you're holding Shift; none on a touch screen.
-- Laid out on a RefWidth-wide screen (Config.BaseUi; the art's drawn at it).
--
--   RideUi.show(visible)
--   RideUi.setHold(fraction) / setDistance(text) / setSprint(visible)
--   (setAbility, setAction, sprintHeld, abilityPressed: no buttons, so nothing)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)

local ART = { -- assets/ui/ride_hud/*.png, drawn at the RefWidth screen's size
	progress = { id = "rbxassetid://106564742417734", size = Vector2.new(646, 110) }, -- Progress.png
	progressGrey = { id = "rbxassetid://128596579962806", size = Vector2.new(646, 110) }, -- ProgressDisabled.png
	shift = { id = "rbxassetid://85118816608847", size = Vector2.new(211, 85) }, -- ShiftKeycap.png
	shiftDown = { id = "rbxassetid://121018909533952", size = Vector2.new(211, 85) }, -- ShiftKeycapPressed.png
	trophy = { id = "rbxassetid://91225534722065", size = Vector2.new(256, 256) }, -- Trophy.png (QM, Oct 10)
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
-- (RefWidth px, from Design's measurements of QM's mock, Oct 10: a 1526 x 830 shot, so
-- its height is 1044 here)
local TOP = 19 -- the bar off the top
local BAR_WIDTH = 646
local FILL_FROM, FILL_TO = 0.015, 0.983 -- the bar's inner fill, of its width
local TROPHY_AT, TROPHY_SIZE = 0.115, 0.72 -- its middle, of the bar's width; its size, of the bar's height
local DISTANCE_TEXT, STROKE = 46, 3
local HINT_Y = 183 -- the Sprint hint's row, its middle, under Roblox's buttons
local HINT_LEFT, HINT_TEXT = 29, 32 -- "Sprint"
local HINT_KEY_LEFT, HINT_KEY = 196, 191 -- the SHIFT keycap's left edge and width
local HINT_SEEN = 0.5 -- the whole hint's see-through (QM: half)

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

local function picture(parent, art, anchor, position, width)
	local p = Instance.new("ImageLabel")
	p.BackgroundTransparency = 1
	p.Image = art.id
	width = width or art.size.X
	p.Size = UDim2.fromOffset(width, width * art.size.Y / art.size.X)
	p.AnchorPoint = anchor
	p.Position = position
	p.Parent = parent
	return p
end

local function text(parent, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextSize = size
	label.TextColor3 = color
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, size)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = STROKE
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

-- The stamina bar.
local bar = picture(root, ART.progressGrey, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, TOP), BAR_WIDTH)
bar.Name = "Stamina"
local clip = Instance.new("Frame")
clip.Name = "Fill"
clip.BackgroundTransparency = 1
clip.ClipsDescendants = true
clip.Size = UDim2.fromScale(1, 1)
clip.Parent = bar
local green = picture(clip, ART.progress, Vector2.zero, UDim2.new())
green.Size = bar.Size
local distance = text(bar, DISTANCE_TEXT, Color3.new(1, 1, 1))
distance.Name = "Distance"
distance.AnchorPoint = Vector2.new(0.5, 0.5)
distance.Position = UDim2.fromScale(0.5, 0.5)
distance.ZIndex = 2
local barHeight = BAR_WIDTH * ART.progress.size.Y / ART.progress.size.X
local trophy = picture(bar, ART.trophy, Vector2.new(0.5, 0.5), UDim2.fromScale(TROPHY_AT, 0.5), barHeight * TROPHY_SIZE)
trophy.Name = "Trophy"
trophy.ZIndex = 2

-- The Sprint hint, top left.
local hint = Instance.new("CanvasGroup") -- (see-through as a whole, QM: its outline doesn't show through the text)
hint.Name = "SprintHint"
hint.BackgroundTransparency = 1
hint.GroupTransparency = HINT_SEEN
hint.Size = UDim2.fromOffset(HINT_KEY_LEFT + HINT_KEY + 20, 120)
hint.Position = UDim2.fromOffset(0, HINT_Y - 60)
local hintText = text(hint, HINT_TEXT, Color3.new(1, 1, 1))
hintText.Text = "Sprint"
hintText.AnchorPoint = Vector2.new(0, 0.5)
hintText.Position = UDim2.fromOffset(HINT_LEFT, 60)
local hintKey = picture(hint, ART.shift, Vector2.new(0, 0.5), UDim2.fromOffset(HINT_KEY_LEFT, 60), HINT_KEY)
hint.Parent = root

function RideUi.show(visible)
	gui.Enabled = visible
end

-- On a touch screen (the last input was a touch, or there's no keyboard): no keys to show.
local function touching()
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return true
	end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local hintWanted = false
RunService.RenderStepped:Connect(function()
	if not gui.Enabled then
		return
	end
	hint.Visible = hintWanted and not touching()
	hintKey.Image = if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		then ART.shiftDown.id
		else ART.shift.id
end)

function RideUi.setHold(fraction)
	bar.Visible = fraction ~= nil
	if fraction then
		local f = math.clamp(fraction, 0, 1)
		clip.Size = UDim2.fromScale(if f <= 0 then 0 else FILL_FROM + (FILL_TO - FILL_FROM) * f, 1)
	end
end

function RideUi.setDistance(value)
	distance.Text = value
end

function RideUi.setSprint(visible)
	hintWanted = visible
end

function RideUi.setAbility() end
function RideUi.setAction() end
function RideUi.sprintHeld()
	return false
end
function RideUi.abilityPressed()
	return false
end

return RideUi
