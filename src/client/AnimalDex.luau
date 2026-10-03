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
--   AnimalDex.toggle()     -- the Pets button
--   AnimalDex.close()
--   AnimalDex.onToggle = fn(open) -- set by the HUD: while it's open the only other
--                                 -- UI is the Pets button (QM)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
	Desert = {
		grid = "rbxassetid://94266934416109", -- assets/ui/dex/DexDesert.png
		examine = "rbxassetid://84664609464522", -- assets/ui/dex/DexDesertExamine.png
	},
	Snow = { -- the Tundra
		grid = "rbxassetid://80820120308003", -- assets/ui/dex/DexSnow.png
		examine = "rbxassetid://93155919439780", -- assets/ui/dex/DexSnowExamine.png
	},
	Ocean = {
		grid = "rbxassetid://114042809798313", -- assets/ui/dex/DexOcean.png
		examine = "rbxassetid://95075172887838", -- assets/ui/dex/DexOceanExamine.png
	},
}

-- Each animal running: its sprite sheets (tools/dex_sheets.py), 25 frames of
-- 192 px a sheet, 5 across and 5 down, with how many frames it has in all and
-- the seconds a frame shows (as its GIF). They're all kept loaded (see the end)
-- so an animal plays smoothly the first time it's shown.
local SHEETS = {
	Horse = { frames = 24, time = 0.03, "rbxassetid://120149236853502" },
	Pinto = { frames = 24, time = 0.03, "rbxassetid://126037490360673" },
	Pig = { frames = 24, time = 0.03, "rbxassetid://114358725443293" },
	Fish = { frames = 24, time = 0.03, "rbxassetid://105026411084404" },
	Rhino = { frames = 24, time = 0.03, "rbxassetid://108540506579286" },
	Unicorn = { frames = 24, time = 0.03, "rbxassetid://96425037730261" },
	Cactus = { frames = 20, time = 0.03, "rbxassetid://109623848986836" },
	Scorpion = { frames = 15, time = 0.03, "rbxassetid://113606148401403" },
	Sandworm = { frames = 20, time = 0.03, "rbxassetid://79124427569630" },
	SpineLizard = { frames = 18, time = 0.03, "rbxassetid://116109970242443" },
	Penguin = { frames = 15, time = 0.03, "rbxassetid://131302675159660" },
	Boar = { frames = 20, time = 0.03, "rbxassetid://94170840211405" },
	Snowman = { frames = 18, time = 0.03, "rbxassetid://139839156164981" },
	IceGolem = { frames = 24, time = 0.03, "rbxassetid://94192117186470" },
	Icebringer = { frames = 24, time = 0.04, "rbxassetid://125520132317720" },
	Starfish = { frames = 48, time = 0.06, "rbxassetid://79068936169772", "rbxassetid://103163746025717" },
	Squid = { frames = 24, time = 0.05, "rbxassetid://103797474563946" },
	KingCrab = { frames = 17, time = 0.03, "rbxassetid://88553226475116" },
	Whale = { frames = 24, time = 0.03, "rbxassetid://115620712947682" },
	Kraken = { frames = 24, time = 0.05, "rbxassetid://77455009647862" },
	FishSchool = { frames = 20, time = 0.03, "rbxassetid://104966778015588" },
	Snake = { frames = 48, time = 0.05, "rbxassetid://74812837390041", "rbxassetid://104986890781116" },
}
local FRAME, PER_SHEET, SHEET_COLUMNS = 192, 25, 5

-- Each animal's bio; one without its own (a new animal) gets PLACEHOLDER_BIO.
local PLACEHOLDER_BIO = "Description feijwufjewuejfw lorem ipsum" -- QM's placeholder
local BIOS = { -- QM's (Oct 3)
	Horse = "Very thoughtful, horse sends gifts to his friends each year.",
	Pig = "Pig isn't actually pink, just always blushing! Recently losing weight, down 2 pounds.",
	Pinto = "Cousin of horse, recently started playing water polo.",
	Fish = "Fish never learned to swim, and thinks it's too late now. Scared of water.",
	Rhino = "Rhino ran away to join the mafia at a young age. Still pays horses tuition.",
	Unicorn = "Unicorn is just a horse who can jump very high. The horn is glued on.",
	Cactus = "Cactus was once a plant, but it decided it had better places to be! Now it searches for cool trinkets.",
	Scorpion = "Scorpion was once the worlds #3 ranked badminton player. After he broke his ankle, he now takes revenge on the world.",
	Sandworm = "Sandworm started out collecting old books, but they all got sandy. Now it just burrows.",
	SpineLizard = "Spine Lizard runs as fast as it can, to try and make each day last forever.",
	Snake = "Snake wants to write a love letter, but has no arms! These days he is searching for some.",
	Penguin = "Penguin was told sardines would be in the Tundra, now hes hungry.",
	Boar = "Boar watched a sad TV show, now he is charging to hide his tears.",
	Snowman = "Snowman came to life when a child gave him a silk hat. He is making the most of it!",
	IceGolem = "Ice golem was originally just a pile of ice rocks, brought to life by the magic of Christmas. Friends with Snowman.",
	Icebringer = "Icebringer went to Antarctica and found troubling stuff. Now it gets brain freezes to try and forget.",
	Starfish = "Starfish was the star of her class. Little did she know they said that to all the starfish.",
	Squid = "Squid started out painting, but his art has gotten more abstract. Now it just squirts ink blotches.",
	KingCrab = "Crab was almost boiled, but escaped with his fast speed. He is still running to this day.",
	Whale = "Whale is a talented singer, but his concerts are usually underwater. Distant cousin of horse.",
	Kraken = "Kraken was once a squid, but started drinking raw milk and bonesmashing. Now his jaw hurts.",
}

local AnimalDex = {}

local gui, page, scale, grid, examine
local open, shown -- the page is up; the animal being examined, its place in `order` (nil: the grid)
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

-- The arrows spring: they swell a little under the mouse, squash when pressed and
-- bounce back when let go (QM). Nothing else on the page animates but the
-- examined animal popping in.
local HOVER, PRESS = 1.12, 0.86
local SPRING = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function bouncy(button)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local hovered = false
	local function to(size, info)
		TweenService:Create(scale, info, { Scale = size }):Play()
	end
	button.MouseEnter:Connect(function()
		hovered = true
		to(HOVER, SPRING)
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		to(1, SPRING)
	end)
	button.MouseButton1Down:Connect(function()
		to(PRESS, SQUASH)
	end)
	button.MouseButton1Up:Connect(function()
		to(if hovered then HOVER else 1, SPRING)
	end)
	return scale
end

-- Pops something in: from small, springing up past its size and settling.
local POP = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function popIn(object, delay)
	local scale = object:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = object
	task.delay(delay or 0, function()
		if scale.Parent then
			TweenService:Create(scale, POP, { Scale = 1 }):Play()
		end
	end)
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

local showGrid, showAnimal, arrow
local gridAt = 1 -- the biome whose grid shows (kept between openings)

-- A biome's grid of cards, with arrows either side of the page to the biome
-- before and after (QM's mockup).
function showGrid(index)
	clear()
	shown = nil
	gridAt = index
	local biome = biomes[index]
	page.Image = PAGES[biome.name].grid
	if biomes[index - 1] then
		arrow(UDim2.fromOffset(-100, 422), -90, function()
			showGrid(index - 1)
		end)
	end
	if biomes[index + 1] then
		arrow(UDim2.fromOffset(PAGE.X + 100, 422), 90, function()
			showGrid(index + 1)
		end)
	end
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
			for at, entry in order do
				if entry.kind == kind and entry.biome == biome.name then
					showAnimal(at)
				end
			end
		end)
		card.Parent = page
	end
end

function arrow(position, turn, onClick)
	local a = Instance.new("ImageButton")
	a.BackgroundTransparency = 1
	a.AutoButtonColor = false
	a.Image = ARROW
	a.Rotation = turn
	a.AnchorPoint = Vector2.new(0.5, 0.5)
	a.Size = UDim2.fromOffset(140, 140)
	a.Position = position
	a.Activated:Connect(onClick)
	bouncy(a)
	a.Parent = page
	return a
end

-- One animal close up: running, with its name and bio, and arrows to the next.
-- (at: its place in `order`, since the Fish is in two biomes.)
function showAnimal(at)
	clear()
	shown = at
	local kind = order[at].kind
	page.Image = PAGES[order[at].biome].examine
	for i, biome in biomes do
		if biome.name == order[at].biome then
			gridAt = i -- reopening shows this animal's biome
		end
	end
	local seen = ridden()[kind]

	-- Its feet a little over the divider, as in the mockup, and drawn over
	-- everything on the page, the bottom panel included (QM).
	local run = image(page, "", UDim2.fromOffset(400, 400), UDim2.fromOffset(PAGE.X / 2, 395), Vector2.new(0.5, 0.5))
	run.ZIndex = 5
	run.ImageRectSize = Vector2.new(FRAME, FRAME)
	run.ImageColor3 = if seen then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	popIn(run) -- bounces in rather than just appearing (QM)
	local sheets = SHEETS[kind]
	if sheets then
		local t = 0
		local function step(dt)
			t += dt
			local f = math.floor(t / sheets.time) % sheets.frames
			local k = f % PER_SHEET
			run.Image = sheets[f // PER_SHEET + 1]
			run.ImageRectOffset = Vector2.new((k % SHEET_COLUMNS) * FRAME, (k // SHEET_COLUMNS) * FRAME)
		end
		step(0)
		animate = RunService.RenderStepped:Connect(step)
	else
		run.Image = PetFaces.HEADSHOTS[kind] or "" -- no sheets yet: the still picture
		run.ImageRectSize = Vector2.zero
	end

	arrow(UDim2.fromOffset(256, 340), -90, function()
		showAnimal((at - 2) % #order + 1)
	end)
	arrow(UDim2.fromOffset(PAGE.X - 256, 340), 90, function()
		showAnimal(at % #order + 1)
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
	bio.Text = if seen then BIOS[kind] or PLACEHOLDER_BIO else "Ride creature to unlock!" -- QM
	bio.Parent = page
end

function AnimalDex.toggle()
	open = not open
	gui.Enabled = open
	if open and biomes[gridAt] then
		showGrid(gridAt)
	elseif not open then
		clear()
	end
	if AnimalDex.onToggle then
		AnimalDex.onToggle(open)
	end
end

function AnimalDex.close()
	if open then
		AnimalDex.toggle()
	end
end

-- The page in the middle of the screen, scaled to fit.
gui = Instance.new("ScreenGui")
gui.Name = "AnimalDex"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- under the HUD, so the Pets button that closes it stays on top
gui.Enabled = false
-- Clicking anywhere off the page closes it (QM): a clear button over the whole
-- screen, under the page. The page doesn't stop clicks reaching it, so a click
-- on the page or on one of its buttons (the arrows stick out past it) is let be.
local function over(object, at)
	local min, size = object.AbsolutePosition, object.AbsoluteSize
	return at.X >= min.X and at.Y >= min.Y and at.X <= min.X + size.X and at.Y <= min.Y + size.Y
end
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if over(page, at) then
		return
	end
	for _, d in page:GetDescendants() do
		if d:IsA("GuiButton") and d.Visible and over(d, at) then
			return
		end
	end
	AnimalDex.close()
end)
backdrop.Parent = gui
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
	elseif biomes[gridAt] then
		showGrid(gridAt)
	end
end)

-- Load the art ahead and keep it loaded: every page, card and sprite sheet is
-- drawn all the time (1 px, nearly see-through, on a screen of its own that's
-- always on), so nothing pops in blank or plays choppy the first time it's seen.
-- PreloadAsync alone left the sheets to load as they first played.
do
	local ids = { ARROW }
	for _, p in PAGES do
		table.insert(ids, p.grid)
		table.insert(ids, p.examine)
	end
	for _, id in CARDS do
		table.insert(ids, id)
	end
	for _, s in SHEETS do
		for _, id in s do
			if typeof(id) == "string" then
				table.insert(ids, id)
			end
		end
	end
	for _, entry in order do
		table.insert(ids, PetFaces.HEADSHOTS[entry.kind] or "")
	end
	local warm = Instance.new("ScreenGui")
	warm.Name = "AnimalDexWarm"
	warm.ResetOnSpawn = false
	for _, id in ids do
		local keep = Instance.new("ImageLabel")
		keep.BackgroundTransparency = 1
		keep.Size = UDim2.fromOffset(1, 1)
		keep.Image = id
		keep.ImageTransparency = 0.99
		keep.Parent = warm
	end
	warm.Parent = player:WaitForChild("PlayerGui")
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync(warm:GetChildren())
	end)
end

return AnimalDex
