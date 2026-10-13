-- The Crystal Tyrant: World 2 Crystal Cavern's boss (QM, Oct 13: "a giant evil version of the
-- crystal guy"). The Living Crystal made bulky and dark violet: a taller tip, angry black brows
-- over glowing red eyes, a grin of white pyramid teeth, and a crown of lighter crystal shards
-- with glowing cyan tips behind its head and on its arms. It pops up when the BOSS IN timer runs
-- out and chases you home, like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/CrystalTyrant.bbmodel (tools/crystal_boss.py, with the Living
-- Crystal's (the Cactus's) idle, walk and gallop), converted into CrystalTyrantModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local CrystalTyrantModel = require(script.Parent.CrystalTyrantModel)

return Horse.variant("CrystalTyrant", CrystalTyrantModel, "Legendary", {
	seat = Vector3.new(0, 11.2, 0),
	neck = { center = Vector3.new(0, 9, 0), radius = 3.4 },
	size = 3.6, -- x the model: about 65 studs to the top of its crown, as the Cactus boss (a guess; Studio tunes it)
})
