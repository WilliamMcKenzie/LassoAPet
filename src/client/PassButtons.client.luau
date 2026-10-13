-- QM's pass buttons down the left of the base HUD (Oct 13, a look test: "no functionality
-- yet"): Starter Pack, 1.5x Speed, 2x Cash, Giant Pets, each with QM's sunburst turning
-- behind it. Shown whenever BaseUi is (not riding, in a cutscene or the tutorial) and no
-- menu's up over the base.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local MARGIN, GAP = 18, 10
local SCALE = 256 / 295 -- QM's art's pixels to ours (the 1.5x Speed, as wide as Merge)
local SUNBURST = "rbxassetid://85834206672187" -- assets/ui/Sunburst.png (QM's)
local SPIN = 30 -- degrees a second
local BUTTONS = {
	{ "StarterPack", "rbxassetid://100466055719917", Vector2.new(245, 138) }, -- assets/ui/PassStarterPack.png
	{ "Speed", "rbxassetid://128119306382781", Vector2.new(295, 141) }, -- assets/ui/PassSpeed.png
	{ "Cash", "rbxassetid://108884731983075", Vector2.new(295, 147) }, -- assets/ui/PassCash.png
	{ "GiantPets", "rbxassetid://126647709261103", Vector2.new(302, 148) }, -- assets/ui/PassGiantPets.png
}

local camera = workspace.CurrentCamera
local gui = Instance.new("ScreenGui")
gui.Name = "PassButtons"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
local root = Instance.new("Frame")
root.BackgroundTransparency = 1
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

local column = Instance.new("Frame")
column.BackgroundTransparency = 1
column.AutomaticSize = Enum.AutomaticSize.XY
column.AnchorPoint = Vector2.new(0, 0.5)
column.Position = UDim2.new(0, MARGIN, 0.5, 0)
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, GAP)
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.Parent = column
local fit = Instance.new("UIScale") -- (a short screen: shrunk to fit between the top bar and the gold)
fit.Parent = column
column.Parent = root

local bursts = {}
for i, spec in BUTTONS do
	local size = spec[3] * SCALE
	local slot = Instance.new("Frame") -- (the sunburst and the button side by side, so it's behind)
	slot.Name = spec[1]
	slot.LayoutOrder = i
	slot.BackgroundTransparency = 1
	slot.Size = UDim2.fromOffset(size.X, size.Y)
	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.BackgroundTransparency = 1
	button.Image = spec[2]
	button.Size = UDim2.fromOffset(size.X, size.Y)
	button.ZIndex = 2
	local burst = Instance.new("ImageLabel") -- (behind it, turning)
	burst.Name = "Sunburst"
	burst.BackgroundTransparency = 1
	burst.Image = SUNBURST
	burst.ImageTransparency = 0.25
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, 0.55)
	burst.Size = UDim2.fromOffset(size.X * 1.1, size.X * 1.1)
	burst.ZIndex = 1
	burst.Parent = slot
	table.insert(bursts, burst)
	local press = Instance.new("UIScale")
	press.Parent = button
	button.MouseButton1Down:Connect(function()
		press.Scale = 0.94
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			press.Scale = 1
		end)
	end
	button.Parent = slot
	slot.Parent = column
end
gui.Parent = player:WaitForChild("PlayerGui")

RunService.RenderStepped:Connect(function()
	local base = player.PlayerGui:FindFirstChild("BaseUi")
	local baseRoot = base and base:FindFirstChild("Root")
	gui.Enabled = base ~= nil and base.Enabled and not (baseRoot and baseRoot:GetAttribute("Modal"))
	if gui.Enabled then
		local tall = list.AbsoluteContentSize.Y / rootScale.Scale / fit.Scale
		fit.Scale = math.min(1, root.Size.Y.Offset * 0.62 / math.max(tall, 1))
		for _, burst in bursts do
			burst.Rotation = os.clock() * SPIN % 360
		end
	end
end)
