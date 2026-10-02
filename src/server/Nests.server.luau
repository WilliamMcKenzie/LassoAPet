-- Egg nests are shared stock, like Steal an Egg: when the server starts, every
-- Nest in World.Nests holds an egg. The first player to grab one empties that
-- nest for everyone, and it restocks with a fresh egg Config.NestRestock seconds
-- later. Each nest's egg is its "Egg" attribute (an animal name, or "" when
-- empty), which every client reads to show the eggs.
--
-- Eggs are rolled with exactly the odds of the nest's biome's stampede
-- (Config.Biomes[b].Herd): an animal that's 1 in 100 of the stampede is 1 in 100
-- of the eggs (QM, Oct 2).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local world = workspace:WaitForChild("World")
local rng = Random.new()

-- Per biome: { { name, weight } }, sorted by name.
local eggOdds = {}
for b, biome in Config.Biomes do
	local odds = {}
	for name, weight in biome.Herd do
		table.insert(odds, { name = name, weight = weight })
	end
	table.sort(odds, function(a, c)
		return a.name < c.name
	end)
	eggOdds[b] = odds
end

local function roll(nest)
	local odds = eggOdds[WorldColors.biomeAt(nest.EggSpot.Position.Z)]
	local total = 0
	for _, o in odds do
		total += o.weight
	end
	local pick = rng:NextNumber(0, total)
	for _, o in odds do
		pick -= o.weight
		if pick < 0 then
			return o.name
		end
	end
	return if #odds > 0 then odds[#odds].name else ""
end

for _, nest in world.Nests:GetChildren() do
	nest:SetAttribute("Egg", roll(nest))
end

local takeEgg = Instance.new("RemoteEvent")
takeEgg.Name = "TakeEgg"
takeEgg.Parent = ReplicatedStorage

-- A rider grabbed the egg in `nest`: the first grab wins, later ones find it empty.
takeEgg.OnServerEvent:Connect(function(player, nest)
	if typeof(nest) ~= "Instance" or nest.Parent ~= world.Nests then
		return
	end
	if (nest:GetAttribute("Egg") or "") == "" then
		-- On the tutorial's first ride the empty first Meadow nest shows that player
		-- a Config.TutorialEgg of their own (Tutorial.luau): grabbing it leaves the
		-- nest as it is for everyone else.
		if player:GetAttribute("Tutorial") and Config.Tutorial and WorldColors.biomeAt(nest.EggSpot.Position.Z) == 1 then
			player:SetAttribute("CarriedEgg", Config.TutorialEgg)
		end
		return
	end
	player:SetAttribute("CarriedEgg", nest:GetAttribute("Egg")) -- theirs once they ride it home (Hatchery)
	nest:SetAttribute("Egg", "")
	task.delay(Config.NestRestock, function()
		if nest.Parent and nest:GetAttribute("Egg") == "" then
			nest:SetAttribute("Egg", roll(nest))
		end
	end)
end)
