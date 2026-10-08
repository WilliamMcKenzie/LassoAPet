-- Where a pen's training dummy stands (QM, Oct 8): just outside the pen, in front of
-- its open side at one corner, facing out the way the pen opens. It follows the pen's
-- size on show (PenLevel swaps the SizeK model in pen.Sizes), so it moves out with
-- the pen as it grows. Training.client builds the dummies, Training.server checks
-- catches against the same spot.
--
--   TrainingSpot.of(pen) -- CFrame at the dummy's foot, facing out (-Z), or nil
--   TrainingSpot.speed(lasso) -- how many times quicker this lasso strength throws

local Config = require(script.Parent.Config)

local TrainingSpot = {}

-- Which way each pen opens. The back row (Pen1..3) opens towards the start line (-Z),
-- the side pens towards the middle of the base; the dummy goes on the corner `side`.
local OPEN = {
	Pen1 = { out = Vector3.new(0, 0, -1), side = Vector3.new(1, 0, 0) },
	Pen2 = { out = Vector3.new(0, 0, -1), side = Vector3.new(1, 0, 0) },
	Pen3 = { out = Vector3.new(0, 0, -1), side = Vector3.new(1, 0, 0) },
	Pen4 = { out = Vector3.new(1, 0, 0), side = Vector3.new(0, 0, 1) },
	Pen5 = { out = Vector3.new(-1, 0, 0), side = Vector3.new(0, 0, 1) },
}

function TrainingSpot.of(pen)
	local open = OPEN[pen.Name]
	local sizes = pen:FindFirstChild("Sizes")
	local shown = sizes and sizes:FindFirstChildWhichIsA("Model")
	if not open or not shown then
		return nil
	end
	local box, size = shown:GetBoundingBox()
	local depth = math.abs(size:Dot(open.out))
	local width = math.abs(size:Dot(open.side))
	local spot = box.Position
		+ open.out * (depth / 2 + Config.Training.Out)
		+ open.side * (width / 2 - Config.Training.In)
	spot = Vector3.new(spot.X, 0, spot.Z)
	return CFrame.lookAt(spot, spot + open.out)
end

function TrainingSpot.speed(lasso)
	local training = Config.Training
	return math.min(1 + training.SpeedPerDecade * math.log10(math.max(lasso or 0, 1)), training.MaxSpeed)
end

return TrainingSpot
