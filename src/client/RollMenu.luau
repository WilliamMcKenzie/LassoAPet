-- The egg roll menu (QM, Oct 4): the Roll button over Pets opens it. QM's panel
-- (the eggs you can roll, baked into the art) with ROLL $1M on its bottom edge,
-- laid out like QM's mockup. The roll itself is Hud's (RollGacha, then the egg
-- card); clicking anywhere off the panel closes it, like the animal dictionary.
--
--   RollMenu.toggle() / RollMenu.close()
--   RollMenu.onToggle = function(open)     -- Hud hides the rest of the home HUD
--   RollMenu.onRoll = function()           -- ROLL was pressed
--   RollMenu.setAffordable(yes)            -- greys ROLL when you can't pay
--   RollMenu.setHidden(yes)                -- out of the way while the egg card shows

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local RollMenu = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local PANEL = { id = "rbxassetid://139179785391159", size = Vector2.new(2204, 1420) } -- RollMenu.png
local BUTTON = { id = "rbxassetid://119520152431016", size = Vector2.new(960, 378) } -- RollButton.png (ROLL $1M)
local PANEL_WIDTH = 720 -- about half the screen, as in the mockup
local BUTTON_WIDTH = 310
local GREY = Color3.fromRGB(150, 150, 150)

local player = Players.LocalPlayer
local open, hidden = false, false

local gui = Instance.new("ScreenGui")
gui.Name = "RollMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, so the Roll button that closes it stays on top
gui.Enabled = false

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local camera = workspace.CurrentCamera
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()

local panel = Instance.new("ImageLabel")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Image = PANEL.id
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.45)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_WIDTH * PANEL.size.Y / PANEL.size.X)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

local roll = Instance.new("ImageButton")
roll.Name = "Roll"
roll.BackgroundTransparency = 1
roll.AutoButtonColor = false
roll.Image = BUTTON.id
roll.AnchorPoint = Vector2.new(0.5, 0.5)
roll.Position = UDim2.fromScale(0.5, 0.97) -- over the panel's bottom edge
roll.Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_WIDTH * BUTTON.size.Y / BUTTON.size.X)
roll.ZIndex = 2
local rollScale = Instance.new("UIScale")
rollScale.Parent = roll
roll.Parent = panel
local press = TweenInfo.new(0.08)
roll.MouseButton1Down:Connect(function()
	TweenService:Create(rollScale, press, { Scale = 0.93 }):Play()
end)
for _, event in { roll.MouseButton1Up, roll.MouseLeave } do
	event:Connect(function()
		TweenService:Create(rollScale, press, { Scale = 1 }):Play()
	end)
end
roll.Activated:Connect(function()
	if RollMenu.onRoll then
		RollMenu.onRoll()
	end
end)

-- Clicking anywhere off the panel and its button closes it.
local function over(object, at)
	local min, size = object.AbsolutePosition, object.AbsoluteSize
	return at.X >= min.X and at.Y >= min.Y and at.X <= min.X + size.X and at.Y <= min.Y + size.Y
end
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if not over(panel, at) and not over(roll, at) then
		RollMenu.close()
	end
end)
backdrop.Parent = gui
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	gui.Enabled = open and not hidden
end

function RollMenu.toggle()
	open = not open
	refresh()
	if open then
		panelScale.Scale = 0.85
		TweenService:Create(panelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	if RollMenu.onToggle then
		RollMenu.onToggle(open)
	end
end

function RollMenu.close()
	if open then
		RollMenu.toggle()
	end
end

function RollMenu.isOpen()
	return open
end

function RollMenu.setAffordable(yes)
	roll.ImageColor3 = if yes then Color3.new(1, 1, 1) else GREY
end

function RollMenu.setHidden(yes)
	hidden = yes
	refresh()
end

return RollMenu
