-- Game pass popups (QM, Oct 7): QM's card for a pass bounces in at the top right at
-- the moment it would help, and tapping it asks to buy the pass (BuyPass,
-- Server/Passes). It stays until you leave your base (over the start line), then
-- it's gone. They're kept rare: none in your first MIN_PLAY seconds (a moment
-- before that waits till then), each pass pops at most once a visit, one at a
-- time, and never for a pass you own or that isn't on sale.
--   VIP: you unlocked the Desert
--   Fast Hatch: you put an egg down in your pen
--   Auto Hatch: you hatched an egg by hand
--   x2 Gold: back home from a ride without the gold for the next zone
-- "/popup vip|auto|speed|gold" (QM only: Server/Passes) shows one now, whatever the rules.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local world = workspace:WaitForChild("World")
local buyPass = ReplicatedStorage:WaitForChild("BuyPass")

-- QM's cards (assets/ui/PassPopup*.png), their size in pixels as drawn, and how
-- big they show: SCALE x that, in pixels of Hud's 1320-wide screen.
local ART = {
	VIP = { id = "rbxassetid://132592725982767", size = Vector2.new(716, 352) }, -- PassPopupVIP.png
	FastHatch = { id = "rbxassetid://85992452177736", size = Vector2.new(1388, 402) }, -- PassPopupFastHatch.png
	AutoHatch = { id = "rbxassetid://87748999824256", size = Vector2.new(1140, 402) }, -- PassPopupAutoHatch.png
	DoubleGold = { id = "rbxassetid://135226874634598", size = Vector2.new(926, 378) }, -- PassPopupDoubleGold.png
}
local SCALE = 0.23 -- the VIP card about 165 x 80, as in QM's mockup
local REFERENCE_WIDTH = 1320 -- Hud's
local MARGIN = 24 -- from the top and right edges
local MIN_PLAY = 300 -- seconds into a visit before any pops by itself
local START_LINE_Z = if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else -2
local LEFT_BASE = 4 -- studs past the start line: you've left your base

local passes = {} -- [Key] = Config.Passes entry
for _, pass in Config.Passes do
	passes[pass.Key] = pass
end

local joinedAt = os.clock()
local shownOnce = {} -- [Key] = true once it's popped this visit
local waiting -- a pass whose moment came before MIN_PLAY was up
local current -- { key, card, scale } on screen

local gui = Instance.new("ScreenGui")
gui.Name = "PassPopups"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1 -- over the HUD
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local camera = workspace.CurrentCamera
local function resize()
	local screen = if gui.AbsoluteSize.X > 0 then gui.AbsoluteSize else camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")
resize()

local function onSale(pass)
	return pass.Id ~= 0 or RunService:IsStudio()
end

local function atBase()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return hrp ~= nil and hrp.Position.Z > START_LINE_Z - LEFT_BASE
end

-- bought: it bounces away (swells, then springs out up and off the screen's
-- edge, QM); otherwise it just shrinks away.
local function hide(bought)
	local shown = current
	if not shown then
		return
	end
	current = nil
	local out
	if bought then
		local swell = TweenService:Create(shown.scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.2 })
		out = TweenService:Create(shown.card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = shown.card.Position + UDim2.new(0, 120, 0, -260), Rotation = 25 })
		swell.Completed:Connect(function()
			out:Play()
		end)
		swell:Play()
	else
		out = TweenService:Create(shown.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
		out:Play()
	end
	out.Completed:Connect(function()
		shown.card:Destroy()
	end)
end

local function show(key)
	local art = ART[key]
	if not art then
		return
	end
	if current then
		current.card:Destroy()
		current = nil
	end
	local card = Instance.new("ImageButton")
	card.Name = key
	card.BackgroundTransparency = 1
	card.AutoButtonColor = false
	card.Image = art.id
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, -MARGIN, 0, MARGIN)
	card.Size = UDim2.fromOffset(art.size.X * SCALE, art.size.Y * SCALE)
	if art.id == "" then -- (until Studio uploads QM's art: a plain gold card with the name and price)
		card.BackgroundTransparency = 0
		card.BackgroundColor3 = Color3.fromRGB(255, 196, 40)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0.3, 0)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = passes[key].Name .. "  " .. passes[key].Price .. "R"
		Instance.new("UIStroke", label).Thickness = 3
		label.Parent = card
	end
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = card
	card.Activated:Connect(function()
		buyPass:FireServer(key)
	end)
	card.Parent = root
	current = { key = key, card = card, scale = scale, owned = player:GetAttribute("Pass" .. key) == true } -- (owned: only by /popup)
	-- Pops in with a bounce.
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- The moment for `key` has come: it pops now, or once MIN_PLAY is up.
local function moment(key)
	local pass = passes[key]
	if not pass or shownOnce[key] or current or not onSale(pass) or player:GetAttribute("Pass" .. key)
		or player:GetAttribute("Tutorial") then
		return
	end
	if os.clock() - joinedAt < MIN_PLAY or not atBase() then
		waiting = waiting or key
		return
	end
	shownOnce[key] = true
	show(key)
end

-- Leaving your base takes it away; a waiting one pops once it may.
local wasAtBase = true
RunService.Heartbeat:Connect(function()
	local here = atBase()
	if current and player:GetAttribute("Pass" .. current.key) and not current.owned then
		hide(true) -- just bought
	elseif current and not here then
		hide()
	end
	if waiting and here and not current and os.clock() - joinedAt >= MIN_PLAY then
		local key = waiting
		waiting = nil
		moment(key)
	end
	-- x2 Gold: back home from a ride without the gold for the next zone.
	if here and not wasAtBase then
		local level = player:GetAttribute("PenLevel") or 1
		local nextZone = Config.Biomes[level + 1]
		if nextZone and nextZone.UnlockCost and (player:GetAttribute("Gold") or 0) < nextZone.UnlockCost then
			moment("DoubleGold")
		end
	end
	wasAtBase = here
end)

-- VIP: you unlocked the Desert (PenLevel.server tells the buyer first).
ReplicatedStorage:WaitForChild("ZoneUnlocked").OnClientEvent:Connect(function(level)
	if level == 2 then
		moment("VIP")
	end
end)

-- Fast Hatch and Auto Hatch, from your pen's contents (Hatchery publishes them):
-- a new egg is one you put down, and an egg that's now a pet was hatched (by
-- hand: Auto Hatch owners never get its popup).
local seen -- [item id] = "egg" | "pet", as last published
local function watchPen(pen)
	seen = nil
	local function read()
		local ok, items = pcall(HttpService.JSONDecode, HttpService, pen:GetAttribute("Contents") or "{}")
		if not ok or typeof(items) ~= "table" then
			return
		end
		local now = {}
		for id, item in items do
			now[id] = if item.egg then "egg" elseif item.pet then "pet" else nil
		end
		if seen then
			for id, what in now do
				if what == "egg" and not seen[id] then
					moment("FastHatch")
				elseif what == "pet" and seen[id] == "egg" then
					moment("AutoHatch")
				end
			end
		end
		seen = now
	end
	pen:GetAttributeChangedSignal("Contents"):Connect(read)
	read()
end
task.spawn(function()
	local pens = workspace:WaitForChild("Pens")
	local index = player:GetAttribute("Pen")
	while not index do
		player:GetAttributeChangedSignal("Pen"):Wait()
		index = player:GetAttribute("Pen")
	end
	local pen = pens:WaitForChild("Pen" .. index, 10)
	if pen then
		watchPen(pen)
	end
end)

-- QM's "/popup ...": shown now.
ReplicatedStorage:WaitForChild("PassPopup").OnClientEvent:Connect(function(key)
	if passes[key] then
		show(key) -- (even for a pass you own)
	end
end)
