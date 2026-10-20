-- While you were away (QM, Oct 3; the panel back, QM Oct 20): back after time away, your pets
-- have earned gold meanwhile (the "AwayGold" attribute, Hatchery.server). QM's panel shows how
-- much: Claim banks it (ClaimAway), and the rainbow button buys it 4x over for Robux
-- (Config.AwayBoost, BuyShop "Away4x": Shop.server, Hatchery's BankAway). It waits till you're
-- out of the tutorial and any cutscene, and goes once the gold's banked either way.
-- As the Starter Pack popup: the world hazy behind it and every other bit of UI gone meanwhile.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local ART = { -- assets/ui/away (QM's)
	panel = "rbxassetid://125418799809598", -- Panel.png (1229x710, its "+$999 CASH" painted out for the live amount; shrunk to 1024x592 by the upload)
	boost = "rbxassetid://109857217281496", -- Claim4x.png (358x142): the rainbow button, Robux 29
	claim = "rbxassetid://106855326447623", -- Claim.png (333x113)
}
local K = 760 / 1229 -- QM's art's pixels to ours
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local claimAway = ReplicatedStorage:WaitForChild("ClaimAway")
local open = false

-- 1,234 then 1.2M, 3.4B, ...
local function amount(n)
	n = math.floor(n)
	for _, unit in { { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" } } do
		if n >= unit[1] then
			return string.format("%.1f", n / unit[1]):gsub("%.0$", "") .. unit[2]
		end
	end
	local s = tostring(n)
	while true do
		local done
		s, done = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if done == 0 then
			return s
		end
	end
end

local function pressable(button)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local press = TweenInfo.new(0.08)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.95 }):Play()
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "AwayPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
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

local panel = Instance.new("ImageLabel")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Image = ART.panel
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(1229 * K, 710 * K)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

-- Where QM's "+$999 CASH" was: the real amount, his green with a black stroke.
local cash = Instance.new("TextLabel")
cash.Name = "Amount"
cash.BackgroundTransparency = 1
cash.FontFace = FONT
cash.TextScaled = true
cash.TextColor3 = Color3.fromRGB(60, 255, 30)
cash.AnchorPoint = Vector2.new(0.5, 0.5)
cash.Position = UDim2.fromOffset(608 * K, 487 * K)
cash.Size = UDim2.fromOffset(760 * K, 74 * K)
cash.ZIndex = 2
local cashStroke = Instance.new("UIStroke")
cashStroke.Thickness = 3
cashStroke.Color = Color3.new(0, 0, 0)
cashStroke.Parent = cash
cash.Parent = panel

local function button(name, image, center, size)
	local b = Instance.new("ImageButton")
	b.Name = name
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Image = image
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromOffset(center.X * K, center.Y * K)
	b.Size = UDim2.fromOffset(size.X * K, size.Y * K)
	b.ZIndex = 3
	pressable(b)
	b.Parent = panel
	return b
end
local boost = button("Claim4x", ART.boost, Vector2.new(455, 611), Vector2.new(340, 340 * 142 / 358))
local claim = button("Claim", ART.claim, Vector2.new(815, 623), Vector2.new(331, 331 * 113 / 333))
-- (the rainbow's own label: the bar's the bottom ~80% of its art, the Robux badge over its top right)
local boostLabel = Instance.new("TextLabel")
boostLabel.BackgroundTransparency = 1
boostLabel.FontFace = FONT
boostLabel.Text = "Claim " .. Config.AwayBoost.Multiplier .. "x"
boostLabel.TextScaled = true
boostLabel.TextColor3 = Color3.new(1, 1, 1)
boostLabel.AnchorPoint = Vector2.new(0.5, 0.5)
boostLabel.Position = UDim2.fromScale(0.43, 0.6)
boostLabel.Size = UDim2.fromScale(0.5, 0.3)
boostLabel.ZIndex = 4
local boostStroke = Instance.new("UIStroke")
boostStroke.Thickness = 2.5
boostStroke.Color = Color3.new(0, 0, 0)
boostStroke.Parent = boostLabel
boostLabel.Parent = boost
gui.Parent = player:WaitForChild("PlayerGui")

-- The world behind hazy (as the Starter Pack's).
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 }
local blur = Instance.new("BlurEffect")
blur.Name = "AwayHaze"
blur.Size = 0
blur.Enabled = false
blur.Parent = camera
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "AwayHaze"
tint.Enabled = false
tint.Parent = camera
local hazeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function haze(on)
	local k = if on then 1 else 0
	blur.Enabled, tint.Enabled = true, true
	TweenService:Create(blur, hazeTween, { Size = HAZE.blur * k }):Play()
	local t = TweenService:Create(tint, hazeTween, { Brightness = HAZE.brightness * k, Contrast = HAZE.contrast * k, Saturation = HAZE.saturation * k })
	t.Completed:Connect(function()
		if not open then
			blur.Enabled, tint.Enabled = false, false
		end
	end)
	t:Play()
end

-- Every other bit of UI goes while it's up (as the Starter Pack's).
local hidden, holdHidden = {}, nil
local function hideOthers(on)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if on then
		local function hideAll()
			for _, g in player.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and g ~= gui then
					g.Enabled = false
					if not table.find(hidden, g) then
						table.insert(hidden, g)
					end
				end
			end
		end
		hideAll()
		holdHidden = RunService.RenderStepped:Connect(hideAll)
	else
		for _, g in hidden do
			g.Enabled = true
		end
		table.clear(hidden)
	end
end

local function setScale(scale)
	panelScale.Scale = scale
end

local function show(total)
	local gems = Config.Gems ~= nil -- (the Halloween world's pets earn gems)
	cash.Text = "+" .. (if gems then "" else "$") .. amount(total * (if gems then Config.Gems.Rate else 1)) .. (if gems then " GEMS" else " CASH")
	if open then
		return
	end
	open = true
	hideOthers(true)
	gui.Enabled = true
	haze(true)
	ModalPop.open(setScale)
	local telemetry = ReplicatedStorage:FindFirstChild("Telemetry")
	if telemetry then
		telemetry:FireServer("monoView", "away4x")
	end
end

local function close()
	if not open then
		return
	end
	open = false
	hideOthers(false)
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end)
end

claim.Activated:Connect(function()
	claimAway:FireServer()
end)
boost.Activated:Connect(function()
	ReplicatedStorage:WaitForChild("BuyShop"):FireServer("Away4x", "away") -- (Roblox's prompt; banked 4x once it's paid)
end)

-- Up when there's away gold and nothing else is going on; down once it's banked.
local checking = false
local function check()
	local total = player:GetAttribute("AwayGold")
	if not total or total <= 0 then
		close()
		return
	end
	if open then
		show(total)
		return
	end
	if checking then
		return
	end
	checking = true
	task.spawn(function()
		task.wait(1.5) -- (let the place settle in first)
		while player:GetAttribute("Tutorial") or player:GetAttribute("Cutscene") do
			task.wait(0.5)
		end
		checking = false
		local now = player:GetAttribute("AwayGold")
		if now and now > 0 then
			show(now)
		end
	end)
end
player:GetAttributeChangedSignal("AwayGold"):Connect(check)
check()
