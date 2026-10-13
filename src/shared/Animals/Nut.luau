-- Nut: one of World 2 Ancient Tomb's three Legendaries (QM, Oct 13: the Tomb of the Ancients
-- bosses, "very complex/detailed"). The sky goddess, flying flat out like a diving bird with
-- you on a gold-trimmed saddle between her shoulder blades: sky-blue skin, a lapis wig and gold
-- diadem with a night-sky orb on top, a gold and turquoise usekh collar, a white pleated robe
-- trailing behind in three rippling sections, two lapis sashes, a glowing star in each hand,
-- two huge Isis wings of gold, royal blue, turquoise and night-blue feathers sprinkled with
-- glowing stars, and four little stars orbiting her. Large (tier 3). She never lands, and
-- sprint flies her up like the Phoenix (Config.SprintSpecials).
-- designs/tomb/Nut.bbmodel (tools/nut.py), converted into NutModel.luau by
-- tools/bbmodel_to_luau.py (no --zyx).

local Horse = require(script.Parent.Horse)
local NutModel = require(script.Parent.NutModel)

return Horse.variant("Nut", NutModel, "Legendary", {
	seat = Vector3.new(0, 7.15, -0.9),
	neck = { center = Vector3.new(0, 7.8, -4.0), radius = 1.5 },
})
