-- The Flytrap Queen: World 3 Garden's boss (Oct 14; approved by the coordinator for QM). A towering
-- three-headed flytrap: a purple bulb in two rings of giant leaves on six root legs; the Queen's
-- head (the biggest trap, magenta inside, ringed with pyramid spikes) on a tall central stem,
-- wearing a crown of magenta pyramid petals with glowing gold tips; two more heads on curving
-- stems at her sides; every eye a dark plate with a glowing green pupil. The heads chomp out of
-- step as she charges. designs/bosses/FlytrapQueen.bbmodel (tools/garden_flytrap_queen.py),
-- converted --zyx into FlytrapQueenModel.luau.

local Horse = require(script.Parent.Parent.Animals.Horse)
local FlytrapQueenModel = require(script.Parent.FlytrapQueenModel)

return Horse.variant("FlytrapQueen", FlytrapQueenModel, "Legendary", {
	seat = Vector3.new(0, 12.0, 3.0), -- (no one rides it: its bulb)
	neck = { center = Vector3.new(0, 13.8, 0.5), radius = 2.0 },
	size = 1.6, -- x the model (a guess: about 53 studs tall; Studio tunes it)
})
