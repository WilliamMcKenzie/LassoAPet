-- Treasure Hermit: World 3 Pirate Cove's Rare (Oct 14). A purple hermit crab living in a treasure
-- chest: two gold straps, a gold lock, the lid propped open on a bed of gold with a glowing ruby;
-- the crab's head, eye stalks, claws (one huge) and four legs out front. You ride on the gold.
-- designs/world3/pirate/TreasureHermit.bbmodel (tools/pirate_treasure_hermit.py), converted (--zyx) into TreasureHermitModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local TreasureHermitModel = require(script.Parent.TreasureHermitModel)

return Horse.variant("TreasureHermit", TreasureHermitModel, "Rare", {
	seat = Vector3.new(0, 4.95, 1.2),
	neck = { center = Vector3.new(0, 2.35, -2.8), radius = 1.8 },
})
