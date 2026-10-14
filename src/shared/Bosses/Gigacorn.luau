-- The Gigacorn: World 3 Candyland's boss (Oct 14), after RotMG's Candyland Hunting Grounds boss. A
-- giant white candy unicorn with angry chocolate brows, a red-and-white candy-cane horn with a
-- glowing pink tip, a cotton-candy mane and tail (pink, sky, lilac), frosting drips, peppermint
-- discs on its shoulders and haunches, a candy saddle, a cherry heart on its chest and waffle-cone
-- hooves. It charges you home like the other bosses; the pet reuses the model.
-- Model from designs/candyland/Gigacorn.bbmodel (tools/gigacorn.py), converted (no --zyx) into
-- GigacornModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GigacornModel = require(script.Parent.GigacornModel)

return Horse.variant("Gigacorn", GigacornModel, "Legendary", {
	seat = Vector3.new(0, 8.7, 0.1), -- (no one rides the boss: its saddle)
	neck = { center = Vector3.new(0, 9.8, -4.0), radius = 2.2 },
	size = 3.5, -- x the model (a guess: about 68 studs tall to the horn tip, above the giga rares; Studio tunes it)
})
