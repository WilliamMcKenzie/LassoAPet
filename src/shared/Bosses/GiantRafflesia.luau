-- The Giant Rafflesia: World 3 Garden's boss (Oct 15; replaces the Flytrap Queen, QM: "use the rafflesia
-- flower and make a giant stemmed flower ... it can just be a stem attached to the ground"). QM's own
-- Rafflesia flower head (five warty petals, a cream rim, a spiny well) on a tall curving stem growing out
-- of a rosette of big leaves. No legs: the stem sways and the petals breathe as it charges.
-- designs/bosses/GiantRafflesia.bbmodel (tools/garden_giant_rafflesia.py), converted --zyx (with --meshes
-- assets/meshes/GiantRafflesia) into GiantRafflesiaModel.luau.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GiantRafflesiaModel = require(script.Parent.GiantRafflesiaModel)

return Horse.variant("GiantRafflesia", GiantRafflesiaModel, "Legendary", {
	seat = Vector3.new(0, 34.0, 1.5), -- (no one rides it: behind the flower)
	seatBone = "Stem",
	neck = { center = Vector3.new(0, 20.0, 0.0), radius = 2.6 },
	size = 1.1, -- x the model (about 54 studs tall, like the Flytrap Queen was; Studio tunes it)
})
