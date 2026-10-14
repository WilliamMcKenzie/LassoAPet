-- Dreadstump the Pirate King: World 3 Pirate Cove's boss (Oct 14), after RotMG's Pirate Cave boss.
-- A giant round pirate captain: a red coat with gold trim and epaulettes, a huge black beard
-- with gold-ringed braids, a big red nose, a black tricorn with a skull and a red plume, a gold
-- cutlass, an iron hook, one boot and one wooden peg leg, and his parrot on his shoulder. He
-- chases you home like the Chicken; as a boss he lives in Shared/Bosses (the pet reuses the model).
-- Model from designs/world3/pirate/Dreadstump.bbmodel (tools/pirate_dreadstump.py), converted
-- (--zyx) into DreadstumpModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local DreadstumpModel = require(script.Parent.DreadstumpModel)

return Horse.variant("Dreadstump", DreadstumpModel, "Legendary", {
	seat = Vector3.new(0, 12.6, 1.8), -- (no one rides the boss: his shoulders)
	neck = { center = Vector3.new(0, 14.4, -0.2), radius = 2.4 },
	size = 3, -- x the model (a guess: about 65 studs tall; Studio tunes it)
})
