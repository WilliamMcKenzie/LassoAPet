-- The Cactus boss: the Desert's. QM's wide spiky cactus (triangular spikes, a flower on its
-- head, the Cactus pet's face, angry brows). It pops up when the BOSS IN timer runs out and
-- chases you home, like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/CactusBoss.bbmodel (QM's Blockbench file with idle, walk and
-- gallop), converted into CactusBossModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local CactusBossModel = require(script.Parent.CactusBossModel)

return Horse.variant("CactusBoss", CactusBossModel, "Legendary", {
	seat = Vector3.new(0, 10.6, 0),
	neck = { center = Vector3.new(0, 8, 0), radius = 3.2 },
	size = 6.4, -- x the model: about 76 studs, twice the Chicken (QM, Oct 10; was 3.2)
})
