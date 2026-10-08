-- Where a pen's training dummy stands (QM, Oct 8): just outside the pen, in front of
-- its open side at one corner, facing out the way the pen opens. It follows the pen's
-- size on show (PenLevel swaps the SizeK model in pen.Sizes), so it moves out with
-- the pen as it grows. Training.client builds the dummies, Training.server checks
-- catches against the same spot.
--
--   TrainingSpot.of(pen, out) -- CFrame at the dummy's foot, facing out (-Z), or nil
-- out: studs from the pen's open side to the dummy's pole (default Config.Training.Out;
-- Training.client sizes it to its biome's dummy).
--   TrainingSpot.perCatch(penLevel) -- lasso strength one catch gives (Config.Training)
--   TrainingSpot.speed(lasso) -- how many times quicker this lasso strength throws
--   TrainingSpot.crit(seed, i) -- whether throw i is a lucky CRIT (Config.Training.Crit)

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

function TrainingSpot.perCatch(penLevel)
	local list = Config.Training.PerCatch
	return list[math.clamp(penLevel or 1, 1, #list)]
end

function TrainingSpot.speed(lasso)
	local training = Config.Training
	return training.SpeedPerDecade ^ math.log10(math.max(lasso or 0, 1))
end

-- Whether your throw number i (1 = your first since you joined) is a CRIT
-- (Config.Training.Crit), from your "CritSeed" attribute: the same on your client and
-- the server, so the client knows ahead (the gold rope) and the server pays it.
function TrainingSpot.crit(seed, i)
	local crit = Config.Training.Crit
	if not crit or not seed then
		return false
	end
	if i == crit.First then
		return true
	end
	return Random.new(seed * 7919 + i):NextNumber() < crit.Chance
end

return TrainingSpot
