-- The Lava Wyrm: the Volcano's boss (QM, Oct 11). The Snake recoloured dragon style, red
-- with a pale beige belly, glowing gold eyes and a big webbed frill of beige spines round
-- the back of its head. It pops up when the BOSS IN timer runs out and chases you home,
-- like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/LavaWyrm.bbmodel (QM's edit of tools/volcano_boss.py's draft,
-- with the Snake's idle, walk and gallop), converted into LavaWyrmModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local LavaWyrmModel = require(script.Parent.LavaWyrmModel)

return Horse.variant("LavaWyrm", LavaWyrmModel, "Legendary", {
	seat = Vector3.new(0, 3.5, 1.6), -- the Snake's
	neck = { center = Vector3.new(0, 2.2, -5), radius = 2.3 },
	size = 4, -- x the model (a guess: about 120 studs nose to tail; Studio tunes it)
})
