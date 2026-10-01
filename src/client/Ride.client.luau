-- The stampede ride, simulated locally: auto-run and steering, lasso transfers,
-- the Hold bar, the egg pickup and turnaround, the stampede, failure and the
-- home boundary.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Hud = require(script.Parent.Hud)
local Lasso = require(script.Parent.Lasso)
local Poof = require(script.Parent.Poof)
local Dust = require(script.Parent.Dust)
local Outline = require(script.Parent.Outline)
local PenPets = require(script.Parent.PenPets)
local Tutorial = require(script.Parent.Tutorial)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end
-- Egg nests: shared stock kept by the server (Nests.server.luau). Each Nest in
-- World.Nests shows the egg its "Egg" attribute names ("" = empty, taken by
-- someone). EggSpot marks the egg's centre. The egg is a rigged model so it can
-- twitch in the nest; it turns its face toward the approaching rider.
local EGG_TWITCH_EVERY = { 2, 4 } -- seconds between twitches, random in this range
local takeEgg = ReplicatedStorage:WaitForChild("TakeEgg")
local bankCoins = ReplicatedStorage:WaitForChild("BankCoins")
local deliverEgg = ReplicatedStorage:WaitForChild("DeliverEgg")
local finishCourse = ReplicatedStorage:WaitForChild("FinishCourse")
local ridePet = ReplicatedStorage:WaitForChild("RidePet")
local waitingEggs = {} -- [nest] = { egg, kind, nest, nextTwitch }
local nearEgg -- the waiting egg in grab range, while actionTarget is "egg"

local function rarityOf(kind)
	return require(Animals[kind]).Rarity
end

-- Shows the egg the server says is in `nest`, if any.
local function showNestEgg(nest)
	local kind = nest:GetAttribute("Egg") or ""
	if kind == "" and Tutorial.active and nest == Tutorial.nest then
		kind = Config.TutorialEgg -- the tutorial's egg, only for you (Tutorial)
	end
	local waiting = waitingEggs[nest]
	if waiting and waiting.kind == kind then
		return
	end
	if waiting then
		waiting.egg.model:Destroy()
		waitingEggs[nest] = nil
	end
	if kind ~= "" then
		waiting = { egg = Egg.new(kind), kind = kind, nest = nest, nextTwitch = 0.5 + math.random() * 1.5 }
		waiting.egg.model:PivotTo(nest.EggSpot.CFrame * CFrame.Angles(0, math.pi, 0))
		waiting.egg.model.Parent = nest
		waitingEggs[nest] = waiting
	end
end

-- Obstacle footprints from each obstacle's "Base" part (an invisible footprint),
-- or else its lowest part (a tree's trunk, a rock's base).
local obstacles = {}
for _, model in world.Obstacles:GetChildren() do
	local base = model:FindFirstChild("Base")
	if not base then
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and (not base or part.Position.Y < base.Position.Y) then
				base = part
			end
		end
	end
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, { part = part, cframe = part.CFrame, transparency = part.Transparency })
		end
	end
	table.insert(obstacles, {
		x = base.Position.X,
		z = base.Position.Z,
		hx = base.Size.X / 2,
		hz = base.Size.Z / 2,
		tier = model:GetAttribute("Tier") or Config.ObstacleTiers[model.Name] or 1,
		center = model:GetPivot().Position,
		parts = parts,
	})
end

-- The obstacles again, by 32-stud slice of the course: each slice lists the ones
-- that could matter to something in it, in their order above. A stampede animal
-- swerving (laneX) or a crash check (blockedAt) looks through a few nearby
-- instead of all ~600 every frame.
-- (One table, not separate locals: this chunk is at Luau's 200-local limit.)
local slices = {
	SIZE = 32,
	SWERVE_BEFORE = 40, -- studs: laneX's reach in front of an obstacle
	SWERVE_AFTER = 28, -- and past it
	BLOCK_PAD = 8, -- studs: the most padZ blockedAt is asked for and still uses the slices
	swerve = {},
	block = {},
	NONE = {},
}
function slices.add(list, o, zMin, zMax)
	for slice = math.floor(zMin / slices.SIZE), math.floor(zMax / slices.SIZE) do
		list[slice] = list[slice] or {}
		table.insert(list[slice], o)
	end
end
function slices.at(list, z)
	return list[math.floor(z / slices.SIZE)] or slices.NONE
end
for _, o in obstacles do
	slices.add(slices.swerve, o, o.z - o.hz - slices.SWERVE_AFTER, o.z + o.hz + slices.SWERVE_BEFORE)
	slices.add(slices.block, o, o.z - o.hz - slices.BLOCK_PAD, o.z + o.hz + slices.BLOCK_PAD)
end

-- Size tiers a pet gains on the way home with the egg.
local RETURN_TIER_BONUS = 1

local function tierOf(kind)
	return Config.PetTiers[kind] or 1
end

-- An obstacle a bigger pet plowed into flies up and away and fades; it's back
-- for the next ride (cleanup). Only on this player's screen.
local SMASH_TIME = 0.7
local function smash(o, dir, side)
	o.smashed = true
	local rng = Random.new()
	local offset = Vector3.new(side * 10, 16, dir * 14)
	local spin = CFrame.Angles(rng:NextNumber(-2, 2), rng:NextNumber(-2, 2), rng:NextNumber(-2, 2))
	local info = TweenInfo.new(SMASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, p in o.parts do
		local rel = CFrame.new(o.center):Inverse() * p.cframe
		TweenService:Create(p.part, info, { CFrame = CFrame.new(o.center + offset) * spin * rel, Transparency = 1 }):Play()
	end
	Poof.at(Vector3.new(o.x, 0, o.z))
end

local function unsmashAll()
	for _, o in obstacles do
		if o.smashed then
			o.smashed = nil
			for _, p in o.parts do
				p.part.CFrame, p.part.Transparency = p.cframe, p.transparency
			end
		end
	end
end

local SEAT_OFFSET = CFrame.new(0, 1.6, 0)
local STUDS_PER_METRE = 4
local THROW_TIME = 0.22 -- lasso flying out to the target's neck
local TRANSFER_TIME = 0.4 -- rider pulled across on the rope
local EGG_PULL_TIME = 0.55 -- egg reeled in on the rope
local TURN_TIME = 1
local LIE_HEIGHT = 0.7 -- root part's height when lying on the ground
local EDGE = Config.CourseHalfWidth - 4
-- The stampede runs all the time, whether anyone is riding or not. Each biome has
-- its own stream: its animal n pops in at the biome's start (just behind the start
-- line, or on the line from the biome before) at n * HerdSpawnEvery seconds on the
-- server clock, with its lane, speed and kind drawn from a generator seeded by n,
-- and runs to the biome's end, where it shrinks away. So everyone sees the same
-- stream, and riding never changes it: an animal you lasso just leaves it.
local START_LINE_Z = if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else -2
local SPAWN_Z = START_LINE_Z + 4
local END_Z = -Config.CourseLength + 4 -- the far wall
local FINISH_Z = -Config.CourseLength + Config.FinishFromEnd -- the finish line (World.server puts it there)
local FINISH_DROP = 40 -- studs the leap off the end drops below the floor by the time it lands
local VIEW = 320 -- stampede animals further than this from the camera aren't drawn
local DUST_VIEW = 160 -- landings further than this from the camera kick up no dust
-- They pop in instead of appearing: a poof, then they spring up out of it,
-- overshoot and settle (a damped spring on their scale) with a hop, wait a beat
-- and burst off.
local POP_TIME = 0.45
local POP_HOP = 1.6 -- studs
local POP_HOP_TIME = 0.32
local START_AFTER = POP_TIME + 0.1 -- seconds after popping in
local START_EASE = 0.3 -- seconds: how quickly they get up to speed
local SHRINK = 12 -- studs before its biome's end over which an animal shrinks into nothing

-- Each biome's stream: where it spawns and ends, how long an animal lives in it and
-- its kinds of animal by weight (Config.Biomes[b].Herd), sorted by name so every
-- client picks the same animals. A stream's animals are keyed n * BIOME_KEYS + b - 1.
local BIOME_KEYS = 8

-- An animal's stats (Config.AnimalStats), 1x for any animal not listed.
local function statsOf(kind)
	return Config.AnimalStats[kind] or { Speed = 1, Stamina = 1 }
end

-- How fast a kind runs in the stampede: always exactly this, no variance.
local function herdSpeed(kind)
	return Config.HerdSpeed * statsOf(kind).Speed
end

-- How long the Hold bar lasts on this mount (its Stamina x Config.HoldTime).
local function holdTime(entity)
	return Config.HoldTime * statsOf(entity.kind).Stamina
end
local streams = {}
do
	local edge = 0
	for b, biome in Config.Biomes do
		local startZ, endZ = edge, edge - biome.Length
		edge = endZ
		local s = {
			spawnZ = if b == 1 then SPAWN_Z else startZ - 2,
			endZ = if b == #Config.Biomes then FINISH_Z + 2 else endZ + 2, -- the course stops at the finish line
			kinds = {},
			total = 0,
		}
		local slowest = math.huge
		for name in biome.Herd do
			slowest = math.min(slowest, herdSpeed(name))
		end
		s.life = START_AFTER + START_EASE + (s.spawnZ - s.endZ) / slowest
		assert(biome.Herd, "Config.Biomes[" .. b .. "] (" .. tostring(biome.Name) .. ") has no Herd")
		local names = {}
		for name, weight in biome.Herd do
			table.insert(s.kinds, { name = name, weight = weight })
			table.insert(names, name .. " " .. weight)
			s.total += weight
		end
		table.sort(s.kinds, function(a, c)
			return a.name < c.name
		end)
		table.sort(names)
		streams[b] = s
		-- One line per biome in the Output, to check the stampede matches Config.
		print(string.format("[Herd] %s: spawns at z %.0f, ends at z %.0f: %s", biome.Name, s.spawnZ, s.endZ, table.concat(names, ", ")))
	end
end

-- Where an animal in biome b (at z) stops: its stream's end.
local function streamAt(z)
	return streams[WorldColors.biomeAt(z)]
end

local rng = Random.new()

for _, nest in world.Nests:GetChildren() do
	showNestEgg(nest)
	nest:GetAttributeChangedSignal("Egg"):Connect(function()
		showNestEgg(nest)
	end)
end
Tutorial.init(function()
	if Tutorial.nest then
		showNestEgg(Tutorial.nest)
	end
end)
local herdFolder = Instance.new("Folder")
herdFolder.Name = "Herd"
herdFolder.Parent = workspace


-- An entity is an animal plus its position on the course.
-- yaw 0 faces -z (outbound); yaw pi faces +z (home).
local phase = "idle" -- idle | outbound | turning | return | home | finish | ended
local starter, mount
local herd = {} -- [n] = entity, for the stampede's animals near enough to draw
local plans = {} -- [n] = { x, speed }, the stampede's schedule
local taken = {} -- [n] = true once lassoed out of the stampede
local strays = {} -- former mounts, running on to the far wall with the stampede
local pools = {} -- [kind] = spare animals of that kind for the stampede
local herdClock = workspace:GetServerTimeNow()
local hold, grace = 0, 0
local transfer, tumble, carried
local cutscene -- TAKE EGG close-up: { shake } while the egg is lassoed and reeled in
local heroLeap -- coming home: { t, fromZ, toZ } while the pet leaps the start line in slow motion
local LEAP_FROM = 8 -- studs before the start line where the leap starts
local RUN_OUT_SPEED = 20 -- studs/s the pet lands at, braking over Config.HomeRunOut
local actionTarget
local picked -- an egg or animal the player clicked to target instead of the default
local turnT, camYaw = 0, 0
local focus = Vector3.zero
local touchSteer, padSteer = 0, 0
local coins = 0 -- cash gained this ride; what the Gold icon shows while riding
local touchStart = {}
local sprintKey = false -- Shift or L2 held

-- Every kind of animal in any biome's stampede, with how many of it the pool
-- starts with: about the most of that kind ever near the camera at once. In view
-- (VIEW either side of the camera, or the whole stream if it's shorter) a kind
-- averages its share of the stream divided by the gap it runs between spawns,
-- plus a margin for runs of it.
local classes, poolSizes = {}, {}
for _, stream in streams do
	local window = math.min(2 * VIEW, stream.spawnZ - stream.endZ)
	for _, kind in stream.kinds do
		classes[kind.name] = classes[kind.name] or require(Animals[kind.name])
		pools[kind.name] = pools[kind.name] or {}
		local average = window * kind.weight / stream.total / (Config.HerdSpawnEvery * herdSpeed(kind.name))
		poolSizes[kind.name] = (poolSizes[kind.name] or 0) + average + math.sqrt(average)
	end
end

local function newEntity(x, z, yaw, kind)
	kind = kind or Config.DefaultPet
	classes[kind] = classes[kind] or require(Animals[kind]) -- a pet that isn't in the stampede
	local animal = classes[kind].new()
	local entity = {
		kind = kind,
		animal = animal,
		rootY = animal.model.PrimaryPart.Position.Y,
		x = x,
		z = z,
		yaw = yaw or 0,
		speed = 0,
		latVel = 0,
		turn = 0,
	}
	animal:setSaddled(false)
	animal.model.Parent = herdFolder
	return entity
end

-- Lets a mount go: it runs on with the stampede (turning back downfield if it
-- was heading home) and settles into its own pace.
local function release(entity)
	entity.animal:setSaddled(false)
	entity.lane = entity.x
	entity.cruise = herdSpeed(entity.kind)
	table.insert(strays, entity)
end

-- Every animal running loose on the course: the stampede's and former mounts.
local function allAnimals()
	local list = table.clone(strays)
	for _, entity in herd do
		table.insert(list, entity)
	end
	return list
end

-- Animals step up onto raised ground (the desert's sandstone) and back down
-- over this long, rather than popping.
local STEP_RATE = 25

local function place(entity, yawOffset)
	local now = os.clock()
	local floor = Ground.heightAt(entity.x, entity.z)
	local lift = entity.lift or floor
	lift += (floor - lift) * (1 - math.exp(-STEP_RATE * (now - (entity.liftAt or now))))
	entity.lift, entity.liftAt = lift, now
	entity.animal.model.PrimaryPart.CFrame = CFrame.new(entity.x, entity.rootY + lift + (entity.hop or 0), entity.z)
		* CFrame.Angles(0, entity.yaw + yawOffset, 0)
end

-- Scale and hop of an animal `t` seconds into its pop-in: 0 -> overshoot ~1.2 -> 1.
local function popScale(t)
	return 1 - math.exp(-12.6 * t) * math.cos(26 * t)
end

local function popHop(t)
	return if t < POP_HOP_TIME then POP_HOP * math.sin(math.pi * t / POP_HOP_TIME) else 0
end

-- The first obstacle overlapping (x, z) that's still standing, of at least this tier (1 if nil).
local function blockedAt(x, z, padX, padZ, tier)
	local list = if padZ <= slices.BLOCK_PAD then slices.at(slices.block, z) else obstacles
	for _, o in list do
		if not o.smashed and o.tier >= (tier or 1) and math.abs(o.x - x) < o.hx + padX and math.abs(o.z - z) < o.hz + padZ then
			return o
		end
	end
	return nil
end

-- key = n * BIOME_KEYS + b - 1. The first biome keeps seeding by n alone, so its
-- lanes and speeds are the same as before biomes had their own streams.
local function plan(key)
	local p = plans[key]
	if not p then
		local n, b = key // BIOME_KEYS, key % BIOME_KEYS + 1
		local stream = streams[b]
		local r = Random.new(if b == 1 then n else key)
		p = { x = r:NextNumber(-EDGE, EDGE) }
		local pick = r:NextNumber(0, stream.total)
		for _, kind in stream.kinds do
			p.kind = kind.name
			pick -= kind.weight
			if pick < 0 then
				break
			end
		end
		plans[key] = p
	end
	return p
end

local function smoothstep(a, b, v)
	local t = math.clamp((v - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

-- A stampede animal's x at z: its lane, swerving round any obstacle in the way.
local function laneX(x0, z)
	local x = x0
	for _, o in slices.at(slices.swerve, z) do
		local reach = o.hx + 6
		local d = x0 - o.x
		if math.abs(d) < reach then
			local side = if d >= 0 then 1 else -1
			if math.abs(o.x + side * reach) > EDGE then
				side = -side
			end
			-- Eases out over the 36 studs before the obstacle and back over the 24 after.
			local w = smoothstep(o.z + o.hz + slices.SWERVE_BEFORE, o.z + o.hz + 4, z) * smoothstep(o.z - o.hz - slices.SWERVE_AFTER, o.z - o.hz - 4, z)
			x += (o.x + side * reach - x0) * w
		end
	end
	return math.clamp(x, -EDGE, EDGE)
end

-- Distance run and current speed `a` seconds after setting off, easing up to `speed`.
local function run(speed, a)
	local e = math.exp(-a / START_EASE)
	return speed * (a - START_EASE * (1 - e)), speed * (1 - e)
end

local function character()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return hrp, humanoid
end

local function cleanup()
	if mount then
		mount.animal.model:Destroy()
	end
	mount, transfer, tumble = nil, nil, nil
	if carried then
		carried.part:Destroy()
		carried = nil
	end
	Lasso.stop()
	cutscene = nil
	heroLeap = nil
	Hud.setCutscene(false)
	Outline.set(nil)
	unsmashAll()
end

local startRide
local rideShown = false -- the RIDE button is up: the pet it rides gets the outline
local rideModel -- the pet RIDE rides: the nearest of yours, or the one you clicked
local pickedPet -- a pet you clicked, which RIDE rides while you stay near it
local PICK_KEEP = 40 -- studs: walk further than this from a clicked pet and RIDE goes back to the nearest

-- The pen the server handed you (your "Pen" attribute), if any.
local function myPen()
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	return index and pens and pens:FindFirstChild("Pen" .. index)
end

-- Where the pet you ride sets off from and where you come home to: the first pet
-- spot in your pen, just inside its open side, or the middle of the base without one.
local function homeSpot()
	local pen = myPen()
	local slot = pen and pen:FindFirstChild("Slots") and pen.Slots:FindFirstChild("Slot1")
	return if slot then Vector3.new(slot.Position.X, 0, slot.Position.Z) else Config.StarterSpot
end

-- Rides from an outer pen are steered into the corridor once past this z (the pen's open side).
local leadFromZ = 0
-- A ride from a corner pen (open side facing in) first runs out sideways to this x,
-- curving round toward the start line; nil once it's out.
local exitX = nil
local EXIT_TURN = 10 -- studs from exitX where the curve toward the start line begins

-- The x a ride from a sideways-facing pen runs out to, past its open side and inside the corridor.
local function penExitX()
	local pen = myPen()
	local spawn, area = pen and pen:FindFirstChild("Spawn"), pen and pen:FindFirstChild("Area")
	if not (spawn and area) then
		return nil
	end
	local d = spawn.Position - area.Position
	if math.abs(d.X) <= math.abs(d.Z) then
		return nil -- faces the start line
	end
	-- Straight into the corridor: the corner pens' open sides sit just outside it.
	return math.clamp(spawn.Position.X, -(EDGE - 4), EDGE - 4)
end

-- Which way your pen's open side faces, as a yaw (0 = toward the start line).
local function penYaw()
	local pen = myPen()
	local spawn, area = pen and pen:FindFirstChild("Spawn"), pen and pen:FindFirstChild("Area")
	if not (spawn and area) then
		return 0
	end
	local d = spawn.Position - area.Position
	return math.atan2(-d.X, -d.Z)
end

-- Animal parts can't be hit by raycasts (so they never block the lasso or the
-- mouse); your pets at home are made clickable so you can pick one to ride.
local function setClickable(model, on)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			part.CanQuery = on
		end
	end
end

local function spawnStarter()
	local spot = homeSpot()
	-- The pet waiting on your pen's first spot (the "RidePet" attribute). Nothing is
	-- special about the horse: it's just the default pet. Every other pet in your
	-- pen can be ridden too (PenPets). "" is no pet at all yet: the tutorial's
	-- first pet hatches in the pen and is ridden from there.
	if player:GetAttribute("RidePet") == "" then
		return
	end
	starter = newEntity(spot.X, spot.Z, penYaw(), player:GetAttribute("RidePet") or Config.DefaultPet)
	setClickable(starter.animal.model, true)
end

-- One prompt, kept on whichever pet RIDE rides. It draws nothing; E still
-- works, and the RIDE button shows while it's in range. It lives in Terrain and
-- follows the pet each frame, so it isn't destroyed along with a pet's model.
local rideSpot = Instance.new("Attachment")
local rideOffset = CFrame.identity -- rideSpot relative to the pet's root
local rideSize = Vector3.one -- the pet's bounding box
local RIDE_REACH = 5 -- studs from the pet's outline where RIDE shows
rideSpot.Name = "RideSpot"
local ridePrompt = Instance.new("ProximityPrompt")
ridePrompt.ActionText = "Ride"
ridePrompt.RequiresLineOfSight = false
ridePrompt.MaxActivationDistance = RIDE_REACH
ridePrompt.Style = Enum.ProximityPromptStyle.Custom
ridePrompt.Parent = rideSpot
ridePrompt.PromptShown:Connect(function()
	rideShown = true
	Hud.showRide(true)
end)
ridePrompt.PromptHidden:Connect(function()
	rideShown = false
	Hud.showRide(false)
end)

-- Your pets at home: the starter's model and every pet in your pen.
local function homePets()
	local list = {}
	if starter then
		table.insert(list, starter.animal.model)
	end
	for model in PenPets.pets do
		if model.Parent then
			table.insert(list, model)
		end
	end
	return list
end

-- Each time your pets pay out (PetIncome), every one of them at home pops its
-- Config.PetIncome as "+N$" over its head, like the coins for switching rides.
ReplicatedStorage:WaitForChild("PetIncome").OnClientEvent:Connect(function()
	if phase ~= "idle" then
		return
	end
	for _, model in homePets() do
		local kind = if starter and model == starter.animal.model
			then player:GetAttribute("RidePet") or Config.DefaultPet
			else PenPets.pets[model] and PenPets.pets[model].kind
		local earned = kind and Config.PetIncome[kind]
		if earned and earned > 0 then
			local middle, size = model:GetBoundingBox()
			local root = model.PrimaryPart
			Hud.coinPopupAt(root, middle.Position.Y - root.Position.Y + size.Y / 2 + 1, earned)
		end
	end
end)

-- Stampede animals near home can be ridden too: the ones that have just popped
-- in at the start line (within 40 studs of it). [model] = entity, rebuilt every
-- frame at home.
local herdRideable = {}
local function rideableHerd()
	table.clear(herdRideable)
	for _, entity in herd do
		if not entity.popping and entity.n and entity.z > START_LINE_Z - 40 and entity.animal.model.Parent then
			herdRideable[entity.animal.model] = entity
		end
	end
	return herdRideable
end

-- Flat distance from `at` to the edge of the pet (roughly), so big pets count as near.
local function petDistance(model, at)
	-- A pet's box is slow to measure (every block), and this runs for every pet every
	-- frame at home: one well out of reach is measured from its root instead.
	local root = model.PrimaryPart
	local far = root and Vector2.new(root.Position.X - at.X, root.Position.Z - at.Z).Magnitude
	if far and far > 100 then
		return far - 50, far
	end
	local middle, size = model:GetBoundingBox()
	local d = Vector2.new(middle.X - at.X, middle.Z - at.Z).Magnitude
	return d - math.max(size.X, size.Z) / 2, d
end

-- Every frame at home: bind RIDE to the pet you clicked, else the nearest (your
-- pets, or a stampede animal just in at the start line).
local function updateRideTarget()
	local hrp = character()
	local target
	if hrp then
		local pets = homePets()
		for model in rideableHerd() do
			table.insert(pets, model)
		end
		if pickedPet and not table.find(pets, pickedPet) then
			pickedPet = nil
		end
		if pickedPet and select(2, petDistance(pickedPet, hrp.Position)) > PICK_KEEP then
			pickedPet = nil
		end
		target = pickedPet
		if not target then
			local best = math.huge
			for _, model in pets do
				local d = petDistance(model, hrp.Position)
				if d < best then
					target, best = model, d
				end
			end
		end
	end
	if target ~= rideModel then
		rideModel = target
		if target then
			local middle, size = target:GetBoundingBox()
			rideOffset = target.PrimaryPart.CFrame:ToObjectSpace(middle)
			rideSize = size
			rideSpot.Parent = workspace.Terrain
		else
			rideSpot.Parent = nil
		end
	end
	if rideModel and rideModel.PrimaryPart then
		-- The prompt sits on the point of the pet's outline nearest you, at your
		-- height, so RIDE shows only when you're right up against the pet (from
		-- any side, and whatever its size: the Snake is 50 studs long).
		local box = rideModel.PrimaryPart.CFrame * rideOffset
		local at = if hrp then box:PointToObjectSpace(hrp.Position) else Vector3.zero
		local half = rideSize / 2
		local inside = math.abs(at.X) < half.X and math.abs(at.Z) < half.Z
		-- Standing inside a big pet's box (a Polar Bear's is 11 x 19), the nearest
		-- point would be your own position, where the prompt never fires on E: put
		-- it a stud in toward the pet's middle instead.
		local edge = if inside
			then box:PointToWorldSpace(at * Vector3.new(1, 0, 1) - Vector3.new(at.X, 0, at.Z).Unit)
			else box:PointToWorldSpace(Vector3.new(math.clamp(at.X, -half.X, half.X), 0, math.clamp(at.Z, -half.Z, half.Z)))
		rideSpot.WorldCFrame = CFrame.new(Vector3.new(edge.X, if hrp then hrp.Position.Y else edge.Y, edge.Z))
	end
end

local function clearRideTarget()
	rideModel, pickedPet = nil, nil
	rideSpot.Parent = nil
end

local function rideFromHome()
	if phase == "idle" and rideModel and rideShown and not Tutorial.busy then
		startRide(rideModel)
	end
end
ridePrompt.Triggered:Connect(rideFromHome)

-- Rides `model`: the starter, or a pet from your pen, which swaps places with the
-- starter (the server makes it the one you ride, and the starter joins the pen).
startRide = function(model)
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if not starter then
		spawnStarter()
	end
	humanoid:UnequipTools() -- put any egg away
	local spot = homeSpot()
	local fromPen = model and PenPets.pets[model]
	local fromHerd = model and herdRideable[model]
	clearRideTarget()
	if fromHerd then
		-- Jumped onto a stampede animal: it leaves the stampede and runs on with
		-- you from where it is. Your own pet stays home.
		herd[fromHerd.n], taken[fromHerd.n], fromHerd.n = nil, true, nil
		mount = fromHerd
		mount.popping, mount.hop, mount.dodge = nil, 0, 0
		mount.animal:setScale(1)
		spot = Vector3.new(mount.x, 0, mount.z)
	elseif fromPen then
		ridePet:FireServer(fromPen.id)
		if starter then
			starter.animal.model:Destroy()
			starter = nil
		end
		mount = newEntity(spot.X, spot.Z, 0, fromPen.kind)
	else
		mount, starter = starter, nil
		setClickable(mount.animal.model, false)
	end
	mount.animal:setSaddled(true)
	leadFromZ = spot.Z - 8
	exitX = if fromHerd then nil else penExitX()
	local runningAt = if fromHerd then fromHerd.speed or 0 else 0 -- a stampede animal keeps its pace
	mount.x, mount.z, mount.yaw, mount.speed, mount.latVel = spot.X, spot.Z, 0, runningAt, 0
	phase, hold, grace, camYaw = "outbound", holdTime(mount), 0, 0
	coins = 0
	hrp.Anchored = true
	humanoid.Sit = true
	controls:Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	focus = Vector3.new(mount.x, 0, mount.z)
	Hud.show(true)
	Hud.setDistance("")
	Lasso.start(player.Character)
end

-- Back on foot at home, standing at x, z.
local function finishRide(x, z)
	local hrp, humanoid = character()
	if hrp then
		hrp.Anchored = false
		humanoid.Sit = false
		humanoid.PlatformStand = false
		hrp.CFrame = CFrame.new(x + 6, 4, z)
	end
	cleanup()
	if coins > 0 then
		bankCoins:FireServer(coins) -- this ride's cash goes into the account's gold
		coins = 0
	end
	phase = "idle"
	controls:Enable()
	camera.CameraType = Enum.CameraType.Custom
	Hud.show(false)
	if not starter then
		spawnStarter()
	end
end

local function fail(reason, tip)
	if phase == "ended" then
		return
	end
	Hud.setTip(tip) -- in place of the "+$N" the fail screen shows
	local hrp, humanoid = character()
	local dir = (phase == "return" or phase == "home") and 1 or -1 -- travelDir() is defined further down
	phase = "ended"
	cutscene = nil
	Hud.setCutscene(false)
	if mount then
		release(mount)
		mount = nil
	end
	transfer = nil
	if carried then
		carried.part:Destroy()
		carried = nil
	end
	Outline.set(nil)
	-- Thrown off behind the animal, landing flat on their back until they go home.
	local look = hrp.CFrame.LookVector
	tumble = { t = 0, from = hrp.Position, yaw = math.atan2(-look.X, -look.Z), dir = dir, side = rng:NextNumber() < 0.5 and -1 or 1 }
	humanoid.Sit = false
	humanoid.PlatformStand = true -- no animations: lies stiff
	Hud.setAction(nil)
	Hud.setHold(nil)
	Hud.setDistance("")
	Hud.flash(reason)
	task.delay(0.8, function()
		if phase == "ended" then
			Hud.showHome(true)
		end
	end)
end

local function goHome()
	if phase ~= "ended" then
		return
	end
	Hud.showHome(false)
	local pen = myPen()
	local spawn = pen and pen:FindFirstChild("Spawn")
	local spot = if spawn then spawn.Position else homeSpot()
	finishRide(spot.X - 6, spot.Z) -- just outside your pen's open side
end

local function startTransfer(target)
	local hrp = character()
	local old = mount
	release(old)
	mount = nil
	transfer = { target = target, old = old, t = 0, stage = "throw", from = hrp.Position }
end

local function grabEgg()
	if waitingEggs[nearEgg.nest] ~= nearEgg then
		return -- someone else took it a moment ago
	end
	-- The nest's own egg goes on the lasso (building a new one here stalled the
	-- grab). Out of waitingEggs first, so emptying the nest leaves it alone.
	local egg = nearEgg.egg
	waitingEggs[nearEgg.nest] = nil
	egg.t = math.huge
	egg:update(0) -- stop any twitch, back to rest
	local part = egg.model
	part.Parent = workspace
	takeEgg:FireServer(nearEgg.nest) -- empties the nest for everyone
	carried = { part = part, kind = nearEgg.kind, stage = "throw", t = 0, spin = rng:NextNumber() < 0.5 and -1 or 1 }
	phase, turnT = "turning", 0
	Hud.setAction(nil)
	Hud.setHold(nil)
	-- Cutscene: the camera snaps in on the egg and the UI hides until it's reeled in.
	cutscene = { shake = 0 }
	Hud.setCutscene(true)
end

-- The z of the first gate you can't pass yet (your pen's level decides; see Gate.client).
local function gateZ()
	return WorldColors.gateZ(player:GetAttribute("PenLevel"))
end

-- On the way out, a trail of arrows on the ground from your pet to the nearest
-- egg still waiting ahead of you (not behind a locked gate).
local guide = { -- the egg guide: the beam and its two ends
	ARROW = "rbxassetid://101032148634562", -- assets/ui/GuideArrow.png (chevrons pointing along the trail)
	AHEAD = 6, -- studs in front of the pet where the trail starts
	HEIGHT = 1.4, -- studs up: over the raised ground patches
	from = Instance.new("Attachment"),
	to = Instance.new("Attachment"),
	beam = Instance.new("Beam"),
}
guide.from.Name, guide.to.Name = "GuideFrom", "GuideTo"
guide.beam.Name = "EggGuide"
guide.beam.Texture = guide.ARROW
guide.beam.TextureMode = Enum.TextureMode.Static
guide.beam.TextureLength = 5
guide.beam.TextureSpeed = 1.2
guide.beam.Width0, guide.beam.Width1 = 4, 4
guide.beam.FaceCamera = false
guide.beam.LightEmission = 1
guide.beam.LightInfluence = 0
guide.beam.ZOffset = 6
guide.beam.Color = ColorSequence.new(Color3.fromRGB(255, 236, 120))
guide.beam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.08, 0.15),
	NumberSequenceKeypoint.new(0.9, 0.15),
	NumberSequenceKeypoint.new(1, 1),
})
guide.beam.Attachment0, guide.beam.Attachment1 = guide.from, guide.to
guide.beam.Enabled = false
guide.beam.Parent = guide.from
guide.from.Parent, guide.to.Parent = workspace.Terrain, workspace.Terrain
task.spawn(function()
	game:GetService("ContentProvider"):PreloadAsync({ guide.beam })
end)

local function updateGuide()
	local target
	-- From the pet, or the rider while they're pulled across to a lassoed one.
	local at = if mount then Vector3.new(mount.x, 0, mount.z) else focus
	if phase == "outbound" and not cutscene then
		local best = math.huge
		for nest, waiting in waitingEggs do
			local spot = nest:FindFirstChild("EggSpot")
			if spot and waiting.egg.model.Parent and spot.Position.Z < at.Z - guide.AHEAD and spot.Position.Z > gateZ() then
				local d = (Vector2.new(spot.Position.X, spot.Position.Z) - Vector2.new(at.X, at.Z)).Magnitude
				if d < best then
					target, best = spot.Position, d
				end
			end
		end
	end
	guide.beam.Enabled = target ~= nil
	if target then
		local from = Vector3.new(at.X, 0, at.Z - guide.AHEAD)
		local flat = Vector3.new(target.X, 0, target.Z)
		local along = (flat - from).Unit
		-- Lying flat just above the highest ground (raised patches are a stud up):
		-- the attachments' up is the beam's width direction. ZOffset draws it
		-- toward the camera, over the floor and the obstacles it passes.
		local side = along:Cross(Vector3.yAxis)
		guide.from.WorldCFrame = CFrame.fromMatrix(Vector3.new(from.X, guide.HEIGHT, from.Z), along, side)
		guide.to.WorldCFrame = CFrame.fromMatrix(Vector3.new(flat.X, guide.HEIGHT, flat.Z), along, side)
	end
end

local function eggInRange(waiting)
	local eggPos = waiting.nest.EggSpot.Position
	return waitingEggs[waiting.nest] == waiting and waiting.egg.model.Parent ~= nil and eggPos.Z > gateZ()
		and Vector2.new(eggPos.X - mount.x, eggPos.Z - mount.z).Magnitude < Config.LassoRange
end

local function animalInRange(entity)
	if entity == mount or entity.popping or entity.z < gateZ() then
		return nil -- no lassoing through a locked gate
	end
	local ahead = mount.z - entity.z
	local dx = entity.x - mount.x
	local dist = math.sqrt(ahead * ahead + dx * dx)
	if ahead > -3 and dist < Config.LassoRange then
		return dist + math.abs(dx) * 0.5 -- lower is a better default pick
	end
	return nil
end

-- Everything that can be lassoed right now: waiting eggs, then animals.
local function candidates()
	local list = {}
	if phase ~= "outbound" or transfer or not mount then
		return list
	end
	for _, waiting in waitingEggs do
		if eggInRange(waiting) then
			table.insert(list, waiting)
		end
	end
	for _, entity in allAnimals() do
		if animalInRange(entity) then
			table.insert(list, entity)
		end
	end
	return list
end

local function findTarget()
	if phase ~= "outbound" or transfer or not mount then
		picked = nil
		return nil
	end
	-- A target the player clicked stays chosen while it's still in range.
	if picked then
		if picked.nest and eggInRange(picked) then
			nearEgg = picked
			return "egg"
		elseif not picked.nest and table.find(allAnimals(), picked) and animalInRange(picked) then
			return picked
		end
		picked = nil
	end
	for _, waiting in waitingEggs do
		if eggInRange(waiting) then
			nearEgg = waiting
			return "egg"
		end
	end
	local best, bestScore = nil, math.huge
	for _, entity in allAnimals() do
		local score = animalInRange(entity)
		if score and score < bestScore then
			best, bestScore = entity, score
		end
	end
	return best
end

-- The in-range egg or animal drawn nearest a click or tap, if it's close
-- enough on screen to count as clicking it.
local PICK_RADIUS = 70 -- pixels
local function candidateAt(screenPos)
	local best, bestScore = nil, math.huge
	for _, c in candidates() do
		local model = if c.nest then c.egg.model else c.animal.model
		local cf, size = model:GetBoundingBox()
		local point, onScreen = camera:WorldToScreenPoint(cf.Position)
		if onScreen then
			-- Nearer the camera looks bigger, so allow a wider miss.
			local slack = PICK_RADIUS * math.clamp(size.Magnitude * 3 / point.Z, 1, 3)
			local d = (Vector2.new(point.X, point.Y) - screenPos).Magnitude
			if d < slack and d / slack < bestScore then
				best, bestScore = c, d / slack
			end
		end
	end
	return best
end

local function onAction()
	if phase ~= "outbound" or transfer or not mount or not actionTarget then
		return
	end
	if actionTarget == "egg" then
		grabEgg()
	else
		startTransfer(actionTarget)
	end
end

-- At home, clicking or tapping one of your pets makes RIDE ride it (not while
-- holding an egg: then a click places the egg).
local function pickPetAt(screenPos)
	if not character() or player.Character:FindFirstChildOfClass("Tool") then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = homePets()
	local ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if hit then
		for _, model in homePets() do
			if hit.Instance:IsDescendantOf(model) then
				pickedPet = model
			end
		end
	end
end

local function readSteer()
	local keys = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		keys -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		keys += 1
	end
	return math.clamp(keys + touchSteer + padSteer, -1, 1)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if phase == "idle" then
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			pickPetAt(input.Position)
		end
		return
	end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Clicking or tapping another egg or animal in range targets it instead.
		local hit = candidateAt(Vector2.new(input.Position.X, input.Position.Y))
		local current = if actionTarget == "egg" then nearEgg else actionTarget
		if hit and hit ~= current then
			picked = hit
			return
		end
	end
	if input.UserInputType == Enum.UserInputType.Touch then
		touchStart[input] = input.Position.X
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonA -- (Space is the ability)
		or input.KeyCode == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then
		onAction()
	end
end)

-- Sprint keys. Bound above the default controls so Shift doesn't also toggle
-- shift lock while riding; outside a ride it's passed on as usual.
ContextActionService:BindActionAtPriority("Sprint", function(_, state)
	sprintKey = state == Enum.UserInputState.Begin
	if phase == "idle" then
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL2)

local function sprinting()
	if phase == "return" then
		return Config.ReturnSprint -- racing home with the egg
	end
	return phase == "outbound" and not Tutorial.active and (sprintKey or Hud.sprintHeld())
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and touchStart[input] then
		touchSteer = math.clamp((input.Position.X - touchStart[input]) / 70, -1, 1)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
		padSteer = math.abs(input.Position.X) > 0.2 and input.Position.X or 0
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if touchStart[input] then
		touchStart[input] = nil
		touchSteer = 0
	end
end)

local function travelDir()
	return (phase == "return" or phase == "home") and 1 or -1
end

-- Building an animal is slow, so the pool is filled before anyone rides, and if
-- it ever runs dry, only a couple are built per frame (the rest show up a frame
-- or two later, far from the camera).
local BUILD_PER_FRAME = 2
local builtThisFrame = 0

local function takeFromPool(n, x, z, kind)
	local entity = table.remove(pools[kind])
	if not entity then
		if builtThisFrame >= BUILD_PER_FRAME then
			return nil
		end
		builtThisFrame += 1
		entity = newEntity(x, z, 0, kind)
	end
	entity.n, entity.x, entity.z, entity.yaw, entity.dodge = n, x, z, 0, 0
	entity.animal.speed, entity.animal.turn = 0, 0 -- a reused animal starts standing, not mid-gallop
	entity.animal.model.Parent = herdFolder
	return entity
end

-- Frost (the Icebringer's ability, Config.Abilities): the stampede animals it has
-- slowed, by key, with the seconds left, and how many studs each has fallen behind
-- its place in the shared stampede (kept: a slowed animal never sprints to catch up).
-- Strays carry their own entity.frostLeft. Only this player's copy slows, like slow-mo.
local vfx = {} -- ability VFX bits and state (one table: this chunk is at Luau's 200-local limit)
vfx.frostLeft = {}
vfx.frostLag = {}
vfx.frostSlow = 0 -- the share of its speed a slowed animal loses (the running Frost's Slow)
vfx.FROST_TINT = Color3.fromRGB(150, 220, 255)
vfx.FLAKE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- Frosted over while slowed: an icy tint and snowflakes drifting off it.
function vfx.setFrosted(entity, on)
	if on == (entity.frostFx ~= nil) then
		return
	end
	if not on then
		for _, fx in entity.frostFx do
			fx:Destroy()
		end
		entity.frostFx = nil
		return
	end
	local model = entity.animal.model
	local glow = Instance.new("Highlight")
	glow.FillColor = vfx.FROST_TINT
	glow.FillTransparency = 0.45
	glow.OutlineColor = Color3.new(1, 1, 1)
	glow.OutlineTransparency = 0.2
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Adornee = model
	glow.Parent = model
	local flakes = Instance.new("ParticleEmitter")
	flakes.Texture = vfx.FLAKE_TEXTURE
	flakes.Color = ColorSequence.new(Color3.new(1, 1, 1), vfx.FROST_TINT)
	flakes.LightEmission = 0.6
	flakes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	flakes.Transparency = NumberSequence.new(0.1)
	flakes.Lifetime = NumberRange.new(0.6, 1.1)
	flakes.Speed = NumberRange.new(2, 5)
	flakes.SpreadAngle = Vector2.new(180, 180)
	flakes.Acceleration = Vector3.new(0, -6, 0)
	flakes.Rate = 18
	flakes.Parent = model.PrimaryPart
	entity.frostFx = { glow, flakes }
end

local function putInPool(entity)
	vfx.setFrosted(entity, false)
	local active = entity.ability and entity.ability.active
	for _, fx in if active then active.fx else {} do
		fx:Destroy()
	end
	entity.animal.model.Parent = nil
	entity.animal:setScale(1)
	entity.hop, entity.popping, entity.lift = 0, nil, nil
	entity.ability, entity.frostLeft, entity.fall = nil, nil, nil
	table.insert(pools[entity.kind], entity)
end

-- Done with an animal: back in its kind's pool if the stampede has one (building
-- a new one later is what stalls a frame), else gone.
local function retire(entity)
	if pools[entity.kind] then
		putInPool(entity)
	else
		entity.animal.model:Destroy()
	end
end

-- Advances an animal's animation, kicking up hoof dust when a leap lands near the camera.
local function animate(entity, dt, speed, turn)
	if entity.animal:update(dt, speed, turn) then
		local root = entity.animal.model.PrimaryPart.CFrame
		if (root.Position - camera.CFrame.Position).Magnitude < DUST_VIEW then
			Dust.kick(root, entity.animal.scale)
		end
	end
end

-- Pets in your pen amble between random spots inside its fence, resting a
-- while at each. Works for any pet.
local WANDER_SPEED = 6 -- studs/s, a walk
local function wander(entity, dt)
	local pen = myPen()
	local area = pen and pen:FindFirstChild("Area")
	local w = entity.wander
	if not w then
		w = { rest = rng:NextNumber(1, 3) }
		entity.wander = w
	end
	local speed, turn = 0, 0
	if area then
		if w.rest > 0 then
			w.rest -= dt
			if w.rest <= 0 then
				local half = area.Size / 2
				w.tx = area.Position.X + rng:NextNumber(-half.X, half.X)
				w.tz = area.Position.Z + rng:NextNumber(-half.Z, half.Z)
			end
		elseif w.tx then
			local dx, dz = w.tx - entity.x, w.tz - entity.z
			if dx * dx + dz * dz < 1 then
				w.tx, w.rest = nil, rng:NextNumber(2, 5)
			else
				-- yaw 0 faces -z, so the heading toward (dx, dz) is atan2(-dx, -dz)
				local diff = (math.atan2(-dx, -dz) - entity.yaw + math.pi) % (2 * math.pi) - math.pi
				entity.yaw += math.clamp(diff, -3 * dt, 3 * dt)
				turn = -math.clamp(diff, -1, 1) -- turn is + to the right, which is -yaw
				speed = WANDER_SPEED * math.max(0, math.cos(diff)) -- turn on the spot first
				entity.x -= math.sin(entity.yaw) * speed * dt
				entity.z -= math.cos(entity.yaw) * speed * dt
			end
		else
			w.rest = 1
		end
	end
	place(entity, 0)
	animate(entity, dt, speed, turn)
end

-- shown: false while it's out of view (see updateHerd), when it only keeps its
-- place on the course and its model waits where it was.
local function moveAnimal(entity, x, z, speed, dt, shown)
	local lat = (x - entity.x) / math.max(dt, 1e-3)
	entity.x, entity.z, entity.speed = x, z, speed
	if shown then
		place(entity, -math.atan2(lat, math.max(speed, 1)))
		animate(entity, dt, speed, lat / 12)
	end
end

-- A stampede animal (or stray) a bigger pet ran into: it's thrown up and away,
-- tumbling, then vanishes in a poof. It leaves the stampede for good.
local flung = {}
local FLING_TIME = 0.9
local function knock(entity, dx)
	if entity.n then
		taken[entity.n] = true
		herd[entity.n] = nil
	else
		table.remove(strays, table.find(strays, entity))
	end
	local side = if dx >= 0 then 1 else -1
	table.insert(flung, {
		entity = entity,
		t = 0,
		vx = side * rng:NextNumber(10, 16),
		vy = rng:NextNumber(22, 28),
		vz = travelDir() * rng:NextNumber(14, 20),
		spin = side * rng:NextNumber(8, 12),
	})
end

local function updateFlung(dt)
	for i = #flung, 1, -1 do
		local f = flung[i]
		local e = f.entity
		f.t += dt
		f.vy -= 60 * dt
		e.x += f.vx * dt
		e.z += f.vz * dt
		e.hop = (e.hop or 0) + f.vy * dt
		e.yaw += f.spin * dt
		place(e, 0)
		if f.t >= FLING_TIME then
			Poof.at(Vector3.new(e.x, math.max(e.hop, 0), e.z))
			table.remove(flung, i)
			retire(e)
		end
	end
end

-- The stampede follows the shared server clock. Only during this player's slow-mo
-- hero leap home does their copy run on the ride's slowed time; as soon as it ends,
-- every animal snaps straight back to where it is on the shared clock.
local function updateHerd(dt, slowed)
	builtThisFrame = 0
	local snapped = false
	if slowed then
		herdClock += dt
	else
		local now = workspace:GetServerTimeNow()
		snapped = math.abs(now - herdClock) > 0.1
		herdClock = now
	end
	local every = Config.HerdSpawnEvery
	local newest = math.floor(herdClock / every)
	local camZ = camera.CFrame.Position.Z
	-- Animals behind the camera aren't moved on screen or animated, which is most
	-- of the cost of an animal (a stampede animal is 20 to 200 blocks). Ones near
	-- the camera always are (at home the camera can swing round any time).
	local camPos, camLook = camera.CFrame.Position, camera.CFrame.LookVector
	local function inView(x, z)
		local dx, dz = x - camPos.X, z - camPos.Z
		return dx * camLook.X - camPos.Y * camLook.Y + dz * camLook.Z > -40 or dx * dx + dz * dz < 80 * 80
	end
	local seen = {}
	for key, left in vfx.frostLeft do
		vfx.frostLeft[key] = if left > dt then left - dt else nil
	end
	for b, stream in streams do
		stream.oldest = math.ceil((herdClock - stream.life) / every)
		for n = stream.oldest, newest do
			local key = n * BIOME_KEYS + b - 1
			if taken[key] then
				continue
			end
			local p = plan(key)
			local age = herdClock - n * every
			local dist, speed = run(herdSpeed(p.kind), math.max(age - START_AFTER, 0))
			if vfx.frostLeft[key] then
				vfx.frostLag[key] = (vfx.frostLag[key] or 0) + speed * vfx.frostSlow * dt
				speed *= 1 - vfx.frostSlow
			end
			local z = stream.spawnZ - dist + (vfx.frostLag[key] or 0)
			local entity = herd[key]
			-- The animal being lassoed runs on past the end until it's caught.
			local lassoed = entity and transfer and transfer.target == entity
			if (z <= stream.endZ and not lassoed) or math.abs(z - camZ) > VIEW then
				continue
			end
			local x = laneX(p.x, z)
			local shown = lassoed or inView(x, z)
			if not entity then
				entity = takeFromPool(key, x, z, p.kind)
				if not entity then
					continue
				end
				herd[key] = entity
				if age < 0.15 and shown then
					Poof.at(Vector3.new(x, 0, z))
				end
			end
			seen[key] = true
			-- Pops in at the start, shrinks into nothing over the last SHRINK studs.
			-- (Rescaling a model is slow: only while it's in view.)
			local shrink = if lassoed then 1 else math.clamp((z - stream.endZ) / SHRINK, 0, 1)
			local scale = 1
			if age < POP_TIME or shrink < 1 then
				entity.popping = true
				entity.hop = if age < POP_TIME then popHop(age) else 0
				scale = (if age < POP_TIME then popScale(age) else 1) * shrink
			elseif entity.popping then
				entity.popping, entity.hop = nil, 0
			end
			if shown then
				entity.animal:setScale(scale)
			end
			-- A nudge from a passing rider fades back out; it never changes the schedule.
			entity.dodge *= math.exp(-1.5 * dt)
			if snapped then
				entity.x = x + entity.dodge -- a snap doesn't swing them sideways
			end
			moveAnimal(entity, math.clamp(x + entity.dodge, -EDGE, EDGE), z, speed, dt, shown)
			vfx.setFrosted(entity, vfx.frostLeft[key] ~= nil)
		end
	end
	for key, entity in herd do
		if not seen[key] then
			herd[key] = nil
			putInPool(entity)
		end
	end
	for key in plans do
		if key // BIOME_KEYS < streams[key % BIOME_KEYS + 1].oldest then
			plans[key], taken[key] = nil, nil
			vfx.frostLag[key], vfx.frostLeft[key] = nil, nil
		end
	end
	for i = #strays, 1, -1 do
		local entity = strays[i]
		local yaw = entity.yaw * math.exp(-3 * dt) -- swings round to face downfield
		local turn = math.clamp((entity.yaw - yaw) / math.max(dt, 1e-3) / 3, -1, 1)
		entity.yaw = yaw
		entity.speed += (entity.cruise - entity.speed) * (1 - math.exp(-2 * dt))
		if entity.frostLeft then
			entity.frostLeft = if entity.frostLeft > dt then entity.frostLeft - dt else nil
		end
		vfx.setFrosted(entity, entity.frostLeft ~= nil)
		local pace = entity.speed * (if entity.frostLeft then 1 - vfx.frostSlow else 1)
		local look = CFrame.Angles(0, yaw, 0).LookVector
		local z = entity.z + look.Z * pace * dt
		-- Shrinks away at the end of the biome it's in, like the stampede.
		local endZ = streamAt(entity.z).endZ
		if z <= endZ then
			table.remove(strays, i)
			retire(entity)
			continue
		end
		local shown = inView(entity.x, z)
		local shrink = math.clamp((z - endZ) / SHRINK, 0, 1)
		entity.popping = if shrink < 1 then true else nil
		if shown then
			entity.animal:setScale(shrink)
		end
		local x = entity.x + look.X * pace * dt
		if math.abs(yaw) > 0.05 then
			entity.lane = x
		end
		-- Swerves round obstacles like the rest of the stampede.
		local lat = math.clamp(laneX(entity.lane, z) - x, -1, 1) * 12
		entity.x, entity.z = math.clamp(x + lat * dt, -EDGE, EDGE), z
		if shown then
			place(entity, -math.atan2(lat, math.max(pace, 1)))
			animate(entity, dt, pace, turn + lat / 12)
		end
	end
	if mount then
		vfx.setFrosted(mount, false) -- lassoed while slowed: your new mount thaws out
	end
end

-- Pet abilities (Config.Abilities): the Ability button, Space (or Q), R1. Each mount keeps
-- its own cooldown (entity.ability); a mount with no entry shows no button. Every
-- ability is one tap: it runs its full Duration.
local abilityKey = false -- Q or R1 pressed since the last frame
local rattleHaze = 0 -- 0..1, eased in and out: the rattle's haze
vfx.RATTLE_HAZE = Color3.fromRGB(255, 170, 40) -- yellow-orange
vfx.FROST_HAZE = Color3.fromRGB(190, 236, 255)
vfx.hazeColor = vfx.RATTLE_HAZE
local abilityClock = 0 -- ride time, slowed with the slow motion like everything else
vfx.ABILITY_RING_TIME = 0.6

ContextActionService:BindActionAtPriority("Ability", function(_, state)
	if state == Enum.UserInputState.Begin and phase ~= "idle" then
		abilityKey = true
	end
	if phase == "idle" then
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.ButtonR1)

-- Whether the ability was asked for since the last frame (a press while it's
-- cooling down is dropped, not saved up).
local function abilityPressed()
	local pressed = Hud.abilityPressed() or abilityKey
	abilityKey = false
	return pressed
end

-- The running ability on the mount, if any: { kind, cfg, t, fx }.
local function activeAbility()
	local a = mount and mount.ability
	return a and a.active
end

-- Charge VFX, from free Creator Store packs: the "Anime/Sharp Wind" beam texture
-- (Wind VFX Pack, asset 88348191251190) and the speed-line shard (Speed Effect/Vfx,
-- asset 16703877340). Only the texture ids are used; the effects are built here.
vfx.WIND_TEXTURE = "rbxassetid://17520182385"
vfx.SHARD_TEXTURE = "rbxassetid://7216979807"
vfx.WIND_SHEETS = 6 -- beams in the cone of air parting round the head

-- Wind breaking round a charging animal's head: a cone of sharp wind sheets
-- sweeping back from its nose, and speed lines streaming past its body.
local function chargeFx(entity)
	local root = entity.animal.model.PrimaryPart
	local middle, size = entity.animal.model:GetBoundingBox()
	local local0 = root.CFrame:ToObjectSpace(middle)
	-- The nose: the front of the box (the model faces -Z), a little above the middle.
	local nose = local0.Position + Vector3.new(0, size.Y * 0.1, -size.Z / 2 - 0.5)
	local radius = math.max(size.X, size.Y) * 0.95
	local length = size.Z * 0.9
	local fx = {}
	for k = 1, vfx.WIND_SHEETS do
		-- Round the cone, missing the underside (the ground).
		local angle = math.rad(-110 + 220 * (k - 1) / (vfx.WIND_SHEETS - 1))
		local out = Vector3.new(math.sin(angle), math.cos(angle), 0) -- radial, 0 = straight up
		local around = Vector3.new(0, 0, -1):Cross(out)
		local a0 = Instance.new("Attachment")
		a0.CFrame = CFrame.fromMatrix(nose, out, around)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.CFrame = CFrame.fromMatrix(nose + out * radius + Vector3.new(0, 0, length), out, around)
		a1.Parent = root
		local beam = Instance.new("Beam")
		beam.Texture = vfx.WIND_TEXTURE
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.TextureLength = 1
		beam.TextureSpeed = 2.2 + 0.3 * (k % 2)
		beam.Width0, beam.Width1 = 0.8, radius * 1.5
		beam.CurveSize0, beam.CurveSize1 = radius * 0.7, 0
		beam.Segments = 16
		beam.LightInfluence = 0
		beam.LightEmission = 0.8
		beam.FaceCamera = false
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.75, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Parent = a0
		table.insert(fx, a0)
		table.insert(fx, a1)
	end
	-- Speed lines streaming back past the whole body.
	local shards = Instance.new("ParticleEmitter")
	shards.Texture = vfx.SHARD_TEXTURE
	shards.Orientation = Enum.ParticleOrientation.VelocityParallel
	shards.EmissionDirection = Enum.NormalId.Back -- the model faces -Z: lines fly backwards
	shards.Shape = Enum.ParticleEmitterShape.Box
	shards.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	shards.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	shards.Speed = NumberRange.new(90, 120)
	shards.Lifetime = NumberRange.new(0.12, 0.2)
	shards.Rate = 70
	shards.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 4), NumberSequenceKeypoint.new(1, 0) })
	shards.Squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, -4), NumberSequenceKeypoint.new(1, -2.2) })
	shards.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	shards.LightEmission = 0.5
	shards.LockedToPart = false
	-- The box: the animal's size, a bit wider, so lines pass all round it.
	local box = Instance.new("Part")
	box.Size = Vector3.new(size.X + 4, size.Y + 2, size.Z)
	box.Transparency = 1
	box.CanCollide, box.CanQuery, box.CanTouch, box.Massless = false, false, false, true
	box.CFrame = middle
	box.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = box, root
	weld.Parent = box
	box.Parent = entity.animal.model
	shards.Parent = box
	table.insert(fx, box)
	return fx
end

-- A ring bursting out from the pet to the ability's radius: sand for the rattle.
local function rattleRing(center, radius, color)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = color or Color3.fromRGB(255, 226, 150)
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.4, 2, 2)
	ring.CFrame = CFrame.new(center.X, 0.3, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = workspace
	local info = TweenInfo.new(vfx.ABILITY_RING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = Vector3.new(0.4, radius * 2, radius * 2), Transparency = 1 }):Play()
	task.delay(vfx.ABILITY_RING_TIME, function()
		ring:Destroy()
	end)
end

-- Rattle: everything standing within the radius is smashed, and the animals
-- there scatter sideways, away from the snake.
local function rattleBlast(dt, cfg)
	for _, o in obstacles do
		if not o.smashed and Vector2.new(o.x - mount.x, o.z - mount.z).Magnitude < cfg.Radius then
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if dx * dx + dz * dz < cfg.Radius * cfg.Radius then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -cfg.Radius, cfg.Radius)
			else
				entity.lane = math.clamp(entity.lane + away * 60 * dt, -EDGE, EDGE)
			end
		end
	end
end

-- Frost: a blizzard bursting out round the Icebringer, then snow swirling round it
-- while it lasts (the returned fx are cleared when it ends).
-- A rainbow streaming out behind a leaping animal while it's in the air: six
-- trails stacked one above another, a band of colour each.
vfx.RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 240),
}
function vfx.rainbowFx(entity)
	local root = entity.animal.model.PrimaryPart
	local middle, size = entity.animal.model:GetBoundingBox()
	local back = root.CFrame:ToObjectSpace(middle * CFrame.new(0, 0, size.Z * 0.3)) -- toward its tail (it faces -Z)
	local band = size.Y * 0.6 / #vfx.RAINBOW
	local parts = {}
	for k, color in vfx.RAINBOW do
		local y = size.Y * 0.3 - (k - 1) * band
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.CFrame = back * CFrame.new(0, y, 0)
		a1.CFrame = back * CFrame.new(0, y - band, 0)
		a0.Parent, a1.Parent = root, root
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(color)
		trail.Lifetime = 1.4
		trail.MinLength = 0.2
		trail.LightEmission = 0.4
		trail.LightInfluence = 0
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 1) })
		trail.Parent = root
		table.insert(parts, trail)
		table.insert(parts, a0)
		table.insert(parts, a1)
	end
	return parts
end

function vfx.frostFx(entity)
	local root = entity.animal.model.PrimaryPart
	local middle, size = entity.animal.model:GetBoundingBox()
	local function flakes(rate, speed, life, sizeMax)
		local e = Instance.new("ParticleEmitter")
		e.Texture = vfx.FLAKE_TEXTURE
		e.Color = ColorSequence.new(Color3.new(1, 1, 1), vfx.FROST_TINT)
		e.LightEmission = 0.7
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, sizeMax), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.6) })
		e.Lifetime = life
		e.Speed = speed
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-180, 180)
		e.Rate = rate
		return e
	end
	-- The burst: thrown out all round, low over the ground.
	local burst = Instance.new("Part")
	burst.Anchored, burst.CanCollide, burst.CanQuery, burst.CanTouch = true, false, false, false
	burst.Transparency = 1
	burst.Size = Vector3.new(1, 1, 1)
	burst.CFrame = CFrame.new(middle.Position.X, 2, middle.Position.Z)
	burst.Parent = workspace
	local blast = flakes(0, NumberRange.new(40, 70), NumberRange.new(0.6, 1.1), 2.4)
	blast.SpreadAngle = Vector2.new(180, 15)
	blast.EmissionDirection = Enum.NormalId.Top
	blast.Drag = 3
	blast.Parent = burst
	blast:Emit(140)
	task.delay(1.5, function()
		burst:Destroy()
	end)
	-- The swirl: snow falling and blowing round the pet for the whole Duration.
	local box = Instance.new("Part")
	box.Size = Vector3.new(size.X + 16, 1, size.Z + 16)
	box.Transparency = 1
	box.CanCollide, box.CanQuery, box.CanTouch, box.Massless = false, false, false, true
	box.CFrame = middle * CFrame.new(0, size.Y / 2 + 4, 0)
	box.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = box, root
	weld.Parent = box
	box.Parent = entity.animal.model
	local swirl = flakes(90, NumberRange.new(4, 9), NumberRange.new(1, 1.6), 1.2)
	swirl.Shape = Enum.ParticleEmitterShape.Box
	swirl.EmissionDirection = Enum.NormalId.Bottom
	swirl.SpreadAngle = Vector2.new(35, 35)
	swirl.Acceleration = Vector3.new(0, -4, 0)
	swirl.Parent = box
	return { box }
end

-- Frost: every animal within the radius (but the pet itself) is slowed until the
-- ability ends; ones that come into range later only for what's left of it.
function vfx.frostBlast(cfg, left)
	vfx.frostSlow = cfg.Slow
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and dx * dx + dz * dz < cfg.Radius * cfg.Radius then
			if entity.n and herd[entity.n] == entity then
				vfx.frostLeft[entity.n] = math.max(vfx.frostLeft[entity.n] or 0, left)
			else
				entity.frostLeft = math.max(entity.frostLeft or 0, left)
			end
		end
	end
end

local function endAbility(entity)
	local a = entity and entity.ability
	local active = a and a.active
	if not active then
		return
	end
	for _, fx in active.fx do
		fx:Destroy()
	end
	local root = entity.animal.model.PrimaryPart
	if active.cfg.Kind == "Leap" then
		entity.hop = 0
		if root then
			Dust.kick(root.CFrame, entity.animal.scale)
		end
	end
	a.active = nil
	a.readyAt = abilityClock + active.cfg.Cooldown
	if entity == mount then
		grace = math.max(grace, 0.4) -- a moment to clear whatever it was going through
	end
end

local function startAbility(cfg)
	local a = mount.ability
	a.active = { kind = cfg.Kind, cfg = cfg, t = 0, fx = {} }
	if cfg.Kind == "Charge" then
		a.active.fx = chargeFx(mount)
		Poof.at(Vector3.new(mount.x, 0, mount.z))
	elseif cfg.Kind == "Leap" then
		Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
		a.active.fx = vfx.rainbowFx(mount)
	elseif cfg.Kind == "Rattle" then
		rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius)
		hold = math.min(hold + holdTime(mount) * (cfg.Restore or 0), holdTime(mount)) -- a breather: the Hold bar refills
	elseif cfg.Kind == "Frost" then
		a.active.fx = vfx.frostFx(mount)
		rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius, vfx.FROST_TINT)
		vfx.frostBlast(cfg, cfg.Duration)
	end
end

-- Every frame while riding: start, run and end the mount's ability, and draw the button.
local abilityMount -- the mount last frame: when it changes (lassoed a new one, thrown off), the old one's ability stops
local function updateAbility(dt)
	abilityClock += dt
	if abilityMount and abilityMount ~= mount then
		endAbility(abilityMount)
	end
	abilityMount = mount
	local cfg = mount and not Tutorial.active and Config.Abilities[mount.kind] -- no abilities in the tutorial
	if not cfg or (phase ~= "outbound" and phase ~= "turning" and phase ~= "return") then
		if mount then
			endAbility(mount)
		end
		abilityKey = false
		Hud.setAbility(nil)
		return
	end
	local a = mount.ability
	if not a then
		a = { readyAt = 0 }
		mount.ability = a
	end
	local pressed = abilityPressed()
	local active = a.active
	if active then
		active.t += dt
		if active.cfg.Kind == "Rattle" then
			rattleBlast(dt, active.cfg)
		elseif active.cfg.Kind == "Frost" then
			vfx.frostBlast(active.cfg, active.cfg.Duration - active.t)
		end
		if active.t >= active.cfg.Duration then
			endAbility(mount)
		end
	elseif pressed and abilityClock >= a.readyAt and (phase == "outbound" or phase == "return") and not transfer then
		startAbility(cfg)
	end
	active = a.active
	if active then
		Hud.setAbility(1 - active.t / active.cfg.Duration, nil)
	else
		local left = math.max(a.readyAt - abilityClock, 0)
		Hud.setAbility(1 - left / cfg.Cooldown, left)
	end
end

local function updateMount(dt)
	local dir = travelDir()
	if phase == "turning" then
		turnT = math.min(turnT + dt / TURN_TIME, 1)
		local eased = 0.5 - math.cos(turnT * math.pi) / 2
		mount.yaw = math.pi * eased
		mount.speed = Config.MountSpeed * statsOf(mount.kind).Speed * (1 - math.sin(turnT * math.pi) * 0.7)
		mount.latVel *= math.exp(-6 * dt)
		local look = CFrame.Angles(0, mount.yaw, 0).LookVector
		mount.x = math.clamp(mount.x + look.X * mount.speed * dt, -EDGE, EDGE)
		mount.z += look.Z * mount.speed * dt
		if turnT >= 1 then
			phase, grace = "return", Config.TurnGrace
			mount.speed = Config.ReturnSpeed * statsOf(mount.kind).Speed
		end
		place(mount, 0)
		animate(mount, dt, mount.speed, eased < 1 and -0.6 or 0)
		return
	end

	if heroLeap then
		-- Slow-motion leap over the start line, landing just past it. Driven by real
		-- time (heroLeap.t) so it lasts HomeHeroTime whatever the slow motion does.
		local t = heroLeap.t
		mount.z = heroLeap.fromZ + (heroLeap.toZ - heroLeap.fromZ) * t
		-- A floaty arc: up fast, hanging near the top, down fast.
		mount.hop = math.sin(math.pi * t) ^ 0.6 * Config.HomeLeapHeight - (heroLeap.drop or 0) * t * t * t
		mount.latVel = 0
		place(mount, 0)
		animate(mount, dt, if t < 1 then mount.speed else 0, 0)
		return
	elseif phase == "finish" then
		-- Over the edge: falling away into the sky (under the egg reveal).
		mount.fall = (mount.fall or 20) + 60 * dt
		mount.hop -= mount.fall * dt
		mount.z -= mount.speed * 0.5 * dt
		place(mount, 0)
		animate(mount, dt, mount.speed, 0)
		return
	elseif phase == "home" then
		-- Landed: runs on HomeRunOut studs, easing to a stop.
		local brake = RUN_OUT_SPEED * RUN_OUT_SPEED / (2 * Config.HomeRunOut)
		mount.speed = math.max(mount.speed - brake * dt, 0)
		mount.z += mount.speed * dt
		place(mount, 0)
		animate(mount, dt, mount.speed, 0)
		return
	end
	local targetSpeed = phase == "home" and 0 or (dir < 0 and Config.MountSpeed or Config.ReturnSpeed) * statsOf(mount.kind).Speed
	if sprinting() then
		targetSpeed *= Config.SprintSpeed
	end
	local rate = phase == "home" and 30 or (dir < 0 and 90 or 40) -- snappy into and out of a sprint
	local ability = activeAbility()
	if ability and ability.cfg.Kind == "Charge" then
		targetSpeed *= ability.cfg.SpeedBoost
	elseif ability and ability.cfg.Kind == "Leap" then
		-- Up into the air and down again in an arc, faster.
		targetSpeed *= ability.cfg.SpeedBoost
		mount.hop = math.sin(math.pi * math.clamp(ability.t / ability.cfg.Duration, 0, 1)) * ability.cfg.LeapHeight
	elseif ability and ability.cfg.Kind == "Rattle" then
		targetSpeed, rate = 0, 120 -- stops dead to coil up
	end
	mount.speed += math.clamp(targetSpeed - mount.speed, -rate * dt, rate * dt)
	if phase == "outbound" and exitX then
		-- Out of a corner pen: sideways through its open side, curving toward the start line.
		local d = exitX - mount.x
		local side = math.clamp(math.abs(d) / EXIT_TURN, 0, 1)
		local lat, fwd = math.sign(d) * side, 1 - side
		local len = math.sqrt(lat * lat + fwd * fwd)
		mount.latVel = mount.speed * lat / len
		local step = mount.latVel * dt
		mount.x = if math.abs(step) >= math.abs(d) then exitX else mount.x + step
		mount.z += dir * mount.speed * fwd / len * dt
		if math.abs(exitX - mount.x) < 0.2 then
			exitX = nil
		end
		place(mount, math.atan2(lat * dir, fwd))
		animate(mount, dt, mount.speed, 0)
		return
	end
	local steer = phase == "home" and 0 or readSteer()
	local targetLat = steer * Config.SteerSpeed * -dir
	-- Leaving the base from an outer pen: lean in so the animal reaches the
	-- corridor by the start line.
	if phase == "outbound" and mount.z > 0 and mount.z < leadFromZ and math.abs(mount.x) > EDGE - 4 then
		local over = math.abs(mount.x) - (EDGE - 4)
		targetLat -= math.sign(mount.x) * over / math.max(mount.z, 4) * math.max(mount.speed, 10)
	end
	mount.latVel += (targetLat - mount.latVel) * (1 - math.exp(-Config.SteerResponse * dt))
	-- At home the side limit widens from the corridor's to the base's over 40 studs,
	-- so a ride from an outer pen is eased into the corridor.
	local edge = EDGE + (Config.HomeHalfWidth - 4 - EDGE) * math.clamp(mount.z / 40, 0, 1)
	mount.x = math.clamp(mount.x + mount.latVel * dt, -edge, edge)
	mount.z += dir * mount.speed * dt
	place(mount, math.atan2(mount.latVel * dir, math.max(mount.speed, 1)))
	animate(mount, dt, mount.speed, mount.latVel * -dir / Config.SteerSpeed)
end

local function reachHome()
	if phase == "return" and mount.z >= START_LINE_Z - LEAP_FROM then
		-- Home with the egg: the hero leap over the line (updateMount), then the reveal.
		phase = "home"
		heroLeap = { t = 0, fromZ = mount.z, toZ = START_LINE_Z + Config.HomeLandPast }
		Hud.setCutscene(true)
	end
end

-- Over the finish line at the end of the course: the same slow-motion leap as
-- coming home, over the line; then a random egg and home (see the landing below).
local function reachFinish()
	if phase == "outbound" and mount.z <= FINISH_Z + LEAP_FROM and not transfer then
		phase = "finish"
		-- Off the end of the course: up over the line and down into the open sky.
		heroLeap = { t = 0, fromZ = mount.z, toZ = FINISH_Z - 26, drop = FINISH_DROP }
		Hud.setCutscene(true)
		Hud.setAction(nil)
		Hud.setHold(nil)
		return true
	end
	return false
end

local function checkRide(dt)
	if phase == "finish" or reachFinish() then
		return -- the leap over the finish line: nothing can go wrong now
	end
	grace = math.max(grace - dt, 0)
	local ability = activeAbility()
	if ability and ability.cfg.Kind == "Frost" then
		ability = nil -- slowing the herd is all it does: it still uses Hold and can still crash
	end
	if phase == "outbound" and mount.z < 0 and not transfer and not ability and not Tutorial.active then -- abilities and the tutorial use no Hold
		hold -= dt * (if sprinting() then Config.SprintDrain else 1)
		if hold <= 0 then
			return fail("BUCKED OFF")
		end
	end
	if mount.z < FINISH_Z - 8 then
		return fail("TOO FAR!") -- only if something skipped the finish line
	end
	if ability and ability.cfg.Kind == "Charge" then
		-- A battering ram: everything in the way goes flying, whatever its size.
		while true do
			local o = blockedAt(mount.x, mount.z, 2.5, 4, 1)
			if not o then
				break
			end
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
		for _, entity in allAnimals() do
			local dx, dz = entity.x - mount.x, entity.z - mount.z
			if not entity.popping and math.abs(dx) < 4 and math.abs(dz) < 6 then
				knock(entity, dx)
			end
		end
	end
	if ability then
		-- Charging, leaping over everything or coiled up rattling: nothing crashes it.
		if phase == "outbound" and mount.z < gateZ() + 2.4 then
			return fail("CRASH!", "Upgrade your pen to go further") -- except a locked gate
		end
		return reachHome()
	end
	-- A bigger pet plows through smaller obstacles; its own size or bigger stops it.
	-- Racing home with the egg, every pet counts as a size bigger against obstacles
	-- (RETURN_TIER_BONUS); against stampede animals it's its own size.
	local tier = tierOf(mount.kind) + (if phase == "return" or phase == "turning" then RETURN_TIER_BONUS else 0)
	while true do
		local o = blockedAt(mount.x, mount.z, 1.3, 2.4)
		if not o or o.tier >= tier then
			break
		end
		smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
	end
	if grace <= 0 and blockedAt(mount.x, mount.z, 1.3, 2.4, tier) then
		return fail("CRASH!")
	end
	if phase == "outbound" and mount.z < gateZ() + 2.4 then
		return fail("CRASH!", "Upgrade your pen to go further") -- a locked gate
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if not entity.popping and math.abs(dx) < 2.6 and math.abs(dz) < 5 then
			if phase == "return" and tierOf(entity.kind) < tierOf(mount.kind) then -- (the +1 is for obstacles only)
				knock(entity, dx)
			elseif phase == "return" and grace <= 0 then
				return fail("CRASH!")
			elseif phase == "outbound" and entity.n then
				entity.dodge = math.clamp(entity.dodge + (if dx >= 0 then 1 else -1) * 12 * dt, -6, 6)
			end
		end
	end
	reachHome()
end

local function updateRider(dt)
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if tumble then
		tumble.t = math.min(tumble.t + dt / 0.7, 1)
		local t = tumble.t
		local from = tumble.from
		local gx, gz = from.X + tumble.side * 9, from.Z - 6 * tumble.dir
		local ground = Vector3.new(gx, LIE_HEIGHT + Ground.heightAt(gx, gz), gz)
		local pos = from:Lerp(ground, t) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
		-- A flip and a quarter backwards, ending face up.
		hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, tumble.yaw, 0)
			* CFrame.Angles(t * math.pi * 2.5, 0, tumble.side * math.sin(t * math.pi) * 0.8)
		focus = focus:Lerp(Vector3.new(pos.X, 0, pos.Z), 1 - math.exp(-4 * dt))
		return
	end
	if transfer and transfer.stage == "throw" then
		-- Still on the old horse while the loop flies out.
		transfer.t = math.min(transfer.t + dt / THROW_TIME, 1)
		hrp.CFrame = transfer.old.animal:getSeatCFrame() * SEAT_OFFSET
		focus = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
		if transfer.t >= 1 then
			transfer.stage, transfer.t, transfer.from = "pull", 0, hrp.Position
		end
		return
	end
	if transfer then
		transfer.t = math.min(transfer.t + dt / TRANSFER_TIME, 1)
		local t = transfer.t
		local seat = transfer.target.animal:getSeatCFrame() * SEAT_OFFSET
		local eased = 1 - (1 - t) * (1 - t)
		local pos = transfer.from:Lerp(seat.Position, eased) + Vector3.new(0, math.sin(t * math.pi) * 5, 0)
		hrp.CFrame = CFrame.new(pos) * seat.Rotation
		focus = Vector3.new(pos.X, 0, pos.Z)
		if t >= 1 then
			local target = transfer.target
			if target.n then
				herd[target.n], taken[target.n], target.n = nil, true, nil
			else
				table.remove(strays, table.find(strays, target))
			end
			mount, transfer = target, nil
			mount.popping, mount.hop = nil, 0
			mount.animal:setScale(1)
			mount.animal:setSaddled(true)
			mount.latVel = 0
			hold, grace = holdTime(mount), Config.LandingGrace
			Tutorial.lassoed()
			if not Tutorial.active then -- no money at all in the tutorial until your pets start earning
				local earned = Config.RarityCoins[mount.animal.Rarity]
				coins += earned
				Hud.setCoins(coins)
				local point = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4, 0))
				Hud.coinPopup(Vector2.new(point.X, point.Y), earned)
			end
		end
		return
	end
	if mount then
		if not humanoid.Sit then
			humanoid.Sit = true
		end
		hrp.CFrame = mount.animal:getSeatCFrame() * SEAT_OFFSET
		if phase ~= "finish" or heroLeap then -- falling off the end: the camera stays at the edge
			focus = Vector3.new(mount.x, math.max(mount.hop or 0, 0) * 0.85, mount.z) -- the camera rises with a leap, keeping the pet in view
		end
	end
	if carried then
		if carried.stage == "throw" then
			-- Sits in the nest while the loop flies out.
			carried.t = math.min(carried.t + dt / THROW_TIME, 1)
			if carried.t >= 1 then
				carried.stage, carried.t, carried.from = "pull", 0, carried.part:GetPivot().Position
				if cutscene then
					cutscene.shake = 0.25 -- the loop cinches: a jolt
				end
			end
		elseif carried.stage == "pull" then
			-- Reeled in on an arc, hanging off the rope: it tips toward the rider
			-- and swings and spins, settling into the overhead twirl.
			carried.t = math.min(carried.t + dt / EGG_PULL_TIME, 1)
			local t = carried.t
			local eased = 1 - (1 - t) ^ 2
			local held = Lasso.heldCFrame()
			local pos = carried.from:Lerp(held.Position, eased) + Vector3.new(0, math.sin(t * math.pi) * 7, 0)
			local towardRider = (hrp.Position - pos).Unit
			local hang = CFrame.lookAt(pos, pos + towardRider) * CFrame.Angles(-math.pi / 2, 0, 0) -- egg's top toward the rope
			local settle = 1 - t
			local wobble = CFrame.Angles(math.sin(t * math.pi * 5) * 0.7 * settle, t * math.pi * 3 * carried.spin, math.cos(t * math.pi * 4) * 0.5 * settle)
			carried.part:PivotTo(hang:Lerp(CFrame.new(pos) * held.Rotation, t * t) * wobble)
			if t >= 1 then
				carried.stage = "held" -- swung round overhead from here (Lasso.twirl)
				-- Zoom back out into DODGE THE STAMPEDE mode.
				cutscene = nil
				Hud.setCutscene(false)
				Hud.setReturning(true)
			end
		end
	end
end

local function updateHud()
	-- The tutorial shows only LASSO / TAKE EGG: no Sprint and no Hold bar (it never runs out).
	Hud.setSprint(phase == "outbound" and not Tutorial.active)
	if phase == "outbound" then
		Hud.setHold(if Tutorial.active then nil elseif mount then hold / holdTime(mount) else 1)
		Hud.setDistance(if Tutorial.active then "" else string.format("%d m", math.max(0, math.floor(-focus.Z / STUDS_PER_METRE))))
		if actionTarget == "egg" then
			Hud.setAction("GRAB EGG", true, rarityOf(nearEgg.kind))
		else
			Hud.setAction("LASSO", actionTarget ~= nil)
		end
	end
	if phase == "turning" or phase == "return" or phase == "home" then
		local metres = math.max(0, -focus.Z / STUDS_PER_METRE)
		Hud.setVignette(math.clamp(metres / Config.VignetteFadeMetres, 0, 1))
	end
end

-- Slow motion during the egg-grab close-up and the hero leap home.
local timeScale = 1

RunService.PreSimulation:Connect(function(dt)
	Tutorial.update({
		phase = phase,
		target = actionTarget,
		pet = starter and starter.animal.model,
		transfer = transfer ~= nil,
		cutscene = cutscene ~= nil or heroLeap ~= nil,
	})
	-- The tutorial slows time while LASSO or TAKE EGG waits for its first press.
	local slow = cutscene ~= nil or heroLeap ~= nil or Tutorial.slowMo ~= nil
	local slowTo = if heroLeap then Config.HomeSlowMo elseif cutscene then Config.EggSlowMo else Tutorial.slowMo
	timeScale += ((slow and slowTo or 1) - timeScale) * (1 - math.exp(-10 * dt))
	if heroLeap then
		heroLeap.t = math.min(heroLeap.t + dt / Config.HomeHeroTime, 1)
	end
	dt *= timeScale
	-- The waiting eggs twitch now and then: something's alive in there.
	for _, waiting in waitingEggs do
		if waiting.egg.model.Parent then
			waiting.nextTwitch -= dt
			if waiting.nextTwitch <= 0 then
				waiting.egg:play("twitch")
				waiting.nextTwitch = rng:NextNumber(EGG_TWITCH_EVERY[1], EGG_TWITCH_EVERY[2])
			end
			waiting.egg:update(dt)
		end
	end
	-- In the tutorial the stampede runs on your own clock, so it's never snapped
	-- back to everyone else's after slowing down.
	updateHerd(dt, (slow and not cutscene) or Tutorial.active)
	updateFlung(dt)
	Dust.update(dt)
	if phase == "idle" then
		updateGuide() -- (hides it)
		-- On foot on the course, a stampede animal running you down throws you
		-- like being bucked off (no cash on the fail screen: there was no ride).
		local hrp, humanoid = character()
		if hrp and humanoid.Health > 0 and hrp.Position.Z < START_LINE_Z + 2 then
			for _, entity in allAnimals() do
				if not entity.popping and math.abs(entity.x - hrp.Position.X) < 2.6 and math.abs(entity.z - hrp.Position.Z) < 4 then
					clearRideTarget()
					humanoid:UnequipTools()
					phase, camYaw, focus = "outbound", 0, Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
					hrp.Anchored = true
					controls:Disable()
					Hud.show(true)
					Hud.setCash(nil)
					fail("BUCKED OFF")
					return
				end
			end
		end
		if starter then
			wander(starter, dt)
		end
		updateRideTarget()
		Outline.set(if rideShown or pickedPet then rideModel else nil) -- the pet RIDE will ride
		Outline.update()
		return
	end
	updateAbility(dt)
	updateGuide()
	if mount then
		updateMount(dt)
	end
	updateRider(dt)
	if carried and carried.stage == "held" then
		Lasso.twirl(dt, carried.part)
	elseif carried then
		local egg = { cframe = carried.part:GetPivot(), radius = Lasso.fitRadius(carried.part) }
		if carried.stage == "throw" then
			Lasso.throw(carried.t, egg)
		else
			Lasso.pull(carried.t, egg)
		end
	elseif transfer then
		local neck = transfer.target.animal:getNeck()
		if transfer.stage == "throw" then
			Lasso.throw(transfer.t, neck)
		else
			Lasso.pull(transfer.t, neck)
		end
	elseif mount and (phase == "outbound" or phase == "return") then
		Lasso.swing(dt)
	else
		Lasso.hide()
	end
	if mount and phase ~= "ended" then
		checkRide(dt)
	end
	if heroLeap and heroLeap.t >= 1 then
		-- Landed: dust, then the egg reveal, then off the pet.
		heroLeap = nil
		mount.speed = RUN_OUT_SPEED
		if phase ~= "finish" then
			mount.hop = 0
			place(mount, 0)
			Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
		end
		Hud.setCutscene(false)
		if phase == "finish" then
			-- Crossed the finish line: a random egg (the server draws it), its
			-- reveal, then back home to your pen.
			task.spawn(function()
				local ok, kind = pcall(finishCourse.InvokeServer, finishCourse)
				kind = ok and kind or nil
				task.wait(kind and Hud.eggReveal(rarityOf(kind), kind) or 0.5)
				if phase == "finish" then
					local pen = myPen()
					local spawn = pen and pen:FindFirstChild("Spawn")
					local spot = if spawn then spawn.Position else homeSpot()
					finishRide(spot.X - 6, spot.Z) -- just outside your pen's open side
				end
			end)
		else
			local kind = carried and carried.kind
			if kind then
				deliverEgg:FireServer(kind) -- into your egg inventory, to place in your pen
			end
			task.delay(kind and Hud.eggReveal(rarityOf(kind), kind) or 0.5, function()
				if phase == "home" then
					finishRide(mount.x, mount.z)
				end
			end)
		end
	end
	actionTarget = findTarget()
	Outline.set(if actionTarget == "egg" then nearEgg.egg.model elseif actionTarget then actionTarget.animal.model else nil)
	Outline.update()
	updateHud()
end)

RunService:BindToRenderStep("RideCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if phase == "idle" then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local targetYaw = mount and mount.yaw or camYaw
	camYaw += (targetYaw - camYaw) * (1 - math.exp(-5 * dt))
	local hrp = character()
	if cutscene and carried and hrp then
		-- Close-up on the egg from the rider's side, slightly off to one side,
		-- snapping in fast and punching the field of view in.
		local egg = carried.part:GetPivot().Position
		local back = (hrp.Position - egg) * Vector3.new(1, 0, 1)
		back = if back.Magnitude > 0.1 then back.Unit else Vector3.zAxis
		local side = back:Cross(Vector3.yAxis)
		local desired = CFrame.lookAt(egg + back * 11 + side * 4 + Vector3.new(0, 5, 0), egg + Vector3.new(0, 1, 0))
		cutscene.shake = math.max(cutscene.shake - dt, 0)
		local jolt = cutscene.shake * 2
		desired *= CFrame.new(rng:NextNumber(-jolt, jolt), rng:NextNumber(-jolt, jolt), 0)
		camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-14 * dt))
		camera.FieldOfView += (50 - camera.FieldOfView) * (1 - math.exp(-14 * dt))
		return
	end
	local basis = CFrame.new(focus) * CFrame.Angles(0, camYaw, 0)
	if heroLeap and hrp then
		-- Hero shot: the camera swings round from its usual spot behind and above to
		-- low in front and off to the side of the leaping rider, and back as they land.
		local a = math.sin(math.pi * heroLeap.t) -- 0 -> 1 -> 0
		a = a * a * (3 - 2 * a)
		local rider = hrp.Position
		local behind = -basis.LookVector
		local around = CFrame.Angles(0, math.rad(150) * a, 0):VectorToWorldSpace(behind)
		local distance = 18 + (15 - 18) * a
		local height = 38 + (Config.HomeHeroCamHeight - 38) * a
		local from = Vector3.new(rider.X, focus.Y, rider.Z) + around * distance + Vector3.new(0, height, 0)
		local lookAt = (basis * CFrame.new(0, 0, -24)).Position:Lerp(rider + Vector3.new(0, 1, 0), math.min(a * 2, 1))
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(from, lookAt), 1 - math.exp(-12 * dt))
		camera.FieldOfView += ((70 - 20 * a) - camera.FieldOfView) * (1 - math.exp(-12 * dt))
		return
	end
	-- Abilities: a yellow-orange haze for the rattle (blue for frost).
	local ability = activeAbility()
	local kind = ability and ability.cfg.Kind
	if kind == "Rattle" or kind == "Frost" then
		vfx.hazeColor = if kind == "Frost" then vfx.FROST_HAZE else vfx.RATTLE_HAZE
	end
	rattleHaze += ((if kind == "Rattle" or kind == "Frost" then 1 else 0) - rattleHaze) * (1 - math.exp(-6 * dt))
	Hud.setAbilityTint(rattleHaze * (if vfx.hazeColor == vfx.FROST_HAZE then 0.6 else 0.85), vfx.hazeColor)
	-- Big pets (the Icebringer, the Snake) fill the view: pull the camera back in
	-- proportion to the pet's height, from 1x for a horse-sized one up to 2.2x.
	if mount and not mount.camZoom then
		local _, size = mount.animal.model:GetBoundingBox()
		mount.camZoom = math.clamp(size.Y / 13, 1, 2.2)
	end
	vfx.camZoom = (vfx.camZoom or 1) + (((mount and mount.camZoom) or 1) - (vfx.camZoom or 1)) * (1 - math.exp(-3 * dt))
	local z = vfx.camZoom
	local desired = CFrame.lookAt((basis * CFrame.new(0, 38 * z, 18 * z)).Position, (basis * CFrame.new(0, 0, -24)).Position)
	camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-8 * dt))
	-- Racing home with the egg: a wider field of view to sell the speed, eased in.
	local fov = if phase == "return" then 70 + Config.ReturnFovKick else 70
	camera.FieldOfView += (fov - camera.FieldOfView) * (1 - math.exp(-3 * dt))
end)

Hud.init(onAction, goHome, rideFromHome)

player.CharacterAdded:Connect(function()
	if phase ~= "idle" then
		cleanup()
		phase = "idle"
		controls:Enable()
		camera.CameraType = Enum.CameraType.Custom
		Hud.show(false)
		spawnStarter()
	end
end)

spawnStarter()

-- The server hands out pens just after joining: move the waiting pet to yours.
-- Picking another pet to ride (in the pen) swaps the waiting one; it's used from
-- the next ride if you're out on one.
for _, name in { "Pen", "RidePet" } do
	player:GetAttributeChangedSignal(name):Connect(function()
		if phase == "idle" and starter then
			starter.animal.model:Destroy()
			starter = nil
			spawnStarter()
		end
	end)
end

-- Fill the pools a few animals per frame, so joining doesn't hitch: each kind up
-- to its poolSizes (at least a couple).
task.spawn(function()
	local built = 0
	local names = {}
	for name in poolSizes do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		for _ = #pools[name] + 1, math.max(2, math.ceil(poolSizes[name]) + 1) do
			putInPool(newEntity(0, 0, 0, name))
			built += 1
			if built % 4 == 0 then
				task.wait()
			end
		end
	end
	print(string.format("[Herd] pool filled: %d animals built", built))
end)
