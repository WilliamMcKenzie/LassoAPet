-- Egg nests. Every nest is always stocked, and its eggs are yours alone (QM, Oct 6:
-- no shared stock, nothing to restock): when you join and after every ride you get
-- a NestSeed attribute, and what each nest holds for you is NestOdds' roll from it
-- (your Ride.client shows that; here the same roll says what you grabbed). So the
-- nests fill up afresh for each ride, and one player's grab leaves everyone else's
-- eggs alone.
--
-- But the egg you take is the animal you're riding (QM, Oct 6): once a rider's got
-- on a wild animal (a "lasso" or "take" cue this ride: not the pet they rode out
-- on), their Ride.client shows every nest of that animal's own biome holding its egg
-- instead, and their grab says which animal (mountEgg); nests anywhere else keep
-- their rolled eggs (QM, Oct 7: no Snake eggs in the Tundra; NestOdds.ridden), bar
-- an event's animal, whose egg is everywhere (finding and riding one is the hard
-- part). The rolled egg is for a rider still on their own pet (riding your best pet
-- to a nest would copy it every ride).
--
-- The Godlands never end, so its nests aren't on the map: one goes in each of its
-- tracks (Shared/Godlands) near any player, at a clear spot picked from the server's
-- seed, and goes again once no one is near (see the end).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local NestOdds = require(ReplicatedStorage.Shared.NestOdds)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Funnel = require(script.Parent.Funnel)

local world = workspace:WaitForChild("World")
local rng = Random.new()

-- Each player's NestSeed: what NestOdds rolls their nests' eggs from, new for every ride.
local function reseed(player)
	player:SetAttribute("NestSeed", rng:NextInteger(1, 1e9))
end
Players.PlayerAdded:Connect(reseed)
for _, player in Players:GetPlayers() do
	reseed(player)
end

-- Where each rider is: their RideSync (the server can't see a ride's anchored
-- character move), kept a few seconds, and whether they've got on a stampede animal
-- this ride (a "lasso" or "take" cue: they're on a wild animal, not the pet they
-- rode out on), till the ride's "end".
local riders = {} -- [player] = { at = Vector3 (rider), t = os.clock(), wild }
local function riderOf(player)
	local r = riders[player]
	if not r then
		r = { at = Vector3.zero, t = 0 }
		riders[player] = r
	end
	return r
end
ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, _, _, riderCFrame)
	if typeof(riderCFrame) == "CFrame" and riderCFrame.Position.Z == riderCFrame.Position.Z then
		local r = riderOf(player)
		r.at, r.t = riderCFrame.Position, os.clock()
	end
end)
ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
	if what == "lasso" or what == "take" then
		riderOf(player).wild = true
	elseif what == "end" then
		riders[player] = nil
		reseed(player) -- the next ride's eggs (their Ride.client swaps the nests over as they near them)
		-- The ride's over: an egg still carried was lost on the way (a crash, bucked
		-- off, Home from the fail screen). One brought home was handed in first
		-- (Hatchery's DeliverEgg, sent before this), so this only clears a lost one,
		-- which otherwise stayed set: Hatchery would take it as brought home next ride.
		player:SetAttribute("CarriedEgg", nil)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	riders[player] = nil
end)

-- The egg `player` takes instead of a nest's rolled one: `mount`, the animal their
-- Ride.client says they're on (the stampede is theirs alone, so there's nothing here
-- to check it against), as long as they've got on a wild animal this ride and it's a
-- real animal. Else nil: the rolled egg (Ride.client sends "" on your own pet).
local function mountEgg(player, mount)
	local r = riders[player]
	if not (r and r.wild) or typeof(mount) ~= "string" or mount == "" or not ReplicatedStorage.Shared.Animals:FindFirstChild(mount) then
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
	local spot = nest:FindFirstChild("EggSpot")
	if spot then
		local biome = Config.Biomes[WorldColors.biomeAt(spot.Position.Z)]
		sizeNest(nest, biome and biome.NestScale or 1)
	else
		warn("Nest without an EggSpot: " .. nest:GetFullName())
	end
end

local takeEgg = Instance.new("RemoteEvent")
takeEgg.Name = "TakeEgg"
takeEgg.Parent = ReplicatedStorage

-- A rider grabbed the egg in `nest` (`mount`: the animal they're on, "" on their own
-- pet; Ride.client). The nest's as full as ever for everyone else, and for them again
-- next ride.
takeEgg.OnServerEvent:Connect(function(player, nest, mount)
	if typeof(nest) ~= "Instance" or nest.Parent ~= world.Nests then
		return
	end
	local spot = nest:FindFirstChild("EggSpot")
	if not spot then
		return -- (not a whole nest: no egg)
	end
	-- The wild animal they're riding, if one and the nest's in its biome (see the top),
	-- else their roll for the nest.
	local wild = mountEgg(player, mount)
	local kind = (wild and NestOdds.ridden(wild, spot.Position.Z)) or NestOdds.roll(nest, player:GetAttribute("NestSeed") or 0)
	if kind == "" then
		return
	end
	player:SetAttribute("CarriedEgg", kind) -- theirs once they ride it home (Hatchery)
	-- A bigger nest's egg stays that much bigger the whole ride (QM, Oct 6): everyone's
	-- Ride.client shows it at this scale (the hatched pet and your eggs aren't changed).
	player:SetAttribute("CarriedEggScale", nest:GetScale() / (nest:GetAttribute("BaseScale") or nest:GetScale()))
	Funnel.step(player, "Grabbed Egg")
end)

-- The Godlands' nests ---------------------------------------------------------

local Godlands = require(ReplicatedStorage.Shared.Godlands)
local Tracks = require(ReplicatedStorage.Shared.GodlandsTracks)

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
			local g = Godlands.pieceScale -- (laid wider and grown: GodlandsStream)
			local hx, hz = (kit.HalfX or kit.Radius) * g, (kit.HalfZ or kit.Radius) * g
			if math.abs(x - piece[2] * Godlands.widen) < hx + PIECE_MARGIN and math.abs(along + piece[3]) < hz + PIECE_MARGIN then
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
	sizeNest(nest, (Config.Biomes[#Config.Biomes].NestScale or 1) * Godlands.pieceScale) -- (the Godlands are the last biome; grown with its beasts)
	local egg = nest:FindFirstChild("EggSpot")
	local fromSpot = CFrame.new(-egg.Position) * nest:GetPivot()
	nest:PivotTo(CFrame.new(spot.X, egg.Position.Y + spot.Y, spot.Z) * fromSpot) -- (the EggSpot as high over the ground as over the map's floor)
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
