-- Gigacorn as a pet (Oct 14): World 3 Candyland's boss, the giant candy unicorn, also runs in its
-- biome's stampede about 1 in 1,000 (Config, World 3 block), a trophy like the Seraphs. You ride on
-- its candy saddle. The same model as the boss (Shared/Bosses/GigacornModel, from
-- tools/gigacorn.py), sized by its tier like any pet.

local Horse = require(script.Parent.Horse)
local GigacornModel = require(script.Parent.Parent.Bosses.GigacornModel)

return Horse.variant("Gigacorn", GigacornModel, "Legendary", {
	seat = Vector3.new(0, 9.2, 0.15),
	neck = { center = Vector3.new(0, 10.4, -3.75), radius = 2.0 },
})
