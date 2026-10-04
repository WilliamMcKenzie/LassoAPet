-- War Elephant: a grey elephant in dark plate armour with steel pyramid spikes, built
-- on the Rhino's rig. Rare, Godlands, large (tier 3): the first Godlands animal (QM, Oct 4).
-- designs/godlands/WarElephant.bbmodel is QM's edit of tools/war_elephant.py's design,
-- converted into WarElephantModel.luau with `tools/bbmodel_to_luau.py --zyx`.

local Horse = require(script.Parent.Horse)
local WarElephantModel = require(script.Parent.WarElephantModel)

return Horse.variant("WarElephant", WarElephantModel, "Rare", {
	seat = Vector3.new(0, 8.1, 1.2),
	neck = { center = Vector3.new(0, 6.4, -4.6), radius = 2.3 },
})
