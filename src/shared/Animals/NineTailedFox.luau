-- Nine-tailed Fox: a World 2 Temple Rare (QM, Oct 13), the Fox's rare variant. The Fox's body
-- in gold with crimson ear tips, a crimson flame mark on its forehead, a crimson bib with a gold
-- bell and nine bushy white-tipped tails fanned up behind it. Model from
-- designs/temple/NineTailedFox.bbmodel (tools/temple_fox.py), converted into
-- NineTailedFoxModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local NineTailedFoxModel = require(script.Parent.NineTailedFoxModel)

return Horse.variant("NineTailedFox", NineTailedFoxModel, "Rare", {
	seat = Vector3.new(0, 6.2, 0.7),
	neck = { center = Vector3.new(0, 5.6, -3.7), radius = 2.0 },
})
