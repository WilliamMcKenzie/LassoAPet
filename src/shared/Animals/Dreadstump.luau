-- Dreadstump as a pet (Oct 14): World 3 Pirate Cove's boss, the peg-legged Pirate King, also runs in
-- its biome's stampede about 1 in 500 (Config, World 3 block), a trophy like the Seraphs. You ride
-- on his shoulders behind his head. The same model as the boss (Shared/Bosses/DreadstumpModel,
-- from tools/pirate_dreadstump.py), sized by its tier like any pet.

local Horse = require(script.Parent.Horse)
local DreadstumpModel = require(script.Parent.Parent.Bosses.DreadstumpModel)

return Horse.variant("Dreadstump", DreadstumpModel, "Legendary", {
	seat = Vector3.new(0, 12.6, 1.8), -- (on his shoulders, behind the hat)
	neck = { center = Vector3.new(0, 14.4, -0.2), radius = 2.4 },
})
