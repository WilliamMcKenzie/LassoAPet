-- "While you were away" (QM, Oct 3): back after time away, a popup shows what your
-- pets earned meanwhile (the "AwayGold" attribute, Hatchery.server). The amount
-- counts up from $0 over COUNT_TIME with coins dropping behind it, bulges when it
-- lands and settles, and Claim banks it (ClaimAway). Layout follows QM's mockup.
-- While it's up, every other UI is hidden (QM): the game's own screens and Roblox's.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)

local player = Players.LocalPlayer
local claimAway = ReplicatedStorage:WaitForChild("ClaimAway")

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local FONT = Enum.Font.FredokaOne
local GOLD = Color3.fromRGB(80, 255, 60) -- the nameplates' income green (QM, Oct 7; was FFE11D)
local COIN = "rbxassetid://99312860837685" -- Hud's coin
local CLAIM = { id = "rbxassetid://135663178618300", size = Vector2.new(960, 378) } -- Claim.png
local CLAIM_WIDTH = 330
local COUNT_TIME = 2 -- seconds from $0 to the amount
local COINS_PER_SECOND = 16 -- dropping while it counts
local COIN_SIZE = { 56, 96 }
local FALL_TIME = { 1.1, 1.7 }
local BULGE = 0.35 -- how much bigger the amount pops when it lands

local gui = Instance.new("ScreenGui")
gui.Name = "AwayEarnings"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10 -- over the HUD
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

-- The darkened screen behind it all. A button, so clicks stop here.
local dim = Instance.new("TextButton")
dim.Text = ""
dim.AutoButtonColor = false
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BorderSizePixel = 0
dim.Size = UDim2.fromScale(1, 1)
dim.Parent = gui

-- Coins fall over the dimmed world, behind the text.
local coinLayer = Instance.new("Frame")
coinLayer.Name = "Coins"
coinLayer.BackgroundTransparency = 1
coinLayer.Size = UDim2.fromScale(1, 1)
coinLayer.ClipsDescendants = true
coinLayer.Parent = gui

-- Everything else is laid out on a REFERENCE_WIDTH-wide frame scaled to the screen.
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
root.Parent = gui

local function label(text, textSize, color, y)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromOffset(900, textSize * 1.3)
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = color
	l.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	local scale = Instance.new("UIScale")
	scale.Parent = l
	l.Parent = root
	return l, scale
end

local title, titleScale = label("While you were away...", 50, Color3.new(1, 1, 1), 0.28)
local amount, amountScale = label("$0", 84, GOLD, 0.44)

local claim = Instance.new("ImageButton")
claim.Name = "Claim"
claim.BackgroundTransparency = 1
claim.AutoButtonColor = false
claim.Image = CLAIM.id
claim.AnchorPoint = Vector2.new(0.5, 0.5)
claim.Position = UDim2.fromScale(0.5, 0.79)
claim.Size = UDim2.fromOffset(CLAIM_WIDTH, CLAIM_WIDTH * CLAIM.size.Y / CLAIM.size.X)
local claimScale = Instance.new("UIScale")
claimScale.Parent = claim
claim.Parent = root
local press = TweenInfo.new(0.08)
claim.MouseButton1Down:Connect(function()
	TweenService:Create(claimScale, press, { Scale = 0.93 }):Play()
end)
for _, event in { claim.MouseButton1Up, claim.MouseLeave } do
	event:Connect(function()
		TweenService:Create(claimScale, press, { Scale = 1 }):Play()
	end)
end

local rng = Random.new()

-- One coin dropping from above the screen to below it, tumbling as it goes.
local function dropCoin()
	local size = rng:NextNumber(COIN_SIZE[1], COIN_SIZE[2]) * rootScale.Scale
	local coin = Instance.new("ImageLabel")
	coin.BackgroundTransparency = 1
	coin.Image = COIN
	coin.AnchorPoint = Vector2.new(0.5, 0.5)
	coin.Size = UDim2.fromOffset(size, size)
	local x = rng:NextNumber(0.05, 0.95)
	coin.Position = UDim2.new(x, 0, 0, -size)
	coin.Rotation = rng:NextNumber(-30, 30)
	coin.Parent = coinLayer
	local fall = TweenService:Create(coin, TweenInfo.new(rng:NextNumber(FALL_TIME[1], FALL_TIME[2]), Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(x + rng:NextNumber(-0.04, 0.04), 0, 1, size),
		Rotation = coin.Rotation + rng:NextNumber(-200, 200),
	})
	fall.Completed:Connect(function()
		coin:Destroy()
	end)
	fall:Play()
end

-- Damped spring from 1 toward 0 (as Hud's): overshoots and settles.
local function spring(t, frequency, decay)
	return math.exp(-decay * t) * math.cos(t * frequency * math.pi * 2)
end

local showing = false
local claimed = false

-- Every other UI goes while it's up, and comes back as it was once it's claimed. A
-- screen another script turns on meanwhile stays off until then (and comes back on).
local StarterGui = game:GetService("StarterGui")
local KEEP = { AnimalDexWarm = true, PreloadWarm = true } -- (1 px, nearly see-through: keep art loaded)
local wanted = {} -- [ScreenGui] = whether it should be on once we're done
local watching = {}
local coreWas = {}
local function hold(screen)
	if screen == gui or not screen:IsA("ScreenGui") or KEEP[screen.Name] or wanted[screen] ~= nil then
		return
	end
	wanted[screen] = screen.Enabled
	screen.Enabled = false
	table.insert(watching, screen:GetPropertyChangedSignal("Enabled"):Connect(function()
		if screen.Enabled and wanted[screen] ~= nil then
			wanted[screen] = true
			screen.Enabled = false
		end
	end))
end
local playerGui = player:WaitForChild("PlayerGui")
local function hideOthers()
	for _, screen in playerGui:GetChildren() do
		hold(screen)
	end
	table.insert(watching, playerGui.ChildAdded:Connect(hold))
	for _, core in Enum.CoreGuiType:GetEnumItems() do
		-- (never the Backpack: the game's own inventory bar stands in for it, and
		-- restoring it here brought the Roblox hotbar back whenever this popup came
		-- up before Inventory had hidden it)
		if core ~= Enum.CoreGuiType.All and core ~= Enum.CoreGuiType.Backpack then
			coreWas[core] = StarterGui:GetCoreGuiEnabled(core)
		end
	end
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, false)
end
local function showOthers()
	for _, c in watching do
		c:Disconnect()
	end
	watching = {}
	local list = wanted
	wanted = {}
	for screen, on in list do
		if screen.Parent then
			screen.Enabled = on
		end
	end
	for core, on in coreWas do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, core, on)
	end
	coreWas = {}
end

local doClaim -- (below: the Claim button)

local function show(total)
	showing, claimed = true, false
	gui.Enabled = true
	Gamepad.openMenu("Away", { close = doClaim, keys = { [Enum.KeyCode.ButtonA] = doClaim } }) -- (A or B claims it)
	hideOthers()
	dim.BackgroundTransparency = 1
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()
	for _, s in { titleScale, claimScale } do
		s.Scale = 0
		TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	amountScale.Scale = 1
	amount.Text = Hud.money(0)
	local t, dropped = 0, 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not gui.Enabled then
			connection:Disconnect()
			return
		end
		t += dt
		if t < COUNT_TIME then
			-- Fast at first, easing into the real amount.
			local eased = 1 - (1 - t / COUNT_TIME) ^ 3
			amount.Text = Hud.money(total * eased)
			while dropped < t * COINS_PER_SECOND do
				dropped += 1
				dropCoin()
				if dropped % 3 == 1 then
					Sounds.play("gold_tick", 0.35) -- (every third coin: a steady patter)
				end
			end
			return
		end
		amount.Text = Hud.money(total)
		-- Landed: a quick swell, then a springy settle back to its size.
		local b = t - COUNT_TIME
		if b < 0.08 then
			amountScale.Scale = 1 + BULGE * b / 0.08
		elseif b < 1.2 then
			amountScale.Scale = 1 + BULGE * spring(b - 0.08, 2.2, 5)
		else
			amountScale.Scale = 1
			connection:Disconnect()
		end
	end)
end

local function hide()
	local fade = TweenInfo.new(0.25)
	TweenService:Create(dim, fade, { BackgroundTransparency = 1 }):Play()
	for _, s in { titleScale, amountScale, claimScale } do
		TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
	end
	task.delay(0.3, function()
		if claimed then
			gui.Enabled = false
			showing = false
			coinLayer:ClearAllChildren()
			showOthers()
		end
	end)
end

function doClaim()
	if showing and not claimed then
		claimed = true
		Gamepad.closeMenu("Away")
		claimAway:FireServer()
		hide()
	end
end
claim.Activated:Connect(doClaim)
Gamepad.hint(claim, Enum.KeyCode.ButtonA, Vector2.new(0.92, 0.12))

local function check()
	local total = player:GetAttribute("AwayGold")
	if total and total > 0 and not showing and not player:GetAttribute("Tutorial") then
		show(total)
	end
end
player:GetAttributeChangedSignal("AwayGold"):Connect(check)
check()
