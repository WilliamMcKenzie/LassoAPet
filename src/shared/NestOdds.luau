-- What egg a nest holds for a rider: rolled from their NestSeed, a number Nests.server
-- gives every player when they join and after each ride. So each nest's egg is theirs
-- alone and new every ride, and every nest is always stocked (QM, Oct 6: no shared
-- stock, nothing to restock). The same nest and seed always roll the same egg, on
-- the server (the grab: Nests.server) and the client (what's shown: NestEggs) alike.
--
-- Eggs are rolled with exactly the odds of the nest's biome's stampede
-- (Config.Biomes[b].Herd): an animal that's 1 in 100 of the stampede is 1 in 100
-- of the eggs (QM, Oct 2), rarer ones likelier deeper in (Config.NestDepthOdds).
-- The Godlands' nests have their own odds, by how deep in they are (its NestDepth).
--
-- A rider on a wild animal takes that animal's egg instead (Nests.server, NestEggs),
-- but only from the nests of the biome it runs in and later ones (QM, Oct 7/8: a
-- Fish ridden into the Desert gives Fish eggs, but no Kraken eggs in the Meadow);
-- elsewhere the nests hold their rolled eggs. An animal that runs in no biome (the events' exclusives) gives
-- its egg everywhere: finding and riding one is the hard part.
--
-- The rolled eggs are only ever Common or Uncommon (QM, Oct 8): Rare, Epic and Legendary
-- eggs come only from riding the animal itself in its own biome (NestOdds.ridden). A
-- biome with no low ones (the Godlands) rolls the nearest earlier biome's.
--
--   NestOdds.roll(nest, seed, full) -- the animal whose egg `nest` holds for the rider with `seed` ("" if there are no odds; full: from the whole table)
--   NestOdds.ridden(kind, z)   -- the egg a nest at `z` gives a rider on wild animal `kind` in place of its roll: `kind`, or nil (the roll)

local Config = require(script.Parent.Config)
local Godlands = require(script.Parent.Godlands)
local WorldColors = require(script.Parent.WorldColors)

-- Per biome: { { name, weight, rare } }, sorted by name (Herd is a dictionary, and
-- both sides must walk it in the same order). rare: Rare or better, the eggs that
-- get likelier deeper into the biome (Config.NestDepthOdds).
local RARE = { Rare = true, Epic = true, Legendary = true }
local eggOdds = {}
for b, biome in Config.Biomes do
	local odds = {}
	for name, weight in biome.Herd do
		local module = script.Parent.Animals:FindFirstChild(name)
		local ok, class = pcall(require, module)
		table.insert(odds, { name = name, weight = weight, rare = ok and class and RARE[class.Rarity] or false })
	end
	table.sort(odds, function(a, c)
		return a.name < c.name
	end)
	eggOdds[b] = odds
end

-- The biome each animal runs in: the one whose Herd spawns it. One listed only at
-- weight 0 (the Horse, the Snack Yak, the Robo Shark) or not at all (the Loong)
-- runs nowhere, so it has none.
local home = {}
for b, biome in Config.Biomes do
	for name, weight in biome.Herd do
		if weight > 0 then
			home[name] = b
		end
	end
end

-- A Godlands nest's egg, `depth` studs past its line (Config: the Godlands' NestDepth).
local function rollDeep(r, depth, nd)
	local epic = math.clamp(depth / nd.Epic.Over, 0, 1) * nd.Epic.Max
	local legendary = math.clamp((depth - nd.Legendary.From) / nd.Legendary.Over, 0, 1) * nd.Legendary.Max
	local pick = r:NextNumber()
	local pool = if pick < legendary then nd.Legendary.Pool elseif pick < legendary + epic then nd.Epic.Pool else nd.Rare
	return pool[r:NextInteger(1, #pool)]
end

local NestOdds = {}

-- Per biome: its Common and Uncommon eggs (weight > 0), else the nearest earlier biome's.
local lowOdds = {}
for b in Config.Biomes do
	for from = b, 1, -1 do
		local low = {}
		for _, o in eggOdds[from] or {} do
			if not o.rare and o.weight > 0 then
				table.insert(low, o)
			end
		end
		if #low > 0 then
			lowOdds[b] = low
			break
		end
	end
end
-- full: the biome's whole spawn table (the Godlands' deep odds too), for what the
-- nests show on the ride home on a lassoed animal (QM, Oct 8; nothing's grabbed then).
function NestOdds.roll(nest, seed, full)
	local spot = nest:FindFirstChild("EggSpot")
	if not spot then
		return "" -- (not a whole nest: no egg)
	end
	local at = spot.Position
	-- One stream per nest and seed (a seeded Random repeats itself, so both sides roll
	-- alike); the nest's spot tells the nests apart (they're all named Nest).
	local r = Random.new(seed * 65536 + math.round(at.Z) * 64 + math.round(at.X))
	local b = WorldColors.biomeAt(at.Z)
	local nd = full and Config.Biomes[b] and Config.Biomes[b].NestDepth
	if nd and Godlands.start then
		return rollDeep(r, math.max(Godlands.start - at.Z, 0), nd)
	end
	local odds = (if full then eggOdds[b] else lowOdds[b]) or {} -- (grabbable rolls: Common and Uncommon only, QM Oct 8)
	local depth = Config.NestDepthOdds
	local boost = if depth and Config.Biomes[b] then depth.Near + (depth.Far - depth.Near) * WorldColors.along(b, at.Z) else 1
	local total = 0
	for _, o in odds do
		total += o.weight * (if o.rare then boost else 1)
	end
	local pick = r:NextNumber(0, total)
	for _, o in odds do
		pick -= o.weight * (if o.rare then boost else 1)
		if pick < 0 then
			return o.name
		end
	end
	return if #odds > 0 then odds[#odds].name else ""
end

function NestOdds.ridden(kind, z)
	local b = home[kind]
	return if b == nil or WorldColors.biomeAt(z) >= b then kind else nil -- (its biome or any later one: QM, Oct 8)
end

return NestOdds
