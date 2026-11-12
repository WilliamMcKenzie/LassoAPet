-- The Giant Pumpkin: the Halloween world's Haunted Hills boss (QM, Oct 15). A huge jack-o'-lantern
-- with angry glowing eyes and a toothy grin, a curled stem and two vine arms, hopping after you.
-- designs/halloween/GiantPumpkin.bbmodel (tools/halloween_giant_pumpkin.py), converted --zyx (with
-- --meshes assets/meshes/GiantPumpkin) into GiantPumpkinModel.luau.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GiantPumpkinModel = require(script.Parent.GiantPumpkinModel)

return Horse.variant("GiantPumpkin", GiantPumpkinModel, "Legendary", {
	seat = Vector3.new(0, 12, 0), -- (no one rides it: the top, by the stem)
	neck = { center = Vector3.new(0, 5, 0), radius = 5 },
	size = 4.5, -- x the model: about 55 studs tall (a guess; Studio tunes it)
})
