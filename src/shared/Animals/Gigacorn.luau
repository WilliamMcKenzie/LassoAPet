-- Gigacorn as a pet (Oct 14): World 3 Candyland's boss, the giant candy unicorn, also runs in its
-- biome's stampede about 1 in 1,000 (Config, World 3 block), a trophy like the Seraphs. The same
-- model as the boss (Shared/Bosses/GigacornModel: the Majestic Unicorn in candy colours, QM Oct 15),
-- 3x the Majestic Unicorn's size (Config.AnimalScale.Gigacorn).

local Horse = require(script.Parent.Horse)
local GigacornModel = require(script.Parent.Parent.Bosses.GigacornModel)

return Horse.variant("Gigacorn", GigacornModel, "Legendary", {
	seat = Vector3.new(0, 7.3, 1.3), -- (the Majestic Unicorn's)
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
})
