-- The shop uses the supplied cards; prices and odds are baked into the art. QM's Oct 20 design:
-- the Halloween Egg banner (NEW, LIMITED!) with its four buy buttons along its bottom, then the
-- three cash packs in an even row across the panel; the 2x Cash and Invincible passes are gone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)
local Gamepad = require(script.Parent.Gamepad)
local Shop = {}
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local buyShop = ReplicatedStorage:WaitForChild("BuyShop")
local open = false
local ART = {
	Panel = "rbxassetid://125036875690208",
	Halloween = "rbxassetid://95709238284593", -- assets/ui/shop3/HalloweenEgg.png (1192x470, QM Oct 20, with its border; shrunk to 1024x404 by the upload)
	Egg1 = "rbxassetid://93494892373199",
	Egg3 = "rbxassetid://106323361129280",
	Egg10 = "rbxassetid://74397756416359",
	Egg50 = "rbxassetid://135798607638786",
	Cash500K = "rbxassetid://101951033426315", -- assets/ui/shop3 (QM, Oct 20: with borders)
	Cash5M = "rbxassetid://83223429511866",
	Cash1B = "rbxassetid://113449238733442",
	StarterPack = "rbxassetid://129857278922864", -- assets/ui/shop3/StarterPack.png (1192x470, QM Oct 20; shrunk to 1024x404 by the upload)
	StarterBuy = "rbxassetid://79966597417896", -- assets/ui/shop3/StarterBuy.png (230x134): Robux 39
	World2 = "rbxassetid://128433749405556", -- assets/ui/shop3/World2.png (342x64): the Starter Pack's "WORLD 2", pulsing
	Price49 = "rbxassetid://114300820141286", -- assets/ui/shop3/Price49.png (144x108, QM Oct 20)
	Price99 = "rbxassetid://107487299920702",
	Price299 = "rbxassetid://80262179750586",
	Close = "rbxassetid://84920756991403",
}
local restricted
function Shop.randomRestricted()
	if restricted == nil then
		local ok, info = pcall(function()
			return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player)
		end)
		restricted = not ok or info.ArePaidRandomItemsRestricted == true
	end
	return restricted
end
local function offered(offer)
	return offer.ProductId ~= 0
end
function Shop.hasGold()
	return #Config.Shop.CashPacks > 0
end
function Shop.hasOffers()
	return Config.ShopOn
end

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "Shop", false, true
gui.DisplayOrder, gui.Enabled = 20, false
local root = Instance.new("Frame")
root.Name, root.BackgroundTransparency = "Root", 1
root.AnchorPoint, root.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(1230, 969)
root.Parent = gui
local fit = Instance.new("UIScale", root)
local function resize()
	local size = camera.ViewportSize
	fit.Scale = math.min(size.X * 0.792 / 1230, size.Y * 0.97 / 969) -- (10% bigger, QM Oct 20: was 0.72 / 0.90)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
local panel = Instance.new("ImageLabel")
panel.Name, panel.BackgroundTransparency, panel.Image = "Panel", 1, ART.Panel
panel.Size = UDim2.fromScale(1, 1)
panel.ImageTransparency = 0.15
panel.Parent = root
local pop = Instance.new("UIScale", panel)
panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
local function image(parent, name, art, x, y, w, h, button)
	local item = Instance.new(if button then "ImageButton" else "ImageLabel")
	item.Name, item.BackgroundTransparency, item.Image = name, 1, art
	item.Position, item.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	if button then
		item.AutoButtonColor = false
	end
	item.Parent = parent
	return item
end
local function outlined(parent, name, text, x, y, w, h)
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.BackgroundTransparency = name, text, 1
	label.Position, label.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
	label.Font, label.TextScaled, label.TextColor3 = Enum.Font.FredokaOne, true, Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke", label)
	stroke.Thickness = 3
	label.Parent = parent
	return label
end
local function pressable(button)
	local scale = Instance.new("UIScale", button)
	-- Anchor at the centre so purchase buttons shrink in place.
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position += UDim2.fromOffset(button.Size.X.Offset / 2, button.Size.Y.Offset / 2)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.95 }):Play()
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1 }):Play()
		end)
	end
end
local closeButton = image(panel, "Close", ART.Close, 1178, 12, 94, 94, true)
closeButton.ZIndex = 4
pressable(closeButton)
closeButton.Activated:Connect(function()
	Shop.close()
end)
local scroll = Instance.new("ScrollingFrame")
scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel = "Offers", 1, 0
scroll.Position, scroll.Size = UDim2.fromOffset(25, 143), UDim2.fromOffset(1180, 779) -- (half the side margin, QM Oct 20: was 50 in, 1132 wide)
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- (all of it fits now: it only scrolls on a short screen)
scroll.ScrollingDirection, scroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 0
scroll.ScrollBarImageColor3 = Color3.fromRGB(230, 230, 230)
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = panel
-- The banner across the panel, at its art's shape; its buy buttons where QM's design has them
-- (x in the art's 1192 pixels: 285, 444, 599, 754; tops at 347, under each one's "x1" label).
local EGG_W = 1180
local EGG_K = EGG_W / 1192
local egg = image(scroll, "HalloweenEgg", ART.Halloween, 0, 0, EGG_W, math.round(470 * EGG_K))
local cards, eggButtons = {}, {}
for i, count in { 1, 3, 10, 50 } do
	local width = if count == 50 then 163 else 145
	local x = ({ 285, 444, 599, 754 })[i]
	local button = image(egg, "Buy" .. count, ART["Egg" .. count], math.round(x * EGG_K), math.round(347 * EGG_K), math.round(width * EGG_K), math.round(98 * EGG_K), true)
	pressable(button)
	button.Activated:Connect(function()
		local offer = Config.Shop.HalloweenPacks[i]
		if open and offered(offer) and not Shop.randomRestricted() then
			buyShop:FireServer(offer.Key, "shop")
		end
	end)
	table.insert(cards, button)
	table.insert(eggButtons, button)
end
local function eggAvailability()
	local allowed = not Shop.randomRestricted()
	for i, button in eggButtons do
		local enabled = allowed and offered(Config.Shop.HalloweenPacks[i])
		button.Active, button.Selectable = enabled, enabled
		button.ImageTransparency = if enabled then 0 else 0.55
	end
	local ready = true
	for _, offer in Config.Shop.HalloweenPacks do
		ready = ready and offered(offer)
	end
	local message = egg:FindFirstChild("Availability")
	if not message then
		message = outlined(egg, "Availability", "", 20, egg.Size.Y.Offset - 34, EGG_W - 40, 25)
	end
	message.Text = if not allowed
		then "Paid random items unavailable in your region"
		elseif not ready then "Coming soon"
		else ""
end
task.spawn(eggAvailability)
-- The cash packs: an even row of three under the banner, each card the same width with the same
-- gaps, at its art's shape, its price button where it was on the card (scaled with it).
local CASH_GAP = 24
local CASH_W = (EGG_W - 2 * CASH_GAP) / 3
local CASH_K = CASH_W / 349
local CASH_Y = egg.Size.Y.Offset + 28
local cashCards = {} -- (moved down under the Starter Pack while it's up: below)
for i, offer in Config.Shop.CashPacks do
	local card = image(
		scroll,
		offer.Key,
		if i == 1 then ART.Cash500K elseif i == 3 then ART.Cash1B else ART.Cash5M,
		math.round((i - 1) * (CASH_W + CASH_GAP)),
		CASH_Y,
		math.round(CASH_W),
		math.round(184 * CASH_K)
	)
	local button = image(
		card,
		"Buy",
		if i == 1 then ART.Price49 elseif i == 2 then ART.Price99 else ART.Price299,
		math.round(191 * CASH_K), -- (where QM's reference has it on the 349x184 card, Oct 20)
		math.round(59 * CASH_K),
		math.round(144 * CASH_K),
		math.round(108 * CASH_K),
		true
	)
	table.insert(cashCards, card)
	pressable(button)
	button.Activated:Connect(function()
		if open then
			buyShop:FireServer(offer.Key, "shop")
		end
	end)
	table.insert(cards, button)
end

-- The Starter Pack (QM, Oct 20): its card on top, over the Halloween Egg, while it's on offer: ten
-- minutes from when it's first seen each join (the HUD's Starter Pack button or here: the local
-- "StarterPackShownAt", shared with PassButtons) and till it's yours. Its ribbon counts down;
-- Buy is Roblox's prompt for the pass (Server/Passes; Hatchery gives it).
local STARTER_FOR = 10 * 60
local starter = image(scroll, "StarterPack", ART.StarterPack, 0, 0, EGG_W, math.round(470 * EGG_K))
local starterBuy = image(starter, "Buy", ART.StarterBuy, math.round(943 * EGG_K), math.round(318 * EGG_K), math.round(230 * EGG_K), math.round(134 * EGG_K), true)
pressable(starterBuy)
starterBuy.ZIndex = 3
local STARTER_BUY = Vector2.new(starterBuy.Size.X.Offset, starterBuy.Size.Y.Offset)
-- (QM's sunburst, turning behind "WORLD 2" (placed with it, below), and Buy pulsing: QM, Oct 20)
local starterBurst = Instance.new("ImageLabel")
starterBurst.Name = "Sunburst"
starterBurst.BackgroundTransparency = 1
starterBurst.Image = "rbxassetid://85834206672187" -- assets/ui/Sunburst.png (QM's)
starterBurst.ImageTransparency = 0.2
starterBurst.AnchorPoint = Vector2.new(0.5, 0.5)
starterBurst.Position = starterBuy.Position
starterBurst.Size = UDim2.fromOffset(STARTER_BUY.X * 1.7, STARTER_BUY.X * 1.7)
starterBurst.ZIndex = 1
starterBurst.Parent = starter
starterBuy.Activated:Connect(function()
	if open then
		ReplicatedStorage:WaitForChild("BuyPass"):FireServer("StarterPack")
	end
end)
table.insert(cards, 1, starterBuy)
local ribbon = Instance.new("TextLabel") -- (on the art's red ribbon, along it)
ribbon.Name = "Countdown"
ribbon.BackgroundTransparency = 1
ribbon.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
ribbon.TextScaled = true
ribbon.TextColor3 = Color3.new(1, 1, 1)
ribbon.AnchorPoint = Vector2.new(0.5, 0.5)
ribbon.Position = UDim2.fromOffset(math.round(1092 * EGG_K), math.round(52 * EGG_K))
ribbon.Size = UDim2.fromOffset(math.round(190 * EGG_K), math.round(38 * EGG_K))
ribbon.Rotation = 20
ribbon.ZIndex = 3 -- (plain white, no stroke: QM, Oct 20)
ribbon.Parent = starter
local world2 = Instance.new("ImageLabel") -- (QM's "WORLD 2" on its own, so it can pulse: Oct 20)
world2.Name = "World2"
world2.BackgroundTransparency = 1
world2.Image = ART.World2
world2.AnchorPoint = Vector2.new(0.5, 0.5)
world2.Position = UDim2.fromOffset(math.round(207 * EGG_K), math.round(291 * EGG_K))
local WORLD2 = Vector2.new(342 * EGG_K, 64 * EGG_K)
world2.Size = UDim2.fromOffset(WORLD2.X, WORLD2.Y)
world2.ZIndex = 2
world2.Parent = starter
starterBurst.Position = world2.Position -- (the sunburst behind it, not Buy: QM, Oct 20)
starterBurst.Size = UDim2.fromOffset(WORLD2.X * 1.3, WORLD2.X * 1.3)
local function starterLeft()
	local shownAt = player:GetAttribute("StarterPackShownAt")
	return math.max(0, math.ceil(STARTER_FOR - (if shownAt then os.clock() - shownAt else 0)))
end
local function layout()
	local show = starterLeft() > 0 and not player:GetAttribute("PassStarterPack")
	starter.Visible = show
	starterBuy.Selectable = show
	local y = if show then starter.Size.Y.Offset + 28 else 0
	egg.Position = UDim2.fromOffset(0, y)
	for _, card in cashCards do
		card.Position = UDim2.fromOffset(card.Position.X.Offset, y + egg.Size.Y.Offset + 28)
	end
end
layout()
player:GetAttributeChangedSignal("PassStarterPack"):Connect(layout)
RunService.Heartbeat:Connect(function()
	if gui.Enabled and starter.Visible then
		if not player:GetAttribute("StarterPackShownAt") then
			player:SetAttribute("StarterPackShownAt", os.clock()) -- (first seen here: its ten minutes start)
		end
		local k = 1 + 0.08 * (0.5 - 0.5 * math.cos(os.clock() * math.pi * 2 * 1.1)) -- ("WORLD 2" swells up to 8% and back, about once a second)
		world2.Size = UDim2.fromOffset(WORLD2.X * k, WORLD2.Y * k)
		local b = 1 + 0.06 * (0.5 - 0.5 * math.cos(os.clock() * math.pi * 2 * 1.1)) -- (Buy swells up to 6% and back)
		starterBuy.Size = UDim2.fromOffset(STARTER_BUY.X * b, STARTER_BUY.Y * b)
		starterBurst.Rotation = os.clock() * 25 % 360
		local left = starterLeft()
		ribbon.Text = string.format("%dm %02ds", left // 60, left % 60)
		if left <= 0 then
			layout()
		end
	end
end)
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- Match the Worlds menu's frosted glass and temporarily hide every other HUD.
local blur = Instance.new("BlurEffect", camera)
blur.Name, blur.Size, blur.Enabled = "ShopHaze", 0, false
local tint = Instance.new("ColorCorrectionEffect", camera)
tint.Name, tint.Enabled = "ShopHaze", false
local hazeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function haze(on)
	local k = if on then 1 else 0
	blur.Enabled, tint.Enabled = true, true
	TweenService:Create(blur, hazeTween, { Size = 14 * k }):Play()
	local tween =
		TweenService:Create(tint, hazeTween, { Brightness = 0.06 * k, Contrast = -0.15 * k, Saturation = -0.35 * k })
	tween.Completed:Connect(function()
		if not open then
			blur.Enabled, tint.Enabled = false, false
		end
	end)
	tween:Play()
end
local hidden, holdHidden, oldCutscene = {}, nil, nil
local function hideOthers(on)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if on then
		oldCutscene = player:GetAttribute("Cutscene")
		player:SetAttribute("Cutscene", true)
		local function hideAll()
			for _, g in player.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g ~= gui and g.Enabled then
					hidden[g] = true
					g.Enabled = false
				end
			end
		end
		hideAll()
		holdHidden = RunService.RenderStepped:Connect(hideAll)
	else
		player:SetAttribute("Cutscene", oldCutscene)
		for g in hidden do
			if g.Parent then
				g.Enabled = true
			end
		end
		table.clear(hidden)
	end
end
local function setScale(scale)
	pop.Scale = scale
end
function Shop.open()
	if open then
		return
	end
	open = true
	if Shop.onToggle then
		Shop.onToggle(true)
	end
	hideOthers(true)
	scroll.CanvasPosition = Vector2.zero
	gui.Enabled = true
	haze(true)
	ModalPop.open(setScale)
	for _, name in { "FunnelStep", "Telemetry" } do
		local event = ReplicatedStorage:FindFirstChild(name)
		if event then
			event:FireServer(if name == "FunnelStep" then "shop" else "shopOpened")
		end
	end
	Gamepad.openMenu("Shop", {
		close = Shop.close,
		group = scroll,
		select = function()
			for _, card in cards do
				if card.Selectable then
					return card
				end
			end
		end,
	})
end
function Shop.close(instant)
	if not open then
		return
	end
	open = false
	Gamepad.closeMenu("Shop")
	hideOthers(false)
	if Shop.onToggle then
		Shop.onToggle(false)
	end
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end, instant)
end
function Shop.toggle()
	if open then
		Shop.close()
	else
		Shop.open()
	end
end

-- A purchase without enough gold: the smallest cash pack that covers the shortfall
-- `amount`, else the biggest there is.
function Shop.buyGoldFor(amount)
	if amount <= 0 then
		return
	end
	local packs = {}
	for _, offer in Config.Shop.CashPacks do
		if offered(offer) then
			table.insert(packs, offer)
		end
	end
	table.sort(packs, function(a, b)
		return a.Gold < b.Gold
	end)
	for i, offer in packs do
		if offer.Gold >= amount or i == #packs then
			buyShop:FireServer(offer.Key)
			return
		end
	end
end

function Shop.isOpen()
	return open
end

return Shop
