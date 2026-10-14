-- Fox: a World 2 Temple Uncommon (QM, Oct 13). An orange red fox with a white chest, cheeks and
-- chin, black stockings, tall black-tipped ears, a red shrine bib and one big bushy tail swept
-- up with a white tip. Model from designs/temple/Fox.bbmodel (tools/temple_fox.py), converted
-- into FoxModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local FoxModel = require(script.Parent.FoxModel)

return Horse.variant("Fox", FoxModel, "Uncommon", {
	seat = Vector3.new(0, 6.2, 0.7),
	neck = { center = Vector3.new(0, 5.6, -3.7), radius = 2.0 },
})
