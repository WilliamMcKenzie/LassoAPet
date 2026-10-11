-- The base's UI (QM, Oct 9: the new look, from QM's Figma), in place of the old home
-- HUD (Config.HomeHud off). Montserrat ExtraBold everywhere, white with a black stroke.
--   Left, centred top to bottom: Merge, Shop and Index, stacked (QM's art, label drawn in).
--   Bottom left: your cash (no more stamina over it: QM, Oct 10).
--   Bottom centre, only by your pen's bull spot (Config.BullSpots): Upgrade, with the
--     next pen level's price beside its cash icon, greyed when you can't afford it; the
--     free Unlock in the tutorial. The egg slots (Inventory) hide while it's up.
-- All of it hides on a ride. Laid out on a Config.BaseUi.RefWidth-wide screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)
local AnimalDex = require(script.Parent.AnimalDex)
local Inventory = require(script.Parent.Inventory)

local player = Players.LocalPlayer
local cfg = Config.BaseUi

local ART = { -- assets/ui/base_hud/*.png (QM, Oct 9)
	shop = { id = "rbxassetid://119060039201858", size = Vector2.new(267, 113) }, -- Shop.png
	index = { id = "rbxassetid://135845846149671", size = Vector2.new(267, 113) }, -- Index.png
	merge = { id = "rbxassetid://126251339270486", size = Vector2.new(267, 113) }, -- Merge.png
	cash = { id = "rbxassetid://76663783463176", size = Vector2.new(256, 256) }, -- Cash.png
	upgrade = { id = "rbxassetid://71762829770863", size = Vector2.new(526, 113) }, -- Upgrade.png
	upgradeGrey = { id = "rbxassetid://84646084249698", size = Vector2.new(526, 113) }, -- UpgradeGrey.png: QM's disabled Upgrade, for when you can't afford it
	unlock = { id = "rbxassetid://123061923353074", size = Vector2.new(526, 113) }, -- Unlock.png ("FREE" drawn in)
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local CASH_GREEN = Color3.fromHex("00FF09")
-- (in RefWidth pixels: QM's mockups at 1300 wide, x 1920 / 1300)
local MARGIN = 18
local MENU_WIDTH = 213 -- each of Shop, Index, Merge (QM, Oct 9: 20% smaller again, was 266, at first 296)
local MENU_GAP = 20
local ICON = 74 -- the counters' icons
local TEXT = 55 -- the counters' text (QM's Figma: 55, stroke 5)
local STROKE = 5
local UPGRADE_WIDTH = 524
local UPGRADE_BOTTOM = 44
-- The price's box on the Upgrade art, between its cash icon and "Upgrade" (Design: x
-- 0.19-0.57, y 0.25-0.75 of the button), left-aligned, as big as fits.
local PRICE_FROM, PRICE_TO = Vector2.new(0.19, 0.25), Vector2.new(0.57, 0.75)
local PRICE_TEXT, PRICE_STROKE = 46, 4

local gui = Instance.new("ScreenGui")
gui.Name = "BaseUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = root
local function resize()
	local view = gui.AbsoluteSize
	scale.Scale = view.X / cfg.RefWidth * (Config.HudScale or 1)
	root.Size = UDim2.fromOffset(view.X / scale.Scale, view.Y / scale.Scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()

local function text(parent, size, color, strokeWidth)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextSize = size
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, size)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = strokeWidth or STROKE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function picture(class, parent, art, width)
	local p = Instance.new(class)
	p.BackgroundTransparency = 1
	p.Image = art.id
	p.Size = UDim2.fromOffset(width, width * art.size.Y / art.size.X)
	p.Parent = parent
	return p
end

-- A press squashes it a little.
local function pressable(button)
	local s = Instance.new("UIScale")
	s.Parent = button
	button.MouseButton1Down:Connect(function()
		s.Scale = 0.94
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			s.Scale = 1
		end)
	end
end

-- Top left: Shop, Index, Merge.
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.BackgroundTransparency = 1
menu.AutomaticSize = Enum.AutomaticSize.XY
menu.AnchorPoint = Vector2.new(0, 0.5) -- (centred down the left edge: QM, Oct 9)
menu.Position = UDim2.new(0, MARGIN, 0.5, 0)
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, MENU_GAP)
list.Parent = menu
menu.Parent = root
for i, spec in { { "shop", function()
	if Shop.hasOffers() then
		Shop.toggle()
	end
end }, { "index", function()
	AnimalDex.toggle()
end }, { "merge", function()
	if Hud.onFuse then
		Hud.onFuse()
	end
end } } do
	local b = picture("ImageButton", menu, ART[spec[1]], MENU_WIDTH)
	b.Name = spec[1]
	b.LayoutOrder = ({ shop = 2, index = 3, merge = 1 })[spec[1]] -- (top to bottom: Merge, Shop, Index: QM, Oct 9)
	b:SetAttribute("Hover", 1.04) -- (ButtonHover: half its usual 1.08 grow, QM)
	b.Activated:Connect(spec[2])
	pressable(b)
end

-- Bottom left: cash, its icon with the number beside it.
local counters = Instance.new("Frame")
counters.Name = "Counters"
counters.BackgroundTransparency = 1
counters.AutomaticSize = Enum.AutomaticSize.XY
counters.AnchorPoint = Vector2.new(0, 1)
counters.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
local stack = Instance.new("UIListLayout")
stack.SortOrder = Enum.SortOrder.LayoutOrder
stack.Padding = UDim.new(0, 6)
stack.Parent = counters
counters.Parent = root
local function counter(order, art, color)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.LayoutOrder = order
	local across = Instance.new("UIListLayout")
	across.FillDirection = Enum.FillDirection.Horizontal
	across.VerticalAlignment = Enum.VerticalAlignment.Center
	across.Padding = UDim.new(0, 10)
	across.Parent = row
	picture("ImageLabel", row, art, ICON)
	local label = text(row, TEXT, color)
	label.LayoutOrder = 1
	row.Parent = counters
	return label
end
local cashText = counter(1, ART.cash, CASH_GREEN)
local function showCounters()
	cashText.Text = Hud.money(player:GetAttribute("Gold") or 0)
end
player:GetAttributeChangedSignal("Gold"):Connect(showCounters)
showCounters()

-- Bottom centre: Upgrade (or the tutorial's free Unlock), by your bull spot.
local upgradePen = ReplicatedStorage:WaitForChild("UpgradePen")
local upgrade = picture("ImageButton", root, ART.upgrade, UPGRADE_WIDTH)
upgrade.Name = "Upgrade"
upgrade.AnchorPoint = Vector2.new(0.5, 1)
upgrade.Position = UDim2.new(0.5, 0, 1, -UPGRADE_BOTTOM)
upgrade.Visible = false
pressable(upgrade)
local price = text(upgrade, PRICE_TEXT, CASH_GREEN, PRICE_STROKE)
price.AutomaticSize = Enum.AutomaticSize.None
price.Position = UDim2.fromScale(PRICE_FROM.X, PRICE_FROM.Y)
price.Size = UDim2.fromScale(PRICE_TO.X - PRICE_FROM.X, PRICE_TO.Y - PRICE_FROM.Y)
price.TextScaled = true
local fit = Instance.new("UITextSizeConstraint")
fit.MaxTextSize = PRICE_TEXT
fit.Parent = price

local function costNow()
	local nextBiome = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
	return if nextBiome then nextBiome.UnlockCost else nil
end

local buying = false
upgrade.Activated:Connect(function()
	local cost = costNow()
	local free = player:GetAttribute("Tutorial") == true
	if buying or not cost or (not free and (player:GetAttribute("Gold") or 0) < cost) then
		return
	end
	buying = true
	pcall(upgradePen.InvokeServer, upgradePen)
	buying = false
end)

local function bullSpot()
	local pen = tonumber(player:GetAttribute("Pen"))
	return pen and Config.BullSpots[pen]
end

local shown = nil
RunService.RenderStepped:Connect(function()
	local riding = Hud.isRiding()
	gui.Enabled = not riding and not player:GetAttribute("Cutscene") -- (none in the intro: Client/Intro)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local spot = bullSpot()
	local cost = costNow()
	local near = not riding and cost ~= nil and spot ~= nil and hrp ~= nil
		and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - spot).Magnitude <= cfg.BullReach
	if near ~= shown then
		shown = near
		upgrade.Visible = near
		Inventory.hideFor("Upgrade", near) -- (the egg slots go while it's up: QM)
	end
	if near then
		local free = player:GetAttribute("Tutorial") == true
		local affordable = (player:GetAttribute("Gold") or 0) >= cost
		upgrade.Image = if free then ART.unlock.id elseif affordable then ART.upgrade.id else ART.upgradeGrey.id
		price.Visible = not free
		price.Text = Hud.money(cost)
		price.TextColor3 = if affordable then CASH_GREEN else Color3.new(1, 1, 1)
	end
end)
