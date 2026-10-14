-- The Jade Asura: World 2 Temple's boss (QM, Oct 13: "take our asura and give it tusks and
-- make it look 10x cooler and more intimidating and jade color scheme"). The Asura in deep
-- jade and light jade armour: ivory tusks, dark jade demon horns with gold tips, a gold
-- crown, glowing gold eyes, spiked shoulders, a glowing chest gem and a gold ring of
-- glowing jade flames behind its back. Same bones and animations as the Asura pet.
-- Model from designs/bosses/JadeAsura.bbmodel (tools/jade_asura.py), converted --zyx into
-- JadeAsuraModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local JadeAsuraModel = require(script.Parent.JadeAsuraModel)

return Horse.variant("JadeAsura", JadeAsuraModel, "Legendary", {
	seat = Vector3.new(0, 7.1, 1.3), -- (no one rides it: the Asura's seat)
	seatBone = "body",
	neck = { center = Vector3.new(0, 7.8, 0.6), radius = 1.4 },
	size = 4.2, -- x the model (a guess: about 50 studs tall; Studio tunes it)
})
