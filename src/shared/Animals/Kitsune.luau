-- Kitsune: World 2 Temple's Legendary (QM, Oct 13: "legendary kitsune (insanely complex
-- and epic)"). A great white fox spirit: nine huge tails fanned up behind it like a halo,
-- each tipped with a glowing blue spirit flame and rippling like one; a straw shrine rope
-- with paper streamers, a gold bell and a red bow; a glowing wish jewel between its tall
-- ears; amber slit eyes, a little shrine fox mask on the side of its head; a red and gold
-- saddle cloth; four fox-fire wisps bobbing at its sides. Large (tier 3).
-- designs/temple/Kitsune.bbmodel (tools/kitsune.py), converted into KitsuneModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local KitsuneModel = require(script.Parent.KitsuneModel)

return Horse.variant("Kitsune", KitsuneModel, "Legendary", {
	seat = Vector3.new(0, 6.65, 0.7),
	neck = { center = Vector3.new(0, 7.2, -2.7), radius = 1.4 },
})
