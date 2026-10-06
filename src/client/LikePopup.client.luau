-- "Enjoying the game?" (QM, Oct 6): once ever, a few seconds after a player's first
-- hatch, a small card asks them to like the game (the server decides when: LikeAsk,
-- Hatchery). Roblox has no prompt for liking an experience, so it only points at the
-- 👍 on the game's page. It doesn't block play: no dimmed screen, and it closes
-- itself after SHOW_TIME if the X isn't pressed.
--
-- Placeholder look until QM's art lands: a blue card with a black outline, white
-- FredokaOne text with a black stroke, like the rest of the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local player = Players.LocalPlayer

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local FONT = Enum.Font.FredokaOne
local CARD = Vector2.new(440, 150)
local SHOW_TIME = 12 -- seconds before it closes by itself

local gui = Instance.new("ScreenGui")
gui.Name = "LikePopup"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6 -- over the HUD, under the away popup
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
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
root.Parent = gui

-- Top centre, clear of the bottom buttons.
local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.fromScale(0.5, 0.12)
card.Size = UDim2.fromOffset(CARD.X, CARD.Y)
card.BackgroundColor3 = Color3.fromRGB(64, 160, 255)
card.Parent = root
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = card
local outline = Instance.new("UIStroke")
outline.Thickness = 3
outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outline.Parent = card
local popScale = Instance.new("UIScale")
popScale.Parent = card

local function label(text, textSize, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromOffset(CARD.X - 40, textSize * 1.3)
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	l.Parent = card
	return l
end
label("Enjoying the game?", 40, 0.33)
label("Give it a 👍 on the game page!", 28, 0.7)

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(0.5, 0.5)
close.Position = UDim2.new(1, -6, 0, 6)
close.Size = UDim2.fromOffset(48, 48)
close.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
close.AutoButtonColor = true
close.Text = ""
close.Parent = card
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.5, 0)
closeCorner.Parent = close
local closeOutline = Instance.new("UIStroke")
closeOutline.Thickness = 3
closeOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
closeOutline.Parent = close
local x = Instance.new("TextLabel")
x.BackgroundTransparency = 1
x.Size = UDim2.fromScale(1, 1)
x.Font = FONT
x.TextSize = 30
x.TextColor3 = Color3.new(1, 1, 1)
x.Text = "X"
local xStroke = Instance.new("UIStroke")
xStroke.Thickness = 3
xStroke.Parent = x
x.Parent = close

local function apply(scale)
	popScale.Scale = scale
end

local showing = false
local function hide()
	if not showing then
		return
	end
	showing = false
	ModalPop.close(apply, function()
		gui.Enabled = false
	end)
end
close.Activated:Connect(hide)

ReplicatedStorage:WaitForChild("LikeAsk").OnClientEvent:Connect(function()
	if showing then
		return
	end
	showing = true
	gui.Enabled = true
	ModalPop.open(apply)
	task.delay(SHOW_TIME, hide)
end)
