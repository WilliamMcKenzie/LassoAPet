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
			Herd = { Horse = 0, Pinto = 0.35, Pig = 0.25, Bunny = 0.25, Fish = 0.22, Rhino = 0.13, Unicorn = 0.05 },
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
			Herd = { Penguin = 0.3, Boar = 0.25, Snowman = 0.22, IceGolem = 0.12, SnackYak = 0, Icebringer = 0.06 }, -- the Snack Yak never spawns: a Robux exclusive (QM, Oct 4)
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
			Herd = { Fish = 0, Starfish = 0.3, Clownfish = 0.25, Whale = 0.15, Squid = 0.2, KingCrab = 0.15, FishSchool = 0.15, BlueCrab = 0.05, RoboShark = 0, Kraken = 0.05, Lionfish = 0.15 }, -- (the Lionfish Rare, a touch faster than the Starfish, QM Oct 11, weight a guess; the Clownfish Uncommon, a little rarer than the Starfish, QM Oct 11; Blue Crab guessed like the Kraken; the Robo Shark never spawns: a future Robux pet, QM Oct 4)
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
			GroundColors = { Color3.fromRGB(78, 140, 40), Color3.fromRGB(86, 152, 44) }, -- dark jungle grass
			WallColors = { Color3.fromRGB(150, 102, 62), Color3.fromRGB(164, 114, 70) },
			Herd = { Fish = 1 }, -- (QM, Oct 11: fish for now, until the dinosaurs are designed)
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
	PenUpgrades = true,
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
	HomeHalfWidth = 176, -- tools/pens.py HALF_W: the arc base (QM, Oct 9; design/base_arc/SPEC.md)
	HomeDepth = 264, -- tools/pens.py DEPTH: the base runs this far back from the start line to its back wall
	StarterSpot = Vector3.new(0, 0, 20), -- where you start without a pen (players past the fifth)

	-- Ride
	MountSpeed = 44,
	ReturnSpeed = 40,
	SteerSpeed = 28,
	-- Wider mounts steer quicker, gently (QM, Oct 8): x (1 + SteerWidthScale x (width
	-- over a horse's - 1)), so twice a horse's width steers 1.2x, three times 1.4x.
	SteerWidthScale = 0.2,
	SteerResponse = 8,
	-- Every ride out lasts RideSeconds (QM, Oct 10: no more stamina), the bar at the top
	-- draining with it, sprinting or not. Empty: you turn round on whatever you're riding
	-- and race it home, and a wild one's egg is yours over the line.
	RideSeconds = 30,
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
		On = true, Kind = "Chicken", ByBiome = { Meadow = "Chicken", Desert = "CactusBoss", Snow = "ElderBoar", Ocean = "SharkBoss", Volcano = "LavaWyrm" }, Ahead = 140, -- (QM, Oct 10: twice as far, was 70)
		ZoomAt = 0.6, CutsceneTime = 2.8, BarTime = 0.35,
		FaceAt = Vector3.new(0, 0.32, 0.25), FaceFrom = Vector3.new(0, 3, 20), Behind = 40, StopShort = 30,
		Room = { CactusBoss = 40, ElderBoar = 40, SharkBoss = 80, LavaWyrm = 60 }, -- (studs more Ahead and Behind for the bigger ones, so they don't clip you: QM)
		CryVolume = { Chicken = 0.9, ElderBoar = 0.6, SharkBoss = 2.5, CactusBoss = 0.3, LavaWyrm = 0.6 }, -- (each boss's cry: QM, Oct 10)
		Faces = { -- (bosses whose faces sit elsewhere: At / From in place of FaceAt / FaceFrom)
			ElderBoar = { At = Vector3.new(0, 0, 0.45), From = Vector3.new(0, 5, 41) }, -- (it's 1.7x the size: QM)
			CactusBoss = { From = Vector3.new(0, 5, 34) }, -- (1.7x the size)
			SharkBoss = { At = Vector3.new(0, 0, 0.4), From = Vector3.new(36, 4, 16) }, -- (from its side, so you see its eye: QM)
			LavaWyrm = { At = Vector3.new(0.17, -0.06, 0.3), From = Vector3.new(0, 3, 58) }, -- (its head is out front and off to one side)
		},
		VeinSize = 0.16, VeinAt = Vector2.new(0.67, 0.317), VeinPopTime = 0.35, VeinPulse = 0.3, VeinPeriod = 0.4, VeinSpin = 25,
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
		-- (QM, Oct 8 evening: progression 2x faster: the Desert's to the Godlands' halved, so
		-- x1 / x2 / x3 / x4 of the JSON; the Meadow's and the exclusives' kept.)
		Horse = 15, Pig = 15, Bunny = 15, Pinto = 15, Fish = 45, Rhino = 120, Unicorn = 300, -- Meadow
		Cactus = 30, Kitten = 30, Scorpion = 90, Sandworm = 210, SpineLizard = 300, Snake = 600, -- Desert
		Penguin = 60, Boar = 90, Snowman = 240, IceGolem = 720, Icebringer = 3600, -- Tundra
		Starfish = 45, Clownfish = 300, Whale = 10800, Squid = 2700, FishSchool = 2000, KingCrab = 3600, BlueCrab = 9000, Kraken = 10000, Lionfish = 1800, -- Ocean
		Firebird = 7200, RockHog = 10800, FireLobster = 10800, Rockworm = 12600, VolcanoTortoise = 14400, Phoenix = 21600, LavaWhale = 14400, -- Volcano (guesses: past the Ocean's)
		Beholder = 2700, Sludge = 2400, WarElephant = 3600, Leviathan = 7200, SoulHorse = 9600, -- Godlands
		SnackYak = 3600, RoboShark = 57600, Loong = 86400, -- exclusives
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
	Tutorial = false,
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
		Horse = 1, Pig = 1, Bunny = 1, Pinto = 1, Fish = 1, Rhino = 2, Unicorn = 2, -- Meadow
		Cactus = 1, Kitten = 1, Scorpion = 1, Sandworm = 2, SpineLizard = 2, Snake = 3, -- Desert
		Penguin = 1, Boar = 1, Snowman = 1, IceGolem = 2, SnackYak = 2, Icebringer = 3, -- Tundra
		Starfish = 1, Clownfish = 1, Squid = 2, KingCrab = 2, FishSchool = 2, BlueCrab = 2, RoboShark = 1, Whale = 4, Kraken = 4, Lionfish = 1, -- Ocean (the Robo Shark starts small and grows as it hunts)
		Firebird = 2, RockHog = 2, FireLobster = 2, Rockworm = 2, VolcanoTortoise = 2, Phoenix = 3, LavaWhale = 4, -- Volcano (guesses; the Lava Whale XL like the Whale)
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
	-- FUSE's price (Shared/Fusion.worth): each of the two pets adds its rarity's, so two
	-- Legendaries $2M (QM; Common 100 is Claude's), and a hybrid every pet in it (QM). Back on Oct 7 (QM), after a spell free;
	-- the fuse lesson's fuse is free (FuseLesson).
	FusePrice = { Common = 100, Uncommon = 1000, Rare = 10000, Epic = 100000, Legendary = 1000000 },
	-- What FUSE actually charges is that worth times this (QM, Oct 7: "100x cheaper"): Common $1,
	-- two Legendaries $20k. Hybrids keep their saved worth on the scale above, so it's done here.
	FuseCostScale = 0.01,
	PetSmallSize = 10.4,
	-- Each animal's look, x its size from above (QM, Oct 11: set from the Studio lineup,
	-- tools/lineup.luau). Only how big it looks: its tier, and so what it plows through
	-- or crashes into, is PetTiers'. Unlisted: 1.
	AnimalScale = { LavaWhale = 2.5, VolcanoTortoise = 2.5, RockHog = 1.5, Phoenix = 2 }, -- (QM, Oct 11)
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
		Horse = 3, Pig = 9, Bunny = 12, Pinto = 15, Fish = 24, Rhino = 90, Unicorn = 450, -- Meadow
		Cactus = 18, Kitten = 24, Scorpion = 60, Sandworm = 180, SpineLizard = 240, Snake = 750, -- Desert
		Penguin = 75, Boar = 150, Snowman = 300, IceGolem = 1260, SnackYak = 9000, Icebringer = 3333, -- Tundra
		Starfish = 300, Clownfish = 700, Squid = 2100, KingCrab = 2850, FishSchool = 2550, BlueCrab = 18000, RoboShark = 57000, Whale = 4500, Kraken = 24600, Lionfish = 1500, -- Ocean
		Firebird = 12000, RockHog = 20000, FireLobster = 20000, Rockworm = 25000, VolcanoTortoise = 30000, Phoenix = 45000, LavaWhale = 40000, -- Volcano (guesses: past the Ocean's)
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
		Position = Vector3.new(104, 0, 20), -- the column, on the ground, in the arc base's front right corner (QM, Oct 9); the snake reaches ~-8..+16 in x, -14..+31 in z
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
		VolcanoTortoise = "rbxassetid://89848692685766", -- assets/ui/VolcanoTortoiseEggRender.png
		Firebird = "rbxassetid://100787444937359", -- assets/ui/FirebirdEggRender.png
		RockHog = "rbxassetid://82336240433052", -- assets/ui/RockHogEggRender.png
		Rockworm = "rbxassetid://105149417332337", -- assets/ui/RockwormEggRender.png
		FireLobster = "rbxassetid://83951862994609", -- assets/ui/FireLobsterEggRender.png
		Phoenix = "rbxassetid://77371080716061", -- assets/ui/PhoenixEggRender.png
		LavaWhale = "rbxassetid://137754762277353", -- assets/ui/LavaWhaleEggRender.png
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
	PetSprintSpeed = { Loong = 4 }, -- these sprint at this x instead (QM, Oct 4)
	ReturnSprint = false, -- the ride home always a sprint (SprintSpeed x ReturnSpeed)? Off (QM, Oct 10): Shift sprints there, as on the way out
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
	LassoRange = 34, -- studs, for a Horse-sized animal (QM, Oct 11: bigger ones further, below)
	LassoRangeFrom = 4.6, -- a Horse's half width (studs): an animal this wide or narrower gets LassoRange
	LassoRangeGain = 1, -- studs more range for each stud wider than that
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
	StatsV2 = true, -- this build's sessions count towards /stats' "V2 AVG SESSION TIME" (the stamina loop, QM Oct 9)
	PetPopups = false, -- the "+$N" over each pet at home as it pays out (QM, Oct 9: off for now; income's the same)
	-- The base UI (BaseUi.client; QM, Oct 9): Montserrat ExtraBold, laid out on a
	-- RefWidth-wide screen (QM's Figma) and scaled to yours (x HudScale). Upgrade / Unlock
	-- shows within BullReach studs of your pen's bull spot (BullSpots, by pen number:
	-- design/base_arc's bull pads, none built yet).
	BaseUi = { RefWidth = 1920, BullReach = 16 },
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
	-- how long the Hold bar lasts while you ride it: 2x lasts twice as long.
	AnimalStats = {
		-- Meadow (QM, Oct 11: the Meadow's and the Desert's back to their speeds from before the ladder:
		-- the Meadow is the tutorial and the Desert should come almost at once)
		Horse = { Speed = 1, Stamina = 1 },
		Pig = { Speed = 0.8, Stamina = 0.8 },
		Bunny = { Speed = 1.2, Stamina = 0.7 },
		Pinto = { Speed = 1.1, Stamina = 0.9 },
		Fish = { Speed = 0.6, Stamina = 3 },
		Rhino = { Speed = 1.35, Stamina = 1.8 },
		Unicorn = { Speed = 1.8, Stamina = 2 },
		-- Desert
		Cactus = { Speed = 1.2, Stamina = 1.5 },
		Kitten = { Speed = 1.4, Stamina = 1.2 },
		Scorpion = { Speed = 1.5, Stamina = 1.5 },
		Sandworm = { Speed = 1.6, Stamina = 3 },
		SpineLizard = { Speed = 1.62, Stamina = 2 },
		Snake = { Speed = 2, Stamina = 3 },
		-- Tundra
		Penguin = { Speed = 1.72, Stamina = 1.5 },
		Boar = { Speed = 1.86, Stamina = 1.6 },
		Snowman = { Speed = 2.06, Stamina = 1.3 },
		IceGolem = { Speed = 2.37, Stamina = 3 },
		SnackYak = { Speed = 3, Stamina = 2 }, -- QM, Oct 4 (stamina 1 -> 2)
		Icebringer = { Speed = 3.6, Stamina = 4 }, -- (QM, Oct 11: a Legendary well past the next biome's Uncommons: 1.25x the Starfish, it lands in the Volcano)
		-- Ocean
		Starfish = { Speed = 2.87, Stamina = 2 },
		Squid = { Speed = 3.7, Stamina = 2.6 },
		KingCrab = { Speed = 3.6, Stamina = 3 },
		BlueCrab = { Speed = 5.7, Stamina = 3 }, -- (QM, Oct 11: as the Kraken, a touch slower)
		Lionfish = { Speed = 3.4, Stamina = 2 }, -- QM Oct 11: "a touch faster than the starfish" (the ladder: an Ocean Rare)
		Clownfish = { Speed = 2.8, Stamina = 2.4 }, -- (a little slower than the Starfish, an Ocean Uncommon too)
		RoboShark = { Speed = 1.2, Stamina = 3 }, -- QM, Oct 4: starts at 1.2x, eating takes it up to 3x (Abilities.RoboShark.MaxSpeed 2.5 x this)
		FishSchool = { Speed = 3.95, Stamina = 2.8 },
		Whale = { Speed = 3.2, Stamina = 10 },
		Kraken = { Speed = 5.8, Stamina = 3 }, -- (QM, Oct 11: 1.25x the Firebird, it lands in the Jurassic)
		-- Volcano
		Firebird = { Speed = 4.59, Stamina = 2.5 },
		RockHog = { Speed = 5.4, Stamina = 2.8 },
		Rockworm = { Speed = 6.3, Stamina = 3 },
		FireLobster = { Speed = 5.15, Stamina = 2.8 },
		Phoenix = { Speed = 6.98, Stamina = 3 },
		LavaWhale = { Speed = 5.85, Stamina = 3 },
		VolcanoTortoise = { Speed = 5, Stamina = 3 },
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
