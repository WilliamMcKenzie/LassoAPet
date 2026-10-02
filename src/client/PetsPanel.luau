-- The Pets panel (QM's mockup): the Pets button at home opens a dark screen
-- with a card for every pet you own, the one you ride included. Each card is
-- the pet's headshot on its rarity's slot picture, its gold a second top left
-- and a trash can top right. Tap the trash once to arm it (it wiggles and turns
-- red), again within a couple of seconds to let the pet go (RemovePet). Best
-- earners come first. As many cards as fit go in a row; past a screenful of
-- rows the grid scrolls. Clicking anywhere off a card closes it, and the rest
-- of the HUD is hidden while it's open.
--
--   PetsPanel.init({ money = fn, hideHud = fn(hidden) })
--   PetsPanel.open()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals

local PetsPanel = {}

-- Headshots rendered from each pet's model (assets/ui/Pet<Kind>.png); "" until
-- uploaded, when the card shows the pet's name instead.
local HEADSHOTS = {
	Horse = "rbxassetid://119389756908548", -- PetHorse.png
	Pinto = "rbxassetid://140221490595819", -- PetPinto.png
	Pig = "rbxassetid://127300311363752", -- PetPig.png
	Fish = "rbxassetid://127767442274755", -- PetFish.png
	Rhino = "rbxassetid://136593454528783", -- PetRhino.png
	Unicorn = "rbxassetid://92220873666400", -- PetUnicorn.png
	Cactus = "rbxassetid://82844219656223", -- PetCactus.png
	Scorpion = "rbxassetid://97432378312477", -- PetScorpion.png
	Sandworm = "rbxassetid://98334444188731", -- PetSandworm.png
	Snake = "rbxassetid://134072754506430", -- PetSnake.png
	Penguin = "rbxassetid://89346746409859", -- PetPenguin.png
	Snowman = "rbxassetid://107750337450328", -- PetSnowman.png
	PolarBear = "rbxassetid://77080611978079", -- PetPolarBear.png
	IceWyvern = "rbxassetid://103993655895431", -- PetIceWyvern.png
	SpineLizard = "rbxassetid://79153083419077", -- PetSpineLizard.png
	Boar = "rbxassetid://71880208640997", -- PetBoar.png
	WhiteWolf = "rbxassetid://111740729525133", -- PetWhiteWolf.png
	Troll = "rbxassetid://119212344502752", -- PetTroll.png
	IceGolem = "rbxassetid://111385178023948", -- PetIceGolem.png
	IceDrake = "rbxassetid://72747878519742", -- PetIceDrake.png
	Icebringer = "rbxassetid://84670113231117", -- PetIcebringer.png
	Kraken = "rbxassetid://73007413768978", -- PetKraken.png
	Squid = "rbxassetid://88019693105640", -- PetSquid.png
	Whale = "rbxassetid://92143885351378", -- PetWhale.png
	KingCrab = "rbxassetid://114286828935377", -- PetKingCrab.png
	Starfish = "rbxassetid://123315052041653", -- PetStarfish.png
}
local TRASH = "rbxassetid://74308771924477" -- assets/ui/Trash.png (QM's trash can)
local COIN = "rbxassetid://99312860837685"
-- QM's slot pictures by rarity (as the inventory bar); a plain colour until one is uploaded.
local SLOTS = {
	Common = "rbxassetid://137596967858841", -- assets/ui/SlotCommon.png
	Uncommon = "rbxassetid://120075276423928",
	Rare = "rbxassetid://92909054184182",
	Epic = "rbxassetid://75096704585668",
	Legendary = "rbxassetid://100279863676585",
}
local COMMON_COLOR = Color3.fromRGB(150, 160, 175)

local FONT = Enum.Font.FredokaOne
local REFERENCE_WIDTH = 1320 -- screen width the sizes below are drawn for (as the HUD)
local CARD = 170 -- the square card
local OVERHANG = 22 -- how far the gold and trash stick out over the card's top
local GAP = 34
local CELL = Vector2.new(CARD + GAP, CARD + OVERHANG + GAP)
-- Headshot transparency across the card: clear at the edges, solid in the middle.
local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0),
	NumberSequenceKeypoint.new(0.8, 0),
	NumberSequenceKeypoint.new(1, 1),
})
local ARM_TIME = 2 -- seconds a tapped trash can stays armed

local player = Players.LocalPlayer
local removePet = ReplicatedStorage:WaitForChild("RemovePet")
local money, hideHud
local gui, scale, scroll, grid
local isOpen = false
local armed -- the id whose trash can was tapped once

local function rarityOf(kind)
	local module = Animals:FindFirstChild(kind)
	return module and require(module).Rarity or "Common"
end

-- Everything you own: the pet you ride ("ride") and the pets in your pen, best earners first.
local function ownedPets()
	local riding = player:GetAttribute("RidePet") or Config.DefaultPet
	local list = if riding ~= "" then { { id = "ride", kind = riding } } else {} -- "": no pet yet (the tutorial)
	local index = player:GetAttribute("Pen")
	local pen = index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
	if pen then
		local ok, items = pcall(HttpService.JSONDecode, HttpService, pen:GetAttribute("Contents") or "{}")
		for id, item in if ok then items else {} do
			if item.pet then
				table.insert(list, { id = id, kind = item.pet })
			end
		end
	end
	table.sort(list, function(a, b)
		local ia, ib = Config.PetIncome[a.kind] or 0, Config.PetIncome[b.kind] or 0
		if ia ~= ib then
			return ia > ib
		end
		return a.id < b.id
	end)
	return list
end

local function stroked(object, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = object
	return s
end

local function card(pet, order)
	local cell = Instance.new("TextButton") -- sinks clicks, so tapping a card doesn't close the panel
	cell.Name = pet.kind
	cell.Text = ""
	cell.AutoButtonColor = false
	cell.BackgroundTransparency = 1
	cell.LayoutOrder = order

	local face = Instance.new("Frame")
	face.Size = UDim2.fromOffset(CARD, CARD)
	face.Position = UDim2.fromOffset(0, OVERHANG)
	face.BackgroundColor3 = COMMON_COLOR
	Instance.new("UICorner", face).CornerRadius = UDim.new(52 / 256, 0) -- the slot pictures' corners
	local slot = SLOTS[rarityOf(pet.kind)]
	if not slot or slot == "" then
		stroked(face, 5).ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- the slot pictures have their own
	else
		face.BackgroundTransparency = 1
		local bg = Instance.new("ImageLabel")
		bg.BackgroundTransparency = 1
		bg.Size = UDim2.fromScale(1, 1)
		bg.Image = slot
		bg.Parent = face
	end
	local shot = HEADSHOTS[pet.kind]
	if shot and shot ~= "" then
		-- The headshot fades out toward every edge so it melts into the slot
		-- picture instead of being cut off hard: one gradient fades it left and
		-- right, the CanvasGroup around it fades the result top and bottom.
		local fade = Instance.new("CanvasGroup")
		fade.BackgroundTransparency = 1
		fade.AnchorPoint = Vector2.new(0.5, 0.5)
		fade.Position = UDim2.fromScale(0.5, 0.5)
		fade.Size = UDim2.fromScale(0.92, 0.92) -- inside the slot picture's own border
		fade.ZIndex = 2
		local picture = Instance.new("ImageLabel")
		picture.BackgroundTransparency = 1
		picture.Size = UDim2.fromScale(1, 1)
		picture.Image = shot
		picture.Parent = fade
		local sides = Instance.new("UIGradient")
		sides.Transparency = FADE
		sides.Parent = picture
		local ends = Instance.new("UIGradient")
		ends.Rotation = 90
		ends.Transparency = FADE
		ends.Parent = fade
		fade.Parent = face
	else
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(1, 1)
		name.Font = FONT
		name.TextSize = 30
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = pet.kind
		name.ZIndex = 2
		stroked(name, 3)
		name.Parent = face
	end
	face.Parent = cell

	-- Gold a second, over the top left corner: the coin with the amount beside it.
	local coin = Instance.new("ImageLabel")
	coin.BackgroundTransparency = 1
	coin.Size = UDim2.fromOffset(46, 46)
	coin.Position = UDim2.fromOffset(-14, OVERHANG - 23)
	coin.Image = COIN
	coin.ZIndex = 3
	coin.Parent = cell
	local rate = Instance.new("TextLabel")
	rate.BackgroundTransparency = 1
	rate.AutomaticSize = Enum.AutomaticSize.X
	rate.Size = UDim2.fromOffset(0, 40)
	rate.Position = UDim2.fromOffset(26, OVERHANG - 20)
	rate.Font = FONT
	rate.TextSize = 30
	rate.TextColor3 = Color3.new(1, 1, 1)
	rate.TextXAlignment = Enum.TextXAlignment.Left
	rate.Text = money(Config.PetIncome[pet.kind] or 0) .. "/s"
	rate.ZIndex = 4
	stroked(rate, 4)
	rate.Parent = cell

	-- The trash can over the top right corner.
	local trash = Instance.new(if TRASH ~= "" then "ImageButton" else "TextButton")
	trash.BackgroundTransparency = 1
	trash.AnchorPoint = Vector2.new(0.5, 0.5)
	trash.Size = UDim2.fromOffset(54, 54)
	trash.Position = UDim2.fromOffset(CARD - 6, OVERHANG + 2)
	trash.ZIndex = 5
	if TRASH ~= "" then
		trash.Image = TRASH
	else
		trash.Text = "X"
		trash.Font = FONT
		trash.TextSize = 36
		trash.TextColor3 = Color3.new(1, 1, 1)
		stroked(trash, 4)
	end
	local wiggle = Instance.new("UIScale")
	wiggle.Parent = trash
	trash.Activated:Connect(function()
		if armed == pet.id then
			armed = nil
			removePet:FireServer(pet.id)
			TweenService:Create(cell, TweenInfo.new(0.15), { Size = UDim2.fromOffset(0, 0) }):Play()
			return
		end
		armed = pet.id
		if trash:IsA("ImageButton") then
			trash.ImageColor3 = Color3.fromRGB(255, 90, 90)
		else
			trash.TextColor3 = Color3.fromRGB(255, 90, 90)
		end
		wiggle.Scale = 1.25
		TweenService:Create(wiggle, TweenInfo.new(0.35, Enum.EasingStyle.Elastic), { Scale = 1.1 }):Play()
		task.delay(ARM_TIME, function()
			if armed == pet.id then
				armed = nil
			end
			if trash.Parent then
				wiggle.Scale = 1
				if trash:IsA("ImageButton") then
					trash.ImageColor3 = Color3.new(1, 1, 1)
				else
					trash.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end)
	end)
	trash.Parent = cell
	return cell
end

-- Rebuilds the cards and sizes the grid: as many a row as fit across 90% of
-- the screen, as many rows as fit in 80% of it before it scrolls.
local function redraw()
	if not isOpen then
		return
	end
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local pets = ownedPets()
	local screen = workspace.CurrentCamera.ViewportSize / scale.Scale
	local columns = math.clamp(#pets, 1, math.max(1, math.floor(screen.X * 0.9 / CELL.X)))
	local rows = math.ceil(#pets / columns)
	local fitRows = math.max(1, math.floor(screen.Y * 0.8 / CELL.Y))
	grid.FillDirectionMaxCells = columns
	-- A GAP wider than the cells so the trash cans on the last column, which
	-- stick out past their cards, aren't clipped.
	scroll.Size = UDim2.fromOffset(columns * CELL.X + GAP, math.min(rows, fitRows) * CELL.Y)
	scroll.CanvasSize = UDim2.fromOffset(0, rows * CELL.Y)
	scroll.ScrollingEnabled = rows > fitRows
	for i, pet in pets do
		card(pet, i).Parent = scroll
	end
end

function PetsPanel.close()
	if not isOpen then
		return
	end
	isOpen, armed = false, nil
	gui.Enabled = false
	hideHud(false)
end

function PetsPanel.open()
	isOpen = true
	hideHud(true)
	gui.Enabled = true
	redraw()
end

function PetsPanel.init(options)
	money, hideHud = options.money, options.hideHud
	gui = Instance.new("ScreenGui")
	gui.Name = "PetsPanel"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Enabled = false

	-- The dark backdrop; a click anywhere on it closes the panel.
	local backdrop = Instance.new("TextButton")
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.35
	backdrop.Activated:Connect(PetsPanel.close)
	backdrop.Parent = gui

	-- Everything else is drawn in pixels of a REFERENCE_WIDTH screen, like the HUD.
	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	scale = Instance.new("UIScale")
	scale.Parent = root
	local camera = workspace.CurrentCamera
	local function resize()
		scale.Scale = camera.ViewportSize.X / REFERENCE_WIDTH * Config.HudScale
		root.Size = UDim2.fromOffset(camera.ViewportSize.X / scale.Scale, camera.ViewportSize.Y / scale.Scale)
		redraw()
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	root.Parent = gui

	scroll = Instance.new("ScrollingFrame")
	scroll.AnchorPoint = Vector2.new(0.5, 0.5)
	scroll.Position = UDim2.fromScale(0.5, 0.5)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 8
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ClipsDescendants = true
	scroll.Parent = root
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, GAP / 2)
	pad.PaddingRight = UDim.new(0, GAP / 2)
	pad.PaddingTop = UDim.new(0, GAP / 2)
	pad.Parent = scroll
	grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD, CARD + OVERHANG)
	grid.CellPadding = UDim2.fromOffset(GAP, GAP)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = scroll
	resize()
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Keep the cards current while it's open (a pet hatches, one is removed).
	player:GetAttributeChangedSignal("RidePet"):Connect(redraw)
	local function watchPen()
		local index = player:GetAttribute("Pen")
		local pen = index and workspace:WaitForChild("Pens"):FindFirstChild("Pen" .. index)
		if pen then
			pen:GetAttributeChangedSignal("Contents"):Connect(redraw)
		end
	end
	player:GetAttributeChangedSignal("Pen"):Connect(watchPen)
	watchPen()
end

return PetsPanel
