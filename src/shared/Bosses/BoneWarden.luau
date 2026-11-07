-- The Bone Warden: the Dungeon's boss (QM, Nov 7: "bosses for all biomes", taken from
-- FightToStealAnEgg). A skeleton king with a sword. It pops up when the BOSS IN timer runs
-- out and chases you home, like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- BoneWardenModel.luau is FightToStealAnEgg's, copied as is (its idle, walk and gallop).

local Horse = require(script.Parent.Parent.Animals.Horse)
local BoneWardenModel = require(script.Parent.BoneWardenModel)

return Horse.variant("BoneWarden", BoneWardenModel, "Legendary", {
	seat = Vector3.new(0, 9.6, 0), -- (no one rides it: its shoulders)
	neck = { center = Vector3.new(0, 9.6, 0), radius = 1.5 },
	size = 4.76, -- x the model, FightToStealAnEgg's (about 52 studs tall)
})
