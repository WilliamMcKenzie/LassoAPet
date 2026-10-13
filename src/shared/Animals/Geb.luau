-- Geb: one of World 2 Ancient Tomb's three Legendaries (QM, Oct 13: the Tomb of the
-- Ancients' bosses, "very complex/detailed"). The green earth god and archer as a centaur:
-- his upper body rises from the front of a great earthen bull and the rider sits on the
-- bull's gold saddle behind him. A gold-and-green nemes with a gold goose on top, glowing
-- gold eyes, a gold bow drawn with a glowing green string and a fire arrow; stone plates
-- split by glowing green cracks, papyrus and lotus on the moss rump, red bombs, a quiver;
-- three fireballs and two green ankhs bob around him. Large (tier 3).
-- designs/tomb/Geb.bbmodel (tools/geb.py), converted into GebModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GebModel = require(script.Parent.GebModel)

return Horse.variant("Geb", GebModel, "Legendary", {
	seat = Vector3.new(0, 7.2, 1.2),
	neck = { center = Vector3.new(0, 8.4, -2.6), radius = 2.1 },
})
