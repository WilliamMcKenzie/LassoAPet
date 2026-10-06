-- The Robux shop (QM, Oct 4; Config.Shop): the gold icon at home opens it. QM's
-- panel with five cards laid out like QM's mockup: Giant Horse, Spawn Loong and the
-- two gold packs in a 2x2 grid, and the tall Legend Egg card on the right, whose ?
-- flips it between the mystery egg and its odds. Each card's picture, name and
-- Robux price are baked into QM's art; clicking a card buys it (BuyShop,
-- Shop.server), which asks Roblox for the Robux. An offer whose product doesn't
-- exist yet only shows in Studio, where it's free. It behaves like the roll menu
-- and the animal dictionary: no dark backdrop, the HUD's left buttons stay on top
-- and clickable, and clicking anywhere off the panel closes it.
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
-- QM's art (assets/ui/Shop*.png). The cards' prices are baked in: keep them in step
-- with the products' prices on the Creator Dashboard.
local PANEL = { id = "rbxassetid://105155399825774", size = Vector2.new(2888, 1694) } -- ShopPanel.png ("Shop" on its top edge)
local ODDS_BUTTON = "rbxassetid://83654143211576" -- ShopOddsButton.png (the green ?)
local CARDS = {
	-- [offer Key] = the card's art, and its column and row in the grid (the
	-- Legend Egg spans both rows)
	GiantHorse = { id = "rbxassetid://73979296990982", column = 0, row = 0 }, -- ShopGiantHorse.png
	SpawnLoong = { id = "rbxassetid://70887174133121", column = 1, row = 0 }, -- ShopSpawnLoong.png
	Gold1 = { id = "rbxassetid://136220197688301", column = 0, row = 1 }, -- ShopGold100k.png
	Gold4 = { id = "rbxassetid://103982023506783", column = 1, row = 1 }, -- ShopGold1M.png
	Legendary = { id = "rbxassetid://125476338322601", odds = "rbxassetid://102515912144773", column = 2, row = 0, tall = true }, -- ShopLegendaryEgg.png / ShopLegendaryEggOdds.png
}
local PANEL_WIDTH = 930 -- about 70% of the screen, as in QM's mockup
local CARD_WIDTH = 265
local SMALL_HEIGHT = CARD_WIDTH * 666 / 848 -- the small cards' art is 848x666
local TALL_HEIGHT = CARD_WIDTH * 1362 / 848 -- the Legend Egg's is 848x1362
local GAP = 30 -- between columns
local ODDS_SIZE = 58

local player = Players.LocalPlayer
local open = false
local buyShop = ReplicatedStorage:WaitForChild("BuyShop")

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

function Shop.hasOffers()
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
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_WIDTH * PANEL.size.Y / PANEL.size.X)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

-- The cards, centred in the panel under its title.
local grid = Instance.new("Frame")
grid.Name = "Cards"
grid.BackgroundTransparency = 1
grid.AnchorPoint = Vector2.new(0.5, 0.5)
grid.Position = UDim2.fromScale(0.5, 0.54)
grid.Size = UDim2.fromOffset(3 * CARD_WIDTH + 2 * GAP, TALL_HEIGHT)
grid.Parent = panel

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
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	local height = if spot.tall then TALL_HEIGHT else SMALL_HEIGHT
	local top = if spot.row == 0 then 0 else TALL_HEIGHT - SMALL_HEIGHT
	card.Position = UDim2.fromOffset(spot.column * (CARD_WIDTH + GAP) + CARD_WIDTH / 2, top + height / 2)
	card.Size = UDim2.fromOffset(CARD_WIDTH, height)
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
	flip.Image = ODDS_BUTTON
	flip.AnchorPoint = Vector2.new(0.5, 0.5)
	flip.Position = UDim2.fromScale(0.88, 0.055) -- on the card's top-right corner, right of its title
	flip.Size = UDim2.fromOffset(ODDS_SIZE, ODDS_SIZE)
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
	if not over(panel, at) then
		Shop.close()
	end
end)
backdrop.Parent = gui
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- It pops in and out like the other menus (ModalPop), hiding once it has shrunk away.
local function setScale(scale)
	panelScale.Scale = scale
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
