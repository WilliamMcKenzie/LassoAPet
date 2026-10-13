-- Garnet Statue: World 2 Temple's Epic (QM, Oct 13: "very badass"). A temple guardian lion come to
-- life, carved in garnet reds, two gold horns sweeping back and garnet shards down the spine: a roaring mouth with fangs, glowing eyes under an angry brow,
-- a curled mane, a gold collar and bell, gold anklets and claws.
-- designs/temple/GarnetStatue.bbmodel (tools/temple_statues.py), converted into
-- GarnetStatueModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GarnetStatueModel = require(script.Parent.GarnetStatueModel)

return Horse.variant("GarnetStatue", GarnetStatueModel, "Epic", {
	seat = Vector3.new(0, 6.8, 0.3),
	neck = { center = Vector3.new(0, 6.8, -4.6), radius = 2.8 },
})
