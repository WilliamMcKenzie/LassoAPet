-- The lasso training target (QM, Oct 8): a sackcloth Horse sewn from patches, X eyes,
-- stuck on a wooden pole mid-leap. designs/props/TrainingDummy.bbmodel
-- (tools/dummy_design.py game) -> TrainingDummyModel via tools/bbmodel_to_luau.py.
-- Build it with Rig.fromData(TrainingDummy.model, "TrainingDummy", studTexture); play
-- `idle` on loop and `hit` once when a lasso lands. Faces -Z, the foot on Y = 0.

local TrainingDummyModel = require(script.Parent.TrainingDummyModel)

return {
	model = TrainingDummyModel,
	-- where the lasso closes: round the horse's neck, in the model's space at rest
	neck = { center = Vector3.new(0, 12.27, -1.04), radius = 1.35 },
}
