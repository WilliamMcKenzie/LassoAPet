-- The Elder Treant: the Forest's boss (QM, Nov 7: "bosses for all biomes", taken from
-- FightToStealAnEgg). The Ancient Treant recoloured teal. It pops up when the BOSS IN timer
-- runs out and chases you home, like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- ElderTreantModel.luau is FightToStealAnEgg's, copied as is (its idle, walk and gallop).

local Horse = require(script.Parent.Parent.Animals.Horse)
local ElderTreantModel = require(script.Parent.ElderTreantModel)

return Horse.variant("ElderTreant", ElderTreantModel, "Legendary", {
	seat = Vector3.new(0, 22, 0), -- (no one rides it: its crown)
	neck = { center = Vector3.new(0, 20.4, 0), radius = 4 },
	size = 1.75, -- x the model, FightToStealAnEgg's (about 56 studs tall)
})
