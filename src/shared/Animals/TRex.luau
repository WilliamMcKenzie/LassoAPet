-- T-Rex: an orange tyrannosaur with dark brown tiger stripes, a cream belly and jaw, lilac
-- teeth, a grumpy brow and tiny clawed arms (QM, Oct 11). Epic, the Jurassic's first dinosaur.
-- QM's file designs/jurassic/TRex.bbmodel (from tools/trex_v2.py; Claude's idle roar, stomping
-- walk and charging run: trex_v2.py animate), converted by tools/bbmodel_to_luau.py --zyx.
-- QM holds its jaw wide open at rest. You ride on its back.

local Horse = require(script.Parent.Horse)
local TRexModel = require(script.Parent.TRexModel)

return Horse.variant("TRex", TRexModel, "Epic", {
	seat = Vector3.new(0, 10.38, 0.6),
	neck = { center = Vector3.new(0, 8.8, -4.7), radius = 2.2 },
})
