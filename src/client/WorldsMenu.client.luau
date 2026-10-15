-- The Worlds menu (QM, Oct 12: his mockup): it pops up when you walk up to the portal
-- gate, and its X closes it (it won't pop up again until you've walked off and come
-- back). A dark rounded panel with "Worlds" over it and a card per world, each QM's
-- banner art with a button on its right: Travel for a world you have, Buy (with its
-- price) for one you don't. The world you're in has a white outline round its card.
-- Each world is its own Place (Config.Places): Buy unlocks one for its gold
-- (Config.WorldPrices; BuyWorld, Gold.server) and Travel teleports you there (Travel).
-- The same in every world (QM, Oct 13): the cards scroll, World 3's is QM's Coming Soon
-- banner (no button), and the panel shows just a sliver of it so you can tell it scrolls.
-- Buying World 2 from World 1 plays its unlock cutscene (WorldUnlock); after that the tap
-- hand points at World 2's Travel till you go ("GuideTravel").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)
local TapHand = require(script.Parent.TapHand)
local WorldUnlock = require(script.Parent.WorldUnlock)

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
-- (QM's mockup, Oct 13, was 1456 wide: its sizes x 1320 / 1456 here)
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Index's X, as the shop's)
local ART = { -- assets/ui/worlds (QM's; World2.png is his World1.png with a 2)
	World1 = "rbxassetid://117854477071908", -- World1.png: the banner (portal, tree, track; "World 1" on it)
	World2 = "rbxassetid://123640921226077", -- World2.png: QM's marble temple banner (Oct 13)
	World3 = "rbxassetid://122859842408693", -- World3.png: QM's "World 3" / COMING SOON banner (his World3 1.png)
	Travel = "rbxassetid://72409176941710", -- Travel.png: the blue button ("Travel" on it)
	TravelLoading = "rbxassetid://104387240097786", -- TravelLoading.png: the same in grey, while a trip's on its way
	Buy = "rbxassetid://128346351326066", -- Buy.png: the green button, a cash stack left, "Buy" right
}
local WORLDS = {
	{ name = "World 1", banner = "World1" },
	{ name = "World 2", banner = "World2" },
	{ name = "World 3", banner = "World3" }, -- (for sale: QM, Oct 15, 10m)
}
local CARD = Vector2.new(723, 212)
local LIST_TOP, CARD_PAD, CARD_GAP = 50, 12, 22 -- the scrolling list's top below the panel's; the first card's below that, and between them
local SLIVER = 34 -- px of the third card that shows (QM: so you can tell it scrolls)
local PANEL = Vector2.new(769, LIST_TOP + CARD_PAD + 2 * (CARD.Y + CARD_GAP) + SLIVER + 8) -- about 58% of the screen across
local BUTTON = Vector2.new(294, 71)
local BUTTON_INSET = 13 -- from the card's top right
local CASH_GREEN, CASH_RED = Color3.fromHex("00FF09"), Color3.fromRGB(255, 70, 70) -- (the Merge button's)
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local NEAR = 30 -- studs (across the ground) from the gate's middle: it pops up
local AWAY = 45 -- and you've walked off once you're this far

local player = Players.LocalPlayer
local open = false
local prompted = false -- (opened by World2Bar's prompt, not the gate: walking about doesn't close it)
local travelling = false -- (a trip's on its way: every Travel button waits)
local TRAVEL_WAIT = 15 -- seconds before Travel works again if the teleport never came
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

-- The cards scroll (QM, Oct 13), under the title.
local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.fromOffset(0, LIST_TOP)
list.Size = UDim2.new(1, 0, 1, -LIST_TOP - 8)
list.CanvasSize = UDim2.fromOffset(0, CARD_PAD * 2 + #WORLDS * CARD.Y + (#WORLDS - 1) * CARD_GAP)
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 30)
list.ZIndex = 2
list.Parent = panel

local travelHand = TapHand.new(90)
travelHand:SetAttribute("Focus", require(script.Parent.Focus).P.Travel) -- (one goal at a time: Client/Focus)
travelHand:SetAttribute("FocusGoal", "travel")
travelHand.Visible = false

local cards = {}
for i, world in WORLDS do
	local card = Instance.new("ImageLabel")
	card.Name = world.name
	card.BackgroundTransparency = 1
	card.Image = ART[world.banner]
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, CARD_PAD + (i - 1) * (CARD.Y + CARD_GAP))
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
	if world.soon then
		cards[i] = { card = card, here = here }
		card.Parent = list
		continue -- (Coming Soon: no button)
	end
	world.price = Config.WorldPrices[i] or 0
	local buy, travel
	if world.price > 0 then
		-- Buy: the art's cash stack, the price in green, then its "Buy".
		buy = button(ART.Buy)
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
			price.Text = "$" .. Config.short(world.price)
			price.TextColor3 = if (player:GetAttribute("Gold") or 0) >= world.price then CASH_GREEN else CASH_RED
		end
		player:GetAttributeChangedSignal("Gold"):Connect(showPrice)
		showPrice()
		buy.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			if not WorldUnlock.buy(i) then -- (it stays open: QM) -- (not enough gold; bought: World 2's unlock cutscene in World 1)
				price.Text = "Need $" .. Config.short(world.price)
				price.TextColor3 = CASH_RED
				task.wait(1.2)
			end
			busy = false
			showPrice()
		end)
		buy.Parent = card
	end
	travel = button(ART.Travel)
	travel.Name = "Travel"
	travel.Activated:Connect(function()
		if i ~= Config.World and not travelling then
			-- Loading (QM, Oct 13: a trip takes seconds): the button goes grey and does
			-- nothing more till the teleport takes you, or TRAVEL_WAIT if it doesn't.
			travelling = true
			travel.Image = ART.TravelLoading
			ReplicatedStorage.Travel:FireServer(i) -- (teleports: not in Studio)
			player:SetAttribute("GuideTravel", nil)
			task.delay(TRAVEL_WAIT, function()
				travelling = false
				travel.Image = ART.Travel
			end)
		end -- (it stays open: only its X or walking off closes it, QM Oct 13)
	end)
	travel.Parent = card
	-- Travel once it's yours (World 1 always is), Buy till then.
	local function owned()
		local has = i == 1 or player:GetAttribute("OwnsWorld" .. i) == true
		travel.Visible = has and i ~= Config.World -- (none on the world you're in: QM, Oct 13)
		if buy then
			buy.Visible = not has
		end
	end
	player:GetAttributeChangedSignal("OwnsWorld" .. i):Connect(owned)
	owned()
	if i == 2 then
		travelHand.Position = UDim2.fromScale(0.55, 0.55) -- (its fingertip on the button)
		travelHand.Parent = travel
	end
	cards[i] = { card = card, here = here }
	card.Parent = list
end
-- The tap hand on World 2's Travel once you've bought it, till you go (WorldUnlock).
local function showHand()
	travelHand.Visible = player:GetAttribute("GuideTravel") == true and Config.World ~= 2
end
player:GetAttributeChangedSignal("GuideTravel"):Connect(showHand)
showHand()

local function showHere()
	for i, c in cards do
		c.here.Visible = i == Config.World
	end
end
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

-- Every other bit of UI goes while it's open (QM, Oct 13), and comes back when it closes.
local hidden, holdHidden = {}, nil
local function hideOthers(on)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if on then
		player:SetAttribute("Cutscene", true) -- (BaseUi and the guides keep themselves off)
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
		player:SetAttribute("Cutscene", nil)
	end
end

local function openMenu()
	if open then
		return
	end
	open = true
	hideOthers(true)
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
	prompted = false
	hideOthers(false)
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end)
end
closeButton.Activated:Connect(function()
	closeMenu()
end)

-- World 1's World 2 prompt (QM, Oct 14: was a forced box over the World 2 bar; softened so
-- players can close it and play on): World2Bar fires this to open the menu wherever you are.
local promptEvent = Instance.new("BindableEvent")
promptEvent.Name = "OpenWorldsMenu"
promptEvent.Event:Connect(function()
	if not open then
		openMenu()
		prompted = true
	end
end)
promptEvent.Parent = script

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
		if open and not prompted then
			closeMenu()
		end
	elseif d < NEAR and armed and not humanoid.SeatPart then -- (not riding past)
		armed = false
		openMenu()
	end
end)
