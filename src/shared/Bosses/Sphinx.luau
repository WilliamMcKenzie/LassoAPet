-- The Sphinx: World 2 Ancient Tomb's boss (QM, Oct 13: "a sphinx boss which chases you, very
-- detailed"). A sandstone lion with a pharaoh's head: a gold and lapis striped nemes with a
-- cobra on the brow, glowing turquoise eyes ringed in kohl, a striped false beard, a jewelled
-- collar, big falcon wings that flap as it runs, a striped back cloth, ankh plaques, gold
-- claws. It chases you home like the Chicken; it isn't a pet, so it lives in Shared/Bosses.
-- Model from designs/bosses/Sphinx.bbmodel (tools/sphinx_boss.py), converted into
-- SphinxModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local SphinxModel = require(script.Parent.SphinxModel)

return Horse.variant("Sphinx", SphinxModel, "Legendary", {
	seat = Vector3.new(0, 7.4, 0.8), -- (no one rides it: its back)
	neck = { center = Vector3.new(0, 9.4, -4.4), radius = 2.4 },
	size = 4, -- x the model (a guess: about 48 studs tall; Studio tunes it)
})
