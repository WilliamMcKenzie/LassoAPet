-- The Robux shop (QM, Oct 4; Config.Shop): the gold icon at home opens it. QM's
-- panel with five cards laid out like QM's mockup (Oct 11): the tall Legend Egg card
-- on the left, whose ? flips it between the mystery egg and its odds, then Giant
-- Horse, Spawn Loong and the two cash packs in a 2x2 grid; an X on the corner closes it. Each card's picture, name and
-- Robux price are baked into QM's art; clicking a card buys it (BuyShop,
-- Shop.server), which asks Roblox for the Robux. An offer whose product doesn't
-- exist yet only shows in Studio, where it's free. It behaves like the roll menu
-- and the animal dictionary: no dark backdrop, the HUD's left buttons stay on top
-- and clickable, and clicking anywhere off the panel closes it.
-- Under the panel, a row of the game passes (Config.Passes; QM, Oct 7): clicking
-- one buys it (BuyPass, Server/Passes), and an owned one says OWNED. They're
-- placeholder gold buttons until QM's art is in PASS_ART.
--
--   Shop.open() / Shop.toggle() / Shop.close(instant) / Shop.isOpen()  -- instant: no closing animation
--   Shop.hasOffers() / Shop.hasGold()   -- anything to show (live: products made)
--   Shop.buyGoldFor(amount)             -- asks to buy the smallest gold pack giving that much
--   Shop.onToggle = function(open)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)

local Shop = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
-- QM's art (assets/ui/Shop*.png), laid out in pixels of the panel picture (the cards
-- are drawn at that size, as in QM's mockup). The cards' prices are baked in: keep
-- them in step with the products' prices on the Creator Dashboard.
local PANEL = { id = "rbxassetid://103831602991183", size = Vector2.new(1444, 858) } -- ShopPanel.png ("Shop" on its top edge)
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Index's X)
local SMALL, TALL = Vector2.new(424, 333), Vector2.new(448, 681) -- the cards' art
local CARDS = {
	-- [offer Key] = the card's art, and its top left on the panel
	Legendary = { id = "rbxassetid://99393989394598", odds = "rbxassetid://127128286637741", at = Vector2.new(44, 133), tall = true }, -- ShopLegendaryEgg.png / ShopLegendaryEggOdds.png
	GiantHorse = { id = "rbxassetid://100105531661393", at = Vector2.new(512, 133) }, -- ShopGiantHorse.png
	SpawnLoong = { id = "rbxassetid://104044722461852", at = Vector2.new(975, 133) }, -- ShopSpawnLoong.png
	Gold1 = { id = "rbxassetid://95428452126143", at = Vector2.new(512, 481) }, -- ShopGold100k.png
	Gold4 = { id = "rbxassetid://99027271786746", at = Vector2.new(975, 481) }, -- ShopGold1M.png
}
-- [pass Key] = QM's card art for it ("" = the placeholder button with its name and price)
local PASS_ART = { Speed = "", DoubleGold = "", GiantPets = "", StarterPack = "" }
local PASS_HEIGHT = 96
local PANEL_WIDTH = 800 -- on the HUD's reference screen: about 60% of it, nearer the Index's size (QM, Oct 11)
local FIT = PANEL_WIDTH / PANEL.size.X
local GAP = 30 -- between the passes
local ODDS = { at = Vector2.new(0.895, 0.088), size = 0.21 } -- the ? drawn on the Legend Egg's card (of its width)

local player = Players.LocalPlayer
local open = false
local buyShop = ReplicatedStorage:WaitForChild("BuyShop")
local buyPass = ReplicatedStorage:WaitForChild("BuyPass")

-- Paid random items (the Legend Egg; egg rolls, as gold can be bought) are left
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

local offers = {} -- [Key] = offer
for _, list in { Config.Shop.Gold, Config.Shop.Specials } do
	for _, offer in list do
		offers[offer.Key] = offer
	end
end

-- Only the offers with a card count (the other gold packs and Nuke All aren't on
-- QM's menu, though they can still be bought).
function Shop.hasGold()
	for key, offer in offers do
		if offer.Gold and CARDS[key] and offered(offer) then
			return true
		end
	end
	return false
end

local function passOffered(pass)
	return pass.Id ~= 0 or RunService:IsStudio()
end

function Shop.hasOffers()
	if not Config.ShopOn then
		return false -- (hidden for now: QM, Oct 15)
	end
	for _, pass in Config.Passes do
		if passOffered(pass) then
			return true
		end
	end
	for key, offer in offers do
		if CARDS[key] and offered(offer) then
			return true
		end
	end
	return false
end

-- Shrinks a little while pressed.
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

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD (its left buttons stay on top), over the roll menu (-2)
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

local panel = Instance.new("ImageLabel")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Image = PANEL.id
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.52) -- a little below centre, as in the mockup
panel.Size = UDim2.fromOffset(PANEL.size.X, PANEL.size.Y)
local panelScale = Instance.new("UIScale")
panelScale.Scale = FIT
panelScale.Parent = panel
panel.Parent = root

-- The cards, where QM's mockup has them.
local grid = Instance.new("Frame")
grid.Name = "Cards"
grid.BackgroundTransparency = 1
grid.Size = UDim2.fromScale(1, 1)
grid.Parent = panel

-- The X, on the panel's top right corner (QM's mockup).
local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.fromOffset(PANEL.size.X - 26, 71)
closeButton.Size = UDim2.fromOffset(88, 88)
closeButton.ZIndex = 3
closeButton.Selectable = false -- (a controller's B closes it)
pressable(closeButton)
closeButton.Activated:Connect(function()
	Shop.close()
end)
closeButton.Parent = panel

local legendCard, legendOdds
local cards = {} -- every card, for a controller's first pick
for key, spot in CARDS do
	local offer = offers[key]
	if not offer then
		continue
	end
	local card = Instance.new("ImageButton")
	card.Name = key
	card.BackgroundTransparency = 1
	card.AutoButtonColor = false
	card.Image = spot.id
	local size = if spot.tall then TALL else SMALL
	card.AnchorPoint = Vector2.new(0.5, 0.5) -- (so it shrinks into its middle when pressed)
	card.Position = UDim2.fromOffset(spot.at.X + size.X / 2, spot.at.Y + size.Y / 2)
	card.Size = UDim2.fromOffset(size.X, size.Y)
	card.Visible = offered(offer)
	pressable(card)
	card.Activated:Connect(function()
		if open then -- (not while it shrinks away)
			buyShop:FireServer(key)
		end
	end)
	card.Parent = grid
	table.insert(cards, card)
	if key == "Legendary" then
		legendCard = card
	end
end

-- The Legend Egg is a paid random item: its ? flips the card to its odds and back
-- (QM's odds art, Config.Shop.LegendaryOdds), and it's left out where the player's
-- policy restricts paid random items (PolicyService).
if legendCard then
	local spot = CARDS.Legendary
	legendCard.Visible = false -- until the policy check says it may show
	local flip = Instance.new("ImageButton")
	flip.Name = "Odds"
	flip.BackgroundTransparency = 1
	flip.AutoButtonColor = false
	flip.Image = "" -- (the ? is drawn on the card: this is where it's clicked)
	flip.AnchorPoint = Vector2.new(0.5, 0.5)
	flip.Position = UDim2.fromScale(ODDS.at.X, ODDS.at.Y)
	flip.Size = UDim2.fromScale(ODDS.size, ODDS.size)
	flip.SizeConstraint = Enum.SizeConstraint.RelativeXX
	flip.ZIndex = 2
	pressable(flip)
	local function flipOdds()
		Sounds.play("book_flip")
		legendOdds = not legendOdds
		legendCard.Image = if legendOdds then spot.odds else spot.id
	end
	flip.Activated:Connect(flipOdds)
	flip.Selectable = false -- (a controller's Y flips it: Shop.open)
	Gamepad.hint(flip, Enum.KeyCode.ButtonY, Vector2.new(-0.45, 0.5), 40)
	flip.Parent = legendCard
	Shop.flipLegendOdds = function()
		if legendCard.Visible then
			flipOdds()
		end
	end
	task.spawn(function()
		legendCard.Visible = offered(offers.Legendary) and not Shop.randomRestricted()
	end)
end

-- The game passes, in a row under the panel (inside the cards' group, so a
-- controller's D-pad reaches them).
local passRow = Instance.new("Frame")
passRow.Name = "Passes"
passRow.BackgroundTransparency = 1
passRow.AnchorPoint = Vector2.new(0.5, 0)
passRow.Position = UDim2.new(0.5, 0, 1, 54) -- just under the panel
passRow.Size = UDim2.fromOffset(PANEL.size.X, PASS_HEIGHT)
local passLayout = Instance.new("UIListLayout")
passLayout.FillDirection = Enum.FillDirection.Horizontal
passLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
passLayout.SortOrder = Enum.SortOrder.LayoutOrder
passLayout.Padding = UDim.new(0, GAP)
passLayout.Parent = passRow
passRow.Parent = grid
passRow.Visible = false -- (QM, Oct 8: nothing under the panel; the passes still sell through PassPopups)

local function outlined(label)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
end

for i, pass in Config.Passes do
	local card = Instance.new("ImageButton")
	card.Name = pass.Key
	card.LayoutOrder = i
	card.AutoButtonColor = false
	card.Size = UDim2.fromOffset((PANEL.size.X - (#Config.Passes - 1) * GAP) / #Config.Passes, PASS_HEIGHT)
	card.Visible = passOffered(pass)
	local art = PASS_ART[pass.Key] or ""
	card.Image = art
	card.BackgroundTransparency = if art ~= "" then 1 else 0
	card.BackgroundColor3 = Color3.fromRGB(255, 196, 40)
	local price = Instance.new("TextLabel")
	price.Name = "Price"
	price.AnchorPoint = Vector2.new(0.5, 1)
	price.Position = UDim2.fromScale(0.5, 0.92)
	price.Size = UDim2.fromScale(0.9, 0.38)
	outlined(price)
	price.Parent = card
	if art == "" then
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
		local edge = Instance.new("UIStroke")
		edge.Thickness = 3
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = card
		local name = Instance.new("TextLabel")
		name.Name = "PassName"
		name.AnchorPoint = Vector2.new(0.5, 0)
		name.Position = UDim2.fromScale(0.5, 0.08)
		name.Size = UDim2.fromScale(0.9, 0.46)
		name.Text = pass.Name
		outlined(name)
		name.Parent = card
	else
		price.Visible = false -- (the art has its price; OWNED still shows)
	end
	local function owned()
		local has = player:GetAttribute("Pass" .. pass.Key) == true
		price.Text = if has then "OWNED" else "\u{E002} " .. pass.Price
		price.Visible = has or art == ""
		card.ImageTransparency = if has then 0.4 else 0
	end
	player:GetAttributeChangedSignal("Pass" .. pass.Key):Connect(owned)
	owned()
	pressable(card)
	card.Activated:Connect(function()
		if open and not player:GetAttribute("Pass" .. pass.Key) then
			buyPass:FireServer(pass.Key)
		end
	end)
	card.Parent = passRow -- (not in cards: a controller starts on the panel's cards)
end

-- Clicking anywhere off the panel closes it. No dark backdrop (QM).
local function over(object, at)
	local min, size = object.AbsolutePosition, object.AbsoluteSize
	return at.X >= min.X and at.Y >= min.Y and at.X <= min.X + size.X and at.Y <= min.Y + size.Y
end
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false -- (never a controller's pick)
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if not over(panel, at) and not over(closeButton, at) and not (passRow.Visible and over(passRow, at)) then
		Shop.close()
	end
end)
backdrop.Parent = gui
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- It pops in and out like the other menus (ModalPop), hiding once it has shrunk away.
local function setScale(scale)
	panelScale.Scale = scale * FIT
end

function Shop.open()
	if open then
		return
	end
	open = true
	local funnelStep = ReplicatedStorage:FindFirstChild("FunnelStep") -- (Funnel.server, analytics)
	if funnelStep then
		funnelStep:FireServer("shop")
	end
	local telemetry = ReplicatedStorage:FindFirstChild("Telemetry") -- (/stats: the shop's open rate)
	if telemetry then
		telemetry:FireServer("shopOpened")
	end
	if legendCard and legendOdds then -- the mystery egg first, every time
		legendOdds = false
		legendCard.Image = CARDS.Legendary.id
	end
	gui.Enabled = true
	ModalPop.open(setScale)
	-- A controller: the D-pad picks a card and A buys it, Y shows the Legend Egg's
	-- odds and back, B closes.
	local keys = {}
	if Shop.flipLegendOdds then
		keys[Enum.KeyCode.ButtonY] = Shop.flipLegendOdds
	end
	Gamepad.openMenu("Shop", {
		close = Shop.close,
		keys = keys,
		group = grid,
		select = function()
			table.sort(cards, function(a, b)
				return a.Position.X.Offset + a.Position.Y.Offset < b.Position.X.Offset + b.Position.Y.Offset
			end)
			for _, card in cards do
				if card.Visible then
					return card
				end
			end
			return nil
		end,
	})
	if Shop.onToggle then
		Shop.onToggle(true)
	end
end

function Shop.close(instant)
	if not open then
		return
	end
	open = false
	Gamepad.closeMenu("Shop")
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end, instant)
	if Shop.onToggle then
		Shop.onToggle(false)
	end
end

function Shop.toggle()
	if open then
		Shop.close()
	else
		Shop.open()
	end
end

-- ROLL without the gold for it (Hud, QM): the smallest gold pack that covers
-- `amount`, else the biggest there is.
function Shop.buyGoldFor(amount)
	local packs = {}
	for _, offer in Config.Shop.Gold do
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
