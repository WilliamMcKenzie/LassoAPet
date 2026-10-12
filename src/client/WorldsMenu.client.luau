-- The Worlds menu (QM, Oct 12: his mockup): it pops up when you walk up to the portal
-- gate, and its X closes it (it won't pop up again until you've walked off and come
-- back). A dark rounded panel with "Worlds" over it and a card per world, each QM's
-- banner art with a button on its right: Travel for a world you have, Buy (with its
-- price) for one you don't. The world you're in has a white outline round its card.
-- For now there's only World 1 (you're always in it); World 2's Buy says "Coming soon"
-- and charges nothing until World 2 exists.
-- Art: "" = a placeholder drawn in its place, until QM's files are uploaded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Index's X, as the shop's)
local ART = {
	World1 = "", -- World1.png: the banner (portal, tree, track; "World 1" on it)
	Travel = "", -- Travel.png: the blue button
	Buy = "", -- Buy.png: the green button, a cash stack on its left
}
local WORLDS = {
	{ name = "World 1", banner = "World1" },
	{ name = "World 2", banner = "World1", price = 400 },
}
local PANEL = Vector2.new(760, 470)
local CARD = Vector2.new(700, 200)
local BUTTON = Vector2.new(210, 84)
local PAD = 30 -- the panel's edge to the cards, and between them
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
panel.Position = UDim2.fromScale(0.5, 0.53)
panel.Size = UDim2.fromOffset(PANEL.X, PANEL.Y)
panel.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
panel.BackgroundTransparency = 0.25
rounded(panel, 28)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 1)
title.Position = UDim2.new(0.5, 0, 0, 22)
title.Size = UDim2.fromOffset(360, 84)
title.Text = "Worlds"
title.ZIndex = 3
outlined(title, 5)
title.Parent = panel

local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.fromOffset(PANEL.X - 8, 8)
closeButton.Size = UDim2.fromOffset(80, 80)
closeButton.ZIndex = 4
pressable(closeButton)
closeButton.Parent = panel

-- A button: QM's art, or a coloured placeholder with its text.
local function button(art, color, text)
	local b = Instance.new("ImageButton")
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -24, 0.5, 0)
	b.Size = UDim2.fromOffset(BUTTON.X, BUTTON.Y)
	b.Image = art
	b.BackgroundTransparency = if art ~= "" then 1 else 0
	b.BackgroundColor3 = color
	b.ZIndex = 3
	if art == "" then
		rounded(b, 18)
		local edge = Instance.new("UIStroke")
		edge.Thickness = 4
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = b
	end
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.8, 0.6)
	label.Text = text
	label.ZIndex = 4
	outlined(label, 3)
	label.Parent = b
	pressable(b)
	return b, label
end

local cards = {}
for i, world in WORLDS do
	local card = Instance.new("ImageLabel")
	card.Name = world.name
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, PAD + (i - 1) * (CARD.Y + PAD))
	card.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	local art = ART[world.banner] or ""
	card.Image = art
	card.ScaleType = Enum.ScaleType.Crop
	card.BackgroundColor3 = Color3.fromRGB(96, 170, 90) -- (placeholder: grass)
	card.BackgroundTransparency = if art ~= "" then 1 else 0
	card.ZIndex = 2
	rounded(card, 22)
	-- The world you're in: a white outline round its card (QM).
	local here = Instance.new("UIStroke")
	here.Name = "Here"
	here.Color = Color3.new(1, 1, 1)
	here.Thickness = 6
	here.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	here.Parent = card
	-- Its name, top left (QM's banner has "World 1" drawn on: shown where the art isn't
	-- this world's own).
	local name = Instance.new("TextLabel")
	name.Name = "WorldName"
	name.Position = UDim2.fromOffset(22, 14)
	name.Size = UDim2.fromOffset(240, 60)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = world.name
	name.ZIndex = 3
	outlined(name, 4)
	name.Visible = art == "" or world.banner ~= "World" .. i
	name.Parent = card
	if world.price then
		local buy, label = button(ART.Buy, Color3.fromRGB(80, 200, 70), "$" .. world.price)
		buy.Name = "Buy"
		if ART.Buy ~= "" then -- (the price beside the art's cash stack, over its "Buy")
			label.AnchorPoint = Vector2.new(1, 0.5)
			label.Position = UDim2.fromScale(0.94, 0.5)
			label.Size = UDim2.fromScale(0.55, 0.6)
		end
		local busy = false
		buy.Activated:Connect(function()
			if busy then
				return
			end
			busy = true -- World 2 isn't there yet (QM): it charges nothing
			label.Text = "Coming soon"
			task.delay(1.5, function()
				label.Text = "$" .. world.price
				busy = false
			end)
		end)
		buy.Parent = card
	else
		local travel = button(ART.Travel, Color3.fromRGB(60, 140, 240), "Travel")
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
		c.here.Enabled = i == world
	end
end
player:GetAttributeChangedSignal("World"):Connect(showHere)
showHere()

gui.Parent = player:WaitForChild("PlayerGui")

local function setScale(scale)
	panelScale.Scale = scale
end

local function openMenu()
	if open then
		return
	end
	open = true
	showHere()
	gui.Enabled = true
	ModalPop.open(setScale)
end

function closeMenu()
	if not open then
		return
	end
	open = false
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
