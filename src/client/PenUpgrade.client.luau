-- A button floating over your own pen that buys its next level (UpgradePen):
-- "UPGRADE PEN 150$". Placeholder look until QM draws the art; hidden once
-- there's no next level. Flashes red if you can't afford it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local upgrade = ReplicatedStorage:WaitForChild("UpgradePen")
local YELLOW = Color3.fromRGB(255, 196, 30)
local RED = Color3.fromRGB(230, 60, 50)

local gui = Instance.new("BillboardGui")
gui.Name = "PenUpgrade"
gui.Size = UDim2.fromOffset(220, 56)
gui.StudsOffsetWorldSpace = Vector3.new(0, -4.5, 0) -- under the owner's picture and name
gui.MaxDistance = 90
gui.LightInfluence = 0
gui.Active = true
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(1, 1)
button.BackgroundColor3 = YELLOW
button.AutoButtonColor = true
button.Font = Enum.Font.FredokaOne
button.TextSize = 26
button.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", button).CornerRadius = UDim.new(0.3, 0)
local border = Instance.new("UIStroke")
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
border.Thickness = 4
border.Parent = button
local outline = Instance.new("UIStroke")
outline.Thickness = 3
outline.Parent = button
button.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:WaitForChild("Pens"):FindFirstChild("Pen" .. index)
end

local function refresh()
	local pen = myPen()
	local nextBiome = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
	gui.Adornee = pen and pen:FindFirstChild("Sign")
	gui.Enabled = Config.ShowHud and gui.Adornee ~= nil and nextBiome ~= nil and nextBiome.UnlockCost ~= nil
	if nextBiome and nextBiome.UnlockCost then
		button.Text = "UPGRADE PEN " .. nextBiome.UnlockCost .. "$"
	end
end

local busy = false
button.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	local ok, bought = pcall(upgrade.InvokeServer, upgrade)
	if not (ok and bought) then
		button.BackgroundColor3 = RED
		task.wait(0.4)
		button.BackgroundColor3 = YELLOW
	end
	busy = false
end)

player:GetAttributeChangedSignal("Pen"):Connect(refresh)
player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
refresh()
