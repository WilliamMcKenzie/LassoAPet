-- A basic wooden chair to sit in while lassoing the training dummy (QM, Oct 8).
-- designs/props/TrainingChair.bbmodel (tools/chair_design.py game) -> TrainingChairModel
-- via tools/bbmodel_to_luau.py. Build it with Rig.fromData(TrainingChair.model,
-- "TrainingChair", studTexture). Faces -Z (turn it so -Z points at the dummy), feet on Y = 0.

local TrainingChairModel = require(script.Parent.TrainingChairModel)

return {
	model = TrainingChairModel,
	-- an invisible Seat part goes here, in the model's space: on top of the seat plank,
	-- facing -Z, so the character sits looking the way the chair faces
	seat = { cframe = CFrame.new(0, 2.2, 0), size = Vector3.new(3, 0.2, 3) },
}
