-- Tomb Jackal: a World 2 Ancient Tomb Rare (QM, Oct 13), after the Tomb of the Ancients jackal.
-- A tall indigo-black Anubis jackal with very tall gold-lined ears, a gold and lapis nemes
-- headdress with a turquoise scarab, a broad usekh collar, gold armour, a red saddle over
-- lapis drapes with gold ankhs, and gold rings on its legs and tail. Model from
-- designs/tomb/TombJackal.bbmodel (tools/tomb_jackal.py), converted into TombJackalModel.luau
-- by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local TombJackalModel = require(script.Parent.TombJackalModel)

return Horse.variant("TombJackal", TombJackalModel, "Rare", {
	seat = Vector3.new(0, 6.7, 0.7),
	neck = { center = Vector3.new(0, 7.6, -4.2), radius = 2.0 },
})
