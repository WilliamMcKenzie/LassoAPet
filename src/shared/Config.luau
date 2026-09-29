-- Tuning values shared by the map, the live colours and the ride.
return {
	-- false hides every UI element (HUD, coins, Roblox menus, the ride prompt), e.g. for mockup screenshots.
	ShowHud = true,
	HudScale = 1, -- multiplies the whole HUD's size; 1 matches QM's mockups

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

	-- Herd
	HerdCount = 12,
	HerdSpeedMin = 26,
	HerdSpeedMax = 36,
	HerdAhead = 260,
	HerdBehind = 70,
}
