-- Hatch All at the top of the screen (QM, Nov 2; back on its own, Nov 7, now the top bar's
-- gone): in your pen with eggs still hatching, a yellow "Hatch All" button, top middle. A tap
-- opens Roblox's prompt for Config.HatchAll (Shop.server's "HatchAll"), which shows the price;
-- the button itself just says "Hatch All" (QM, Nov 7: no Robux on it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
if not Config.HatchAll then
	return
end
local Hud = require(script.Parent.Hud)
local HudKit = require(script.Parent.HudKit)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local REFERENCE_WIDTH = 1320 -- (Hud's: sizes below are pixels on a screen this wide)
local SIZE = Vector2.new(330, 70)
local TOP = 14

local gui = Instance.new("ScreenGui")
gui.Name = "HatchAllBar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = -1
gui.Enabled = false

local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
root.Parent = gui

local button = Instance.new("ImageButton")
button.Name = "HatchAll"
button.AutoButtonColor = false
button.BackgroundTransparency = 1
button.Image = ""
button.AnchorPoint = Vector2.new(0.5, 0)
button.Position = UDim2.new(0.5, 0, 0, TOP)
button.Size = UDim2.fromOffset(SIZE.X, SIZE.Y)
button.Parent = root
HudKit.back(button, "Yellow", { Name = "NativeBack", ZIndex = 1 })
HudKit.label(button, "Text", {
	Text = "Hatch All",
	TextXAlignment = Enum.TextXAlignment.Center,
	TextScaled = true,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.6),
	ZIndex = 3,
})
button.Activated:Connect(function()
	ReplicatedStorage:WaitForChild("BuyShop"):FireServer("HatchAll", "pen") -- (Roblox's prompt; hatched once it's paid)
end)
gui.Parent = player:WaitForChild("PlayerGui")

-- Standing in your own pen (its Area, a few studs' grace).
local function inPen()
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	local pen = index and pens and pens:FindFirstChild("Pen" .. index)
	local area = pen and pen:FindFirstChild("Area")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not area or not area:IsA("BasePart") or not hrp then
		return false
	end
	local at = area.CFrame:PointToObjectSpace(hrp.Position)
	return math.abs(at.X) <= area.Size.X / 2 + 4 and math.abs(at.Z) <= area.Size.Z / 2 + 4
end

RunService.RenderStepped:Connect(function()
	local busy = Hud.isRiding() or player:GetAttribute("Cutscene") or player:GetAttribute("Tutorial")
	gui.Enabled = not busy and (player:GetAttribute("PenHatchLast") or 0) > workspace:GetServerTimeNow() and inPen()
end)
