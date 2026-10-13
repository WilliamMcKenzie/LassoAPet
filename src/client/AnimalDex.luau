-- The animal dictionary, the Index (QM's mockup, Oct 3; one page for every biome,
-- Oct 11): the Pets button opens it and closes it again (the button stays up while
-- it's open), as does its X. It opens straight onto the Horse: the animal running (its
-- sprite sheets) on the page, with its name and bio, in colour once you've ridden one
-- and a black silhouette until then (the server keeps the list: the "Ridden"
-- attribute, Hatchery.server). Arrows step to the animal before or after, biome by
-- biome.
--
-- Everything is laid out in pixels of QM's 1102 x 840 page (assets/ui/dex/IndexPanel.png)
-- and scaled to fit the screen.
--
--   AnimalDex.toggle()     -- the Pets button
--   AnimalDex.close(instant)  -- instant: no closing animation (switching menus)
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
local ModalPop = require(script.Parent.ModalPop)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)

local player = Players.LocalPlayer

local PAGE = Vector2.new(1102, 840)
local SCREEN_SHARE = 0.54 -- the page is this share of the screen's width (QM's mockup), or less to fit its height
local DIVIDER = 575 -- the page's line between the picture and the bio
local NAME_FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local BIO_FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local PANEL = "rbxassetid://103615321543388" -- assets/ui/dex/IndexPanel.png (QM's, without arrows: they're buttons)
local ARROW = "rbxassetid://133433182612945" -- assets/ui/dex/IndexArrow.png (points right)
local CLOSE = "rbxassetid://84920756991403" -- assets/ui/dex/IndexClose.png
local ARROW_AT = { 324, 396 } -- (left one's middle, as in QM's mockup; the right one's mirrored)
local ARROW_SIZE = Vector2.new(56, 53)

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
	Bunny = { frames = 23, time = 0.03, "rbxassetid://109509060486808" },
	Kitten = { frames = 24, time = 0.03, "rbxassetid://76735200273090" },
	Firebird = { frames = 13, time = 0.03, "rbxassetid://92445178825484" }, -- dex/DexFirebird_1.png
	RockHog = { frames = 20, time = 0.03, "rbxassetid://84423041173252" }, -- dex/DexRockHog_1.png
	Rockworm = { frames = 48, time = 0.06, "rbxassetid://101259765786362", "rbxassetid://98609799525177" }, -- dex/DexRockworm_1.png, _2
	FireLobster = { frames = 48, time = 0.05, "rbxassetid://136257565701438", "rbxassetid://116867911164006" }, -- dex/DexFireLobster_1.png, _2
	LavaWhale = { frames = 24, time = 0.03, "rbxassetid://107947322659885" }, -- dex/DexLavaWhale_1.png
	TRex = { frames = 17, time = 0.03, "rbxassetid://83277205426899" }, -- dex/DexTRex_1.png
	Raptor = { frames = 12, time = 0.03, "rbxassetid://118475104372693" }, -- dex/DexRaptor_1.png
	Spinosaurus = { frames = 20, time = 0.03, "rbxassetid://122762734286787" }, -- dex/DexSpinosaurus_1.png
	Pterodactyl = { frames = 24, time = 0.04, "rbxassetid://110282216559726" }, -- dex/DexPterodactyl_1.png
	Ankylosaurus = { frames = 17, time = 0.03, "rbxassetid://122123351672825" }, -- dex/DexAnkylosaurus_1.png
	PalmGuy = { frames = 12, time = 0.03, "rbxassetid://134915752151829" }, -- dex/DexPalmGuy_1.png
	BoneRex = { frames = 17, time = 0.03, "rbxassetid://107213392278992" }, -- dex/DexBoneRex_1.png
	Phoenix = { frames = 24, time = 0.04, "rbxassetid://82014579609498" }, -- dex/DexPhoenix_1.png
	Lionfish = { frames = 24, time = 0.03, "rbxassetid://111810935342924" }, -- dex/DexLionfish_1.png
	VolcanoTortoise = { frames = 20, time = 0.03, "rbxassetid://120212888052337" }, -- dex/DexVolcanoTortoise_1.png
	Cactus = { frames = 20, time = 0.03, "rbxassetid://109623848986836" },
	Scorpion = { frames = 15, time = 0.03, "rbxassetid://113606148401403" },
	Sandworm = { frames = 20, time = 0.03, "rbxassetid://79124427569630" },
	SpineLizard = { frames = 18, time = 0.03, "rbxassetid://116109970242443" },
	Penguin = { frames = 15, time = 0.03, "rbxassetid://131302675159660" },
	Boar = { frames = 20, time = 0.03, "rbxassetid://94170840211405" },
	Snowman = { frames = 18, time = 0.03, "rbxassetid://139839156164981" },
	IceGolem = { frames = 24, time = 0.03, "rbxassetid://94192117186470" },
	SnackYak = { frames = 18, time = 0.03, "rbxassetid://131389846384914" },
	Icebringer = { frames = 24, time = 0.04, "rbxassetid://125520132317720" },
	Starfish = { frames = 48, time = 0.06, "rbxassetid://79068936169772", "rbxassetid://103163746025717" },
	Clownfish = { frames = 24, time = 0.03, "rbxassetid://98236364459356" }, -- dex/DexClownfish_1.png
	Squid = { frames = 24, time = 0.05, "rbxassetid://103797474563946" },
	KingCrab = { frames = 17, time = 0.03, "rbxassetid://88553226475116" },
	BlueCrab = { frames = 17, time = 0.03, "rbxassetid://101217167881986" },
	RoboShark = { frames = 20, time = 0.03, "rbxassetid://121345968224573" },
	Loong = { frames = 24, time = 0.04, "rbxassetid://122418900338409" }, -- tools/dex_render.py
	Beholder = { frames = 20, time = 0.03, "rbxassetid://120731347381935" }, -- tools/dex_render.py
	WarElephant = { frames = 24, time = 0.03, "rbxassetid://103485896070996" }, -- tools/dex_render.py
	SoulHorse = { frames = 24, time = 0.03, "rbxassetid://71539574618443" }, -- tools/dex_render.py
	Sludge = { frames = 24, time = 0.06, "rbxassetid://101851743328298" }, -- tools/dex_render.py
	Leviathan = { frames = 20, time = 0.03, "rbxassetid://130093266232562" }, -- tools/dex_render.py
	Whale = { frames = 24, time = 0.03, "rbxassetid://115620712947682" },
	Kraken = { frames = 24, time = 0.05, "rbxassetid://77455009647862" },
	FishSchool = { frames = 20, time = 0.03, "rbxassetid://104966778015588" },
	Snake = { frames = 48, time = 0.05, "rbxassetid://74812837390041", "rbxassetid://104986890781116" },
}
local FRAME, PER_SHEET, SHEET_COLUMNS = 192, 25, 5

-- Each animal's bio; one without its own (a new animal) gets PLACEHOLDER_BIO.
local PLACEHOLDER_BIO = "Description feijwufjewuejfw lorem ipsum" -- QM's placeholder
local BIOS = { -- QM's (Oct 4, the pets JSON)
	Horse = "Very thoughtful, horse sends gifts to his friends each year.",
	Bunny = "Hops everywhere, even to the fridge. Has never once walked.",
	Pig = "Isn't actually pink, just always blushing. Recently losing weight, down 2 pounds.",
	Pinto = "Cousin of horse, recently started playing water polo.",
	Fish = "Never learned to swim, and thinks it's too late now. Scared of water.",
	MarbleColossus = "Was a museum statue for 900 years. Got bored. Kept the gold.",
	MarbleFish = "Saw a unicorn once and has been wearing the horn ever since. Still can't swim.",
	Lion = "King of the meadow, by his own vote. The mane takes three hours every morning.",
	Buffalo = "Has never once been in a hurry. Will flatten you anyway.",
	Crocodile = "Smiles at everyone. Nobody has ever smiled back.",
	MajesticUnicorn = "Never walks anywhere without a rainbow. Has a stylist for the mane. Two, actually.",
	CrystalCentipede = "Grows a new crystal every birthday. Has a hundred legs and owns no shoes.",
	RedMushroom = "Smallest of the bunch. Insists the spots are freckles.",
	BrownMushroom = "Very sensible. Brings an umbrella everywhere, just in case.",
	PurpleMushroom = "The big cousin. Gives the best hugs in the whole cave.",
	BlueCrystal = "The Cactus's pen pal. Polishes itself every morning.",
	PinkCrystal = "Sparkles when it laughs, which is all the time.",
	LivingBirch = "Thinks it is very well hidden in the woods. Its leaves are bright orange.",
	CrystalSpider = "Knits sweaters for all eight legs. Takes a while to get dressed.",
	CrystalElephant = "Grew its own armour. Never forgets, and never lets you forget it's sparkly.",
	CrystalPhoenix = "The Phoenix's cousin who doesn't like getting burnt. Shatters instead.",
	Rhino = "Ran away to join the mafia at a young age. Still pays horses tuition.",
	Unicorn = "Just a horse who can jump very high. The horn is glued on.",
	Kitten = "Came to the desert for the world's biggest litter box. Has not left since.",
	Cactus = "The fastest plant in the west. Deals eggs on the side.",
	Scorpion = "Got busted dealing spice, now speaks about drug awareness at high school ceremonies.",
	Eyeworm = "Has one eye and never blinks during staring contests. Undefeated.",
	CrimsonScorpion = "Dyed itself red to look scarier. Now everyone just calls it Ketchup.",
	Maw = "All mouth, no eyes. Finds snacks by smell and good luck.",
	Asura = "Never sheathes its sword. Nobody has asked it to.",
	Seraph = "Be not afraid. Its every eye is watching you hatch it.",
	CrimsonSeraph = "Be very afraid. Every one of its eyes is glaring, and its rings never stop spinning.",
	CrystalSeraph = "Sparkles from every eye at once. Nobody has ever won a staring contest with it.",
	IvorySpider = "Spins its webs in perfect white. Hates muddy boots.",
	Sandworm = "Sandworm started out collecting old books, but they all got sandy. Now it just burrows.",
	SpineLizard = "A natural solar panel, yet overheats easily. Going extinct.",
	Snake = "Wants to write a love letter, but has no arms. Scares off animals with its rattle.",
	Penguin = "Chasing after boar, hoping to catch a ride. Looking for a body of water.",
	Boar = "Watched a sad TV show, now he is forever charging to hide his tears.",
	Snowman = "Came to life after he was given a silk hat. Feeling a bit frosty.",
	IceGolem = "Travelled from Clash Royal just to stampede, can grow/shrink at will.",
	Icebringer = "Found a legendary amulet under an iceberg, trying to return it to its owner. Can freeze nearby objects.",
	Starfish = "Not actually a fish.",
	Lionfish = "All spikes, no roar. Still very proud of the name.",
	Clownfish = "Lives in a stinging plant on purpose. Thinks it's hilarious.",
	Whale = "A talented singer, but no one can hear it from underwater. Distant cousin of horse.",
	Squid = "Started out with oil painting, but its art has gotten more abstract: now it just squirts ink blotches.",
	FishSchool = "Schools out. Fish are in. Can destroy any obstacles in their path.",
	KingCrab = "Was almost boiled once. Still running to this day.",
	BlueCrab = "Tried to join the crips, couldn't crip walk so got booted. Cousin of king crab.",
	Kraken = "A squid turned looksmaxxer, hasn't acted the same since ascending.",
	Beholder = "Really bad vision but can't afford the custom glasses. They say beauty is in it's eye.",
	Sludge = "Straight from the sewer, smells like a winner.",
	WarElephant = "Ran away from home after losing tug of war to rhino. Plans to go back to the meadow one day.",
	Leviathan = "Got upgraded from the ocean after it started breathing fire. Cousin of axalotl.",
	SoulHorse = "Very thoughtful, soul horse sends souls to his friends each year.",
	SnackYak = "A hungry yak tempted by carrots. Likes to snack on the go, can stampede for hours on end.",
	RoboShark = "Built a suit of robo-armor to escape the ocean. Can eat any and all animals.",
	Firebird = "Hatched in a volcano. Still thinks everything is food.",
	RockHog = "Ate a lava rock for a dare. Now its horns won't stop smoking.",
	Rockworm = "Tried burrowing through a volcano. Now it can't stop jumping out of the ground.",
	FireLobster = "Fell into a pot of boiling lava. Came out redder and angrier.",
	LavaWhale = "Swims through lava like it's bathwater. The horn is just for showing off.",
	TRex = "Tiny arms, huge attitude. Has never once managed to clap.",
	Raptor = "Never hunts alone. Never knocks, either: it opens doors.",
	Spinosaurus = "Built a sail on its back and still cannot sail. Fishes instead.",
	Pterodactyl = "Not technically a dinosaur. Please do not tell it, it is very proud.",
	Ankylosaurus = "Built like a tank, swings its tail like a hammer. Hugs are not recommended.",
	PalmGuy = "Thinks the Cactus is his long-lost cousin. The Cactus disagrees.",
	BoneRex = "Was a T-Rex once. Then it got angrier. Then it lost the skin.",
	Phoenix = "Burns up, crumbles to ash, hatches again. Has done it so many times it finds it boring.",
	VolcanoTortoise = "Fell asleep in the sun for three hundred years. Woke up as a volcano.",
	Loong = "The loongest dragon around. Ex sword-swallower for the circus, passionate about entertainment.",
}

local AnimalDex = {}

local gui, page, scale, grid, examine
local pop = 1 -- the page's pop in or out (ModalPop), times its fit to the screen
local resize
local open, shown -- the page is up; the animal being examined, its place in `order` (nil: the grid)
local animate -- the running animal's frame clock

local function rarityOf(kind)
	return require(Animals[kind]).Rarity
end

-- Every animal for the arrows: biome by biome, each biome's in rarity order
-- (cheapest first within one).
local order = {}
for _, biome in Config.Biomes do
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
	for _, kind in kinds do
		table.insert(order, { kind = kind, biome = biome.Name })
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

local showAnimal, arrow

-- An arrow either side of the animal (QM's page).
function arrow(position, turn, onClick)
	local a = Instance.new("ImageButton")
	a.BackgroundTransparency = 1
	a.AutoButtonColor = false
	a.Image = ARROW
	a.Rotation = turn
	a.AnchorPoint = Vector2.new(0.5, 0.5)
	a.Size = UDim2.fromOffset(ARROW_SIZE.X, ARROW_SIZE.Y)
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
	local seen = ridden()[kind]

	-- Between the arrows (QM's mockup), drawn over everything on the page.
	local run = image(page, "", UDim2.fromOffset(400, 400), UDim2.fromOffset(PAGE.X / 2, ARROW_AT[2] + 10), Vector2.new(0.5, 0.5))
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

	arrow(UDim2.fromOffset(ARROW_AT[1], ARROW_AT[2]), 180, function()
		Sounds.play("book_flip")
		showAnimal((at - 2) % #order + 1)
	end)
	arrow(UDim2.fromOffset(PAGE.X - ARROW_AT[1], ARROW_AT[2]), 0, function()
		Sounds.play("book_flip")
		showAnimal(at % #order + 1)
	end)
	-- A controller's LB / RB, under the arrows (on the page: the arrows are turned).
	Gamepad.hint(page, Enum.KeyCode.ButtonL1, Vector2.new(ARROW_AT[1] / PAGE.X, (ARROW_AT[2] + 70) / PAGE.Y), 80)
	Gamepad.hint(page, Enum.KeyCode.ButtonR1, Vector2.new((PAGE.X - ARROW_AT[1]) / PAGE.X, (ARROW_AT[2] + 70) / PAGE.Y), 80)

	-- The X, on the page's top right corner (QM's mockup).
	local close = Instance.new("ImageButton")
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Image = CLOSE
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Size = UDim2.fromOffset(96, 96)
	close.Position = UDim2.fromOffset(PAGE.X - 19, 71)
	close.ZIndex = 6
	close.Activated:Connect(function()
		AnimalDex.close()
	end)
	bouncy(close)
	close.Parent = page

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.FontFace = NAME_FONT
	name.TextSize = 52
	name.TextColor3 = if seen then Config.RarityColors[rarityOf(kind)] or Color3.new(1, 1, 1) else Color3.new(1, 1, 1) -- (its rarity's colour: QM)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.AnchorPoint = Vector2.new(0, 0.5)
	name.Position = UDim2.fromOffset(60, DIVIDER - 8)
	name.Size = UDim2.fromOffset(600, 70)
	name.Text = if seen then nameOf(kind) else "???"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = name
	name.Parent = page

	local bio = Instance.new("TextLabel")
	bio.BackgroundTransparency = 1
	bio.FontFace = BIO_FONT
	bio.TextSize = 38
	bio.TextColor3 = Color3.new(0, 0, 0)
	bio.TextTransparency = 0.5 -- QM: black at 50%, no outline
	bio.TextWrapped = true
	bio.TextXAlignment = Enum.TextXAlignment.Left
	bio.TextYAlignment = Enum.TextYAlignment.Top
	bio.Position = UDim2.fromOffset(64, DIVIDER + 45)
	bio.Size = UDim2.fromOffset(PAGE.X - 128, PAGE.Y - DIVIDER - 70)
	bio.Text = if seen then BIOS[kind] or PLACEHOLDER_BIO else "Ride creature to unlock!" -- QM
	bio.Parent = page
end

-- It pops in and out (ModalPop), hiding (and clearing) once it has shrunk away.
local function setPop(scale)
	pop = scale
	resize()
end

function AnimalDex.toggle(instant)
	open = not open
	if open then
		gui.Enabled = true
		local horse = 1 -- the Horse first, every time (QM)
		for at, entry in order do
			if entry.kind == "Horse" then
				horse = at
				break
			end
		end
		if order[horse] then
			showAnimal(horse)
		end
		ModalPop.open(setPop)
		Gamepad.openMenu("Pets", {
			close = AnimalDex.close,
			keys = {
				[Enum.KeyCode.ButtonL1] = function()
					if shown then
						Sounds.play("book_flip")
						showAnimal((shown - 2) % #order + 1)
					end
				end,
				[Enum.KeyCode.ButtonR1] = function()
					if shown then
						Sounds.play("book_flip")
						showAnimal(shown % #order + 1)
					end
				end,
			},
		})
	else
		Gamepad.closeMenu("Pets")
		ModalPop.close(setPop, function()
			gui.Enabled = false
			clear()
		end, instant)
	end
	if AnimalDex.onToggle then
		AnimalDex.onToggle(open)
	end
end

function AnimalDex.isOpen()
	return open == true
end

function AnimalDex.close(instant)
	if open then
		AnimalDex.toggle(instant)
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
backdrop.Selectable = false -- (never a controller's pick)
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
page.Image = PANEL
scale = Instance.new("UIScale")
scale.Parent = page
page.Parent = gui
local camera = workspace.CurrentCamera
function resize()
	local screen = camera.ViewportSize
	scale.Scale = math.min(screen.X * SCREEN_SHARE / PAGE.X, screen.Y * 0.8 / PAGE.Y) * pop
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
	end
end)

-- Load the art ahead and keep it loaded: every page and sprite sheet is
-- drawn all the time (1 px, nearly see-through, on a screen of its own that's
-- always on), so nothing pops in blank or plays choppy the first time it's seen.
-- PreloadAsync alone left the sheets to load as they first played.
do
	local ids = { PANEL, ARROW, CLOSE }
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
