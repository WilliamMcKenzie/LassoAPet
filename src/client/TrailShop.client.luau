-- The Trails Shop (QM, Nov 7): Fight to Steal an Egg's Weapon Shop 1:1 (its client/WeaponShop),
-- with trails for weapons and a blue header (his reference's Trails Shop). Opened at its stand
-- (Server/TrailShop: its Open prompt, or walking onto its ring). Under the header a dark panel
-- with a row of cards, one per trail (Config.TrailBars, in Config.TrailShop.Order), scrolling
-- sideways when they don't fit. Each card: the trail's name, its rarity (in its rarity's
-- colours), QM's trail guy recoloured to the trail, its speed (x every ride:
-- Config.trailSpeed), and at the bottom
--   Equipped  it's the one you wear (Config.trailIndex)
--   Equip     you own it: EquipTrail
--   $Price    buy it with cash (BuyTrail; buying equips it), beside the Robux price (its
--             developer product, ProductId: Shop.server's receipt hands it over)
-- The card's back is studded and coloured by its rarity (Config.NativeUi.Rarities; from
-- Mythic up it turns, with a sheen sweeping across, as the Weapon Shop's).
-- The Godly trail needs every animal in the Index first (Shared/Trails).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Trails = require(ReplicatedStorage.Shared:WaitForChild("Trails"))
local HudImages = require(script.Parent:WaitForChild("HudImages"))
local HudKit = require(script.Parent:WaitForChild("HudKit"))
local NativeHud = require(script.Parent:WaitForChild("NativeHud"))
local RarityLook = require(script.Parent:WaitForChild("RarityLook"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local UiFx = require(script.Parent:WaitForChild("UiFx"))

local player = Players.LocalPlayer
local fig, art, label, button = HudKit.fig, HudKit.art, HudKit.label, HudKit.button
local SPEED_COLOR = "#7CFF4D" -- (the reference's green x2)
local NAME_STROKE = Color3.fromRGB(70, 70, 70)
local RARITY = Config.NativeUi.Rarities
local SPIN = 45 -- degrees a second a moving card's back turns
local SHEEN = 0.45 -- transparency at the middle of the sheen's band
local ICON_OUTLINE = 3
local FAIL_SHOW = 1.2 -- seconds a failed buy's message shows on the button
local CFG = Config.TrailShop

-- the popup's blue header (QM's reference), on HudKit's header (its studs, bevel and shine)
HudKit.LOOKS.BlueHeader = HudKit.LOOKS.BlueHeader or {
	across = { Color3.fromHex("1e8fff"), Color3.fromHex("5ad8ff"), Color3.fromHex("1e8fff") },
	bevel = { 0.5, 0.5, Color3.fromHex("b8f4ff"), Color3.fromHex("00307a"), 12 },
	tile = { 223.5, 0.8 },
	outline = 8,
}

local gui, cards
local made = {} -- { { card, i } }
local moving = {} -- { { back's Fill, sheen's UIGradient } }

local function price(n)
	return "$" .. Config.short(n or 0)
end

local function speedText(x)
	return string.format('<font color="%s">x%s</font> Speed', SPEED_COLOR, (string.format("%.2f", x):gsub("%.?0+$", "")))
end

-- QM's trail guy (white, black outlined) in the trail's colours: one colour multiplies it;
-- banded trails (Rainbow, Galactic, Godly) run their bands across it
local function tint(picture, bar)
	local colors = bar.Colors
	local old = picture:FindFirstChildOfClass("UIGradient")
	if not colors or (RARITY[bar.Rarity] or {}).move then
		local bands = colors or { -- (the Rainbow Trail's)
			Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 235, 70),
			Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 150, 255), Color3.fromRGB(170, 90, 240),
		}
		local keys = {}
		for k, c in bands do
			table.insert(keys, ColorSequenceKeypoint.new((k - 1) / (#bands - 1), c))
		end
		local g = old or Instance.new("UIGradient")
		g.Color = ColorSequence.new(keys)
		g.Rotation = 35
		g.Parent = picture
		picture.ImageColor3 = Color3.new(1, 1, 1)
	else
		if old then
			old:Destroy()
		end
		picture.ImageColor3 = colors[2] or colors[1]
	end
end

-- a card (the Weapon Shop's: 729 x 991 Figma px)
local function makeCard(parent, slot, i)
	local bar = Config.TrailBars[i]
	local look = RARITY[bar.Rarity] or RARITY.Common
	local card = Ui.make(parent, "Card" .. slot, "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(729), fig(991)),
		LayoutOrder = slot,
	})
	local back = HudKit.back(card, "Card", {})
	-- (Figma: an inset white glow, 16px, on every rarity but Common)
	local glow = Ui.make(back, "Glow", "Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(fig(5 + 16), fig(5 + 16)),
		Size = UDim2.new(1, -2 * fig(5 + 16), 1, -2 * fig(5 + 16)),
	})
	if not glow:FindFirstChildOfClass("UIStroke") then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.5
		stroke.Thickness = fig(16)
		stroke.Parent = glow
	end
	glow.Visible = look.top ~= nil
	-- the back in its rarity's colours (bottom colour up to the top one, which it reaches
	-- `at` of the way up); from Mythic up it turns, with a sheen sweeping across
	if look.top and back:FindFirstChild("Fill") then
		back.Fill.Color = if look.at < 1
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, look.top),
				ColorSequenceKeypoint.new(1 - look.at, look.top),
				ColorSequenceKeypoint.new(1, look.bottom),
			})
			else ColorSequence.new(look.top, look.bottom)
		back.Fill.Rotation = 90
		if look.move and not back:FindFirstChild("Sheen") then
			local sheen = Instance.new("Frame")
			sheen.Name = "Sheen"
			sheen.BackgroundColor3 = Color3.new(1, 1, 1)
			sheen.BorderSizePixel = 0
			sheen.Size = UDim2.fromScale(1, 1)
			local corner = back:FindFirstChildOfClass("UICorner")
			if corner then
				corner:Clone().Parent = sheen
			end
			local band = Instance.new("UIGradient")
			band.Rotation = 60
			band.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 1),
				NumberSequenceKeypoint.new(0.5, SHEEN),
				NumberSequenceKeypoint.new(0.6, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			band.Offset = Vector2.new(-1.5, 0)
			band.Parent = sheen
			sheen.Parent = back
			table.insert(moving, { back.Fill, band })
		end
	end
	local picture = Ui.make(card, "Picture", "ImageLabel", {
		BackgroundTransparency = 1,
		Image = HudImages.TrailGuy or "",
		ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(fig(109), fig(237)),
		Size = UDim2.fromOffset(fig(512), fig(512)),
		ZIndex = 2,
	})
	tint(picture, bar)
	local name = label(card, "TrailName", {
		Text = bar.Name .. " Trail",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		Position = UDim2.fromOffset(fig(24), fig(15)),
		Size = UDim2.fromOffset(fig(674), fig(120)),
		ZIndex = 3,
	})
	name.Outline.Color = NAME_STROKE
	if not name:FindFirstChildOfClass("UITextSizeConstraint") then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = fig(120)
		limit.Parent = name
	end
	local rarity = label(card, "Rarity", {
		Text = bar.Rarity,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(70),
		Position = UDim2.fromOffset(fig(24), fig(143)),
		Size = UDim2.fromOffset(fig(674), fig(85)),
		ZIndex = 3,
	})
	RarityLook.paint(rarity, bar.Rarity, rarity.Outline)
	-- the speed bar (the Weapon Shop's DPS)
	local speed = HudKit.back(card, "Dark", {
		Name = "ShopSpeed",
		Position = UDim2.fromOffset(fig(24), fig(631)),
		Size = UDim2.fromOffset(fig(674), fig(128)),
		ZIndex = 3,
	})
	label(speed, "Speed", {
		RichText = true,
		Text = speedText(bar.Speed or 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(95),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
	})
	-- the buttons: Equip (whole width) or the cash price and the Robux price
	local equip = button(card, "ShopEquip", 674, 160, { Position = UDim2.fromOffset(fig(24), fig(799)), ZIndex = 4 }, "GreenEdged")
	label(equip, "Text", {
		Text = "Equip",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(80),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	local buy = button(card, "ShopBuy", 413, 160, { Position = UDim2.fromOffset(fig(24), fig(799)), ZIndex = 4 }, "GreenEdged")
	label(buy, "Text", {
		Text = price(bar.Price),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	if not buy.Text:FindFirstChildOfClass("UITextSizeConstraint") then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = fig(80)
		limit.Parent = buy.Text
	end
	local robux = button(card, "ShopRobux", 213, 160, { Position = UDim2.fromOffset(fig(479), fig(799)), ZIndex = 4 }, "PinkEdged")
	local icon = art(robux, "RobuxIcon", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, fig(12), 0.5, 0),
		Size = UDim2.fromOffset(fig(85), fig(93)),
		ZIndex = 5,
	})
	HudKit.outlineArt(icon, ICON_OUTLINE)
	label(robux, "Text", {
		Text = tostring(bar.Robux or ""),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, fig(110), 0.5, 0),
		Size = UDim2.fromOffset(fig(100), fig(98)),
		TextSize = fig(80),
		ZIndex = 5,
	})
	return card
end

local function refresh()
	local wearing = Config.trailIndex(player)
	for _, m in made do
		local card, i = m[1], m[2]
		local mine = Config.ownsTrail(player, i)
		card.ShopEquip.Visible = mine
		card.ShopEquip.Text.Text = if wearing == i then "Equipped" else "Equip"
		card.ShopBuy.Visible = not mine
		card.ShopRobux.Visible = not mine
		if not mine and not card.ShopBuy:GetAttribute("Failing") then
			card.ShopBuy.Text.Text = price(Config.TrailBars[i].Price)
		end
	end
end

local function fail(card, i, why)
	UiFx.shake(card.ShopBuy)
	card.ShopBuy:SetAttribute("Failing", true)
	card.ShopBuy.Text.Text = why
	task.delay(FAIL_SHOW, function()
		card.ShopBuy:SetAttribute("Failing", nil)
		card.ShopBuy.Text.Text = price(Config.TrailBars[i].Price)
	end)
end

local TrailShop = {}

local function build()
	if gui then
		return
	end
	local close
	gui, close = HudKit.popup(NativeHud.popupRoot(), "TrailShop", "Trails Shop", "BlueHeader")
	UiFx.menu(gui, TrailShop.close) -- (one menu at a time: client/UiFx)
	close.Activated:Connect(TrailShop.close)

	-- (the Weapon Shop's row, scrolling sideways when the cards don't fit)
	cards = Ui.make(gui, "Cards", "ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(fig(46) - 4, fig(330) - 4),
		Size = UDim2.fromOffset(fig(2268 - 92) + 8, fig(991) + 8 + 10),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(150, 150, 150),
		ZIndex = 2,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingTop = UDim.new(0, 4), UDim.new(0, 4)
	pad.Parent = cards
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, fig(44))
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = cards

	local buyRemote = ReplicatedStorage:WaitForChild("BuyTrail", 10)
	local equipRemote = ReplicatedStorage:WaitForChild("EquipTrail", 10)
	for slot, i in CFG.Order do
		local bar = Config.TrailBars[i]
		local card = makeCard(cards, slot, i)
		table.insert(made, { card, i })
		card.ShopEquip.Activated:Connect(function()
			if equipRemote and Config.trailIndex(player) ~= i then
				UiFx.play("Equip")
				equipRemote:FireServer(i)
			end
		end)
		card.ShopBuy.Activated:Connect(function()
			if card.ShopBuy:GetAttribute("Failing") then
				return
			end
			if bar.AllAnimals and not Trails.hasAllAnimals(player) then
				return fail(card, i, "Need all animals!")
			end
			if (player:GetAttribute("Gold") or 0) < bar.Price then
				return fail(card, i, "Need cash!")
			end
			local ok, bought = false, false
			if buyRemote then
				ok, bought = pcall(buyRemote.InvokeServer, buyRemote, i)
			end
			if ok and bought then
				UiFx.play("Buy")
				refresh()
			else
				fail(card, i, "Can't buy")
			end
		end)
		card.ShopRobux.Activated:Connect(function()
			if bar.AllAnimals and not Trails.hasAllAnimals(player) then
				return fail(card, i, "Need all animals!")
			end
			if (bar.ProductId or 0) ~= 0 then
				MarketplaceService:PromptProductPurchase(player, bar.ProductId)
			else
				UiFx.shake(card.ShopRobux) -- (no developer product yet: Config.TrailBars ProductId)
			end
		end)
	end
	-- the real Robux prices (regional pricing: the product's own), then the cards again
	task.spawn(function()
		for _, m in made do
			local id = Config.TrailBars[m[2]].ProductId
			if id and id ~= 0 then
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Product)
				if ok and info and info.PriceInRobux then
					m[1].ShopRobux.Text.Text = tostring(info.PriceInRobux)
				end
			end
		end
	end)
	for _, name in { "TrailsOwned", "TrailOn", "FinishTrail", "RainbowTrail", "Gold" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end

	-- the moving cards, while the shop's open: each back's gradient turns and its sheen
	-- sweeps across in step with the band on its rarity (RarityLook)
	RunService.RenderStepped:Connect(function()
		if not gui.Visible or #moving == 0 then
			return
		end
		local turn = (90 + os.clock() * SPIN) % 360
		local sweep = RarityLook.sweep()
		for _, m in moving do
			m[1].Rotation = turn
			m[2].Offset = Vector2.new(sweep * 1.5, 0)
		end
	end)
end

function TrailShop.isOpen()
	return gui ~= nil and UiFx.isOpen(gui)
end

function TrailShop.open()
	build()
	refresh()
	UiFx.popIn(gui)
end

function TrailShop.close()
	if gui and UiFx.isOpen(gui) then
		UiFx.popOut(gui)
	end
end

-- ---- the stand: its Open prompt, and stepping onto its ring ------------------------------

local stand = workspace:WaitForChild("TrailShop", 60)
if not stand then
	return
end
local prompt = stand:FindFirstChild("OpenPrompt", true)
if prompt then
	prompt.Triggered:Connect(function()
		if TrailShop.isOpen() then
			TrailShop.close()
		else
			TrailShop.open()
		end
	end)
end
-- (on the ring opens it once; step off and on again to open it again)
local disc = stand:WaitForChild("Ring", 10) and stand.Ring:FindFirstChild("Disc")
local inside = false
RunService.Heartbeat:Connect(function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (disc and hrp and humanoid) or humanoid.Sit or humanoid.PlatformStand then
		inside = false -- (riding or flying past doesn't open it)
		return
	end
	local away = (hrp.Position - disc.Position) * Vector3.new(1, 0, 1)
	local now = away.Magnitude < disc.Size.Y / 2 and math.abs(hrp.Position.Y - disc.Position.Y) < 8
	if now and not inside and not TrailShop.isOpen() then
		TrailShop.open()
	end
	inside = now
end)
