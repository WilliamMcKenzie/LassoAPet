-- Tuning values shared by the world builder and the ride.
return {
	-- World (studs). Home is z > 0, the course runs toward -z.
	Tile = 4,
	GroundColors = { Color3.fromRGB(109, 186, 64), Color3.fromRGB(120, 200, 67) },
	WallColors = { Color3.fromRGB(192, 140, 91), Color3.fromRGB(209, 157, 102) },
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
