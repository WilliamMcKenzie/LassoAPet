-- The Shark boss: the Ocean's. QM's angry shark, built off the Robo Shark (angry brows, open
-- jaw, teeth). It pops up when the BOSS IN timer runs out and chases you home, like the
-- Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/SharkBoss.bbmodel (QM's Blockbench file with idle, walk and
-- gallop), converted into SharkBossModel.luau by tools/bbmodel_to_luau.py --zyx. The model
-- is small (Robo Shark sized), so it's scaled up a lot.

local Horse = require(script.Parent.Parent.Animals.Horse)
local SharkBossModel = require(script.Parent.SharkBossModel)

return Horse.variant("SharkBoss", SharkBossModel, "Legendary", {
	seat = Vector3.new(0, 2.2, 0.5),
	neck = { center = Vector3.new(0, 1.6, -1.45), radius = 0.6 },
	size = 9, -- x the model: about 38 studs, like the Chicken; tune freely
})
