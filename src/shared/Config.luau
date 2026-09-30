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
		},
		{
			Name = "Desert",
			Length = 760,
			GroundColors = { Color3.fromRGB(232, 188, 102), Color3.fromRGB(250, 214, 130) },
			WallColors = { Color3.fromRGB(206, 118, 72), Color3.fromRGB(226, 138, 88) },
			Herd = { Cactus = 30, Scorpion = 16, Sandworm = 8, Snake = 3 },
			-- Locked behind a gate until your pen is this biome's level (its place
			-- in this list). Upgrading your pen to it costs UnlockCost gold; your pen's
			-- floor tiles take this biome's ground colours and its posts PostColor.
			UnlockCost = 150,
			PostColor = Color3.fromRGB(206, 118, 72),
			GateImage = "rbxassetid://88918626302524", -- assets/ui/GateLv2.png
		},
	},
	-- The gate across the corridor at a locked biome's line: yellow at the floor
	-- fading to clear this many studs up. Only you see it, until you unlock it.
	GateHeight = 26,
	GateColor = Color3.fromRGB(255, 204, 40),
	CourseHalfWidth = 56,
	CourseLength = 1520, -- all the biomes' lengths added up
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
