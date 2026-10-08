-- Where a pen's training dummy stands (QM, Oct 8): just outside the pen, in front of
-- its open side at one corner, facing out the way the pen opens. It follows the pen's
-- size on show (PenLevel swaps the SizeK model in pen.Sizes), so it moves out with
-- the pen as it grows. Training.client builds the dummies, Training.server checks
-- catches against the same spot.
--
--   TrainingSpot.of(pen, out) -- CFrame at the dummy's foot, facing out (-Z), or nil
--   TrainingSpot.chair(pen, out, along) -- CFrame at the chair's feet beside it, -Z at the dummy, or nil
-- out: studs from the pen's open side to the dummy's pole (default Config.Training.Out);
-- along: from the pole to the chair (default Config.Training.Chair). Training.client
-- sizes both to its biome's dummy.
--   TrainingSpot.perCatch(penLevel) -- lasso strength one catch gives (Config.Training)
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

function TrainingSpot.of(pen, out)
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
		+ open.out * (depth / 2 + (out or Config.Training.Out))
		+ open.side * (width / 2 - Config.Training.In)
	spot = Vector3.new(spot.X, 0, spot.Z)
	return CFrame.lookAt(spot, spot + open.out)
end

-- The chair you lasso from (Props/TrainingChair): Config.Training.Chair studs along
-- the pen's front from the dummy, towards the pen's middle, turned to face it.
function TrainingSpot.chair(pen, out, along)
	local spot = TrainingSpot.of(pen, out)
	if not spot then
		return nil
	end
	local at = spot.Position - OPEN[pen.Name].side * (along or Config.Training.Chair)
	return CFrame.lookAt(at, spot.Position)
end

function TrainingSpot.perCatch(penLevel)
	local training = Config.Training
	return training.PerCatch * training.PerLevel ^ (math.max(penLevel or 1, 1) - 1)
end

function TrainingSpot.speed(lasso)
	local training = Config.Training
	return 1 + training.SpeedPerDecade * math.log10(math.max(lasso or 0, 1))
end

return TrainingSpot
