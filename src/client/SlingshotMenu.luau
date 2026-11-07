-- The Slingshot's menu (QM, Nov 6: in place of the top bar): hold E at your slingshot and
-- pick where it flings you. Fight to Steal an Egg's Weapon Shop 1:1 (its client/WeaponShop:
-- the orange-headed popup, HudKit.popup, and its 729 x 991 cards in a row that scrolls
-- sideways), one card per biome (Config.Biomes), its back in the biome's colours:
--   its name, Unlocked / Locked under it, over its picture (Config.Biomes[i].Picture, a render
--   of it, filling the card), how hard it is (Config.BiomeDifficulty: the Weapon Shop's DPS bar), and at the bottom
--   GO!       unlocked: flings you there (onPick)
--   $Price    the next one to unlock, for its UnlockCost (Server/Slingshot's UnlockBiome: in
--             order only), beside its Robux price when it has a developer product
--             (Config.Biomes[i].RobuxProduct = { ProductId, Price }: Server/Slingshot's
--             GrantBiome, from Shop.server's ProcessReceipt)
--
--   SlingshotMenu.open(onPick)   -- onPick(biome index) when you pick an unlocked one
--   SlingshotMenu.open(nil, i)   -- (the Goal panel's Buy!, QM Nov 7) scrolled so biome i's card
--                                -- is in the middle, the clicking cursor on its buy button
--   SlingshotMenu.open(onPick, nil, true) -- (holding E on a pet, QM Nov 7: not at the slingshot,
--                                -- so walking away doesn't close it)
--   SlingshotMenu.atSlingshot()  -- open from the slingshot itself (Client/SlingshotLaunch
--                                -- closes it when you walk away; not one from the Goal panel)
--   SlingshotMenu.close()
--   SlingshotMenu.isOpen()

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HudKit = require(script.Parent.HudKit)
local NativeHud = require(script.Parent.NativeHud)
local UiFx = require(script.Parent.UiFx)
local Ui = require(script.Parent.Ui)

local SlingshotMenu = {}

local player = Players.LocalPlayer
local fig, art, label, button = HudKit.fig, HudKit.art, HudKit.label, HudKit.button
local NAME_STROKE = Color3.fromRGB(70, 70, 70) -- (the Weapon Shop's)
local ICON_OUTLINE = 3
local FAIL_SHOW = 1.2 -- seconds a failed buy's message shows on the button
local UNLOCKED_COLOR = Color3.fromHex("7CFF4D")
local LOCKED_COLOR = Color3.fromHex("ff5a5a")

local RunService = game:GetService("RunService")
local CURSOR_CLICK = 0.12 -- how much the cursor shrinks as it "clicks" (Hud's upgrade hand's look)

local gui, cards, onPick, fromSlingshot
local cursor, cursorScale, cursorOn -- the clicking cursor (the Goal panel's Buy!), on the card i = cursorOn
local made = {} -- [biome index] = its card's parts

local function price(n)
	return "$" .. Config.short(n or 0)
end

local function level()
	return player:GetAttribute("PenLevel") or 1
end

-- a card (the Weapon Shop's: 729 x 991 Figma px)
local function makeCard(parent, i, biome)
	local ground = biome.GroundColors or { Color3.fromRGB(120, 200, 90), Color3.fromRGB(100, 170, 70) }
	local wall = biome.WallColors or ground
	local card = Ui.make(parent, "Card" .. i, "Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(fig(729), fig(991)),
		LayoutOrder = i,
	})
	local back = HudKit.back(card, "Card", {})
	-- (its rarity's gradient on the Weapon Shop's: here the biome's ground down to its wall)
	local fill = back:FindFirstChild("Fill")
	if fill then
		fill.Color = ColorSequence.new(ground[2] or ground[1], wall[1])
		fill.Rotation = 90
	end
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
	local picture = Ui.make(card, "Picture", "ImageLabel", {
		BackgroundTransparency = 1,
		Image = biome.Picture or "",
		ScaleType = Enum.ScaleType.Crop,
		-- (the card's whole background, inside its black edge: QM, Nov 7; the name, bar and
		-- buttons over it)
		Position = UDim2.fromOffset(fig(5), fig(5)),
		Size = UDim2.new(1, -2 * fig(5), 1, -2 * fig(5)),
		ZIndex = 2,
	})
	if not picture:FindFirstChildOfClass("UICorner") then
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, fig(8))
		round.Parent = picture
	end
	local name = label(card, "BiomeName", {
		Text = biome.DisplayName or biome.Name,
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
	local status = label(card, "Status", {
		Text = "Locked",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(70),
		Position = UDim2.fromOffset(fig(24), fig(143)),
		Size = UDim2.fromOffset(fig(674), fig(85)),
		ZIndex = 3,
	})
	-- the dark bar (the Weapon Shop's DPS): how hard it is (Config.BiomeDifficulty, QM)
	local ladder = Config.BiomeDifficulty or {}
	local difficulty = ladder[math.min(i, #ladder)]
	local bar = HudKit.back(card, "Dark", {
		Name = "Info",
		Position = UDim2.fromOffset(fig(24), fig(631)),
		Size = UDim2.fromOffset(fig(674), fig(128)),
		ZIndex = 3,
	})
	label(bar, "Text", {
		RichText = true,
		Text = if difficulty then difficulty[1] .. " " .. difficulty[2] else "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(95),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
	})
	-- the buttons: GO! (whole width), or the cash price and the Robux price
	local go = button(card, "ShopGo", 674, 160, { Position = UDim2.fromOffset(fig(24), fig(799)), ZIndex = 4 }, "GreenEdged")
	label(go, "Text", {
		Text = "GO!",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(80),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	local robuxProduct = biome.RobuxProduct
	local buyW = if robuxProduct then 413 else 674
	local buy = button(card, "ShopBuy", buyW, 160, { Position = UDim2.fromOffset(fig(24), fig(799)), ZIndex = 4 }, "GreenEdged")
	label(buy, "Text", {
		Text = price(Config.unlockCost(player, i)),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = fig(80),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
	})
	local robux
	if robuxProduct then
		robux = button(card, "ShopRobux", 213, 160, { Position = UDim2.fromOffset(fig(479), fig(799)), ZIndex = 4 }, "PinkEdged")
		local icon = art(robux, "RobuxIcon", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, fig(12), 0.5, 0),
			Size = UDim2.fromOffset(fig(85), fig(93)),
			ZIndex = 5,
		})
		HudKit.outlineArt(icon, ICON_OUTLINE)
		label(robux, "Text", {
			Text = tostring(robuxProduct.Price or ""),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, fig(110), 0.5, 0),
			Size = UDim2.fromOffset(fig(100), fig(98)),
			TextSize = fig(80),
			ZIndex = 5,
		})
	end
	for _, b in { go, buy, robux } do
		UiFx.button(b)
	end
	return { card = card, status = status, go = go, buy = buy, robux = robux }
end

local function refresh()
	for i, c in made do
		local open = i <= level()
		c.status.Text = if open then "Unlocked" else "Locked"
		c.status.TextColor3 = if open then UNLOCKED_COLOR else LOCKED_COLOR
		c.go.Visible = open
		c.buy.Visible = not open
		if c.robux then
			c.robux.Visible = not open
		end
		if not open and not c.buy:GetAttribute("Failing") then
			c.buy.Text.Text = price(Config.unlockCost(player, i))
		end
	end
	if cursor and cursorOn and cursorOn <= level() then -- (bought: the cursor goes)
		cursorOn = nil
		cursor.Visible = false
	end
end

-- the clicking hand (assets/ui/TapHand.png, as on Hud's Upgrade) on card i's buy button
local function pointAt(i)
	local c = made[i]
	if not c then
		return
	end
	if not cursor then
		cursor = Instance.new("ImageLabel")
		cursor.Name = "Cursor"
		cursor.BackgroundTransparency = 1
		cursor.Image = "rbxassetid://134865745295413" -- assets/ui/TapHand.png (QM's; the old TutorialCursor art is a grey placeholder while Config.UiArt is off)
		cursor.AnchorPoint = Vector2.new(0.365, 0.03) -- its tip, so it clicks about it
		cursor.Position = UDim2.fromScale(0.55, 0.3) -- (low enough to read, high enough not to be cut off by the row)
		cursor.SizeConstraint = Enum.SizeConstraint.RelativeYY
		cursor.Size = UDim2.fromScale(0.9 * 488 / 610, 0.9) -- (TapHand.png is 488 x 610)
		cursor.ZIndex = 9
		cursorScale = Instance.new("UIScale")
		cursorScale.Parent = cursor
		RunService.RenderStepped:Connect(function()
			if cursor.Visible then
				-- (a click a second: quick press in, slower let go)
				local t = os.clock() % 1
				local press = if t < 0.15 then t / 0.15 elseif t < 0.5 then 1 - (t - 0.15) / 0.35 else 0
				cursorScale.Scale = 1 - CURSOR_CLICK * press
			end
		end)
	end
	cursor.Parent = c.buy
	cursorOn = i
	cursor.Visible = true
end

-- scrolls the row so card i is in the middle (as far as the row goes)
local function centre(i)
	local cardW, gap = fig(729), fig(44)
	local window = cards.Size.X.Offset
	local count = #Config.Biomes
	local canvas = 4 + count * cardW + (count - 1) * gap
	local mid = 4 + (i - 1) * (cardW + gap) + cardW / 2
	local x = math.clamp(mid - window / 2, 0, math.max(canvas - window, 0))
	cards.CanvasPosition = Vector2.new(x, 0)
end

local function fail(c, i, why)
	UiFx.shake(c.buy)
	c.buy:SetAttribute("Failing", true)
	c.buy.Text.Text = why
	task.delay(FAIL_SHOW, function()
		c.buy:SetAttribute("Failing", nil)
		c.buy.Text.Text = price(Config.unlockCost(player, i))
	end)
end

local function build()
	if gui then
		return
	end
	local root = NativeHud.popupRoot()
	local close
	gui, close = HudKit.popup(root, "SlingshotMenu", "Slingshot", "Header")
	UiFx.menu(gui, SlingshotMenu.close) -- (one menu at a time: client/UiFx)
	close.Activated:Connect(SlingshotMenu.close)

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

	local unlock = ReplicatedStorage:WaitForChild("UnlockBiome", 10)
	for i, biome in Config.Biomes do
		local c = makeCard(cards, i, biome)
		made[i] = c
		c.go.Activated:Connect(function()
			if i <= level() then
				SlingshotMenu.close()
				if onPick then
					onPick(i)
				end
			end
		end)
		c.buy.Activated:Connect(function()
			if c.buy:GetAttribute("Failing") then
				return
			end
			if i > level() + 1 then
				return fail(c, i, "Unlock " .. (Config.Biomes[i - 1].DisplayName or Config.Biomes[i - 1].Name) .. "!")
			end
			if (player:GetAttribute("Gold") or 0) < Config.unlockCost(player, i) then
				return fail(c, i, "Need cash!")
			end
			local ok, bought = false, false
			if unlock then
				ok, bought = pcall(unlock.InvokeServer, unlock, i)
			end
			if ok and bought then
				UiFx.play("Buy")
				refresh()
			else
				fail(c, i, "Can't buy")
			end
		end)
		if c.robux then
			c.robux.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, biome.RobuxProduct.ProductId)
			end)
		end
	end
	-- the real Robux prices (regional pricing: the product's own), then the cards again
	task.spawn(function()
		for i, biome in Config.Biomes do
			local product = biome.RobuxProduct
			if product and product.ProductId and made[i].robux then
				local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, product.ProductId, Enum.InfoType.Product)
				if ok and info and info.PriceInRobux then
					made[i].robux.Text.Text = tostring(info.PriceInRobux)
				end
			end
		end
	end)
	player:GetAttributeChangedSignal("Gold"):Connect(refresh)
	player:GetAttributeChangedSignal("PenLevel"):Connect(refresh)
	player:GetAttributeChangedSignal("Reborn"):Connect(refresh) -- (prices x2: Config.Luck)
end

function SlingshotMenu.open(callback, focus, away)
	build()
	onPick = callback
	fromSlingshot = callback ~= nil and not away
	if cursor then
		cursor.Visible = false
	end
	cursorOn = nil
	if focus and made[focus] then
		centre(focus)
		task.defer(centre, focus) -- (again once a first build's row has its canvas size)
		if focus > level() then
			pointAt(focus)
		end
	end
	refresh()
	NativeHud.haze("SlingshotMenu", true)
	UiFx.popIn(gui)
end

function SlingshotMenu.close()
	if gui and UiFx.isOpen(gui) then
		UiFx.popOut(gui)
	end
	NativeHud.haze("SlingshotMenu", false)
end

function SlingshotMenu.isOpen()
	return gui ~= nil and UiFx.isOpen(gui)
end

function SlingshotMenu.atSlingshot()
	return SlingshotMenu.isOpen() and fromSlingshot == true
end

return SlingshotMenu
