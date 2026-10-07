-- Speed gates (QM, Oct 7; the speed-gates branch): the zone gates aren't bought
-- with gold any more, they shatter when you ride into them on one of your own
-- pets that's fast enough. Fast enough is its m/s, the same number its nameplate
-- shows (Speed x 20, uncapped: not the curved speed it really travels at, and no
-- abilities). Gold goes on merging instead, priced by how fast the hybrid will be.
--
--   SpeedGates.on()                   Config.SpeedGates.On
--   SpeedGates.need(i)                m/s to break gate i (nil: no gate). Gates 2 to #Biomes are the
--                                     biomes' lines; past that, the endless Godlands' (Config.SpeedGates.Endless)
--   SpeedGates.biome(i)               the biome gate i stands in (its colour and card)
--   SpeedGates.level(player)          gates opened: PenLevel, plus the Godlands' broken ("GodGates")
--   SpeedGates.mps(kind, fuse, stats) a pet's m/s stat scale (Speed x 20: merge prices)
--   SpeedGates.mph(studsPerSecond)    a live speed in mph, as the ride bar and gates count it
--   SpeedGates.topMph(kind, fuse, stats) a pet's flat-out sprint in mph (its nameplate)
--   SpeedGates.anyAnimal(i)           gate i breaks for wild animals too (the Desert's)
--   SpeedGates.mergePrice(a, b)       gold to merge pets a and b ({ kind, fuse, stats })

local Config = require(script.Parent.Config)
local Fusion = require(script.Parent.Fusion)

local SpeedGates = {}

function SpeedGates.on()
	return Config.SpeedGates ~= nil and Config.SpeedGates.On == true
end

function SpeedGates.need(i)
	local n = #Config.Biomes
	local endless = Config.SpeedGates.Endless
	if i > n then
		local last = Config.SpeedGates.Need[Config.Biomes[n].Name]
		return if endless and last then math.floor(last * endless.Growth ^ (i - n) / 10 + 0.5) * 10 else nil
	end
	local biome = Config.Biomes[i]
	return biome and Config.SpeedGates.Need[biome.Name]
end

function SpeedGates.biome(i)
	return Config.Biomes[math.min(i, #Config.Biomes)]
end

function SpeedGates.level(player)
	return (player:GetAttribute("PenLevel") or 1) + (player:GetAttribute("GodGates") or 0)
end

function SpeedGates.mph(studsPerSecond)
	return math.floor(studsPerSecond * Config.SpeedGates.MphPerStud + 0.5)
end

function SpeedGates.topMph(kind, fuse, stats)
	local sprint = Config.PetSprintSpeed[kind] or Config.SprintSpeed
	return SpeedGates.mph(Fusion.stats(kind, fuse, stats).Speed * Config.MountSpeed * sprint)
end

function SpeedGates.anyAnimal(i)
	local biome = Config.Biomes[i]
	return i <= #Config.Biomes and biome ~= nil and (Config.SpeedGates.AnyAnimal or {})[biome.Name] == true
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
