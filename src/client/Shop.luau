-- The Robux shop (QM, Oct 4; Config.Shop): the gold icon at home opens it. Gold
-- offers on top, then the specials (Giant Horse, Nuke All, Legendary Pet). Pressing
-- ROLL with less than Config.Shop.TopUpBelow gold opens just the gold offers as a
-- top-up, with ROLL under them when you can pay. Buying asks the server (BuyShop,
-- Shop.server), which asks Roblox for the Robux; an offer whose product doesn't
-- exist yet only shows in Studio, where it's free. Clicking off the panel closes it.
-- Placeholder art drawn in code until QM's is in.
--
--   Shop.open(topUp) / Shop.toggle() / Shop.close() / Shop.isOpen()
--   Shop.hasOffers() / Shop.hasGold()   -- anything to show (live: products made)
--   Shop.onToggle = function(open, topUp)
--   Shop.onRoll = function()            -- ROLL on the top-up was pressed

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local PetFaces = require(script.Parent.PetFaces)

local Shop = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(92, 214, 72)
local GREY = Color3.fromRGB(150, 150, 150)
local PANEL_COLOR = Color3.fromRGB(255, 196, 64)
local CARD_COLOR = Color3.fromRGB(255, 240, 200)
-- Placeholder pictures until QM draws the cards ("" = an emoji in its place).
local ICONS = {
	gold = "rbxassetid://99312860837685", -- Hud's coin
	GiantHorse = PetFaces.HEADSHOTS.Horse or "",
	Nuke = "", -- 💥
	Legendary = "rbxassetid://85066893166855", -- Hud's Unicorn egg render
}
local EMOJI = { Nuke = "💥" }

local player = Players.LocalPlayer
local open, topUp = false, false
local buyShop = ReplicatedStorage:WaitForChild("BuyShop")

-- Paid random items (the Legendary Pet; egg rolls, as gold can be bought) are left
-- out where the player's policy restricts them. Unknown counts as restricted.
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
	return offer.ProductId ~= 0 or RunService:IsStudio()
end

function Shop.hasGold()
	for _, offer in Config.Shop.Gold do
		if offered(offer) then
			return true
		end
	end
	return false
end

function Shop.hasOffers()
	if Shop.hasGold() then
		return true
	end
	for _, offer in Config.Shop.Specials do
		if offered(offer) then
			return true
		end
	end
	return false
end

-- Money as Hud shows it: "$1M", "$25M".
local function money(amount)
	for _, s in { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "k" } } do
		if amount >= s[1] then
			return "$" .. (string.format("%.1f", amount / s[1]):gsub("%.0$", "")) .. s[2]
		end
	end
	return "$" .. amount
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function label(parent, text, textSize, size, position)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = WHITE
	l.Text = text
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- A green text button that shrinks a little while pressed.
local function pushButton(parent, text, size, position, onActivated)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = GREEN
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Size = size
	b.Position = position
	b.Text = ""
	corner(b, 14)
	label(b, text, 34, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	local scale = Instance.new("UIScale")
	scale.Parent = b
	local press = TweenInfo.new(0.08)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.93 }):Play()
	end)
	for _, event in { b.MouseButton1Up, b.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
	b.Activated:Connect(onActivated)
	b.Parent = parent
	return b
end

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10 -- over the roll menu, for the top-up
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

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.BackgroundColor3 = PANEL_COLOR
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(820, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
corner(panel, 28)
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 56)
padding.PaddingBottom = UDim.new(0, 28)
padding.Parent = panel
local rows = Instance.new("UIListLayout")
rows.HorizontalAlignment = Enum.HorizontalAlignment.Center
rows.SortOrder = Enum.SortOrder.LayoutOrder
rows.Padding = UDim.new(0, 18)
rows.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root
-- The title over the panel's top edge (outside the list layout's reach).
local titleHolder = Instance.new("Frame")
titleHolder.BackgroundTransparency = 1
titleHolder.AnchorPoint = Vector2.new(0.5, 0.5)
titleHolder.Position = UDim2.fromScale(0.5, 0.5)
titleHolder.Size = UDim2.fromOffset(820, 0)
titleHolder.Parent = root
local title = label(titleHolder, "SHOP", 72, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0))

local function row(order, height)
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.Size = UDim2.fromOffset(780, height)
	r.LayoutOrder = order
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 16)
	list.Parent = r
	r.Parent = panel
	return r
end

-- One offer: its picture, its name, and its Robux price as the buy button.
local function card(parent, order, width, height, icon, emoji, name, offer)
	local c = Instance.new("Frame")
	c.BackgroundColor3 = CARD_COLOR
	c.Size = UDim2.fromOffset(width, height)
	c.LayoutOrder = order
	c.Visible = offered(offer)
	corner(c, 20)
	local picture = height - 120
	if icon ~= "" then
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.ScaleType = Enum.ScaleType.Fit
		i.AnchorPoint = Vector2.new(0.5, 0)
		i.Position = UDim2.new(0.5, 0, 0, 10)
		i.Size = UDim2.fromOffset(picture, picture)
		i.Image = icon
		i.Parent = c
	else
		local e = label(c, emoji or "?", picture * 0.8, UDim2.fromOffset(picture, picture), UDim2.new(0.5, 0, 0, 10 + picture / 2))
		e.UIStroke.Enabled = false
	end
	label(c, name, 32, UDim2.fromOffset(width, 36), UDim2.new(0.5, 0, 1, -82))
	pushButton(c, "R$ " .. offer.Price, UDim2.fromOffset(width - 28, 52), UDim2.new(0.5, 0, 1, -36), function()
		buyShop:FireServer(offer.Key)
	end)
	c.Parent = parent
	return c
end

local goldRow = row(1, 230)
for i, offer in Config.Shop.Gold do
	card(goldRow, i, 180, 230, ICONS.gold, nil, money(offer.Gold), offer)
end
local specialRow = row(2, 250)
-- The Legendary Pet is a paid random item: its odds are on its card, and it's
-- left out where the player's policy restricts paid random items (PolicyService).
for i, offer in Config.Shop.Specials do
	local c = card(specialRow, i, 240, 250, ICONS[offer.Key] or "", EMOJI[offer.Key], offer.Name, offer)
	if offer.Key == "Legendary" then
		local pool, total = {}, 0
		for _, weight in Config.Gacha.Pool.Legendary do
			total += weight
		end
		for kind, weight in Config.Gacha.Pool.Legendary do
			table.insert(pool, string.format("%s %d%%", kind, math.round(weight / total * 100)))
		end
		table.sort(pool)
		local odds = label(c, table.concat(pool, "  "), 16, UDim2.fromOffset(224, 40), UDim2.new(0.5, 0, 0, 24))
		odds.TextWrapped = true
		odds.ZIndex = 2
		c.Visible = false -- until the policy check says it may show
		task.spawn(function()
			c.Visible = offered(offer) and not Shop.randomRestricted()
		end)
	end
end
-- The top-up's way on to the roll you asked for, when you can pay for it.
local rollRow = row(3, 70)
local rollButton = pushButton(rollRow, "ROLL " .. money(Config.Gacha.Price), UDim2.fromOffset(300, 64), UDim2.new(), function()
	if Shop.onRoll then
		Shop.close()
		Shop.onRoll()
	end
end)

local function refresh()
	rollButton.BackgroundColor3 = if (player:GetAttribute("Gold") or 0) >= Config.Gacha.Price then GREEN else GREY
	rollRow.Visible = topUp and (player:GetAttribute("Gold") or 0) >= Config.Gacha.Price
end
player:GetAttributeChangedSignal("Gold"):Connect(refresh)

-- The title sits on the panel's top edge, wherever its height ends up.
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	titleHolder.Size = UDim2.fromOffset(820, panel.AbsoluteSize.Y / rootScale.Scale)
end)

-- Clicking anywhere off the panel closes it.
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.6
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local at = Vector2.new(input.Position.X, input.Position.Y)
	local min, size = panel.AbsolutePosition, panel.AbsoluteSize
	if at.X < min.X or at.Y < min.Y or at.X > min.X + size.X or at.Y > min.Y + size.Y then
		Shop.close()
	end
end)
backdrop.Parent = gui
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- topUp: just the gold offers, titled as a top-up, with ROLL under them.
function Shop.open(asTopUp)
	if open then
		return
	end
	open, topUp = true, asTopUp == true
	title.Text = if topUp then "TOP UP GOLD!" else "SHOP"
	specialRow.Visible = not topUp
	refresh()
	gui.Enabled = true
	panelScale.Scale = 0.85
	TweenService:Create(panelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if Shop.onToggle then
		Shop.onToggle(true, topUp)
	end
end

function Shop.close()
	if not open then
		return
	end
	open = false
	gui.Enabled = false
	if Shop.onToggle then
		Shop.onToggle(false, topUp)
	end
end

function Shop.toggle()
	if open then
		Shop.close()
	else
		Shop.open(false)
	end
end

function Shop.isOpen()
	return open
end

return Shop
