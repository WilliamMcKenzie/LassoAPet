-- Egg nests are shared stock, like Steal an Egg: when the server starts, every
-- Nest in World.Nests holds an egg. The first player to grab one empties that
-- nest for everyone, and it restocks with a fresh egg Config.NestRestock seconds
-- later. Each nest's egg is its "Egg" attribute (an animal name, or "" when
-- empty), which every client reads to show the eggs.
--
-- Eggs are rolled with exactly the odds of the nest's biome's stampede
-- (Config.Biomes[b].Herd): an animal that's 1 in 100 of the stampede is 1 in 100
-- of the eggs (QM, Oct 2), rarer ones likelier deeper in (Config.NestDepthOdds).
--
-- But the egg you take is the animal you're riding (QM, Oct 6): once a rider's got
-- on a wild animal (a "lasso" or "take" cue this ride: not the pet they rode out
-- on), their Ride.client shows every nest holding that animal's egg instead, and
-- their grab says which animal (mountEgg). The rolled egg is for a rider still on
-- their own pet (riding your best pet to a nest would copy it every ride) or on an
-- exclusive event's animal (its egg is the EventNest's).
--
-- The Godlands' nests have their own odds, by how deep in they are (its NestDepth).
--
-- The Godlands never end, so its nests aren't on the map: one goes in each of its
-- tracks (Shared/Godlands) near any player, at a clear spot picked from the server's
-- seed, and goes again once no one is near (see the end).
--
-- The EventNest is Events.server's: its egg is the event's, never rolled, swapped or restocked here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Funnel = require(script.Parent.Funnel)

local world = workspace:WaitForChild("World")
local rng = Random.new()

-- Per biome: { { name, weight, rare } }, sorted by name. rare: Rare or better, the
-- eggs that get likelier deeper into the biome (Config.NestDepthOdds).
local RARE = { Rare = true, Epic = true, Legendary = true }
local eggOdds = {}
for b, biome in Config.Biomes do
	local odds = {}
	for name, weight in biome.Herd do
		local module = ReplicatedStorage.Shared.Animals:FindFirstChild(name)
		local ok, class = pcall(require, module)
		table.insert(odds, { name = name, weight = weight, rare = ok and class and RARE[class.Rarity] or false })
	end
	table.sort(odds, function(a, c)
		return a.name < c.name
	end)
	eggOdds[b] = odds
end

local godlandsStart -- z of the Godlands' line (Shared/Godlands, below)

-- A Godlands nest's egg, `depth` studs past its line (Config: the Godlands' NestDepth).
local function rollDeep(depth, nd)
	local epic = math.clamp(depth / nd.Epic.Over, 0, 1) * nd.Epic.Max
	local legendary = math.clamp((depth - nd.Legendary.From) / nd.Legendary.Over, 0, 1) * nd.Legendary.Max
	local r = rng:NextNumber()
	local pool = if r < legendary then nd.Legendary.Pool elseif r < legendary + epic then nd.Epic.Pool else nd.Rare
	return pool[rng:NextInteger(1, #pool)]
end

local function roll(nest)
	local z = nest.EggSpot.Position.Z
	local b = WorldColors.biomeAt(z)
	local nd = Config.Biomes[b] and Config.Biomes[b].NestDepth
	if nd and godlandsStart then
		return rollDeep(math.max(godlandsStart - z, 0), nd)
	end
	local odds = eggOdds[b] or {}
	local depth = Config.NestDepthOdds
	local boost = if depth and Config.Biomes[b] then depth.Near + (depth.Far - depth.Near) * WorldColors.along(b, z) else 1
	local total = 0
	for _, o in odds do
		total += o.weight * (if o.rare then boost else 1)
	end
	local pick = rng:NextNumber(0, total)
	for _, o in odds do
		pick -= o.weight * (if o.rare then boost else 1)
		if pick < 0 then
			return o.name
		end
	end
	return if #odds > 0 then odds[#odds].name else ""
end

-- Where each rider is and what they're on: their RideSync (the server can't see a
-- ride's anchored character move), kept a few seconds, and whether they've got on
-- a stampede animal this ride (a "lasso" or "take" cue: they're on a wild animal,
-- not the pet they rode out on), till the ride's "end".
local riders = {} -- [player] = { at = Vector3 (rider), t = os.clock(), on = riding an animal, wild }
local function riderOf(player)
	local r = riders[player]
	if not r then
		r = { at = Vector3.zero, t = 0, on = false }
		riders[player] = r
	end
	return r
end
ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _, riderCFrame)
	if typeof(riderCFrame) == "CFrame" and riderCFrame.Position.Z == riderCFrame.Position.Z then
		local r = riderOf(player)
		r.at, r.t, r.on = riderCFrame.Position, os.clock(), type(kind) == "string" and kind ~= ""
	end
end)
ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
	if what == "lasso" or what == "take" then
		riderOf(player).wild = true
	elseif what == "end" then
		riders[player] = nil
		-- The ride's over: an egg still carried was lost on the way (a crash, bucked
		-- off, Home from the fail screen). One brought home was handed in first
		-- (Hatchery's DeliverEgg, sent before this), so this only clears a lost one,
		-- which otherwise stayed set and blocked stealing on the next ride.
		player:SetAttribute("CarriedEgg", nil)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	riders[player] = nil
end)

-- The egg `player` takes instead of a nest's rolled one: `mount`, the animal their
-- Ride.client says they're on (the stampede is theirs alone, so there's nothing here
-- to check it against), as long as they've got on a wild animal this ride and it's an
-- animal a nest can give (not an exclusive: an event animal's egg is the EventNest's).
-- Else nil: the rolled egg (Ride.client sends "" on your own pet or an event animal).
local function mountEgg(player, mount)
	local r = riders[player]
	if not (r and r.wild) or typeof(mount) ~= "string" or mount == "" then
		return nil
	end
	if not ReplicatedStorage.Shared.Animals:FindFirstChild(mount) or table.find(Config.Events.Animals, mount) then
		return nil
	end
	return mount
end

-- Nests from the Desert on are bigger (Config.Biomes[b].NestScale; QM, Oct 6): you
-- ride past them fast there, so they have to show from far off. Only the nest grows,
-- about the bottom of its box so it still sits on the ground; the egg stays its size
-- (Ride.client puts it on the EggSpot, which goes up with the nest).
local function sizeNest(nest, scale)
	local base = nest:GetAttribute("BaseScale") or nest:GetScale() -- (ScaleTo is absolute: never grow one twice)
	nest:SetAttribute("BaseScale", base)
	if base * scale == nest:GetScale() then
		return
	end
	local function bottom()
		local box, size = nest:GetBoundingBox()
		return box.Position - box.UpVector * size.Y / 2
	end
	local was = bottom()
	nest:ScaleTo(base * scale)
	nest:PivotTo(nest:GetPivot() + (was - bottom()))
end

for _, nest in world.Nests:GetChildren() do
	if nest.Name ~= "EventNest" then
		local biome = Config.Biomes[WorldColors.biomeAt(nest.EggSpot.Position.Z)]
		sizeNest(nest, biome and biome.NestScale or 1)
		nest:SetAttribute("Egg", roll(nest))
	end
end

local takeEgg = Instance.new("RemoteEvent")
takeEgg.Name = "TakeEgg"
takeEgg.Parent = ReplicatedStorage

-- A rider grabbed the egg in `nest` (`mount`: the animal they're on, "" on their own
-- pet; Ride.client): the first grab wins, later ones find it empty.
takeEgg.OnServerEvent:Connect(function(player, nest, mount)
	if typeof(nest) ~= "Instance" or nest.Parent ~= world.Nests then
		return
	end
	local kind = nest:GetAttribute("Egg") or ""
	if kind == "" then
		-- On the tutorial's first ride the empty first Meadow nest shows that player an
		-- egg of their own (Tutorial.luau: their lassoed animal's, else a Config.TutorialEgg):
		-- grabbing it leaves the nest as it is for everyone else.
		if player:GetAttribute("Tutorial") and Config.Tutorial and WorldColors.biomeAt(nest.EggSpot.Position.Z) == 1 then
			player:SetAttribute("CarriedEgg", mountEgg(player, mount) or Config.TutorialEgg)
			player:SetAttribute("CarriedEggScale", 1)
			Funnel.step(player, "Grabbed Egg")
		end
		return
	end
	if nest.Name ~= "EventNest" then
		kind = mountEgg(player, mount) or kind -- the wild animal they're riding, if one (see the top)
	end
	player:SetAttribute("CarriedEgg", kind) -- theirs once they ride it home (Hatchery)
	-- A bigger nest's egg stays that much bigger the whole ride (QM, Oct 6): everyone's
	-- Ride.client shows it at this scale (the hatched pet and your eggs aren't changed).
	player:SetAttribute("CarriedEggScale", nest:GetScale() / (nest:GetAttribute("BaseScale") or nest:GetScale()))
	Funnel.step(player, "Grabbed Egg")
	nest:SetAttribute("Egg", "")
	if nest.Name == "EventNest" then
		return -- the event's over (Events.server)
	end
	task.delay(Config.NestRestock, function()
		if nest.Parent and nest:GetAttribute("Egg") == "" then
			nest:SetAttribute("Egg", roll(nest))
		end
	end)
end)

-- The Godlands' nests ---------------------------------------------------------

local Godlands = require(ReplicatedStorage.Shared.Godlands)
local Tracks = require(ReplicatedStorage.Shared.GodlandsTracks)
godlandsStart = Godlands.start

local NEAR = { 1, 3 } -- tracks behind and ahead of a player that have their nest
local WALL_MARGIN = 14 -- studs in from the walls
local PIECE_MARGIN = 16 -- studs clear of a mountain's footprint
local CLEAR = 6 -- studs of plain snow all round the spot

local template = world.Nests:FindFirstChildWhichIsA("Model")
local godlandsNests = {} -- [k] = its nest

-- Where a rider is: their ride's position (riders, above), else their character's.
local function zOf(player)
	local r = riders[player]
	if r and os.clock() - r.t < 3 then
		return r.at.Z
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and root.Position.Z
end

-- A clear spot in track k: level ground round it (all snow, or all stone; no ice or
-- lava), away from the walls and mountains,
-- picked from the server's seed so it's the same spot every time it comes back.
local function spotIn(k)
	local seed = world:GetAttribute("GodlandsSeed") or 1
	local r = Random.new(seed * 7919 + k)
	local track = Godlands.track(k)
	local near = Godlands.segmentStart(k)
	local half = Godlands.halfWidth - WALL_MARGIN
	for _ = 1, 60 do
		local x, along = r:NextNumber(-half, half), r:NextNumber(120, Godlands.length - 120)
		local z = near - along
		local ok, ground = true, Godlands.glyphAt(x, z)
		for dx = -CLEAR, CLEAR, CLEAR do
			for dz = -CLEAR, CLEAR, CLEAR do
				if Godlands.glyphAt(x + dx, z + dz) ~= ground or ground == "~" then
					ok = false
				end
			end
		end
		for _, piece in if ok then Tracks.Pieces[track.Grid] else {} do
			local kit = Tracks.Kit[piece[1]]
			local hx, hz = kit.HalfX or kit.Radius, kit.HalfZ or kit.Radius
			if math.abs(x - piece[2]) < hx + PIECE_MARGIN and math.abs(along + piece[3]) < hz + PIECE_MARGIN then
				ok = false
			end
		end
		if ok then
			return Vector3.new(x, Godlands.heightAt(x, z), z)
		end
	end
	return nil
end

local function addNest(k)
	local spot = spotIn(k)
	if not template or not spot then
		godlandsNests[k] = false -- (no room in this one)
		return
	end
	local nest = template:Clone()
	nest.Name = "GodlandsNest" .. k
	nest:SetAttribute("Egg", "")
	sizeNest(nest, Config.Biomes[#Config.Biomes].NestScale or 1) -- (the Godlands are the last biome)
	local egg = nest:FindFirstChild("EggSpot")
	local fromSpot = CFrame.new(-egg.Position) * nest:GetPivot()
	nest:PivotTo(CFrame.new(spot.X, egg.Position.Y + spot.Y, spot.Z) * fromSpot) -- (the EggSpot as high over the ground as over the map's floor)
	nest:SetAttribute("Egg", roll(nest))
	nest.Parent = world.Nests
	godlandsNests[k] = nest
end

task.spawn(function()
	while not world:GetAttribute("Ready") do
		world:GetAttributeChangedSignal("Ready"):Wait()
	end
	while true do
		task.wait(1)
		local wanted = {}
		for _, player in Players:GetPlayers() do
			local z = zOf(player)
			local k = z and Godlands.segmentAt(z - Godlands.length * NEAR[2])
			if k then
				for j = math.max(k - NEAR[1] - NEAR[2], 0), k do
					wanted[j] = true
				end
			end
		end
		for k in wanted do
			if godlandsNests[k] == nil then
				addNest(k)
			end
		end
		for k, nest in godlandsNests do
			if not wanted[k] then
				if nest then
					nest:Destroy()
				end
				godlandsNests[k] = nil
			end
		end
	end
end)

-- Stealing eggs (QM, Oct 4) ----------------------------------------------------
-- Out on the course, a rider without an egg can lasso the egg off another rider who's
-- carrying one, from as far as they could grab a nest's (Config.LassoRange): their
-- STEAL EGG asks for it (StealEgg, victim) and it's checked here against both riders'
-- RideSync positions, never taken on a client's word. Whoever has it when they get home
-- keeps it (Hatchery's DeliverEgg). After a steal the egg can't change hands again for
-- Config.EggSteal.Lock seconds. EggSteal tells every client (thief, victim, kind, scale) for the
-- effects; the thief's client reels it in and turns for home with it.

local SLACK = 12 -- studs of leeway on the range, for the time the positions take to arrive
local lockedUntil = {} -- [player] = os.clock() before which their egg can't be taken
Players.PlayerRemoving:Connect(function(player)
	lockedUntil[player] = nil
end)

local function riding(player, now)
	local r = riders[player]
	return r and r.on and now - r.t < 1 and r.at.Z < 0 and not player:GetAttribute("Tutorial") and r or nil
end

local eggSteal = Instance.new("RemoteEvent")
eggSteal.Name = "EggSteal"
eggSteal.Parent = ReplicatedStorage
local stealEgg = Instance.new("RemoteEvent")
stealEgg.Name = "StealEgg"
stealEgg.Parent = ReplicatedStorage

stealEgg.OnServerEvent:Connect(function(thief, victim)
	local now = os.clock()
	if typeof(victim) ~= "Instance" or not victim:IsA("Player") or victim == thief then
		return
	end
	local kind = victim:GetAttribute("CarriedEgg")
	local t, v = riding(thief, now), riding(victim, now)
	if not kind or thief:GetAttribute("CarriedEgg") or not t or not v or now < (lockedUntil[victim] or 0) then
		return
	end
	if (Vector3.new(t.at.X, 0, t.at.Z) - Vector3.new(v.at.X, 0, v.at.Z)).Magnitude > Config.LassoRange + SLACK then
		return
	end
	local scale = victim:GetAttribute("CarriedEggScale") or 1
	victim:SetAttribute("CarriedEgg", nil)
	thief:SetAttribute("CarriedEgg", kind)
	thief:SetAttribute("CarriedEggScale", scale)
	lockedUntil[thief] = now + Config.EggSteal.Lock
	eggSteal:FireAllClients(thief, victim, kind, scale)
end)
