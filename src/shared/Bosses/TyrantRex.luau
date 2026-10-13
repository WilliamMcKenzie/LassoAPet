-- The Tyrant Rex: the Jurassic's boss (QM, Oct 11). QM's T-Rex recoloured burgundy with dark
-- wine stripes, a dusty rose jaw, black eyes with red pupils and a red mouth. It pops up when
-- the BOSS IN timer runs out and chases you home, like the Chicken; it isn't a pet, so it
-- lives in Shared/Bosses.
-- Model from designs/bosses/TyrantRex.bbmodel (tools/rex_boss.py, with the T-Rex's idle, walk
-- and gallop), converted into TyrantRexModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local TyrantRexModel = require(script.Parent.TyrantRexModel)

return Horse.variant("TyrantRex", TyrantRexModel, "Legendary", {
	seat = Vector3.new(0, 10.38, 0.6), -- the T-Rex's
	neck = { center = Vector3.new(0, 8.8, -4.7), radius = 2.2 },
	size = 4.8, -- x the model: about 130 studs nose to tail (QM, Oct 13: 2x, was 2.4)
})
