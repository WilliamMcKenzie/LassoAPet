-- How fast an animal runs in the stampede, studs/s, from its Speed stat (QM, Oct 11):
-- HerdSpeed x Speed, but never more than a fixed gap behind you riding the same kind
-- out at a sprint (MountSpeed x SprintSpeed x Speed), that gap the Clownfish's
-- (Config.HerdGapFrom). Up to it, the stampede keeps its old speeds; past it, the faster
-- animals of the later biomes run faster in the stampede, so you no longer whiz past
-- them. Your own riding speed is untouched.
--
--   HerdSpeed(speedStat) -> studs/s

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local RIDDEN = Config.MountSpeed * Config.SprintSpeed -- studs/s ridden out at a sprint, x Speed
local GAP = (RIDDEN - Config.HerdSpeed) * ((Config.AnimalStats[Config.HerdGapFrom] or {}).Speed or 1)

return function(speed)
	return math.max(Config.HerdSpeed * speed, RIDDEN * speed - GAP)
end
