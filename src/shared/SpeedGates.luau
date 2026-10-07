-- Speed gates (QM, Oct 7; the speed-gates branch): the zone gates aren't bought
-- with gold any more, they shatter when you ride into them on one of your own
-- pets that's fast enough. Fast enough is its m/s, the same number its nameplate
-- shows (Speed x 20, uncapped: not the curved speed it really travels at, and no
-- abilities). Gold goes on merging instead, priced by how fast the hybrid will be.
--
--   SpeedGates.on()                   Config.SpeedGates.On
--   SpeedGates.need(i)                m/s to break biome i's gate (nil: no gate)
--   SpeedGates.mps(kind, fuse, stats) a pet's m/s (PetPlates shows the same)
--   SpeedGates.mergePrice(a, b)       gold to merge pets a and b ({ kind, fuse, stats })

local Config = require(script.Parent.Config)
local Fusion = require(script.Parent.Fusion)

local SpeedGates = {}

function SpeedGates.on()
	return Config.SpeedGates ~= nil and Config.SpeedGates.On == true
end

function SpeedGates.need(i)
	local biome = Config.Biomes[i]
	return biome and Config.SpeedGates.Need[biome.Name]
end

function SpeedGates.mps(kind, fuse, stats)
	return math.floor(Fusion.stats(kind, fuse, stats).Speed * 20 + 0.5)
end

-- MergePrice.Base x (the hybrid's m/s / MergePrice.From) ^ MergePrice.Power, to two
-- significant figures.
function SpeedGates.mergePrice(a, b)
	local speed = Fusion.best(Fusion.stats(a.kind, a.fuse, a.stats), Fusion.stats(b.kind, b.fuse, b.stats)).Speed
	local p = Config.SpeedGates.MergePrice
	local raw = p.Base * (speed * 20 / p.From) ^ p.Power
	local step = 10 ^ math.max(math.floor(math.log10(math.max(raw, 1))) - 1, 0)
	return math.max(math.floor(raw / step + 0.5) * step, 1)
end

return SpeedGates
