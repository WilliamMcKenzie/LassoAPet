-- The Seraph: World 2 Meadow's boss (QM, Oct 13: "an absolutely epic biblically accurate
-- angel"). A floating wheel-within-wheels: a big golden eye with a glowing blue iris, three
-- gold rings round it covered in eyes, each spinning on its own axis, six white wings with
-- gold tips spread behind, and a glowing gold halo on top. It pops up when the BOSS IN timer
-- runs out and chases you home, like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/Seraph.bbmodel (tools/angel_boss.py), converted into
-- SeraphModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local SeraphModel = require(script.Parent.SeraphModel)

return Horse.variant("Seraph", SeraphModel, "Legendary", {
	seat = Vector3.new(0, 21.7, 0), -- (no one rides it: the top of its core)
	neck = { center = Vector3.new(0, 18.15, -3.6), radius = 3.6 },
	size = 1.3, -- x the model (a guess: about 80 studs wingtip to wingtip, 57 tall; Studio tunes it)
})
