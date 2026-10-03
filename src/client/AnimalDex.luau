-- The animal dictionary (QM's mockup, Oct 3): the Pets button opens it and closes
-- it again (the button stays up while it's open). A biome's page is a 4 x 3 grid
-- of its animals, each on its rarity's card, in colour once you've ridden one and
-- a black silhouette until then (the server keeps the list: the "Ridden"
-- attribute, Hatchery.server). Tapping an animal examines it: the page turns to
-- the biome's examine background with the animal running (its sprite sheets) and
-- its name and bio, and arrows step to the animal before or after, on into the
-- next biome's. Only the Meadow has its art so far: biomes without a page are
-- left out.
--
-- Everything is laid out in pixels of QM's 1102 x 829 page (half the size of
-- the page pictures) and scaled to fit the screen.
--
--   AnimalDex.toggle()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals
local PetFaces = require(script.Parent.PetFaces)

local player = Players.LocalPlayer

local PAGE = Vector2.new(1102, 829)
local SCREEN_SHARE = 0.54 -- the page is this share of the screen's width (QM's mockup), or less to fit its height
local CARD, ART, GAP = 200, 180, 43 -- QM: 200 px cards, the animal 180 px in the middle
local COLUMNS, ROWS = 4, 3
local GRID_TOP = 90 -- the grid sits in the middle of the page's frame (37 to 829)
local DIVIDER = 560 -- the examine page's line between the picture and the bio
local FONT = Enum.Font.FredokaOne

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local CARDS = {
	Common = "rbxassetid://79697917998703", -- assets/ui/dex/DexCommon.png
	Uncommon = "rbxassetid://129147449223279",
	Rare = "rbxassetid://72145821537095",
	Epic = "rbxassetid://137693950544184",
	Legendary = "rbxassetid://80504921595928",
}
local ARROW = "rbxassetid://130844925944438" -- assets/ui/dex/DexArrow.png (points up)

-- Each biome's page and examine page (Config.Biomes names). Biomes without
-- them aren't in the dictionary yet.
local PAGES = {
	Meadow = {
		grid = "rbxassetid://133205113798142", -- assets/ui/dex/DexMeadow.png
		examine = "rbxassetid://114285728618249", -- assets/ui/dex/DexMeadowExamine.png
	},
}

-- Each animal running: its sprite sheets (tools/dex_sheets.py), 12 frames of
-- 256 px each, 4 across and 3 down, 30 ms a frame.
local SHEETS = {
	Horse = { "rbxassetid://117214923442803", "rbxassetid://92016581002992" },
	Pinto = { "rbxassetid://90941968473030", "rbxassetid://122380495096996" },
	Pig = { "rbxassetid://72090209789482", "rbxassetid://126968575360177" },
	Fish = { "rbxassetid://125040909461882", "rbxassetid://134214794380576" },
	Rhino = { "rbxassetid://117539225187822", "rbxassetid://82166405562428" },
	Unicorn = { "rbxassetid://108504409647134", "rbxassetid://93485365774832" },
}
local FRAME, PER_SHEET, FRAME_TIME = 256, 12, 0.03

local BIOS = {
	Horse = "Very thoughtful, horse sends gifts to his friends each year.", -- QM's
	Pinto = "Never sits still. Pinto has galloped every inch of the meadow twice.",
	Pig = "Always first to dinner and last to leave. Surprisingly quick for a pig.",
	Fish = "Nobody knows how Fish ended up in the meadow, least of all Fish.",
	Rhino = "Rhino doesn't go around things. Rhino goes through them.",
	Unicorn = "Shy and rarely seen. Wherever it lands, a rainbow follows.",
}

local AnimalDex = {}

local gui, page, scale, grid, examine
local open, shown -- the page is up; the animal being examined (nil: the grid)
local animate -- the running animal's frame clock

local function rarityOf(kind)
	return require(Animals[kind]).Rarity
end

-- The biomes with a page, each with its animals in rarity order (cheapest first
-- within one), and every animal in that order across biomes for the arrows.
local biomes, order = {}, {}
for _, biome in Config.Biomes do
	if PAGES[biome.Name] then
		local kinds = {}
		for kind in biome.Herd do
			table.insert(kinds, kind)
		end
		table.sort(kinds, function(a, b)
			local ra, rb = table.find(RARITIES, rarityOf(a)), table.find(RARITIES, rarityOf(b))
			if ra ~= rb then
				return ra < rb
			end
			return (Config.PetIncome[a] or 0) < (Config.PetIncome[b] or 0)
		end)
		table.insert(biomes, { name = biome.Name, kinds = kinds })
		for _, kind in kinds do
			table.insert(order, { kind = kind, biome = biome.Name })
		end
	end
end

local function ridden()
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Ridden") or "[]")
	local set = {}
	for _, kind in if ok then list else {} do
		set[kind] = true
	end
	return set
end

local function nameOf(kind)
	return (kind:gsub("(%l)(%u)", "%1 %2")) -- "SpineLizard" reads "Spine Lizard"
end

local function image(parent, id, size, position, anchor)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.Image = id
	i.Size = size
	i.Position = position
	i.AnchorPoint = anchor or Vector2.zero
	i.Parent = parent
	return i
end

local function clear()
	if animate then
		animate:Disconnect()
		animate = nil
	end
	for _, child in page:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local showGrid, showAnimal

-- A biome's grid of cards.
function showGrid(biome)
	clear()
	shown = nil
	page.Image = PAGES[biome.name].grid
	local seen = ridden()
	local width = COLUMNS * CARD + (COLUMNS - 1) * GAP
	for i, kind in biome.kinds do
		if i > COLUMNS * ROWS then
			break
		end
		local col, row = (i - 1) % COLUMNS, (i - 1) // COLUMNS
		local card = Instance.new("ImageButton")
		card.Name = kind
		card.BackgroundTransparency = 1
		card.AutoButtonColor = false
		card.Image = CARDS[rarityOf(kind)]
		card.Size = UDim2.fromOffset(CARD, CARD)
		card.Position = UDim2.fromOffset((PAGE.X - width) / 2 + col * (CARD + GAP), GRID_TOP + row * (CARD + GAP))
		local art = image(card, PetFaces.HEADSHOTS[kind] or "", UDim2.fromOffset(ART, ART), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		art.ImageColor3 = if seen[kind] then Color3.new(1, 1, 1) else Color3.new(0, 0, 0) -- not ridden yet: a silhouette
		card.Activated:Connect(function()
			showAnimal(kind)
		end)
		card.Parent = page
	end
end

local function arrow(position, turn, onClick)
	local a = Instance.new("ImageButton")
	a.BackgroundTransparency = 1
	a.AutoButtonColor = false
	a.Image = ARROW
	a.Rotation = turn
	a.AnchorPoint = Vector2.new(0.5, 0.5)
	a.Size = UDim2.fromOffset(140, 140)
	a.Position = position
	a.Activated:Connect(onClick)
	a.Parent = page
	return a
end

-- One animal close up: running, with its name and bio, and arrows to the next.
function showAnimal(kind)
	clear()
	shown = kind
	local at = 1
	for i, entry in order do
		if entry.kind == kind then
			at = i
		end
	end
	page.Image = PAGES[order[at].biome].examine
	local seen = ridden()[kind]

	local run = image(page, "", UDim2.fromOffset(400, 400), UDim2.fromOffset(PAGE.X / 2, 375), Vector2.new(0.5, 0.5)) -- its feet over the divider, as in the mockup
	run.ImageRectSize = Vector2.new(FRAME, FRAME)
	run.ImageColor3 = if seen then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	local sheets = SHEETS[kind]
	if sheets then
		local t = 0
		local frames = #sheets * PER_SHEET
		local function step(dt)
			t += dt
			local f = math.floor(t / FRAME_TIME) % frames
			local k = f % PER_SHEET
			run.Image = sheets[f // PER_SHEET + 1]
			run.ImageRectOffset = Vector2.new((k % 4) * FRAME, (k // 4) * FRAME)
		end
		step(0)
		animate = RunService.RenderStepped:Connect(step)
	else
		run.Image = PetFaces.HEADSHOTS[kind] or "" -- no sheets yet: the still picture
		run.ImageRectSize = Vector2.zero
	end

	arrow(UDim2.fromOffset(256, 340), -90, function()
		showAnimal(order[(at - 2) % #order + 1].kind)
	end)
	arrow(UDim2.fromOffset(PAGE.X - 256, 340), 90, function()
		showAnimal(order[at % #order + 1].kind)
	end)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Font = FONT
	name.TextSize = 60
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.AnchorPoint = Vector2.new(0, 0.5)
	name.Position = UDim2.fromOffset(32, DIVIDER)
	name.Size = UDim2.fromOffset(600, 70)
	name.Text = if seen then nameOf(kind) else "???"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = name
	name.Parent = page

	local bio = Instance.new("TextLabel")
	bio.BackgroundTransparency = 1
	bio.Font = FONT
	bio.TextSize = 44
	bio.TextColor3 = Color3.new(0, 0, 0)
	bio.TextTransparency = 0.5 -- QM: black at 50%, no outline
	bio.TextWrapped = true
	bio.TextXAlignment = Enum.TextXAlignment.Left
	bio.TextYAlignment = Enum.TextYAlignment.Top
	bio.Position = UDim2.fromOffset(36, DIVIDER + 45)
	bio.Size = UDim2.fromOffset(PAGE.X - 72, 829 - DIVIDER - 70)
	bio.Text = if seen then BIOS[kind] or "" else "Ride one to find out more."
	bio.Parent = page
end

function AnimalDex.toggle()
	open = not open
	gui.Enabled = open
	if open and biomes[1] then
		showGrid(biomes[1])
	elseif not open then
		clear()
	end
end

-- The page in the middle of the screen, scaled to fit.
gui = Instance.new("ScreenGui")
gui.Name = "AnimalDex"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, so the Pets button that closes it stays on top
gui.Enabled = false
page = Instance.new("ImageLabel")
page.Name = "Page"
page.BackgroundTransparency = 1
page.AnchorPoint = Vector2.new(0.5, 0.5)
page.Position = UDim2.fromScale(0.5, 0.5)
page.Size = UDim2.fromOffset(PAGE.X, PAGE.Y)
scale = Instance.new("UIScale")
scale.Parent = page
page.Parent = gui
local camera = workspace.CurrentCamera
local function resize()
	local screen = camera.ViewportSize
	scale.Scale = math.min(screen.X * SCREEN_SHARE / PAGE.X, screen.Y * 0.8 / PAGE.Y)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
gui.Parent = player:WaitForChild("PlayerGui")

-- A newly ridden animal colours in straight away if the page is up.
player:GetAttributeChangedSignal("Ridden"):Connect(function()
	if not open then
		return
	end
	if shown then
		showAnimal(shown)
	elseif biomes[1] then
		showGrid(biomes[1])
	end
end)

-- Load the art ahead so the page doesn't pop in blank.
task.spawn(function()
	local ids = { ARROW }
	for _, p in PAGES do
		table.insert(ids, p.grid)
		table.insert(ids, p.examine)
	end
	for _, id in CARDS do
		table.insert(ids, id)
	end
	for _, s in SHEETS do
		table.insert(ids, s[1])
		table.insert(ids, s[2])
	end
	game:GetService("ContentProvider"):PreloadAsync(ids)
end)

return AnimalDex
