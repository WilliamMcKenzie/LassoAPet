-- The Worlds menu (QM, Oct 12: his mockup): it pops up when you walk up to the portal
-- gate, and its X closes it (it won't pop up again until you've walked off and come
-- back). A dark rounded panel with "Worlds" over it and a card per world, each QM's
-- banner art with a button on its right: Travel for a world you have, Buy (with its
-- price) for one you don't. The world you're in has a white outline round its card.
-- For now there's only World 1 (you're always in it); World 2's Buy says "Coming soon"
-- and charges nothing until World 2 exists.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
-- (QM's mockup, Oct 13, was 1456 wide: its sizes x 1320 / 1456 here)
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Index's X, as the shop's)
local ART = { -- assets/ui/worlds (QM's; World2.png is his World1.png with a 2)
	World1 = "rbxassetid://117854477071908", -- World1.png: the banner (portal, tree, track; "World 1" on it)
	World2 = "rbxassetid://139660587337646", -- World2.png
	Travel = "rbxassetid://72409176941710", -- Travel.png: the blue button ("Travel" on it)
	Buy = "rbxassetid://128346351326066", -- Buy.png: the green button, a cash stack left, "Buy" right
}
local WORLDS = {
	{ name = "World 1", banner = "World1" },
	{ name = "World 2", banner = "World2", price = 400 },
}
local PANEL = Vector2.new(769, 520) -- about 58% of the screen across
local CARD = Vector2.new(723, 212)
local CARD_TOP, CARD_GAP = 62, 22 -- the first card's top below the panel's, and between them
local BUTTON = Vector2.new(294, 71)
local BUTTON_INSET = 13 -- from the card's top right
local CASH_GREEN, CASH_RED = Color3.fromHex("00FF09"), Color3.fromRGB(255, 70, 70) -- (the Merge button's)
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local NEAR = 30 -- studs (across the ground) from the gate's middle: it pops up
local AWAY = 45 -- and you've walked off once you're this far

local player = Players.LocalPlayer
local open = false
local closeMenu

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

local function outlined(label, thickness)
	label.BackgroundTransparency = 1
	label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 3
	stroke.Parent = label
end

local function rounded(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

local gui = Instance.new("ScreenGui")
gui.Name = "WorldsMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, as the other menus
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
root.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL.X, PANEL.Y)
panel.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
panel.BackgroundTransparency = 0.15
rounded(panel, 11)
local panelEdge = Instance.new("UIStroke")
panelEdge.Color = Color3.fromRGB(16, 16, 16)
panelEdge.Thickness = 4
panelEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
panelEdge.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

-- "Worlds" across the panel's top edge.
local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.new(0.5, 0, 0, -3)
title.Size = UDim2.fromOffset(360, 48)
title.Text = "Worlds"
title.ZIndex = 3
outlined(title, 3)
title.FontFace = MONTSERRAT
title.Parent = panel

-- The X, centred on the panel's top right corner.
local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.new(1, -5, 0, 6)
closeButton.Size = UDim2.fromOffset(71, 71)
closeButton.ZIndex = 4
pressable(closeButton)
closeButton.Parent = panel

-- A button of QM's art, at the card's top right.
local function button(art)
	local b = Instance.new("ImageButton")
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Image = art
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -BUTTON_INSET, 0, BUTTON_INSET)
	b.Size = UDim2.fromOffset(BUTTON.X, BUTTON.Y)
	b.ZIndex = 3
	pressable(b)
	return b
end

local cards = {}
for i, world in WORLDS do
	local card = Instance.new("ImageLabel")
	card.Name = world.name
	card.BackgroundTransparency = 1
	card.Image = ART[world.banner]
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, CARD_TOP + (i - 1) * (CARD.Y + CARD_GAP))
	card.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	card.ZIndex = 2
	-- The world you're in: a white outline round the art's black one (QM).
	local here = Instance.new("Frame")
	here.Name = "Here"
	here.BackgroundTransparency = 1
	here.Size = UDim2.fromScale(1, 1)
	here.ZIndex = 3
	rounded(here, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = here
	here.Parent = card
	if world.price then
		-- Buy: the art's cash stack, the price in green, then its "Buy".
		local buy = button(ART.Buy)
		buy.Name = "Buy"
		-- The price as the merge menu's Merge button has it (QM): left aligned just past
		-- the cash, Montserrat ExtraBold with a round black stroke, green when you can
		-- afford it and red when you can't (its 420-wide button's sizes x 0.7).
		local K = BUTTON.X / 420
		local price = Instance.new("TextLabel")
		price.Name = "Price"
		price.BackgroundTransparency = 1
		price.FontFace = MONTSERRAT
		price.TextSize = 48 * K
		price.TextXAlignment = Enum.TextXAlignment.Left
		price.AnchorPoint = Vector2.new(0, 0.5)
		price.Position = UDim2.new(0, 83 * K, 0.5, 0)
		price.Size = UDim2.fromOffset(158 * K, 64 * K)
		price.ZIndex = 4
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 5 * K
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = price
		price.Parent = buy
		local busy = false
		local function showPrice()
			if busy then
				return
			end
			price.Text = "$" .. world.price
			price.TextColor3 = if (player:GetAttribute("Gold") or 0) >= world.price then CASH_GREEN else CASH_RED
		end
		player:GetAttributeChangedSignal("Gold"):Connect(showPrice)
		showPrice()
		buy.Activated:Connect(function()
			if busy then
				return
			end
			busy = true -- World 2 isn't there yet (QM): it charges nothing
			price.Text = "Soon!"
			price.TextColor3 = Color3.new(1, 1, 1)
			task.delay(1.5, function()
				busy = false
				showPrice()
			end)
		end)
		buy.Parent = card
	else
		local travel = button(ART.Travel)
		travel.Name = "Travel"
		travel.Activated:Connect(function()
			if open then
				closeMenu()
			end
		end)
		travel.Parent = card
	end
	cards[i] = { card = card, here = here }
	card.Parent = panel
end

local function showHere()
	local world = player:GetAttribute("World") or 1 -- (only World 1 for now)
	for i, c in cards do
		c.here.Visible = i == world
	end
end
player:GetAttributeChangedSignal("World"):Connect(showHere)
showHere()

gui.Parent = player:WaitForChild("PlayerGui")

local function setScale(scale)
	panelScale.Scale = scale
end

-- While it's open the world behind goes hazy, like frosted glass (QM): blurred, paler
-- and a little washed out, fading in and out.
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 }
local blur = Instance.new("BlurEffect")
blur.Name = "WorldsMenuHaze"
blur.Size = 0
blur.Enabled = false
blur.Parent = camera
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "WorldsMenuHaze"
tint.Enabled = false
tint.Parent = camera
local hazeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function haze(on)
	local k = if on then 1 else 0
	blur.Enabled, tint.Enabled = true, true
	TweenService:Create(blur, hazeTween, { Size = HAZE.blur * k }):Play()
	local t = TweenService:Create(tint, hazeTween, {
		Brightness = HAZE.brightness * k,
		Contrast = HAZE.contrast * k,
		Saturation = HAZE.saturation * k,
	})
	t.Completed:Connect(function()
		if not open then
			blur.Enabled, tint.Enabled = false, false
		end
	end)
	t:Play()
end

local function openMenu()
	if open then
		return
	end
	open = true
	showHere()
	gui.Enabled = true
	haze(true)
	ModalPop.open(setScale)
end

function closeMenu()
	if not open then
		return
	end
	open = false
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end)
end
closeButton.Activated:Connect(function()
	closeMenu()
end)

-- Walking up to the gate pops it up, once a visit: walk off (AWAY) and back for it again.
local gate = workspace:WaitForChild("World"):WaitForChild("BaseDecor"):WaitForChild("PortalGate", 30)
if not gate then
	return
end
local armed = true
RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	local centre = gate:GetPivot().Position
	local d = Vector2.new(root.Position.X - centre.X, root.Position.Z - centre.Z).Magnitude
	if d > AWAY then
		armed = true
		if open then
			closeMenu()
		end
	elseif d < NEAR and armed and not humanoid.SeatPart then -- (not riding past)
		armed = false
		openMenu()
	end
end)
