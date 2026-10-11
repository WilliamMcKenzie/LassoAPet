-- The Elder Boar: the Tundra's boss. QM's Boar at 1.5x, greyish brown and angrier (heavy
-- brows, red pupils). It pops up when the BOSS IN timer runs out and chases you home, like
-- the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/ElderBoar.bbmodel (QM's Blockbench file with idle, walk and
-- gallop), converted into ElderBoarModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local ElderBoarModel = require(script.Parent.ElderBoarModel)

return Horse.variant("ElderBoar", ElderBoarModel, "Legendary", {
	seat = Vector3.new(0, 9.4, 2.28), -- the Boar's, x1.5
	neck = { center = Vector3.new(0, 7.41, -6.84), radius = 4 },
	size = 4.6, -- x the model: about 76 studs, twice the Chicken (QM, Oct 10; was 2.3)
})
