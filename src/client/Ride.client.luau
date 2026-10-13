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

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end
-- The egg you bring home is the animal you're riding when your time runs out
-- (QM, Oct 8: no nests): TakeEgg tells the server which (Nests.server).
local takeEgg = ReplicatedStorage:WaitForChild("TakeEgg")
local bankCoins = ReplicatedStorage:WaitForChild("BankCoins")
local deliverEgg = ReplicatedStorage:WaitForChild("DeliverEgg")
local finishCourse = ReplicatedStorage:WaitForChild("FinishCourse")
local ridePet = ReplicatedStorage:WaitForChild("RidePet")

local function rarityOf(kind)
	return require(Animals[kind]).Rarity
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

local function tierOf(kind)
	return Config.PetTiers[kind] or 1
end

local vfx = {} -- ability VFX bits and state (one table: this chunk is at Luau's 200-local limit)
vfx.tutorialRide = require(script.Parent.TutorialRide) -- (the tutorial's first ride: Client/Tutorial steers it)
vfx.speedLines = require(script.Parent.SpeedLines) -- speed lines on the screen while sprinting (QM, Oct 9 / 11)
vfx.bossChase = require(script.Parent.BossChase) -- the boss when the timer's out (QM, Oct 10)
vfx.lassoPrompt = require(script.Parent.LassoPrompt) -- the prompt on what you'd lasso (QM, Oct 10)
vfx.shoulderCam = require(script.Parent.ShoulderCam) -- the run home's camera (QM, Oct 10)
vfx.newAnimal = require(script.Parent.NewAnimal) -- the animal you got, shown (QM, Oct 13)
vfx.skyFlash = require(script.Parent.SkyFlash) -- white on a sprint tier-up (QM, Oct 9)
vfx.sprintCam = require(script.Parent.SprintCam) -- wider and closer while sprinting (QM, Oct 9)
vfx.sprintTrail = require(script.Parent.SprintTrail) -- a white trail behind your mount while it sprints (QM, Oct 9)
vfx.returnVignette = require(script.Parent.ReturnVignette) -- the run home's pulsing red edges (QM, Oct 9)
vfx.homeBiome = {} -- [kind] = the index of the first biome whose herd lists it (the Horse: the Meadow)
for b, biome in Config.Biomes do
	for kind in biome.Herd or {} do
		vfx.homeBiome[kind] = vfx.homeBiome[kind] or b
	end
end
-- Half its body's width and length on the ground (its real box, at the size it is).
function vfx.halfBody(entity)
	local _, size = Outline.box(entity.animal.model)
	return size.X / 2, size.Z / 2
end
-- (declared up here: smash() below already uses it, and was reading a nil global)

-- An obstacle you ride into flies up and away and fades; it's back
-- for the next ride (cleanup). Everyone else sees it too (Riders.server), and
-- on their screens it's back a few seconds later (remote).
local SMASH_TIME = 0.7
local function smash(o, dir, side, remote)
	o.smashed = true
	if not remote then
		vfx.sounds.play("smash", 0.4)
		ReplicatedStorage.RideCue:FireServer("smash", o.x, o.z, dir, side)
	end
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
			o.smashed, o.remoteSmash = nil, nil
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
local EDGE = Config.CourseHalfWidth - 4 -- at the start line: the course widens on from there (a funnel)
-- How far either side of the middle you can go at z, and how many times wider than
-- at the start line the course is there. Herd lanes (plan's x, entity.lane) are in
-- start-line units, spread out by vfx.widen as the course opens up.
function vfx.edge(z)
	return WorldColors.halfWidth(z) - 4
end
function vfx.widen(z)
	return WorldColors.widen(z)
end
-- The stampede runs all the time, whether anyone is riding or not. Each biome has
-- its own stream: its animal n pops in at the biome's start (just behind the start
-- line, or on the line from the biome before) at n * HerdSpawnEvery seconds on the
-- server clock, with its lane, speed and kind drawn from a generator seeded by n,
-- and runs to the biome's end, where it shrinks away. So everyone sees the same
-- stream, and riding never changes it: an animal you lasso just leaves it.
local START_LINE_Z = if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else -2
local SPAWN_Z = START_LINE_Z + 4
local FINISH_Z = if Config.Endless then -math.huge else -Config.CourseLength + Config.FinishFromEnd -- the finish line (World.server puts it there)
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
local BIOME_KEYS = 1024

-- An animal's stats (Config.AnimalStats), 1x for any animal not listed; a hybrid
-- `entity` has the best of its two pets' (Shared/Fusion.stats).
local function statsOf(kind, entity)
	if entity and entity.fuse then
		return vfx.Fusion.stats(kind, entity.fuse, entity.stats)
	end
	local s = Config.AnimalStats[kind] or { Speed = 1, Stamina = 1 }
	local biome = s.BiomeSpeed and entity and entity.z and Config.Biomes[WorldColors.biomeAt(entity.z)]
	local as = biome and Config.AnimalStats[s.BiomeSpeed[biome.Name] or ""] -- (the Fish in the Ocean: QM)
	return if as then { Speed = as.Speed, Stamina = s.Stamina } else s
end

-- A run's hidden speed floor (QM, Oct 12): whatever you lasso onto runs at least the
-- Speed of the pet you left your pen on less Config.RunSpeedLeeway, so a slow animal
-- lassoed for fun doesn't strand you short of your biome (a Penguin's Rhino runs 1.62,
-- not 1.35). 0 for a ride that didn't start on a pet, or before you've reached the Desert
-- (a new player's Horse's Fish keeps its own 0.6).
local runFloor = 0
local function rideSpeed(entity)
	return math.max(statsOf(entity.kind, entity).Speed, runFloor) * Config.rebirthSpeed(player) -- (rebirths: Config.Rebirth)
end

-- How fast a kind runs in the stampede: always exactly this, no variance. z: where (its
-- biome's BiomeSpeed: the Fish in the Ocean).
local herdSpeedOf = require(ReplicatedStorage.Shared.HerdSpeed) -- (past the Clownfish's, a fixed gap behind your sprint: QM)
local function herdSpeed(kind, z)
	return herdSpeedOf(statsOf(kind, z and { z = z }).Speed)
end

-- How long the Hold bar lasts: Config.RideSeconds, whatever you're riding (QM, Oct 10:
-- no more stamina).
local function holdTime(_entity)
	return vfx.tutorialRide.bossSeconds or Config.RideSeconds -- (the tutorial's: a short one, once it's let go)
end
local streams = {}
-- A stream from spawnZ to endZ of the herd's kinds; name labels its line in the Output.
local function newStream(spawnZ, endZ, herd, name)
	local s = {
		spawnZ = spawnZ,
		endZ = endZ,
		kinds = {},
		total = 0,
	}
	s.mid = (spawnZ + endZ) / 2 -- (its biome's speeds: herdSpeed)
	local slowest = math.huge
	for kind in herd do
		slowest = math.min(slowest, herdSpeed(kind, s.mid))
	end
	s.life = START_AFTER + START_EASE + (s.spawnZ - s.endZ) / slowest
	local names = {}
	for kind, weight in herd do
		table.insert(s.kinds, { name = kind, weight = weight })
		table.insert(names, kind .. " " .. weight)
		s.total += weight
	end
	table.sort(s.kinds, function(a, c)
		return a.name < c.name
	end)
	table.sort(names)
	if name then
		-- One line per biome in the Output, to check the stampede matches Config.
		print(string.format("[Herd] %s: spawns at z %.0f, ends at z %.0f: %s", name, s.spawnZ, s.endZ, table.concat(names, ", ")))
	end
	return s
end
do
	local edge = 0
	for b, biome in Config.Biomes do
		local startZ, endZ = edge, edge - biome.Length
		edge = endZ
		assert(biome.Herd, "Config.Biomes[" .. b .. "] (" .. tostring(biome.Name) .. ") has no Herd")
		streams[b] = newStream(
			if b == 1 then SPAWN_Z else startZ - 2,
			if b == #Config.Biomes then (if Config.Endless then Config.Endless.Cut else FINISH_Z) + 2 else endZ + 2, -- the course stops at the finish line
			biome.Herd,
			biome.Name
		)
		streams[b].keep = biome.HerdKeep -- (fewer animals in the Meadow)
		streams[b].every = biome.HerdSpawnEvery or Config.HerdSpawnEvery -- (more in the Ocean: QM, Oct 11)
	end
end

-- Where an animal in biome b (at z) stops: its stream's end.
local function streamAt(z)
	return vfx.endless.streamAt(z) or streams[WorldColors.biomeAt(z)]
end

local rng = Random.new()

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
local warpLevel -- /biome: the biome you were put in, so its gate (and those before) let you through
local transfer, tumble, carried
vfx.Merge = require(ReplicatedStorage.Shared.Merge)
vfx.Fusion = require(ReplicatedStorage.Shared.Fusion)
vfx.Skins = require(ReplicatedStorage.Shared.Skins)
vfx.HerdPacks = require(script.Parent.HerdPacks)
vfx.endless = require(script.Parent.Endless) -- the endless Jurassic: copies past the cut (Config.Endless)
vfx.endless.init({ obstacles = obstacles, slices = slices, streams = streams, newStream = newStream })
vfx.Burrow = require(script.Parent.Burrow) -- the Sandworm's spray and mounds (yours and other riders')
vfx.Studs = require(ReplicatedStorage.Shared.Studs) -- hybrids: the donor's size and colours
-- The stretch of course with stampede loaded round the camera at camZ: VIEW either
-- way. Racing home (+z) the wider field of view (Config.ReturnFovKick) sees to the
-- horizon, so VIEW ahead had animals popping in about 2 s before you reached them in
-- the fast zones (QM, Oct 6): then the same-size window sits mostly ahead, VIEW_BACK
-- behind the camera (nothing behind comes back at you: the stampede runs the other way).
vfx.VIEW_BACK = 80
function vfx.viewWindow(camZ)
	if phase == "return" then
		return camZ - vfx.VIEW_BACK, camZ + 2 * VIEW - vfx.VIEW_BACK
	end
	return camZ - VIEW, camZ + VIEW
end
-- A merged pet (Shared/Merge) rides bigger and faster: its boost starts it off where
-- the Robo Shark's and Loong's growing (vfx.feed) carries on from.
-- Riding an exclusive event's animal (Events.server; its stampede key is negative):
-- every barrier is gone for the rest of that ride (QM). Gate.client hides them on the
-- local "EventRun" attribute.
function vfx.markEventRun(entity)
	if entity and ((entity.n or 0) < 0 or entity.event) then
		vfx.eventRun = true
		player:SetAttribute("EventRun", true)
	end
end
function vfx.endEventRun()
	vfx.eventRun = nil
	player:SetAttribute("EventRun", nil)
end

function vfx.applyMerge(entity)
	local n = entity.merged or 1
	if n > 1 or entity.fuse then
		local size = vfx.Merge.size(entity.kind, n) * vfx.Fusion.scale(entity.kind, entity.fuse, entity.tier)
		entity.feast = { count = 0, size = size, speed = vfx.Merge.speed(entity.kind, n) }
		entity.animal:setScale(size)
	end
end
vfx.sounds = require(script.Parent.Sounds) -- sound effects and music (a field: this chunk is at the local limit)
vfx.rideSync = ReplicatedStorage:WaitForChild("RideSync") -- multiplayer rides (Riders.server)
vfx.rideCue = ReplicatedStorage:WaitForChild("RideCue")
vfx.hazards = require(script.Parent.PetTrails) -- your Sludge's and Soul Horse's sprint trails
vfx.speedFx = require(script.Parent.SpeedFx) -- the speed cap's curve, speed lines and wider view (QM, Oct 7)
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
		local average = window * kind.weight / stream.total / (stream.every * herdSpeed(kind.name, stream.mid))
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
	entity.animal.sprinting = false -- (the Kraken walks again: Horse gallopOnSprint)
	entity.lane = entity.x / vfx.widen(entity.z)
	entity.cruise = herdSpeed(entity.kind, entity.z)
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
	tier = tier or 1
	for _, o in list do
		if not o.smashed and o.tier >= tier and math.abs(o.x - x) < o.hx + padX and math.abs(o.z - z) < o.hz + padZ then
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
		p = vfx.HerdPacks.plan(streams[b], n, b, BIOME_KEYS, EDGE) -- (Raptors in threes: Client/HerdPacks)
		if p.kind == "Unicorn" and player:GetAttribute("Tutorial") then
			p.kind = "Pinto" -- (no Unicorns in the tutorial: it'd carry you past the Desert's gate, QM)
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
	x0 *= vfx.widen(z) -- (lanes are in start-line units)
	local EDGE = vfx.edge(z)
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
	-- Mid-respawn the root part can exist before (or after) the Humanoid: no hrp
	-- without a humanoid, so every "if hrp" check covers both.
	return if humanoid then hrp else nil, humanoid
end

local function cleanup()
	if mount then
		mount.animal.model:Destroy()
	end
	mount, transfer, tumble, warpLevel = nil, nil, nil, nil
	if carried then
		if carried.part then
			carried.part:Destroy()
		end
		carried = nil
	end
	if vfx.revive and vfx.revive.carried and vfx.revive.carried.part then
		vfx.revive.carried.part:Destroy() -- the egg kept for a Continue that wasn't bought
	end
	vfx.revive = nil
	Lasso.stop()
	if vfx.endScare then
		vfx.endScare() -- (the snake's glow goes with the ride)
		vfx.endShield() -- (and the Blue Crab's King Crabs)
	end
	vfx.hunting, vfx.huntTarget = nil, nil -- (a hunt cut short by the ride ending)
	vfx.endEventRun() -- (the barriers are back for the next ride)
	vfx.hazards.clear()
	vfx.nuke = nil
	cutscene = nil
	heroLeap = nil
	Hud.setCutscene(false)
	Outline.set(nil)
	unsmashAll()
end

local startRide
local rideShown = false -- the RIDE button is up: the pet it rides gets the outline
local rideModel -- the pet RIDE rides: always the nearest of yours

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
-- A ride from your pen (the arc base, QM Oct 9) runs out of its gap and straight
-- across the yard to the corridor: these points in turn (Vector2 x, z), nil once
-- it's in the corridor and riding as usual.
local exitPath = nil

-- Out of your pen's gap (to its Spawn, just outside it), then straight to the
-- corridor's mouth, then a few studs on into it, square to the start line.
local function penExitPath()
	local pen = myPen()
	local spawn = pen and pen:FindFirstChild("Spawn")
	if not spawn then
		return nil
	end
	local x = math.clamp(spawn.Position.X * 0.25, -(EDGE - 8), EDGE - 8) -- (a little toward its side of the corridor)
	return { Vector2.new(spawn.Position.X, spawn.Position.Z), Vector2.new(x, 24), Vector2.new(x, 4) }
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
	starter.merged = player:GetAttribute("RideMerged") or 1
	starter.fuse = player:GetAttribute("RideFuse") -- a hybrid (Shared/Fusion): its donor's colours and size
	starter.tier = player:GetAttribute("RideTier") -- (its saved size tier: Fusion.tier)
	local stats = player:GetAttribute("RideStats") -- (and the best of both pets' Speed, Stamina)
	starter.stats = stats and { Speed = stats.X, Stamina = stats.Y }
	vfx.Fusion.paint(starter.animal.model, starter.kind, starter.fuse)
	vfx.Skins.apply(starter.animal.model, player:GetAttribute("Rebirths")) -- (your rebirth's skin)
	PenPets.starter = starter -- (FuseMenu: the one you ride can be fused too)
	starter.animal:setScale(vfx.Merge.size(starter.kind, starter.merged) * vfx.Fusion.scale(starter.kind, starter.fuse, starter.tier)) -- a merged pet is bigger
	setClickable(starter.animal.model, true)
	-- Just merged (PenPets.merges): it pops out up over the pen once the pets going
	-- into it have been pulled up there, and drops down (vfx.dropStarter).
	local merge = (starter.merged > 1 or starter.fuse) and PenPets.mergeFor(vfx.Fusion.key(starter.kind, starter.fuse))
	if merge then
		starter.drop, starter.full = merge, vfx.Merge.size(starter.kind, starter.merged) * vfx.Fusion.scale(starter.kind, starter.fuse, starter.tier)
		starter.x, starter.z = merge.at.X, merge.at.Z
		starter.dropParent = starter.animal.model.Parent or workspace
		starter.animal.model.Parent = nil
	end
end
player:GetAttributeChangedSignal("Rebirths"):Connect(function() -- (loaded after the starter was drawn)
	if starter then
		vfx.Skins.apply(starter.animal.model, player:GetAttribute("Rebirths"))
	end
end)

-- One prompt, kept on whichever pet you'd ride: Roblox's own "Hold E to Ride"
-- (QM, Oct 9: in place of the RIDE button; a controller's button and a tap on
-- phones come with it). It's this client's alone, so only you see it on your pet.
-- Whether you're near enough is still measured here (updateRideTarget). It lives
-- in Terrain and follows the pet each frame, so it isn't destroyed along with a
-- pet's model.
local rideSpot = Instance.new("Attachment")
local rideOffset = CFrame.identity -- rideSpot relative to the pet's root
local rideSize = Vector3.one -- the pet's bounding box
local RIDE_REACH = 5 -- studs from the pet's outline where RIDE shows
rideSpot.Name = "RideSpot"
local ridePrompt = Instance.new("ProximityPrompt")
ridePrompt.ActionText = "Ride"
ridePrompt.RequiresLineOfSight = false
ridePrompt.MaxActivationDistance = RIDE_REACH
ridePrompt.Style = Enum.ProximityPromptStyle.Custom -- (Roblox's look without its panel: PromptUi)
ridePrompt.KeyboardKeyCode = Enum.KeyCode.E
ridePrompt.HoldDuration = 0.5
ridePrompt.Parent = rideSpot

-- Your pets at home: the starter's model and every pet in your pen.
local function homePets()
	local list = {}
	-- (Not while a just-merged or fused starter waits unparented to drop: its joints
	-- don't hold out of the world, so its parts sit back at the origin and its
	-- measured box, and RIDE's ring round it, came out giant.)
	if starter and starter.animal.model.Parent then
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
-- Config.PetIncome as "+N$" over its head, like the coins for switching rides,
-- except the ones near you showing their nameplate (PenPets.plated: PetPlates.client).
ReplicatedStorage:WaitForChild("PetIncome").OnClientEvent:Connect(function()
	if phase ~= "idle" or not Config.PetPopups then -- (Config.PetPopups off: none, QM Oct 9)
		return
	end
	for _, model in homePets() do
		local isStarter = starter and model == starter.animal.model
		local kind = if isStarter
			then player:GetAttribute("RidePet") or Config.DefaultPet
			else PenPets.pets[model] and PenPets.pets[model].kind
		-- (a merged pet earns for every pet it's made of: Shared/Merge)
		local merged = if isStarter then starter.merged or 1 else PenPets.pets[model] and PenPets.pets[model].merged or 1
		local earned = kind and Config.PetIncome[kind] and Config.PetIncome[kind] * merged
		local income = if isStarter then player:GetAttribute("RideIncome") else PenPets.pets[model] and PenPets.pets[model].income
		earned = income or earned -- (a hybrid earns what both its pets did: Shared/Fusion)
		if earned and earned > 0 and model.PrimaryPart and not PenPets.plated[model] then
			local box, size = Outline.box(model)
			Hud.coinPopupAt(model.PrimaryPart, box.Y + size.Y / 2 + 1, earned)
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
	-- frame at home: one well out of reach is measured from its root instead, and
	-- the rest use the box measured once (Outline.box).
	local root = model.PrimaryPart
	if not root then
		return math.huge, math.huge
	end
	local far = Vector2.new(root.Position.X - at.X, root.Position.Z - at.Z).Magnitude
	if far > 100 then
		return far - 50, far
	end
	local box, size = Outline.box(model)
	local middle = root.CFrame:PointToWorldSpace(box.Position)
	local d = Vector2.new(middle.X - at.X, middle.Z - at.Z).Magnitude
	return d - math.max(size.X, size.Z) / 2, d
end

-- Every frame at home: bind RIDE to the nearest pet, measured to the middle of its
-- body so a small pet you stand on beats a huge one nearby (your pets, or a
-- stampede animal just in at the start line).
local function updateRideTarget()
	local hrp = character()
	local target
	-- Holding an egg, the egg comes first: no RIDE (a click places it).
	local holdingEgg = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if hrp and not holdingEgg then
		local pets = homePets()
		for model in rideableHerd() do
			table.insert(pets, model)
		end
		-- The nearest one (QM: no clicking a pet to pick it any more), but of those in
		-- reach, the fastest (QM, Oct 11).
		local best, fastest = math.huge, -1
		for _, model in pets do
			local edge, d = petDistance(model, hrp.Position) -- from the middle of its body, not its outline (QM)
			local info = if starter and model == starter.animal.model then starter else PenPets.pets[model] or herdRideable[model]
			if edge <= RIDE_REACH and model.PrimaryPart then -- (in reach of its outline itself, as the prompt: below)
				local offset, size = Outline.box(model)
				local at = (model.PrimaryPart.CFrame * offset):PointToObjectSpace(hrp.Position)
				edge = Vector2.new(math.max(math.abs(at.X) - size.X / 2, 0), math.max(math.abs(at.Z) - size.Z / 2, 0)).Magnitude
			end
			local speed = if edge <= RIDE_REACH and info and info.kind then statsOf(info.kind, info).Speed else -1
			if speed > fastest or (speed == fastest and d < best) then
				target, best, fastest = model, d, speed
			end
		end
	end
	if target ~= rideModel then
		rideModel = target
		if target then
			rideOffset, rideSize = Outline.box(target)
			-- The prompt's name line: the pet's name, a hybrid's fused one (as its plate).
			local info = if starter and target == starter.animal.model then starter else PenPets.pets[target]
			ridePrompt:SetAttribute("ObjectColor", info and info.kind and Config.RarityColors[vfx.Fusion.rarity(info.kind, info.fuse)]) -- (the name in its rarity's colour: PromptUi, QM)
			ridePrompt.ObjectText = if info and info.kind then vfx.Fusion.name(info.kind, info.fuse) else ""
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
	local near = rideModel ~= nil and hrp ~= nil and (rideSpot.WorldPosition - hrp.Position).Magnitude <= RIDE_REACH and not Hud.inLesson() -- (no riding in the fuse lesson)
	if near ~= rideShown then
		rideShown = near -- (no RIDE button any more: the prompt's the way to ride)
		player:SetAttribute("RidePromptUp", near) -- (Client/Tutorial's arrow goes)
	end
	ridePrompt.Enabled = not Hud.inLesson() and not player:GetAttribute("EggPromptUp") -- (not over an egg's prompt: Pen.client, QM)
end

local function clearRideTarget()
	rideModel = nil
	rideSpot.Parent = nil
	rideShown = false -- (Hud.show hides the button itself)
end

local function rideFromHome()
	if phase == "idle" and rideModel and rideShown then
		startRide(rideModel)
	end
end
ridePrompt.Triggered:Connect(rideFromHome)

-- Rides `model`: the starter, or a pet from your pen, which swaps places with the
-- starter (the server makes it the one you ride, and the starter joins the pen).
-- `at`: set off from there instead of home.
startRide = function(model, at)
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if not starter then
		spawnStarter()
	end
	humanoid:UnequipTools() -- put any egg away
	local spot = at or homeSpot()
	local fromPen = model and PenPets.pets[model]
	local fromHerd = model and herdRideable[model]
	clearRideTarget()
	if fromHerd then
		-- Jumped onto a stampede animal: it leaves the stampede and runs on with
		-- you from where it is. Your own pet stays home.
		vfx.rideCue:FireServer("take", fromHerd.n)
		vfx.markEventRun(fromHerd)
		if fromHerd.n then -- (nil: a Meadow animal for walking over the start line, below)
			herd[fromHerd.n], taken[fromHerd.n], fromHerd.n = nil, true, nil
		end
		mount = fromHerd
		mount.popping, mount.hop, mount.dodge, mount.merged, mount.fuse, mount.tier = nil, 0, 0, nil, nil, nil
		mount.swerve, mount.swerveTo, mount.swerveV, mount.swerveSide = 0, 0, 0, nil
		mount.animal:setScale(1)
		spot = Vector3.new(mount.x, 0, mount.z)
	elseif fromPen then
		ridePet:FireServer(fromPen.id)
		if starter then
			starter.animal.model:Destroy()
			starter = nil
		end
		mount = newEntity(spot.X, spot.Z, 0, fromPen.kind)
		mount.merged, mount.fuse, mount.stats, mount.tier = fromPen.merged, fromPen.fuse, fromPen.stats, fromPen.tier
		vfx.Fusion.paint(mount.animal.model, mount.kind, mount.fuse)
		mount.own = true -- your own pet: no egg for bringing it home (it stays yours once let go and lassoed back)
	else
		mount, starter = starter, nil
		mount.own = true
		setClickable(mount.animal.model, false)
	end
	if not fromHerd then
		vfx.rideCue:FireServer("out") -- your pet's left your pen: others stop drawing it there (Riders.server, Pen.client)
		vfx.syncing = true -- (so "end" follows, however soon the ride ends)
	end
	mount.animal:setSaddled(true)
	runFloor = if fromHerd or (player:GetAttribute("GatesBroken") or 1) < 2 then 0 else statsOf(mount.kind, mount).Speed - (Config.RunSpeedLeeway or math.huge) -- (none till you've reached the Desert)
	vfx.rideAgain = nil
	leadFromZ = spot.Z - 8
	exitPath = if fromHerd or at then nil else penExitPath()
	vfx.exitTrack, vfx.exitLat, vfx.exitRoute = nil, nil, nil
	local runningAt = if fromHerd then fromHerd.speed or 0 else 0 -- a stampede animal keeps its pace
	mount.x, mount.z, mount.yaw, mount.speed, mount.latVel = spot.X, spot.Z, if exitPath then penYaw() else 0, runningAt, 0 -- (out of your pen: facing out of its gap)
	mount.feast = nil -- (the Blue Crab starts every ride at its own size)
	vfx.applyMerge(mount)
	phase, hold, grace, camYaw = "outbound", holdTime(mount), 0, 0
	vfx.startNuke()
	coins = 0
	hrp.Anchored = true
	humanoid.Sit = true
	controls:Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	focus = Vector3.new(mount.x, 0, mount.z)
	Hud.show(true)
	Hud.setDistance("")
	Lasso.start(player.Character, nil, player:GetAttribute("PenLevel") or 1) -- (your pen level's lasso: LassoTiers)
end

-- Walking over the start line on foot (WalkLimit.client): you're on your fastest pet
-- there and then (QM, Oct 12), else (none yet) a random Meadow animal (QM, Oct 6).
require(script.Parent.StartLine).ride = function(x, z)
	if phase ~= "idle" then
		return false
	end
	local best, fastest = nil, -1
	for _, model in homePets() do
		local info = if starter and model == starter.animal.model then starter else PenPets.pets[model]
		local speed = info and statsOf(info.kind, info).Speed or -1
		if speed > fastest then
			best, fastest = model, speed
		end
	end
	if best then
		startRide(best, Vector3.new(x, 0, z))
		return phase == "outbound"
	end
	local kinds = {}
	for kind, weight in Config.Biomes[1].Herd do
		if weight > 0 and Animals:FindFirstChild(kind) then
			table.insert(kinds, kind)
		end
	end
	if #kinds == 0 then
		return false
	end
	table.sort(kinds) -- (pairs order isn't random)
	local entity = newEntity(x, z, 0, kinds[math.random(#kinds)])
	herdRideable[entity.animal.model] = entity
	startRide(entity.animal.model)
	return phase == "outbound"
end

-- Testing (/biome, see Hatchery.server): drops you just inside biome b's start
-- line riding a new `kind`, whatever you were doing. Your own pet stays home.
-- /boss: at its end instead, with the timer at 0.01 s, so the boss comes (QM, Oct 10).
ReplicatedStorage:WaitForChild("BiomeWarp").OnClientEvent:Connect(function(b, kind, boss)
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if phase ~= "idle" then
		cleanup()
		Hud.showHome(false)
		Hud.show(false) -- clears a fail screen's banner
	end
	humanoid:UnequipTools()
	clearRideTarget()
	local z = if boss then WorldColors.biomeStart(b) - Config.Biomes[b].Length + Config.FinishFromEnd + 60 -- (short of the finish line, on the last)
		elseif b == 1 then SPAWN_Z - 6 else WorldColors.biomeStart(b) - 10 -- the meadow's starts at the start line
	mount = newEntity(0, z, 0, kind)
	mount.animal:setSaddled(true)
	warpLevel = b
	leadFromZ, exitPath = z - 8, nil
	phase, hold, grace, camYaw = "outbound", if boss then 0.01 else holdTime(mount), 1, 0
	coins = 0
	hrp.Anchored = true
	humanoid.Sit = true
	humanoid.PlatformStand = false
	controls:Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	focus = Vector3.new(mount.x, 0, mount.z)
	Hud.show(true)
	Hud.setDistance("")
	Lasso.start(player.Character, nil, player:GetAttribute("PenLevel") or 1) -- (your pen level's lasso: LassoTiers)
end)

-- Back on foot at home: however the ride ended (egg home, Home from the fail screen,
-- the finish line), just outside your pen's open side, facing in (QM, Oct 6: no
-- walking back). x, z only if you have no pen.
local function finishRide(x, z)
	local hrp, humanoid = character()
	if hrp then
		hrp.Anchored = false
		humanoid.Sit = false
		humanoid.PlatformStand = false
		local pen = myPen()
		local spawn = pen and pen:FindFirstChild("Spawn")
		if spawn and pen:FindFirstChild("Area") then
			local at = Vector3.new(spawn.Position.X, 4, spawn.Position.Z)
			hrp.CFrame = CFrame.lookAt(at, Vector3.new(pen.Area.Position.X, 4, pen.Area.Position.Z))
		else
			hrp.CFrame = CFrame.new(x + 6, 4, z)
		end
	end
	cleanup()
	if coins > 0 then
		bankCoins:FireServer(coins) -- this ride's cash goes into the account's gold
		coins = 0
	end
	phase = "idle"
	-- (No arrows back to the pen now you're put down at it: vfx.updateHomeGuide stays
	-- off. Set vfx.rideAgain = true here to bring them back.)
	controls:Enable()
	camera.CameraType = Enum.CameraType.Custom
	Hud.show(false)
	if not starter then
		spawnStarter()
	end
end

-- Continue's price band for `metres` from home (Config.ContinueTiers): the furthest passed.
function vfx.continueTier(metres)
	local tier = Config.ContinueTiers[1]
	for _, t in Config.ContinueTiers do
		if metres >= t.From then
			tier = t
		end
	end
	return tier
end

local function fail(reason, tip)
	if phase == "ended" then
		return
	end
	vfx.sounds.play("crash")
	Hud.setTip(tip) -- in place of the "+$N" the fail screen shows
	local hrp, humanoid = character()
	local dir = (phase == "return" or phase == "home") and 1 or -1 -- travelDir() is defined further down
	-- Continue (Config.ContinueTiers): a crash or buck-off on the way out or
	-- back can be bought off, picking up right here on the same kind of animal,
	-- with the egg. Not into a locked gate, and not in the tutorial.
	local gate = WorldColors.gateZ(math.max(player:GetAttribute("PenLevel") or 1, warpLevel or 1))
	vfx.revive = nil
	if mount and (reason == "CRASH!" or reason == "BUCKED OFF") and (phase == "outbound" or phase == "return")
		and not (phase == "outbound" and mount.z < gate + 2.4)
		and (RunService:IsStudio() or vfx.continueTier(-mount.z / STUDS_PER_METRE).ProductId ~= 0) then
		vfx.revive = { kind = mount.kind, x = mount.x, z = mount.z, yaw = mount.yaw, speed = mount.speed, phase = phase, dir = dir }
	end
	phase = "ended"
	cutscene = nil
	Hud.setCutscene(false)
	if mount then
		release(mount)
		mount = nil
	end
	transfer = nil
	if carried then
		if vfx.revive then
			vfx.revive.carried = carried -- put away until Continue or Home
			if carried.part then
				carried.part.Parent = nil
			end
		elseif carried.part then
			carried.part:Destroy()
		end
		carried = nil
	end
	Outline.set(nil)
	-- Thrown off behind the animal, landing flat on their back until they go home.
	if hrp then -- (no character mid-respawn: nothing to throw)
		local look = hrp.CFrame.LookVector
		tumble = { t = 0, from = hrp.Position, yaw = math.atan2(-look.X, -look.Z), dir = dir, side = rng:NextNumber() < 0.5 and -1 or 1 }
		vfx.rideCue:FireServer("crash", tumble.from, tumble.yaw, tumble.dir, tumble.side) -- everyone sees you thrown off
		humanoid.Sit = false
		humanoid.PlatformStand = true -- no animations: lies stiff
	end
	Hud.setAction(nil)
	Hud.setHold(nil)
	Hud.setDistance("")
	Hud.flash(reason)
	task.delay(0.8, function()
		if phase == "ended" then
			Hud.showHome(true)
			Hud.showContinue(if vfx.revive then "ready" else nil)
		end
	end)
	if Config.RideHud == false then
		vfx.revive = nil -- (no riding UI for now, QM Oct 9: no Home or Continue to press, so home you go)
		task.delay(2, function()
			if phase == "ended" and vfx.goHome then
				vfx.goHome()
			end
		end)
	end
end

local function goHome()
	if phase ~= "ended" or (vfx.revive and vfx.revive.asked) then
		return -- (not while the Continue prompt is up)
	end
	Hud.showHome(false)
	local pen = myPen()
	local spawn = pen and pen:FindFirstChild("Spawn")
	local spot = if spawn then spawn.Position else homeSpot()
	finishRide(spot.X - 6, spot.Z) -- just outside your pen's open side
end
vfx.goHome = goHome -- (fail, above, sends you home itself without the riding UI)

local function startTransfer(target)
	local hrp = character()
	local old = mount
	release(old)
	mount = nil
	transfer = { target = target, old = old, t = 0, stage = "throw", from = hrp.Position }
	vfx.tutorialRide.throws += 1
	vfx.rideCue:FireServer("lasso", target.n or false)
	vfx.sounds.play("lasso_throw")
end

-- Out of time (QM, Oct 8; a fixed RideSeconds since Oct 10): you turn round on whatever you're riding and race it
-- home. A wild one's egg goes up on your lasso, and it's yours once you're over the
-- line (Hatchery's DeliverEgg); your own pet brings no egg.
local function turnHome()
	if not mount.own and Animals:FindFirstChild(mount.kind) then
		takeEgg:FireServer(mount.kind) -- (the server checks you got on a wild one: Nests.server)
		carried = { kind = mount.kind, stage = "home" } -- (no egg on the lasso any more: you get the animal itself, QM Oct 13)
	end
	phase, turnT = "turning", 0
	Hud.setAction(nil)
	Hud.setHold(nil)
end

-- The z of the first gate you can't pass yet (your pen's level decides; see Gate.client).
local function gateZ()
	if vfx.eventRun then
		return -math.huge -- riding an event's animal: no barriers this ride (QM)
	end
	return WorldColors.gateZ(math.max(player:GetAttribute("PenLevel") or 1, warpLevel or 1))
end

-- A trail of arrows on the ground: to the Robo Shark's prey while it hunts, and back
-- home to your pen after a ride (vfx.updateHomeGuide).
local guide = {
	AHEAD = 6, -- studs in front of the pet where the trail starts
	MAX_LENGTH = 300, -- studs: the longest the trail is drawn, toward a farther target
	HEIGHT = 1.4, -- studs up: over the raised ground patches
	HOME_CLOSE = 10, -- studs: back home, the arrows to your pen's entrance go once you're this close
}
local arrowTrail = require(script.Parent.ArrowTrail).new() -- (QM's arrows in a row, Oct 12; was a chevron beam)

local function updateGuide()
	local target
	-- From the pet, or the rider while they're pulled across to a lassoed one.
	local at = if mount then Vector3.new(mount.x, 0, mount.z) else focus
	if vfx.huntTarget then
		target = Vector3.new(vfx.huntTarget.x, 0, vfx.huntTarget.z) -- the Robo Shark's prey while it hunts
	elseif player:GetAttribute("LassoGuide") and mount and phase == "outbound" and not transfer then
		-- (the tutorial's: to the nearest animal ahead, till you lasso one: Client/Tutorial;
		-- to the one the lasso prompt's on whenever there is one, QM)
		local best, bestD = actionTarget, if actionTarget then -1 else 260
		for _, e in allAnimals() do
			local d = mount.z - e.z
			if e ~= mount and not e.popping and d > 4 and d < bestD then
				best, bestD = e, d
			end
		end
		target = best and Vector3.new(best.x, 0, best.z)
	end
	vfx.drawGuide(at, target)
end

-- Back on foot after a ride (any ride, however it ended), the same arrows lead from
-- you to your strongest pet at home (QM, Oct 11: the fastest; was your pen's entrance),
-- so you go and ride it next. They go once you're up close to it (for good, till the
-- next ride) or riding.
function vfx.updateHomeGuide()
	local hrp = character()
	local target
	if hrp and hrp.Position.Z > 0 and not cutscene and not player:GetAttribute("Tutorial") and not player:GetAttribute("MergeView") then -- (always, at your base: QM, Oct 11)
		local best, fastest = nil, -1
		for _, model in homePets() do
			local info = if starter and model == starter.animal.model then starter else PenPets.pets[model]
			local speed = info and statsOf(info.kind, info).Speed or 0
			if speed > fastest and model.PrimaryPart then
				best, fastest = model, speed
			end
		end
		local at = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
		local spot = best and best.PrimaryPart.Position * Vector3.new(1, 0, 1)
		if spot and (spot - at).Magnitude > guide.HOME_CLOSE and not (rideShown and rideModel == best) then
			target = spot
		end
	end
	vfx.drawGuide(if target then Vector3.new(hrp.Position.X, 0, hrp.Position.Z) else nil, target)
end

-- Draws the trail of arrows from `at` toward `target`, or hides it (no target).
function vfx.drawGuide(at, target)
	if not target then
		return arrowTrail.draw()
	end
	do
		-- The trail starts a little out from the pet toward the target (guide.AHEAD, or
		-- half way to a target that close), so it always comes straight off the pet,
		-- whether it leads to an egg far ahead or the Robo Shark's prey right beside it.
		local flat = Vector3.new(target.X, 0, target.Z)
		local toward = Vector3.new(flat.X - at.X, 0, flat.Z - at.Z)
		local from = Vector3.new(at.X, 0, at.Z) + (if toward.Magnitude > 0.01 then toward.Unit * math.min(guide.AHEAD, toward.Magnitude / 2) else Vector3.zero)
		local along = (flat - from).Unit
		-- A far target (an event egg thousands of studs off) isn't drawn as one huge beam,
		-- which doesn't render: the trail runs toward it for at most guide.MAX_LENGTH.
		if (flat - from).Magnitude > guide.MAX_LENGTH then
			flat = from + along * guide.MAX_LENGTH
		end
		-- (just above the highest ground: raised patches are a stud up)
		arrowTrail.draw(Vector3.new(from.X, guide.HEIGHT, from.Z), Vector3.new(flat.X, guide.HEIGHT, flat.Z))
	end
end

-- How far off an animal can be lassoed: LassoRange for a Horse's size, and as much
-- further as it's wider than one (QM, Oct 11: big animals from further away).
local function lassoReach(entity)
	local a = entity.animal
	if entity.lassoAt ~= a.scale then -- (measured once, again only if it's rescaled)
		local size = a.model:GetExtentsSize()
		entity.lassoR, entity.lassoAt = math.max(size.X, size.Z) / 2, a.scale
	end
	return Config.LassoRange + math.max(entity.lassoR - Config.LassoRangeFrom, 0) * Config.LassoRangeGain
end

local function animalInRange(entity)
	if entity == mount or entity.popping or entity.z < gateZ() then
		return nil -- no lassoing through a locked gate
	end
	local ahead = mount.z - entity.z
	local dx = entity.x - mount.x
	local dist = math.sqrt(ahead * ahead + dx * dx)
	if ahead > -3 and dist < lassoReach(entity) then
		return dist + math.abs(dx) * 0.5 -- lower is a better default pick
	end
	return nil
end

-- Every animal that can be lassoed right now.
local function candidates()
	local list = {}
	if phase ~= "outbound" or transfer or not mount then
		return list
	end
	for _, entity in allAnimals() do
		if animalInRange(entity) then
			table.insert(list, entity)
		end
	end
	return list
end

local function findTarget()
	if phase ~= "outbound" or transfer or not mount or player:GetAttribute("NoLasso") then -- (NoLasso: Client/Tutorial)
		picked = nil
		return nil
	end
	-- A target the player clicked stays chosen while it's still in range.
	if picked then
		if table.find(allAnimals(), picked) and animalInRange(picked) then
			return picked
		end
		picked = nil
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

-- The in-range animal drawn nearest a click or tap, if it's close
-- enough on screen to count as clicking it.
local PICK_RADIUS = 70 -- pixels
local function candidateAt(screenPos)
	local best, bestScore = nil, math.huge
	for _, c in candidates() do
		local model = c.animal.model
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
	startTransfer(actionTarget)
end
vfx.lassoPrompt.onTap = onAction

-- The phone joystick while riding: the player controls stay on (the rider is
-- anchored, so it only steers, see readSteer) with jumping off, so no jump button.
local rideStick = { on = false }
function rideStick.set(on)
	on = on and UserInputService.TouchEnabled
	local _, humanoid = character()
	if on == rideStick.on then
		return
	end
	rideStick.on = on
	if on then
		controls:Enable()
		if humanoid then
			rideStick.jump = { humanoid.JumpPower, humanoid.JumpHeight }
			humanoid.JumpPower, humanoid.JumpHeight = 0, 0
		end
	else
		if phase ~= "idle" then
			controls:Disable() -- still on the ride (thrown off, cutscene): no walking
		end
		if humanoid and rideStick.jump then
			humanoid.JumpPower, humanoid.JumpHeight = rideStick.jump[1], rideStick.jump[2]
		end
		rideStick.jump = nil
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
	-- On a phone the usual movement joystick stays up while riding (rideStick) and
	-- steers like the arrow keys.
	local stick = if rideStick.on then controls:GetMoveVector().X else 0
	return math.clamp(keys + touchSteer + padSteer + stick, -1, 1)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if phase == "idle" then
		return -- (RIDE always rides the nearest pet: clicking one doesn't pick it)
	end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Clicking or tapping another animal in range targets it instead.
		local hit = candidateAt(Vector2.new(input.Position.X, input.Position.Y))
		if hit and hit ~= actionTarget then
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
	if vfx.hunting or player:GetAttribute("NoSprint") then -- (NoSprint: the tutorial's first seconds, Client/Tutorial)
		return false -- the Robo Shark can't sprint while it hunts (QM)
	end
	if (phase == "return" and Config.ReturnSprint) or (phase == "outbound" and Config.OutboundSprint) then -- (the ride out always a sprint too: QM, Oct 11)
		return true -- racing home with the egg, always
	end
	-- (the joystick pushed far out sprints, QM: a phone's, either the fixed or the
	-- dynamic one (both drive the move vector, rideStick), or a controller's left stick)
	local stickOut = (rideStick.on and controls:GetMoveVector().Magnitude >= Config.TouchSprintAt)
		or (vfx.padPush or 0) >= Config.TouchSprintAt
	return (phase == "outbound" or phase == "return") and (sprintKey or Hud.sprintHeld() or stickOut) -- (the run home too: QM, Oct 10)
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and touchStart[input] then
		touchSteer = math.clamp((input.Position.X - touchStart[input]) / 70, -1, 1)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
		padSteer = math.abs(input.Position.X) > 0.2 and input.Position.X or 0
		vfx.padPush = Vector2.new(input.Position.X, input.Position.Y).Magnitude -- (pushed far out: sprints, as on a phone)
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
	pools[kind] = pools[kind] or {} -- (a kind no stream listed at load: built on the spot)
	local entity = table.remove(pools[kind])
	if not entity then
		if builtThisFrame >= BUILD_PER_FRAME then
			return nil
		end
		builtThisFrame += 1
		entity = newEntity(x, z, 0, kind)
	end
	entity.n, entity.x, entity.z, entity.yaw, entity.dodge = n, x, z, 0, 0
	entity.swerve, entity.swerveTo, entity.swerveV, entity.swerveSide, entity.lat = 0, 0, 0, nil, 0 -- (vfx.updateAvoid; moveAnimal)
	entity.animal.speed, entity.animal.turn = 0, 0 -- a reused animal starts standing, not mid-gallop
	-- Put where it now is at once: one taken out of view isn't moved until it comes
	-- into view, and it stood frozen where it was last used meanwhile (QM, Oct 4: full-size
	-- animals standing at the biome's end, where they'd shrunk away last time).
	place(entity, 0)
	entity.animal.model.Parent = herdFolder
	return entity
end

-- Frost (the Icebringer's ability, Config.Abilities): the stampede animals it has
-- slowed, by key, with the seconds left, and how many studs each has fallen behind
-- its place in the shared stampede (kept: a slowed animal never sprints to catch up).
-- Strays carry their own entity.frostLeft. Only this player's copy slows, like slow-mo.
vfx.frostLeft = {}
vfx.frostLag = {}
vfx.frostSlow = 0 -- the share of its speed a slowed animal loses (the running Frost's Slow)
vfx.FROST_TINT = Color3.fromRGB(150, 220, 255)
vfx.FLAKE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- Frozen while slowed (QM, Oct 4): a see-through block of ice round the whole
-- animal, sized from its box with room to spare so it always fits, with snowflakes
-- drifting off it. It pops on and, when the animal thaws, shrinks down into the
-- ground. (No Highlight: one on each animal it reached hitched on phones.)
-- now: drop it at once, no melt (the animal is going back to the pool).
vfx.ICE_COLOR = Color3.fromRGB(175, 225, 255)
vfx.ICE_TRANSPARENCY = 0.55
vfx.ICE_ROOM = 1.25 -- the block is this much bigger than the animal's box, so animation can't poke out
vfx.ICE_POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
vfx.ICE_MELT = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
function vfx.setFrosted(entity, on, now)
	if on == (entity.frostFx ~= nil) then
		return
	end
	if not on then
		local fx = entity.frostFx
		entity.frostFx = nil
		fx.flakes:Destroy()
		if now or not fx.ice.Parent then
			fx.ice:Destroy()
			return
		end
		-- Melts: shrinks down to a puddle at the animal's feet.
		local size = fx.ice.Size
		TweenService:Create(fx.ice, vfx.ICE_MELT, { Size = Vector3.new(size.X * 0.6, 0.1, size.Z * 0.6), Transparency = 0.8 }):Play()
		TweenService:Create(fx.weld, vfx.ICE_MELT, { C0 = fx.weld.C0 * CFrame.new(0, -size.Y / 2, 0) }):Play()
		task.delay(vfx.ICE_MELT.Time, function()
			fx.ice:Destroy()
		end)
		return
	end
	local model = entity.animal.model
	local root = model.PrimaryPart
	local box, size = Outline.box(model)
	size *= vfx.ICE_ROOM
	local ice = Instance.new("Part")
	ice.Name = "Ice"
	ice.Anchored, ice.CanCollide, ice.CanQuery, ice.CanTouch, ice.Massless = false, false, false, false, true
	ice.CastShadow = false
	ice.Material = Enum.Material.Ice
	ice.Color = vfx.ICE_COLOR
	ice.Transparency = vfx.ICE_TRANSPARENCY
	ice.Size = size * 0.6
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = root, ice
	weld.C0 = CFrame.new(box.Position) -- level with the root (its feet), not tipped with the model's box
	weld.Parent = ice
	ice.CFrame = root.CFrame * weld.C0
	ice.Parent = herdFolder -- not in the model: rescaling or measuring the animal leaves it alone
	TweenService:Create(ice, vfx.ICE_POP, { Size = size }):Play()
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
	flakes.Parent = root
	entity.frostFx = { ice = ice, weld = weld, flakes = flakes }
end

-- Smashed while frozen: the ice bursts into chunks that fly out and fade.
function vfx.shatterIce(entity)
	local fx = entity.frostFx
	if not fx then
		return
	end
	local at, size = fx.ice.CFrame, fx.ice.Size
	vfx.setFrosted(entity, false, true)
	local chunk = math.clamp(math.min(size.X, size.Y, size.Z) * 0.3, 0.6, 4)
	for _ = 1, 10 do
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.CastShadow = false
		p.Material = Enum.Material.Ice
		p.Color = vfx.ICE_COLOR
		p.Transparency = vfx.ICE_TRANSPARENCY
		p.Size = Vector3.one * chunk * rng:NextNumber(0.6, 1.2)
		local out = Vector3.new(rng:NextNumber(-0.5, 0.5) * size.X, rng:NextNumber(-0.3, 0.5) * size.Y, rng:NextNumber(-0.5, 0.5) * size.Z)
		p.CFrame = at * CFrame.new(out)
		p.Parent = herdFolder
		local spin = CFrame.Angles(rng:NextNumber(-3, 3), rng:NextNumber(-3, 3), rng:NextNumber(-3, 3))
		TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = (p.CFrame + (out + Vector3.yAxis * 0.1).Unit * size.Magnitude * 0.6 + Vector3.yAxis * size.Y * 0.3) * spin, Transparency = 1, Size = p.Size * 0.4 }):Play()
		task.delay(0.5, p.Destroy, p)
	end
end

local function putInPool(entity)
	vfx.setFrosted(entity, false, true)
	local active = entity.ability and entity.ability.active
	for _, fx in if active then active.fx else {} do
		fx:Destroy()
	end
	entity.animal.model.Parent = nil
	entity.animal:setScale(1)
	if entity.fuse then -- a hybrid you let go: back to its own colours for the stampede
		vfx.Fusion.paint(entity.animal.model, entity.kind, nil)
		entity.fuse, entity.stats = nil, nil
	end
	entity.hop, entity.popping, entity.lift = 0, nil, nil
	entity.ability, entity.frostLeft, entity.fall, entity.scaredOffBy = nil, nil, nil, nil
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
	local landed = entity.animal:update(dt, speed, turn)
	vfx.Burrow.leaper(entity.animal) -- the Rockworm's dives under the floor
	if landed then
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
				local to = area.CFrame:PointToWorldSpace(Vector3.new(rng:NextNumber(-half.X, half.X), 0, rng:NextNumber(-half.Z, half.Z))) -- (in the pen's frame)
				w.tx, w.tz = to.X, to.Z
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
	-- Faces along its sideways speed, smoothed (~0.1 s) so any frame-to-frame wobble in x
	-- can't twitch its head (QM, Oct 6). Its position isn't smoothed: that's the hitbox.
	local lat = (x - entity.x) / math.max(dt, 1e-3)
	lat = (entity.lat or lat) + (lat - (entity.lat or lat)) * (1 - math.exp(-10 * dt))
	entity.lat = lat
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
local function knock(entity, dx, remote)
	if entity.event then
		return -- an event's animal (vfx.updateEvent) can only be ridden
	end
	if entity.n and not remote then
		vfx.rideCue:FireServer("knock", entity.n, dx)
	end
	vfx.shatterIce(entity)
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

-- Exclusive animal events (Events.server): when the countdown ends, the event's
-- animal pops in at the start line like any stampede animal and runs off with
-- the stampede, on the server clock so everyone sees it in the same place, all
-- the way to the finish line (it doesn't stop at its biome's end). It's in the
-- herd under key -EventId, so riding or lassoing it works as for the rest; it
-- can't be knocked away or crashed into. Built during the countdown, since a big
-- animal is slow to build.
vfx.EVENT_LANE = 0
vfx.EVENT_END = WorldColors.biomeNamedStart(Config.Events.DespawnBiome) or FINISH_Z -- (it runs off at the Jungle's edge: QM, Oct 11)
function vfx.updateEvent(dt, seen, inView)
	local id = world:GetAttribute("EventId") or 0
	local key, kind = -id, world:GetAttribute("EventKind") or ""
	local age = workspace:GetServerTimeNow() - (world:GetAttribute("EventSpawnAt") or math.huge)
	local old = vfx.event
	if old and (old.key ~= key or kind == "" or taken[key] or world:GetAttribute("EventTaken")) then
		-- Over, or someone has it: gone (unless it's someone's mount now).
		vfx.event = nil
		local entity = old.entity
		if entity then
			entity.event = nil -- (as someone's mount, or back in a pool, it's an animal like any other)
			if herd[old.key] == entity then
				herd[old.key] = nil
				Poof.at(Vector3.new(entity.x, 0, entity.z))
				retire(entity)
			elseif not old.shown then
				retire(entity) -- built for the countdown, never shown
			end
		end
	end
	if kind == "" or age < -3 or taken[key] or world:GetAttribute("EventTaken") or not Animals:FindFirstChild(kind) then
		return
	end
	if not vfx.event then
		local entity = newEntity(vfx.EVENT_LANE, SPAWN_Z, 0, kind)
		entity.animal.model.Parent = nil
		entity.n, entity.dodge, entity.event = key, 0, true
		vfx.event = { key = key, entity = entity }
	end
	local event = vfx.event
	local entity = event.entity
	if age < 0 or not entity then
		return -- still counting down, or it already ran off the end
	end
	local dist, speed = run(herdSpeed(kind), math.max(age - START_AFTER, 0))
	local z = SPAWN_Z - dist
	local lassoed = transfer and transfer.target == entity
	if z <= vfx.EVENT_END + 2 and not lassoed then
		-- Ran its course: shrinks away at the Jungle's edge, for good.
		event.entity = nil
		if herd[key] == entity then
			herd[key] = nil
		end
		entity.event = nil
		retire(entity)
		return
	end
	if not herd[key] then
		herd[key], event.shown = entity, true
		entity.x, entity.z = laneX(vfx.EVENT_LANE, z), z
		place(entity, 0) -- (where it is now, even if it's out of view: see takeFromPool)
		if age < 0.15 then
			Poof.at(Vector3.new(entity.x, 0, z))
		end
	end
	seen[key] = true
	local near = math.abs(z - camera.CFrame.Position.Z) <= VIEW or lassoed
	entity.animal.model.Parent = if near then herdFolder else nil
	if entity.frostFx then
		entity.frostFx.ice.Parent = entity.animal.model.Parent -- its ice comes and goes with it
	end
	local x = laneX(vfx.EVENT_LANE, z)
	local shown = near and (lassoed or inView(x, z))
	local shrink = if lassoed then 1 else math.clamp((z - vfx.EVENT_END - 2) / SHRINK, 0, 1)
	local scale = 1
	if age < POP_TIME or shrink < 1 then
		entity.popping = true
		entity.hop = if age < POP_TIME then popHop(age) else 0
		scale = (if age < POP_TIME then popScale(age) else 1) * shrink
	elseif entity.popping then
		entity.popping, entity.hop = nil, 0
	end
	if shown then
		entity.animal:setScale(scale * vfx.ownSize(entity)) -- (grown while you rode it, it stays grown)
	end
	entity.dodge *= math.exp(-1.5 * dt)
	moveAnimal(entity, math.clamp(x + entity.dodge, -vfx.edge(z), vfx.edge(z)), z, speed, dt, shown)
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
	local fromZ, toZ = vfx.viewWindow(camZ)
	vfx.endless.update(camZ)
	-- (the animal you're lassoing is kept however old it gets or far it runs: QM, Oct 8, a
	-- Fish wrestled on into the Desert outlived its stream's schedule and vanished)
	local held = transfer and transfer.target and transfer.target.n
	for b, stream in streams do
		local every = stream.every
		local newest = math.floor(herdClock / every)
		stream.oldest = math.ceil((herdClock - stream.life) / every)
		local first = stream.oldest
		if held and held % BIOME_KEYS == b - 1 then
			first = math.min(first, held // BIOME_KEYS)
		end
		for n = first, newest + vfx.HerdPacks.most - 1 do -- (a pack's followers pop in with it)
			local key = n * BIOME_KEYS + b - 1
			-- (keep: spawn n runs if n x the golden ratio's fraction is under it, the same
			-- on every client and spread evenly, without a pattern to the gaps)
			if taken[key] or (stream.thin and n % stream.thin ~= 0) or (stream.keep and (n * 0.6180339887) % 1 >= stream.keep) then
				continue
			end
			local p = plan(key)
			local age = herdClock - (n - p.lead) * every - p.lag
			if age < 0 then
				continue
			end
			local dist, speed = run(herdSpeed(p.kind, stream.mid), math.max(age - START_AFTER, 0))
			if vfx.frostLeft[key] then
				vfx.frostLag[key] = (vfx.frostLag[key] or 0) + speed * vfx.frostSlow * dt
				speed *= 1 - vfx.frostSlow
			end
			local z = stream.spawnZ - dist + (vfx.frostLag[key] or 0)
			local entity = herd[key]
			-- The animal being lassoed runs on past the end until it's caught.
			local lassoed = entity and transfer and transfer.target == entity
			if (z <= stream.endZ or z < fromZ or z > toZ) and not lassoed then
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
				entity.x = x + entity.dodge + (entity.swerve or 0) -- a snap doesn't swing them sideways
			end
			local ox, oz = vfx.hazards.offset(key) -- (stuck in your Sludge's sludge: falling behind)
			moveAnimal(entity, math.clamp(x + entity.dodge + (entity.swerve or 0) + ox, -vfx.edge(z), vfx.edge(z)), z + oz, speed, dt, shown)
			vfx.setFrosted(entity, vfx.frostLeft[key] ~= nil)
		end
	end
	vfx.updateEvent(dt, seen, inView)
	for key, entity in herd do
		if not seen[key] then
			herd[key] = nil
			putInPool(entity)
		end
	end
	for key in plans do
		local stream = streams[key % BIOME_KEYS + 1]
		if not stream or key // BIOME_KEYS < stream.oldest then
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
			entity.animal:setScale(shrink * vfx.ownSize(entity)) -- (your merged or grown pet stays that size, let go)
		end
		local x = entity.x + look.X * pace * dt
		if math.abs(yaw) > 0.05 then
			entity.lane = x / vfx.widen(z)
		end
		-- Swerves round obstacles like the rest of the stampede.
		local lat = math.clamp(laneX(entity.lane, z) - x, -1, 1) * 12
		entity.x, entity.z = math.clamp(x + lat * dt, -vfx.edge(z), vfx.edge(z)), z
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
vfx.FishWave = require(script.Parent.FishWave) -- the School of Fish's wave
vfx.Missiles = require(script.Parent.Missiles) -- the Robo Shark's missiles
vfx.FROST_HAZE = Color3.fromRGB(190, 236, 255)
vfx.HUNT_HAZE = Color3.fromRGB(230, 10, 10) -- the Robo Shark's hunt
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
-- sweeping back from its nose, and speed lines streaming past its body. scale
-- shrinks it all (the Icebringer's sprint uses 0.35: QM).
-- turn: radians the model is turned from the way it's going (a crab walking sideways,
-- pi / 2): the wind then breaks round its side.
local function chargeFx(entity, scale, turn)
	scale = scale or 1
	local root = entity.animal.model.PrimaryPart
	local middle, full = entity.animal.model:GetBoundingBox()
	local ahead = CFrame.Angles(0, -(turn or 0), 0) -- from the way it's going to the model's own axes
	if turn then
		full = Vector3.new(full.Z, full.Y, full.X) -- going along its width
		middle *= ahead
	end
	local size = full * scale
	local base = CFrame.new(root.CFrame:ToObjectSpace(middle).Position) * ahead
	-- The nose: the front of the box (the model faces -Z), a little above the middle.
	local nose = Vector3.new(0, full.Y * 0.1, -full.Z / 2 - 0.5)
	local radius = math.max(size.X, size.Y) * 0.95
	local length = size.Z * 0.9
	local fx = {}
	for k = 1, vfx.WIND_SHEETS do
		-- Round the cone, missing the underside (the ground).
		local angle = math.rad(-110 + 220 * (k - 1) / (vfx.WIND_SHEETS - 1))
		local out = Vector3.new(math.sin(angle), math.cos(angle), 0) -- radial, 0 = straight up
		local around = Vector3.new(0, 0, -1):Cross(out)
		local a0 = Instance.new("Attachment")
		a0.CFrame = base * CFrame.fromMatrix(nose, out, around)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.CFrame = base * CFrame.fromMatrix(nose + out * radius + Vector3.new(0, 0, length), out, around)
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
vfx.hazards.spiked = function(entity, dx) -- (a stampede animal ran into your Soul Horse's spike trail)
	knock(entity, dx)
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

-- Rattle, once the rattling's done (QM, Oct 4): everything standing within the
-- radius is smashed, and for cfg.ScareTime the snake scares off every animal that
-- comes within it (vfx.updateScared), each one refilling cfg.RestorePer of Hold.
local function rattleBlast(cfg)
	rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius)
	for _, o in obstacles do
		if not o.smashed and Vector2.new(o.x - mount.x, o.z - mount.z).Magnitude < cfg.Radius then
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
	vfx.endScare()
	vfx.scareAura = { mount = mount, left = cfg.ScareTime, radius = cfg.Radius, restorePer = cfg.RestorePer, scared = {} }
	vfx.snakeGlow(mount, true)
end

-- Spikes (the Soul Horse, QM Oct 4): steel spikes burst up out of the ground all round
-- it, rippling out to cfg.Radius, then sink back after cfg.Duration. Every animal within
-- the radius (whatever its size; never an event's) is killed, flung away, each one
-- refilling cfg.RestorePer of Hold. remote: another rider's, just the look.
vfx.SPIKE_FIELD_COLOR = Color3.fromRGB(132, 144, 162)
local SPIKE_PEAK = Vector3.new(1, 0, -1) -- a CornerWedgePart's peak, seen from above
function vfx.spikeField(center, cfg, remote)
	local rng = Random.new()
	local holder = Instance.new("Model")
	holder.Name = "SpikeField"
	holder.Parent = workspace
	local rise = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local sink = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for i = 1, cfg.Count do
		-- spread evenly over the disc (sqrt), none right under the horse
		local r = math.sqrt(rng:NextNumber((6 / cfg.Radius) ^ 2, 1)) * cfg.Radius
		local a = rng:NextNumber(0, 2 * math.pi)
		local x, z = center.X + math.cos(a) * r, center.Z + math.sin(a) * r
		local w, h = rng:NextNumber(2.4, 3.6), rng:NextNumber(4, 7)
		local floor = Ground.heightAt(x, z)
		-- four corner wedges, each with its peak over the middle: a pyramid
		for sx = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local turn = 0
				for k = 0, 3 do
					local v = CFrame.Angles(0, k * math.pi / 2, 0) * SPIKE_PEAK
					if math.sign(v.X) == -sx and math.sign(v.Z) == -sz then
						turn = k * math.pi / 2
					end
				end
				local part = Instance.new("CornerWedgePart")
				part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
				part.Material = Enum.Material.SmoothPlastic
				part.Color = vfx.SPIKE_FIELD_COLOR
				part.Size = Vector3.new(w / 2, h, w / 2)
				local up = CFrame.new(x + sx * w / 4, floor + h / 2, z + sz * w / 4) * CFrame.Angles(0, turn, 0)
				part.CFrame = up - Vector3.new(0, h + 0.5, 0)
				part.Parent = holder
				task.delay(r / cfg.Radius * 0.35, function() -- rippling out from the horse
					TweenService:Create(part, rise, { CFrame = up }):Play()
				end)
				task.delay(cfg.Duration, function()
					TweenService:Create(part, sink, { CFrame = up - Vector3.new(0, h + 0.5, 0) }):Play()
				end)
			end
		end
	end
	task.delay(cfg.Duration + 0.5, function()
		holder:Destroy()
	end)
	rattleRing(Vector3.new(center.X, 0, center.Z), cfg.Radius, vfx.SPIKE_FIELD_COLOR)
	if remote then
		return
	end
	local killed = 0
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and not entity.popping and not entity.event and dx * dx + dz * dz < cfg.Radius * cfg.Radius then
			knock(entity, dx)
			killed += 1
		end
	end
	hold = math.min(hold + holdTime(mount) * cfg.RestorePer * killed, holdTime(mount)) -- QM: 10% each
end

-- While the snake's scare lasts, its horns and blue spikes glow (QM): the parts in
-- its spike colour turn Neon, their studs hidden so the glow shows.
vfx.SPIKE_COLOR = Color3.fromRGB(48, 196, 214)
function vfx.snakeGlow(entity, on)
	for _, part in entity.animal.model:GetDescendants() do
		if part:IsA("BasePart") and part.Color == vfx.SPIKE_COLOR then
			part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			if not on then
				vfx.Studs.apply(part, 0.5) -- (studs as a material, if they're on: Shared/Studs)
			end
			for _, texture in part:GetChildren() do
				if texture:IsA("Texture") then
					texture.Transparency = if on then 1 else 0
				end
			end
		end
	end
end

-- On the ride home the stampede swerves out of your way, late (Config.ReturnAvoid).
-- Like the snake's scare, but only the animals about to hit you, and only just enough.
-- Each animal's swerve is its own sideways offset (entity.swerve, added to its lane by
-- updateHerd), pulled toward a target by a critically damped spring: it eases out,
-- holds its new line till you're past, then eases back. A spring can be retargeted
-- any frame without a kink, and it is the only thing that writes the offset, so nothing
-- fights it. (Before: the swerve rode the shared nudge, which updateHerd decays every
-- frame before the swerve set it again, so the animal shook by a frame-time-dependent
-- amount and moveAnimal swung its facing with it; worse live, where frame times vary.
-- QM, Oct 6.) It aims Clear studs beside where you'll be when it reaches you (your
-- sideways speed carried on), keeps the side it first picked (no ping-pong as you steer)
-- and only ever moves further out. Loose former mounts (strays) swerve the same way,
-- moved bodily with their lane, and keep their new line afterwards.
-- skip: the animals that rolled not to swerve this ride home (one roll each).
vfx.avoid = {
	lastZ = nil,
	lastX = nil,
	vz = 0,
	vx = 0,
	skip = setmetatable({}, { __mode = "k" }),
}
function vfx.updateAvoid(dt)
	local cfg, state = Config.ReturnAvoid, vfx.avoid
	local on = cfg and cfg.On and phase == "return" and mount
	if on and state.lastZ and dt > 0 then
		state.vz = math.max((mount.z - state.lastZ) / dt, 0) -- (toward home is +z)
		state.vx += ((mount.x - state.lastX) / dt - state.vx) * (1 - math.exp(-10 * dt))
	end
	if on then
		state.lastZ, state.lastX = mount.z, mount.x
	else
		state.lastZ, state.lastX, state.vx = nil, nil, 0
		table.clear(state.skip)
	end
	local maxSpeed = cfg and cfg.MaxSpeed or 140
	-- (the crash check is whole bodies now, Oct 8: checkRide. The swerve clears them the
	-- same way, so a wide mount or a big animal still gets out of the way in time.)
	local mhx, mhz = 0, 0
	if on then
		mhx, mhz = vfx.halfBody(mount)
	end
	for _, entity in allAnimals() do
		if entity == mount then
			continue
		end
		local ehx, ehz = 0, 0
		if on then
			ehx, ehz = vfx.halfBody(entity)
		end
		local hitX = math.max((mhx + ehx) * 0.8, 2.6) -- (how close the crash check lets it come)
		local dz = if on then entity.z - mount.z - math.max((mhz + ehz) * 0.8, 5) else -math.huge -- (from where the crash check reaches)
		-- By each zone's Config.Biomes[].Swerve (QM, Oct 6; off Oct 8, back on Oct 9; all
		-- the Meadow's, Oct 10)...
		local here = WorldColors.biomeAt(entity.z)
		local zone = if dz > 0 then Config.Biomes[here].Swerve or 1 else 0
		-- (Any mount: the Oct 8 rule that only a mount from its biome or later got swerved
		-- for is off, QM Oct 9: no lasso levels now, you're nearly always on the latest biome's.)
		if zone > 0 and not (entity.popping or entity.event) then
			local clear = (cfg.Clear + hitX - 2.6) * zone -- (Clear was tuned for the old 2.6-stud check)
			local t = dz / math.max(state.vz + math.max(entity.speed or 0, 0), 1) -- seconds until it's on you
			local base = entity.x - (entity.swerve or 0) -- its line without the swerve
			local px = math.clamp(mount.x + state.vx * math.min(t, 1), -vfx.edge(entity.z), vfx.edge(entity.z)) -- where you'll be by then (a guess past 1 s)
			local gap = base + (entity.swerveTo or 0) - px
			-- How briskly it swerves: its sideways speed peaks at Turn x its own running speed
			-- (a spring's peak is shift x w / e), so quick animals dart aside and slow ones lumber
			-- (QM, Oct 6). It starts early enough to be ~95% there (4.74 / w s) when it reaches
			-- you, never later than Warn; if you swerve at it late, it hurries (w t >= 2: over half
			-- way across by then).
			local side0 = entity.swerveSide or (if gap > 0 then 1 elseif gap < 0 then -1 elseif entity.x > 0 then -1 else 1)
			local reach = math.abs(math.clamp(px + side0 * clear, -vfx.edge(entity.z), vfx.edge(entity.z)) - entity.x)
			local w = 2.718 * cfg.Turn * math.max(entity.speed or 0, 10) / math.max(reach, 1)
			w = math.clamp(math.max(w, 2 / math.max(t, 0.1)), 0.8, 12)
			if t <= math.max(cfg.Warn, 4.74 / w) and math.abs(gap) < clear then
				if state.skip[entity] == nil then
					state.skip[entity] = false -- (always: QM, Oct 9; the zone's Swerve only sets how far)
				end
				if not state.skip[entity] then
					-- Away from you (the side it first picked), unless the wall leaves it in your way.
					local side = side0
					local target = math.clamp(px + side * clear, -vfx.edge(entity.z), vfx.edge(entity.z))
					if math.abs(target - px) < math.min(6, clear) then
						side = -side
						target = math.clamp(px + side * clear, -vfx.edge(entity.z), vfx.edge(entity.z))
					end
					entity.swerveSide, entity.swerveTo = side, target - base
					entity.swerveW = w
				end
			end
		elseif dz < -10 and entity.swerveSide then
			-- Past you: a stampede animal drifts back to its line; a stray keeps its new one.
			entity.swerveSide, entity.swerveW = nil, 2
			entity.swerveTo = if entity.n then 0 else entity.swerve
		end
		local s, to, v = entity.swerve or 0, entity.swerveTo or 0, entity.swerveV or 0
		if s ~= to or v ~= 0 then
			-- Critically damped spring, solved exactly for this dt (the same at any frame rate).
			local w = entity.swerveW or 2
			local off = s - to
			local a = (v + w * off) * dt
			local decay = math.exp(-w * dt)
			off, v = (off + a) * decay, math.clamp((v - w * a) * decay, -maxSpeed, maxSpeed)
			if math.abs(off) < 0.01 and math.abs(v) < 0.05 then
				off, v = 0, 0
			end
			if not entity.n then
				local step = to + off - s
				entity.x = math.clamp(entity.x + step, -vfx.edge(entity.z), vfx.edge(entity.z))
				entity.lane = math.clamp((entity.lane or entity.x / vfx.widen(entity.z)) + step / vfx.widen(entity.z), -EDGE, EDGE)
			end
			entity.swerve, entity.swerveV = to + off, v
		end
	end
end

-- The scare's over (its time is up, the ride ended, or the snake's gone).
function vfx.endScare()
	local aura = vfx.scareAura
	if aura then
		vfx.scareAura = nil
		vfx.snakeGlow(aura.mount, false)
	end
end

-- The snake's scare, while it lasts: every animal within its radius scatters
-- sideways, away from it (QM: all of them, not only the ones there for the rattle).
function vfx.updateScared(dt)
	local aura = vfx.scareAura
	if not aura then
		return
	end
	aura.left -= dt
	if aura.left <= 0 or mount ~= aura.mount then
		vfx.endScare()
		return
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and not entity.popping and dx * dx + dz * dz < aura.radius * aura.radius then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -aura.radius, aura.radius)
			else
				entity.lane = math.clamp((entity.lane or entity.x / vfx.widen(entity.z)) + away * 60 * dt / vfx.widen(entity.z), -EDGE, EDGE)
			end
			if not aura.scared[entity] then
				aura.scared[entity] = true
				hold = math.min(hold + holdTime(mount) * aura.restorePer, holdTime(mount))
			end
		end
	end
end

-- Frost: a blizzard bursting out round the Icebringer, then snow swirling round it
-- while it lasts (the returned fx are cleared when it ends).
-- A rainbow streaming out behind a leaping animal while it's in the air: six
-- trails stacked one above another, a band of colour each. lifetime: how long
-- each band trails (the Leap's 1.4 s by default).
vfx.RAINBOW = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 240),
}
-- scale: x the bands' height (the bought Rainbow Trail's Config.RainbowTrail.Width);
-- a taller rainbow is lifted so its bottom stays at the ground.
function vfx.rainbowFx(entity, lifetime, scale, colors)
	colors = colors or vfx.RAINBOW
	local root = entity.animal.model.PrimaryPart
	local middle, size = entity.animal.model:GetBoundingBox()
	local back = root.CFrame:ToObjectSpace(middle * CFrame.new(0, 0, size.Z * 0.3)) -- toward its tail (it faces -Z)
	scale = scale or 1
	local band = size.Y * 0.6 * scale / #colors
	local lift = math.max(size.Y * 0.3 * scale - size.Y * 0.5, 0)
	local parts = {}
	for k, color in colors do
		local y = size.Y * 0.3 * scale + lift - (k - 1) * band
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.CFrame = back * CFrame.new(0, y, 0)
		a1.CFrame = back * CFrame.new(0, y - band, 0)
		a0.Parent, a1.Parent = root, root
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(color)
		trail.Lifetime = lifetime or 1.4
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
			if cfg.RestorePer and vfx.frozenByThis and not vfx.frozenByThis[entity] then
				vfx.frozenByThis[entity] = true
				hold = math.min(hold + holdTime(mount) * cfg.RestorePer, holdTime(mount))
			end
			if entity.n and herd[entity.n] == entity then
				vfx.frostLeft[entity.n] = math.max(vfx.frostLeft[entity.n] or 0, left)
			else
				entity.frostLeft = math.max(entity.frostLeft or 0, left)
			end
		end
	end
end

-- Abilities that don't make the pet untouchable: it still uses Hold and can crash.
vfx.PLAIN = { Frost = true, Boost = true, Grow = true, Ink = true, Crabwalk = true, Breath = true, Feast = true, Missiles = true, Shield = true }

-- An animal's size when nothing's growing it for now: what merging (Shared/Merge) or
-- its hunts and feasts this ride have made it (entity.feast), else 1. It stays with
-- the animal when you let it go and get back on it.
function vfx.ownSize(entity)
	return entity.feast and entity.feast.size or 1
end

-- A pet's ability (Config.Abilities): a hybrid's is its donor's, the right pick's, or
-- if that has none its body's (QM, Oct 6).
function vfx.abilityOf(entity)
	if not Config.AbilitiesOn then
		return nil -- (abilities off for now: QM, Oct 10)
	end
	return entity and (entity.fuse and Config.Abilities[entity.fuse] or Config.Abilities[entity.kind])
end

-- The Blue Crab's Feast (Config.Abilities): what it has broken since the last one, and
-- how much bigger and faster it has grown this ride. nil for every other pet.
function vfx.feastOf(entity)
	local cfg = vfx.abilityOf(entity)
	if not cfg or (cfg.Kind ~= "Feast" and cfg.Kind ~= "Hunt" and cfg.Kind ~= "Breath") then -- (the Robo Shark and Loong grow the same way)
		return nil
	end
	entity.feast = entity.feast or { count = 0, size = 1, speed = 1 }
	return entity.feast
end

-- The mount broke something (smashed an obstacle, knocked an animal flying).
function vfx.broke()
	local feast = vfx.feastOf(mount)
	if feast then
		feast.count += 1
	end
end

-- The mount's size tier right now: Grow and Crabwalk make it bigger while they run.
function vfx.mountTier()
	local a = activeAbility()
	local tier = tierOf(mount.kind)
	if a and a.cfg.Tier then
		tier = math.max(tier, a.cfg.Tier)
	end
	if mount.feast and mount.feast.size > 1 then -- grown by its Feasts: TierGrowth x bigger is a tier up
		tier += math.floor(math.log(mount.feast.size) / math.log(Config.TierGrowth) + 1e-6)
	end
	return tier
end

-- The mount's special sprint (Config.SprintSpecials) while Sprint is held on the
-- way out, else nil.
function vfx.sprintSpecial()
	local cfg = mount and Config.SprintSpecials[mount.kind]
	local now = phase == "outbound" or (phase == "return" and cfg and cfg.OnReturn) -- (OnReturn: on the way home too, QM)
	return if cfg and now and not transfer and sprinting() then cfg else nil
end

-- Ink: a dark cloud bursting out round the squid.
function vfx.inkFx(entity)
	local middle = entity.animal.model:GetBoundingBox()
	local burst = Instance.new("Part")
	burst.Anchored, burst.CanCollide, burst.CanQuery, burst.CanTouch = true, false, false, false
	burst.Transparency = 1
	burst.Size = Vector3.new(1, 1, 1)
	burst.CFrame = CFrame.new(middle.Position)
	burst.Parent = workspace
	local ink = Instance.new("ParticleEmitter")
	ink.Texture = "rbxasset://textures/particles/smoke_main.dds"
	ink.Color = ColorSequence.new(Color3.fromRGB(30, 20, 50), Color3.fromRGB(10, 8, 20))
	ink.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 12) })
	ink.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	ink.Lifetime = NumberRange.new(1, 1.8)
	ink.Speed = NumberRange.new(25, 45)
	ink.Drag = 2.5
	ink.SpreadAngle = Vector2.new(180, 30)
	ink.EmissionDirection = Enum.NormalId.Top
	ink.Rate = 0
	ink.Parent = burst
	ink:Emit(80)
	task.delay(2, function()
		burst:Destroy()
	end)
end

-- Ink: the animals within the radius scatter sideways away from the squid.
-- The Unicorn's sprint: the animals within special.ScareRadius scatter away from it,
-- each refilling special.RestorePer of Hold the first time it's scared off.
function vfx.scareOff(dt, special)
	local r = special.ScareRadius
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and not entity.popping and dx * dx + dz * dz < r * r then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -r, r)
			else
				entity.lane = math.clamp((entity.lane or entity.x / vfx.widen(entity.z)) + away * 60 * dt / vfx.widen(entity.z), -EDGE, EDGE)
			end
			if special.RestorePer and entity.scaredOffBy ~= mount then
				entity.scaredOffBy = mount
				hold = math.min(hold + holdTime(mount) * special.RestorePer, holdTime(mount))
			end
		end
	end
end

-- The Robo Shark's Hunt (Config.Abilities): it goes after the nearest animal (not
-- one far behind it) and eats it on contact, growing cfg.Grow x and getting
-- cfg.SpeedUp x faster each time up to size tier cfg.MaxTier, and refilling
-- cfg.RestorePer of Hold. vfx.huntTarget is its prey (steering and arrows follow it).
-- Returns true on the frame it eats one (the Leviathan's hunt, cfg.Once, stops there).
function vfx.huntStep(cfg)
	local prey = vfx.huntTarget
	local function alive(entity)
		return (entity.n and herd[entity.n] == entity) or (not entity.n and table.find(strays, entity) ~= nil)
	end
	if prey and (not alive(prey) or (prey.z - mount.z) * travelDir() <= 0) then
		prey = nil -- gone (eaten, lassoed or knocked away), or no longer ahead of it
	end
	if not prey then
		local best = math.huge
		for _, entity in allAnimals() do
			local dx, dz = entity.x - mount.x, entity.z - mount.z
			if entity ~= mount and not entity.popping and not entity.event and dz * travelDir() > 0 then -- (only ones in front of it, QM)
				local d = dx * dx + dz * dz
				if d < best then
					prey, best = entity, d
				end
			end
		end
	end
	vfx.huntTarget = prey
	if not prey then
		return
	end
	local s = mount.animal.scale
	if math.abs(prey.x - mount.x) < 3 * s and math.abs(prey.z - mount.z) < 5 * s then
		-- Caught: eaten on the spot.
		if prey.n then
			herd[prey.n], taken[prey.n] = nil, true
			vfx.rideCue:FireServer("take", prey.n) -- gone for everyone else too
		else
			table.remove(strays, table.find(strays, prey))
		end
		Poof.at(Vector3.new(prey.x, 0, prey.z))
		retire(prey)
		vfx.huntTarget = nil
		vfx.feed(cfg, 1)
		return true
	end
	return false
end

-- The Robo Shark eats / the Loong burns n animals (cfg: its Config.Abilities entry):
-- cfg.RestorePer of Hold back for each, and cfg.Grow x bigger and cfg.SpeedUp x faster
-- each, up to size tier cfg.MaxTier and cfg.MaxSpeed x its own speed.
function vfx.feed(cfg, n)
	if n <= 0 then
		return
	end
	hold = math.min(hold + holdTime(mount) * cfg.RestorePer * n, holdTime(mount))
	local feast = vfx.feastOf(mount)
	local max = Config.TierGrowth ^ math.max(cfg.MaxTier - tierOf(mount.kind), 0)
	if feast.size < max then
		local size = math.min(feast.size * cfg.Grow ^ n, max)
		local looming = vfx.sprintMount == mount and vfx.sprintKind == "Loom"
		local special = Config.SprintSpecials[mount.kind]
		local show = if looming and special then size * special.Grow else size -- (bigger still while it looms)
		mount.scaleAnim = { t = 0, from = mount.animal.scale, size = show }
		feast.size = size
	end
	feast.speed = math.min(feast.speed * cfg.SpeedUp ^ n, cfg.MaxSpeed or math.huge)
end

-- The Kraken's Devour (Config.Abilities): its tentacles shoot out to the nearest
-- animals of cfg.MaxTier or smaller within cfg.Radius (up to cfg.Max), each one is
-- reeled in over cfg.PullTime, shrinking into it, and eaten, refilling
-- cfg.RestorePer of Hold. The prey leave the stampede the moment they're grabbed.
-- The Beholder's is the same with one tentacle (cfg.Max 1) in its own colour.
vfx.TENTACLE_COLOR = Color3.fromRGB(44, 64, 150)
function vfx.devour(active, cfg)
	local found = {}
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		local d = dx * dx + dz * dz
		if entity ~= mount and not entity.popping and not entity.event and tierOf(entity.kind) <= cfg.MaxTier
			and d < cfg.Radius * cfg.Radius then
			table.insert(found, { entity = entity, d = d })
		end
	end
	table.sort(found, function(a, b)
		return a.d < b.d
	end)
	active.prey, active.fx = {}, active.fx or {}
	for i = 1, math.min(cfg.Max, #found) do
		local entity = found[i].entity
		if entity.n and herd[entity.n] == entity then
			herd[entity.n], taken[entity.n] = nil, true
			vfx.rideCue:FireServer("take", entity.n) -- gone for everyone else too
		else
			local k = table.find(strays, entity)
			if k then
				table.remove(strays, k)
			end
		end
		local tentacle = Instance.new("Part")
		tentacle.Anchored, tentacle.CanCollide, tentacle.CanQuery, tentacle.CanTouch = true, false, false, false
		tentacle.Color = cfg.TentacleColor or vfx.TENTACLE_COLOR
		tentacle.Material = Enum.Material.SmoothPlastic
		tentacle.Parent = workspace
		table.insert(active.fx, tentacle)
		table.insert(active.prey, { entity = entity, from = Vector3.new(entity.x, 0, entity.z), tentacle = tentacle })
	end
end

function vfx.devourStep(active, t)
	local cfg = active.cfg
	local mouth = Vector3.new(mount and mount.x or 0, cfg.Mouth or 3, mount and mount.z or 0) -- (the Beholder's floats higher)
	for _, prey in active.prey do
		if not prey.eaten then
			local entity = prey.entity
			local reach = math.clamp(t / (cfg.PullTime * 0.35), 0, 1) -- out to it first...
			local pull = math.clamp((t - cfg.PullTime * 0.35) / (cfg.PullTime * 0.65), 0, 1) -- ...then reeled in
			local eased = pull * pull
			if pull >= 1 or not mount then
				prey.eaten = true
				prey.tentacle:Destroy()
				Poof.at(Vector3.new(entity.x, 0, entity.z))
				retire(entity)
				if mount then
					hold = math.min(hold + holdTime(mount) * cfg.RestorePer, holdTime(mount))
				end
			else
				local at = prey.from:Lerp(Vector3.new(mouth.X, 0, mouth.Z), eased)
				entity.x, entity.z = at.X, at.Z
				entity.animal:setScale(1 - 0.8 * eased)
				place(entity, 0)
				local tip = mouth:Lerp(Vector3.new(at.X, 2, at.Z), reach)
				local length = (tip - mouth).Magnitude
				prey.tentacle.Size = Vector3.new(2.6, 2.6, math.max(length, 0.1))
				prey.tentacle.CFrame = CFrame.lookAt((mouth + tip) / 2, tip + Vector3.new(0, 0, 0.001))
			end
		end
	end
end

-- The Blue Crab's Shield (Config.Abilities): King Crabs marching in a line in front
-- of it, each soaking one hit (the animal that runs into it is knocked flying).
function vfx.summonShield(cfg)
	vfx.endShield()
	local crabs = {}
	for i = 1, cfg.Crabs do
		local offset = (i - (cfg.Crabs + 1) / 2) * cfg.Spread
		local crab = newEntity(mount.x + offset, mount.z + travelDir() * cfg.Ahead, mount.yaw, "KingCrab")
		crab.offset = offset
		Poof.at(Vector3.new(crab.x, 0, crab.z))
		table.insert(crabs, crab)
	end
	vfx.shield = { mount = mount, cfg = cfg, crabs = crabs, left = cfg.Life }
end

function vfx.endShield()
	local shield = vfx.shield
	vfx.shield = nil
	for _, crab in shield and shield.crabs or {} do
		Poof.at(Vector3.new(crab.x, 0, crab.z))
		crab.animal.model:Destroy()
	end
end

function vfx.updateShield(dt)
	local shield = vfx.shield
	if not shield then
		return
	end
	shield.left -= dt
	if shield.left <= 0 or mount ~= shield.mount or #shield.crabs == 0 then
		vfx.endShield()
		return
	end
	local cfg = shield.cfg
	for i = #shield.crabs, 1, -1 do
		local crab = shield.crabs[i]
		crab.x = math.clamp(mount.x + crab.offset, -vfx.edge(mount.z), vfx.edge(mount.z))
		crab.z = mount.z + travelDir() * cfg.Ahead
		crab.yaw = mount.yaw
		animate(crab, dt, mount.speed, 0)
		place(crab, 0)
		for _, entity in allAnimals() do
			local dx = entity.x - crab.x
			if entity ~= mount and not entity.popping and not entity.event
				and math.abs(dx) < cfg.Radius and math.abs(entity.z - crab.z) < cfg.Radius then
				knock(entity, dx) -- soaked: the attacker goes flying, and this crab is spent
				Poof.at(Vector3.new(crab.x, 0, crab.z))
				crab.animal.model:Destroy()
				table.remove(shield.crabs, i)
				break
			end
		end
	end
end

function vfx.inkBlast(dt, cfg)
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and dx * dx + dz * dz < cfg.Radius * cfg.Radius then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -cfg.Radius, cfg.Radius)
			else
				entity.lane = math.clamp(entity.lane + away * 60 * dt / vfx.widen(entity.z), -EDGE, EDGE)
			end
		end
	end
end

-- Breath (the Loong): from FireFrom to FireTo seconds into its "special" animation,
-- a stream of QM's spiral (assets/ui/LoongSpiral.png) pours out of its mouth, growing as
-- they fly (like QM's reference clip), aimed at the spot on the ground under the
-- mouse; on a phone, the last place tapped; with neither, straight ahead.
vfx.SPIRAL = "rbxassetid://73420824782915"
vfx.FIRE_LIFE = 0.9 -- seconds a fire spiral lives (and flies out to the range in)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.Touch and not processed then
		vfx.lastTap = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

-- Flat unit vector from the mount toward where the breath is aimed.
function vfx.breathAim()
	local ahead = Vector3.new(0, 0, travelDir())
	local ray
	if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
		local m = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(m.X, m.Y)
	elseif vfx.lastTap then
		ray = camera:ScreenPointToRay(vfx.lastTap.X, vfx.lastTap.Y)
	end
	if not ray or ray.Direction.Y > -1e-3 then
		return ahead
	end
	local floor = Ground.heightAt(mount.x, mount.z)
	local hit = ray.Origin + ray.Direction * ((floor - ray.Origin.Y) / ray.Direction.Y)
	local d = Vector3.new(hit.X - mount.x, 0, hit.Z - mount.z)
	return if d.Magnitude > 1 then d.Unit else ahead
end

-- remote: another player's Loong (we don't know their aim): straight out of its mouth.
function vfx.breathFx(entity, cfg, remote)
	-- Always the size it'd be on a large Loong, however big this one has grown (QM).
	local s = entity.animal.size * Config.TierGrowth ^ math.max(3 - (Config.PetTiers[entity.kind] or 1), 0)
	local at = Instance.new("Attachment") -- yours: in the world, turned toward the aim each frame (breathBlast)
	at.Name = "LoongFireAt"
	if remote then
		local jaw = entity.animal.model:FindFirstChild("jawBone") or entity.animal.model.PrimaryPart
		at.CFrame = CFrame.new(0, 0, -2 * entity.animal.size)
		at.Parent = jaw
	else
		at.Parent = workspace.Terrain
	end
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "LoongFire"
	fire.Texture = vfx.SPIRAL
	-- Like real fire (QM): white at the mouth, then yellow, orange and red as it flies out.
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.15, Color3.fromRGB(255, 236, 90)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 140, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 30, 20)),
	})
	fire.LightEmission = 0.4
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * s), NumberSequenceKeypoint.new(1, 6.4 * s) }) -- (QM: 2x)
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fire.Rotation = NumberRange.new(0, 360)
	fire.RotSpeed = NumberRange.new(-120, 120)
	-- They brake to a stop right at the end of the range and bunch up there (QM): out
	-- fast, then braked steadily by an Acceleration against the aim (set each frame in
	-- breathBlast), so a spiral covers 2 x speed x life / 2 = Range. (Particles can't
	-- follow a custom speed curve; steady braking is the closest an emitter does.)
	fire.Lifetime = NumberRange.new(vfx.FIRE_LIFE)
	fire.Speed = NumberRange.new(2 * cfg.Range / vfx.FIRE_LIFE * 0.95, 2 * cfg.Range / vfx.FIRE_LIFE * 1.05)
	fire.SpreadAngle = Vector2.new(8, 8)
	fire.EmissionDirection = Enum.NormalId.Front -- the attachment's -Z, pointed at the aim
	fire.Rate = 140 -- a constant stream (QM)
	fire.Enabled = false
	fire.Parent = at
	task.delay(cfg.FireFrom, function()
		if fire.Parent then
			fire.Enabled = true
		end
	end)
	task.delay(cfg.FireTo, function()
		if fire.Parent then
			fire.Enabled = false
		end
	end)
	return { at }
end

-- Breath: the fire follows the aim, and while it pours everything in its path
-- (Range long, Width wide) is burnt away, obstacles and animals whatever their size.
function vfx.breathBlast(active)
	local cfg = active.cfg
	local aim = vfx.breathAim()
	local at = active.fx and active.fx[1]
	if at then
		local model = mount.animal.model
		local jaw = model:FindFirstChild("jawBone") or model.PrimaryPart
		local mouth = (jaw.CFrame * CFrame.new(0, 0, -2 * mount.animal.size * mount.animal.scale)).Position
		at.WorldCFrame = CFrame.lookAt(mouth, mouth + aim)
		local fire = at:FindFirstChild("LoongFire")
		if fire then
			fire.Acceleration = -aim * (2 * cfg.Range / vfx.FIRE_LIFE / vfx.FIRE_LIFE) -- braking to a stop at the range's end
		end
	end
	if active.t < cfg.FireFrom or active.t > cfg.FireTo then
		return
	end
	local half = cfg.Width / 2
	local function inPath(x, z, extra)
		local rx, rz = x - mount.x, z - mount.z
		local along = rx * aim.X + rz * aim.Z
		local across = math.abs(rx * aim.Z - rz * aim.X)
		return along > -4 and along < cfg.Range and across < half + (extra or 0)
	end
	for _, o in obstacles do
		if not o.smashed and inPath(o.x, o.z, o.hx) then
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
	local burnt = 0
	for _, entity in allAnimals() do
		if entity ~= mount and not entity.popping and not entity.event and inPath(entity.x, entity.z) then
			knock(entity, entity.x - mount.x)
			burnt += 1
		end
	end
	if cfg.Grow then
		vfx.feed(cfg, burnt) -- each one burnt: Hold back, and bigger and faster (QM)
	end
end

-- Flame (the Leviathan's sprint, QM Oct 4): the Loong's fire as a short flamethrower
-- out of its mouth, straight ahead of its head. flameFx makes the stream; flameBlast
-- aims it each frame and burns away every obstacle and animal within cfg.Range studs
-- of the mouth (cfg.Width wide), whatever its size.
vfx.FLAME_LIFE = 0.3 -- seconds a flame spiral lives
function vfx.flameMouth(entity)
	local model = entity.animal.model
	local head = model:FindFirstChild("neckBone") or model.PrimaryPart
	local s = entity.animal.size * entity.animal.scale
	local mouth = (head.CFrame * CFrame.new(0, 0.5 * s, -6.9 * s)).Position -- the tip of its snout (model studs)
	local look = head.CFrame.LookVector
	local aim = Vector3.new(look.X, 0, look.Z)
	return mouth, if aim.Magnitude > 0.1 then aim.Unit else Vector3.new(0, 0, travelDir())
end

function vfx.flameFx(entity, cfg)
	local at = Instance.new("Attachment")
	at.Name = "LeviathanFlameAt"
	at.Parent = workspace.Terrain
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "LeviathanFlame"
	fire.Texture = vfx.SPIRAL
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 236, 90)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 140, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 30, 20)),
	})
	fire.LightEmission = 0.4
	local s = entity.animal.scale
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5 * s), NumberSequenceKeypoint.new(1, 5 * s) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 1) })
	fire.Rotation = NumberRange.new(0, 360)
	fire.RotSpeed = NumberRange.new(-180, 180)
	fire.Lifetime = NumberRange.new(vfx.FLAME_LIFE)
	local speed = (cfg.Range + 3) / vfx.FLAME_LIFE -- out a little past the reach of the burn
	fire.Speed = NumberRange.new(speed * 0.9, speed * 1.1)
	fire.SpreadAngle = Vector2.new(14, 14)
	fire.EmissionDirection = Enum.NormalId.Front
	fire.Rate = 120
	fire.Parent = at
	vfx.flameBlast(cfg, at) -- placed at the mouth before its first frame
	return { at }
end

function vfx.flameBlast(cfg, at)
	local mouth, aim = vfx.flameMouth(mount)
	at = at or (vfx.sprintFx and vfx.sprintFx[1])
	if at then
		at.WorldCFrame = CFrame.lookAt(mouth, mouth + aim)
	end
	local half = cfg.Width / 2
	local function inPath(x, z, extra)
		local rx, rz = x - mouth.X, z - mouth.Z
		local along = rx * aim.X + rz * aim.Z
		local across = math.abs(rx * aim.Z - rz * aim.X)
		return along > -2 - (extra or 0) and along < cfg.Range + (extra or 0) and across < half + (extra or 0)
	end
	for _, o in obstacles do
		if not o.smashed and inPath(o.x, o.z, o.hx) then
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
	for _, entity in allAnimals() do
		if entity ~= mount and not entity.popping and not entity.event and inPath(entity.x, entity.z) then
			knock(entity, entity.x - mount.x)
		end
	end
end

-- Missiles (the Robo Shark): two missiles off its sides, sized to it, heading `dir`.
-- Spread and Size are in the shark's own model studs.
function vfx.launchMissiles(entity, cfg, dir)
	local s = entity.animal.size * entity.animal.scale
	local p = entity.animal.model.PrimaryPart.Position
	return vfx.Missiles.new(p.X, p.Y, p.Z, dir, cfg.Spread * s, cfg.Size * s)
end

-- Missiles: everything in the stretch of each missile's lane it flew through this
-- frame is smashed or knocked flying, obstacles and animals whatever their size.
function vfx.missileSweep(lanes, cfg)
	local dir = travelDir()
	for _, lane in lanes do
		local lo, hi = math.min(lane.from, lane.to) - 2, math.max(lane.from, lane.to) + 2
		for _, o in obstacles do
			if not o.smashed and o.z >= lo and o.z <= hi and math.abs(o.x - lane.x) < cfg.Radius + o.hx then
				smash(o, dir, if o.x >= lane.x then 1 else -1)
				Poof.at(Vector3.new(o.x, 0, o.z))
			end
		end
		for _, entity in allAnimals() do
			if entity ~= mount and not entity.popping and entity.z >= lo and entity.z <= hi and math.abs(entity.x - lane.x) < cfg.Radius then
				knock(entity, entity.x - mount.x)
			end
		end
	end
end

-- The kind of animal a model at home is: the waiting starter, a pen pet or a
-- stampede animal RIDE can jump on.
function vfx.kindOf(model)
	if starter and starter.animal.model == model then
		return starter.kind
	end
	local pet = PenPets.pets[model] or herdRideable[model]
	return pet and pet.kind
end

-- Grow and Crabwalk change size with a springy pop (QM: animation principles,
-- not a sudden jump). Growing: a quick squash down first (anticipation), then it
-- springs up past its new size and settles (overshoot). Shrinking: a little puff
-- first, then it drops back past its own size and settles.
vfx.POP_WIND = 0.12 -- seconds of the squash or puff before the pop
vfx.POP_TIME = 0.9 -- seconds the whole pop takes
function vfx.updateScale(dt)
	local old = vfx.scaleMount
	if old and old ~= mount and old.scaleAnim then
		old.animal:setScale(if old.scaleAnim.shrink then old.scaleAnim.base or 1 else old.scaleAnim.size) -- let go mid-pop: finish it
		old.scaleAnim = nil
	end
	vfx.scaleMount = mount
	local e = mount
	local anim = e and e.scaleAnim
	if not anim then
		return
	end
	anim.t += dt
	local t, s = anim.t, nil
	local from, to = if anim.shrink then anim.size else anim.from or 1, if anim.shrink then anim.base or 1 else anim.size
	if t < vfx.POP_WIND then
		local u = math.sin(math.pi * t / vfx.POP_WIND)
		s = from * (if anim.shrink then 1 + 0.06 * u else 1 - 0.1 * u)
	else
		local k = t - vfx.POP_WIND
		s = to + (from - to) * math.exp(-7 * k) * math.cos(14 * k)
	end
	if t >= vfx.POP_TIME then
		s, e.scaleAnim = to, nil
	end
	e.animal:setScale(s)
end

-- Special sprints: their effects come and go with Sprint (and stop with the mount).
function vfx.updateSprint(dt)
	local cfg = vfx.sprintSpecial()
	local kind = cfg and cfg.Kind
	if mount ~= vfx.sprintMount or kind ~= vfx.sprintKind then
		for _, fx in vfx.sprintFx or {} do
			fx:Destroy()
		end
		local old = vfx.sprintMount
		if old and old ~= mount and (vfx.sprintKind == "Fly" or vfx.sprintKind == "Burrow") then
			old.hop = 0 -- let go of mid-air or underground: back on the ground
		end
		vfx.Burrow.stop(vfx.burrowSpray)
		vfx.sprintFx, vfx.burrowSpray = {}, nil
		if old ~= mount then
			vfx.burrowDepth = nil
		end
		-- Loom (the Loong) swells while Sprint is held, and pops back when it's let go.
		if vfx.sprintKind == "Loom" and old then
			local base = old.feast and old.feast.size or 1 -- (back to what its breath has grown it to)
			if old == mount then
				old.scaleAnim = { shrink = true, t = 0, size = old.animal.scale, base = base }
			else
				old.scaleAnim = nil
				old.animal:setScale(base)
			end
		end
		if kind == "Loom" then
			mount.scaleAnim = { t = 0, from = mount.animal.scale, size = cfg.Grow * (mount.feast and mount.feast.size or 1) }
		end
		if kind == "Ram" then
			vfx.sprintFx = chargeFx(mount, 0.35) -- QM: 0.7x the half-size wind it had
		elseif kind == "Crabwalk" then
			vfx.sprintFx = chargeFx(mount, 0.5, math.pi / 2) -- sideways, like the crab
		elseif kind == "Flame" then
			vfx.sprintFx = vfx.flameFx(mount, cfg)
		elseif kind == "Burrow" then
			vfx.burrowSpray = vfx.Burrow.start(mount.z)
		end
		vfx.sprintMount, vfx.sprintKind = mount, kind
	end
	local special = mount and Config.SprintSpecials[mount.kind]
	if not special or activeAbility() then
		return
	end
	if kind == "Loom" then
		vfx.inkBlast(dt, special) -- the animals round it scatter
	elseif kind == "Smash" then
		vfx.scareOff(dt, special) -- the Unicorn's: the animals round it scatter too, refilling Hold
	elseif kind == "Flame" then
		vfx.flameBlast(special) -- the Leviathan's flamethrower
	end
	if kind and kind ~= "Smash" and special.ScareRadius then
		vfx.scareOff(dt, special) -- (the Beholder's flight scares animals off too)
	end
	-- Fly rises into the air and Burrow sinks under the floor, easing in and out.
	if special.Kind == "Fly" or special.Kind == "Burrow" then
		if special.Kind == "Burrow" and not vfx.burrowDepth then
			local _, size = Outline.box(mount.animal.model)
			vfx.burrowDepth = size.Y + 1
		end
		local target = if kind == "Fly" then special.Height elseif kind == "Burrow" then -vfx.burrowDepth else 0
		mount.hop = (mount.hop or 0) + (target - (mount.hop or 0)) * (1 - math.exp(-4 * dt))
	end
	if vfx.burrowSpray then
		vfx.Burrow.follow(vfx.burrowSpray, mount.x, mount.z)
	end
end

-- The School of Fish's wave: every obstacle and stampede animal between where its
-- front was and where it is now, anywhere across the course, goes flying.
function vfx.waveSweep(from, to)
	if from == to then
		return
	end
	local lo, hi = math.min(from, to) - 3, math.max(from, to) + 3
	local dir = travelDir()
	for _, o in obstacles do
		if not o.smashed and o.z >= lo and o.z <= hi then
			smash(o, dir, if o.x >= 0 then 1 else -1)
		end
	end
	for _, entity in allAnimals() do
		if entity ~= mount and not entity.popping and entity.z >= lo and entity.z <= hi then
			knock(entity, entity.x - mount.x)
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
	if active.wave then
		active.wave:destroy()
	end
	if active.missiles then
		active.missiles:destroy()
	end
	if active.prey then
		vfx.devourStep(active, math.huge) -- cut short: whatever it had hold of is eaten now
	end
	if active.cfg.Kind == "Hunt" then
		vfx.huntTarget, vfx.hunting = nil, nil -- (the arrows go back to the eggs, and Sprint works again)
		entity.yaw = if phase == "return" or phase == "home" then math.pi else 0 -- facing the right way again
	end
	local after = if active.cfg.Kind == "Hunt" then 1.5 else 0.4 -- (you get the steering back mid-stampede after a hunt)
	local root = entity.animal.model.PrimaryPart
	if active.cfg.Tier then
		-- Back to its own size: a springy pop down if it's still the mount.
		entity.scaleAnim = if entity == mount then { shrink = true, t = 0, size = entity.animal.scale, base = vfx.ownSize(entity) } else nil
		if entity ~= mount then
			entity.animal:setScale(vfx.ownSize(entity))
		end
	end
	if active.cfg.Kind == "Leap" or active.cfg.Kind == "Devour" then
		entity.hop = 0
		if root then
			Dust.kick(root.CFrame, entity.animal.scale)
		end
	end
	a.active = nil
	a.readyAt = abilityClock + active.cfg.Cooldown
	if entity == mount then
		grace = math.max(grace, after) -- a moment to clear whatever it was going through
	end
end

local function startAbility(cfg)
	local a = mount.ability
	vfx.rideCue:FireServer("ability", cfg.Kind)
	vfx.sounds.play("ability_use") -- (QM, Oct 9)
	a.active = { kind = cfg.Kind, cfg = cfg, t = 0, fx = {} }
	if cfg.Kind == "Charge" then
		a.active.fx = chargeFx(mount)
		Poof.at(Vector3.new(mount.x, 0, mount.z))
	elseif cfg.Kind == "Leap" then
		Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
		a.active.fx = vfx.rainbowFx(mount)
	elseif cfg.Kind == "Rattle" then
		-- (it scares only once the rattling's done: rattleBlast, from updateAbility)
	elseif cfg.Kind == "Frost" then
		a.active.fx = vfx.frostFx(mount)
		vfx.frozenByThis = {} -- (each animal it freezes refills cfg.RestorePer of Hold once: frostBlast)
		rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius, vfx.FROST_TINT)
		vfx.frostBlast(cfg, cfg.Duration)
	elseif cfg.Kind == "Boost" then
		Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
	elseif cfg.Kind == "Grow" or cfg.Kind == "Crabwalk" then
		Poof.at(Vector3.new(mount.x, 0, mount.z))
		mount.scaleAnim = { t = 0, size = math.max(Config.TierGrowth ^ math.max(cfg.Tier - tierOf(mount.kind), 0), vfx.ownSize(mount)) }
	elseif cfg.Kind == "Ink" then
		vfx.inkFx(mount)
		rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius, Color3.fromRGB(40, 30, 70))
	elseif cfg.Kind == "Wave" then
		a.active.wave = vfx.FishWave.new(mount.z, travelDir(), vfx.edge(mount.z))
	elseif cfg.Kind == "Missiles" then
		hold = math.min(hold + holdTime(mount) * cfg.Restore, holdTime(mount)) -- QM: every launch refills 10% of the Hold bar
		a.active.missiles = vfx.launchMissiles(mount, cfg, travelDir())
	elseif cfg.Kind == "Shield" then
		vfx.summonShield(cfg)
	elseif cfg.Kind == "Spikes" then
		vfx.spikeField(Vector3.new(mount.x, 0, mount.z), cfg)
	elseif cfg.Kind == "Hunt" then
		vfx.huntTarget, vfx.hunting = nil, true
	elseif cfg.Kind == "Devour" then
		mount.speed = 0 -- stops dead on the spot to feed (QM)
		vfx.devour(a.active, cfg)
	elseif cfg.Kind == "Feast" then
		-- Everything broken since the last Feast: Hold back, and bigger and faster for good.
		local feast = vfx.feastOf(mount)
		local n = feast.count
		feast.count = 0
		hold = math.min(hold + holdTime(mount) * cfg.Heal * n, holdTime(mount))
		feast.speed = math.min(feast.speed * cfg.SpeedUp ^ n, cfg.Max)
		if n > 0 and feast.size < cfg.Max then
			mount.scaleAnim = { t = 0, from = mount.animal.scale, size = math.min(feast.size * cfg.Grow ^ n, cfg.Max) }
		end
		feast.size = math.min(feast.size * cfg.Grow ^ n, cfg.Max)
		Poof.at(Vector3.new(mount.x, 0, mount.z))
	elseif cfg.Kind == "Breath" then
		-- (no Hold back just for breathing: only for what it burns, vfx.feed; QM)
		mount.animal:playOnce("special")
		a.active.fx = vfx.breathFx(mount, cfg)
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
	local cfg = mount and vfx.abilityOf(mount)
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
		if active.cfg.Kind == "Hunt" then
			local ate = vfx.huntStep(active.cfg)
			if active.cfg.Once and (ate or not vfx.huntTarget) then
				endAbility(mount) -- the Leviathan: one animal (or nothing ahead to hunt), then done
			end
		elseif active.cfg.Kind == "Devour" then
			vfx.devourStep(active, active.t)
		elseif active.cfg.Kind == "Ink" then
			vfx.inkBlast(dt, active.cfg)
		elseif active.cfg.Kind == "Frost" then
			vfx.frostBlast(active.cfg, active.cfg.Duration - active.t)
		elseif active.cfg.Kind == "Breath" then
			vfx.breathBlast(active)
		elseif active.wave then
			vfx.waveSweep(active.wave:update(dt, mount.speed, active.t, active.cfg.Duration))
		elseif active.missiles then
			vfx.missileSweep(active.missiles:update(dt, mount.speed, active.t), active.cfg)
		end
		if active.cfg.Duration and active.t >= active.cfg.Duration then
			if active.cfg.Kind == "Rattle" then
				rattleBlast(active.cfg) -- the rattle's over: now they're scared
			end
			endAbility(mount) -- (an UntilFull charge ends in checkRide, when Hold is full again)
		end
	elseif pressed and abilityClock >= a.readyAt and (phase == "outbound" or phase == "return") and not transfer
		and not (cfg.UntilFull and hold >= holdTime(mount)) -- nothing to refill
	then
		startAbility(cfg)
	end
	active = a.active
	if active then
		Hud.setAbility(if active.cfg.Duration then 1 - active.t / active.cfg.Duration else hold / holdTime(mount), nil, true)
	else
		local left = math.max(a.readyAt - abilityClock, 0)
		Hud.setAbility(1 - left / cfg.Cooldown, left)
	end
end

local function updateMount(dt)
	local dir = travelDir()
	if phase == "boss" then
		-- Stopped before the boss (BossChase), then off home once its cutscene's done.
		mount.speed, mount.latVel = 0, 0
		place(mount, 0)
		animate(mount, dt, 0, 0)
		if vfx.bossChase.over() then
			turnHome()
		end
		return
	end
	if phase == "turning" then
		turnT = math.min(turnT + dt / TURN_TIME, 1)
		local eased = 0.5 - math.cos(turnT * math.pi) / 2
		mount.yaw = math.pi * eased
		mount.speed = vfx.speedFx.curve(Config.MountSpeed * rideSpeed(mount) * (1 - math.sin(turnT * math.pi) * 0.7))
		mount.latVel *= math.exp(-6 * dt)
		local look = CFrame.Angles(0, mount.yaw, 0).LookVector
		mount.x = math.clamp(mount.x + look.X * mount.speed * dt, -vfx.edge(mount.z), vfx.edge(mount.z))
		mount.z += look.Z * mount.speed * dt
		if turnT >= 1 then
			phase, grace = "return", Config.TurnGrace
			mount.speed = Config.ReturnSpeed * rideSpeed(mount)
			if vfx.tutorialRide.active then -- (the first ride home: a Unicorn gallops past you, to make you curious: QM)
				local st = streams[1]
				local n = math.floor(herdClock / st.every) + 1
				while (st.thin and n % st.thin ~= 0) or (st.keep and (n * 0.6180339887) % 1 >= st.keep) do
					n += 1
				end
				local p = plan(n * BIOME_KEYS)
				p.kind, p.x = "Unicorn", (mount.x + (if mount.x > 0 then -12 else 12)) / vfx.widen(mount.z)
			end
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
	local targetSpeed = phase == "home" and 0 or (dir < 0 and Config.MountSpeed or Config.ReturnSpeed) * rideSpeed(mount)
	if sprinting() then
		targetSpeed *= (Config.PetSprintSpeed[mount.kind] or Config.SprintSpeed) * ((vfx.sprintSpecial() or {}).SpeedBoost or 1) -- the Blue Crab's crab walk: faster still
	end
	targetSpeed *= if mount.feast then mount.feast.speed else 1 -- the Blue Crab, grown by its Feasts
	-- (Out of stamina you turn for home, never ride on tired: checkRide.)
	local rate = phase == "home" and 30 or (dir < 0 and (if (mount.rampUntil or 0) > os.clock() then Config.LandRamp.Rate else 90) or 40) -- snappy into and out of a sprint (gentler just after landing: from a walk to the sprint)
	local ability = activeAbility()
	if ability and ability.cfg.MaxBoost then
		-- The Leviathan's hunt: faster and faster, steadily, up to MaxBoost x (QM).
		local cfg = ability.cfg
		targetSpeed *= math.min(cfg.SpeedBoost + (cfg.MaxBoost - cfg.SpeedBoost) * ability.t / cfg.RampTime, cfg.MaxBoost)
	elseif ability and (ability.cfg.Kind == "Charge" or ability.cfg.Kind == "Boost" or ability.cfg.Kind == "Grow" or ability.cfg.Kind == "Crabwalk" or ability.cfg.Kind == "Hunt") then
		targetSpeed *= ability.cfg.SpeedBoost
	elseif ability and ability.cfg.Kind == "Leap" then
		-- Up into the air and down again in an arc, faster.
		targetSpeed *= ability.cfg.SpeedBoost
		mount.hop = math.sin(math.pi * math.clamp(ability.t / ability.cfg.Duration, 0, 1)) * ability.cfg.LeapHeight
	elseif ability and ability.cfg.Kind == "Breath" then
		targetSpeed *= ability.cfg.Crawl or 1 -- the Loong slows to a crawl while it breathes fire (QM)
	elseif ability and (ability.cfg.Kind == "Rattle" or ability.cfg.Kind == "Devour") then
		targetSpeed, rate = 0, 120 -- stops dead to coil up (or for the Kraken to feed)
		if ability.cfg.Kind == "Devour" then
			targetSpeed, rate = 0, math.huge
			-- A little bounce while it feeds, so it doesn't just sit there (QM): up and
			-- down twice, the first hop the higher.
			local f = math.clamp(ability.t / ability.cfg.Duration, 0, 1)
			mount.hop = math.abs(math.sin(f * math.pi * 2)) * (1 - 0.4 * f) * ability.cfg.Hop
		end
	end
	local curved = vfx.speedFx.curve(targetSpeed) -- (past the knee it bends off: SpeedFx)
	vfx.speedGain = if curved > 0 then targetSpeed / curved else 1
	targetSpeed = curved
	mount.speed += math.clamp(targetSpeed - mount.speed, -rate * dt, rate * dt)
	if ability and ability.cfg.Kind == "Hunt" and vfx.huntTarget then
		-- Hunting (the Robo Shark, QM): no momentum, any direction: it goes straight at
		-- its prey at full charge speed, turning on the spot, whichever way that is.
		local prey = vfx.huntTarget
		local dx, dz = prey.x - mount.x, prey.z - mount.z
		local len = math.max(math.sqrt(dx * dx + dz * dz), 0.001)
		mount.speed = targetSpeed
		local step = math.min(targetSpeed * dt, len)
		mount.x = math.clamp(mount.x + dx / len * step, -vfx.edge(mount.z), vfx.edge(mount.z))
		local z = mount.z + dz / len * step
		if phase == "outbound" then
			z = math.clamp(z, gateZ() + 3, SPAWN_Z) -- not back over the start line, nor into a locked gate
		end
		mount.z = z
		mount.latVel = 0
		mount.yaw = math.atan2(-dx, -dz) -- facing it (yaw 0 faces -z)
		place(mount, 0)
		animate(mount, dt, mount.speed, 0)
		return
	end
	if phase == "outbound" and exitPath then
		-- Out of your pen: out of its gap and straight across the yard to the corridor
		-- (penExitPath), turning smoothly onto each leg. You steer on the way just as you
		-- do riding the stampede (QM, Oct 9: the same SteerSpeed and response), anywhere
		-- that still ends up across the start line: the room either side grows from
		-- GateRoom in your pen's gap to the start line's width (less Margin) by the
		-- corridor, and your sideways speed eases off toward its edges (tanh) so you
		-- never reach them, however long the ride out (Config.ExitSteer).
		local cfg = Config.ExitSteer
		local track = vfx.exitTrack or Vector2.new(mount.x, mount.z) -- (the point on the path itself)
		if not vfx.exitRoute then
			-- (how far the route is, all told and to its first leg's end, and where it ends)
			local total, from = 0, track
			for _, p in exitPath do
				total += (p - from).Magnitude
				from = p
			end
			vfx.exitRoute = { total = math.max(total, 1), first = (exitPath[1] - track).Magnitude, gone = 0, endX = exitPath[#exitPath].X }
			vfx.exitU = 0
		end
		local route = vfx.exitRoute
		local to = exitPath[1]
		local dx, dz = to.X - track.X, to.Y - track.Y
		local len = math.sqrt(dx * dx + dz * dz)
		local step = mount.speed * dt
		local ux, uz = if len > 1e-3 then dx / len else 0, if len > 1e-3 then dz / len else -1
		route.gone += math.min(step, len)
		if len <= step then
			track = to
			table.remove(exitPath, 1)
		else
			track += Vector2.new(ux * step, uz * step)
			local want = math.atan2(-dx, -dz) -- (yaw 0 faces -z)
			local diff = (want - mount.yaw + math.pi) % (2 * math.pi) - math.pi
			mount.yaw += diff * (1 - math.exp(-8 * dt))
		end
		-- Off the line: the room either side here (lo..hi studs, to its right), and where
		-- in it you are (tanh of what you've steered: never quite at either end).
		local f = math.clamp((route.gone - route.first) / math.max(route.total - route.first, 1), 0, 1) ^ 0.7
		local reach = EDGE - cfg.Margin -- (the start line's half width, less a margin)
		local lo = -cfg.GateRoom + (-reach - route.endX + cfg.GateRoom) * f
		local hi = cfg.GateRoom + (reach - route.endX - cfg.GateRoom) * f
		local mid, half = (lo + hi) / 2, (hi - lo) / 2
		-- (steering as on the course: mount.latVel eases toward SteerSpeed x your input)
		local targetLat = readSteer() * Config.SteerSpeed
		mount.latVel += (targetLat - mount.latVel) * (1 - math.exp(-Config.SteerResponse * dt))
		local v = math.tanh(vfx.exitU)
		vfx.exitU += mount.latVel * dt / half
		local lat = mid + half * math.tanh(vfx.exitU)
		local sideways = mount.latVel * (1 - v * v) -- (the speed it really moves aside at, slowing near the edges)
		vfx.exitTrack, vfx.exitLat = track, lat
		mount.x, mount.z = track.X - uz * lat, track.Y + ux * lat -- (its right: (-look.Z, look.X))
		if #exitPath == 0 then
			exitPath, vfx.exitTrack, vfx.exitLat, vfx.exitRoute = nil, nil, nil, nil
			mount.yaw = 0 -- (square to the start line: riding on as usual from here, latVel and all)
		end
		place(mount, math.atan2(-sideways, math.max(mount.speed, 1)))
		animate(mount, dt, mount.speed, sideways / Config.SteerSpeed)
		return
	end
	local steer = phase == "home" and 0 or readSteer()
	-- A wider body steers quicker, gently (QM, Oct 8): Config.SteerWidthScale of each
	-- extra horse-width (1.6 studs half) on top, so twice as wide steers 1.2x.
	local halfWidth = vfx.halfBody(mount)
	local wide = 1 + Config.SteerWidthScale * math.max(halfWidth / 1.6 - 1, 0)
	local targetLat = steer * Config.SteerSpeed * wide * -dir
	-- Leaving the base from an outer pen: lean in so the animal reaches the
	-- corridor by the start line.
	if phase == "outbound" and mount.z > 0 and mount.z < leadFromZ and math.abs(mount.x) > EDGE - 4 then
		local over = math.abs(mount.x) - (EDGE - 4)
		targetLat -= math.sign(mount.x) * over / math.max(mount.z, 4) * math.max(mount.speed, 10)
	end
	if ability and ability.cfg.Kind == "Hunt" then
		-- Hunting on its own (the Robo Shark): it swerves after its prey, not your steering.
		local prey = vfx.huntTarget
		targetLat = if prey then math.clamp((prey.x - mount.x) * 4, -Config.SteerSpeed * 1.5, Config.SteerSpeed * 1.5) else 0
	end
	mount.latVel += (targetLat - mount.latVel) * (1 - math.exp(-Config.SteerResponse * dt))
	-- At home the side limit widens from the corridor's to the base's over 40 studs,
	-- so a ride from an outer pen is eased into the corridor.
	local edge = vfx.edge(mount.z) + (Config.HomeHalfWidth - 4 - vfx.edge(mount.z)) * math.clamp(mount.z / 40, 0, 1)
	edge = math.max(edge - math.max(halfWidth - 2, 0), 4) -- (its whole body stays off the walls)
	mount.x = math.clamp(mount.x + mount.latVel * dt, -edge, edge)
	mount.z += dir * mount.speed * dt
	local sideways = if (ability and ability.cfg.Kind == "Crabwalk") or (vfx.sprintSpecial() or {}).Kind == "Crabwalk" then math.pi / 2 else 0 -- a crab scuttles sideways
	place(mount, math.atan2(mount.latVel * dir, math.max(mount.speed, 1)) + sideways)
	animate(mount, dt, mount.speed, mount.latVel * -dir / (Config.SteerSpeed * wide))
end

local function reachHome()
	if phase == "return" and mount.z >= START_LINE_Z - LEAP_FROM then
		-- Home with the egg: the hero leap over the line (updateMount), then the reveal.
		phase = "home"
		heroLeap = { t = 0, fromZ = mount.z, toZ = START_LINE_Z + Config.HomeLandPast }
		vfx.sounds.play("arrive_home")
		vfx.sounds.play("record_scratch", 0.225) -- (half of 0.45: QM, Oct 10) -- the run home's music stops dead, and it's the base's again (QM, Oct 9)
		vfx.sounds.setMusic("base", true)
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
	if phase == "finish" or phase == "boss" or reachFinish() then -- (nothing crashes you in the boss's cutscene either)
		return -- the leap over the finish line: nothing can go wrong now
	end
	grace = math.max(grace - dt, 0)
	if vfx.tutorialRide.invulnerable then
		grace = math.max(grace, 0.1) -- (nothing crashes you on the tutorial's ride: QM)
	end
	if carried and (phase == "return" or phase == "turning") and mount.z > START_LINE_Z - Config.HomeSafeZone then
		grace = math.max(grace, 0.05) -- nearly home with the egg: nothing crashes you now (QM, Oct 6)
	end
	local ability = activeAbility()
	if ability and vfx.PLAIN[ability.cfg.Kind] then
		ability = nil -- these still use Hold and can still crash (Config.Abilities)
	end
	if ability and ability.cfg.UntilFull then
		-- The Snack Yak's charge refills Hold as fast as it usually drains, and ends
		-- once the bar is full.
		hold += dt
		if hold >= holdTime(mount) then
			hold = holdTime(mount)
			endAbility(mount)
			ability = nil
		end
	end
	-- The Hold bar drains as you ride out (Config.RideSeconds: QM, Oct 10), and lassoing
	-- doesn't refill it. Empty, you turn round on whatever you're on (turnHome).
	local tr = vfx.tutorialRide
	if tr.bossSeconds and not tr.bossStarted then
		tr.bossStarted, hold = true, tr.bossSeconds -- (the tutorial lets BOSS IN go, short)
	end
	if phase == "outbound" and mount.z < 0 and not transfer and not ability and not mount.giant and not tr.holdFrozen then -- abilities and the Giant Horse use no Hold
		hold = math.max(hold - dt, 0) -- (no quicker sprinting: QM, Oct 10)
		if hold <= 0 then
			if Config.Boss.On then -- (the boss first: BossChase, then turnHome; QM, Oct 10)
				phase, mount.speed = "boss", 0 -- (stopped dead, or you'd run on through it: QM)
				vfx.bossChase.start(mount.x, mount.z)
			else
				turnHome()
			end
			return
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
	elseif ability and ability.cfg.Kind == "Hunt" then
		-- The hunting Robo Shark crashes through whatever's in its way (its prey it eats: vfx.huntStep).
		local s = mount.animal.scale
		while true do
			local o = blockedAt(mount.x, mount.z, 2.5 * s, 4 * s, 1)
			if not o then
				break
			end
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
	if ability then
		-- Charging, leaping over everything or coiled up rattling: nothing crashes it.
		if phase == "outbound" and mount.z < gateZ() + 2.4 then
			return fail("CRASH!") -- except a locked gate
		end
		return reachHome()
	end
	-- Special sprints (Config.SprintSpecials).
	local special = vfx.sprintSpecial()
	local kind = special and special.Kind
	if (kind == "Fly" and (mount.hop or 0) > 8) or (kind == "Burrow" and (mount.hop or 0) < -2) then
		-- Over or under everything: nothing to hit but a locked gate.
		if phase == "outbound" and mount.z < gateZ() + 2.4 then
			return fail("CRASH!")
		end
		return reachHome()
	elseif kind == "Smash" then
		for _, o in obstacles do
			if not o.smashed and Vector2.new(o.x - mount.x, o.z - mount.z).Magnitude < special.Radius then
				smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
			end
		end
	elseif kind == "Ram" or kind == "Crabwalk" then
		while true do
			local o = blockedAt(mount.x, mount.z, 2.5, 4, 1)
			if not o then
				break
			end
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
			vfx.broke()
		end
	end
	-- Obstacles never crash you: whatever you ride into is smashed (QM, Oct 6: new
	-- players kept crashing into them). Stampede animals still go by size.
	local bodyX, bodyZ = vfx.halfBody(mount)
	while true do
		local o = blockedAt(mount.x, mount.z, math.max(1.3, bodyX * 0.7), math.max(2.4, bodyZ * 0.7))
		if not o then
			break
		end
		smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		vfx.broke()
	end
	local myTier = vfx.mountTier()
	if phase == "outbound" and mount.z < gateZ() + 2.4 then
		return fail("CRASH!") -- a locked gate
	end
	-- Whole bodies touching (QM, Oct 8): your mount's real box against each animal's,
	-- a little forgiving at the edges. Smaller ones are trampled.
	local mhx, mhz = vfx.halfBody(mount)
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		local ehx, ehz = 0, 0
		if math.abs(dz) < mhz + 60 and not entity.popping and entity ~= mount then
			ehx, ehz = vfx.halfBody(entity)
		end
		if not entity.popping and not entity.event and entity ~= mount and math.abs(dx) < math.max((mhx + ehx) * 0.8, 2.6) and math.abs(dz) < math.max((mhz + ehz) * 0.8, 5) then
			local trample = kind == "Trample" and tierOf(entity.kind) < special.BelowTier -- the Kraken's sprint
			-- Racing home on the Icebringer, an animal frozen in ice smashes whatever its size (QM).
			local shatter = phase == "return" and entity.frostFx ~= nil and (vfx.abilityOf(mount) or {}).Kind == "Frost"
			-- (racing home, nothing crashes you: whatever you run into is knocked away, QM Oct 11)
			if phase == "return" or (trample and tierOf(entity.kind) < myTier) or kind == "Crabwalk" or shatter then
				knock(entity, dx) -- (the Blue Crab's crab walk knocks everything)
				vfx.broke()
				if kind == "Crabwalk" and special.RestorePer then
					hold = math.min(hold + holdTime(mount) * special.RestorePer, holdTime(mount)) -- 20% Hold per animal it hits (QM)
				end
			elseif phase == "outbound" and entity.n then
				entity.dodge = math.clamp(entity.dodge + (if dx >= 0 then 1 else -1) * 12 * dt, -6, 6)
			end
		end
	end
	reachHome()
end

-- Where a thrown-off rider is t (0..1) through their tumble: a flip and a quarter
-- backwards, ending face up on the ground (yours, and other riders': RideCue "crash").
vfx.TUMBLE_TIME = 0.7
function vfx.tumbleCFrame(tumble, t)
	local from = tumble.from
	local gx, gz = from.X + tumble.side * 9, from.Z - 6 * tumble.dir
	local ground = Vector3.new(gx, LIE_HEIGHT + Ground.heightAt(gx, gz), gz)
	local pos = from:Lerp(ground, t) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
	return CFrame.new(pos) * CFrame.Angles(0, tumble.yaw, 0)
		* CFrame.Angles(t * math.pi * 2.5, 0, tumble.side * math.sin(t * math.pi) * 0.8)
end

local function updateRider(dt)
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if tumble then
		tumble.t = math.min(tumble.t + dt / vfx.TUMBLE_TIME, 1)
		hrp.CFrame = vfx.tumbleCFrame(tumble, tumble.t)
		focus = focus:Lerp(Vector3.new(hrp.Position.X, 0, hrp.Position.Z), 1 - math.exp(-4 * dt))
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
			vfx.markEventRun(target)
			if target.n then
				vfx.rideCue:FireServer("take", target.n)
				herd[target.n], taken[target.n], target.n = nil, true, nil
			else
				table.remove(strays, table.find(strays, target))
			end
			mount, transfer = target, nil
			exitPath, vfx.exitTrack, vfx.exitLat, vfx.exitRoute = nil, nil, nil, nil -- (lassoed off your pet still on its way out of your pen: it'd pull you back onto the path, QM)
			vfx.rideCue:FireServer("landed") -- (Riders.server: not lassoing any more)
			picked = nil
			vfx.sounds.play("lasso_land")
			mount.popping, mount.hop, mount.rampUntil = nil, 0, os.clock() + Config.LandRamp.Time
			mount.animal:setScale(vfx.ownSize(mount)) -- (back on a pet you let go: merged or grown, it still is)
			mount.animal:setSaddled(true)
			mount.latVel = 0
			grace = Config.LandingGrace -- (stamina isn't refilled: QM, Oct 8; and no coins for it any more, Oct 9)
		end
		return
	end
	if mount then
		if not humanoid.Sit then
			humanoid.Sit = true
		end
		hrp.CFrame = mount.animal:getSeatCFrame() * SEAT_OFFSET
		if phase ~= "finish" or heroLeap then -- falling off the end: the camera stays at the edge
			-- (and with how high you sit: on a big pet the camera rises with you, eased so a
			-- gallop's bob doesn't shake it, Config.RideCamSeat: QM, Oct 11)
			local lift = math.max(hrp.Position.Y - (mount.hop or 0) - Config.RideCamSeat, 0)
			vfx.seatLift = (vfx.seatLift or lift) + (lift - (vfx.seatLift or lift)) * (1 - math.exp(-2 * dt)) -- (slow: a Rockworm's leaps barely move it)
			focus = Vector3.new(mount.x, math.max(mount.hop or 0, 0) * 0.85 + vfx.seatLift, mount.z) -- the camera rises with a leap, keeping the pet in view
			if mount.animal.seatOnNeck then
				-- A squid's rider sits far out on its leaning mantle: the camera follows the
				-- rider instead (QM), eased so the glide's surges don't shake it.
				-- (at the rider's height, so they stay in the middle of the view)
				local want = hrp.Position - Vector3.new(0, 4, 0)
				vfx.riderFocus = if vfx.riderFocus then vfx.riderFocus:Lerp(want, 1 - math.exp(-10 * dt)) else want
				focus = vfx.riderFocus
			else
				vfx.riderFocus = nil
			end
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
			local held = Lasso.heldCFrame(carried.part)
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
	Hud.setSprint(phase == "outbound", mount ~= nil and sprinting())
	if phase == "outbound" then
		-- The ride's time left (QM, Oct 10: RideSeconds, no more stamina).
		-- (only once you're over the start line, QM: it's as full as it gets till then)
		Hud.setHold(if vfx.tutorialRide.holdFrozen then nil elseif focus.Z < 0 or hold < holdTime(nil) then hold / holdTime(nil) else nil, true, holdTime(nil)) -- (mid-lasso too)
		Hud.setDistance(string.format("%dm", math.max(0, math.floor(-focus.Z / STUDS_PER_METRE))))
		Hud.setAction("LASSO", actionTarget ~= nil)
	end
	local t = phase == "outbound" and not transfer and actionTarget -- (the lasso's prompt on its target: QM, Oct 10)
	vfx.lassoPrompt.update(t and t.animal.model, t and vfx.Fusion.name(t.kind, t.fuse), t and Config.RarityColors[vfx.Fusion.rarity(t.kind, t.fuse)])
	if phase == "turning" or phase == "return" or phase == "home" then
		local metres = math.max(0, -focus.Z / STUDS_PER_METRE)
		Hud.setVignette(math.clamp(metres / Config.VignetteFadeMetres, 0, 1))
	end
end

-- Multiplayer rides (Riders.server): your ride goes out ~10 times a second, and
-- everyone else's comes in. Each other rider gets their own copy of their mount
-- here, moved smoothly between updates, with their character sat on it. What
-- they do to the stampede (jumping on, lassoing, knocking animals flying,
-- smashing obstacles, abilities) shows here too, for looks only: their
-- abilities don't slow or scatter your copy of the stampede.
vfx.SYNC_EVERY = 0.1 -- seconds between your ride's updates
vfx.RIDER_STALE = 2 -- seconds without an update before a rider is taken off
vfx.REMOTE_SMASH_BACK = 4 -- seconds before an obstacle someone else smashed is back
vfx.riders = {} -- [player] = { entity, kind, mountCF, riderCF, vel, speed, scale, at, char, fx, fxEnd, rope }
vfx.syncAt = 0
vfx.syncing = false

function vfx.sendRide()
	local hrp = character()
	if phase == "idle" or not hrp then
		if vfx.syncing then
			vfx.syncing = false
			vfx.rideCue:FireServer("end")
		end
		return
	end
	local now = os.clock()
	if now < vfx.syncAt then
		return
	end
	vfx.syncAt = now + vfx.SYNC_EVERY
	vfx.syncing = true
	local root = mount and mount.animal.model.PrimaryPart
	vfx.rideSync:FireServer(
		if root then vfx.Fusion.key(mount.kind, mount.fuse) else "", -- ("Loong:Pig" for a hybrid)
		if root then root.CFrame else hrp.CFrame,
		hrp.CFrame,
		if mount then mount.speed else 0,
		if mount then mount.animal.scale else 1,
		vfx.lassoState
	)
end

function vfx.riderFx(rider)
	for _, fx in rider.fx do
		fx:Destroy()
	end
	table.clear(rider.fx)
	rider.fxEnd = nil
end

-- Lets go of a rider's mount: it runs on with the stampede, like yours does.
function vfx.dropMount(rider)
	local entity = rider.entity
	if not entity then
		return
	end
	vfx.riderFx(rider)
	for _, fx in rider.trail or {} do
		fx:Destroy()
	end
	rider.trail = nil
	vfx.Burrow.rider(rider, nil)
	rider.entity, rider.kind = nil, nil
	entity.animal:setScale(1)
	entity.hop = 0
	release(entity)
end

function vfx.endRider(player)
	local rider = vfx.riders[player]
	if not rider then
		return
	end
	vfx.riders[player] = nil
	vfx.dropMount(rider)
	vfx.riderLasso(rider, nil)
	local hrp = rider.char and rider.char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false -- back to where the server has it
	end
end

vfx.rideSync.OnClientEvent:Connect(function(player, kind, mountCF, riderCF, speed, scale, lasso)
	if player == Players.LocalPlayer then
		return
	end
	local rider = vfx.riders[player]
	local now = os.clock()
	if not rider then
		rider = { fx = {}, mountCF = mountCF, riderCF = riderCF, vel = Vector3.zero, at = now }
		vfx.riders[player] = rider
	end
	local dt = now - rider.at
	rider.vel = if dt > 0.02 and dt < 0.5 then (mountCF.Position - rider.mountCF.Position) / dt else Vector3.zero
	if rider.vel.Magnitude > 400 then
		rider.vel = Vector3.zero -- a jump (warped, continued): no gliding there
		rider.shown = nil
	end
	rider.mountCF, rider.riderCF, rider.at = mountCF, riderCF, now
	rider.speed, rider.scale = speed, scale
	rider.lassoState = if type(lasso) == "string" then lasso else ""
	if rider.tumble then
		kind = "" -- thrown off: a late update from before the crash doesn't sit them back on
	end
	if rider.kind ~= kind then
		vfx.dropMount(rider)
	end
	local base, fuse = vfx.Fusion.split(kind) -- (a hybrid: Shared/Fusion)
	if kind ~= "" and not rider.entity and Animals:FindFirstChild(base) and (not fuse or Animals:FindFirstChild(fuse)) then
		local p = mountCF.Position
		rider.entity = newEntity(p.X, p.Z, 0, base)
		vfx.Fusion.paint(rider.entity.animal.model, base, fuse)
		rider.entity.animal:setSaddled(true)
		rider.entity.dodge = 0
		rider.kind = kind
		if Config.trailColors(player) then -- the Rainbow Trail, or the finish line's (Config.FinishTrails)
			rider.trail = vfx.rainbowFx(rider.entity, Config.RainbowTrail.Lifetime, Config.RainbowTrail.Width, Config.trailColors(player))
		end
		rider.shown = nil
	end
end)

-- Each other rider has their own lasso (a copy of the Lasso module: it holds one
-- character's state, as the podium's does), swung over their head, thrown at the
-- animal they're lassoing ("lasso" cue) and twirling a caught egg, like yours.
function vfx.riderLasso(rider, char)
	if rider.lasso and rider.lassoChar == char then
		return rider.lasso
	end
	if rider.lasso then
		rider.lasso.Lasso.stop()
		rider.lasso.module:Destroy()
		rider.lasso = nil
	end
	rider.lassoChar = char
	if char and char:FindFirstChild("RightGripAttachment", true) then
		local module = script.Parent.Lasso:Clone()
		module.Name = "RiderLasso"
		module.Parent = script
		rider.lasso = { module = module, Lasso = require(module) }
		rider.lasso.Lasso.start(char, nil, rider.player and rider.player:GetAttribute("PenLevel") or 1)
	end
	return rider.lasso
end

-- Their lasso this frame (after their mount and them are placed).
function vfx.updateRiderLasso(rider, dt)
	local own = vfx.riderLasso(rider, rider.char)
	if not own then
		return
	end
	local L = own.Lasso
	local throw = rider.throw
	local e = throw and os.clock() - throw.at
	if throw and (e > THROW_TIME + TRANSFER_TIME or not throw.entity.animal.model.PrimaryPart) then
		rider.throw, throw = nil, nil
	end
	if throw then
		local neck = throw.entity.animal:getNeck()
		if e < THROW_TIME then
			L.throw(e / THROW_TIME, neck)
		else
			L.pull((e - THROW_TIME) / TRANSFER_TIME, neck)
		end
		own.shown = true
	elseif rider.lassoState == "twirl" and vfx.eggHeads[rider.player] then
		L.twirl(dt, vfx.eggHeads[rider.player].model)
		own.shown = true
	elseif rider.lassoState == "swing" and rider.entity then
		L.swing(dt)
		own.shown = true
	elseif own.shown then
		L.hide() -- once: then their own animations have the arm back
		own.shown = false
	end
end

vfx.rideCue.OnClientEvent:Connect(function(player, what, a, b, c, d)
	if player == Players.LocalPlayer then
		return
	end
	if what == "end" then
		vfx.endRider(player)
		return
	end
	local rider = vfx.riders[player]
	if what == "crash" then
		-- Thrown off (fail): the crash, and them tumbling to the ground behind the animal.
		local from, yaw, dir, side = a, tonumber(b), tonumber(c), tonumber(d)
		if typeof(from) ~= "Vector3" or not yaw or not dir or not side then
			return
		end
		if not rider then
			rider = { fx = {}, mountCF = CFrame.new(from), riderCF = CFrame.new(from), vel = Vector3.zero, at = os.clock() }
			vfx.riders[player] = rider
		end
		vfx.dropMount(rider)
		rider.throw = nil
		rider.tumble = { from = from, yaw = yaw, dir = dir, side = side, at = os.clock() }
		Poof.at(Vector3.new(from.X, 0, from.Z))
		if (from - camera.CFrame.Position).Magnitude < VIEW / 2 then
			vfx.sounds.play("crash", 0.5)
		end
		return
	end
	if what == "take" or what == "lasso" or what == "knock" then
		local key = tonumber(a)
		local entity = key and herd[key]
		if entity and transfer and transfer.target == entity then
			return -- you're lassoing it too: it stays yours
		end
		if what == "lasso" then
			if rider then
				vfx.dropMount(rider) -- their old mount runs on, as yours does
				rider.throw = if entity then { entity = entity, at = os.clock() } else nil
			end
			return -- (it stays in the stampede till it's reeled in: "take")
		end
		if key then
			taken[key] = true
		end
		if what == "knock" then
			if entity then
				knock(entity, tonumber(b) or 0, true)
			end
		elseif entity and rider then
			-- Now their mount: the stampede's copy carries on as it.
			herd[key], entity.n = nil, nil
			if rider.entity then
				retire(rider.entity)
				vfx.riderFx(rider)
			end
			entity.popping, entity.hop = nil, 0
			entity.animal:setScale(1)
			entity.animal:setSaddled(true)
			rider.entity, rider.kind = entity, entity.kind
			rider.tumble = nil
		end
	elseif what == "smash" then
		local x, z = tonumber(a), tonumber(b)
		if not x or not z then
			return
		end
		for _, o in slices.at(slices.block, z) do
			if not o.smashed and math.abs(o.x - x) < 0.5 and math.abs(o.z - z) < 0.5 then
				smash(o, tonumber(c) or -1, tonumber(d) or 1, true)
				o.remoteSmash = true
				task.delay(vfx.REMOTE_SMASH_BACK, function()
					if o.remoteSmash then
						o.smashed, o.remoteSmash = nil, nil
						for _, p in o.parts do
							p.part.CFrame, p.part.Transparency = p.cframe, p.transparency
						end
						Poof.at(Vector3.new(o.x, 0, o.z))
					end
				end)
				break
			end
		end
	elseif what == "ability" and rider and rider.entity then
		local entity = rider.entity
		local cfg = vfx.abilityOf({ kind = entity.kind, fuse = select(2, vfx.Fusion.split(rider.kind)) }) -- (a hybrid's is its donor's)
		if not cfg or cfg.Kind ~= a then
			return
		end
		vfx.riderFx(rider)
		local p = entity.animal.model.PrimaryPart.Position
		if a == "Charge" then
			rider.fx = chargeFx(entity)
			Poof.at(Vector3.new(p.X, 0, p.Z))
		elseif a == "Leap" then
			Dust.kick(entity.animal.model.PrimaryPart.CFrame, entity.animal.scale)
			rider.fx = vfx.rainbowFx(entity)
		elseif a == "Rattle" then
			rattleRing(p, cfg.Radius)
		elseif a == "Spikes" then
			vfx.spikeField(p, cfg, true)
		elseif a == "Frost" then
			rider.fx = vfx.frostFx(entity)
			rattleRing(p, cfg.Radius, vfx.FROST_TINT)
		elseif a == "Ink" then
			vfx.inkFx(entity)
			rattleRing(p, cfg.Radius, Color3.fromRGB(40, 30, 70))
		elseif a == "Boost" then
			Dust.kick(entity.animal.model.PrimaryPart.CFrame, entity.animal.scale)
		elseif a == "Breath" then
			entity.animal:playOnce("special")
			rider.fx = vfx.breathFx(entity, cfg, true)
		elseif a == "Missiles" then
			local s = entity.animal.size * entity.animal.scale
			local dir = if entity.animal.model.PrimaryPart.CFrame.LookVector.Z < 0 then -1 else 1
			vfx.Missiles.show(p.X, p.Y, p.Z, dir, cfg.Spread * s, cfg.Size * s, cfg.Duration, rider.vel.Magnitude)
		else
			Poof.at(Vector3.new(p.X, 0, p.Z))
		end
		rider.fxEnd = os.clock() + (cfg.Duration or holdTime(entity)) -- an UntilFull charge: at most a full bar
	end
end)

-- Every frame: the Rainbow Trail (Config.RainbowTrail), once bought, on whatever
-- you're riding, moved over when you swap mounts and gone when the ride ends.
vfx.trail = { parts = {} }
function vfx.updateTrail()
	local colors = Config.trailColors(Players.LocalPlayer)
	local want = if mount and colors and mount.animal.model.PrimaryPart then mount else nil
	if vfx.trail.entity == want and vfx.trail.colors == colors then
		return
	end
	for _, fx in vfx.trail.parts do
		fx:Destroy()
	end
	vfx.trail.entity, vfx.trail.colors = want, colors
	vfx.trail.parts = if want then vfx.rainbowFx(want, Config.RainbowTrail.Lifetime, Config.RainbowTrail.Width, colors) else {}
end

-- Every frame: each other rider's mount glides toward where it was last heard
-- of (carried on at the speed it was going), with them sat on it.
function vfx.updateRiders(dt)
	local now = os.clock()
	local camPos = camera.CFrame.Position
	local ease = 1 - math.exp(-12 * dt)
	for player, rider in vfx.riders do
		if now - rider.at > vfx.RIDER_STALE or not player.Parent then
			vfx.endRider(player)
			continue
		end
		if rider.fxEnd and now >= rider.fxEnd then
			vfx.riderFx(rider)
		end
		local ahead = rider.vel * math.min(now - rider.at, 0.25)
		local entity = rider.entity
		local char = player.Character
		if char ~= rider.char then
			rider.char = char
		end
		rider.player = player
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if entity then
			local root = entity.animal.model.PrimaryPart
			local want = rider.mountCF + ahead
			local cf = if rider.shown then root.CFrame:Lerp(want, ease) else want
			rider.shown = true
			local yaw = select(2, cf:ToEulerAnglesYXZ())
			entity.x, entity.z, entity.yaw, entity.speed = cf.X, cf.Z, yaw, rider.speed
			local near = (cf.Position - camPos).Magnitude < VIEW
			if math.abs(entity.animal.scale - rider.scale) > 0.02 then
				entity.animal:setScale(rider.scale)
			end
			root.CFrame = cf
			if near then
				animate(entity, dt, rider.speed, 0)
			end
			vfx.Burrow.rider(rider, entity) -- their Sandworm's burrow
			if hrp then
				hrp.Anchored = true
				hrp.CFrame = entity.animal:getSeatCFrame() * SEAT_OFFSET
			end
		elseif hrp and rider.tumble and now - rider.tumble.at < vfx.TUMBLE_TIME then
			hrp.Anchored = true
			hrp.CFrame = vfx.tumbleCFrame(rider.tumble, (now - rider.tumble.at) / vfx.TUMBLE_TIME)
		elseif hrp then
			rider.tumble = nil -- landed: on with where they say they are (lying there, till they go home)
			local want = rider.riderCF + ahead
			hrp.Anchored = true
			hrp.CFrame = if (hrp.Position - want.Position).Magnitude < 30 then hrp.CFrame:Lerp(want, ease) else want
		end
		vfx.updateRiderLasso(rider, dt)
	end
end

-- Another rider carrying an egg has it over their head (their "CarriedEgg"), as big
-- as it is for them ("CarriedEggScale": from a bigger nest), lifted clear of their head.
vfx.eggHeads = {} -- [player] = { kind, model }
function vfx.updateEggHeads()
	for other, rider in vfx.riders do
		local kind = other:GetAttribute("CarriedEgg")
		local head = vfx.eggHeads[other]
		if head and head.kind ~= kind then
			head.model:Destroy()
			vfx.eggHeads[other], head = nil, nil
		end
		local hrp = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if kind and hrp and not head and Animals:FindFirstChild(kind) then
			local egg = Egg.new(kind)
			local scale = other:GetAttribute("CarriedEggScale") or 1
			if scale ~= 1 then
				egg.model:ScaleTo(egg.size * scale)
				Egg.fitStuds(egg.model)
			end
			head = { kind = kind, model = egg.model, lift = 7 + math.max(Lasso.fitRadius(egg.model) - 2.5, 0) }
			head.model.Parent = workspace
			vfx.eggHeads[other] = head
		end
		if head and hrp and rider.lassoState ~= "twirl" then -- (twirling: on their lasso, vfx.updateRiderLasso)
			head.model:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, head.lift, 0)) * CFrame.Angles(0, os.clock() * 3, 0))
		end
	end
	for other, head in vfx.eggHeads do
		if not vfx.riders[other] then
			head.model:Destroy()
			vfx.eggHeads[other] = nil
		end
	end
end

-- Slow motion during the egg-grab close-up and the hero leap home.
local timeScale = 1

RunService.PreSimulation:Connect(function(dt)
	local slow = cutscene ~= nil or heroLeap ~= nil
	local slowTo = if heroLeap then Config.HomeSlowMo else Config.EggSlowMo
	local tr = vfx.tutorialRide -- (its slow motion: Client/Tutorial; Ride tells it what it needs)
	tr.canLasso = phase == "outbound" and actionTarget ~= nil and not transfer
	tr.sprinting = mount ~= nil and sprinting()
	timeScale += ((slow and slowTo or 1) * tr.timeScale - timeScale) * (1 - math.exp(-10 * dt))
	vfx.sounds.setTimeScale(timeScale) -- (the sounds slow with it: QM)
	if heroLeap then
		heroLeap.t = math.min(heroLeap.t + dt / Config.HomeHeroTime, 1)
	end
	dt *= timeScale
	updateHerd(dt, (slow and not cutscene) or tr.active) -- (the tutorial's herd is yours alone: no snapping back to the shared one, QM)
	updateFlung(dt)
	if phase == "boss" or phase == "turning" or phase == "return" or phase == "home" then -- (the boss, then after you home, in the leap's slow motion too)
		vfx.bossChase.update(dt, phase ~= "boss", mount and mount.x, mount and mount.z, mount and mount.speed)
	end
	vfx.hazards.update(dt, herd, mount, phase == "outbound" or phase == "turning" or phase == "return",
		mount and (vfx.sprintSpecial() or {}).Kind) -- (the Sludge's and Soul Horse's sprints lay trails)
	vfx.updateNuke()
	vfx.sendRide()
	vfx.updateSound()
	vfx.updateRiders(dt)
	vfx.updateTrail()
	vfx.updateEggHeads()
	Dust.update(dt)
	rideStick.set((phase == "outbound" or phase == "return") and mount ~= nil and not cutscene and not heroLeap)
	if phase == "idle" then
		vfx.updateHomeGuide() -- (to your fastest pet whenever you're at your base)
		-- On foot out on the course, a stampede animal running you down throws you
		-- like being bucked off (no cash on the fail screen: there was no ride).
		-- Never at the start line (QM, Oct 8): walking up to it is how you start a
		-- ride (WalkLimit holds you there), so only 8+ studs past it, where no
		-- animal at the line reaches.
		local hrp, humanoid = character()
		if hrp and humanoid.Health > 0 and hrp.Position.Z < START_LINE_Z - 8 then
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
		if starter and starter.drop then
			vfx.dropStarter(starter, dt)
		elseif starter then
			wander(starter, dt)
		end
		updateRideTarget()
		Outline.set(if rideShown and not player:GetAttribute("MergeView") then rideModel else nil) -- the pet RIDE will ride (not in the merge view: FuseMenu)
		vfx.updateMerge()
		return
	end
	if mount and mount ~= vfx.riddenMount then
		-- On a new animal: it goes in your animal dictionary (Hatchery.server, AnimalDex).
		vfx.riddenMount = mount
		vfx.tutorialRide.mounts += 1
		ReplicatedStorage:WaitForChild("Ridden"):FireServer(mount.kind)
	end
	if mount then
		mount.animal.sprinting = sprinting() -- (the Kraken gallops only at a sprint)
	end
	updateAbility(dt)
	vfx.updateScared(dt)
	vfx.updateAvoid(dt)
	vfx.updateShield(dt)
	vfx.updateSprint(dt)
	vfx.updateScale(dt)
	updateGuide()
	if mount then
		updateMount(dt)
	end
	updateRider(dt)
	-- What others see your lasso doing (sendRide; a throw at an animal is its own cue, "lasso").
	vfx.lassoState = if carried and carried.part and carried.stage == "held" then "twirl"
		elseif not (carried and carried.part) and not transfer and mount and (phase == "outbound" or phase == "return") then "swing"
		else ""
	if carried and carried.part and carried.stage == "held" then
		Lasso.twirl(dt, carried.part)
	elseif carried and carried.part then
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
		-- Landed: dust, then the egg reveal, then off the pet. The boss goes (QM, Oct 10).
		heroLeap = nil
		vfx.bossChase.stop()
		mount.speed = RUN_OUT_SPEED
		if phase ~= "finish" then
			mount.hop = 0
			place(mount, 0)
			Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
		end
		Hud.setCutscene(false)
		if phase == "finish" then
			-- Crossed the finish line: the animal you rode is yours, in your pen
			-- (Hatchery's FinishCourse), then back home to your pen.
			task.spawn(function()
				local ok, kind = pcall(finishCourse.InvokeServer, finishCourse, mount.kind)
				task.wait(ok and kind and vfx.newAnimal.show(kind) or 0.5)
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
			task.delay(kind and (if player:GetAttribute("Tutorial") then Hud.eggReveal(rarityOf(kind), kind) else vfx.newAnimal.show(kind)) or 0.5, function() -- (the animal's in your pen; the tutorial's an egg)
				if phase == "home" then
					finishRide(mount.x, mount.z)
				end
			end)
		end
	end
	actionTarget = findTarget()
	Outline.set(if actionTarget then actionTarget.animal.model else nil)
	updateHud()
end)

RunService:BindToRenderStep("RideCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local riding = mount and not cutscene and not heroLeap and (phase == "outbound" or phase == "return")
	vfx.speedFx.update(dt, if riding and sprinting() then mount.speed * (vfx.speedGain or 1) else 0) -- speed lines while sprinting, by the uncurved speed
	-- QM's speed lines (Config.SpeedLines): full on any sprint whatever the pet's speed,
	-- none otherwise (QM, Oct 11).
	vfx.speedLines.update(if riding and sprinting() then Config.SpeedLines.Speed else 0, dt)
	vfx.sprintTrail.update(if riding then player.Character else nil, riding and sprinting(), riding and mount.speed * (vfx.speedGain or 1) or 0) -- (off the rider: QM)
	vfx.returnVignette.update(dt, mount ~= nil and (phase == "turning" or phase == "return"))
	if not (phase == "boss" or phase == "turning" or phase == "return" or phase == "home") then
		vfx.bossChase.stop() -- (it moves with the ride, slow motion and all: below)
	end
	if phase == "idle" then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local targetYaw = mount and mount.yaw or camYaw
	camYaw += (targetYaw - camYaw) * (1 - math.exp(-5 * dt))
	local hrp = character()
	if cutscene and carried and carried.part and hrp then
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
	if vfx.scareAura and not kind then
		kind = "Rattle" -- the snake's scare keeps its haze the whole time (QM)
	end
	-- (the Beholder's pink, while it flies; nil, never false, while an ability runs: a false
	-- here counted as a haze and tinted every ability orange, Oct 5)
	local sprintHaze = if kind then nil else (vfx.sprintSpecial() or {}).Haze
	local hazed = kind == "Rattle" or kind == "Frost" or kind == "Hunt" or sprintHaze ~= nil
	if hazed then
		vfx.hazeColor = if kind == "Frost" then vfx.FROST_HAZE elseif kind == "Hunt" then vfx.HUNT_HAZE elseif sprintHaze then sprintHaze else vfx.RATTLE_HAZE
	end
	rattleHaze += ((if hazed then 1 else 0) - rattleHaze) * (1 - math.exp(-6 * dt))
	-- (the Robo Shark's hunt: a strong red, QM)
	Hud.setAbilityTint(rattleHaze * (if vfx.hazeColor == vfx.FROST_HAZE then 0.6 elseif vfx.hazeColor == vfx.HUNT_HAZE then 1 else 0.85), vfx.hazeColor)
	-- Bigger pets fill more of the view: the camera pulls back RideZoomPerTier
	-- times further for each size tier above small (Config.PetTiers).
	local zoomTo = if mount and mount.giant then Config.Shop.GiantHorse.Zoom elseif mount then Config.RideZoomPerTier ^ (vfx.mountTier() - 1) else 1
	vfx.camZoom = (vfx.camZoom or 1) + (zoomTo - (vfx.camZoom or 1)) * (1 - math.exp(-3 * dt))
	local sprintFov, sprintZoom = vfx.sprintCam.update(dt, mount ~= nil and (phase == "outbound" or phase == "return") and sprinting(), if phase == "return" and Config.ReturnCamFixed then Config.SprintCam.HorseSprint elseif mount then mount.speed * (vfx.speedGain or 1) else nil) -- (the run home's a sprint too: QM)
	local z = vfx.camZoom * sprintZoom
	local desired = vfx.bossChase.camera() -- (on the boss's face in its cutscene)
		or CFrame.lookAt((basis * CFrame.new(0, 38 * z, 18 * z)).Position, (basis * CFrame.new(0, 0, -24)).Position)
	-- (snappier while the Robo Shark hunts: it darts about too fast for the usual ease)
	camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-(if vfx.huntTarget then 30 else 8) * dt))
	-- The run home: over the shoulder (QM, Oct 10), pinned to the rider rather than eased
	-- after them (the ease above trailed far behind at the run home's speed).
	local shoulder = vfx.shoulderCam.blend(dt, mount ~= nil and hrp ~= nil and (phase == "turning" or phase == "return") and not vfx.bossChase.lingering(), mount ~= nil and hrp ~= nil)
	if shoulder > 0 and hrp then
		camera.CFrame = camera.CFrame:Lerp(vfx.shoulderCam.pose(hrp.Position, camYaw, z, hrp.Position.Y - (mount and mount.hop or 0), mount ~= nil and (mount.hop or 0) < -1), shoulder)
	end
	-- Racing home with the egg: a wider field of view to sell the speed, eased in.
	local fov = if phase == "return" then 70 + Config.ReturnFovKick else 70
	fov = math.max(fov, math.min(fov + vfx.speedFx.fovKick(), Config.SpeedFeel.MaxFov))
	-- (the sprint's widening on top, eased on its own: SprintCam; what's under it eases as before)
	local base = camera.FieldOfView - (vfx.sprintFov or 0)
	base += (fov - base) * (1 - math.exp(-3 * dt))
	camera.FieldOfView, vfx.sprintFov = base + sprintFov, sprintFov
end)

-- Continue on the fail screen: the server asks for the Robux (Shop.server) and
-- answers true once it's paid, false if it was cancelled. Paid: back on the same
-- kind of animal where you crashed, with your egg and this ride's cash, the
-- obstacles and animals right there knocked away and a moment of grace.
function vfx.askContinue()
	local revive = vfx.revive
	if phase == "ended" and revive and not revive.asked then
		revive.asked = true
		Hud.showContinue("waiting")
		ReplicatedStorage:WaitForChild("ContinueRide"):FireServer(-revive.z / STUDS_PER_METRE)
	end
end

ReplicatedStorage:WaitForChild("ContinueRide").OnClientEvent:Connect(function(paid)
	local revive = vfx.revive
	local hrp, humanoid = character()
	if phase ~= "ended" or not revive or not hrp then
		return
	end
	if not paid then
		revive.asked = false
		Hud.showContinue("ready")
		return
	end
	vfx.sounds.play("purchase")
	vfx.revive = nil
	for _, o in obstacles do
		if not o.smashed and Vector2.new(o.x - revive.x, o.z - revive.z).Magnitude < Config.ContinueClear then
			smash(o, revive.dir, if o.x >= revive.x then 1 else -1)
		end
	end
	for _, entity in allAnimals() do
		local dx = entity.x - revive.x
		if not entity.popping and math.abs(dx) < Config.ContinueClear and math.abs(entity.z - revive.z) < Config.ContinueClear then
			knock(entity, dx)
		end
	end
	tumble = nil
	mount = newEntity(revive.x, revive.z, revive.yaw, revive.kind)
	mount.animal:setSaddled(true)
	mount.speed = revive.speed
	carried = revive.carried
	if carried and carried.part then
		carried.part.Parent = workspace
	end
	phase, hold, grace = revive.phase, holdTime(mount), Config.ContinueGrace
	humanoid.PlatformStand = false
	humanoid.Sit = true
	Hud.resume(phase == "return")
end)

-- MERGE (QM, Oct 4; Shared/Merge): in RIDE's spot whenever you have two or more
-- of any kind (in the pen, and the one waiting on its spot), near a pet or not. It
-- merges every kind you have more than one of (Hatchery.server's MergePets).
function vfx.mergeKinds()
	local counts = {} -- [Fusion.key]: two of the same hybrid merge too
	if starter then
		counts[vfx.Fusion.key(starter.kind, starter.fuse)] = 1
	end
	for _, pet in PenPets.pets do
		local key = vfx.Fusion.key(pet.kind, pet.fuse)
		counts[key] = (counts[key] or 0) + 1
	end
	local kinds = {}
	for kind, n in counts do
		if n >= 2 then
			table.insert(kinds, kind)
		end
	end
	return kinds
end

function vfx.updateMerge()
	local hrp = character()
	local home = phase == "idle" and hrp ~= nil and hrp.Position.Z > START_LINE_Z -- in the base (QM), not out on the course
	Hud.showMerge(Config.MergeEnabled and home and #vfx.mergeKinds() > 0)
end

-- The just-merged starter popping out over the pen and dropping (PenPets.drop).
function vfx.dropStarter(entity, dt)
	local t = os.clock() - entity.drop.landAt
	if t >= 0 and not entity.dropPopped then
		entity.dropPopped = true
		vfx.sounds.play("merge_pop")
	end
	if t >= 0 then
		local floor = Ground.heightAt(entity.x, entity.z)
		local size, hop, landed = PenPets.drop(t, entity.drop.at.Y - floor)
		entity.animal.model.Parent = entity.dropParent
		entity.animal:setScale(entity.full * size)
		entity.hop = hop
		if landed then
			entity.drop, entity.hop = nil, 0
		end
	end
	place(entity, 0)
	animate(entity, dt, 0, 0)
end

-- Music and the gallop loop, every frame: the ride theme out riding, the base theme at
-- home; the gallop while you ride an animal that gallops (Config.GallopSound), louder
-- and quicker the faster it goes. Sprint's whoosh as it starts.
function vfx.updateSound()
	vfx.sounds.setMusic(if phase == "idle" then "base"
		elseif phase == "home" then "base" -- (over the line: back to the base's, cut with a scratch in reachHome)
		elseif phase == "turning" or phase == "return" then "home1" -- (the Meadow's, wherever you turned round: QM, Oct 10)
		else "ride")
	local riding = mount and (phase == "outbound" or phase == "return" or phase == "turning") and not transfer
	vfx.sounds.setGallop(riding and Config.GallopSound[mount.kind] ~= false and (mount.hop or 0) < 2,
		mount and mount.speed / Config.MountSpeed or 0)
	local now = (phase == "outbound" or phase == "return") and mount ~= nil and not transfer and sprinting() -- (the run home too: QM)
	-- The whoosh as you start sprinting, and again each time you break into a faster
	-- sprint tier (Config.SprintTiers; QM, Oct 9).
	local tier = if now then vfx.sprintCam.tier(mount.speed * (vfx.speedGain or 1)) else 0
	if now and not vfx.wasSprinting then
		vfx.sounds.play("sprint_whoosh", 0.32) -- (20% and 20% again under the usual 0.5: QM)
	elseif now and tier > (vfx.sprintTier or 0) then
		vfx.sounds.play("sprint_tier", 0.5) -- (its own sound: QM)
		vfx.skyFlash.flash() -- (and the sky flashes white: QM)
	end
	vfx.wasSprinting, vfx.sprintTier = now, tier
	-- (the wind loop while you sprint on a mount, the run home's too: Sounds.sprint_wind)
	vfx.sounds.setSprintWind(mount ~= nil and not transfer and (phase == "outbound" or phase == "return") and sprinting(),
		vfx.sprintCam.tierLoudness(tier)) -- (louder a step each sprint tier, up to 2x: QM)
end

-- MERGE (QM, Oct 4): every pet going into a merge is pulled up into one spot 2 m
-- over the pen (over the pet that stays: the one you ride, else the server's pick),
-- shrinking away as it goes, then a poof; the new, bigger pet pops out up there and
-- drops down (Pen.client, or the starter here: PenPets.merges).
Hud.onMerge = function()
	if phase ~= "idle" or not Config.MergeEnabled then
		return
	end
	local pen = myPen()
	local area = pen and pen:FindFirstChild("Area")
	for _, kind in vfx.mergeKinds() do
		local models, target, targetId = {}, nil, nil
		local starterIn = starter and vfx.Fusion.key(starter.kind, starter.fuse) == kind
		if starterIn then
			table.insert(models, starter.animal.model)
			target = starter.animal.model
		end
		for model, pet in PenPets.pets do
			if vfx.Fusion.key(pet.kind, pet.fuse) == kind and model.Parent then
				table.insert(models, model)
				-- (the server keeps the pen pet whose id sorts first)
				if not starterIn and (not targetId or pet.id < targetId) then
					target, targetId = model, pet.id
				end
			end
		end
		ReplicatedStorage:WaitForChild("MergePets"):FireServer(kind)
		if target then
			local base = target:GetPivot().Position
			local floor = if area then area.Position.Y - area.Size.Y / 2 else Ground.heightAt(base.X, base.Z)
			local at = Vector3.new(base.X, floor + PenPets.MERGE_UP, base.Z)
			PenPets.merges[kind] = { at = at, landAt = os.clock() + PenPets.MERGE_PULL }
			vfx.mergePull(models, at)
		end
	end
end

-- The pets going into a merge: copies of them fly up to `at` (backing off a touch
-- first), spinning and shrinking away, then a poof. The pets themselves are hidden
-- meanwhile (the server's merge removes them; if it never comes, they show again).
function vfx.mergePull(models, at)
	vfx.sounds.play("merge_whoosh")
	local copies = {}
	for _, model in models do
		local copy = model:Clone()
		if copy then
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
				end
			end
			copy.Parent = workspace
			table.insert(copies, { model = copy, from = copy:GetPivot(), scale = copy:GetScale() })
		end
		local function hide(amount)
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") or d:IsA("Decal") then
					d.LocalTransparencyModifier = amount
				end
			end
		end
		hide(1)
		task.delay(PenPets.MERGE_PULL + 3, function()
			if model.Parent then
				hide(0)
			end
		end)
	end
	local start = os.clock()
	local step
	step = RunService.RenderStepped:Connect(function()
		local a = math.min((os.clock() - start) / PenPets.MERGE_PULL, 1)
		local ease = a * a * (2.7 * a - 1.7) -- back in: a small pull back, then faster and faster
		for _, c in copies do
			local spin = CFrame.Angles(0, a * a * math.pi * 2, 0)
			c.model:PivotTo(CFrame.new(c.from.Position:Lerp(at, ease)) * spin * c.from.Rotation)
			c.model:ScaleTo(math.max(c.scale * (1 - 0.95 * a * a), 0.01))
		end
		if a >= 1 then
			step:Disconnect()
			for _, c in copies do
				c.model:Destroy()
			end
			Poof.at(at - Vector3.new(0, 1, 0))
			vfx.sounds.play("merge_poof")
		end
	end)
end
PenPets.pull = vfx.mergePull -- (FuseMenu pulls the two it fuses up the same way)

-- Nuke All from the shop (Shop.server's "Nukes"): spent on the next ride as it
-- starts. Every animal in sight is knocked flying, and for the whole ride every
-- obstacle within Config.Shop.NukeRange of you is blown away (back next ride).
function vfx.startNuke()
	if (player:GetAttribute("Nukes") or 0) < 1 or not mount then
		return
	end
	local ride = mount
	task.spawn(function()
		-- Spent on the server first (Shop.server's ledger), so it's used exactly once.
		local ok, spent = pcall(ReplicatedStorage:WaitForChild("UseNuke").InvokeServer, ReplicatedStorage.UseNuke)
		if ok and spent and mount == ride then
			vfx.nukeNow()
		end
	end)
end

function vfx.nukeNow()
	vfx.nuke = true
	Hud.flash("NUKE!", 1.5)
	for _, entity in allAnimals() do
		if entity ~= mount and not entity.popping and math.abs(entity.z - mount.z) < VIEW then
			knock(entity, entity.x - mount.x)
		end
	end
	vfx.updateNuke()
end

function vfx.updateNuke()
	if not vfx.nuke or not mount then
		return
	end
	local range = Config.Shop.NukeRange
	for _, o in obstacles do
		if not o.smashed and math.abs(o.z - mount.z) < range then
			smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		end
	end
end

-- The Giant Horse from the shop (Config.Shop.GiantHorse): as if you'd pressed RIDE,
-- but on a huge Horse at the start line, with no Hold drain, for one ride. Bought
-- while out on a ride (or on an earlier visit), it waits for you to be back on
-- foot at home; the ride is spent on the server (UseGiant) as it starts.
local giantWaiting = false
ReplicatedStorage:WaitForChild("ShopGrant").OnClientEvent:Connect(function(key)
	if key ~= "GiantHorse" or giantWaiting then
		return
	end
	giantWaiting = true
	while phase ~= "idle" or not character() do
		task.wait(0.5)
	end
	local ok, spent = pcall(ReplicatedStorage:WaitForChild("UseGiant").InvokeServer, ReplicatedStorage.UseGiant)
	giantWaiting = false
	local hrp, humanoid = character()
	if not (ok and spent) or not hrp or phase ~= "idle" then
		return
	end
	local giant = Config.Shop.GiantHorse
	humanoid:UnequipTools()
	clearRideTarget()
	mount = newEntity(0, SPAWN_Z - 6, 0, "Horse")
	mount.giant = true
	mount.feast = { count = 0, size = giant.Scale, speed = giant.Speed / statsOf("Horse").Speed }
	mount.animal:setScale(giant.Scale)
	mount.animal:setSaddled(true)
	leadFromZ, exitPath = mount.z - 8, nil
	phase, hold, grace, camYaw = "outbound", holdTime(mount), 1, 0
	coins = 0
	hrp.Anchored = true
	humanoid.Sit = true
	controls:Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	focus = Vector3.new(mount.x, 0, mount.z)
	Hud.show(true)
	Hud.setDistance("")
	Lasso.start(player.Character, nil, player:GetAttribute("PenLevel") or 1) -- (your pen level's lasso: LassoTiers)
	vfx.startNuke()
end)

Hud.init(onAction, goHome, rideFromHome, vfx.askContinue)

player.CharacterAdded:Connect(function()
	clearRideTarget() -- the prompt starts afresh for the new character (E)
	Hud.showRide(false)
	if phase ~= "idle" then
		cleanup()
		phase = "idle"
		controls:Enable()
		camera.CameraType = Enum.CameraType.Custom
		Hud.show(false)
		Hud.showHome(false)
		spawnStarter()
	end
end)

spawnStarter()

-- The server hands out pens just after joining: move the waiting pet to yours.
-- Picking another pet to ride (in the pen) swaps the waiting one; it's used from
-- the next ride if you're out on one.
for _, name in { "Pen", "RidePet", "RideMerged", "RideFuse", "RideStats", "RideTier" } do
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
