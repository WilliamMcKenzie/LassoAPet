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
	-- model in World.Nests is an egg spawn of the biome it stands in; each ride,
	-- one nest per biome holds an egg.
	Biomes = {
		{
			Name = "Meadow",
			Length = 760,
			GroundColors = { Color3.fromRGB(77, 196, 63), Color3.fromRGB(105, 255, 74) },
			WallColors = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
			-- Which animals run in this biome's stampede and how often (names are modules
			-- in Shared/Animals). QM's spawn table (Oct 3): chances out of 1. They're
			-- weights, so a biome that doesn't add up to exactly 1 still works. Nest eggs
			-- use the same odds (Nests.server). A 0 never spawns but keeps the animal on
			-- the biome's page in the animal dictionary.
			Herd = { Horse = 0, Pinto = 0.35, Pig = 0.25, Fish = 0.22, Rhino = 0.13, Unicorn = 0.05 },
			-- Dirt patches in the walls' colours, a stud below the grass
			-- (tools/meadow_ground.py); see the Desert's Patches.
			Patches = {
				Dirt = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
			},
		},
		{
			Name = "Desert",
			Length = 2280, -- 3x the meadow (QM)
			GroundColors = { Color3.fromRGB(232, 188, 102), Color3.fromRGB(250, 214, 130) },
			WallColors = { Color3.fromRGB(206, 118, 72), Color3.fromRGB(226, 138, 88) },
			Herd = { Cactus = 0.3, Scorpion = 0.25, Sandworm = 0.2, SpineLizard = 0.2, Snake = 0.05 },
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
			UnlockCost = 1000,
			PostColor = Color3.fromRGB(206, 118, 72),
			GateImage = "rbxassetid://113778810800288", -- assets/ui/GateDesert.png ("Zone Locked")
			GateColor = Color3.fromRGB(255, 204, 40), -- the gate's glow at this biome's line: desert yellow
			-- Upgrade Pen while this is the next biome to unlock (its price is drawn in).
			UpgradeImage = "rbxassetid://78830244894115", -- assets/ui/UpgradePenDesert.png
			UpgradeImageDisabled = "rbxassetid://81637358609980", -- assets/ui/UpgradePenDesertDisabled.png: while you can't afford it
		},
		{
			Name = "Snow",
			Length = 5472, -- 3x the desert, then 0.8x (QM, Oct 2)
			GroundColors = { Color3.fromRGB(228, 234, 242), Color3.fromRGB(244, 247, 251) },
			WallColors = { Color3.fromRGB(126, 164, 214), Color3.fromRGB(146, 182, 228) },
			Herd = { Penguin = 0.3, Boar = 0.25, Snowman = 0.22, IceGolem = 0.12, SnackYak = 0, Icebringer = 0.06 }, -- the Snack Yak never spawns: a Robux exclusive (QM, Oct 4)
			-- tools/snow_ground.py: cold grass a stud above the snow, ice ponds a stud below.
			Patches = {
				Grass = { Color3.fromRGB(80, 160, 166), Color3.fromRGB(96, 176, 180) },
				Ice = { Color3.fromRGB(160, 188, 244), Color3.fromRGB(178, 202, 250) },
			},
			UnlockCost = 100000,
			PostColor = Color3.fromRGB(126, 164, 214),
			GateImage = "rbxassetid://93384010922515", -- assets/ui/GateTundra.png
			GateColor = Color3.fromRGB(70, 220, 255), -- cyan (QM)
			UpgradeImage = "rbxassetid://88059029653274", -- assets/ui/UpgradePenTundra.png
			UpgradeImageDisabled = "rbxassetid://110114947102534", -- assets/ui/UpgradePenTundraDisabled.png
		},
		{
			Name = "Ocean",
			Length = 7680, -- 1.4x the snow (QM, Oct 2), a whole number of 240-stud depth bands
			GroundColors = { Color3.fromRGB(236, 214, 164), Color3.fromRGB(246, 228, 184) },
			WallColors = { Color3.fromRGB(236, 140, 124), Color3.fromRGB(250, 160, 142) }, -- salmon coral (QM)
			-- The Fish is a placeholder until the rest of the ocean animals are designed.
			Herd = { Fish = 0, Starfish = 0.3, Whale = 0.15, Squid = 0.2, KingCrab = 0.15, FishSchool = 0.15, BlueCrab = 0.05, Kraken = 0.05 }, -- (Blue Crab guessed like the Kraken)
			-- tools/ocean_ground.py: seagrass a stud above the sand, trenches a stud below.
			Patches = {
				Grass = { Color3.fromRGB(64, 178, 122), Color3.fromRGB(80, 196, 138) },
				Trench = { Color3.fromRGB(70, 150, 214), Color3.fromRGB(86, 166, 228) },
				Lava = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- Neon (WorldColors keeps the textures off its glow)
			},
			-- It gets darker the further you ride (QM, Oct 2): coral reef, sand flats,
			-- dark rock with the first lava, volcanic abyss. At is the fraction of the
			-- way along; the floor, walls and haze blend between these stops (the floor
			-- and walls step every 240 studs, tools/ocean_ground.py BAND). Where a stop
			-- has a colour, it wins over the GroundA/WallA... attributes above.
			Depths = {
				{
					At = 0,
					Ground = { Color3.fromRGB(236, 214, 164), Color3.fromRGB(246, 228, 184) },
					Grass = { Color3.fromRGB(64, 178, 122), Color3.fromRGB(80, 196, 138) },
					Trench = { Color3.fromRGB(70, 150, 214), Color3.fromRGB(86, 166, 228) },
					Wall = { Color3.fromRGB(236, 140, 124), Color3.fromRGB(250, 160, 142) },
					Haze = Color3.fromRGB(60, 150, 235),
					Tint = Color3.fromRGB(200, 228, 255),
				},
				{
					At = 0.33,
					Ground = { Color3.fromRGB(222, 196, 150), Color3.fromRGB(234, 210, 166) },
					Grass = { Color3.fromRGB(76, 150, 112), Color3.fromRGB(90, 164, 124) },
					Trench = { Color3.fromRGB(60, 120, 190), Color3.fromRGB(74, 134, 204) },
					Wall = { Color3.fromRGB(196, 150, 140), Color3.fromRGB(212, 166, 154) },
					Haze = Color3.fromRGB(44, 112, 200),
					Tint = Color3.fromRGB(192, 214, 245),
				},
				{
					At = 0.55,
					Ground = { Color3.fromRGB(150, 146, 150), Color3.fromRGB(164, 160, 164) },
					Grass = { Color3.fromRGB(84, 86, 102), Color3.fromRGB(96, 98, 114) },
					Trench = { Color3.fromRGB(50, 80, 140), Color3.fromRGB(60, 92, 152) },
					Wall = { Color3.fromRGB(120, 116, 132), Color3.fromRGB(136, 132, 148) },
					Haze = Color3.fromRGB(34, 76, 160),
					Tint = Color3.fromRGB(180, 192, 228),
				},
				{
					At = 0.75,
					Ground = { Color3.fromRGB(104, 104, 120), Color3.fromRGB(118, 118, 134) },
					Grass = { Color3.fromRGB(66, 68, 86), Color3.fromRGB(78, 80, 98) },
					Trench = { Color3.fromRGB(40, 50, 90), Color3.fromRGB(50, 60, 100) },
					Wall = { Color3.fromRGB(78, 82, 106), Color3.fromRGB(92, 96, 120) },
					Haze = Color3.fromRGB(26, 50, 120),
					Tint = Color3.fromRGB(168, 170, 210),
				},
				{
					At = 1,
					Ground = { Color3.fromRGB(54, 50, 62), Color3.fromRGB(66, 62, 74) },
					Grass = { Color3.fromRGB(36, 34, 44), Color3.fromRGB(46, 44, 54) },
					Trench = { Color3.fromRGB(30, 30, 50), Color3.fromRGB(40, 40, 60) },
					Wall = { Color3.fromRGB(40, 38, 50), Color3.fromRGB(52, 50, 62) },
					Haze = Color3.fromRGB(18, 16, 52),
					Tint = Color3.fromRGB(150, 140, 185),
				},
			},
			UnlockCost = 1000000,
			PostColor = Color3.fromRGB(236, 140, 124),
			GateImage = "rbxassetid://129714355476447", -- assets/ui/GateOcean.png
			GateColor = Color3.fromRGB(30, 80, 220), -- deep blue (QM)
			UpgradeImage = "rbxassetid://86653048989907", -- assets/ui/UpgradePenOcean.png
			UpgradeImageDisabled = "rbxassetid://134800932476227", -- assets/ui/UpgradePenOceanDisabled.png
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
		{
			-- The endgame (QM, Oct 3), after Realm of the Mad God's godlands: dark stone
			-- plates split by snow, with ice or lava cracks. It never ends: one 960-stud
			-- track after another, each picked at random from four (two with ice, two
			-- with lava; Shared/Godlands, Shared/GodlandsTracks), built round each rider
			-- as they go (Client/GodlandsStream). It has no finish line.
			Name = "Godlands",
			Length = math.huge, -- endless
			GroundColors = { Color3.fromRGB(208, 212, 224), Color3.fromRGB(224, 228, 238) }, -- grey snow
			WallColors = { Color3.fromRGB(48, 46, 58), Color3.fromRGB(62, 60, 74) }, -- dark stone (snow caps)
			-- Placeholder until the Godlands has animals (and bosses) of its own: Fish (QM), and
			-- now the Loong, rare (a guess). PlaceholderHerd keeps it out of the finish line's
			-- egg odds (Hatchery).
			Herd = { Fish = 1, Loong = 0.05 },
			PlaceholderHerd = true,
			Patches = {
				Stone = { Color3.fromRGB(62, 60, 72), Color3.fromRGB(76, 74, 88) }, -- a stud up
				Ice = { Color3.fromRGB(170, 196, 250), Color3.fromRGB(184, 208, 252) },
				Lava = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- Neon
			},
			UnlockCost = 10000000, -- guessed: 10x the Ocean
			PostColor = Color3.fromRGB(62, 60, 72),
			GateColor = Color3.fromRGB(255, 72, 0), -- lava orange
			-- No GateImage / UpgradeImage yet: the gate shows plain text and Upgrade Pen
			-- the default button with the price, until QM's art is in.
		},
	},
	-- The gate across the corridor at a locked biome's line: its colour (the biome's GateColor, else this one) at the floor
	-- fading to clear this many studs up. Only you see it, until you unlock it.
	GateHeight = 26,
	GateColor = Color3.fromRGB(255, 204, 40),
	CourseHalfWidth = 56,
	CourseLength = math.huge, -- all the biomes' lengths added up: endless, with the Godlands last
	HomeHalfWidth = 144, -- tools/pens.py HALF_W: the base grew to fit the bigger pens (QM, Oct 3)
	StarterSpot = Vector3.new(0, 0, 20), -- where you start without a pen (players past the fifth)

	-- Ride
	MountSpeed = 44,
	ReturnSpeed = 40,
	SteerSpeed = 28,
	SteerResponse = 8,
	HoldTime = 6,
	-- Egg nests are shared stock: they all start full, a grabbed egg empties its nest
	-- for everyone, and it restocks this many seconds later. Eggs are rolled with the
	-- nest's biome's Herd odds; Common animals are the ones you get by default, so
	-- their eggs never show up.
	NestRestock = 30,
	-- Any pet can be ridden. Until pets can be picked in the pen, you ride this one
	-- (it waits on the first pet spot in your pen).
	DefaultPet = "Horse",
	-- Seconds an egg placed in your pen takes to hatch, by the rarity of the
	-- animal inside (first-biome eggs; later biomes can take longer).
	HatchTime = { Uncommon = 15, Rare = 45, Epic = 120, Legendary = 300 },
	-- The first-time tutorial (Tutorial.luau): a new player places their first egg
	-- (a DefaultPet egg, hatching in TutorialHatchTime seconds), rides that pet and
	-- brings home an egg, one hint at a time and only the buttons each step needs.
	-- false turns it off. On that first ride the first Meadow nest always holds a
	-- TutorialEgg (only that player sees it), the stampede runs on the player's own
	-- clock so it can slow down to TutorialSlowMo x speed while LASSO or TAKE EGG is
	-- waiting to be pressed, and the Hold bar never runs out.
	Tutorial = true,
	TutorialEgg = "Pinto",
	TutorialHatchTime = 0,
	TutorialSlowMo = 0.2,
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
	--     coiled idle), smashing every obstacle within Radius studs and scattering
	--     the animals there away from it, and refilling Restore of the Hold bar. No
	--     Hold drain while it rattles; a yellow-orange haze closes in round the screen.
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
	--   Feast (Blue Crab): one tap cashes in everything it broke since the last Feast:
	--     for each, Heal of the Hold bar back, and it grows Grow x bigger and runs
	--     SpeedUp x faster for the rest of the ride, up to Max x its own size and speed
	--     (a size TierGrowth x bigger counts as a size tier up).
	--   Wave (School of Fish): a wall of fish rushes up from behind across the whole
	--     course, overtakes it and races on ahead for Duration, and every obstacle and
	--     animal it passes goes flying, whatever its size; then the fish dive away
	--     (client/FishWave.luau). Nothing crashes the school while it runs.
	--   Breath (Loong): it plays its fire breath ("special") and, from FireFrom to FireTo
	--     seconds in, everything in a Width-stud lane Range studs ahead is burnt away:
	--     obstacles smashed, animals flung, whatever their size. It refills Restore of
	--     the Hold bar when it starts (QM: 20%).
	-- Boost, Grow, Ink, Crabwalk and Breath, like Frost, still use Hold and can crash.
	-- (The Kraken's ability is on hold until QM and Claude settle how it looks.)
	-- Charge swings the camera round to a cinematic front-side angle.
	-- (QM, Oct 2: the cooldowns, durations and radii QM didn't give are guesses.)
	Abilities = {
		Rhino = { Kind = "Charge", Duration = 4, Cooldown = 7, SpeedBoost = 1.2 },
		SnackYak = { Kind = "Charge", UntilFull = true, Cooldown = 5, SpeedBoost = 2 }, -- QM, Oct 4
		Unicorn = { Kind = "Leap", Duration = 3, Cooldown = 8, SpeedBoost = 1.4, LeapHeight = 56 },
		Snake = { Kind = "Rattle", Duration = 2.4, Cooldown = 6, Radius = 45, Restore = 0.5 },
		Icebringer = { Kind = "Frost", Duration = 4, Cooldown = 8, Radius = 50, Slow = 0.7 },
		SpineLizard = { Kind = "Boost", Duration = 5, Cooldown = 8, SpeedBoost = 2 },
		IceGolem = { Kind = "Grow", Duration = 5, Cooldown = 10, SpeedBoost = 1.2, Tier = 4 },
		Squid = { Kind = "Ink", Duration = 2.5, Cooldown = 8, Radius = 45 },
		KingCrab = { Kind = "Crabwalk", Duration = 4, Cooldown = 8, SpeedBoost = 2, Tier = 3 },
		BlueCrab = { Kind = "Feast", Duration = 0.9, Cooldown = 8, Heal = 0.1, Grow = 1.1, SpeedUp = 1.1, Max = 2 }, -- QM, Oct 4 (cooldown a guess)
		FishSchool = { Kind = "Wave", Duration = 4, Cooldown = 10 },
		-- the animation's length and fire window; the range, width and cooldown are guesses
		Loong = { Kind = "Breath", Duration = 2.6, FireFrom = 0.95, FireTo = 2.1, Cooldown = 8, Range = 70, Width = 22, Restore = 0.2 },
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
	SprintSpecials = {
		Unicorn = { Kind = "Smash", Radius = 14 },
		Sandworm = { Kind = "Burrow" },
		Icebringer = { Kind = "Ram" },
		Whale = { Kind = "Fly", Height = 56 },
		Kraken = { Kind = "Trample", BelowTier = 3 },
		Loong = { Kind = "Loom", Grow = 1.2, Radius = 40 }, -- QM: 1.2x; the radius is a guess
		BlueCrab = { Kind = "Crabwalk", SpeedBoost = 1.2 }, -- QM, Oct 4
	},
	-- Size tiers (any whole number, bigger is bigger). A pet plows straight through
	-- obstacles and stampede animals of a lower tier, knocking them up and away;
	-- one of its own tier or higher still crashes it. Obstacles take their tier
	-- from their model's "Tier" attribute, else from ObstacleTiers by name.
	PetTiers = {
		Horse = 1, Pig = 1, Pinto = 1, Fish = 1, Rhino = 2, Unicorn = 2, -- Meadow
		Cactus = 1, Scorpion = 1, Sandworm = 2, SpineLizard = 2, Snake = 3, -- Desert
		Penguin = 1, Boar = 1, Snowman = 1, IceGolem = 2, SnackYak = 2, Icebringer = 3, -- Tundra
		Starfish = 1, Squid = 2, KingCrab = 2, FishSchool = 2, BlueCrab = 2, Whale = 4, Kraken = 4, -- Ocean
		Loong = 3, -- Godlands
	},
	-- Eggs are this much bigger per tier above small, like their animals: 1x small,
	-- 1.2x medium, 1.44x large, 1.73x XL (QM, Oct 2; Eggs/Egg.luau).
	EggSizePerTier = 1.2,
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
	AwayCap = 10 * 3600,
	-- Gold per second each pet in your pen earns you (the one you ride too), paid
	-- every second while you're in the game.
	PetIncome = {
		Horse = 1, Pig = 3, Pinto = 5, Fish = 8, Rhino = 30, Unicorn = 150, -- Meadow
		Cactus = 6, Scorpion = 20, Sandworm = 60, SpineLizard = 80, Snake = 250, -- Desert
		Penguin = 25, Boar = 50, Snowman = 100, IceGolem = 420, SnackYak = 4000, Icebringer = 1111, -- Tundra
		Starfish = 100, Squid = 700, KingCrab = 950, FishSchool = 850, BlueCrab = 6000, Whale = 5000, Kraken = 8200, -- Ocean
		Loong = 20000, -- Godlands (a guess, past the Kraken)
	},
	-- Egg Machine (gacha) in the home base: walk up and roll for a random egg.
	-- Odds picks a tier by weight (percent), then an egg from that tier's Pool,
	-- weighted too. Exclusive animals are only ever in this machine (keep them
	-- out of every biome's Herd), and get their own card in the reveal.
	Gacha = {
		Enabled = false, -- off for now: QM will revisit the gacha later (no machine, no ROLL)
		Price = 25000,
		Position = Vector3.new(-28, 0, 30), -- on the grass between Pen1 and Pen2's ride lanes
		Odds = { Rare = 50, Epic = 32, Legendary = 15, Exclusive = 3 },
		Pool = {
			Rare = { Fish = 1, Scorpion = 1, Snowman = 1, Whale = 1 },
			Epic = { Rhino = 1, Sandworm = 1, SpineLizard = 1, IceGolem = 1, Squid = 1, KingCrab = 1, FishSchool = 1 },
			Legendary = { Unicorn = 1, Snake = 1, Icebringer = 1, Kraken = 1, BlueCrab = 1 },
			-- New gacha-only animals go here once they're built (QM, Oct 1). A tier
			-- with an empty pool is never rolled.
			Exclusive = {},
		},
		Reach = 10, -- studs from the machine where ROLL shows
	},
	EggGrowScale = 2, -- a placed egg grows from 1x to this size by the time it hatches
	-- Egg pictures for the eggs in your inventory (the renders the egg reveal uses).
	EggIcons = {
		Horse = "rbxassetid://96698232796495", -- assets/ui/HorseEggRender.png (the tutorial's first egg)
		Pinto = "rbxassetid://79525419811481",
		Pig = "rbxassetid://139970505549400",
		Fish = "rbxassetid://105098230793344",
		Rhino = "rbxassetid://139482781062355",
		Unicorn = "rbxassetid://85066893166855",
		Cactus = "rbxassetid://95599437590618",
		Scorpion = "rbxassetid://138046936786400",
		Sandworm = "rbxassetid://96884572036784",
		Snake = "rbxassetid://71071272639782",
		Penguin = "rbxassetid://135143840112034",
		Snowman = "rbxassetid://105231134861157",
		SpineLizard = "rbxassetid://98567631088826",
		Boar = "rbxassetid://121234341393694",
		IceGolem = "rbxassetid://102264545247873",
		SnackYak = "rbxassetid://87632604695329", -- assets/ui/SnackYakEggRender.png
		Icebringer = "rbxassetid://108999142038756",
		Kraken = "rbxassetid://104654341782924", -- assets/ui/KrakenEggRender.png
		Squid = "rbxassetid://128883182267763", -- assets/ui/SquidEggRender.png
		Whale = "rbxassetid://97101351248514", -- assets/ui/WhaleEggRender.png
		KingCrab = "rbxassetid://136150514529079", -- assets/ui/KingCrabEggRender.png
		BlueCrab = "rbxassetid://119349539273288", -- assets/ui/BlueCrabEggRender.png
		Starfish = "rbxassetid://114368032731288", -- assets/ui/StarfishEggRender.png
		FishSchool = "rbxassetid://137156704531563", -- assets/ui/FishSchoolEggRender.png
		Loong = "rbxassetid://70469571709365", -- assets/ui/LoongEggRender.png
	},
	-- Sprint (hold Shift, L2 or the button, on the way out only): faster, but the
	-- Hold bar drains faster too.
	SprintSpeed = 2, -- x MountSpeed
	SprintDrain = 1.5, -- x the Hold bar's usual drain
	ReturnSprint = true, -- the ride home with the egg is always a sprint (SprintSpeed x ReturnSpeed)
	ReturnFovKick = 20, -- degrees added to the field of view on the ride home, to feel faster (0 = off)
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
	-- from where it happened (Shop.server, Ride.client). It costs more the further
	-- from home you are: Roblox prices are fixed per developer product, so each
	-- band is its own product (made on the Creator Dashboard at that price), and
	-- the furthest band you've passed (From, metres from the start line) is the
	-- one offered. Until a band's id is here, it only shows in Studio, for free.
	ContinueTiers = {
		{ From = 0, Price = 25, ProductId = 0 },
		{ From = 200, Price = 50, ProductId = 0 },
		{ From = 500, Price = 100, ProductId = 0 },
		{ From = 1000, Price = 200, ProductId = 0 },
		{ From = 2000, Price = 400, ProductId = 0 },
	},
	ContinueGrace = 1.5, -- seconds nothing can crash you once you're back on
	ContinueClear = 14, -- studs: obstacles this close to where you crashed are knocked away
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
		Pinto = { Speed = 1.1, Stamina = 0.9 },
		Fish = { Speed = 0.6, Stamina = 3 },
		Rhino = { Speed = 1.5, Stamina = 1.8 },
		Unicorn = { Speed = 2, Stamina = 2 },
		-- Desert
		Cactus = { Speed = 1.2, Stamina = 1.5 },
		Scorpion = { Speed = 1.5, Stamina = 1.5 },
		Sandworm = { Speed = 1.6, Stamina = 3 },
		SpineLizard = { Speed = 1.8, Stamina = 2 },
		Snake = { Speed = 2, Stamina = 3 },
		-- Tundra
		Penguin = { Speed = 1.5, Stamina = 1.5 },
		Boar = { Speed = 1.6, Stamina = 1.6 },
		Snowman = { Speed = 1.9, Stamina = 1.3 },
		IceGolem = { Speed = 1.6, Stamina = 3 },
		SnackYak = { Speed = 3, Stamina = 1 }, -- QM, Oct 4
		Icebringer = { Speed = 2.7, Stamina = 4 },
		-- Ocean
		Starfish = { Speed = 2.5, Stamina = 2 },
		Squid = { Speed = 3, Stamina = 2.6 },
		KingCrab = { Speed = 3.1, Stamina = 3 },
		BlueCrab = { Speed = 3.1, Stamina = 3 }, -- the King Crab's; its Feast ability grows it to 2x
		FishSchool = { Speed = 3, Stamina = 2.8 }, -- a guess between the Squid and King Crab
		Whale = { Speed = 1.2, Stamina = 10 },
		Kraken = { Speed = 4.5, Stamina = 3 },
		-- Godlands
		Loong = { Speed = 4, Stamina = 8 }, -- QM
	},

	-- Coins for landing on an animal, by the animal's rarity (set in its Animals module).
	RarityCoins = { Common = 1, Uncommon = 3, Rare = 5, Epic = 10, Legendary = 25 },

	-- Stampede: each biome has its own steady stream of animals (its Herd above),
	-- one every HerdSpawnEvery seconds, whether anyone is riding or not. They pop in
	-- at the biome's start (the start line, or the line from the biome before) and
	-- shrink away at its end.
	HerdSpawnEvery = 0.9,
	HerdSpeed = 31, -- studs/s for a 1x animal; each kind runs at exactly this x its Speed
}
