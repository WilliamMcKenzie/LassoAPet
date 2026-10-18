-- VenusFlytrap: World 3's Garden Epic (Oct 14; roster approved by the coordinator for QM): a walking flytrap: a bulb in a rosette of leaves on four root legs, a
-- curving stem and a huge open trap ringed with pyramid spikes that chomps. You ride on the bulb. QM edited the
-- .bbmodel by hand in Blockbench (Oct 15), which is now the source.
-- designs/garden/VenusFlytrap.bbmodel (tools/garden_flytrap.py), converted (--zyx) into VenusFlytrapModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local VenusFlytrapModel = require(script.Parent.VenusFlytrapModel)

return Horse.variant("VenusFlytrap", VenusFlytrapModel, "Epic", {
	seat = Vector3.new(0, 7.1, 0.8),
	neck = { center = Vector3.new(0, 10.3, -2.6), radius = 1.5 },
})
