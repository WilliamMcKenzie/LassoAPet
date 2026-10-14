-- Lion Archer: World 2 Ancient Tomb's Rare (QM, Oct 13: from RotMG's Tomb of the Ancients).
-- A sphinx lion in a lapis-and-gold striped nemes with a gold cobra (glowing ruby) on the
-- brow, a braided beard, kohl-lined eyes and a dark mane fringe; a bead collar, a lapis
-- saddle cloth with an Eye of Horus each side, a red recurve bow on the left flank and a
-- quiver of arrows on the right. designs/tomb/LionArcher.bbmodel (tools/lion_archer.py),
-- converted into LionArcherModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local LionArcherModel = require(script.Parent.LionArcherModel)

return Horse.variant("LionArcher", LionArcherModel, "Rare", {
	seat = Vector3.new(0, 6.85, 0.5),
	neck = { center = Vector3.new(0, 6.4, -4.4), radius = 2.4 },
})
