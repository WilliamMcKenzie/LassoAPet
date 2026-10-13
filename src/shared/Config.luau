-- Tuning values shared by the map, the live colours and the ride.
local Config = {
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
			AnimalSize = 1, -- its obstacles (tools/funnel.luau) and the Godlands' terrain grow ^0.8 of this. Animals no longer do (QM, Oct 8: back to their old sizes)
			Swerve = 1, -- how much the stampede swerves out of your way on the ride home: ReturnAvoid's Clear and Chance x this (QM, Oct 6: full in the Meadow, less each zone, none in the Godlands)
			Length = 2168, -- (QM, Oct 11: the pacing ladder, below AnimalStats; was 760)
			GroundColors = { Color3.fromRGB(113, 173, 31), Color3.fromRGB(122, 190, 25) }, -- (QM, Oct 10; was 77, 196, 63 / 105, 255, 74)
			WallColors = { Color3.fromRGB(197, 126, 70), Color3.fromRGB(211, 142, 75) }, -- (QM, Oct 10; was 225, 150, 104 / 248, 170, 114)
			-- Which animals run in this biome's stampede and how often (names are modules
			-- in Shared/Animals). QM's spawn table (Oct 3): chances out of 1. They're
			-- weights, so a biome that doesn't add up to exactly 1 still works. Nest eggs
			-- use the same odds (NestOdds). A 0 never spawns but keeps the animal on
			-- the biome's page in the animal dictionary. No Common animal runs wild (QM,
			-- Oct 6: no Common eggs): the Horse is only ever the pet you start with.
			Herd = { Horse = 0, Pinto = 0.35, Pig = 0.25, Bunny = 0.25, Fish = 0.13, Rhino = 0.08, Unicorn = 0.05 },
			-- Dirt patches in the walls' colours, a stud below the grass
			-- (tools/meadow_ground.py); see the Desert's Patches.
			Patches = {
				Dirt = { Color3.fromRGB(206, 146, 84), Color3.fromRGB(222, 164, 100) }, -- (QM, Oct 10; was the walls' 225, 150, 104 / 248, 170, 114)
			},
		},
		{
			Name = "Desert",
			AnimalSize = 1.35,
			Swerve = 1, -- (as the Meadow's: QM, Oct 10; was 0.75)
			NestScale = 2, -- its nests are this many times bigger, so they show from afar at its speed (Nests.server; QM, Oct 6)
			Length = 1816, -- (QM, Oct 11: 1.5x as long; the pacing ladder made it 1208, was 2280)
			GroundColors = { Color3.fromRGB(232, 188, 102), Color3.fromRGB(250, 214, 130) },
			WallColors = { Color3.fromRGB(206, 118, 72), Color3.fromRGB(226, 138, 88) },
			Herd = { Cactus = 0.3, Kitten = 0.1, Scorpion = 0.3, Sandworm = 0.2, SpineLizard = 0.2, Snake = 0.025 },
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
			UpgradeImage = "rbxassetid://134340111977085", -- assets/ui/UpgradePenDesertEnabled.png (QM, Oct 8: price drawn in)
			UpgradeImageDisabled = "rbxassetid://97537967185164", -- assets/ui/UpgradePenDesertDisabled.png: grey, while you can't afford it (QM, Oct 8: price drawn in)
		},
		{
			Name = "Snow",
			AnimalSize = 1.8,
			Swerve = 1, -- (as the Meadow's: QM, Oct 10; was 0.5)
			NestScale = 2.25,
			Length = 1920, -- (QM, Oct 11: the pacing ladder; was 5472)
			GroundColors = { Color3.fromRGB(228, 234, 242), Color3.fromRGB(244, 247, 251) },
			WallColors = { Color3.fromRGB(126, 164, 214), Color3.fromRGB(146, 182, 228) },
			Herd = { Penguin = 0.3, Boar = 0.25, Snowman = 0.22, IceGolem = 0.12, SnackYak = 0, Icebringer = 0.02 }, -- the Snack Yak never spawns: a Robux exclusive (QM, Oct 4)
			-- tools/snow_ground.py: cold grass a stud above the snow, ice ponds a stud below.
			Patches = {
				Grass = { Color3.fromRGB(80, 160, 166), Color3.fromRGB(96, 176, 180) },
				Ice = { Color3.fromRGB(160, 188, 244), Color3.fromRGB(178, 202, 250) },
			},
			UnlockCost = 300000, -- QM, Oct 8: matches the new button art (Oct 7 had $150k: the Tundra took too long to reach, "shorten it a BIT" (balance pass Oct 6 had it $300k, before that $100k)
			PostColor = Color3.fromRGB(126, 164, 214),
			GateImage = "rbxassetid://93384010922515", -- assets/ui/GateTundra.png
			GateColor = Color3.fromRGB(70, 220, 255), -- cyan (QM)
			UpgradeImage = "rbxassetid://105968538824751", -- assets/ui/UpgradePenTundraEnabled.png (QM, Oct 8: price drawn in)
			UpgradeImageDisabled = "rbxassetid://133303061216721", -- assets/ui/UpgradePenTundraDisabled.png: grey, while you can't afford it (QM, Oct 8: price drawn in)
		},
		{
			Name = "Ocean",
			AnimalSize = 2.6,
			Swerve = 1, -- (as the Meadow's: QM, Oct 10; was 0.25)
			NestScale = 2.5,
			Length = 3120, -- a whole number of 240-stud depth bands (QM, Oct 11: the pacing ladder; was 7680)
			GroundColors = { Color3.fromRGB(236, 214, 164), Color3.fromRGB(246, 228, 184) },
			WallColors = { Color3.fromRGB(236, 140, 124), Color3.fromRGB(250, 160, 142) }, -- salmon coral (QM)
			-- The Fish is a placeholder until the rest of the ocean animals are designed.
			HerdSpawnEvery = 0.45, -- (twice the stampede of the rest: it looked barren, QM Oct 11)
			Herd = { Fish = 0.1, Starfish = 0.3, Clownfish = 0.25, Whale = 0.05, Squid = 0.2, KingCrab = 0.15, FishSchool = 0.15, BlueCrab = 0.05, RoboShark = 0, Kraken = 0.05, Lionfish = 0.15 }, -- (the Lionfish Rare, a touch faster than the Starfish, QM Oct 11, weight a guess; the Clownfish Uncommon, a little rarer than the Starfish, QM Oct 11; Blue Crab guessed like the Kraken; the Robo Shark never spawns: a future Robux pet, QM Oct 4)
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
			UnlockCost = 10000000, -- QM, Oct 8: matches the new button art (Oct 7 had $5M: halved with the Tundra's ("same with ocean/godlands"); balance pass Oct 6 had it $10M, before that $1M
			PostColor = Color3.fromRGB(236, 140, 124),
			GateImage = "rbxassetid://75356296124042", -- assets/ui/GateOcean.png
			GateColor = Color3.fromRGB(30, 80, 220), -- deep blue (QM)
			UpgradeImage = "rbxassetid://86611519789045", -- assets/ui/UpgradePenOceanEnabled.png (QM, Oct 8: price drawn in)
			UpgradeImageDisabled = "rbxassetid://98686807740770", -- assets/ui/UpgradePenOceanDisabled.png: grey, while you can't afford it (QM, Oct 8: price drawn in)
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
			-- The volcano (QM, Oct 11): after the ocean, bright and warm, brown more than
			-- black (design/lava_biome). Floor, walls and nests: tools/volcano.py; its rocks:
			-- tools/biome_rocks.py; the big crack at its end: VolcanoCrack below.
			Name = "Volcano",
			AnimalSize = 2.6, -- (as the ocean's)
			Swerve = 1,
			NestScale = 2.5,
			Length = 5040, -- (QM, Oct 11: the pacing ladder; was 7680)
			GroundColors = { Color3.fromRGB(156, 98, 66), Color3.fromRGB(168, 108, 74) }, -- baked-earth brown
			WallColors = { Color3.fromRGB(170, 92, 58), Color3.fromRGB(186, 104, 66) },
			HerdSpawnEvery = 0.45, -- (twice the stampede, as the Ocean and Jurassic: QM Oct 11)
			Herd = { Firebird = 0.42, RockHog = 0.18, FireLobster = 0.17, Rockworm = 0.13, VolcanoTortoise = 0.1, Phoenix = 0.03, LavaWhale = 0.03 }, -- (QM, Oct 11: the Firebird Uncommon, the Rock Hog and Fire Lobster Rare, the Rockworm Epic, the Phoenix Legendary and very rare, the Lava Whale Epic and as rare as the Phoenix; the weights a guess)
			-- tools/volcano.py: lighter ash flush, darker crust plates a stud up, lava pools
			-- a stud down out by the walls.
			Patches = {
				Ash = { Color3.fromRGB(184, 124, 84), Color3.fromRGB(196, 134, 92) },
				Crust = { Color3.fromRGB(124, 78, 58), Color3.fromRGB(136, 86, 64) },
				Lava = { Color3.fromRGB(255, 116, 24), Color3.fromRGB(255, 146, 40) }, -- Neon
			},
			UnlockCost = 300000000, -- a guess (the old Godlands price)
			PostColor = Color3.fromRGB(170, 92, 58),
			GateColor = Color3.fromRGB(255, 110, 20), -- lava orange
			Sky = "rbxassetid://87302593393430", -- assets/ui/SkyVolcano.png: a flat lava orange (QM, Oct 11; Client/BiomeSky)
			-- How much that sky colours everything (the red-orange cast) and a tint over it
			-- (QM, Oct 11; Client/BiomeSky): Diffuse 0 to 1, Specular 0 to 1, Tint white for none.
			SkyLight = { Diffuse = 0, Specular = 1, Tint = Color3.new(1, 1, 1) }, -- (QM, Oct 11: no orange cast)
			-- No Upgrade Pen art yet: the plain button with the price.
		},
		{
			-- The Jurassic (QM, Oct 11): the final biome, after the volcano (design/jurassic_biome):
			-- darker jungle grass, a rough dirt trail down the middle, brown rocks, jungle plants
			-- and a giant ribcage halfway. Floor, walls, nests and ribcage: tools/jurassic.py;
			-- rocks and plants: tools/biome_rocks.py.
			Name = "Jurassic",
			AnimalSize = 2.6, -- (as the volcano's)
			Swerve = 1,
			NestScale = 2.5,
			Length = 7680, -- as long as the volcano was (a guess; its animals aren't on the ladder yet)
			HerdSpawnEvery = 0.15, -- (3x its stampede again: QM Oct 12; was 0.45, twice the rest, as the Ocean)
			GroundColors = { Color3.fromRGB(78, 140, 40), Color3.fromRGB(86, 152, 44) }, -- dark jungle grass
			WallColors = { Color3.fromRGB(150, 102, 62), Color3.fromRGB(164, 114, 70) },
			Herd = { Fish = 0, Spinosaurus = 0.2, TRex = 0.12, Raptor = 0.15, Pterodactyl = 0.08, Ankylosaurus = 0.25, PalmGuy = 0.25, BoneRex = 0.03 }, -- (the Bone Rex the final Legendary, as rare as the Phoenix, QM Oct 11; Palm Guy an Uncommon too, QM Oct 11, weight a guess; no more Fish: QM, Oct 11; the Ankylosaurus the Jurassic's Uncommon, QM Oct 11, weight a guess; the Pterodactyl an Epic, QM Oct 11; the Spinosaurus Rare, QM Oct 11; QM, Oct 11: fish for now, until the dinosaurs are designed; the T-Rex, an Epic, is the first; the Raptor a Rare that runs in packs of three (HerdPacks), so 0.15 is about a third of the stampede. Weights a guess)
			-- tools/jurassic.py: the dirt trail, flush.
			Patches = {
				Trail = { Color3.fromRGB(150, 104, 64), Color3.fromRGB(162, 114, 70) },
			},
			UnlockCost = 3000000000, -- a guess (10x the volcano)
			PostColor = Color3.fromRGB(150, 102, 62),
			GateColor = Color3.fromRGB(90, 200, 50), -- jungle green
			-- No Upgrade Pen art or boss yet (Config.Boss falls back to the Chicken).
		},
	},
	-- The gate across the corridor at a locked biome's line: its colour (the biome's GateColor, else this one) at the floor
	-- fading to clear this many studs up. Only you see it, until you unlock it.
	-- Zone gates on? Off (QM, Oct 8: new-loops): ride anywhere, no gates, no tutorial
	-- flight to the next gate. PenLevel still loads and saves as before.
	Gates = false,
	-- Breakable barriers instead (QM, Oct 9): the same sheets at each biome line (their
	-- colour alone, no card), shattering the first time you ride through, gone for good
	-- for you after (Gate.client; saved by Gold.server). They never stop you.
	BreakGates = true,
	-- The Upgrade Pen button (Hud): buys the next pen level at the next biome's
	-- UnlockCost. With the gates off it only grows and repaints your pen and swaps in
	-- that biome's training dummy (QM, Oct 8); past the last, the Rainbow Trail.
	-- Off (QM, Oct 11): claiming a quest upgrades your pen now (Quests, below).
	PenUpgrades = false,
	GateHeight = 26,
	GateColor = Color3.fromRGB(255, 204, 40),
	-- The course is a funnel (QM, Oct 8): CourseHalfWidth at the start line, each wall
	-- angled out CourseWidening studs per stud of course (one straight line), up to
	-- CourseMaxHalfWidth (reached at the Godlands line, which keeps that width). Full
	-- widths: Meadow 112-120, Desert 120-142, Snow 142-197, Ocean 197-274, Godlands 274.
	-- WorldColors.halfWidth(z) is the width at z. The place's walls, ground, obstacles
	-- and nests are moved to it by tools/funnel.luau (re-run it after a World push).
	-- The big lava crack at the volcano's end (QM, Oct 10-11: a geyser to launch you on
	-- to the next biome, later; for now it's only there). VolcanoCrack.client draws it
	-- with ViewportStencil (Shared/ViewportStencil) from the Model named Model in
	-- ReplicatedStorage: CrackMask and CrackInside, imported from design/volcano/VolcanoCrack.gltf
	-- (tools/volcano_crack.py). FromFinish: studs before the volcano's end (where the finish line was) its middle is.
	VolcanoCrack = {
		Model = "VolcanoCrack",
		FromFinish = 110,
		Yaw = 0,
		Brightness = 1.4, -- SurfaceGui.Brightness: a little over 1 so it glows
		MaxDistance = 900,
	},
	CourseHalfWidth = 56,
	CourseWidening = 0.005,
	CourseMaxHalfWidth = 137,
	CourseLength = 2168 + 1816 + 1920 + 3120 + 5040 + 7680, -- all the biomes' lengths added up (QM, Oct 10: no more Godlands; Oct 11: the Volcano after the Ocean, then the Jurassic, its end is the end; off its edge, the void)
	-- The Jurassic went on forever (QM, Oct 11: the temporary endgame): the course was
	-- cut at Cut (World.server: no far wall, no finish line) and the Length studs
	-- before it laid again and again past it (Client/Endless). Cut and Length are
	-- whole 16s, so the floor's checker keeps its step. nil: the course ends as before.
	-- (QM, Oct 13: off; World 1 ends at a giant portal to World 2 instead, EndPortal below.
	-- Was { Cut = -21504, Length = 1536 }.)
	Endless = nil,
	HomeHalfWidth = 176, -- tools/pens.py HALF_W: the arc base (QM, Oct 9; design/base_arc/SPEC.md)
	HomeDepth = 264, -- tools/pens.py DEPTH: the base runs this far back from the start line to its back wall
	StarterSpot = Vector3.new(0, 0, 20), -- where you start without a pen (players past the fifth)

	-- Ride
	MountSpeed = 44,
	RunSpeedLeeway = 0.1, -- Speed (2 m/s as the plates show it, x20): once you've reached the Desert, nothing you lasso in a run goes slower than the pet you left your pen on less this (Ride: QM, Oct 12: a Penguin's Rhino runs 1.62 and reaches the Tundra; before the Desert, no floor, so a new player's Horse's Fish keeps its own 0.6)
	ReturnSpeed = 88, -- 2x MountSpeed: the ride home twice as fast as the ride out (QM, Oct 11; was 1.6x, 70.4; at first 40)
	SteerSpeed = 28,
	-- Wider mounts steer quicker, gently (QM, Oct 8): x (1 + SteerWidthScale x (width
	-- over a horse's - 1)), so twice a horse's width steers 1.2x, three times 1.4x.
	SteerWidthScale = 0.2,
	SteerResponse = 8,
	-- Every ride out lasts RideSeconds (QM, Oct 10: no more stamina), the bar at the top
	-- draining with it, sprinting or not. Empty: you turn round on whatever you're riding
	-- and race it home, and a wild one's egg is yours over the line.
	RideSeconds = 33, -- (QM, Oct 11: "a bit easier to get to each biome", kids don't sprint all the way: was 30. Each biome's Epic now reaches the next line sprinting ~70% of the ride, was ~90%; its Rares only past ~83%)
	-- The boss when the ride's time runs out (QM, Oct 10: Client/BossChase): your animal
	-- stops dead, the biome's boss (Shared/Bosses: ByBiome; Kind for one with none) pops up Ahead studs in
	-- front, the camera's on its face (FaceAt: of its box, up and forward from the middle)
	-- from ZoomAt s (FaceFrom studs off it, between black
	-- bars sliding in over BarTime), and at CutsceneTime s you turn for home with it
	-- chasing at your speed (QM: the gap holds, so it's there at the end), never nearer than
	-- Behind studs, and pulling up StopShort studs short of the start line. Its anger vein,
	-- on the screen while the bars are in: VeinSize x the screen's height, at VeinAt (of
	-- the screen: by its head, in the strip), popping up, then
	-- VeinPopTime s on pulsing once VeinPulse x bigger over VeinPeriod s, and turning
	-- VeinSpin degrees a second.
	-- ByBiome: which boss (Shared/Bosses) each biome (Config.Biomes Name) gets; Kind for any other.
	Boss = {
		On = true, Kind = "Chicken", ByBiome = { Meadow = "Chicken", Desert = "CactusBoss", Snow = "ElderBoar", Ocean = "SharkBoss", Volcano = "LavaWyrm", Jurassic = "TyrantRex" }, Ahead = 140, -- (QM, Oct 10: twice as far, was 70)
		ZoomAt = 0.6, CutsceneTime = 2.8, BarTime = 0.35,
		-- (you turn for home at once, but the camera lingers behind you, on the boss, for
		-- Linger s as it starts after you, at ChaseMin studs/s at least: QM, Oct 11)
		Linger = 1, ChaseMin = 70,
		FaceAt = Vector3.new(0, 0.32, 0.25), FaceFrom = Vector3.new(0, 3, 20), Behind = 40, StopShort = 30,
		Room = { CactusBoss = 40, ElderBoar = 40, SharkBoss = 80, LavaWyrm = 60, TyrantRex = 50, Seraph = 60, CrystalTyrant = 40, CrystalSeraph = 60, CrimsonSeraph = 60, Monarch = 60 }, -- (studs more Ahead and Behind for the bigger ones, so they don't clip you: QM)
		CryVolume = { Chicken = 0.9, ElderBoar = 0.6, SharkBoss = 2.5, CactusBoss = 0.3, LavaWyrm = 0.8, TyrantRex = 1, CrystalTyrant = 0.3 }, -- (each boss's cry: QM, Oct 10)
		CryPitch = { CrystalTyrant = 0.7 }, -- (a cry's playback speed, so its pitch: the Crystal Tyrant's is the Cactus growl pitched down, QM, Oct 13)
		Faces = { -- (bosses whose faces sit elsewhere: At / From in place of FaceAt / FaceFrom)
			ElderBoar = { At = Vector3.new(0, 0, 0.45), From = Vector3.new(0, 5, 41) }, -- (it's 1.7x the size: QM)
			CactusBoss = { From = Vector3.new(0, 5, 34) }, -- (1.7x the size)
			SharkBoss = { At = Vector3.new(0, 0, 0.4), From = Vector3.new(36, 4, 16) }, -- (from its side, so you see its eye: QM)
			LavaWyrm = { At = Vector3.new(0.17, -0.06, 0.3), From = Vector3.new(0, 3, 58) }, -- (its head is out front and off to one side)
			TyrantRex = { At = Vector3.new(0.12, 0.4, 0.38), From = Vector3.new(20, 4, 48) }, -- (its eye and snout, from a little to one side: the jaw hangs open)
			Seraph = { At = Vector3.new(0, -0.15, 0.18), From = Vector3.new(0, 4, 60) }, -- (its big eye, low in the middle of its wings; a guess)
			CrimsonSeraph = { At = Vector3.new(0, -0.15, 0.18), From = Vector3.new(0, 4, 60) }, -- (as the Seraph's)
			CrystalSeraph = { At = Vector3.new(0, -0.15, 0.18), From = Vector3.new(0, 4, 60) }, -- (as the Seraph's)
			Monarch = { At = Vector3.new(0, 0, 0.12), From = Vector3.new(0, 16, 75) }, -- (its head, from further out and above so the wings frame it: Studio saw the head too high from (0,4,50))
			CrystalTyrant = { At = Vector3.new(0, 0.02, 0.48), From = Vector3.new(0, 4, 34) }, -- (its eyes and teeth, halfway up: the crown makes it tall)
		},
		VeinSize = 0.16, VeinAt = Vector2.new(0.67, 0.317), VeinPopTime = 0.35, VeinPulse = 0.3, VeinPeriod = 0.4, VeinSpin = 25,
		-- On the run home it cries again every so often (QM, Oct 11): its opening cry, the
		-- screen shaking and the red vignette surging with how loud the cry is (BossChase.roar).
		-- First s after the close-up, then every Every[1] to Every[2] s; Shake degrees and
		-- ShakeMove studs at its loudest.
		Roar = { On = true, First = 3, Every = { 10, 10 }, Shake = 0.8, ShakeMove = 0.35 }, -- (every 10 s: QM, Oct 11; was 5 to 8)
	},
	TerrainSaturation = 1, -- x the ground's, floor tiles' and walls' colour saturation (WorldColors.saturate): 1 leaves them as they are (QM, Oct 6: tried 1.15 and 1.05, back to the original)
	-- Studs as a material (QM, Oct 7, FPS): parts get the "Studs" (1 stud) or "StudsHalf"
	-- (0.5 stud) MaterialVariant from MaterialService instead of a stud Texture per face,
	-- which cut tens of thousands of textures. Off (or those variants missing from
	-- MaterialService): the stud Textures as before. Shared/Studs.
	StudMaterial = true,
	Sky = "Flat", -- (QM, Oct 9: back to Oct 5 evening's flat sky) "Anime" (the Creator Store's Anime sky, QM Oct 6) or "Flat" (one flat #59D9FD): World.server
	WalkSpeed = 48, -- on foot, studs a second (Roblox's default is 16; QM, Oct 9: 3x, was 2x)
	HomeSafeZone = 40, -- studs before the start line where a rider bringing an egg home can't be crashed: an animal popping in as they cross felt like bad faith (QM, Oct 6)
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
		DespawnBiome = "Jurassic", -- it runs off (gone) as it reaches this biome (QM, Oct 11: the Jungle)
	},
	-- Any pet can be ridden. Until pets can be picked in the pen, you ride this one
	-- (it waits on the first pet spot in your pen).
	DefaultPet = "Horse",
	-- Seconds an egg placed in your pen takes to hatch: PetHatchTime by the animal
	-- inside (QM's pets JSON, Oct 4), else HatchTime by its rarity.
	-- By rarity from the Desert on (QM, Oct 11: no cliffs, ~5 runs a biome): each biome's
	-- Epics are what carry you into the next one (the pacing ladder, below AnimalStats),
	-- so they take ~5 runs to hatch; Uncommons and Rares hatch within a run, so every run
	-- pays out. Legendaries hatch slower (PetHatchTime: QM's D1 retention eggs).
	HatchTime = { Uncommon = 15, Rare = 60, Epic = 300, Legendary = 480 },
	PetHatchTime = {
		-- (QM's spawn/hatch JSON, Oct 11, applied as given: the Herd weights in Biomes too)
		-- QM's own table (Oct 11, "new json"): every animal's egg, by biome. Uncommons and Rares
		-- hatch within a run, each biome's Epics a little longer, the Legendaries are the long
		-- D1 eggs you come back for.
		Horse = 15, ArmoredHorse = 15, Pinto = 15, Pig = 15, Bunny = 15, Fish = 45, Rhino = 120, Unicorn = 300, MarbleFish = 15, Lion = 60, Buffalo = 60, Crocodile = 60, MarbleColossus = 120, MajesticUnicorn = 300, -- Meadow (the Marble Fish, Lion, Marble Colossus and Majestic Unicorn: World 2's, as the Pinto, a Rare, the Rhino and Unicorn)
		Cactus = 15, Kitten = 15, Scorpion = 60, Sandworm = 75, SpineLizard = 90, Snake = 600, -- Desert
		Eyeworm = 15, CrimsonScorpion = 15, Maw = 60, IvorySpider = 75, Asura = 600, -- World 2 Crimson Lands
		Caterpillar = 15, -- World 2 Woodland Maze (as the Starfish)
		Penguin = 15, Boar = 15, Snowman = 60, IceGolem = 120, Icebringer = 900, SnackYak = 3600, CrystalCentipede = 15, RedMushroom = 15, BrownMushroom = 60, PurpleMushroom = 120, BlueCrystal = 15, PinkCrystal = 60, CrystalSpider = 120, CrystalPhoenix = 120, CrystalElephant = 900, -- Tundra (World 2's Crystal Cavern animals, as the Penguin, Boar, Snowman and Ice Golem; the Living Crystals as the Boar and Snowman)
		Starfish = 15, Clownfish = 15, PinkButterfly = 15, Whale = 60, Lionfish = 35, Squid = 45, KingCrab = 300, FishSchool = 200, BlueCrab = 800, Kraken = 1200, GiantGolem = 1200, -- Ocean
		OrangeButterfly = 35, -- World 2 Woodland Maze (the Orange Butterfly a Rare, as the Lionfish)
		LivingBirch = 35, -- World 2 Woodland Maze (a Rare, as the Lionfish, until QM sets it)
		Hawkmoth = 45, -- World 2 Woodland Maze's Hawkmoth (Epic, as the Squid until QM sets it)
		RollingLog = 35, -- World 2 Woodland Maze (as the Lionfish)
		Tiger = 60, -- World 2 Temple (a Rare, as the Fire Lobster)
		JadeStatue = 300, GarnetStatue = 300, -- World 2 Temple's Epics (as the Rockworm until QM sets them)
		Firebird = 15, RockHog = 60, FireLobster = 60, VolcanoTortoise = 60, Rockworm = 300, LavaWhale = 300, Phoenix = 43200, Kitsune = 43200, -- Volcano
		Catfish = 15, -- World 2 Temple (as the Firebird)
		Fox = 15, NineTailedFox = 60, -- World 2 Temple (the Fox an Uncommon as the Firebird, the Nine-tailed Fox a Rare as the Fire Lobster, until QM sets them)
		Ankylosaurus = 15, PalmGuy = 15, Spinosaurus = 60, Raptor = 60, TRex = 190, Pterodactyl = 90, BoneRex = 43200, -- Jurassic
		Beholder = 2700, Sludge = 2400, WarElephant = 3600, Leviathan = 7200, SoulHorse = 9600, -- Godlands
		RoboShark = 57600, Loong = 86400, -- exclusives
		Seraph = 3600, CrimsonSeraph = 3600, CrystalSeraph = 3600, -- World 2's trophy angels, 1 in 300 of their stampedes (QM, Oct 13; the hatch a guess)
	},
	-- The first-time tutorial (Tutorial.luau): a new player places their first egg
	-- (a DefaultPet egg, hatching in TutorialHatchTime seconds), rides that pet and
	-- brings home an egg, one hint at a time and only the buttons each step needs.
	-- false turns it off (QM, Oct 8: off, to be redone from scratch). On that first ride the stampede runs on the player's own
	-- clock so it can slow down to TutorialSlowMo x speed, and ever slower from there
	-- (TutorialSlowDeepen), while LASSO or TAKE EGG is waiting to be pressed, and the
	-- Hold bar never runs out. The tutorial's eggs hatch by themselves
	-- (TutorialHatchTime); every other egg waits for you to hold F by it once it's
	-- ready (Hatchery, Pen.client).
	Tutorial = true, -- (QM, Oct 11: back, redone: Client/Intro, then Client/Tutorial)
	TutorialHatchTime = 0,
	TutorialRideSeconds = 20, -- the BOSS IN timer on the tutorial's ride (QM: not far enough to reach the Desert)
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
	NativePrompts = false, -- Roblox's own interact prompts instead of ours (Client/PromptUi), to compare (QM, Oct 10)
	AbilitiesOn = false, -- (QM, Oct 10: off till the riding UX is settled; Abilities below stay as they are)
	Abilities = {
		Rhino = { Kind = "Charge", Duration = 4, Cooldown = 7, SpeedBoost = 1.2 },
		SnackYak = { Kind = "Charge", Duration = 10, Cooldown = 5, SpeedBoost = 2 }, -- QM, Oct 4; a fixed 10 s since Oct 8 (no more stamina to charge "until full")
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
	--     run into it are stuck, crawling, for a moment (Client/PetTrails).
	--   SpikeTrail (Soul Horse): it leaves the wild Soul Horse's spikes behind it; stampede
	--     animals that run into one are killed, whatever their size (they never crash you).
	-- OnReturn (QM, Oct 4): the special also runs on the ride home with the egg, while
	-- you sprint.
	SprintSpecials = {
		Unicorn = { Kind = "Smash", Radius = 14, ScareRadius = 30, OnReturn = true }, -- scares animals within ScareRadius off (QM, Oct 4; no more Hold back for each: QM, Oct 11)
		Sandworm = { Kind = "Burrow", OnReturn = true },
		Whale = { Kind = "Fly", Height = 56 },
		Phoenix = { Kind = "Fly", Height = 56 }, -- QM, Oct 11: "fly like the whale"
		CrystalPhoenix = { Kind = "Fly", Height = 56 }, -- QM, Oct 13: "flying sprint like normal phoenix"
		OrangeButterfly = { Kind = "Fly", Height = 56 }, -- World 2 Woodland Maze: flies like the Crystal Phoenix (QM, Oct 13)
		Hawkmoth = { Kind = "Fly", Height = 56 }, -- (Oct 13) a flyer like the Crystal Phoenix
		Pterodactyl = { Kind = "Fly", Height = 56 }, -- QM, Oct 11: a flying type, like the Phoenix
		PinkButterfly = { Kind = "Fly", Height = 56 }, -- World 2 Woodland: a flier like the Crystal Phoenix (Oct 13)
		BoneRex = { Kind = "Smash", Radius = 60, ScareRadius = 60, OnReturn = true }, -- QM, Oct 11: scares animals off and smashes every obstacle in a massive radius (60 studs: a guess; the Unicorn's is 14 / 30)
		-- The Beholder (QM, Oct 4; it has no ability): floats up over everything like the
		-- Whale, a pink haze round the screen, and scares the animals round it off.
		Beholder = { Kind = "Fly", Height = 24, ScareRadius = 30, Haze = Color3.fromRGB(255, 110, 210) }, -- height and radius are guesses
		Leviathan = { Kind = "Flame", Range = 5, Width = 9, OnReturn = true }, -- QM, Oct 4: "like 1m ahead" (4 studs a metre; the width is a guess)
		Loong = { Kind = "Loom", Grow = 1.2, Radius = 40 }, -- QM: 1.2x; the radius is a guess
		SoulHorse = { Kind = "SpikeTrail" }, -- QM, Oct 4: the wild Soul Horse's spike trail behind it; stampede animals that run into a spike are killed (Client/PetTrails)
		Sludge = { Kind = "Goo", OnReturn = true }, -- QM, Oct 4: the wild Sludge's sludge trail; stampede animals that run into it get stuck and fall behind (Client/PetTrails)
		BlueCrab = { Kind = "Crabwalk", SpeedBoost = 1.2, OnReturn = true }, -- QM, Oct 4 (QM, Oct 11: no more Hold back per animal it hits: passives leave the timer alone)
	},
	-- Size tiers (any whole number, bigger is bigger). Racing home, a pet plows
	-- through stampede animals of a lower tier; one of its own tier or higher
	-- crashes it. Obstacles never crash you: every one is smashed on contact (QM,
	-- Oct 6); their tier (model "Tier" attribute, else ObstacleTiers by name) only
	-- decides which ones some abilities break.
	PetTiers = {
		Horse = 1, ArmoredHorse = 1, Pig = 1, Bunny = 1, Pinto = 1, Fish = 1, Rhino = 2, Unicorn = 2, MarbleFish = 1, Lion = 1, Buffalo = 2, Crocodile = 1, MarbleColossus = 2, MajesticUnicorn = 2, -- Meadow
		Cactus = 1, Kitten = 1, Scorpion = 1, Sandworm = 2, SpineLizard = 2, Snake = 3, -- Desert
		Eyeworm = 1, CrimsonScorpion = 1, Maw = 1, IvorySpider = 2, Asura = 3, -- World 2 Crimson Lands (the Asura large, QM)
		Caterpillar = 1, -- World 2 Woodland Maze
		Penguin = 1, Boar = 1, Snowman = 1, IceGolem = 2, SnackYak = 2, Icebringer = 3, CrystalCentipede = 1, RedMushroom = 1, BrownMushroom = 1, PurpleMushroom = 2, BlueCrystal = 1, PinkCrystal = 1, CrystalSpider = 2, CrystalPhoenix = 2, CrystalElephant = 3, -- Tundra
		Starfish = 1, Clownfish = 1, PinkButterfly = 1, Squid = 2, KingCrab = 2, FishSchool = 2, BlueCrab = 2, RoboShark = 1, Whale = 4, Kraken = 4, Lionfish = 1, LivingBirch = 2, GiantGolem = 3, -- Ocean (the Robo Shark starts small and grows as it hunts)
		OrangeButterfly = 1, -- World 2 Woodland Maze (as the Lionfish)
		Hawkmoth = 2, -- World 2 Woodland Maze
		RollingLog = 1, -- World 2 Woodland Maze
		Tiger = 1, -- World 2 Temple (the Lion's body)
		JadeStatue = 2, GarnetStatue = 2, -- World 2 Temple
		Firebird = 2, RockHog = 2, FireLobster = 2, Rockworm = 2, VolcanoTortoise = 2, Phoenix = 3, LavaWhale = 4, Kitsune = 3, -- Volcano (guesses; the Lava Whale XL like the Whale)
		Catfish = 1, -- World 2 Temple (Fish-sized)
		Fox = 1, NineTailedFox = 2, -- World 2 Temple (the Fox under the Horse's size; the Nine-tailed Fox's fan of tails)
		TRex = 4, Raptor = 2, -- Jurassic (QM: the T-Rex as big as the Whale; the Raptor smaller)
		Spinosaurus = 4, -- Jurassic (QM: slightly smaller than the T-Rex: AnimalScale 0.85)
		Ankylosaurus = 3, -- Jurassic (a guess: a wide armoured tank, under the T-Rex)
		PalmGuy = 2, -- Jurassic (QM: a bit bigger than the Cactus)
		Pterodactyl = 1, -- Jurassic (QM: a small animal; AnimalScale 2 so its body is as big as a Horse's under the long wings)
		BoneRex = 4, -- Jurassic (the final Legendary: the T-Rex's size, AnimalScale 1.15 so it towers over it)
		WarElephant = 3, SoulHorse = 2, -- Godlands (QM: large, medium)
		Loong = 1, Beholder = 2, Sludge = 2, Leviathan = 2, -- Godlands (starts small, grows to XL as its breath burns animals: Abilities.Loong)
		Seraph = 3, CrimsonSeraph = 3, CrystalSeraph = 3, -- World 2's trophy angels (large, like the Asura)
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
	RideZoomPerTier = 1, -- (QM, Oct 9: riding always the same plain view; was 1.2)
	RideCamSeat = 9, -- how high a Horse's rider sits (studs); on anything taller the ride out's camera rises by the difference (QM, Oct 11)
	ObstacleTiers = {
		Bush = 1, Rock = 2, Stone = 1, Sandstone = 1, -- small
		Boulder = 2, BoulderSplit = 2, Cactus = 2, SandBoulder = 2, SandBoulderCarved = 2, -- medium
		SandMound = 3, -- large
		Icicle = 1, Pine = 2, IcicleLarge = 2, IceBoulder = 3, -- snow: small, medium, medium, large
		TubeCoral = 1, BrainCoral = 1, BranchCoral = 2, FanCoral = 2, ReefRock = 3, -- ocean
		BasaltRock = 2, Vent = 3, -- the deep ocean
		DeadBush = 1, DarkStone = 1, DeadTree = 2, Crag = 2, LavaRock = 3, -- Godlands
		Fern = 1, Horsetail = 1, Cycad = 2, JungleTree = 3, -- Jurassic
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
	-- FUSE's ("Merge") price (Shared/Fusion.price; QM, Oct 11: cash should matter): this many
	-- seconds of what the two pets earn between them (PetIncome, a hybrid's saved income), so
	-- two Kittens ~$9k, two Snowmen ~$110k: a minute or two of a pen's gold wherever you are.
	-- The fuse lesson's fuse is free (FuseLesson). (Was by rarity, FusePrice x 0.01.)
	FusePriceSeconds = 90, -- (merging 2x cheaper: QM, Oct 12; was 180)
	-- A hybrid's Speed: the faster one's plus this share of the slower one's (QM, Oct 11; was
	-- 1/2, which let two Desert Kittens reach the Ocean). Two equal pets come out 1.15x, one
	-- rarity step on the pacing ladder: two Rares merge to an Epic's speed, a way past the gate
	-- that costs gold instead of waiting on the Epic's egg. Hybrids made before keep theirs.
	FuseSpeedShare = 0.15,
	-- (Shared/Fusion.worth: what went into a hybrid, by rarity; kept on saves, no longer priced.)
	FusePrice = { Common = 100, Uncommon = 1000, Rare = 10000, Epic = 100000, Legendary = 1000000 },
	PetSmallSize = 10.4,
	-- Each animal's look, x its size from above (QM, Oct 11: set from the Studio lineup,
	-- tools/lineup.luau). Only how big it looks: its tier, and so what it plows through
	-- or crashes into, is PetTiers'. Unlisted: 1.
	AnimalScale = { BoneRex = 1.15, PalmGuy = 1.15, Pterodactyl = 2, Spinosaurus = 0.85, LavaWhale = 2.5, VolcanoTortoise = 2.5, RockHog = 1.5, Phoenix = 2, CrystalPhoenix = 2, Hawkmoth = 1.5, CrimsonScorpion = 0.75, Crocodile = 2, Lion = 2, MarbleColossus = 1.6, MajesticUnicorn = 1.4, IvorySpider = 2, Maw = 0.8, Eyeworm = 1.2, CrystalCentipede = 2, CrimsonSeraph = 1.5, CrystalSeraph = 2 }, -- (QM, Oct 11; the Crimson Scorpion smaller than the Scorpion, Oct 13; Crocodile and Lion 2x, Marble Colossus 1.6x, Majestic Unicorn 1.4x, Ivory Spider 2x, Maw 0.8x, Eyeworm 1.2x, Crystal Centipede 2x, Oct 13; the Crimson Seraph 1.5x and Crystal Seraph 2x, the Seraph 1x)
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
	-- every second while you're in the game. (QM, Oct 8 evening: progression 2x faster, so
	-- x3 QM's pets JSON: rides don't get quicker, so the gold has to more than double.)
	PetIncome = {
		Horse = 3, ArmoredHorse = 3, Pig = 9, Bunny = 12, Pinto = 15, Fish = 24, Rhino = 90, Unicorn = 450, MarbleFish = 15, Lion = 24, Buffalo = 30, Crocodile = 24, MarbleColossus = 90, MajesticUnicorn = 450, -- Meadow
		Cactus = 18, Kitten = 24, Scorpion = 60, Sandworm = 180, SpineLizard = 240, Snake = 750, -- Desert
		Eyeworm = 18, CrimsonScorpion = 24, Maw = 60, IvorySpider = 180, Asura = 750, -- World 2 Crimson Lands
		Caterpillar = 300, -- World 2 Woodland Maze (as the Starfish)
		Seraph = 4500, CrimsonSeraph = 7500, CrystalSeraph = 33330, -- World 2's trophy angels (QM, Oct 13: slow but earn a lot): 10x their biome's Legendary (the Majestic Unicorn, Asura, Crystal Elephant)
		Penguin = 75, Boar = 150, Snowman = 300, IceGolem = 1260, SnackYak = 9000, Icebringer = 3333, CrystalCentipede = 75, RedMushroom = 150, BrownMushroom = 300, PurpleMushroom = 1260, BlueCrystal = 150, PinkCrystal = 300, CrystalSpider = 1260, CrystalPhoenix = 1260, CrystalElephant = 3333, -- Tundra
		Starfish = 300, Clownfish = 700, PinkButterfly = 700, Squid = 2100, KingCrab = 2850, FishSchool = 2550, BlueCrab = 18000, RoboShark = 57000, Whale = 4500, Kraken = 24600, Lionfish = 1500, GiantGolem = 24600, -- Ocean
		OrangeButterfly = 1500, -- World 2 Woodland Maze (as the Lionfish until QM sets it)
		LivingBirch = 1500, -- World 2 Woodland Maze Rare (the Lionfish's, until QM sets it)
		Hawkmoth = 2100, -- World 2 Woodland Maze (as the Squid)
		RollingLog = 1500, -- World 2 Woodland Maze (as the Lionfish)
		Tiger = 20000, -- World 2 Temple (as the Fire Lobster)
		JadeStatue = 25000, GarnetStatue = 25000, -- World 2 Temple (as the Rockworm)
		Firebird = 12000, RockHog = 20000, FireLobster = 20000, Rockworm = 25000, VolcanoTortoise = 30000, Phoenix = 45000, LavaWhale = 40000, Kitsune = 45000, -- Volcano (guesses: past the Ocean's)
		Catfish = 12000, -- World 2 Temple (as the Firebird)
		Fox = 12000, NineTailedFox = 20000, -- World 2 Temple (the Firebird's and Fire Lobster's, until QM sets them)
		TRex = 60000, Raptor = 40000, -- Jurassic (guesses: past the Volcano's)
		Spinosaurus = 40000, -- Jurassic (a guess: a Rare, under the T-Rex)
		Pterodactyl = 60000, -- Jurassic (a guess: an Epic, as the T-Rex)
		Ankylosaurus = 25000, -- Jurassic (a guess: an Uncommon, past the Volcano's Rares)
		PalmGuy = 22000, -- Jurassic (a guess: an Uncommon, a touch under the Ankylosaurus)
		BoneRex = 100000, -- Jurassic (a guess: the final Legendary, the best earner)
		Loong = 60000, Beholder = 9000, Leviathan = 45000, -- Godlands (QM's pets JSON, Oct 4; the Godlands' raised in the balance pass, Oct 6,
		WarElephant = 12000, SoulHorse = 60000, Sludge = 7500, -- so they pay more than the Ocean's)
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
		On = false, -- (QM, Oct 12: Carl's gone; a stone portal gate, World.BaseDecor.PortalGate, now stands left of the start line at (-63.5, 24.6), its opening swirling (Client/PortalFx), doing nothing yet)
		Position = Vector3.new(-104, 0, 20), -- the arc base's front left corner, beside the corridor (QM, Oct 9)
		Yaw = 15, -- degrees it turns in toward the course, off square with the wall (QM)
		Reach = 12, -- studs from the counter where Talk shows
	},
	-- The podium (Leaderboard.server, QM Oct 4): the avatar of the player who rode
	-- furthest from base, all time (OrderedDataStore "BestDistance", metres), standing on
	-- QM's cream marble column in the middle of a coiled grass snake (Props/GrassSnake,
	-- PodiumSnake.client), in the base's right front corner, their username and best
	-- distance over their head (QM, Oct 5).
	-- Rarity text colours (QM, Oct 7): pet nameplates, the ride and egg prompts' names.
	RarityColors = {
		Common = Color3.fromHex("DDDDDD"), -- (QM, Oct 10; was 150, 160, 175)
		Uncommon = Color3.fromHex("43FA00"),
		Rare = Color3.fromHex("40D6FF"),
		Epic = Color3.fromHex("FF7CC6"),
		Legendary = Color3.fromHex("5CE6B7"),
	},
	Podium = {
		Position = Vector3.new(63.5, 0, 24.6), -- the column, on the ground, mirroring the portal gate across the start line (QM, Oct 12; was 104, 20, the front right corner); the snake reaches ~-8..+16 in x, -14..+31 in z
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
		ArmoredHorse = "rbxassetid://96698232796495", -- the Horse's (QM, Oct 13)
		Pinto = "rbxassetid://79525419811481",
		Pig = "rbxassetid://139970505549400",
		Bunny = "rbxassetid://102165948456968", -- assets/ui/BunnyEggRender.png
		Fish = "rbxassetid://105098230793344",
		Rhino = "rbxassetid://139482781062355",
		MarbleColossus = "rbxassetid://110439659872687", -- assets/ui/MarbleColossusEggRender.png (World 2)
		CrystalCentipede = "rbxassetid://101332917430774", -- assets/ui/CrystalCentipedeEggRender.png (World 2)
		MajesticUnicorn = "rbxassetid://112045413530937", -- assets/ui/MajesticUnicornEggRender.png (World 2)
		RedMushroom = "rbxassetid://102610484944753", -- assets/ui/RedMushroomEggRender.png (World 2)
		BrownMushroom = "rbxassetid://84196239547123", -- assets/ui/BrownMushroomEggRender.png (World 2)
		PurpleMushroom = "rbxassetid://132151928968903", -- assets/ui/PurpleMushroomEggRender.png (World 2)
		MarbleFish = "rbxassetid://121162393893227", -- assets/ui/MarbleFishEggRender.png (World 2)
		BlueCrystal = "rbxassetid://112194074349421", -- assets/ui/BlueCrystalEggRender.png (World 2)
		PinkCrystal = "rbxassetid://117236752430565", -- assets/ui/PinkCrystalEggRender.png (World 2)
		Lion = "rbxassetid://82682007346790", -- assets/ui/LionEggRender.png (World 2)
		Buffalo = "rbxassetid://118027620960011", -- assets/ui/BuffaloEggRender.png (World 2)
		Crocodile = "rbxassetid://138455431560057", -- assets/ui/CrocodileEggRender.png (World 2)
		CrystalSpider = "rbxassetid://98286776885826", -- assets/ui/CrystalSpiderEggRender.png (World 2)
		Eyeworm = "rbxassetid://132028611021169", -- assets/ui/EyewormEggRender.png (World 2)
		Maw = "rbxassetid://121895939250438", -- assets/ui/MawEggRender.png (World 2)
		IvorySpider = "rbxassetid://79662614434978", -- assets/ui/IvorySpiderEggRender.png (World 2)
		Asura = "rbxassetid://113695299206853", -- assets/ui/AsuraEggRender.png (World 2)
		CrimsonScorpion = "rbxassetid://126802958042799", -- assets/ui/CrimsonScorpionEggRender.png (World 2)
		CrystalPhoenix = "rbxassetid://137731947260447", -- assets/ui/CrystalPhoenixEggRender.png (World 2; scaled to 941 x 1000)
		CrystalElephant = "rbxassetid://105220500829443", -- assets/ui/CrystalElephantEggRender.png (World 2)
		Seraph = "rbxassetid://129763838096024", -- assets/ui/SeraphEggRender.png (World 2)
		CrimsonSeraph = "rbxassetid://132120882288488", -- assets/ui/CrimsonSeraphEggRender.png (World 2)
		CrystalSeraph = "rbxassetid://100476636621954", -- assets/ui/CrystalSeraphEggRender.png (World 2)
		Caterpillar = "rbxassetid://109185103681711", -- assets/ui/CaterpillarEggRender.png (World 2)
		PinkButterfly = "rbxassetid://139551342957176", -- assets/ui/PinkButterflyEggRender.png (World 2)
		OrangeButterfly = "rbxassetid://136557216823067", -- assets/ui/OrangeButterflyEggRender.png (World 2)
		LivingBirch = "rbxassetid://78918914654470", -- assets/ui/LivingBirchEggRender.png (World 2)
		GiantGolem = "rbxassetid://130649889910224", -- assets/ui/GiantGolemEggRender.png (World 2)
		Hawkmoth = "rbxassetid://111594299533130", -- assets/ui/HawkmothEggRender.png (World 2)
		RollingLog = "rbxassetid://125301165432908", -- assets/ui/RollingLogEggRender.png (World 2)
		Catfish = "rbxassetid://136135901593127", -- assets/ui/CatfishEggRender.png (World 2)
		Tiger = "rbxassetid://112691374931555", -- assets/ui/TigerEggRender.png (World 2)
		JadeStatue = "rbxassetid://106883633786837", -- assets/ui/JadeStatueEggRender.png (World 2)
		GarnetStatue = "rbxassetid://121784684526161", -- assets/ui/GarnetStatueEggRender.png (World 2)
		Fox = "rbxassetid://92522948167443", -- assets/ui/FoxEggRender.png (World 2)
		NineTailedFox = "rbxassetid://110560724842212", -- assets/ui/NineTailedFoxEggRender.png (World 2)
		Kitsune = "rbxassetid://124688776792586", -- assets/ui/KitsuneEggRender.png (World 2)
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
		VolcanoTortoise = "rbxassetid://89848692685766", -- assets/ui/VolcanoTortoiseEggRender.png
		Firebird = "rbxassetid://100787444937359", -- assets/ui/FirebirdEggRender.png
		RockHog = "rbxassetid://82336240433052", -- assets/ui/RockHogEggRender.png
		Rockworm = "rbxassetid://105149417332337", -- assets/ui/RockwormEggRender.png
		FireLobster = "rbxassetid://83951862994609", -- assets/ui/FireLobsterEggRender.png
		Phoenix = "rbxassetid://77371080716061", -- assets/ui/PhoenixEggRender.png
		LavaWhale = "rbxassetid://137754762277353", -- assets/ui/LavaWhaleEggRender.png
		TRex = "rbxassetid://132088301588431", -- assets/ui/TRexEggRender.png
		Raptor = "rbxassetid://86585294053216", -- assets/ui/RaptorEggRender.png
		Spinosaurus = "rbxassetid://118684084308728", -- assets/ui/SpinosaurusEggRender.png
		Pterodactyl = "rbxassetid://125349573529100", -- assets/ui/PterodactylEggRender.png
		Ankylosaurus = "rbxassetid://117144807245289", -- assets/ui/AnkylosaurusEggRender.png
		PalmGuy = "rbxassetid://119803210932578", -- assets/ui/PalmGuyEggRender.png
		BoneRex = "rbxassetid://139955585467041", -- assets/ui/BoneRexEggRender.png
		Starfish = "rbxassetid://114368032731288", -- assets/ui/StarfishEggRender.png
		Lionfish = "rbxassetid://114164241366433", -- assets/ui/LionfishEggRender.png
		Clownfish = "rbxassetid://130227469695086", -- assets/ui/ClownfishEggRender.png
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
	PetSprintSpeed = { Loong = 4, Seraph = 10, CrimsonSeraph = 10, CrystalSeraph = 10 }, -- these sprint at this x instead (QM, Oct 4; the Seraphs, Oct 13: slow in the stampede, very fast ridden)
	OutboundSprint = true, -- the ride out always a sprint too (QM, Oct 11)
	-- Just lassoed onto an animal it's still at its stampede walk: for Time s it builds up to
	-- the sprint at Rate studs/s a second (not the usual snap), so you see it break into it.
	LandRamp = { Time = 2.5, Rate = 35 },
	ReturnSprint = true, -- the ride home always a sprint (SprintSpeed x ReturnSpeed)? On again (QM, Oct 11; Oct 10 had it off, Shift to sprint)
	ReturnFovKick = 0, -- (QM, Oct 9: plain, was 20) degrees added to the field of view on the ride home, to feel faster (0 = off)
	-- The feel of speed (QM, Oct 7; Client/SpeedFx): Speed is uncapped, but rides travel
	-- straight up to Knee studs/s and then bend off towards Max; speed lines and a wider
	-- view (up to MaxFov) grow from Start studs/s. Each part off with On = false.
	SpeedCurve = { On = true, Knee = 500, Max = 900 }, -- (QM, Oct 11: was 400 / 700 before the pacing ladder; the Phoenix sprints at 614)
	-- Speed lines and a wider view (SpeedFx), only while sprinting (QM, Oct 8: none
	-- otherwise, and a lot more of them): at Min strength on the slowest sprint, rising
	-- with speed as (speed / Ref) ^ Curve (a square root: quick to build, gentle at the
	-- top) to full at Ref studs/s and over. Lines, their Opacity and LineSpeed, and
	-- FovKick degrees wider (up to MaxFov), all at full strength.
	-- Speed lines while you sprint (QM, Oct 9; drawn on the screen, Oct 11: Client/SpeedLines):
	-- Rate a second at Speed studs/s (a sprint), more or fewer with your speed up to
	-- MaxScale x, none otherwise. Each starts From of the way from the middle to a corner
	-- and shoots Travel further out over Life seconds, Length by Thickness pixels (on a
	-- 1000 px tall screen), white at Opacity at its most solid. Zoom: the whole effect's
	-- size on the screen (over 1 spreads it out past the edges, under 1 pulls it in).
	SpeedLines = { On = true, Zoom = 1.2, Rate = 200, Speed = 88, MaxScale = 2, From = 0.5, Travel = 0.8, Life = 0.32, Length = 200, Thickness = 9, Opacity = 0.6 }, -- (QM's tuning, Oct 11)
	-- The sprint camera (QM, Oct 9; Client/SprintCam): sprinting, the view widens to Fov
	-- degrees (a fisheye-like stretch at the edges) and the camera comes in to Zoom x
	-- its usual distance, easing in over InTime seconds and back over OutTime.
	-- Steering on the way out of your pen to the start line (QM, Oct 9; Ride's exit path):
	-- you steer just as on the course, anywhere that still ends up across the start line
	-- (its half width less Margin studs), the room growing from GateRoom studs either
	-- side in your pen's gap. It eases off toward the edges and never reaches them,
	-- however slow the pet (checked from every pen at the biggest pen size: clear of
	-- the pens, walls, Carl and the podium).
	ExitSteer = { GateRoom = 3, Margin = 6 },
	-- The run home's red vignette (QM, Oct 9; Client/ReturnVignette): pulses in over
	-- InTime seconds and out over OutTime, its ImageTransparency between MaxTransparency
	-- (out) and MinTransparency (in), from turning round till the leap over the line.
	ReturnVignette = { On = true, InTime = 0.4, OutTime = 0.6, MinTransparency = 0, MaxTransparency = 1 },
	-- A white trail off you while your mount sprints (QM, Oct 9; Client/SprintTrail):
	-- Life seconds long at HorseSprint studs/s (a horse's sprint: a short streak), longer
	-- the faster it goes, up to MaxLife. Built like VIP's gold trail (Shared/RiderTrail).
	SprintTrail = { On = true, Life = 0.12, HorseSprint = 88, MaxLife = 0.6, Transparency = 0.55 }, -- (Transparency at you: half VIP's opacity, QM)
	-- How much scales with your speed (QM, Oct 9): x speed / HorseSprint (a horse's sprint
	-- gets Fov / Zoom as set), between MinScale and MaxScale.
	-- Creep: within a sprint tier the fisheye grows only this share of what the speed
	-- alone would give; crossing into a new tier snaps it up (QM, Oct 9).
	SprintCam = { On = true, Fov = 95, Zoom = 0.75, InTime = 0.3, OutTime = 0.5, HorseSprint = 88, MinScale = 0.5, MaxScale = 1.8, Bounce = { In = 0.7, InTime = 0.1, Out = 1.2, OutTime = 0.15, SettleTime = 0.4 } },
	-- Sprint tiers (QM, Oct 9): the speeds (studs/s, the uncurved) each starts at. Breaking
	-- into a new one replays the sprint whoosh, snaps the fisheye up (SprintCam) and
	-- steps the wind louder (up to 2x). The first is a horse's sprint.
	-- The owner's headshot and name over their pen (QM, Oct 10: back, Height studs over
	-- the middle of its floor; off Oct 9).
	PenProfile = { On = true, Height = 40 },
	-- How many pets (and eggs waiting to hatch) your pen holds (QM, Oct 11): Base, and
	-- PerUpgrade more for each pen upgrade (PenLevel). Full, you can't put an egg down;
	-- "5/10" shows under your name over the pen (Pens.server).
	PenLevels = 13, -- pen levels, one per quest claimed after Reach Meadow, each with its own fence (tools/pens.py STYLES: QM, Oct 11)
	PenCapacity = { Base = 10, PerUpgrade = 8 }, -- (QM, Oct 11: was 5; 8 a level since QM's Collect 50 quest: the top level, 6, holds 50, was 35)
	-- The sky flashes white on each sprint tier-up, fading back over Time seconds (QM, Oct 9):
	-- Client/SkyFlash. Start: its see-through at the flash (0: solid white). Distance: studs
	-- round the camera; anything further off goes white with the sky.
	-- The run home's over-the-shoulder camera (QM, Oct 10): Client/ShoulderCam. Studs from
	-- the rider (x the ride's zoom: bigger pets, the sprint tiers' bounce), easing in over
	-- InTime seconds as you turn for home and out over OutTime at the home line.
	-- The run home's fisheye and zoom stay put, as at a horse's sprint, whatever your speed
	-- (no tier bounces either): QM, Oct 10, to test the shoulder camera. false: by speed.
	ReturnCamFixed = true,
	ShoulderCam = { On = true, Right = 15, UpMin = 5, UpMax = 12, UpBelow = 2.5, BurrowUp = 20, Back = 20, Ahead = 60, LookUp = 0, LookRight = 0, -- (QM's tuning, Oct 10)
		InTime = 0.8, OutTime = 0.5 },
	SkyFlash = { On = true, Time = 0.8, Start = 0, Distance = 1000 },
	SprintTiers = { 180, 360, 440 },
	-- (QM, Oct 9: On false, no speed lines or wider view: riding's plain)
	SpeedFeel = { On = false, Min = 0.5, Ref = 400, Curve = 0.5, Lines = 44, Opacity = 0.85, LineSpeed = 2.8, FovKick = 26, MaxFov = 115 },
	Intro = false, -- (off for now: QM, Oct 11) a new player's opening cutscene: the villain steals your egg (Client/Intro, QM Oct 11; "/tutorial" replays it)
	LassoRange = 51, -- studs, for a Horse-sized animal (QM, Oct 11: bigger ones further, below; Oct 12: 1.5x, was 34)
	LassoRangeFrom = 4.6, -- a Horse's half width (studs): an animal this wide or narrower gets LassoRange
	LassoRangeGain = 1.5, -- studs more range for each stud wider than that (1.5x with LassoRange, QM Oct 12; was 1)
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
	-- The game's owner gets their passes (Roblox has a creator own them all)? false: they
	-- play without them, live and in Studio, like any player (QM, Oct 9). Passes.
	OwnerPasses = false,
	-- The UI's art (QM, Oct 9: all being redrawn). false: every UI picture is a plain
	-- placeholder with its art's name on it (UiArt.client); true puts the art back.
	UiArt = false,
	-- The home HUD's gold counter, Pets, Shop, Merge and Upgrade Pen buttons (QM, Oct 9:
	-- off till the new UI). false hides them; true brings them back.
	HomeHud = false,
	-- The old riding UI: the stamina bar, LASSO, Sprint, the ability button, DODGE, the
	-- fail screen. false (QM, Oct 9): the new one instead (Client/RideUi: stamina bar,
	-- LASSO, Sprint, ability), no fail screen (a crash takes you home by itself). true
	-- brings the old one back.
	RideHud = false,
	PetPopups = false, -- the "+$N" over each pet at home as it pays out (QM, Oct 9: off for now; income's the same)
	-- The base UI (BaseUi.client; QM, Oct 9): Montserrat ExtraBold, laid out on a
	-- RefWidth-wide screen (QM's Figma) and scaled to yours (x HudScale). Upgrade / Unlock
	-- shows within BullReach studs of your pen's bull spot (BullSpots, by pen number:
	-- design/base_arc's bull pads, none built yet).
	BaseUi = { RefWidth = 1920, BullReach = 16 },
	-- Quests (QM, Oct 11), top right at your base in place of the Upgrade button: two
	-- questlines, each showing its next quest, top and bottom (QM's final list). Claiming a
	-- finished one gives its Egg and upgrades your pen, unless NoPenLevel (PenLevel + 1, up to the last
	-- biome's: more room, Config.PenCapacity), and that line's next one comes up. A line
	-- that's done leaves the other alone in the panel; both done, the panel's gone.
	-- (QM, Oct 11: "Reach ...", was "Enter the ...")
	-- Kind: "reach" (ride into Config.Biomes[Biome]; the Meadow's, 1, is done from the start), "lasso" (land Need lassos on wild
	-- animals), "home" (bring Need animals home), "merge" (merge Need times), "invite" (Need
	-- friends you invited joined); the last
	-- three count from when the quest comes up.
	Quests = {
		{
			{ Text = "Reach Meadow", Kind = "reach", Biome = 1, Egg = "Cactus", NoPenLevel = true }, -- (QM, Oct 11: done from the start, so there's something to claim right away, and no pen upgrade; Quests.load moves saves from before it on one)
			{ Text = "Reach Desert", Kind = "reach", Biome = 2, Egg = "Penguin" }, -- (QM, Oct 11: quick eggs early, to speed you up; was the Unicorn)
			{ Text = "Reach Tundra", Kind = "reach", Biome = 3, Egg = "Snowman" }, -- (QM, Oct 11: was the Snake, then the Starfish, then the Boar)
			{ Text = "Reach Ocean", Kind = "reach", Biome = 4, Egg = "Lionfish" }, -- (QM, Oct 11: was the Icebringer)
			{ Text = "Reach Volcano", Kind = "reach", Biome = 5, Egg = "FireLobster" }, -- (QM, Oct 11: was the Kraken)
			{ Text = "Reach Jurassic", Kind = "reach", Biome = 6, Egg = "PalmGuy" }, -- (QM, Oct 11: was the Phoenix)
		},
		{
			{ Text = "Lasso animals", Kind = "lasso", Need = 3, Egg = "SpineLizard" }, -- (QM, Oct 11: 3, was 10)
			{ Text = "Merge animals", Kind = "merge", Need = 3, Egg = "SnackYak" }, -- (QM, Oct 11: the Snack Yak, was the Snowman) -- (before Collect: QM, Oct 12)
			{ Text = "Collect animals", Kind = "home", Need = 10, Egg = "BoneRex" }, -- (for D1: its egg's long, QM; 10, was 5: QM, Oct 11)
			{ Text = "Lasso Snowmen", Kind = "lasso", Animal = "Snowman", Need = 4, Egg = "TRex" }, -- (QM, Oct 11: these three after Merge)
			{ Text = "Lasso Crabs", Kind = "lasso", Animal = "KingCrab", Need = 3, Egg = "LavaWhale" }, -- (QM, Oct 11: 3, was 5) -- (QM's "crab": the King Crab, the Ocean's common one; the Blue Crab is a 0.05 Legendary)
			{ Text = "Lasso Lava Whales", Kind = "lasso", Animal = "LavaWhale", Need = 2, Egg = "RoboShark" }, -- (QM, Oct 11: was Collect 30)
			{ Text = "Lasso a Bone Rex", Kind = "lasso", Animal = "BoneRex", Need = 1, Egg = "Loong" }, -- (QM, Oct 11: was Collect 50)
		},
		{ -- (QM, Oct 12: a third line, just this; tapping it opens Roblox's invite, done when an invited friend joins: Hatchery)
			{ Text = "Invite a friend", Kind = "invite", Need = 1, Egg = "Squid", NoPenLevel = true },
		},
	},
	BullSpots = { Vector3.new(-18, 0, 173), Vector3.new(-75.2, 0, 129.6), Vector3.new(52, 0, 157.1), Vector3.new(-78.6, 0, 57.9), Vector3.new(84.9, 0, 93.3) },
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

	-- The pacing ladder (QM, Oct 11; balance/pacing_ladder_v1.md): Speed = 0.7 x 1.6 per biome
	-- x 1.15 per rarity (Uncommon, Rare, Epic, Legendary), so any animal of a later biome
	-- outruns every one behind it (each animal a little either side of its rarity's speed, so
	-- they feel different, never past the next rarity's), and each biome's line sits where its biome before's Rares
	-- just get to in a 30 s sprint: Epics and Legendaries take you into the next one. The
	-- Meadow and Desert are off the ladder (QM, Oct 11: their old speeds, the Desert reached at once). Change a biome's Length or these together.
	-- Each animal's stats, x MountSpeed and HerdSpeed (1x). Speed scales how fast it runs,
	-- ridden (MountSpeed, ReturnSpeed) and in the stampede (HerdSpeed). Stamina scales
	-- how long the Hold bar lasts while you ride it: 2x lasts twice as long. BiomeSpeed:
	-- ridden in that biome (by Name), as fast as the animal named.
	AnimalStats = {
		-- Meadow (QM, Oct 11: the Meadow's and the Desert's back to their speeds from before the ladder:
		-- the Meadow is the tutorial and the Desert should come almost at once)
		Horse = { Speed = 1, Stamina = 1 },
		ArmoredHorse = { Speed = 1, Stamina = 1 }, -- World 2's starter (QM, Oct 13: match the Horse)
		Pig = { Speed = 0.8, Stamina = 0.8 },
		Bunny = { Speed = 1.2, Stamina = 0.7 },
		Pinto = { Speed = 1.1, Stamina = 0.9 },
		Fish = { Speed = 0.6, Stamina = 3, BiomeSpeed = { Ocean = "Clownfish" } }, -- (slow everywhere but the Ocean, where it's as fast as a Clownfish: QM, Oct 11)
		Rhino = { Speed = 1.35, Stamina = 1.8 },
		MarbleColossus = { Speed = 1.35, Stamina = 1.8 }, -- World 2's Meadow Epic (as the Rhino until QM sets it)
		MarbleFish = { Speed = 1.1, Stamina = 0.9 }, -- World 2's Meadow Uncommon (QM, Oct 13; as the Pinto until QM sets it)
		Lion = { Speed = 1.25, Stamina = 1.2 }, -- World 2's Meadow Rare (QM, Oct 13; between the Pinto and the Rhino, a guess)
		Buffalo = { Speed = 1.3, Stamina = 1.6 }, -- World 2's Meadow Rare, Rhino-sized (QM, Oct 13; a guess)
		Crocodile = { Speed = 1.25, Stamina = 1.2 }, -- World 2's Meadow Rare (QM, Oct 13; the Lion's numbers, a guess)
		MajesticUnicorn = { Speed = 1.8, Stamina = 2 }, -- World 2's Meadow Legendary (as the Unicorn until QM sets it)
		Unicorn = { Speed = 1.8, Stamina = 2 }, -- (QM, Oct 12: kept at 1.8, into the Tundra from the start line, ~4,440 of 3,984)
		-- Desert
		Caterpillar = { Speed = 3.37, Stamina = 2 }, -- World 2's Woodland Maze Uncommon (as the Starfish until QM sets it)
		Eyeworm = { Speed = 1.31, Stamina = 1.5 }, -- World 2 Crimson Lands Uncommon: the Cactus's numbers (QM, Oct 13: World 2 ~matches World 1's speeds)
		CrimsonScorpion = { Speed = 1.5, Stamina = 1.2 }, -- World 2 Crimson Lands Uncommon: the Kitten's numbers
		Maw = { Speed = 1.77, Stamina = 1.5 }, -- World 2 Crimson Lands Rare: the Scorpion's numbers
		IvorySpider = { Speed = 1.7, Stamina = 3 }, -- World 2 Crimson Lands Epic: the Sandworm's numbers
		Asura = { Speed = 2.8, Stamina = 3 }, -- World 2 Crimson Lands Legendary: the Snake's numbers
		Cactus = { Speed = 1.31, Stamina = 1.5 }, -- (QM, Oct 12: 90% into the Desert; was 1.2)
		Kitten = { Speed = 1.5, Stamina = 1.2 }, -- (QM, Oct 12: 20% into the Tundra; was 1.4)
		Scorpion = { Speed = 1.77, Stamina = 1.5 }, -- (QM, Oct 12: 60% into the Tundra; was 1.5)
		Sandworm = { Speed = 1.7, Stamina = 3 }, -- (QM, Oct 12: 50% into the Tundra; was 1.6)
		SpineLizard = { Speed = 1.97, Stamina = 2 }, -- (QM, Oct 12: 90% into the Tundra; was 1.62)
		Snake = { Speed = 2.8, Stamina = 3 }, -- (QM, Oct 12: was 2)
		-- Tundra
		CrystalCentipede = { Speed = 1.99, Stamina = 1.5 }, -- World 2's Crystal Cavern Uncommon (as the Penguin until QM sets it)
		RedMushroom = { Speed = 2.36, Stamina = 1.6 }, -- World 2's Cavern Living Mushrooms: the small red one Uncommon (as the Boar),
		BrownMushroom = { Speed = 2.52, Stamina = 1.3 }, -- the medium brown one Rare (as the Snowman),
		PurpleMushroom = { Speed = 2.57, Stamina = 3 }, -- the giant purple one Epic (as the Ice Golem), until QM sets them
		BlueCrystal = { Speed = 2.36, Stamina = 1.6 }, -- World 2's Cavern Living Crystals: blue Uncommon (as the Boar),
		PinkCrystal = { Speed = 2.52, Stamina = 1.3 }, -- pink Rare (as the Snowman), until QM sets them
		CrystalSpider = { Speed = 2.57, Stamina = 3 }, -- World 2's Cavern Crystal Spider: Epic (as the Ice Golem until QM sets it)
		CrystalElephant = { Speed = 3.8, Stamina = 4 }, -- World 2's Cavern Legendary Crystal Elephant (as the Icebringer until QM sets it)
		Seraph = { Speed = 0.5, Stamina = 3 }, -- World 2's trophy angels (QM, Oct 13: "move quite slowly (like say 0.5 speed)")
		CrimsonSeraph = { Speed = 0.5, Stamina = 3 },
		CrystalSeraph = { Speed = 0.5, Stamina = 3 },
		CrystalPhoenix = { Speed = 2.57, Stamina = 3 }, -- World 2's Cavern Crystal Phoenix: Epic (as the Ice Golem until QM sets it)
		OrangeButterfly = { Speed = 3.54, Stamina = 2 }, -- World 2's Woodland Orange Butterfly: Rare (as the Lionfish until QM sets it)
		Penguin = { Speed = 1.99, Stamina = 1.5 }, -- (QM, Oct 12: 93% into the Tundra; was 1.72)
		Boar = { Speed = 2.36, Stamina = 1.6 }, -- (QM, Oct 12: 30% into the Ocean; was 1.86)
		Snowman = { Speed = 2.52, Stamina = 1.3 }, -- (QM, Oct 12: 45% into the Ocean; was 2.06)
		IceGolem = { Speed = 2.57, Stamina = 3 }, -- (QM, Oct 12: 50% into the Ocean; was 2.37)
		SnackYak = { Speed = 3, Stamina = 2 }, -- QM, Oct 4 (stamina 1 -> 2)
		Icebringer = { Speed = 3.8, Stamina = 4 }, -- (QM, Oct 12: into the Volcano from the start line, ~9,380 of 9,024; was 3.6) -- (QM, Oct 11: a Legendary well past the next biome's Uncommons: 1.25x the Starfish, it lands in the Volcano)
		-- Ocean
		Starfish = { Speed = 3.37, Stamina = 2 }, -- (QM, Oct 12: 15% into the Volcano; was 2.87)
		Squid = { Speed = 4.15, Stamina = 2.6 }, -- (QM, Oct 12: 60% into the Volcano; was 3.7)
		JadeStatue = { Speed = 7.12, Stamina = 3 }, -- World 2's Temple Epics: the Rockworm's numbers until QM sets them
		GarnetStatue = { Speed = 7.12, Stamina = 3 },
		Hawkmoth = { Speed = 4.15, Stamina = 2.6 }, -- World 2's Woodland Hawkmoth: Epic, the Squid's numbers until QM sets it (60% into the Temple, as the Squid is 60% into the Volcano)
		KingCrab = { Speed = 3.98, Stamina = 3 }, -- (QM, Oct 12: 50% into the Volcano; was 3.6)
		BlueCrab = { Speed = 5.7, Stamina = 3 }, -- (QM, Oct 11: as the Kraken, a touch slower)
		Lionfish = { Speed = 3.54, Stamina = 2 }, -- (QM, Oct 12: 25% into the Volcano; was 3.4); QM Oct 11: "a touch faster than the starfish" (the ladder: an Ocean Rare)
		PinkButterfly = { Speed = 3.28, Stamina = 2.4 }, -- World 2's Woodland Pink Butterfly: Uncommon (as the Clownfish until QM sets it)
		LivingBirch = { Speed = 3.54, Stamina = 2 }, -- World 2 Woodland Maze Rare: the Lionfish's (25% into the Temple), until QM sets it
		RollingLog = { Speed = 3.54, Stamina = 2 }, -- World 2's Woodland Maze Rare (QM, Oct 13; as the Lionfish until QM sets it)
		Tiger = { Speed = 6.43, Stamina = 2.8 }, -- World 2's Temple Rare (QM, Oct 13; as the Fire Lobster until QM sets it)
		Clownfish = { Speed = 3.28, Stamina = 2.4 }, -- (QM, Oct 12: 10% into the Volcano; was 2.8); (a little slower than the Starfish, an Ocean Uncommon too)
		RoboShark = { Speed = 1.2, Stamina = 3 }, -- QM, Oct 4: starts at 1.2x, eating takes it up to 3x (Abilities.RoboShark.MaxSpeed 2.5 x this)
		FishSchool = { Speed = 4.15, Stamina = 2.8 }, -- (QM, Oct 12: 60% into the Volcano; was 3.95)
		Whale = { Speed = 3.45, Stamina = 10 }, -- (QM, Oct 12: 20% into the Volcano; was 3.2)
		GiantGolem = { Speed = 5.8, Stamina = 3 }, -- World 2's Woodland Legendary Giant Golem (as the Kraken until QM sets it)
		Kraken = { Speed = 5.8, Stamina = 3 }, -- (QM, Oct 11: 1.25x the Firebird, it lands in the Jurassic)
		-- Volcano
		Firebird = { Speed = 5.11, Stamina = 2.5 }, -- (QM, Oct 13: 10% into the Jurassic; was 4.59)
		Catfish = { Speed = 5.11, Stamina = 2.5 }, -- World 2's Temple Uncommon (as the Firebird until QM sets it)
		RockHog = { Speed = 6.56, Stamina = 2.8 }, -- (QM, Oct 13: 65% into the Jurassic; was 5.3)
		Rockworm = { Speed = 7.12, Stamina = 3 }, -- (QM, Oct 13: 86% into the Jurassic; was 6.3)
		FireLobster = { Speed = 6.43, Stamina = 2.8 }, -- (QM, Oct 13: 60% into the Jurassic; was 5.15)
		Fox = { Speed = 5.11, Stamina = 2.5 }, -- World 2 Temple Uncommon: the Firebird's, until QM sets it
		NineTailedFox = { Speed = 6.43, Stamina = 2.8 }, -- World 2 Temple Rare: the Fire Lobster's, until QM sets it
		Kitsune = { Speed = 7.2, Stamina = 3 }, -- World 2's Temple Legendary Kitsune (as the Phoenix until QM sets it)
		Phoenix = { Speed = 7.2, Stamina = 3 }, -- (QM, Oct 12: well into the Jurassic, a touch slower than the Bone Rex; was 6.98)
		LavaWhale = { Speed = 6.83, Stamina = 3 }, -- (QM, Oct 13: 75% into the Jurassic; was 5.85)
		TRex = { Speed = 6, Stamina = 3 }, -- (a guess: a touch past the Lava Whale)
		Raptor = { Speed = 5.6, Stamina = 3 }, -- (a guess: a Rare, past the Volcano's Rares and short of the T-Rex)
		Spinosaurus = { Speed = 5.4, Stamina = 3 }, -- (a guess: a touch under the T-Rex)
		Pterodactyl = { Speed = 6.2, Stamina = 3 }, -- (a guess: an Epic, a touch past the T-Rex)
		Ankylosaurus = { Speed = 5, Stamina = 3 }, -- (a guess: the Jurassic's Uncommon, under its Rares)
		PalmGuy = { Speed = 4.9, Stamina = 3 }, -- (a guess: an Uncommon, a touch under the Ankylosaurus)
		BoneRex = { Speed = 7.5, Stamina = 3 }, -- (a guess: the final Legendary, the fastest in the game)
		VolcanoTortoise = { Speed = 6.17, Stamina = 3 }, -- (QM, Oct 13: 50% into the Jurassic; was 5)
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
	-- Kinds that run in packs (Client/HerdPacks): when one is drawn, the next slots in its
	-- stream are the rest of its pack, popping in with it in a V.
	HerdPacks = { Raptor = 3 }, -- (QM, Oct 11)
	HerdSpeed = 31, -- studs/s for a 1x animal; each kind runs at exactly this x its Speed
	-- ...up to Speed HerdGapSpeed: past it, no further behind you riding it out at a sprint than
	-- an animal of that Speed is (Shared/HerdSpeed: the later biomes' fast ones run faster, QM
	-- Oct 11; Oct 12: a fixed 2, was the Clownfish's).
	HerdGapSpeed = 2,
}

-- Flowing water (QM, Oct 13; Client/WaterFlow): a Texture named "Water" on a tile's top
-- with this Image flows Flow studs a second (U across the course, V along it).
Config.Water = {
	Image = "rbxassetid://77807866797953", -- assets/world2/WaterTile256.png (QM's 8 x 8 tile, x32 for crisp pixels)
	StudsPerTile = 8, -- (a pixel a stud)
	Flow = Vector2.new(0, 2),
}

-- Worlds (QM, Oct 13): each is its own Place in the experience, running this same code.
-- Gold is shared; each world has its own pen, pets, pen levels and quests.
Config.Places = { 126872244121414, 139418530058790 } -- [world] = its PlaceId
Config.World = table.find(Config.Places, game.PlaceId) or 1
-- (World 1 ended at a giant portal to World 2 for a while: QM, Oct 13 took it out. Both
-- worlds end at the finish line, into the void. EndPortal = { Scale, At } brings it back.)
Config.EndPortal = nil
-- What each world costs in gold to unlock, once (the Worlds menu's Buy and World 1's
-- World 2 bar; QM, Oct 13: 10m). World 1 is everyone's.
Config.WorldPrices = { 0, 10000000 }
-- 15, 1.2k, 3.4m, 10m... (gold, short: the Worlds menu's prices and the World 2 bar)
function Config.short(n)
	for _, unit in { { 1e12, "t" }, { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" } } do
		if n >= unit[1] then
			return (string.format("%.1f", math.floor(n / unit[1] * 10) / 10):gsub("%.0$", "")) .. unit[2]
		end
	end
	return tostring(math.floor(n))
end
-- The finish line's trails (QM, Oct 13): each time you ride over the finish line, in either
-- world, you get the next of these, no message (Hatchery's FinishCourse; FinishTrail, saved
-- with your gold). Bands top to bottom, as the Rainbow Trail's. After the last, no more.
Config.FinishTrails = {
	{ Name = "Yellow", Colors = { Color3.fromRGB(255, 246, 120), Color3.fromRGB(255, 226, 60), Color3.fromRGB(255, 200, 20), Color3.fromRGB(240, 170, 0) } },
	{ Name = "Blue", Colors = { Color3.fromRGB(140, 220, 255), Color3.fromRGB(70, 180, 255), Color3.fromRGB(30, 130, 240), Color3.fromRGB(20, 80, 200) } },
	{ Name = "Red", Colors = { Color3.fromRGB(255, 130, 110), Color3.fromRGB(255, 70, 60), Color3.fromRGB(220, 30, 30), Color3.fromRGB(160, 10, 20) } },
	{ Name = "Rainbow" }, -- (the Rainbow Trail's bands)
	{ Name = "Galaxy", Colors = { Color3.fromRGB(235, 225, 255), Color3.fromRGB(190, 90, 230), Color3.fromRGB(120, 50, 200), Color3.fromRGB(60, 70, 210), Color3.fromRGB(40, 20, 110), Color3.fromRGB(15, 10, 50) } },
}
-- The bands a player's ride trails, or nil for none: the best of their finish line trail
-- and the bought Rainbow Trail (Config.RainbowTrail).
local RAINBOW = {
	Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 150, 255), Color3.fromRGB(170, 90, 240),
}
function Config.trailColors(player)
	local n = math.max(player:GetAttribute("FinishTrail") or 0, if player:GetAttribute("RainbowTrail") then 4 else 0) -- (the bought one counts as the Rainbow)
	local trail = Config.FinishTrails[n]
	return if trail then trail.Colors or RAINBOW else nil
end
-- The per-world saves' DataStore names: World 1's as they've always been, the others' with
-- this on the end ("Pen_W2"). Gold's store is shared.
function Config.storeName(name, world)
	world = world or Config.World
	return if world == 1 then name else name .. "_W" .. world
end

-- World 2's look: its first biome and base as QM's reference (marble walls, yellow
-- grass, the darker grass beside the dirt, brown dirt); the rest World 1's colours
-- hue-turned as placeholders (tools/world2_terrain.luau's turns).
if Config.World == 2 then
	-- World 2's quests (QM, Oct 13): reach each biome, its egg World 1's reward's
	-- equivalent here; and the other line, merge 3, lasso 10 Lions, lasso 3 Kitsunes (that
	-- last one's three eggs). No invite line here.
	Config.Quests = {
		{
			{ Text = "Reach Meadow", Kind = "reach", Biome = 1, Egg = "Eyeworm", NoPenLevel = true }, -- (World 1's Cactus: the next biome's Uncommon)
			{ Text = "Reach Crimson Lands", Kind = "reach", Biome = 2, Egg = "CrystalCentipede" }, -- (the Penguin)
			{ Text = "Reach Crystal Cavern", Kind = "reach", Biome = 3, Egg = "BrownMushroom" }, -- (the Snowman)
			{ Text = "Reach Woodland Maze", Kind = "reach", Biome = 4, Egg = "OrangeButterfly" }, -- (the Lionfish)
			{ Text = "Reach Temple", Kind = "reach", Biome = 5, Egg = "Tiger" }, -- (the Fire Lobster)
			{ Text = "Reach Tomb", Kind = "reach", Biome = 6, Egg = "TombJackal" }, -- (the Palm Guy)
		},
		{
			{ Text = "Merge animals", Kind = "merge", Need = 3, Egg = "Seraph" },
			{ Text = "Lasso Lions", Kind = "lasso", Animal = "Lion", Need = 10, Egg = "Asura" },
			{ Text = "Lasso Kitsunes", Kind = "lasso", Animal = "Kitsune", Need = 3, Egg = { "Geb", "Nut", "Bes" } },
		},
	}
	Config.DefaultPet = "ArmoredHorse" -- World 2's starter, in your pen from the start (QM, Oct 13)
	local rgb = Color3.fromRGB
	local TURN = { 0.55, 0.6, 0.35, 0.2, 0.45, 0.75 } -- [biome] hue turn
	local function turn(value, by)
		if typeof(value) == "Color3" then
			local h, sat, v = value:ToHSV()
			return if sat < 0.12 then value else Color3.fromHSV((h + by) % 1, sat, v)
		elseif type(value) == "table" then
			local out = {}
			for k, v in value do
				out[k] = turn(v, by)
			end
			return out
		end
		return value
	end
	for i, biome in Config.Biomes do
		for _, key in { "GroundColors", "WallColors", "Patches", "Depths", "PostColor", "GateColor" } do
			if biome[key] then
				biome[key] = turn(biome[key], TURN[i] or 0)
			end
		end
	end
	Config.Boss.ByBiome = table.clone(Config.Boss.ByBiome)
	Config.Boss.ByBiome.Meadow = "Seraph" -- World 2's Meadow boss: the biblically accurate angel (QM, Oct 13)
	Config.Boss.ByBiome.Desert = "CrimsonSeraph" -- the Crimson Lands' (biome 2): the Seraph in crimson (QM, Oct 13)
	Config.Boss.ByBiome.Snow = "CrystalSeraph" -- the Crystal Cavern's (biome 3): the Seraph in crystal (QM, Oct 13; was the Crystal Tyrant)
	Config.Boss.ByBiome.Ocean = "Monarch" -- the Woodland Maze's (biome 4): a giant monarch butterfly (QM, Oct 13)
	local meadow = Config.Biomes[1]
	meadow.Herd = table.clone(meadow.Herd)
	meadow.Herd.MarbleFish = 0.3 -- World 2's Meadow Uncommon (QM, Oct 13), about as often as the Pinto
	meadow.Herd.Lion = 0.2 -- World 2's Meadow Rare (QM, Oct 13), as often as the Fish
	meadow.Herd.Buffalo = 0.1 -- World 2's Meadow Rare (QM, Oct 13; a guess)
	meadow.Herd.Crocodile = 0.2 -- World 2's Meadow Rare (QM, Oct 13; a guess)
	meadow.Herd.MarbleColossus = 0.08 -- World 2's Meadow Epic (QM, Oct 13), as often as the Rhino
	meadow.Herd.MajesticUnicorn = 0.05 -- World 2's Meadow Legendary (QM, Oct 13), as often as the Unicorn
	meadow.GroundColors = { rgb(206, 168, 58), rgb(190, 152, 46) }
	meadow.WallColors = { rgb(236, 232, 224), rgb(218, 214, 206) } -- marble
	meadow.Patches = {
		Dirt = { rgb(142, 101, 60), rgb(128, 89, 52) }, -- (QM, Oct 13: 20% lighter, then its checker 20% less contrast; was 118, 84, 50 / 104, 72, 42)
		Grass = { rgb(182, 144, 44), rgb(166, 130, 36) }, -- the darker grass, beside the dirt
	}
	-- The second biome: the Crimson Lands (QM, Oct 13; tools/world2_crimson.luau's floor).
	local crimson = Config.Biomes[2]
	crimson.GroundColors = { rgb(121, 20, 37), rgb(110, 17, 33) } -- #791425
	crimson.Patches = {
		Crimson = { rgb(144, 44, 43), rgb(132, 38, 38) }, -- #902C2B, round every stone tile
		Stone = { rgb(119, 86, 86), rgb(108, 77, 77) }, -- #775656 single tiles
	}
	crimson.Herd = table.clone(crimson.Herd)
	crimson.Herd.Eyeworm = 0.3 -- the Crimson Lands' animals (QM, Oct 13): Uncommon, as often as the Cactus
	crimson.Herd.Maw = 0.3 -- Rare, as the Scorpion
	crimson.Herd.IvorySpider = 0.05 -- Epic, as the Sandworm
	crimson.Herd.Asura = 0.05 -- Legendary, as the Snake
	crimson.Herd.CrimsonScorpion = 0.2 -- Uncommon, as the Kitten
	crimson.Herd.Beholder = 0.3 -- the Godlands' Rare joins the Crimson Lands (QM, Oct 13), in the Spine Lizard's slot
	-- The third: the Crystal Cavern (QM, Oct 13; tools/world2_cavern.luau): blue-grey by the
	-- walls to ice to crystal down the middle; its plank boards keep their own colours.
	local cavern = Config.Biomes[3]
	cavern.GroundColors = { rgb(90, 109, 143), rgb(82, 99, 131) } -- #5A6D8F
	cavern.Patches = {
		Ice = { rgb(98, 129, 167), rgb(89, 118, 153) }, -- #6281A7
		Crystal = { rgb(116, 186, 213), rgb(105, 171, 197) }, -- #74BAD5
	}
	cavern.WallColors = { rgb(56, 72, 103), rgb(48, 62, 90) } -- #384867
	cavern.CapColor = rgb(44, 57, 82)
	cavern.Herd = table.clone(cavern.Herd)
	cavern.Herd.CrystalCentipede = 0.3 -- the Cavern's first animal (QM, Oct 13), an Uncommon as often as the Penguin
	cavern.Herd.RedMushroom = 0.25 -- the Living Mushrooms (QM, Oct 13), as often as the Boar, Snowman and Ice Golem
	cavern.Herd.BrownMushroom = 0.22
	cavern.Herd.PurpleMushroom = 0.12
	cavern.Herd.BlueCrystal = 0.25 -- the Living Crystals (QM, Oct 13), as often as the Boar and Snowman
	cavern.Herd.PinkCrystal = 0.22
	cavern.Herd.CrystalSpider = 0.12 -- the Crystal Spider (QM, Oct 13), an Epic as often as the Ice Golem
	cavern.Herd.CrystalPhoenix = 0.08 -- the Crystal Phoenix (QM, Oct 13), an Epic too
	cavern.Herd.CrystalElephant = 0.04 -- the Crystal Elephant (QM, Oct 13), the Legendary, as rare as the Icebringer
	-- The fourth: the Woodland Maze (QM, Oct 13; tools/world2_woodland.luau): brown, darker
	-- by the walls.
	local woodland = Config.Biomes[4]
	woodland.GroundColors = { rgb(121, 72, 46), rgb(110, 65, 41) } -- #79482E
	woodland.Patches = {
		Soil = { rgb(142, 81, 57), rgb(130, 74, 52) }, -- #8E5139
		Path = { rgb(151, 89, 57), rgb(139, 81, 52) }, -- #975939, the middle
	}
	woodland.Herd = table.clone(woodland.Herd)
	woodland.Herd.Caterpillar = 0.3 -- the Woodland Maze's Uncommon (QM, Oct 13), as often as the Starfish
	woodland.Herd.PinkButterfly = 0.25 -- the Pink Butterfly (QM, Oct 13): Uncommon, as often as the Clownfish
	woodland.Herd.OrangeButterfly = 0.15 -- the Orange Butterfly (QM, Oct 13), a Rare as often as the Lionfish
	woodland.Herd.LivingBirch = 0.15 -- the Woodland's Rare (QM, Oct 13), as often as the Lionfish
	woodland.Herd.Hawkmoth = 0.15 -- the Hawkmoth (QM, Oct 13), an Epic as often as the King Crab
	woodland.Herd.RollingLog = 0.15 -- the Woodland Maze's Rare (QM, Oct 13), as often as the Lionfish
	woodland.Herd.GiantGolem = 0.05 -- the Giant Golem (QM, Oct 13), the Legendary, as rare as the Kraken
	-- The fifth: the Temple (QM, Oct 13; tools/world2_temple.luau): a rock path, grass and
	-- marble a stud up, ponds a stud and two down (their flowing water: tools/world2_water.luau).
	local temple = Config.Biomes[5]
	temple.Herd = table.clone(temple.Herd)
	temple.Herd.Loong = 0.025 -- the Loong runs wild here as a Legendary (QM, Oct 13)
	temple.Herd.Catfish = 0.42 -- the Temple's Uncommon (QM, Oct 13), as often as the Firebird
	temple.Herd.Tiger = 0.17 -- the Temple's Rare (QM, Oct 13), as often as the Fire Lobster
	temple.Herd.JadeStatue = 0.13 -- the Jade and Garnet Statues (QM, Oct 13), Epics as often as the Rockworm
	temple.Herd.GarnetStatue = 0.13
	temple.Herd.Fox = 0.42 -- the Temple's Uncommon (QM, Oct 13), as often as the Firebird
	temple.Herd.NineTailedFox = 0.17 -- the Fox's rare variant (QM, Oct 13), as often as the Fire Lobster
	temple.Herd.Kitsune = 0.03 -- the Kitsune (QM, Oct 13), the Temple's Legendary, as rare as the Phoenix
	temple.GroundColors = { rgb(158, 141, 116), rgb(146, 130, 106) } -- (no Ground parts: Rock is its base)
	temple.Patches = {
		Rock = { rgb(158, 141, 116), rgb(146, 130, 106) }, -- #9E8D74
		Grass = { rgb(145, 178, 41), rgb(133, 164, 35) }, -- #91B229
		Marble = { rgb(200, 200, 200), rgb(186, 186, 186) }, -- #C8C8C8
		SideDirt = { rgb(200, 200, 200), rgb(190, 188, 184) },
		Water = { rgb(37, 81, 40), rgb(34, 99, 55) }, -- (QM's water tile's greens, so the pond sides match it)
		DeepWater = { rgb(26, 57, 28), rgb(24, 69, 38) },
	}
	temple.WallColors = { rgb(200, 200, 200), rgb(186, 186, 186) }
	temple.CapColor = rgb(176, 176, 176)
	-- The last: the Ancient Tomb (QM, Oct 13; tools/world2_tomb.luau): sand, a gold causeway a
	-- stud up and gold daises two up in darker frames. (World 2's zones end: no endless.)
	local tomb = Config.Biomes[6]
	tomb.GroundColors = { rgb(220, 201, 152), rgb(210, 191, 142) } -- (its base is Sand)
	tomb.Patches = {
		Sand = { rgb(220, 201, 152), rgb(210, 191, 142) }, -- #DCC998
		Dune = { rgb(208, 184, 134), rgb(198, 174, 124) }, -- #D0B886
		Paving = { rgb(208, 184, 134), rgb(198, 174, 124) },
		Gold = { rgb(226, 194, 0), rgb(196, 167, 3) }, -- #E2C200 / #C4A703
		Frame = { rgb(196, 167, 3), rgb(180, 152, 2) },
	}
	tomb.WallColors = { rgb(211, 183, 66), rgb(196, 168, 54) } -- #D3B742
	tomb.CapColor = rgb(186, 158, 46)
	-- Walls and gate glows (QM, Oct 13: the Level design thread's batch; tools/world2_walls.luau).
	crimson.WallColors = { rgb(91, 50, 54), rgb(82, 44, 48) }
	crimson.CapColor = rgb(72, 39, 42)
	crimson.GateColor = rgb(255, 59, 92)
	cavern.GateColor = rgb(92, 225, 255)
	woodland.WallColors = { rgb(70, 42, 24), rgb(60, 36, 20) } -- dark brown (QM, Oct 13)
	woodland.CapColor = rgb(242, 109, 57) -- vibrant autumn leaves on top (QM, Oct 13)
	woodland.GateColor = rgb(242, 109, 57)
	temple.GateColor = rgb(130, 226, 80)
	tomb.GateColor = rgb(255, 200, 30)
	-- Only World 2's own animals run in its herds (QM, Oct 13: no World 1 animals in the
	-- marble Meadow): each biome keeps the kinds the lines above added. A biome with none
	-- yet runs Fish as a placeholder.
	local own = {}
	for i, biome in Config.Biomes do
		own[i] = {}
	end
	local function ownHerd(i, kinds)
		for _, kind in kinds do
			own[i][kind] = true
		end
	end
	ownHerd(1, { "MarbleFish", "Lion", "Buffalo", "Crocodile", "MarbleColossus", "MajesticUnicorn", "Bunny", "Rhino" }) -- (the Bunny and Rhino too, at World 1's weights: QM, Oct 13)
	ownHerd(2, { "Eyeworm", "CrimsonScorpion", "Maw", "Beholder", "IvorySpider", "Asura" })
	ownHerd(3, { "CrystalCentipede", "RedMushroom", "BrownMushroom", "PurpleMushroom", "BlueCrystal", "PinkCrystal", "CrystalSpider", "CrystalPhoenix", "CrystalElephant" })
	ownHerd(4, { "Caterpillar", "PinkButterfly", "OrangeButterfly", "LivingBirch", "Hawkmoth", "RollingLog", "GiantGolem" }) -- the Woodland Maze
	ownHerd(5, { "Loong", "Catfish", "Fox", "Tiger", "NineTailedFox", "JadeStatue", "GarnetStatue", "Kitsune" }) -- the Temple
	for i, biome in Config.Biomes do
		local herd = {}
		for kind, weight in biome.Herd or {} do
			if own[i][kind] then
				herd[kind] = weight
			end
		end
		biome.Herd = if next(herd) then herd else { Fish = 1 }
	end
	-- World 2's speeds (QM, Oct 13: each animal's % into a biome on a full sprint ride,
	-- 2,904 studs per 1 Speed). The rest keep theirs (the Seraphs 0.5, the Majestic Unicorn,
	-- Eyeworm, Asura and Crystal Centipede as they were).
	for kind, speed in {
		MarbleFish = 0.809, -- 10% into the Crimson Lands
		Lion = 0.872, -- 20% into the Crimson Lands
		Crocodile = 0.878, -- 21% into the Crimson Lands
		Buffalo = 0.934, -- 30% into the Crimson Lands
		MarbleColossus = 1.028, -- 45% into the Crimson Lands
		CrimsonScorpion = 1.405, -- 5% into the Crystal Cavern
		IvorySpider = 1.537, -- 25% into the Crystal Cavern (QM, Oct 13; was 45%)
		Maw = 1.438, -- 10% into the Crystal Cavern
		Beholder = 1.504, -- 20% into the Crystal Cavern
		RedMushroom = 2.14, -- 10% into the Woodland
		BlueCrystal = 2.14, -- 10% into the Woodland
		BrownMushroom = 2.248, -- 20% into the Woodland
		PinkCrystal = 2.248, -- 20% into the Woodland
		PurpleMushroom = 2.302, -- 25% into the Woodland
		CrystalSpider = 2.355, -- 30% into the Woodland
		CrystalPhoenix = 3.097, -- 99% into the Woodland
		CrystalElephant = 4.409, -- 75% into the Temple
	} do
		Config.AnimalStats[kind] = table.clone(Config.AnimalStats[kind] or { Stamina = 1 })
		Config.AnimalStats[kind].Speed = speed
	end
	-- The trophy angels (QM, Oct 13: his weights; were 1 in 300 of their biome's stampede).
	for i, weight in { 0.001, 0.002, 0.002 } do
		Config.Biomes[i].Herd[({ "Seraph", "CrimsonSeraph", "CrystalSeraph" })[i]] = weight
	end
end

return Config
