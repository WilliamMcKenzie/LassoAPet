-- Tuning values shared by the map, the live colours and the ride.
return {
	-- false hides every UI element (HUD, coins, Roblox menus, the ride prompt), e.g. for mockup screenshots.
	ShowHud = true,
	HudScale = 1, -- multiplies the whole HUD's size; 1 matches QM's mockups
	TakeEggSunburst = true, -- turning sunburst behind the TAKE EGG button (trial)
	-- Outline on what the lasso would catch. true: thin white line inside a black
	-- one twice as thick (trial); false: the old thin yellow line.
	LayeredOutline = true,
	OutlineWidth = 0.1, -- studs between the stacked lines; about one line's width at riding distance

	-- World (studs). The map is the saved model src/world/World.rbxmx; these sizes
	-- must match it (the ride reads them). Ground and wall colours are calibrated so
	-- they render like the Steal an Egg reference under the Lighting set in
	-- default.project.json. Home is z > 0, the course runs toward -z.
	GroundColors = { Color3.fromRGB(77, 196, 63), Color3.fromRGB(105, 255, 74) },
	WallColors = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
	CourseHalfWidth = 56,
	CourseLength = 1400,
	HomeHalfWidth = 80,
	StarterSpot = Vector3.new(0, 0, 56),

	-- Ride
	MountSpeed = 44,
	ReturnSpeed = 40,
	SteerSpeed = 28,
	SteerResponse = 8,
	HoldTime = 6,
	LassoRange = 34,
	EggRange = 51, -- about 1.5x LassoRange
	EggSlowMo = 0.5, -- time scale while the egg is in grab range
	LandingGrace = 0.8,
	TurnGrace = 2,
	-- Ride back's vignette: edges only, soft, breathing slowly, to add tension without
	-- covering the lane. Its shape (clear middle 60%) is baked into the image.
	VignetteColor = Color3.fromRGB(210, 30, 30),
	VignetteOpacity = 0.5, -- 0..1: about 30% red at the screen's edges, 50% in the corners
	VignettePulse = 0.3, -- how much it fades on each breath (0 = steady)
	VignetteFadeMetres = 25, -- fades out over this last stretch before home

	-- Coins for landing on an animal, by the animal's rarity (set in its Animals module).
	RarityCoins = { Common = 1, Uncommon = 3, Rare = 5, Epic = 10, Legendary = 25 },

	-- Stampede: a steady stream of animals popping in at the start line, one every
	-- HerdSpawnEvery seconds, whether anyone is riding or not.
	HerdSpawnEvery = 0.9,
	HerdSpeedMin = 26,
	HerdSpeedMax = 36,
}
