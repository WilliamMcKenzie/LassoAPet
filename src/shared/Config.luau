-- Tuning values shared by the map, the live colours and the ride.
return {
	-- false hides every UI element (HUD, coins, Roblox menus, the ride prompt), e.g. for mockup screenshots.
	ShowHud = true,
	HudScale = 1, -- multiplies the whole HUD's size; 1 matches QM's mockups
	TakeEggSunburst = true, -- turning sunburst behind the TAKE EGG button (trial)
	-- Outline on what the lasso would catch. true: thin white line inside a black
	-- one about twice as thick (trial); false: just the thin white line.
	LayeredOutline = false, -- the mirrored hull draws as a solid black horse in Studio, so off for now
	OutlineWidth = 0.1, -- studs; the black rim reaches 2x this past the target's edges

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
			-- Which animals run in this biome's stampede and how often, by weight
			-- (names are modules in Shared/Animals).
			Herd = { Horse = 30, Pinto = 20, Pig = 20, Fish = 12, Rhino = 8, Unicorn = 3 },
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
			Herd = { Cactus = 30, Scorpion = 16, Sandworm = 8, SpineLizard = 8, Snake = 3 },
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
			UnlockCost = 150,
			PostColor = Color3.fromRGB(206, 118, 72),
			GateImage = "rbxassetid://88918626302524", -- assets/ui/GateLv2.png
		},
		{
			Name = "Snow",
			Length = 6840, -- 3x the desert (QM)
			GroundColors = { Color3.fromRGB(228, 234, 242), Color3.fromRGB(244, 247, 251) },
			WallColors = { Color3.fromRGB(126, 164, 214), Color3.fromRGB(146, 182, 228) },
			Herd = {
				Penguin = 30, Boar = 30, Snowman = 16, WhiteWolf = 16,
				PolarBear = 8, Troll = 8, IceGolem = 8, IceWyvern = 3, IceDrake = 3,
			},
			-- tools/snow_ground.py: cold grass a stud above the snow, ice ponds a stud below.
			Patches = {
				Grass = { Color3.fromRGB(80, 160, 166), Color3.fromRGB(96, 176, 180) },
				Ice = { Color3.fromRGB(160, 188, 244), Color3.fromRGB(178, 202, 250) },
			},
			UnlockCost = 5000,
			PostColor = Color3.fromRGB(126, 164, 214),
			GateImage = nil, -- no LV. 3 art yet: the gate shows "LV. 3 REQUIRED" in text
		},
	},
	-- The gate across the corridor at a locked biome's line: yellow at the floor
	-- fading to clear this many studs up. Only you see it, until you unlock it.
	GateHeight = 26,
	GateColor = Color3.fromRGB(255, 204, 40),
	CourseHalfWidth = 56,
	CourseLength = 9880, -- all the biomes' lengths added up
	HomeHalfWidth = 112,
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
	-- Pet abilities: the Ability button (bottom right while riding), Q or R1.
	-- A pet without an entry has no button. Seconds throughout.
	--   Charge (Rhino): one tap, for Duration: a battering ram at SpeedBoost x speed.
	--     No Hold drain, and every obstacle and animal in the way is knocked flying,
	--     whatever its size. Wind breaks round its head and the camera pulls back.
	--   Leap (Unicorn): one tap: a gallop up into the air and down again in an arc
	--     LeapHeight studs high, over everything, at SpeedBoost x speed with no Hold drain.
	--   Rattle (Snake): one tap: it stops, coils up and rattles for Duration (its
	--     coiled idle), smashing every obstacle within Radius studs and scattering
	--     the animals there away from it, and refilling Restore of the Hold bar. No
	--     Hold drain while it rattles; a blue haze closes in round the screen.
	-- Charge swings the camera round to a cinematic front-side angle.
	Abilities = {
		Rhino = { Kind = "Charge", Duration = 4, Cooldown = 7, SpeedBoost = 1.2 },
		Unicorn = { Kind = "Leap", Duration = 3, Cooldown = 8, SpeedBoost = 1.4, LeapHeight = 14 },
		Snake = { Kind = "Rattle", Duration = 2.4, Cooldown = 6, Radius = 45, Restore = 0.5 },
	},
	-- Size tiers (any whole number, bigger is bigger). A pet plows straight through
	-- obstacles and stampede animals of a lower tier, knocking them up and away;
	-- one of its own tier or higher still crashes it. Obstacles take their tier
	-- from their model's "Tier" attribute, else from ObstacleTiers by name.
	PetTiers = {
		Horse = 1, Pinto = 1, Pig = 1, Fish = 1, Cactus = 1, Scorpion = 1,
		Rhino = 2, Unicorn = 2, Sandworm = 2,
		Snake = 3,
		Penguin = 1, Snowman = 1, PolarBear = 2, IceWyvern = 3,
		SpineLizard = 2, Boar = 1, WhiteWolf = 1, Troll = 2, IceGolem = 2, IceDrake = 3,
	},
	ObstacleTiers = {
		Bush = 1, Rock = 2, Stone = 1, Sandstone = 1, -- small
		Boulder = 2, BoulderSplit = 2, Cactus = 2, SandBoulder = 2, SandBoulderCarved = 2, -- medium
		SandMound = 3, -- large
		Icicle = 1, Pine = 2, IcicleLarge = 2, IceBoulder = 3, -- snow: small, medium, medium, large
	},
	-- Gold per second each pet in your pen earns you (the one you ride too), paid
	-- every second while you're in the game.
	PetIncome = {
		Horse = 1, Pinto = 3, Pig = 3, Fish = 8, Rhino = 40, Unicorn = 150,
		Cactus = 6, Scorpion = 14, Sandworm = 60, Snake = 1000,
		Penguin = 25, Snowman = 60, PolarBear = 250, IceWyvern = 5000,
		SpineLizard = 80, Boar = 30, WhiteWolf = 70, Troll = 280, IceGolem = 260, IceDrake = 4500,
	},
	EggGrowScale = 2, -- a placed egg grows from 1x to this size by the time it hatches
	-- Egg pictures for the eggs in your inventory (the renders the egg reveal uses).
	EggIcons = {
		Pinto = "rbxassetid://79525419811481",
		Pig = "rbxassetid://139970505549400",
		Fish = "rbxassetid://105098230793344",
		Rhino = "rbxassetid://139482781062355",
		Unicorn = "rbxassetid://85066893166855",
		Cactus = "rbxassetid://95599437590618",
		Scorpion = "rbxassetid://138046936786400",
		Sandworm = "rbxassetid://96884572036784",
		Snake = "rbxassetid://71071272639782",
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
		Horse = { Speed = 1, Stamina = 1 },
		Pinto = { Speed = 1.1, Stamina = 0.9 },
		Pig = { Speed = 0.8, Stamina = 0.8 },
		Fish = { Speed = 0.6, Stamina = 3 },
		Rhino = { Speed = 1.5, Stamina = 1.8 },
		Unicorn = { Speed = 2, Stamina = 2 },
		Cactus = { Speed = 1.2, Stamina = 1.5 },
		Scorpion = { Speed = 1.5, Stamina = 1.5 },
		Sandworm = { Speed = 1.6, Stamina = 2 },
		Snake = { Speed = 2, Stamina = 2 },
		Penguin = { Speed = 1.5, Stamina = 1.5 },
		Snowman = { Speed = 1.9, Stamina = 1.3 },
		PolarBear = { Speed = 1.5, Stamina = 3 },
		IceWyvern = { Speed = 3, Stamina = 3 },
		SpineLizard = { Speed = 1.7, Stamina = 2 },
		Boar = { Speed = 1.6, Stamina = 1.6 },
		WhiteWolf = { Speed = 2.3, Stamina = 1.8 },
		Troll = { Speed = 2.5, Stamina = 2 },
		IceGolem = { Speed = 1.6, Stamina = 2.6 },
		IceDrake = { Speed = 2.8, Stamina = 3 },
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
