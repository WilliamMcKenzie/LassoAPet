-- Each pen's training dummy and chair, by biome (QM, Oct 8): the pen for biome n
-- (Config.Biomes[n]) gets entry n. Every dummy is one of its biome's plain animals
-- sewn into a stitched toy on a pole, each biome's bigger than the last (x1.3); the
-- chairs are one size, in the biome's materials. Meadow is QM's stitched horse
-- (Props/TrainingDummy, TrainingChair); the rest come from tools/biome_dummies.py.
-- Build both with Rig.fromData(entry.dummy / entry.chair, name, studTexture); dummies
-- play `idle` on loop and `hit` once per catch. Both face -Z, feet on Y = 0.
-- neck: where the lasso closes, in the dummy's model space at rest.

local Props = script.Parent
local TrainingDummy = require(Props.TrainingDummy)
local TrainingChair = require(Props.TrainingChair)

local function entry(biome, neckCenter, neckRadius)
	return {
		name = biome,
		dummy = require(Props["TrainingDummy" .. biome .. "Model"]),
		chair = require(Props["TrainingChair" .. biome .. "Model"]),
		neck = { center = neckCenter, radius = neckRadius },
	}
end

return {
	{ name = "Meadow", dummy = TrainingDummy.model, chair = TrainingChair.model, neck = TrainingDummy.neck },
	entry("Desert", Vector3.new(-0.35, 19.19, -1.11), 1.48), -- Cactus
	entry("Snow", Vector3.new(0, 23.27, -2.1), 2.89), -- Snowman
	entry("Ocean", Vector3.new(0, 16.58, -1.75), 2.82), -- Starfish
	entry("Godlands", Vector3.new(0, 19.02, -16.3), 7.52), -- War Elephant
	-- the seat on every chair (TrainingChair.seat): same place, they're all one size
	seat = TrainingChair.seat,
}
