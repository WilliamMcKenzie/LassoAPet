-- The Shop in the native UI (Config.NativeUi, QM Nov 6): Fight to Steal an Egg's Shop (its
-- client/Shop, 1:1 in look): the popup with the lime header, "Shop" and the red X, and under
-- it one scrolling list of its cards (gradient, studs, the white inner glow, a sunburst behind
-- the picture, the green Robux price button):
--   the Starter Pack   while it's on offer (Client/Shop's ten minutes): its three pets, World 2,
--                      the time left, Buy (the pass: BuyPass)
--   ~Halloween Egg~    its odds (each pet's headshot and chance) and x1, x3, x10, x50
--   ~Cash Packs~       three cards: a pile of cash, how much, the price
-- Prices are read live from Roblox (the products' own), so they're always what's charged.
-- Client/Shop keeps opening and closing it (its haze, hiding the rest of the UI, telemetry,
-- the auto pop-up) and shows this in place of its art.
--
--   NativeShop.build(screenGui, handlers) -> shop
--     handlers: close(), buy(key), buyPass(key), starterLeft() -> seconds, restricted() -> bool
--     shop.setScale(s)  shop.refresh()  shop.list  shop.cards

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local HudImages = require(script.Parent.HudImages)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local PetFaces = require(script.Parent.PetFaces)
local Ui = require(script.Parent.Ui)

local NativeShop = {}

local player = Players.LocalPlayer
local fig, art, label, button = HudKit.fig, HudKit.art, HudKit.label, HudKit.button

-- QM's Figma px (the reference's)
local WIDTH = 2177 -- the list's width: three cards and two gaps
local GAP = 22
local CARD_H = 635
local THIRD = (WIDTH - 2 * GAP) / 3
local EDGE = 47 -- the buttons' inset from the card's sides
local BUTTONS_Y = 443
local BURST = 620
local PILE_Y = 229
local ICON_OUTLINE = 3
local PICTURES = { Stack = "CashStack", StackFlip = "CashStackFlip", Bills = "CashBills" }
-- the cash packs' piles (the reference's arrangements, smallest to biggest)
local PILES = {
	{ { "Stack", 0, 229, 256 } },
	{ { "Stack", -111, 175, 219 }, { "StackFlip", 136, 191, 219 }, { "Stack", 13, 229, 294 } },
	{
		{ "Stack", -111, 194, 219 }, { "Stack", 245, 247, 219 }, { "StackFlip", 154, 138, 219 },
		{ "StackFlip", -240, 266, 219 }, { "Bills", 16, 229, 294 },
	},
}

-- a product's or pass's price in Robux, read once from Roblox (fallback: Config's)
local prices = {}
local function price(id, isPass, fallback, set)
	if prices[id] then
		set(prices[id])
		return
	end
	set(fallback)
	task.spawn(function()
		local ok, product = pcall(
			MarketplaceService.GetProductInfo,
			MarketplaceService,
			id,
			if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product
		)
		if ok and product and product.PriceInRobux then
			prices[id] = product.PriceInRobux
			set(product.PriceInRobux)
		end
	end)
end

local function gradient(parent, colours)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex(colours[1])),
		ColorSequenceKeypoint.new(0.495, Color3.fromHex(colours[2])),
		ColorSequenceKeypoint.new(1, Color3.fromHex(colours[3])),
	})
	g.Parent = parent
end

-- a section's title: gradient text over its 8px drop shadow
local function heading(list, name, text, colours, order)
	local frame = Ui.make(list, name, "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(WIDTH), fig(150)),
		LayoutOrder = order,
	})
	label(frame, "Shadow", {
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(120),
		TextColor3 = HudKit.BLACK,
		Position = UDim2.fromOffset(0, fig(8)),
		Size = UDim2.fromScale(1, 1),
	})
	local title = label(frame, "Title", {
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(120),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})
	gradient(title, colours)
	return frame
end

-- the inset white glow every card has
local function glow(back)
	local g = Ui.make(back, "Glow", "Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(fig(5 + 16), fig(5 + 16)),
		Size = UDim2.new(1, -2 * fig(5 + 16), 1, -2 * fig(5 + 16)),
	})
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.5
	stroke.Thickness = fig(16)
	stroke.Parent = g
end

-- the sunburst behind a picture, centred at x, y (x from the card's middle), clipped to the card
local function sunburst(card, x, y, size)
	local clip = Ui.make(card, "Burst", "Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(fig(5), fig(5)),
		Size = UDim2.new(1, -fig(10), 1, -fig(10)),
		ZIndex = 2,
	})
	return art(clip, "Sunburst", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, fig(x), 0, fig(y - 5)),
		Size = UDim2.fromOffset(fig(size), fig(size)),
		ImageTransparency = 0.15,
		ZIndex = 2,
	})
end

local function card(parent, name, look, width, height, order)
	local c = Ui.make(parent, name, "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(width), fig(height)),
		LayoutOrder = order or 0,
	})
	glow(HudKit.back(c, look, {}))
	return c
end

-- the green Robux price button: its Robux icon and price (prefix: "x10 " before them)
local function buyButton(parent, name, w, props, prefix)
	local buy = button(parent, name, w, 160, props, "GreenEdged")
	local row = Ui.make(buy, "Price", "Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, fig(98)),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 6,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, fig(13))
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	if prefix then
		label(row, "Count", {
			Text = prefix,
			TextSize = fig(80),
			Size = UDim2.fromOffset(0, fig(98)),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 0,
			ZIndex = 7,
		})
	end
	local holder = Ui.make(row, "Robux", "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(85), fig(93)),
		LayoutOrder = 1,
		ZIndex = 6,
	})
	local icon = art(holder, "RobuxIcon", { Size = UDim2.fromScale(1, 1), ZIndex = 7 })
	HudKit.outlineArt(icon, ICON_OUTLINE)
	local text = label(row, "Text", {
		Text = "",
		TextSize = fig(80),
		Size = UDim2.fromOffset(0, fig(98)),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = 7,
	})
	return buy, text
end

local function row(list, name, order)
	local r = Ui.make(list, name, "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(WIDTH), fig(CARD_H)),
		LayoutOrder = order,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, fig(GAP))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = r
	return r
end

function NativeShop.build(screen, handlers)
	local shop = { cards = {} }
	local root = Ui.make(screen, "NativeRoot", "Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
	local fit = Ui.make(root, "Fit", "UIScale")
	local function resize()
		local h = screen.AbsoluteSize.Y
		if h < 1 then
			h = workspace.CurrentCamera.ViewportSize.Y
		end
		fit.Scale = NativeHud.scaleFor(h)
		root.Size = UDim2.fromScale(1 / fit.Scale, 1 / fit.Scale)
	end
	resize()
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)

	local gui, close = HudKit.popup(root, "Shop", "Shop", "LimeHeader")
	gui.Visible = true -- (its ScreenGui comes and goes: Client/Shop)
	local pop = gui:FindFirstChild("Pop")
	close.Activated:Connect(handlers.close)
	local UiFx = require(script.Parent.UiFx)
	function shop.setScale(s)
		pop.Scale = s * UiFx.fitScale(gui)
	end

	local list = Ui.make(gui, "List", "ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(fig(45), fig(290)),
		Size = UDim2.fromOffset(fig(2268 - 90) + 4, fig(1370 - 290 - 30)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
		ZIndex = 2,
	})
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, fig(GAP))
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, fig(16)), UDim.new(0, fig(30))
	pad.Parent = list
	shop.list = list

	-- ---- the Starter Pack ----
	local starterPass
	for _, pass in Config.Passes do
		if pass.Key == "StarterPack" then
			starterPass = pass
		end
	end
	local starter = card(list, "StarterPack", "GrowthCard", WIDTH, CARD_H, 1)
	local burst = sunburst(starter, 420 - WIDTH / 2, 260, 700)
	for i, kind in (Config.StarterPack and Config.StarterPack.Pets) or {} do
		art(starter, "Pet" .. i, {
			Image = PetFaces.HEADSHOTS[kind] or "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, fig(420 - WIDTH / 2 + (i - 2) * 250), 0, fig(if i == 2 then 230 else 290)),
			Size = UDim2.fromOffset(fig(if i == 2 then 380 else 300), fig(if i == 2 then 380 else 300)),
			ZIndex = if i == 2 then 4 else 3,
		})
	end
	label(starter, "PackName", {
		Text = "Starter Pack",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(120),
		Position = UDim2.fromOffset(fig(900), fig(40)),
		Size = UDim2.new(1, -fig(960), 0, fig(140)),
		ZIndex = 4,
	})
	label(starter, "Description", {
		RichText = true,
		Text = '3 rare pets + <font color="#7CFF4D">World 2!</font>',
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		TextSize = fig(80),
		Position = UDim2.fromOffset(fig(900), fig(190)),
		Size = UDim2.new(1, -fig(960), 0, fig(110)),
		ZIndex = 4,
	})
	local timer = label(starter, "Timer", {
		Text = "10m 00s",
		FontFace = HudKit.ITALIC,
		TextColor3 = Color3.fromHex("ffe700"),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(70),
		Position = UDim2.fromOffset(fig(900), fig(305)),
		Size = UDim2.new(1, -fig(960), 0, fig(90)),
		ZIndex = 4,
	})
	local starterBuy, starterPrice = buyButton(starter, "Buy", 900, {
		Position = UDim2.fromOffset(fig(1100), fig(BUTTONS_Y)),
		ZIndex = 5,
	})
	if starterPass then
		price(starterPass.Id, true, starterPass.Price, function(r)
			starterPrice.Text = tostring(r)
		end)
	end
	starterBuy.Activated:Connect(function()
		handlers.buyPass("StarterPack")
	end)
	table.insert(shop.cards, starterBuy)

	-- ---- the Halloween Egg ----
	heading(list, "EggHeading", "~Halloween Egg~", { "ff9d00", "ffd000", "ff5e00" }, 2)
	local egg = card(list, "HalloweenEgg", "DamageCard", WIDTH, CARD_H, 3)
	local odds = {}
	for kind, chance in Config.Shop.HalloweenOdds or {} do
		table.insert(odds, { kind = kind, chance = chance })
	end
	table.sort(odds, function(a, b)
		return a.chance > b.chance
	end)
	local slotW = (WIDTH - 2 * EDGE) / math.max(#odds, 1)
	for i, o in odds do
		local x = EDGE + (i - 0.5) * slotW - WIDTH / 2
		if i == #odds then
			sunburst(egg, x, 200, 420)
		end
		art(egg, "Pet" .. i, {
			Image = PetFaces.HEADSHOTS[o.kind] or "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, fig(x), 0, fig(200)),
			Size = UDim2.fromOffset(fig(300), fig(300)),
			ZIndex = 3,
		})
		label(egg, "Chance" .. i, {
			Text = o.chance .. "%",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(70),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, fig(x), 0, fig(345)),
			Size = UDim2.fromOffset(fig(300), fig(80)),
			ZIndex = 4,
		})
	end
	local packs = Config.Shop.HalloweenPacks or {}
	local packW = (WIDTH - 2 * EDGE - (#packs - 1) * GAP) / math.max(#packs, 1)
	local eggButtons = {}
	for i, offer in packs do
		local b, text = buyButton(egg, "Buy" .. offer.Count, packW, {
			Position = UDim2.fromOffset(fig(EDGE + (i - 1) * (packW + GAP)), fig(BUTTONS_Y)),
			ZIndex = 5,
		}, "x" .. offer.Count)
		if offer.ProductId ~= 0 then
			price(offer.ProductId, false, offer.Price, function(r)
				text.Text = tostring(r)
			end)
		end
		b.Activated:Connect(function()
			if offer.ProductId ~= 0 and not handlers.restricted() then
				handlers.buy(offer.Key)
			end
		end)
		table.insert(eggButtons, b)
		table.insert(shop.cards, b)
	end
	local note = label(egg, "Availability", {
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		Position = UDim2.fromOffset(fig(40), fig(CARD_H - 60)),
		Size = UDim2.new(1, -fig(80), 0, fig(46)),
		ZIndex = 6,
	})
	task.spawn(function()
		local restricted = handlers.restricted()
		for i, b in eggButtons do
			b.Visible = not restricted and packs[i].ProductId ~= 0
		end
		note.Text = if restricted then "Paid random items unavailable in your region" else ""
	end)

	-- ---- the cash packs ----
	heading(list, "CashHeading", "~Cash Packs~", { "61ff00", "b9ff00", "57ff00" }, 4)
	local cashRow = row(list, "CashRow", 5)
	for i, offer in Config.Shop.CashPacks do
		local c = card(cashRow, offer.Key, "CashCard", THIRD, CARD_H, i)
		sunburst(c, 0, PILE_Y, BURST)
		local icons = Ui.make(c, "Icons", "Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = 3,
		})
		for k, p in PILES[math.min(i, #PILES)] do
			art(icons, "Icon" .. k, {
				Image = HudImages[PICTURES[p[1]]] or "",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(fig(p[2]), fig(p[3])),
				Size = UDim2.fromOffset(fig(p[4]), fig(p[4])),
				ZIndex = 3 + k,
			})
		end
		label(c, "Amount", {
			Text = "$" .. Config.short(offer.Gold):upper(),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = fig(75),
			Position = UDim2.fromOffset(0, fig(285)),
			Size = UDim2.new(1, 0, 0, fig(91)),
			ZIndex = 20,
		})
		local b, text = buyButton(c, "Buy", THIRD - 2 * EDGE, {
			Position = UDim2.fromOffset(fig(EDGE), fig(BUTTONS_Y)),
			ZIndex = 5,
		})
		if offer.ProductId ~= 0 then
			price(offer.ProductId, false, offer.Price or 0, function(r)
				text.Text = tostring(r)
			end)
		end
		b.Activated:Connect(function()
			handlers.buy(offer.Key)
		end)
		table.insert(shop.cards, b)
	end

	-- the Starter Pack's card only while it's on offer; its time counts down
	function shop.refresh()
		local left = handlers.starterLeft()
		starter.Visible = left > 0 and not player:GetAttribute("PassStarterPack")
		starterBuy.Selectable = starter.Visible
		timer.Text = string.format("Ends in %dm %02ds", left // 60, left % 60)
	end
	shop.refresh()
	RunService.Heartbeat:Connect(function()
		if screen.Enabled then
			burst.Rotation = os.clock() * 25 % 360
			shop.refresh()
		end
	end)
	return shop
end

return NativeShop
