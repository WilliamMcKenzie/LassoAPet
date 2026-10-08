-- Tuning values shared by the map, the live colours and the ride.
return {
	-- false hides every UI element (HUD, coins, Roblox menus, the ride prompt), e.g. for mockup screenshots.
	ShowHud = true,
	HudScale = 1, -- multiplies the whole HUD's size; 1 matches QM's mockups
	TakeEggSunburst = true, -- turning sunburst behind the TAKE EGG button (trial)

	-- World (studs). The map is the saved model src/world/World.rbxmx; these sizes
	-- must match it (the ride reads them). Ground and wall colours are calibrated so
	-- they render like the Steal an Egg reference under the Lighting set in
	-- default.project.json. Home is z > 0, the course runs toward -z.
	-- The course is biomes end to end from the start line, each Length studs long,
	-- with its own tile colours. The home base uses the first biome's. Any Nest
	-- model in World.Nests is an egg spawn of the biome it stands in (NestOdds).
	Biomes = {
		{
			Name = "Meadow",
			Swerve = 1, -- how much the stampede swerves out of your way on the ride home: ReturnAvoid's Clear and Chance x this (QM, Oct 6: full in the Meadow, less each zone, none in the Godlands)
			Length = 760,
			GroundColors = { Color3.fromRGB(77, 196, 63), Color3.fromRGB(105, 255, 74) },
			WallColors = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
			-- Which animals run in this biome's stampede and how often (names are modules
			-- in Shared/Animals). QM's spawn table (Oct 3): chances out of 1. They're
			-- weights, so a biome that doesn't add up to exactly 1 still works. Nest eggs
			-- use the same odds (NestOdds). A 0 never spawns but keeps the animal on
			-- the biome's page in the animal dictionary. No Common animal runs wild (QM,
			-- Oct 6: no Common eggs): the Horse is only ever the pet you start with.
			Herd = { Horse = 0, Pinto = 0.35, Pig = 0.25, Bunny = 0.25, Fish = 0.22, Rhino = 0.13, Unicorn = 0.05 },
			-- Dirt patches in the walls' colours, a stud below the grass
			-- (tools/meadow_ground.py); see the Desert's Patches.
			Patches = {
				Dirt = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
			},
		},
		{
			Name = "Desert",
			Swerve = 0.75,
			NestScale = 2, -- its nests are this many times bigger, so they show from afar at its speed (Nests.server; QM, Oct 6)
			Length = 2280, -- 3x the meadow (QM)
			GroundColors = { Color3.fromRGB(232, 188, 102), Color3.fromRGB(250, 214, 130) },
			WallColors = { Color3.fromRGB(206, 118, 72), Color3.fromRGB(226, 138, 88) },
			Herd = { Cactus = 0.3, Kitten = 0.25, Scorpion = 0.25, Sandworm = 0.2, SpineLizard = 0.2, Snake = 0.05 },
			-- Patches of other ground in the floor (parts named after them in
			-- World.Ground, laid out by tools/desert_ground.py): dry grass flush with
			-- the sand, sandstone a stud higher. Checker colours, like GroundColors.
			Patches = {
				Grass = { Color3.fromRGB(184, 172, 70), Color3.fromRGB(200, 188, 86) },
				Stone = { Color3.fromRGB(206, 146, 84), Color3.fromRGB(222, 164, 100) },
			},
			-- Locked behind a gate until your pen is this biome's level (its place
			-- in this list). Upgrading your pen to it costs UnlockCost gold; your pen's
			-- floor tiles take this biome's ground colours and its posts PostColor.
			UnlockCost = 500, -- balance pass (Oct 6): was $1k; most new players quit before reaching it
			PostColor = Color3.fromRGB(206, 118, 72),
			GateImage = "rbxassetid://113778810800288", -- assets/ui/GateDesert.png ("Zone Locked")
			GateColor = Color3.fromRGB(255, 204, 40), -- the gate's glow at this biome's line: desert yellow
			-- Upgrade Pen while this is the next biome to unlock (its price is drawn in).
			UpgradeImage = "rbxassetid://115511110106388", -- assets/ui/UpgradePenDesert.png
			UpgradeImageDisabled = "rbxassetid://82534446488604", -- assets/ui/UpgradePenDesertDisabled.png: while you can't afford it
		},
		{
			Name = "Snow",
			Swerve = 0.5,
			NestScale = 2.25,
			Length = 5472, -- 3x the desert, then 0.8x (QM, Oct 2)
			GroundColors = { Color3.fromRGB(228, 234, 242), Color3.fromRGB(244, 247, 251) },
			WallColors = { Color3.fromRGB(126, 164, 214), Color3.fromRGB(146, 182, 228) },
			Herd = { Penguin = 0.3, Boar = 0.25, Snowman = 0.22, IceGolem = 0.12, SnackYak = 0, Icebringer = 0.06 }, -- the Snack Yak never spawns: a Robux exclusive (QM, Oct 4)
			-- tools/snow_ground.py: cold grass a stud above the snow, ice ponds a stud below.
			Patches = {
				Grass = { Color3.fromRGB(80, 160, 166), Color3.fromRGB(96, 176, 180) },
				Ice = { Color3.fromRGB(160, 188, 244), Color3.fromRGB(178, 202, 250) },
			},
			UnlockCost = 150000, -- QM, Oct 7: the Tundra took too long to reach, "shorten it a BIT" (balance pass Oct 6 had it $300k, before that $100k)
			PostColor = Color3.fromRGB(126, 164, 214),
			GateImage = "rbxassetid://93384010922515", -- assets/ui/GateTundra.png
			GateColor = Color3.fromRGB(70, 220, 255), -- cyan (QM)
			UpgradeImage = "rbxassetid://100202451134816", -- assets/ui/UpgradePenTundra.png ($150k)
			UpgradeImageDisabled = "rbxassetid://84089158899976", -- assets/ui/UpgradePenTundraDisabled.png ($150k)
		},
		{
			Name = "Ocean",
			Swerve = 0.25,
			NestScale = 2.5,
			Length = 7680, -- 1.4x the snow (QM, Oct 2), a whole number of 240-stud depth bands
			GroundColors = { Color3.fromRGB(236, 214, 164), Color3.fromRGB(246, 228, 184) },
			WallColors = { Color3.fromRGB(236, 140, 124), Color3.fromRGB(250, 160, 142) }, -- salmon coral (QM)
			-- The Fish is a placeholder until the rest of the ocean animals are designed.
			Herd = { Fish = 0, Starfish = 0.3, Whale = 0.15, Squid = 0.2, KingCrab = 0.15, FishSchool = 0.15, BlueCrab = 0.05, RoboShark = 0, Kraken = 0.05 }, -- (Blue Crab guessed like the Kraken; the Robo Shark never spawns: a future Robux pet, QM Oct 4)
			-- tools/ocean_ground.py: seagrass a stud above the sand, trenches a stud below.
			Patches = {
				Grass = { Color3.fromRGB(64, 178, 122), Color3.fromRGB(80, 196, 138) },
				Trench = { Color3.fromRGB(70, 150, 214), Color3.fromRGB(86, 166, 228) },
				Lava = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- Neon (WorldColors keeps the textures off its glow)
			},
			-- It gets darker the further you ride (QM, Oct 2; bluer and a little brighter, Oct 6): coral reef, sand flats,
			-- dark rock with the first lava, volcanic abyss. At is the fraction of the
			-- way along; the floor, walls and haze blend between these stops (the floor
			-- and walls step every 240 studs, tools/ocean_ground.py BAND). Where a stop
			-- has a colour, it wins over the GroundA/WallA... attributes above.
			Depths = {
				{
					At = 0,
					Ground = { Color3.fromRGB(236, 214, 164), Color3.fromRGB(246, 228, 184) },
					Grass = { Color3.fromRGB(64, 178, 122), Color3.fromRGB(80, 196, 138) },
					Trench = { Color3.fromRGB(60, 156, 232), Color3.fromRGB(76, 172, 244) },
					Wall = { Color3.fromRGB(236, 140, 124), Color3.fromRGB(250, 160, 142) },
					Haze = Color3.fromRGB(56, 160, 245),
					Tint = Color3.fromRGB(214, 236, 255),
				},
				{
					At = 0.33,
					Ground = { Color3.fromRGB(222, 196, 150), Color3.fromRGB(234, 210, 166) },
					Grass = { Color3.fromRGB(76, 150, 112), Color3.fromRGB(90, 164, 124) },
					Trench = { Color3.fromRGB(52, 132, 212), Color3.fromRGB(66, 146, 226) },
					Wall = { Color3.fromRGB(196, 150, 140), Color3.fromRGB(212, 166, 154) },
					Haze = Color3.fromRGB(42, 124, 220),
					Tint = Color3.fromRGB(205, 224, 250),
				},
				{
					At = 0.55,
					Ground = { Color3.fromRGB(132, 150, 176), Color3.fromRGB(146, 164, 190) },
					Grass = { Color3.fromRGB(70, 96, 124), Color3.fromRGB(82, 108, 136) },
					Trench = { Color3.fromRGB(44, 92, 170), Color3.fromRGB(54, 104, 184) },
					Wall = { Color3.fromRGB(100, 118, 156), Color3.fromRGB(116, 134, 172) },
					Haze = Color3.fromRGB(36, 96, 190),
					Tint = Color3.fromRGB(196, 214, 245),
				},
				{
					At = 0.75,
					Ground = { Color3.fromRGB(82, 104, 140), Color3.fromRGB(96, 118, 154) },
					Grass = { Color3.fromRGB(56, 76, 108), Color3.fromRGB(66, 88, 120) },
					Trench = { Color3.fromRGB(34, 62, 130), Color3.fromRGB(44, 74, 142) },
					Wall = { Color3.fromRGB(64, 86, 128), Color3.fromRGB(78, 100, 142) },
					Haze = Color3.fromRGB(28, 70, 160),
					Tint = Color3.fromRGB(188, 200, 240),
				},
				{
					At = 1,
					Ground = { Color3.fromRGB(46, 58, 92), Color3.fromRGB(58, 70, 104) },
					Grass = { Color3.fromRGB(34, 44, 70), Color3.fromRGB(44, 54, 80) },
					Trench = { Color3.fromRGB(28, 40, 90), Color3.fromRGB(38, 50, 100) },
					Wall = { Color3.fromRGB(36, 46, 80), Color3.fromRGB(48, 58, 92) },
					Haze = Color3.fromRGB(20, 36, 100),
					Tint = Color3.fromRGB(176, 180, 230),
				},
			},
			UnlockCost = 5000000, -- QM, Oct 7: halved with the Tundra's ("same with ocean/godlands"); balance pass Oct 6 had it $10M, before that $1M
			PostColor = Color3.fromRGB(236, 140, 124),
			GateImage = "rbxassetid://75356296124042", -- assets/ui/GateOcean.png
			GateColor = Color3.fromRGB(30, 80, 220), -- deep blue (QM)
			UpgradeImage = "rbxassetid://120593568705149", -- assets/ui/UpgradePenOcean.png (QM's Oct 7 art, now $5m)
			UpgradeImageDisabled = "rbxassetid://126023633689709", -- assets/ui/UpgradePenOceanDisabled.png ($5m)
			-- Under the sea (Ocean.client): while you're in this biome the distance
			-- fades into Haze.Color and bubbles drift up round the camera.
			Haze = {
				Color = Color3.fromRGB(60, 150, 235),
				Density = 0.45, -- Atmosphere.Density
				Tint = Color3.fromRGB(200, 228, 255), -- ColorCorrection.TintColor
				FadeTime = 1.5, -- seconds to sink into it or come out of it
				Bubbles = 24, -- per second
			},
		},
		-- (Off for a while on Oct 4, back the same night as the endless endgame, QM.)
		{
			-- The endgame (QM, Oct 3), after Realm of the Mad God's godlands: dark stone
			-- plates split by snow, with ice or lava cracks. It never ends: one 960-stud
			-- track after another, each picked at random from four (two with ice, two
			-- with lava; Shared/Godlands, Shared/GodlandsTracks), built round each rider
			-- as they go (Client/GodlandsStream). It has no finish line.
			Name = "Godlands",
			Swerve = 0,
			NestScale = 2.5,
			Length = math.huge, -- endless
			GroundColors = { Color3.fromRGB(208, 212, 224), Color3.fromRGB(224, 228, 238) }, -- grey snow
			WallColors = { Color3.fromRGB(48, 46, 58), Color3.fromRGB(62, 60, 74) }, -- dark stone (snow caps)
			-- Its own animals now; the Fish that stood in are gone (QM, Oct 4). (The Loong is
			-- an event and roll exclusive, so it doesn't run here.) PlaceholderHerd keeps it
			-- out of the finish line's egg odds (Hatchery).
			Herd = { Beholder = 0.1, WarElephant = 1, SoulHorse = 0.5, Sludge = 0.5, Leviathan = 0.1 }, -- its own animals, no Fish (QM, Oct 4; weights are guesses)
			-- Its nests' eggs (Nests.server: one nest a track, near the riders) get rarer the
			-- deeper in you are (QM, Oct 4), each tier's pool split evenly: at its line only
			-- Rares; the Epic chance grows from 0 to Epic.Max over the first Epic.Over
			-- studs; past Legendary.From studs the Legendary chance grows to Legendary.Max
			-- over Legendary.Over studs, then holds. The rest is Rares.
			NestDepth = {
				Rare = { "Beholder", "Sludge", "WarElephant" },
				Epic = { Pool = { "Leviathan", "SoulHorse" }, Max = 0.4, Over = 5000 },
				Legendary = { Pool = { "Unicorn", "Snake", "Icebringer", "Kraken", "BlueCrab" }, From = 5000, Max = 0.1, Over = 5000 },
			},
			PlaceholderHerd = true,
			HerdThin = 2, -- only every 2nd of the stampede's spawns runs here: half as many animals (QM, Oct 4)
			Patches = {
				Stone = { Color3.fromRGB(62, 60, 72), Color3.fromRGB(76, 74, 88) }, -- a stud up
				Ice = { Color3.fromRGB(170, 196, 250), Color3.fromRGB(184, 208, 252) },
				Lava = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- Neon
			},
			UnlockCost = 150000000, -- QM, Oct 7: halved with the Tundra's; balance pass Oct 6 had it $300M, before that $10M (a guess). The Badlands (PR #154) would sit at about $50M
			PostColor = Color3.fromRGB(62, 60, 72),
			GateColor = Color3.fromRGB(255, 72, 0), -- lava orange
			GateImage = "rbxassetid://81079145393331", -- assets/ui/GateGodlands.png
			UpgradeImage = "rbxassetid://138868721056257", -- assets/ui/UpgradePenGodlands.png ($150m)
			UpgradeImageDisabled = "rbxassetid://111144732532154", -- assets/ui/UpgradePenGodlandsDisabled.png ($150m)
		},
	},
	-- The gate across the corridor at a locked biome's line: its colour (the biome's GateColor, else this one) at the floor
	-- fading to clear this many studs up. Only you see it, until you unlock it.
	-- Zone gates on? Off (QM, Oct 8: new-loops): ride anywhere, no gates, no Upgrade Pen
	-- button, no tutorial flight to the next gate. PenLevel still loads and saves as before.
	Gates = false,
	GateHeight = 26,
	GateColor = Color3.fromRGB(255, 204, 40),
	-- The course is a funnel (QM, Oct 8): CourseHalfWidth at the start line, each wall
	-- angled out CourseWidening studs per stud of course (one straight line), up to
	-- CourseMaxHalfWidth (reached at the Godlands line, which keeps that width). Full
	-- widths: Meadow 112-120, Desert 120-142, Snow 142-197, Ocean 197-274, Godlands 274.
	-- WorldColors.halfWidth(z) is the width at z. The place's walls, ground, obstacles
	-- and nests are moved to it by tools/funnel.luau (re-run it after a World push).
	CourseHalfWidth = 56,
	CourseWidening = 0.005,
	CourseMaxHalfWidth = 137,
	CourseLength = math.huge, -- all the biomes' lengths added up: endless, with the Godlands last
	HomeHalfWidth = 144, -- tools/pens.py HALF_W: the base grew to fit the bigger pens (QM, Oct 3)
	HomeDepth = 144, -- tools/pens.py DEPTH: the base runs this far back from the start line to its back wall
	StarterSpot = Vector3.new(0, 0, 20), -- where you start without a pen (players past the fifth)

	-- Ride
	MountSpeed = 44,
	ReturnSpeed = 40,
	SteerSpeed = 28,
	SteerResponse = 8,
	HoldTime = 6,
	TerrainSaturation = 1, -- x the ground's, floor tiles' and walls' colour saturation (WorldColors.saturate): 1 leaves them as they are (QM, Oct 6: tried 1.15 and 1.05, back to the original)
	-- Studs as a material (QM, Oct 7, FPS): parts get the "Studs" (1 stud) or "StudsHalf"
	-- (0.5 stud) MaterialVariant from MaterialService instead of a stud Texture per face,
	-- which cut tens of thousands of textures. Off (or those variants missing from
	-- MaterialService): the stud Textures as before. Shared/Studs.
	StudMaterial = true,
	Sky = "Anime", -- "Anime" (the Creator Store's Anime sky, QM Oct 6; tried Flat again and kept Anime) or "Flat" (one flat #59D9FD): World.server
	WalkSpeed = 32, -- on foot, studs a second (Roblox's default is 16; QM, Oct 6: 2x, walking round took too long)
	HomeSafeZone = 40, -- studs before the start line where a rider bringing an egg home can't be crashed: an animal popping in as they cross felt like bad faith (QM, Oct 6)
	TiredSpeed = 0.5, -- x speed once the Hold bar's empty: no more bucking off (QM, Oct 5)
	-- On the ride home with an egg the stampede gets out of your way (QM, Oct 6, to
	-- test: dodging home lost new players): an animal heading into you swerves aside
	-- late, Warn seconds before it would hit, so it still looks like a near miss. It
	-- eases across, turning that way, to Clear studs to the side of you (a crash is
	-- within 2.6) over up to Ease seconds, never faster than MaxSpeed studs/s, then
	-- keeps that line till you're past. Only Chance of them swerve at all, so dodging
	-- still counts. On = false turns it off.
	-- Turn: a swerve's top sideways speed, x the animal's own running speed (QM: slower
	-- animals swerve slower); slow ones start earlier than Warn to make it in time.
	ReturnAvoid = { On = true, Warn = 1.6, Clear = 17, Turn = 0.6, MaxSpeed = 140, Chance = 0.9 }, -- (QM Oct 6: was 0.4 s / 5 studs / 0.85, too easy to crash; Warn doubled from 0.8; Clear 9 -> 80 -> 20 -> 14 -> 17)
	-- Egg nests are always stocked, and their eggs are yours alone (QM, Oct 6: no
	-- shared stock, nothing to restock): each ride they're rolled afresh for you from
	-- the nest's biome's Herd odds (NestOdds); Common animals are the ones you get by
	-- default, so their eggs never show up. But the egg you take is the animal you're
	-- riding (QM, Oct 6: lassoing is hunting): once you've lassoed a wild animal the
	-- nests of its own biome (the one whose Herd runs it) show its egg, swapping with
	-- a bounce on every hop; nests anywhere else keep their rolled eggs (QM, Oct 7: no
	-- Snake eggs in the Tundra, no Kraken eggs in the Meadow on the ride home). An
	-- event's animal runs in no biome, so its egg is everywhere (finding and riding
	-- one is the hard part). The rolled egg is what you get on your own pet (so your
	-- best pet never copies itself).
	-- Rare, Epic and Legendary eggs get likelier the further into its biome a nest is
	-- (QM, Oct 6: going further should pay): their odds x Near at the biome's start
	-- line, rising evenly to x Far at its end, so a biome's average stays about the
	-- same. Common and Uncommon eggs keep their odds. Not the Godlands (its NestDepth).
	NestDepthOdds = { Near = 0.5, Far = 1.5 },
	-- Exclusive animal events (Events.server, QM Oct 4): every Cycle seconds one of
	-- the Animals, picked at random, pops in at the start line Countdown seconds after
	-- it's picked (the clients build it meanwhile) and runs off with the stampede to
	-- the finish line. Nothing announces it (QM, Oct 6: no banner, sound or arrows; the
	-- hard part is finding and riding it in the wild): lasso it and the nests give its
	-- egg, like any wild animal's. The event's over once someone's riding it, it's run
	-- off the course, or the next one's due.
	Events = {
		Animals = { "Loong", "SnackYak", "RoboShark" },
		Countdown = 10,
		Cycle = 600, -- seconds from one event to the next (QM: every 10 minutes)
	},
	-- Any pet can be ridden. Until pets can be picked in the pen, you ride this one
	-- (it waits on the first pet spot in your pen).
	DefaultPet = "Horse",
	-- Seconds an egg placed in your pen takes to hatch: PetHatchTime by the animal
	-- inside (QM's pets JSON, Oct 4), else HatchTime by its rarity.
	HatchTime = { Uncommon = 15, Rare = 45, Epic = 120, Legendary = 300 },
	PetHatchTime = {
		-- Balance pass (Oct 6): QM's pets JSON times, x1 in the Meadow (the first eggs stay quick),
		-- x2 Desert, x4 Tundra, x6 Ocean, x8 Godlands; the exclusives 1 h / 16 h / 24 h. Eggs hatch
		-- while you're offline, so long ones bring players back (Steal an Egg goes up to 12-36 h).
		Horse = 15, Pig = 15, Bunny = 15, Pinto = 15, Fish = 45, Rhino = 120, Unicorn = 300, -- Meadow
		Cactus = 60, Kitten = 60, Scorpion = 180, Sandworm = 420, SpineLizard = 600, Snake = 1200, -- Desert
		Penguin = 120, Boar = 180, Snowman = 480, IceGolem = 1440, Icebringer = 7200, -- Tundra
		Starfish = 90, Whale = 21600, Squid = 5400, FishSchool = 4000, KingCrab = 7200, BlueCrab = 18000, Kraken = 20000, -- Ocean
		Beholder = 5400, Sludge = 4800, WarElephant = 7200, Leviathan = 14400, SoulHorse = 19200, -- Godlands
		SnackYak = 3600, RoboShark = 57600, Loong = 86400, -- exclusives
	},
	-- The first-time tutorial (Tutorial.luau): a new player places their first egg
	-- (a DefaultPet egg, hatching in TutorialHatchTime seconds), rides that pet and
	-- brings home an egg, one hint at a time and only the buttons each step needs.
	-- false turns it off. On that first ride the stampede runs on the player's own
	-- clock so it can slow down to TutorialSlowMo x speed, and ever slower from there
	-- (TutorialSlowDeepen), while LASSO or TAKE EGG is waiting to be pressed, and the
	-- Hold bar never runs out. The tutorial's eggs hatch by themselves
	-- (TutorialHatchTime); every other egg waits for you to hold F by it once it's
	-- ready (Hatchery, Pen.client).
	Tutorial = true,
	TutorialHatchTime = 0,
	TutorialSlowMo = 0.2,
	-- Seconds of waiting for that press before time runs at a quarter of TutorialSlowMo;
	-- it keeps slowing (x 1 / (1 + waited / this)^2) till the press, so the stampede all
	-- but stops and the egg can't be outrun (QM, Oct 7: it was, into the Desert gate).
	TutorialSlowDeepen = 1,
	-- Pet abilities: the Ability button (bottom right while riding), Q or R1.
	-- A pet without an entry has no button. Seconds throughout.
	--   Charge (Rhino): one tap, for Duration: a battering ram at SpeedBoost x speed.
	--     No Hold drain, and every obstacle and animal in the way is knocked flying,
	--     whatever its size. Wind breaks round its head and the camera pulls back.
	--     With UntilFull (Snack Yak) it has no Duration: while it charges the Hold bar
	--     refills, as fast as it usually drains, and the charge ends once the bar is
	--     full. It can't start on a full bar.
	--   Leap (Unicorn): one tap: a gallop up into the air and down again in an arc
	--     LeapHeight studs high, over everything, at SpeedBoost x speed with no Hold drain,
	--     leaving a rainbow trail.
	--   Rattle (Snake): one tap: it stops, coils up and rattles for Duration (its
	--     coiled idle). Once the rattle's over (QM, Oct 4) every obstacle within
	--     Radius studs is smashed, and for ScareTime seconds every animal that comes
	--     within Radius is scared off, each one refilling RestorePer of the Hold bar
	--     (once). No Hold drain while it rattles; a yellow-orange haze closes in round the screen.
	--   Frost (Icebringer): one tap: a blizzard bursts out round it and every animal
	--     within Radius studs (but itself) runs Slow slower (0.7 = 70%) until Duration
	--     is up, frosted over. Unlike the others it doesn't stop the Hold bar or crashes.
	--   Boost (Spine Lizard): SpeedBoost x speed for Duration.
	--   Grow (Ice Golem): it swells to size tier Tier (XL) for Duration at SpeedBoost x
	--     speed, plowing through whatever's smaller.
	--   Ink (Squid): a cloud of ink bursts out and every animal within Radius scatters
	--     away from it while it lasts.
	--   Crabwalk (King Crab): it grows to size tier Tier (large) and scuttles sideways
	--     at SpeedBoost x speed for Duration.
	--   Shield (Blue Crab, QM Oct 4): one tap summons Crabs King Crabs Ahead studs in
	--     front of it, Spread studs apart, marching along with it for Life seconds. Each
	--     one soaks one hit: the first animal to run into it is knocked flying and that
	--     crab is gone.
	--   Feast (unused now; was the Blue Crab's): one tap cashes in everything it broke since the last Feast:
	--     for each, Heal of the Hold bar back, and it grows Grow x bigger and runs
	--     SpeedUp x faster for the rest of the ride, up to Max x its own size and speed
	--     (a size TierGrowth x bigger counts as a size tier up).
	--   Wave (School of Fish): a wall of fish rushes up from behind across the whole
	--     course, overtakes it and races on ahead for Duration, and every obstacle and
	--     animal it passes goes flying, whatever its size; then the fish dive away
	--     (client/FishWave.luau). Nothing crashes the school while it runs.
	--   Breath (Loong): it plays its fire breath ("special") and, from FireFrom to FireTo
	--     seconds in, everything in a Width-stud lane Range studs ahead is burnt away:
	--     obstacles smashed, animals flung, whatever their size, aimed at the mouse. Each
	--     animal it burns refills RestorePer of the Hold bar and makes it Grow x bigger and
	--     SpeedUp x faster for the rest of the ride, up to size tier MaxTier and MaxSpeed x
	--     its own speed (QM, Oct 4: it starts small and slow, as the Robo Shark does).
	--   Hunt (Robo Shark, QM Oct 4): for Duration seconds it hunts on its own (you lose
	--     the steering or Sprint): it goes at SpeedBoost x speed (QM: 0.8x) at the nearest animal and eats
	--     it, then the next. Each one eaten makes it Grow x bigger and SpeedUp x faster (up to MaxSpeed x) for
	--     the rest of the ride and refills RestorePer of the Hold bar. It starts small and
	--     grows a size tier every TierGrowth x, stopping at MaxTier (XL). While it hunts
	--     (Once, the Leviathan: no Duration; it hunts one animal, however long that takes,
	--     and stops once it's eaten it. Its speed climbs steadily from SpeedBoost x to
	--     MaxBoost x over RampTime seconds.)
	--     the guide arrows lead to its prey, and nothing can crash it.
	--   Missiles (unused now; was the Robo Shark's): two missiles fly out from its sides straight ahead for
	--     Duration, smashing every obstacle and knocking away every animal within Radius
	--     of their lanes, whatever its size (client/Missiles.luau; Spread and Size are in
	--     its model studs). Every launch refills Restore of the Hold bar (QM: 10%).
	-- Boost, Grow, Ink, Crabwalk, Breath and Missiles, like Frost, still use Hold and can crash.
	--   Devour (Kraken, QM Oct 4): one tap: it stops dead and its tentacles reach out to
	--     up to Max animals of size tier MaxTier or smaller within Radius studs, reeling
	--     each one in over PullTime seconds and eating it, each one refilling RestorePer
	--     of the Hold bar. Nothing can crash it while it feeds. TentacleColor (default navy)
	--     and Mouth (studs up its tentacles start from, default 3) are optional.
	-- Charge swings the camera round to a cinematic front-side angle.
	-- (QM, Oct 2: the cooldowns, durations and radii QM didn't give are guesses.)
	Abilities = {
		Rhino = { Kind = "Charge", Duration = 4, Cooldown = 7, SpeedBoost = 1.2 },
		SnackYak = { Kind = "Charge", UntilFull = true, Cooldown = 5, SpeedBoost = 2 }, -- QM, Oct 4
		Unicorn = { Kind = "Leap", Duration = 3, Cooldown = 8, SpeedBoost = 1.4, LeapHeight = 56 },
		Snake = { Kind = "Rattle", Duration = 2.4, Cooldown = 10, Radius = 45, ScareTime = 10, RestorePer = 0.1 }, -- QM, Oct 4
		Kraken = { Kind = "Devour", Duration = 1.4, Cooldown = 6, Radius = 50, Max = 8, MaxTier = 2, PullTime = 0.7, RestorePer = 0.2, Hop = 6 }, -- QM, Oct 4 (radius a guess)
		Icebringer = { Kind = "Frost", Duration = 4, Cooldown = 8, Radius = 50, Slow = 0.7, RestorePer = 0.03 }, -- 3% Hold per animal frozen (QM, Oct 4)
		SpineLizard = { Kind = "Boost", Duration = 5, Cooldown = 8, SpeedBoost = 2 },
		IceGolem = { Kind = "Grow", Duration = 5, Cooldown = 10, SpeedBoost = 1.2, Tier = 4 },
		Squid = { Kind = "Ink", Duration = 2.5, Cooldown = 8, Radius = 45 },
		KingCrab = { Kind = "Crabwalk", Duration = 4, Cooldown = 8, SpeedBoost = 2, Tier = 3 },
		BlueCrab = { Kind = "Shield", Duration = 0.6, Cooldown = 15, Crabs = 3, Ahead = 22, Spread = 11, Life = 15, Radius = 5 }, -- QM, Oct 4 (cooldown and life are guesses)
		FishSchool = { Kind = "Wave", Duration = 4, Cooldown = 10 },
		SoulHorse = { Kind = "Spikes", Duration = 1.5, Cooldown = 10, Radius = 45, Count = 28, RestorePer = 0.1 }, -- QM, Oct 4: 10% Hold per kill (duration, cooldown, radius guesses)
		-- the animation's length and fire window; the range, width and cooldown are guesses
		RoboShark = { Kind = "Hunt", Duration = 3, Cooldown = 8, SpeedBoost = 0.8, Grow = 1.1, SpeedUp = 1.05, MaxSpeed = 2.5, RestorePer = 0.3, MaxTier = 4 }, -- QM, Oct 4 (cooldown and charge speed are guesses)
		-- QM, Oct 4: one animal, however long it takes, speeding up from 1x to MaxBoost x over RampTime s
		Leviathan = { Kind = "Hunt", Once = true, Cooldown = 5, SpeedBoost = 1, MaxBoost = 8, RampTime = 10, RestorePer = 0.2, Grow = 1, SpeedUp = 1, MaxTier = 2 },
		Loong = { Kind = "Breath", Duration = 4.2, FireFrom = 0.95, FireTo = 3.95, Cooldown = 8, Range = 140, Width = 22, Crawl = 0.15, RestorePer = 0.1, Grow = 1.1, SpeedUp = 1.1, MaxSpeed = 2, MaxTier = 4 }, -- (MaxSpeed: x its 0.5x speed, so up to 1x)
	},
	-- Special sprints: what holding Sprint does for these pets on the way out (not the
	-- automatic sprint home with the egg). Like any sprint they drain Hold faster.
	--   Smash (Unicorn): every obstacle within Radius studs is smashed, whatever its size.
	--   Burrow (Sandworm): it dives underground and passes under everything; dirt sprays
	--     up where it is.
	--   Ram (Icebringer): the Rhino's charge wind, and it breaks every obstacle it hits.
	--   Fly (Whale): it rises Height studs into the air, over everything.
	--   Trample (Kraken): animals smaller than tier BelowTier it runs into are thrown
	--     up and away, as when a bigger pet runs into them racing home.
	--   Crabwalk (Blue Crab): it scuttles sideways at SpeedBoost x its sprint speed with
	--     the Icebringer's wind, breaking every obstacle and knocking every animal in
	--     its path, whatever its size.
	--   Loom (Loong): it swells to Grow x its size (a look only: its tier stays) and the
	--     animals within Radius studs scatter away from it.
	--   Flame (Leviathan): a flamethrower, the Loong's fire straight ahead: every obstacle
	--     and animal within Range studs of its mouth (Width wide) is burnt away, whatever
	--     its size.
	--   Goo (Sludge): it lays the wild Sludge's sludge behind it; stampede animals that
	--     run into it are stuck, crawling, for a moment (Client/GodlandsHazards).
	--   SpikeTrail (Soul Horse): it leaves the wild Soul Horse's spikes behind it; stampede
	--     animals that run into one are killed, whatever their size (they never crash you).
	-- OnReturn (QM, Oct 4): the special also runs on the ride home with the egg, which
	-- is always a sprint (ReturnSprint).
	SprintSpecials = {
		Unicorn = { Kind = "Smash", Radius = 14, ScareRadius = 30, RestorePer = 0.02, OnReturn = true }, -- scares animals within ScareRadius off, 2% Hold each (QM, Oct 4)
		Sandworm = { Kind = "Burrow", OnReturn = true },
		Whale = { Kind = "Fly", Height = 56 },
		-- The Beholder (QM, Oct 4; it has no ability): floats up over everything like the
		-- Whale, a pink haze round the screen, and scares the animals round it off.
		Beholder = { Kind = "Fly", Height = 24, ScareRadius = 30, Haze = Color3.fromRGB(255, 110, 210) }, -- height and radius are guesses
		Leviathan = { Kind = "Flame", Range = 5, Width = 9, OnReturn = true }, -- QM, Oct 4: "like 1m ahead" (4 studs a metre; the width is a guess)
		Loong = { Kind = "Loom", Grow = 1.2, Radius = 40 }, -- QM: 1.2x; the radius is a guess
		SoulHorse = { Kind = "SpikeTrail" }, -- QM, Oct 4: the wild Soul Horse's spike trail behind it; stampede animals that run into a spike are killed (Client/GodlandsHazards)
		Sludge = { Kind = "Goo", OnReturn = true }, -- QM, Oct 4: the wild Sludge's sludge trail; stampede animals that run into it get stuck and fall behind (Client/GodlandsHazards)
		BlueCrab = { Kind = "Crabwalk", SpeedBoost = 1.2, OnReturn = true, RestorePer = 0.2 }, -- QM, Oct 4: 20% Hold per animal it hits
	},
	-- Size tiers (any whole number, bigger is bigger). Racing home, a pet plows
	-- through stampede animals of a lower tier; one of its own tier or higher
	-- crashes it. Obstacles never crash you: every one is smashed on contact (QM,
	-- Oct 6); their tier (model "Tier" attribute, else ObstacleTiers by name) only
	-- decides which ones some abilities break.
	PetTiers = {
		Horse = 1, Pig = 1, Bunny = 1, Pinto = 1, Fish = 1, Rhino = 2, Unicorn = 2, -- Meadow
		Cactus = 1, Kitten = 1, Scorpion = 1, Sandworm = 2, SpineLizard = 2, Snake = 3, -- Desert
		Penguin = 1, Boar = 1, Snowman = 1, IceGolem = 2, SnackYak = 2, Icebringer = 3, -- Tundra
		Starfish = 1, Squid = 2, KingCrab = 2, FishSchool = 2, BlueCrab = 2, RoboShark = 1, Whale = 4, Kraken = 4, -- Ocean (the Robo Shark starts small and grows as it hunts)
		WarElephant = 3, SoulHorse = 2, -- Godlands (QM: large, medium)
		Loong = 1, Beholder = 2, Sludge = 2, Leviathan = 2, -- Godlands (starts small, grows to XL as its breath burns animals: Abilities.Loong)
	},
	-- Eggs are this much bigger per tier above small, like their animals: 1x small,
	-- 1.5x medium, 2.25x large, 3.4x XL (QM, Oct 4: was 1.2x per tier; Eggs/Egg.luau).
	EggSizePerTier = 1.5,
	-- Merging pets (QM, Oct 4; Shared/Merge): each pet merged in makes the one it becomes
	-- MergeGrowth x bigger (up to XL), x more stamina (no cap) and x faster, up to a
	-- Speed stat of MergeMaxSpeed.
	MergeGrowth = 1.1,
	MergeMaxSpeed = 8,
	-- The riding camera pulls back this much further per tier above small: 1x on a
	-- small pet, 1.2x on a medium, 1.44x on a large (QM, Oct 2).
	RideZoomPerTier = 1.2,
	ObstacleTiers = {
		Bush = 1, Rock = 2, Stone = 1, Sandstone = 1, -- small
		Boulder = 2, BoulderSplit = 2, Cactus = 2, SandBoulder = 2, SandBoulderCarved = 2, -- medium
		SandMound = 3, -- large
		Icicle = 1, Pine = 2, IcicleLarge = 2, IceBoulder = 3, -- snow: small, medium, medium, large
		TubeCoral = 1, BrainCoral = 1, BranchCoral = 2, FanCoral = 2, ReefRock = 3, -- ocean
		BasaltRock = 2, Vent = 3, -- the deep ocean
		DeadBush = 1, DarkStone = 1, DeadTree = 2, Crag = 2, LavaRock = 3, -- Godlands
	},
	-- How big each tier looks: each one is TierGrowth x the one below, so a medium is
	-- 1.6x a small and a large 2.56x. "Size" is the square root of the two biggest sides of
	-- the thing's box multiplied (so a long snake and a tall cactus compare fairly).
	-- Animals are sized from their model to PetSmallSize x TierGrowth^(tier - 1) studs
	-- (the horse is the tier 1 anchor), unless their file gives an explicit size.
	-- Obstacles are rescaled about their spot on the floor by ObstacleScale (worked out the same
	-- way from tools/terrain_assets.py, against smalls of ~5.4 studs).
	TierGrowth = 1.6, -- QM, Oct 1: 2x was too much
	-- MERGE is off for now that there's FUSE (QM, Oct 6 19:16): no MERGE button, and
	-- the server refuses MergePets. Pets already merged keep their size and gold.
	MergeEnabled = false,
	-- FUSE's price (Shared/Fusion.worth): each of the two pets adds its rarity's, so two
	-- Legendaries $2M (QM; Common 100 is Claude's), and a hybrid every pet in it (QM). Back on Oct 7 (QM), after a spell free;
	-- the fuse lesson's fuse is free (FuseLesson).
	FusePrice = { Common = 100, Uncommon = 1000, Rare = 10000, Epic = 100000, Legendary = 1000000 },
	-- What FUSE actually charges is that worth times this (QM, Oct 7: "100x cheaper"): Common $1,
	-- two Legendaries $20k. Hybrids keep their saved worth on the scale above, so it's done here.
	FuseCostScale = 0.01,
	PetSmallSize = 10.4,
	ObstacleScale = {
		Boulder = 0.83, BoulderSplit = 0.96, Cactus = 0.97, SandBoulder = 0.88, SandBoulderCarved = 0.93,
		SandMound = 0.58, Pine = 0.78, IcicleLarge = 0.83, IceBoulder = 0.85,
		BranchCoral = 1.27, FanCoral = 1.1, ReefRock = 0.83, BasaltRock = 0.89, Vent = 1.31,
		DeadTree = 1.07, Crag = 0.87, LavaRock = 0.86,
	},
	-- While you were away (QM, Oct 3): coming back, your pets have earned this share of
	-- their usual gold a second for the time you were gone, up to AwayCap seconds of it
	-- (10 hours at 0.1x: an hour's worth at most). Claimed from a popup (Away.client).
	AwayRate = 0.1,
	AutosaveEvery = 90, -- seconds between autosaves of each player's gold, pets and pen (Gold, Hatchery, PenLevel)
	AwayCap = 10 * 3600,
	-- Gold per second each pet in your pen earns you (the one you ride too), paid
	-- every second while you're in the game.
	PetIncome = {
		Horse = 1, Pig = 3, Bunny = 4, Pinto = 5, Fish = 8, Rhino = 30, Unicorn = 150, -- Meadow
		Cactus = 6, Kitten = 8, Scorpion = 20, Sandworm = 60, SpineLizard = 80, Snake = 250, -- Desert
		Penguin = 25, Boar = 50, Snowman = 100, IceGolem = 420, SnackYak = 3000, Icebringer = 1111, -- Tundra
		Starfish = 100, Squid = 700, KingCrab = 950, FishSchool = 850, BlueCrab = 6000, RoboShark = 19000, Whale = 1500, Kraken = 8200, -- Ocean
		Loong = 20000, Beholder = 3000, Leviathan = 15000, -- Godlands (QM's pets JSON, Oct 4; the Godlands' raised in the balance pass, Oct 6,
		WarElephant = 4000, SoulHorse = 20000, Sludge = 2500, -- so they pay more than the Ocean's)
	},
	-- Egg Machine (gacha) in the home base: walk up and roll for a random egg.
	-- Odds picks a tier by weight (percent), then an egg from that tier's Pool,
	-- weighted too. Exclusive animals are only ever in this machine (keep them
	-- out of every biome's Herd), and get their own card in the reveal.
	Gacha = {
		-- The egg roll menu (QM, Oct 4): Roll over Pets opens it (RollMenu, Hud). The old
		-- Egg Machine in the base stays off (Machine).
		Enabled = true,
		Machine = false,
		-- Each roll costs PriceGrowth x the last, rounded to two figures ($1M, $1.1M, $1.2M,
		-- $1.3M, $1.5M...), counted per player and saved (balance pass, Oct 6: a flat $1M
		-- roll paid for itself in ~2 minutes once you had the Ocean). Hatchery sets it on
		-- the player as "RollPrice".
		Price = 1000000, -- the first roll
		PriceGrowth = 1.1,
		Position = Vector3.new(-28, 0, 30), -- on the grass between Pen1 and Pen2's ride lanes
		-- QM, Oct 4: the Loong, Snack Yak and Robo Shark 10% each (Exclusive), the other
		-- 70% split evenly over the other Legendaries (14% each).
		Odds = { Legendary = 70, Exclusive = 30 },
		Pool = {
			Rare = { Fish = 1, Scorpion = 1, Snowman = 1, Whale = 1, Beholder = 1, Sludge = 1 },
			Epic = { Rhino = 1, Sandworm = 1, SpineLizard = 1, IceGolem = 1, Squid = 1, KingCrab = 1, FishSchool = 1, Leviathan = 1 },
			Legendary = { Unicorn = 1, Snake = 1, Icebringer = 1, Kraken = 1, BlueCrab = 1 },
			-- New gacha-only animals go here once they're built (QM, Oct 1). A tier
			-- with an empty pool is never rolled.
			Exclusive = { Loong = 1, SnackYak = 1, RoboShark = 1 },
		},
		Reach = 10, -- studs from the machine where ROLL shows
	},
	-- Rainbow Trail (QM, Oct 6): once the Godlands are open, Upgrade Pen's spot (top
	-- right) sells a rainbow trail for Price gold, one time, saved (Hatchery's
	-- "RainbowTrail"). After that every pet you ride trails the Unicorn's Leap rainbow,
	-- for the whole ride, and other players see it too. The price is drawn into the art.
	RainbowTrail = {
		Price = 1000000000,
		Image = "rbxassetid://74500954492785", -- assets/ui/RainbowTrail.png
		ImageDisabled = "rbxassetid://71726481257884", -- assets/ui/DisabledRainbowTrail.png: while you can't afford it
		Lifetime = 0.8, -- seconds each band trails behind (the Leap's is 1.4; very long trails don't render)
		Width = 2, -- x the Unicorn's rainbow's height (QM, Oct 6: tried 3, settled on 2)
	},
	-- Carl's stall (Carl.client, QM Oct 4): a desert stall with a cactus guy in it, in
	-- the gap between the left corner pen and the start line. Talk to him and he asks
	-- if you want to spin; Yes opens the roll menu. Faces into the base (+z).
	Carl = {
		Position = Vector3.new(-62, 0, 18), -- clear of Pen4 at its biggest (x <= -76) and its ride lane (z ~32); the egg heap behind reaches the wall
		Yaw = 15, -- degrees it turns in toward the course, off square with the wall (QM)
		Reach = 12, -- studs from the counter where Talk shows
	},
	-- The podium (Leaderboard.server, QM Oct 4): the avatar of the player who rode
	-- furthest from base, all time (OrderedDataStore "BestDistance", metres), standing on
	-- QM's cream marble column in the middle of a coiled grass snake (Props/GrassSnake,
	-- PodiumSnake.client), in the base's right front corner, their username and best
	-- distance over their head (QM, Oct 5).
	-- Lasso training (QM, Oct 8: new-loops): a stitched horse dummy on a pole at home.
	-- Stand within Radius of it (on foot) and you lasso it over and over, each catch
	-- PerCatch lasso strength (the saved "Lasso" attribute, Training.server). It
	-- doesn't gate anything yet. Each pen has its own dummy (Design's Props/TrainingDummy)
	-- at a front corner, facing out (TrainingSpot); you train at your own pen's. It's
	-- meant to upgrade with the pen later (QM).
	Training = {
		Out = 8, -- studs in front of the pen's open side
		In = 6, -- studs in from the pen's corner, along that side
		Chair = 8, -- studs from the dummy to the chair you lasso it from (Design's TrainingChair), along the pen's front
		Radius = 14, -- studs from the pole you train from
		PerCatch = 1,
		Swing = 1.1, -- seconds of each catch: the loop spun overhead,
		Throw = 0.45, -- flying out to the dummy's neck,
		Pull = 0.5, -- cinching on it (the catch counts here),
		Rest = 0.35, -- and slack before the next
		-- The stronger your lasso, the faster you lasso (QM, Oct 8): all of the above
		-- runs SpeedPerDecade quicker per x10 of lasso strength, up to MaxSpeed
		-- (TrainingSpot.speed). It ramps up quick (QM: level 100 is 3x level 1):
		-- 1 -> x1 (2.4 s a catch), 10 -> x2 (1.2 s), 100 -> x3 (0.8 s), 1k+ -> x4 (0.6 s).
		SpeedPerDecade = 1,
		MaxSpeed = 4,
	},
	-- Recommended lasso level for each animal, shown over the one you'd lasso as you
	-- ride (LassoLevel.luau). PLACEHOLDERS until Game design sets them (QM, Oct 8): each
	-- biome has a range (Meadow 10-100, Desert 100-10k, Snow 10k-500k, Ocean 1M-100M,
	-- Godlands 100M-10B), Common at its bottom and Legendary at its top, the rarities
	-- between evenly spaced on a log scale (2 significant figures). An animal not
	-- listed shows nothing.
	LassoLevels = {
		Horse = 10, Pinto = 18, Pig = 18, Bunny = 18, Fish = 32, Rhino = 56, Unicorn = 100, -- Meadow
		Cactus = 320, Kitten = 320, Scorpion = 1000, Sandworm = 3200, SpineLizard = 3200, Snake = 10000, -- Desert
		Penguin = 27000, Boar = 27000, Snowman = 71000, IceGolem = 190000, SnackYak = 190000, Icebringer = 500000, -- Snow
		Starfish = 3200000, Whale = 10000000, Squid = 32000000, KingCrab = 32000000, FishSchool = 32000000, BlueCrab = 100000000, RoboShark = 100000000, Kraken = 100000000, -- Ocean
		Beholder = 1000000000, WarElephant = 1000000000, Sludge = 1000000000, SoulHorse = 3200000000, Leviathan = 3200000000, Loong = 10000000000, -- Godlands
	},
	-- Rarity text colours (QM, Oct 7): pet nameplates, lasso levels. Common keeps the inventory slots' grey.
	RarityColors = {
		Common = Color3.fromRGB(150, 160, 175),
		Uncommon = Color3.fromHex("43FA00"),
		Rare = Color3.fromHex("40D6FF"),
		Epic = Color3.fromHex("FF7CC6"),
		Legendary = Color3.fromHex("5CE6B7"),
	},
	Podium = {
		Position = Vector3.new(58, 0, 16), -- the column, on the ground; the snake reaches x ~50..74, z ~2..47 (Pen5 is x >= 76)
		Refresh = 120, -- seconds between re-reading the leader
		AvatarScale = 1.5,
		SnakeScale = 2, -- x the model (the Snake pet is about 1.9)
		SnakeYaw = 165, -- degrees: its head rears in front of the column, looking into the base
	},
	-- Eggs that aren't just an animal's (QM, Oct 4): the inventory holds them by this
	-- key; placed, they hatch after HatchTime seconds into Pet merged from Merged
	-- (Shared/Merge). They look like Pet's egg, EggScale x as big (QM).
	SpecialEggs = {
		GiantHorse = { Name = "Giant Horse", Pet = "Horse", Merged = 10, HatchTime = 0, EggScale = 3 }, -- the shop's Giant Horse
	},
	EggGrowScale = 2, -- a placed egg grows from 1x to this size by the time it hatches
	-- Egg pictures for the eggs in your inventory (the renders the egg reveal uses).
	EggIcons = {
		Horse = "rbxassetid://96698232796495", -- assets/ui/HorseEggRender.png (the tutorial's first egg)
		Pinto = "rbxassetid://79525419811481",
		Pig = "rbxassetid://139970505549400",
		Bunny = "rbxassetid://102165948456968", -- assets/ui/BunnyEggRender.png
		Fish = "rbxassetid://105098230793344",
		Rhino = "rbxassetid://139482781062355",
		Unicorn = "rbxassetid://85066893166855",
		Cactus = "rbxassetid://95599437590618",
		Kitten = "rbxassetid://124881834655792", -- assets/ui/KittenEggRender.png
		Scorpion = "rbxassetid://84668325203507",
		Sandworm = "rbxassetid://102795691143589",
		Snake = "rbxassetid://90142926499080",
		Beholder = "rbxassetid://111649507533762", -- assets/ui/BeholderEggRender.png
		Penguin = "rbxassetid://135143840112034",
		Snowman = "rbxassetid://105231134861157",
		SpineLizard = "rbxassetid://131132122596946",
		Boar = "rbxassetid://137113936385932",
		IceGolem = "rbxassetid://103638328020279",
		SnackYak = "rbxassetid://86307268458670", -- assets/ui/SnackYakEggRender.png
		Icebringer = "rbxassetid://93831958938146",
		Kraken = "rbxassetid://78320352111053", -- assets/ui/KrakenEggRender.png
		Squid = "rbxassetid://128883182267763", -- assets/ui/SquidEggRender.png
		Whale = "rbxassetid://97101351248514", -- assets/ui/WhaleEggRender.png
		KingCrab = "rbxassetid://80563240117126", -- assets/ui/KingCrabEggRender.png
		BlueCrab = "rbxassetid://119349539273288", -- assets/ui/BlueCrabEggRender.png
		RoboShark = "rbxassetid://95626930006876", -- assets/ui/RoboSharkEggRender.png
		Starfish = "rbxassetid://114368032731288", -- assets/ui/StarfishEggRender.png
		FishSchool = "rbxassetid://137156704531563", -- assets/ui/FishSchoolEggRender.png
		Loong = "rbxassetid://70469571709365", -- assets/ui/LoongEggRender.png
		WarElephant = "rbxassetid://84356622911486", -- assets/ui/WarElephantEggRender.png
		SoulHorse = "rbxassetid://136725772402125", -- assets/ui/SoulHorseEggRender.png
		Sludge = "rbxassetid://140005979942732", -- assets/ui/SludgeEggRender.png
		Leviathan = "rbxassetid://95236739672996", -- assets/ui/LeviathanEggRender.png
	},
	-- Sprint (hold Shift, L2 or the button, on the way out only): faster, but the
	-- Hold bar drains faster too.
	-- The gallop sound plays while you ride any animal (Sounds; QM, Oct 4: "add the galloping
	-- sfx to all animals"). List animals here as false to leave them out.
	GallopSound = {},
	SprintSpeed = 2, -- x MountSpeed
	-- Phones have no Sprint button (QM, Oct 4): pushing the joystick out past this share of
	-- its reach sprints, easing it back stops.
	TouchSprintAt = 0.85,
	PetSprintSpeed = { Loong = 4 }, -- these sprint at this x instead (QM, Oct 4)
	SprintDrain = 1.5, -- x the Hold bar's usual drain
	ReturnSprint = true, -- the ride home with the egg is always a sprint (SprintSpeed x ReturnSpeed)
	ReturnFovKick = 20, -- degrees added to the field of view on the ride home, to feel faster (0 = off)
	-- The feel of speed (QM, Oct 7; Client/SpeedFx): Speed is uncapped, but rides travel
	-- straight up to Knee studs/s and then bend off towards Max; speed lines and a wider
	-- view (up to MaxFov) grow from Start studs/s. Each part off with On = false.
	SpeedCurve = { On = true, Knee = 400, Max = 700 }, -- (the Kraken sprints at 396)
	SpeedFeel = { On = true, Start = 44, Scale = 200, Lines = 28, Opacity = 0.6, LineSpeed = 2.2, FovKick = 18, MaxFov = 110 },
	LassoRange = 34,
	EggSlowMo = 0.5, -- time scale during the egg-grab close-up
	-- Coming home with an egg: the pet leaps over the start line in slow motion while
	-- the camera swings round to a hero angle in front and back again, landing
	-- HomeLandPast studs past the line and running on HomeRunOut studs to a stop,
	-- where you dismount and the egg reveal pops up.
	HomeHeroTime = 2.4, -- real seconds for the whole leap
	HomeSlowMo = 0.3, -- time scale for the world during the leap
	HomeLeapHeight = 8, -- studs at the top of the arc
	HomeHeroCamHeight = 9, -- studs above the ground for the camera at the hero angle
	HomeLandPast = 4, -- studs past the start line (1 m)
	HomeRunOut = 6, -- studs the pet runs on after landing, easing to a stop
	-- The finish line, this many studs before the end of the last biome (it moves
	-- with the course as biomes are added). The course stops at it: no floor or walls
	-- past it, just sky. Riding over it plays the slow-motion leap off the edge, then
	-- a random egg (drawn like the stampede) and you're back home.
	FinishFromEnd = 50,
	-- Egg reveal back home (gacha): the card rolls through the three unknown eggs,
	-- slow at first and faster and faster, then pops onto the egg's rarity card.
	EggRevealFlicks = 24, -- unknown cards shown before the real one
	EggRevealFirstGap = 0.3, -- seconds between the first, slow flicks
	EggRevealLastGap = 0.03, -- seconds between the last, fastest flicks
	EggRevealHold = 2.2, -- seconds the real card stays up before the ride ends
	EggRevealBurst = true, -- spinning sunburst behind the real card
	LandingGrace = 0.8,
	TurnGrace = 2,
	-- Continue (QM, Oct 3): after a crash or a buck-off, pay Robux to keep riding
	-- from where it happened (Shop.server, Ride.client). Price bands by distance are
	-- possible (each band its own product; the furthest band passed, From metres from
	-- the start line, is offered), but QM (Oct 4): always the same, one 100 R$ product.
	-- OldProductIds: the bands it was sold as before, still honoured.
	ContinueTiers = {
		{ From = 0, Price = 100, ProductId = 3716554535, OldProductIds = { 3716409203, 3716409211, 3716409249, 3716409258, 3716409346 } },
	},
	ContinueGrace = 1.5, -- seconds nothing can crash you once you're back on
	ContinueClear = 14, -- studs: obstacles this close to where you crashed are knocked away
	-- Robux shop (QM, Oct 4; Shop client, Shop.server): the gold icon at home opens it,
	-- and pressing ROLL without the gold for it asks you to buy the smallest gold pack
	-- that covers it.
	-- Each offer is its own developer product, like Continue's bands (QM's
	-- dashboard, Oct 4; a ProductId of 0 would only show in Studio, for free).
	-- QM's new menu (Oct 4) shows Giant Horse, Spawn Loong, Gold1, Gold4 and the
	-- Legend Egg, with their prices baked into the cards' art (Price here is just
	-- a note of it: what's charged is the product's price on the dashboard). Gold2,
	-- Gold3 and Nuke All aren't on it but can still be bought.
	SpeedupEgg = { ProductId = 3716598923, Price = 10, Range = 10 }, -- instantly hatch one egg in your pen
	-- Game passes (QM, Oct 7; Server/Passes): bought once, kept for good. Each is a
	-- pass on the Creator Hub (Monetization > Passes); put its id in Id. With Id 0
	-- it isn't offered live, and in Studio buying it is free for the session.
	-- Owning one sets the player's "Pass<Key>" attribute (PassDoubleGold, ...).
	--   DoubleGold: x2 on every gold you earn (pets, rides, away gold)
	--   FastHatch: eggs hatch in half the time
	--   AutoHatch: ready eggs hatch by themselves, no holding F
	--   VIP: a gold fence with red banners round your pen (the floor stays the
	--     biome's), your name over the pen in gold, and a gold trail behind you
	Passes = {
		{ Key = "DoubleGold", Name = "x2 Gold", Price = 99, Id = 2014472441 },
		{ Key = "FastHatch", Name = "Fast Hatch", Price = 99, Id = 2014634454 },
		{ Key = "AutoHatch", Name = "Auto Hatch", Price = 40, Id = 2012972449 },
		{ Key = "VIP", Name = "VIP", Price = 199, Id = 2013764414 },
	},
	PassGoldMultiplier = 2, -- DoubleGold's
	PassHatchSpeed = 2, -- FastHatch's: hatch times / this
	Vip = {
		Fence = { Post = Color3.fromRGB(255, 196, 40), Rail = Color3.fromRGB(255, 222, 90), Brace = Color3.fromRGB(232, 160, 20) },
		Banner = Color3.fromRGB(214, 32, 40), -- the red banners on the pen's corner posts
		Name = Color3.fromRGB(255, 205, 50), -- the owner's name over the pen
		Trail = { Color3.fromRGB(255, 236, 140), Color3.fromRGB(255, 180, 20) }, -- head to tail
	},
	Shop = {
		Gold = {
			{ Key = "Gold1", Gold = 100000, Price = 50, ProductId = 3716553782, OldProductIds = { 3716409553 } }, -- $100K (QM's nerf, Oct 4: was $1M)
			{ Key = "Gold2", Gold = 5000000, Price = 99, ProductId = 3716409568 },
			{ Key = "Gold3", Gold = 25000000, Price = 399, ProductId = 3716409595 },
			{ Key = "Gold4", Gold = 1000000, Price = 150, ProductId = 3716553841, OldProductIds = { 3716409606 } }, -- $1M (QM's nerf, Oct 4: was $100M)
		},
		Specials = {
			{ Key = "GiantHorse", Name = "Giant Horse", Price = 5, ProductId = 3716552368, OldProductIds = { 3716409132 } }, -- a Giant Horse egg (SpecialEggs); the old product was one giant ride -- one ride (GiantHorse below)
			{ Key = "SpawnLoong", Name = "Spawn Loong", Price = 25, ProductId = 3716553200 }, -- starts the Loong event now, no countdown, and the 10 minute cycle over (Events.server)
			{ Key = "Nuke", Name = "Nuke All", Price = 200, ProductId = 3716409185 }, -- your next ride (NukeRange)
			{ Key = "Legendary", Name = "Legend Egg", Price = 150, ProductId = 3716553941, OldProductIds = { 3716409444 } }, -- a pet by LegendaryOdds, into your pen
		},
		-- The Legend Egg's odds (percent, QM's odds card, Oct 4).
		LegendaryOdds = { Unicorn = 18, Snake = 20, Icebringer = 20, Kraken = 20, BlueCrab = 20, Loong = 1, RoboShark = 1 },
		-- The Giant Horse: a Horse this many times its size, Speed x its own, no
		-- Hold drain, for one ride from the start line. Zoom is the camera's pull-back.
		GiantHorse = { Scale = 8, Speed = 16, Zoom = 2.6 },
		-- Nuke All: the ride after buying it starts with every animal in sight
		-- knocked flying, and every obstacle within NukeRange studs of you is blown
		-- away for the whole ride (they're back the ride after).
		NukeRange = 160,
	},
	-- Ride back's vignette: edges only, soft, breathing slowly, to add tension without
	-- covering the lane. Its shape (clear middle 60%) is baked into the image.
	VignetteColor = Color3.fromRGB(210, 30, 30),
	VignetteOpacity = 0.5, -- 0..1: about 30% red at the screen's edges, 50% in the corners
	VignettePulse = 0.3, -- how much it fades on each breath (0 = steady)
	VignetteFadeMetres = 25, -- fades out over this last stretch before home

	-- Each animal's stats, relative to the horse (1x). Speed scales how fast it runs,
	-- ridden (MountSpeed, ReturnSpeed) and in the stampede (HerdSpeed). Stamina scales
	-- how long the Hold bar lasts while you ride it: 2x lasts twice as long.
	AnimalStats = {
		-- Meadow
		Horse = { Speed = 1, Stamina = 1 },
		Pig = { Speed = 0.8, Stamina = 0.8 },
		Bunny = { Speed = 1.2, Stamina = 0.7 }, -- quick hops, tires fast (guess)
		Pinto = { Speed = 1.1, Stamina = 0.9 },
		Fish = { Speed = 0.6, Stamina = 3 },
		Rhino = { Speed = 1.5, Stamina = 1.8 },
		Unicorn = { Speed = 2, Stamina = 2 },
		-- Desert
		Cactus = { Speed = 1.2, Stamina = 1.5 },
		Kitten = { Speed = 1.4, Stamina = 1.2 }, -- quick pounces (guess)
		Scorpion = { Speed = 1.5, Stamina = 1.5 },
		Sandworm = { Speed = 1.6, Stamina = 3 },
		SpineLizard = { Speed = 1.8, Stamina = 2 },
		Snake = { Speed = 2, Stamina = 3 },
		-- Tundra
		Penguin = { Speed = 1.5, Stamina = 1.5 },
		Boar = { Speed = 1.6, Stamina = 1.6 },
		Snowman = { Speed = 1.9, Stamina = 1.3 },
		IceGolem = { Speed = 1.6, Stamina = 3 },
		SnackYak = { Speed = 3, Stamina = 2 }, -- QM, Oct 4 (stamina 1 -> 2)
		Icebringer = { Speed = 2.7, Stamina = 4 },
		-- Ocean
		Starfish = { Speed = 2.5, Stamina = 2 },
		Squid = { Speed = 3, Stamina = 2.6 },
		KingCrab = { Speed = 3.1, Stamina = 3 },
		BlueCrab = { Speed = 3.1, Stamina = 3 }, -- the King Crab's
		RoboShark = { Speed = 1.2, Stamina = 3 }, -- QM, Oct 4: starts at 1.2x, eating takes it up to 3x (Abilities.RoboShark.MaxSpeed 2.5 x this)
		FishSchool = { Speed = 3, Stamina = 2.8 }, -- a guess between the Squid and King Crab
		Whale = { Speed = 1.2, Stamina = 10 },
		Kraken = { Speed = 4.5, Stamina = 3 },
		-- Godlands
		Loong = { Speed = 0.5, Stamina = 8 }, -- QM, Oct 4: starts at 0.5x, its breath's kills take it up to 1x (Abilities.Loong.MaxSpeed 2 x this); sprints at 4x (PetSprintSpeed)
		Beholder = { Speed = 2, Stamina = 2 }, -- QM, Oct 4
		Leviathan = { Speed = 2, Stamina = 3 }, -- QM, Oct 4
		WarElephant = { Speed = 1.1, Stamina = 4 }, -- QM, Oct 4
		SoulHorse = { Speed = 2, Stamina = 3 }, -- QM, Oct 4
		Sludge = { Speed = 1, Stamina = 2 }, -- guesses (Oct 4)
	},

	-- Coins for landing on an animal: LassoCoins for that animal, else by its rarity (set
	-- in its Animals module).
	RarityCoins = { Common = 1, Uncommon = 3, Rare = 5, Epic = 10, Legendary = 25 },
	LassoCoins = { Beholder = 50, Sludge = 50, WarElephant = 50, Leviathan = 100 }, -- QM's pets JSON, Oct 4

	-- Stampede: each biome has its own steady stream of animals (its Herd above),
	-- one every HerdSpawnEvery seconds, whether anyone is riding or not. They pop in
	-- at the biome's start (the start line, or the line from the biome before) and
	-- shrink away at its end.
	HerdSpawnEvery = 0.9,
	HerdSpeed = 31, -- studs/s for a 1x animal; each kind runs at exactly this x its Speed
}
