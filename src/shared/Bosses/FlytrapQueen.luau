-- The Flytrap Queen: World 3 Garden's boss (Oct 14; rebuilt Oct 15 from QM's hand-edited Venus Flytrap,
-- QM: "the boss has to be more like the new flytrap"). QM's Flytrap at 1.7x with three heads: a purple box
-- bulb on four bent root legs, the Queen's head (magenta inside, pyramid spikes) on the middle stem wearing a
-- crown of magenta pyramid petals with glowing gold tips, two smaller heads on arms at her sides; every pupil
-- glows green. The heads chomp out of step as she charges. designs/bosses/FlytrapQueen.bbmodel
-- (tools/garden_flytrap_queen.py), converted --zyx into FlytrapQueenModel.luau.

local Horse = require(script.Parent.Parent.Animals.Horse)
local FlytrapQueenModel = require(script.Parent.FlytrapQueenModel)

return Horse.variant("FlytrapQueen", FlytrapQueenModel, "Legendary", {
	seat = Vector3.new(0, 11.2, 3.0), -- (no one rides it: its bulb)
	neck = { center = Vector3.new(0, 13.0, -2.0), radius = 2.0 },
	size = 1.6, -- x the model (a guess: about 53 studs tall; Studio tunes it)
})
