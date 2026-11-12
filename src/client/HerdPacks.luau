-- Packs in the stampede (QM, Oct 11: Raptors run in threes). When a slot in a biome's
-- schedule (Ride.client's plan) draws a pack animal, the next Config.HerdPacks[kind] - 1
-- slots come with it: they're that kind too, and pop in with it in a V, fanned out either
-- side just behind it. Everything is drawn from generators seeded by the slots, so every
-- client sees the same packs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local HerdPacks = {}
local SPREAD = 8 -- studs between neighbours in a pack's V (start-line units: they widen with the course)
local BEHIND = 10 -- studs each row of the V runs behind the one ahead (a Raptor is 17.6 long, tail and all)

-- The most slots any pack takes up (Ride.client looks this far past the newest slot).
HerdPacks.most = 1
for _, size in Config.HerdPacks do
	HerdPacks.most = math.max(HerdPacks.most, size)
end

-- Slot n of biome b's stream: the lane and kind its own generator draws (the first
-- biome seeds by n alone, so its stream is the same as before biomes had their own).
local function roll(stream, n, b, keys, edge)
	local r = Random.new(if b == 1 then n else n * keys + b - 1)
	local x = r:NextNumber(-edge, edge)
	local pick, kind = r:NextNumber(0, stream.total), nil
	for _, k in stream.kinds do
		kind = k.name
		pick -= k.weight
		if pick < 0 then
			break
		end
	end
	local giga = Config.HalloweenGiga
	if giga and Config.World == 4 then
		-- (one of the Halloween world's giga rares instead, likelier further down the course)
		local far = math.clamp(stream.spawnZ / giga.FarZ, 0, 1)
		if r:NextNumber() < giga.Chance + (giga.MaxChance - giga.Chance) * far then
			kind = giga.Kinds[r:NextInteger(1, #giga.Kinds)]
		end
	end
	return x, kind
end

-- The pack slot n follows, if any: how many slots back its leader is, and the leader's
-- lane and kind. A follower never leads a pack of its own, so packs are always whole.
local function leaderOf(stream, n, b, keys, edge, depth)
	if depth > 8 then
		return nil -- (a run of pack draws that long: let it lead)
	end
	for j = 1, HerdPacks.most - 1 do
		local x, kind = roll(stream, n - j, b, keys, edge)
		if j < (Config.HerdPacks[kind] or 1) and not leaderOf(stream, n - j, b, keys, edge, depth + 1) then
			return j, x, kind
		end
	end
	return nil
end

-- Slot n's plan: { x, kind, lead, lag }. A pack's j-th follower (lead = j) pops in with
-- the slot j before it, lag seconds later, beside its lane.
function HerdPacks.plan(stream, n, b, keys, edge)
	local j, x, kind = leaderOf(stream, n, b, keys, edge, 0)
	if j then
		local row = math.ceil(j / 2)
		local dx = SPREAD * row * (if j % 2 == 1 then 1 else -1)
		if math.abs(x + dx) > edge then
			dx = -dx
		end
		local speed = require(ReplicatedStorage.Shared.HerdSpeed)((Config.AnimalStats[kind] or { Speed = 1 }).Speed)
		return { x = x + dx, kind = kind, lead = j, lag = BEHIND * row / speed }
	end
	x, kind = roll(stream, n, b, keys, edge)
	return { x = x, kind = kind, lead = 0, lag = 0 }
end

return HerdPacks
