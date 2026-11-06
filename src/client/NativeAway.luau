-- The While You Were Away popup in the native UI (Config.NativeUi, QM Nov 6): Fight to Steal an
-- Egg's Offline Cash popup (its client/OfflineCash, 1:1 in look): a lime header with its shine
-- and "Offline Cash", "You earned:" over the amount on a cash stack, a sunburst slowly turning
-- behind it, green Claim and the pink Robux button with its "4x" badge (Config.AwayBoost).
-- Client/Away still opens, closes and wires it (ClaimAway, BuyShop "Away4x"); this is its look.
--
--   NativeAway.build(screenGui) -> away
--     away.claim, away.boost (buttons), away.setAmount(text, boostText), away.setScale(s)

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local Ui = require(script.Parent.Ui)
local UiFx = require(script.Parent.UiFx)

local NativeAway = {}

local fig, label = HudKit.fig, HudKit.label
local W, H = 1500, 1120 -- the whole popup (QM's Figma px)
local HEADER = 230
local BUTTON_W, BUTTON_H, BUTTON_Y = 650, 230, 830
local STACK = 560
local BURST = 1000
local PILE_Y = 610
local SPIN = 12 -- degrees a second
local ICON_OUTLINE = 3
local GREEN_TOP = Color3.fromHex("d8ff3a")
local GREEN_BOTTOM = Color3.fromHex("1fd31f")
local PINK_TOP = Color3.fromHex("ff6bf6")
local PINK_BOTTOM = Color3.fromHex("b100ff")

local function gradient(parent, top, bottom)
	local g = Ui.make(parent, "Shade", "UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(top, bottom)
	return g
end

function NativeAway.build(screen)
	local away = {}
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

	local gui = Ui.make(root, "OfflineCash", "Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(fig(W), fig(H)),
		ZIndex = 12,
	})
	local pop = Ui.make(gui, "Pop", "UIScale")
	function away.setScale(s)
		pop.Scale = s * UiFx.fitScale(gui)
	end

	-- the dark studded panel, and the lime header over its top
	HudKit.back(gui, "Panel", {
		Name = "Panel",
		Position = UDim2.fromOffset(0, fig(HEADER - 20)),
		Size = UDim2.fromOffset(fig(W), fig(H - HEADER + 20)),
	})
	local header = HudKit.back(gui, "LimeHeader", {
		Name = "Header",
		Size = UDim2.fromOffset(fig(W), fig(HEADER)),
		ZIndex = 2,
	})
	local shine = Ui.make(header, "Shine", "CanvasGroup", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 0.7,
		ZIndex = 2,
	})
	for i, st in { { 0.6, 0.08 }, { 0.71, 0.03 } } do
		local stripe = Instance.new("Frame")
		stripe.Name = "Stripe" .. i
		stripe.BackgroundColor3 = Color3.new(1, 1, 1)
		stripe.BorderSizePixel = 0
		stripe.AnchorPoint = Vector2.new(0.5, 0.5)
		stripe.Position = UDim2.fromScale(st[1], 0.5)
		stripe.Size = UDim2.new(st[2], 0, 2, 0)
		stripe.Rotation = 22
		stripe.Parent = shine
	end
	for _, t in { { "TitleShadow", 8, HudKit.BLACK, 3 }, { "Title", 0, Color3.new(1, 1, 1), 4 } } do
		label(gui, t[1], {
			Text = "Offline Cash",
			TextSize = fig(120),
			TextColor3 = t[3],
			Position = UDim2.fromOffset(fig(60), fig(40 + t[2])),
			Size = UDim2.fromOffset(fig(1100), fig(150)),
			ZIndex = t[4],
		})
	end

	-- "You earned:", the burst, the stack, the amount
	label(gui, "Earned", {
		Text = "You earned:",
		FontFace = HudKit.ITALIC,
		TextSize = fig(110),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(W / 2), fig(HEADER + 110)),
		Size = UDim2.fromOffset(fig(1200), fig(140)),
		ZIndex = 6,
	})
	local clip = Ui.make(gui, "Burst", "Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(fig(8), fig(HEADER)),
		Size = UDim2.fromOffset(fig(W - 16), fig(H - HEADER - 8)),
		ZIndex = 2,
	})
	local burst = HudKit.art(clip, "Sunburst", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(W / 2 - 8), fig(PILE_Y - HEADER)),
		Size = UDim2.fromOffset(fig(BURST), fig(BURST)),
		ImageColor3 = Color3.fromHex("b8ff6a"),
		ImageTransparency = 0.55,
		ZIndex = 2,
	})
	HudKit.art(gui, "CashStack", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(W / 2), fig(PILE_Y + 20)),
		Size = UDim2.fromOffset(fig(STACK), fig(STACK)),
		ZIndex = 4,
	})
	local amount = label(gui, "Amount", {
		Text = "$0",
		TextSize = fig(210),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(W / 2), fig(PILE_Y + 10)),
		Size = UDim2.fromOffset(fig(1300), fig(250)),
		ZIndex = 6,
	})
	amount.Outline.Thickness = fig(16)
	gradient(amount, GREEN_TOP, GREEN_BOTTOM)

	-- Claim, and the Robux 4x
	local claim = HudKit.button(gui, "Claim", BUTTON_W, BUTTON_H, {
		Position = UDim2.fromOffset(fig(60), fig(BUTTON_Y)),
		ZIndex = 6,
	}, "GreenEdged")
	label(claim, "Text", {
		Text = "Claim",
		TextSize = fig(130),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	})
	local boost = HudKit.button(gui, "Boost", BUTTON_W, BUTTON_H, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(fig(W - 60), fig(BUTTON_Y)),
		ZIndex = 6,
	}, "PinkEdged")
	local price = Ui.make(boost, "Price", "Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, fig(130)),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 7,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, fig(18))
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = price
	local holder = Ui.make(price, "Robux", "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(110), fig(120)),
		LayoutOrder = 1,
		ZIndex = 7,
	})
	local icon = HudKit.art(holder, "RobuxIcon", { Size = UDim2.fromScale(1, 1), ZIndex = 8 })
	HudKit.outlineArt(icon, ICON_OUTLINE)
	local priceText = label(price, "Text", {
		Text = "9",
		TextSize = fig(120),
		Size = UDim2.fromOffset(0, fig(130)),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = 8,
	})
	local badge = label(gui, "Multiplier", {
		Text = Config.AwayBoost.Multiplier .. "x",
		FontFace = HudKit.ITALIC,
		TextSize = fig(130),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(fig(W - 110), fig(BUTTON_Y - 10)),
		Size = UDim2.fromOffset(fig(220), fig(150)),
		Rotation = -14,
		ZIndex = 9,
	})
	gradient(badge, PINK_TOP, PINK_BOTTOM)

	-- the 4x's price: the product's own
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, Config.AwayBoost.ProductId, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			priceText.Text = tostring(info.PriceInRobux)
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if screen.Enabled then
			burst.Rotation = (burst.Rotation + SPIN * dt) % 360
		end
	end)

	away.claim, away.boost = claim, boost
	function away.setAmount(text)
		amount.Text = text
	end
	return away
end

return NativeAway
