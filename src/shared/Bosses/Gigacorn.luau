-- The Gigacorn: World 3 Candyland's boss (Oct 14), after RotMG's Candyland Hunting Grounds boss. The
-- Majestic Unicorn reskinned in candy colours (QM, Oct 15): bubblegum socks and muzzle, a cherry
-- horn, brows and hooves, and a cotton-candy mane and tail (bubblegum, sky and lilac), 3x its size.
-- It charges you home like the other bosses; the pet reuses the model.
-- Model: designs/candyland/Gigacorn.bbmodel, QM's designs/world2/MajesticUnicorn.bbmodel with its
-- palette recoloured, converted with --zyx into GigacornModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GigacornModel = require(script.Parent.GigacornModel)

return Horse.variant("Gigacorn", GigacornModel, "Legendary", {
	seat = Vector3.new(0, 7.3, 1.3), -- (the Majestic Unicorn's; no one rides the boss)
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
	size = 6.3, -- x the model: 3x the Majestic Unicorn pet, about 83 studs tall (QM, Oct 15; was 3.5 on the old model)
})
