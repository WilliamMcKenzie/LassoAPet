-- Werewolf: the Halloween world's Haunted Hills Epic (QM, Oct 15): a hunched grey-blue wolf with shaggy shoulder tufts, fangs and ripped purple shorts.
-- designs/halloween/Werewolf.bbmodel (tools/halloween_werewolf.py), converted (--zyx --meshes) into
-- WerewolfModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local WerewolfModel = require(script.Parent.WerewolfModel)

return Horse.variant("Werewolf", WerewolfModel, "Epic", {
	seat = Vector3.new(0, 9.2, 0.4),
	neck = { center = Vector3.new(0, 9.8, -5.4), radius = 2.4 },
})
