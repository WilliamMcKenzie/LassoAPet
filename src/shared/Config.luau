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
			Herd = { Fish = 0, Starfish = 0.3, Whale = 0.15, Squid = 0.2, KingCrab = 0.15, FishSchool = 0.15, BlueCrab = 0.05, RoboShark = 0, Kraken = 0.05 }, -- (Blue Crab guessed like the Kraken; the Robo Shark never spawns: a future Robux pet, QM Oct 4)
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
			GateImage = "rbxassetid://75356296124042", -- assets/ui/GateOcean.png
			GateColor = Color3.fromRGB(30, 80, 220), -- deep blue (QM)
			UpgradeImage = "rbxassetid://86653048989907", -- assets/ui/UpgradePenOcean.png
			UpgradeImageDisabled = "rbxassetid://98442121637216", -- assets/ui/UpgradePenOceanDisabled.png
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
			Length = math.huge, -- endless
			GroundColors = { Color3.fromRGB(208, 212, 224), Color3.fromRGB(224, 228, 238) }, -- grey snow
			WallColors = { Color3.fromRGB(48, 46, 58), Color3.fromRGB(62, 60, 74) }, -- dark stone (snow caps)
			-- Its own animals now; the Fish that stood in are gone (QM, Oct 4). (The Loong is
			-- an event and roll exclusive, so it doesn't run here.) PlaceholderHerd keeps it
			-- out of the finish line's egg odds (Hatchery).
			Herd = { Beholder = 0.1, WarElephant = 1, SoulHorse = 0.5, Sludge = 0.5, Leviathan = 0.1 }, -- its own animals, no Fish (QM, Oct 4; weights are guesses)
			PlaceholderHerd = true,
			Patches = {
				Stone = { Color3.fromRGB(62, 60, 72), Color3.fromRGB(76, 74, 88) }, -- a stud up
				Ice = { Color3.fromRGB(170, 196, 250), Color3.fromRGB(184, 208, 252) },
				Lava = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- Neon
			},
			UnlockCost = 10000000, -- guessed: 10x the Ocean
			PostColor = Color3.fromRGB(62, 60, 72),
			GateColor = Color3.fromRGB(255, 72, 0), -- lava orange
			GateImage = "rbxassetid://81079145393331", -- assets/ui/GateGodlands.png
			UpgradeImage = "rbxassetid://133410257702964", -- assets/ui/UpgradePenGodlands.png
			UpgradeImageDisabled = "rbxassetid://75177337427277", -- assets/ui/UpgradePenGodlandsDisabled.png
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
	-- Exclusive animal events (Events.server, QM Oct 4): there's always one on. A
	-- banner counts down the last Countdown seconds, then the animal pops in at the
	-- start line and runs off with the stampede to the finish line, and its egg drops
	-- somewhere random on the course. Riding that kind of animal while its egg is out, the guide arrows
	-- lead to that egg. The event ends when someone takes the egg or after Duration
	-- seconds; the next countdown starts Gap seconds later. One kind at a time,
	-- picked at random (never the same twice running).
	Events = {
		Animals = { "Loong", "SnackYak", "RoboShark" },
		Countdown = 10,
		Cycle = 600, -- seconds from one event's countdown to the next (QM: every 10 minutes)
		-- The egg's spot: this far in from the walls, this far from any obstacle's
		-- footprint and from a gate's line.
		WallMargin = 14,
		ObstacleMargin = 10,
		GateMargin = 30,
	},
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
		Beholder = { Kind = "Devour", Duration = 1.2, Cooldown = 10, Radius = 50, Max = 1, MaxTier = 2, PullTime = 0.8, RestorePer = 1, Hop = 3, TentacleColor = Color3.fromRGB(222, 136, 56), Mouth = 11 }, -- QM, Oct 4: one tentacle eats the nearest animal and refills all of Hold (radius and size limit guesses)
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
		Loong = { Kind = "Breath", Duration = 4.2, FireFrom = 0.95, FireTo = 3.95, Cooldown = 8, Range = 140, Width = 22, Crawl = 0.15, RestorePer = 0.1, Grow = 1.1, SpeedUp = 1.1, MaxSpeed = 4, MaxTier = 4 },
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
	-- OnReturn (QM, Oct 4): the special also runs on the ride home with the egg, which
	-- is always a sprint (ReturnSprint).
	SprintSpecials = {
		Unicorn = { Kind = "Smash", Radius = 14, ScareRadius = 30, RestorePer = 0.02, OnReturn = true }, -- scares animals within ScareRadius off, 2% Hold each (QM, Oct 4)
		Sandworm = { Kind = "Burrow", OnReturn = true },
		Whale = { Kind = "Fly", Height = 56 },
		Leviathan = { Kind = "Flame", Range = 5, Width = 9, OnReturn = true }, -- QM, Oct 4: "like 1m ahead" (4 studs a metre; the width is a guess)
		Loong = { Kind = "Loom", Grow = 1.2, Radius = 40 }, -- QM: 1.2x; the radius is a guess
		BlueCrab = { Kind = "Crabwalk", SpeedBoost = 1.2, OnReturn = true, RestorePer = 0.2 }, -- QM, Oct 4: 20% Hold per animal it hits
	},
	-- Size tiers (any whole number, bigger is bigger). A pet plows straight through
	-- obstacles and stampede animals of a lower tier, knocking them up and away;
	-- one of its own tier or higher still crashes it. Obstacles take their tier
	-- from their model's "Tier" attribute, else from ObstacleTiers by name.
	PetTiers = {
		Horse = 1, Pig = 1, Pinto = 1, Fish = 1, Rhino = 2, Unicorn = 2, -- Meadow
		Cactus = 1, Scorpion = 1, Sandworm = 2, SpineLizard = 2, Snake = 3, -- Desert
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
		Starfish = 100, Squid = 700, KingCrab = 950, FishSchool = 850, BlueCrab = 6000, RoboShark = 7000, Whale = 5000, Kraken = 8200, -- Ocean
		Loong = 20000, Beholder = 40, Leviathan = 400, -- Godlands (guesses: the Loong past the Kraken)
		WarElephant = 10000, SoulHorse = 15000, Sludge = 40, -- Godlands (guesses)
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
		Price = 1000000, -- QM's ROLL $1M button
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
	-- Carl's stall (Carl.client, QM Oct 4): a desert stall with a cactus guy in it, in
	-- the gap between the left corner pen and the start line. Talk to him and he asks
	-- if you want to spin; Yes opens the roll menu. Faces into the base (+z).
	Carl = {
		Position = Vector3.new(-66, 0, 8), -- clear of Pen4 at its biggest (x <= -76) and its ride lane (z ~32)
		Reach = 12, -- studs from the counter where Talk shows
	},
	-- The top-3 podium (Leaderboard.server, QM Oct 4): the avatars of the three players
	-- who rode furthest from base, all time (OrderedDataStore "BestDistance", metres),
	-- in the gap between the right corner pen and the start line. Faces into the base.
	Podium = {
		Position = Vector3.new(66, 0, 8), -- clear of Pen5 at its biggest (x >= 76)
		Refresh = 120, -- seconds between re-reading the top 3
		AvatarScale = 1.5,
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
	-- Robux shop (QM, Oct 4; Shop client, Shop.server): the gold icon at home opens it,
	-- and pressing ROLL with less than TopUpBelow gold opens just its gold offers.
	-- Each offer is its own developer product, like Continue's bands: until its
	-- ProductId is filled in it only shows in Studio, for free. Amounts and prices
	-- are guesses.
	Shop = {
		TopUpBelow = 10000000,
		Gold = {
			{ Key = "Gold1", Gold = 1000000, Price = 25, ProductId = 0 },
			{ Key = "Gold2", Gold = 5000000, Price = 99, ProductId = 0 },
			{ Key = "Gold3", Gold = 25000000, Price = 399, ProductId = 0 },
			{ Key = "Gold4", Gold = 100000000, Price = 1199, ProductId = 0 },
		},
		Specials = {
			{ Key = "GiantHorse", Name = "Giant Horse", Price = 100, ProductId = 0 }, -- one ride (GiantHorse below)
			{ Key = "Nuke", Name = "Nuke All", Price = 200, ProductId = 0 }, -- your next ride (NukeRange)
			{ Key = "Legendary", Name = "Legendary Pet", Price = 50, ProductId = 0 }, -- Gacha.Pool.Legendary, into your pen
		},
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
		Loong = { Speed = 1, Stamina = 8 }, -- QM, Oct 4: starts at 1x, its breath's kills take it up to 4x
		Beholder = { Speed = 2, Stamina = 2 }, -- QM, Oct 4
		Leviathan = { Speed = 2, Stamina = 3 }, -- QM, Oct 4
		WarElephant = { Speed = 1.1, Stamina = 4 }, -- QM, Oct 4
		SoulHorse = { Speed = 2, Stamina = 3 }, -- QM, Oct 4
		Sludge = { Speed = 1, Stamina = 2 }, -- guesses (Oct 4)
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
