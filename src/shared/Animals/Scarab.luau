-- Scarab: World 2 Ancient Tomb's Uncommon (QM, Oct 13), after the Tomb of the Ancients scarab.
-- A chunky sacred beetle: a domed teal shell in stepped layers split by a gold seam, gold rim
-- and studs, lapis stripes, an ankh on each side and a hieroglyph band across the back; a
-- winged red sun crest on its shield; a toothed gold shovel head with a little horn, fan
-- antennae and plate eyes; six spiked legs walking in a tripod gait. You ride on its shell.
-- designs/tomb/Scarab.bbmodel (tools/tomb_scarab.py), converted (--zyx) into ScarabModel.luau
-- by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ScarabModel = require(script.Parent.ScarabModel)

return Horse.variant("Scarab", ScarabModel, "Uncommon", {
	seat = Vector3.new(0, 7.2, 1.2),
	neck = { center = Vector3.new(0, 3.6, -5.6), radius = 2.2 },
})
