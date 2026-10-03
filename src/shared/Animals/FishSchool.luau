-- School of Fish: a swarm of 25 little yellow tangs packed into a rough ball, with a
-- bigger lead fish out front (the lasso loops round it). Epic, Ocean, medium. You
-- ride on the backs of the top fish. Its ability (Config.Abilities, "Wave") sends
-- a wall of fish rushing past across the whole course (client/FishWave.luau).
-- designs/ocean/FishSchool.bbmodel is built and animated by tools/fish_school_design.py,
-- converted into FishSchoolModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local FishSchoolModel = require(script.Parent.FishSchoolModel)

return Horse.variant("FishSchool", FishSchoolModel, "Epic", {
	seat = Vector3.new(0, 4.65, 0.4),
	neck = { center = Vector3.new(0, 2.5, -4.6), radius = 1.1 },
})
