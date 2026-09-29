-- Tuning values shared by the world builder and the ride.
return {
	-- World (studs). Ground and wall colours are calibrated so they render like the
	-- Steal an Egg reference under the Lighting set in default.project.json. Home is z > 0, the course runs toward -z.
	Tile = 4,
	GroundColors = { Color3.fromRGB(77, 196, 63), Color3.fromRGB(105, 255, 74) },
	WallColors = { Color3.fromRGB(225, 150, 104), Color3.fromRGB(248, 170, 114) },
	PlotColors = { Color3.fromRGB(96, 106, 134), Color3.fromRGB(128, 139, 166) },
	CourseHalfWidth = 56,
	CourseLength = 1400,
	HomeHalfWidth = 80,
	HomeDepth = 160,
	NestZ = -760,
	StarterSpot = Vector3.new(0, 0, 56),

	-- Ride
	MountSpeed = 44,
	ReturnSpeed = 40,
	SteerSpeed = 28,
	SteerResponse = 8,
	HoldTime = 6,
	LassoRange = 34,
	EggRange = 16,
	LandingGrace = 0.8,
	TurnGrace = 2,

	-- Herd
	HerdCount = 12,
	HerdSpeedMin = 26,
	HerdSpeedMax = 36,
	HerdAhead = 260,
	HerdBehind = 70,
}
