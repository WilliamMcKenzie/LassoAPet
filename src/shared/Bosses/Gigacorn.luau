-- The Gigacorn: World 3 Candyland's boss (Oct 14), after RotMG's Candyland Hunting Grounds boss. A
-- giant white candy unicorn, made clean and majestic (QM Oct 15): a tall proud stance, neck held
-- high, a long spiral candy-cane horn with a glowing pink tip, a flowing cotton-candy mane and tail
-- of smooth mesh locks (pink, sky, lilac), determined grape brows, a cherry saddle on a sky blanket
-- with a peppermint each side, and waffle-cone hooves under lilac frosting cuffs.
-- It charges you home like the other bosses; the pet reuses the model.
-- Model from designs/candyland/Gigacorn.bbmodel (tools/gigacorn.py), converted (no --zyx,
-- --meshes: its curved parts are MeshParts from ReplicatedStorage.AnimalMeshes) into
-- GigacornModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Parent.Animals.Horse)
local GigacornModel = require(script.Parent.GigacornModel)

return Horse.variant("Gigacorn", GigacornModel, "Legendary", {
	seat = Vector3.new(0, 9.2, 0.15), -- (no one rides the boss: its saddle)
	neck = { center = Vector3.new(0, 10.4, -3.75), radius = 2.0 },
	size = 3.5, -- x the model (a guess: about 76 studs tall to the horn tip since the Oct 15 remake, was 68; above the giga rares; Studio tunes it)
})
