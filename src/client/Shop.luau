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
scroll.Position, scroll.Size = UDim2.fromOffset(50, 143), UDim2.fromOffset(1132, 779)
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- (all of it fits now: it only scrolls on a short screen)
scroll.ScrollingDirection, scroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 0
scroll.ScrollBarImageColor3 = Color3.fromRGB(230, 230, 230)
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Parent = panel
-- The banner across the panel, at its art's shape; its buy buttons where QM's design has them
-- (x in the art's 1192 pixels: 285, 444, 599, 754; tops at 347, under each one's "x1" label).
local EGG_W = 1132
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
	pressable(button)
	button.Activated:Connect(function()
		if open then
			buyShop:FireServer(offer.Key, "shop")
		end
	end)
	table.insert(cards, button)
end
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
