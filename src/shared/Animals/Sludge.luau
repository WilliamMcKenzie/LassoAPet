-- Sludge: a stepped olive mound of goo with a brown nub on top, a wide black mouth, three
-- eyes and twig arms (QM's pixel art, Oct 4). Medium; it has no legs and oozes along, each
-- tier sliding forward a beat after the one below (the run is the walk, QM).
-- designs/sludge/Sludge.bbmodel is built and animated by tools/sludge_design.py, converted
-- into SludgeModel.luau by tools/bbmodel_to_luau.py. You sit on the nub.

local Horse = require(script.Parent.Horse)
local SludgeModel = require(script.Parent.SludgeModel)

return Horse.variant("Sludge", SludgeModel, "Rare", {
	seat = Vector3.new(0, 8.8, 0), -- on the nub
	neck = { center = Vector3.new(0, 6.6, 0), radius = 3.2 }, -- round the top tier
})
