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
		-- (EggSpot is a 1x egg's centre: a bigger egg sits higher so it stays on the nest)
		waiting.egg.model:PivotTo(nest.EggSpot.CFrame * CFrame.new(0, 1.6 * (waiting.egg.size - 1), 0) * CFrame.Angles(0, math.pi, 0))
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
-- The Godlands' terrain pieces come and go with the tracks built round you
-- (Client/GodlandsStream): in and out of the list and the slices.
function slices.remove(list, o, zMin, zMax)
	for slice = math.floor(zMin / slices.SIZE), math.floor(zMax / slices.SIZE) do
		local i = list[slice] and table.find(list[slice], o)
		if i then
			table.remove(list[slice], i)
		end
	end
end
function slices.pieces(list, added)
	for _, o in list do
		if added then
			table.insert(obstacles, o)
			slices.add(slices.swerve, o, o.z - o.hz - slices.SWERVE_AFTER, o.z + o.hz + slices.SWERVE_BEFORE)
			slices.add(slices.block, o, o.z - o.hz - slices.BLOCK_PAD, o.z + o.hz + slices.BLOCK_PAD)
		else
			local i = table.find(obstacles, o)
			if i then
				table.remove(obstacles, i)
			end
			slices.remove(slices.swerve, o, o.z - o.hz - slices.SWERVE_AFTER, o.z + o.hz + slices.SWERVE_BEFORE)
			slices.remove(slices.block, o, o.z - o.hz - slices.BLOCK_PAD, o.z + o.hz + slices.BLOCK_PAD)
		end
	end
end

-- Size tiers a pet gains on the way home with the egg.
local RETURN_TIER_BONUS = 1

local function tierOf(kind)
	return Config.PetTiers[kind] or 1
end

-- An obstacle a bigger pet plowed into flies up and away and fades; it's back
-- for the next ride (cleanup). Everyone else sees it too (Riders.server), and
-- on their screens it's back a few seconds later (remote).
local SMASH_TIME = 0.7
local function smash(o, dir, side, remote)
	o.smashed = true
	if not remote then
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
local EDGE = Config.CourseHalfWidth - 4
-- The stampede runs all the time, whether anyone is riding or not. Each biome has
-- its own stream: its animal n pops in at the biome's start (just behind the start
-- line, or on the line from the biome before) at n * HerdSpawnEvery seconds on the
-- server clock, with its lane, speed and kind drawn from a generator seeded by n,
-- and runs to the biome's end, where it shrinks away. So everyone sees the same
-- stream, and riding never changes it: an animal you lasso just leaves it.
local START_LINE_Z = if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else -2
local SPAWN_Z = START_LINE_Z + 4
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
-- The endless Godlands has a stream per track instead (endless below), at b past the
-- other biomes', wrapping round well within BIOME_KEYS.
local BIOME_KEYS = 1024

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
-- The endless Godlands (Shared/Godlands): a stream per track, each running from
-- its track's line to the next, made as the camera nears it (endless.stream(k)).
local endless = { Godlands = require(ReplicatedStorage.Shared.Godlands) }
-- A stream from spawnZ to endZ of the herd's kinds; name labels its line in the Output.
function endless.newStream(spawnZ, endZ, herd, name)
	local s = {
		spawnZ = spawnZ,
		endZ = endZ,
		kinds = {},
		total = 0,
	}
	local slowest = math.huge
	for kind in herd do
		slowest = math.min(slowest, herdSpeed(kind))
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
		if b == endless.Godlands.biome then
			endless.b, endless.herd = b, biome.Herd
			print(string.format("[Herd] %s: a stream per %d-stud track from z %.0f on", biome.Name, endless.Godlands.length, startZ))
			continue
		end
		streams[b] = endless.newStream(
			if b == 1 then SPAWN_Z else startZ - 2,
			if b == #Config.Biomes then FINISH_Z + 2 else endZ + 2, -- the course stops at the finish line
			biome.Herd,
			biome.Name
		)
	end
end
-- Track k's stream, at streams[endless.b + k % 900] (made now if it isn't there).
-- Its animals pop in at the track's line and shrink away at the next one.
function endless.stream(k)
	local b = endless.b + k % 900
	local s = streams[b]
	if not s or s.k ~= k then
		local z0 = endless.Godlands.segmentStart(k)
		s = endless.newStream(z0 - 2, z0 - endless.Godlands.length + 2, endless.herd)
		s.k = k
		streams[b] = s
	end
	return s
end
-- Keeps streams for the tracks within reach of the camera at z, and only those.
function endless.near(z)
	if not endless.b then
		return
	end
	local hi = endless.Godlands.segmentAt(z - VIEW)
	local lo = endless.Godlands.segmentAt(z + VIEW) or 0
	for b, s in streams do
		if s.k and (not hi or s.k < lo or s.k > hi) then
			streams[b] = nil
		end
	end
	for k = lo, hi or -1 do
		endless.stream(k)
	end
end
if endless.b then
	endless.stream(0) -- so the pools below count its animals
end

-- Where an animal in biome b (at z) stops: its stream's end.
local function streamAt(z)
	local k = endless.Godlands.segmentAt(z)
	if k and endless.b then
		return endless.stream(k)
	end
	return streams[WorldColors.biomeAt(z)]
end

local rng = Random.new()

do
	local function watchNest(nest)
		showNestEgg(nest)
		nest:GetAttributeChangedSignal("Egg"):Connect(function()
			showNestEgg(nest)
		end)
	end
	for _, nest in world.Nests:GetChildren() do
		watchNest(nest)
	end
	world.Nests.ChildAdded:Connect(watchNest) -- the EventNest (Events.server) can come in late
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
local warpLevel -- /biome: the biome you were put in, so its gate (and those before) let you through
local transfer, tumble, carried
local vfx = {} -- ability VFX bits and state (one table: this chunk is at Luau's 200-local limit)
vfx.rideSync = ReplicatedStorage:WaitForChild("RideSync") -- multiplayer rides (Riders.server)
vfx.rideCue = ReplicatedStorage:WaitForChild("RideCue")
vfx.godlands = require(script.Parent.GodlandsStream) -- the endless Godlands, built round the camera
vfx.godlands.onPieces = slices.pieces
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
	mount, transfer, tumble, warpLevel = nil, nil, nil, nil
	if carried then
		carried.part:Destroy()
		carried = nil
	end
	if vfx.revive and vfx.revive.carried then
		vfx.revive.carried.part:Destroy() -- the egg kept for a Continue that wasn't bought
	end
	vfx.revive = nil
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
		if earned and earned > 0 and model.PrimaryPart then
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

-- Every frame at home: bind RIDE to the pet you clicked, else the nearest (your
-- pets, or a stampede animal just in at the start line).
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
			rideOffset, rideSize = Outline.box(target)
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
		vfx.rideCue:FireServer("take", fromHerd.n)
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
	mount.feast = nil -- (the Blue Crab starts every ride at its own size)
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

-- Testing (/biome, see Hatchery.server): drops you just inside biome b's start
-- line riding a new `kind`, whatever you were doing. Your own pet stays home.
ReplicatedStorage:WaitForChild("BiomeWarp").OnClientEvent:Connect(function(b, kind)
	local hrp, humanoid = character()
	if not hrp or Tutorial.busy then
		return
	end
	if phase ~= "idle" then
		cleanup()
		Hud.showHome(false)
		Hud.show(false) -- clears a fail screen's banner
	end
	humanoid:UnequipTools()
	clearRideTarget()
	local z = if b == 1 then SPAWN_Z - 6 else WorldColors.biomeStart(b) - 10 -- the meadow's starts at the start line
	mount = newEntity(0, z, 0, kind)
	mount.animal:setSaddled(true)
	warpLevel = b
	leadFromZ, exitX = z - 8, nil
	phase, hold, grace, camYaw = "outbound", holdTime(mount), 1, 0
	coins = 0
	hrp.Anchored = true
	humanoid.Sit = true
	humanoid.PlatformStand = false
	controls:Disable()
	camera.CameraType = Enum.CameraType.Scriptable
	focus = Vector3.new(mount.x, 0, mount.z)
	Hud.show(true)
	Hud.setDistance("")
	Lasso.start(player.Character)
end)

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
	Hud.setTip(tip) -- in place of the "+$N" the fail screen shows
	local hrp, humanoid = character()
	local dir = (phase == "return" or phase == "home") and 1 or -1 -- travelDir() is defined further down
	-- Continue (Config.ContinueTiers): a crash or buck-off on the way out or
	-- back can be bought off, picking up right here on the same kind of animal,
	-- with the egg. Not into a locked gate, and not in the tutorial.
	local gate = WorldColors.gateZ(math.max(player:GetAttribute("PenLevel") or 1, warpLevel or 1))
	vfx.revive = nil
	if mount and (reason == "CRASH!" or reason == "BUCKED OFF") and (phase == "outbound" or phase == "return")
		and not (phase == "outbound" and mount.z < gate + 2.4) and not Tutorial.active
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
			carried.part.Parent = nil
		else
			carried.part:Destroy()
		end
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
			Hud.showContinue(if vfx.revive then "ready" else nil)
		end
	end)
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

local function startTransfer(target)
	local hrp = character()
	local old = mount
	release(old)
	mount = nil
	transfer = { target = target, old = old, t = 0, stage = "throw", from = hrp.Position }
	vfx.rideCue:FireServer("lasso", target.n or false)
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
	return WorldColors.gateZ(math.max(player:GetAttribute("PenLevel") or 1, warpLevel or 1))
end

-- On the way out, a trail of arrows on the ground from your pet to the nearest
-- egg still waiting ahead of you (not behind a locked gate). In the tutorial's
-- lasso step it leads to the nearest animal ahead instead (Tutorial.guideTo).
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
	local want = Tutorial.guideTo()
	if phase == "outbound" and not cutscene and want == "animal" then
		local best = math.huge
		for _, entity in allAnimals() do
			if entity ~= mount and not entity.popping and entity.z < at.Z - guide.AHEAD and entity.z > gateZ() then
				local d = (Vector2.new(entity.x, entity.z) - Vector2.new(at.X, at.Z)).Magnitude
				if d < best then
					target, best = Vector3.new(entity.x, 0, entity.z), d
				end
			end
		end
	elseif phase == "outbound" and not cutscene and want == "egg" then
		-- Riding an event's kind of animal while its egg is out (Events.server), the
		-- arrows lead to that egg instead; the event's egg is never the nearest egg
		-- otherwise. (If it's behind you or a locked gate, back to the nearest egg.)
		local event = world.Nests:FindFirstChild("EventNest")
		local chasing = event and waitingEggs[event] and mount and mount.kind == world:GetAttribute("EventKind")
		for _, eventOnly in if chasing then { true, false } else { false } do
			local best = math.huge
			for nest, waiting in waitingEggs do
				local spot = nest:FindFirstChild("EggSpot")
				if (nest == event) == eventOnly and spot and waiting.egg.model.Parent
					and spot.Position.Z < at.Z - guide.AHEAD and spot.Position.Z > gateZ() then
					local d = (Vector2.new(spot.Position.X, spot.Position.Z) - Vector2.new(at.X, at.Z)).Magnitude
					if d < best then
						target, best = spot.Position, d
					end
				end
			end
			if target then
				break
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
	if z <= FINISH_Z + 2 and not lassoed then
		-- Ran the whole course: shrinks away at the finish line, for good.
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
	local shrink = if lassoed then 1 else math.clamp((z - FINISH_Z - 2) / SHRINK, 0, 1)
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
	entity.dodge *= math.exp(-1.5 * dt)
	moveAnimal(entity, math.clamp(x + entity.dodge, -EDGE, EDGE), z, speed, dt, shown)
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
	endless.near(camZ)
	vfx.godlands.update(camZ)
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
	vfx.updateEvent(dt, seen, inView)
	for key, entity in herd do
		if not seen[key] then
			herd[key] = nil
			putInPool(entity)
		end
	end
	for key in plans do
		local stream = streams[key % BIOME_KEYS + 1] -- (gone if it was a Godlands track's left behind)
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
vfx.FishWave = require(script.Parent.FishWave) -- the School of Fish's wave
vfx.Missiles = require(script.Parent.Missiles) -- the Robo Shark's missiles
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
	vfx.scareAura = { mount = mount, left = cfg.ScareTime, radius = cfg.Radius, restorePer = cfg.RestorePer, scared = {} }
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
		vfx.scareAura = nil
		return
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and not entity.popping and dx * dx + dz * dz < aura.radius * aura.radius then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -aura.radius, aura.radius)
			else
				entity.lane = math.clamp((entity.lane or entity.x) + away * 60 * dt, -EDGE, EDGE)
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
vfx.PLAIN = { Frost = true, Boost = true, Grow = true, Ink = true, Crabwalk = true, Breath = true, Feast = true, Missiles = true }

-- The Blue Crab's Feast (Config.Abilities): what it has broken since the last one, and
-- how much bigger and faster it has grown this ride. nil for every other pet.
function vfx.feastOf(entity)
	local cfg = entity and Config.Abilities[entity.kind]
	if not cfg or cfg.Kind ~= "Feast" then
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
	return if cfg and phase == "outbound" and not transfer and sprinting() then cfg else nil
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
function vfx.inkBlast(dt, cfg)
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if entity ~= mount and dx * dx + dz * dz < cfg.Radius * cfg.Radius then
			local away = if dx >= 0 then 1 else -1
			if entity.n then
				entity.dodge = math.clamp(entity.dodge + away * 60 * dt, -cfg.Radius, cfg.Radius)
			else
				entity.lane = math.clamp(entity.lane + away * 60 * dt, -EDGE, EDGE)
			end
		end
	end
end

-- Breath (the Loong): fire pours out of its mouth from FireFrom to FireTo seconds into
-- its "special" animation. A placeholder flame (QM will put the real fire in, in
-- Studio): a ParticleEmitter named LoongFire on the jaw, blowing straight ahead.
function vfx.breathFx(entity, cfg)
	local model = entity.animal.model
	local jaw = model:FindFirstChild("jawBone") or model.PrimaryPart
	local at = Instance.new("Attachment")
	at.Name = "LoongFireAt"
	at.CFrame = CFrame.new(0, 0, -2 * entity.animal.size) * CFrame.Angles(math.pi / 2, 0, 0) -- out the front, emitting along -Z
	at.Parent = jaw
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "LoongFire"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 140)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 10)),
	})
	fire.LightEmission = 0.8
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 14) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Lifetime = NumberRange.new(0.5, 0.8)
	fire.Speed = NumberRange.new(cfg.Range * 1.2, cfg.Range * 1.5)
	fire.SpreadAngle = Vector2.new(12, 12)
	fire.EmissionDirection = Enum.NormalId.Bottom -- the attachment is turned so Bottom is ahead
	fire.Rate = 220
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

-- Breath: while the fire pours, everything in the lane ahead is burnt away, obstacles
-- and animals whatever their size.
function vfx.breathBlast(active)
	local cfg = active.cfg
	if active.t < cfg.FireFrom or active.t > cfg.FireTo then
		return
	end
	local dir = travelDir()
	local half = cfg.Width / 2
	for _, o in obstacles do
		local ahead = (o.z - mount.z) * dir
		if not o.smashed and ahead > -4 and ahead < cfg.Range and math.abs(o.x - mount.x) < half + o.hx then
			smash(o, dir, if o.x >= mount.x then 1 else -1)
		end
	end
	for _, entity in allAnimals() do
		local ahead = (entity.z - mount.z) * dir
		if entity ~= mount and not entity.popping and ahead > 0 and ahead < cfg.Range and math.abs(entity.x - mount.x) < half then
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
		old.animal:setScale(if old.scaleAnim.shrink then 1 else old.scaleAnim.size) -- let go mid-pop: finish it
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
	local from, to = if anim.shrink then anim.size else anim.from or 1, if anim.shrink then 1 else anim.size
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
		vfx.sprintFx, vfx.burrowSpray = {}, nil
		if old ~= mount then
			vfx.burrowDepth = nil
		end
		-- Loom (the Loong) swells while Sprint is held, and pops back when it's let go.
		if vfx.sprintKind == "Loom" and old then
			if old == mount then
				old.scaleAnim = { shrink = true, t = 0, size = old.animal.scale }
			else
				old.scaleAnim = nil
				old.animal:setScale(1)
			end
		end
		if kind == "Loom" then
			mount.scaleAnim = { t = 0, size = cfg.Grow }
		end
		if kind == "Ram" then
			vfx.sprintFx = chargeFx(mount, 0.35) -- QM: 0.7x the half-size wind it had
		elseif kind == "Crabwalk" then
			vfx.sprintFx = chargeFx(mount, 0.5, math.pi / 2) -- sideways, like the crab
		elseif kind == "Burrow" then
			local spray = Instance.new("Part")
			spray.Anchored, spray.CanCollide, spray.CanQuery, spray.CanTouch = true, false, false, false
			spray.Transparency = 1
			spray.Size = Vector3.new(4, 1, 4)
			spray.Parent = workspace
			local dirt = Instance.new("ParticleEmitter")
			dirt.Texture = "rbxasset://textures/particles/smoke_main.dds"
			local ground = Config.Biomes[WorldColors.biomeAt(mount.z)].GroundColors
			dirt.Color = ColorSequence.new(ground[1], ground[2])
			dirt.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
			dirt.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			dirt.Lifetime = NumberRange.new(0.6, 1)
			dirt.Speed = NumberRange.new(2, 5)
			dirt.SpreadAngle = Vector2.new(80, 80)
			dirt.Rate = 25
			dirt.Parent = spray
			vfx.moundAt = nil -- where the last mound went up
			vfx.sprintFx = { spray }
			vfx.burrowSpray = spray
		end
		vfx.sprintMount, vfx.sprintKind = mount, kind
	end
	local special = mount and Config.SprintSpecials[mount.kind]
	if not special or activeAbility() then
		return
	end
	if kind == "Loom" then
		vfx.inkBlast(dt, special) -- the animals round it scatter
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
		local floor = Ground.heightAt(mount.x, mount.z)
		vfx.burrowSpray.CFrame = CFrame.new(mount.x, floor + 0.5, mount.z)
		-- A sand mound pushes up over the worm every few studs; the ones behind
		-- slowly sink back into the floor (QM's pick).
		local here = Vector2.new(mount.x, mount.z)
		if not vfx.moundAt or (here - vfx.moundAt).Magnitude > vfx.MOUND_EVERY then
			vfx.moundAt = here
			vfx.mound(mount.x, mount.z, floor)
		end
	end
end

vfx.MOUND_EVERY = 4.5 -- studs between the Sandworm's mounds (QM: a bit more spread out than 3)
vfx.MOUND_LIFE = 1.8 -- seconds a mound takes to sink away
-- Three mound shapes, one picked at random each time (QM): blocks of sand as
-- { x, z, height, width } from the worm.
vfx.MOUNDS = {
	{ { 0, 0, 2.2, 6 }, { -2.2, 0.8, 1.4, 4 }, { 2.2, -0.8, 1.4, 4 } },
	{ { 0, 0.5, 2.6, 5 }, { -1.6, -1.6, 1.6, 4.5 }, { 2.4, 0.6, 1, 3.5 }, { -2.6, 1.4, 0.8, 3 } },
	{ { 0.4, 0, 1.8, 7 }, { -1.8, -1.2, 1.2, 3.5 }, { 1.4, 1.8, 1.5, 3 } },
}
function vfx.mound(x, z, floor)
	local ground = Config.Biomes[WorldColors.biomeAt(z)].GroundColors
	local size = rng:NextNumber(0.8, 1.2) -- a little bigger or smaller each time
	for k, shape in vfx.MOUNDS[rng:NextInteger(1, #vfx.MOUNDS)] do
		local s = { shape[1] * size, shape[2] * size, shape[3] * size, shape[4] * size }
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Color = ground[(k % 2) + 1]
		p.Material = Enum.Material.SmoothPlastic
		p.Size = Vector3.new(s[4], s[3], s[4] * 0.8)
		p.CFrame = CFrame.new(x + s[1], floor + s[3] / 2, z + s[2]) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		p.Parent = workspace
		local sunk = Vector3.new(p.Size.X * 0.6, 0.05, p.Size.Z * 0.6)
		TweenService:Create(p, TweenInfo.new(vfx.MOUND_LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = sunk,
			CFrame = p.CFrame - Vector3.new(0, s[3] / 2, 0),
		}):Play()
		task.delay(vfx.MOUND_LIFE, function()
			p:Destroy()
		end)
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
	local root = entity.animal.model.PrimaryPart
	if active.cfg.Tier then
		-- Back to its own size: a springy pop down if it's still the mount.
		entity.scaleAnim = if entity == mount then { shrink = true, t = 0, size = entity.animal.scale } else nil
		if entity ~= mount then
			entity.animal:setScale(1)
		end
	end
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
	vfx.rideCue:FireServer("ability", cfg.Kind)
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
		mount.scaleAnim = { t = 0, size = Config.TierGrowth ^ math.max(cfg.Tier - tierOf(mount.kind), 0) }
	elseif cfg.Kind == "Ink" then
		vfx.inkFx(mount)
		rattleRing(Vector3.new(mount.x, 0, mount.z), cfg.Radius, Color3.fromRGB(40, 30, 70))
	elseif cfg.Kind == "Wave" then
		a.active.wave = vfx.FishWave.new(mount.z, travelDir(), EDGE)
	elseif cfg.Kind == "Missiles" then
		hold = math.min(hold + holdTime(mount) * cfg.Restore, holdTime(mount)) -- QM: every launch refills 10% of the Hold bar
		a.active.missiles = vfx.launchMissiles(mount, cfg, travelDir())
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
		hold = math.min(hold + holdTime(mount) * (cfg.Restore or 0), holdTime(mount)) -- QM: refills 20% of the Hold bar
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
		if active.cfg.Kind == "Ink" then
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
		Hud.setAbility(if active.cfg.Duration then 1 - active.t / active.cfg.Duration else hold / holdTime(mount), nil)
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
		targetSpeed *= Config.SprintSpeed * ((vfx.sprintSpecial() or {}).SpeedBoost or 1) -- the Blue Crab's crab walk: faster still
	end
	targetSpeed *= if mount.feast then mount.feast.speed else 1 -- the Blue Crab, grown by its Feasts
	local rate = phase == "home" and 30 or (dir < 0 and 90 or 40) -- snappy into and out of a sprint
	local ability = activeAbility()
	if ability and (ability.cfg.Kind == "Charge" or ability.cfg.Kind == "Boost" or ability.cfg.Kind == "Grow" or ability.cfg.Kind == "Crabwalk") then
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
	local sideways = if (ability and ability.cfg.Kind == "Crabwalk") or (vfx.sprintSpecial() or {}).Kind == "Crabwalk" then math.pi / 2 else 0 -- a crab scuttles sideways
	place(mount, math.atan2(mount.latVel * dir, math.max(mount.speed, 1)) + sideways)
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
	if ability and vfx.PLAIN[ability.cfg.Kind] then
		ability = nil -- these still use Hold and can still crash (Config.Abilities)
	end
	if ability and ability.cfg.UntilFull and not Tutorial.active then
		-- The Snack Yak's charge refills Hold as fast as it usually drains, and ends
		-- once the bar is full.
		hold += dt
		if hold >= holdTime(mount) then
			hold = holdTime(mount)
			endAbility(mount)
			ability = nil
		end
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
	-- A bigger pet plows through smaller obstacles; its own size or bigger stops it.
	-- Racing home with the egg, every pet counts as a size bigger against obstacles
	-- (RETURN_TIER_BONUS); against stampede animals it's its own size.
	local myTier = vfx.mountTier()
	local tier = myTier + (if phase == "return" or phase == "turning" then RETURN_TIER_BONUS else 0)
	while true do
		local o = blockedAt(mount.x, mount.z, 1.3, 2.4)
		if not o or o.tier >= tier then
			break
		end
		smash(o, travelDir(), if o.x >= mount.x then 1 else -1)
		vfx.broke()
	end
	if grace <= 0 and blockedAt(mount.x, mount.z, 1.3, 2.4, tier) then
		return fail("CRASH!")
	end
	if phase == "outbound" and mount.z < gateZ() + 2.4 then
		return fail("CRASH!") -- a locked gate
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if not entity.popping and not entity.event and math.abs(dx) < 2.6 and math.abs(dz) < 5 then
			local trample = kind == "Trample" and tierOf(entity.kind) < special.BelowTier -- the Kraken's sprint
			-- Racing home on the Icebringer, an animal frozen in ice smashes whatever its size (QM).
			local shatter = phase == "return" and entity.frostFx ~= nil and (Config.Abilities[mount.kind] or {}).Kind == "Frost"
			if ((phase == "return" or trample) and tierOf(entity.kind) < myTier) or kind == "Crabwalk" or shatter then -- (the +1 is for obstacles only)
				knock(entity, dx) -- (the Blue Crab's crab walk knocks everything)
				vfx.broke()
			elseif phase == "return" and grace <= 0 then
				return fail("CRASH!")
			elseif phase == "outbound" and entity.n then
				entity.dodge = math.clamp(entity.dodge + (if dx >= 0 then 1 else -1) * 12 * dt, -6, 6)
				if special and special.RestorePer and entity.scaredOffBy ~= mount then
					-- The Unicorn's sprint: each animal it scares out of its way refills Hold (once).
					entity.scaredOffBy = mount
					hold = math.min(hold + holdTime(mount) * special.RestorePer, holdTime(mount))
				end
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
				vfx.rideCue:FireServer("take", target.n)
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
	-- The animal LASSO would catch, top left (Hud.setSelected).
	Hud.setSelected(if phase == "outbound" and typeof(actionTarget) == "table" and not cutscene then actionTarget.kind else nil)
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
		if root then mount.kind else "",
		if root then root.CFrame else hrp.CFrame,
		hrp.CFrame,
		if mount then mount.speed else 0,
		if mount then mount.animal.scale else 1
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
	if rider.rope then
		rider.rope:Destroy()
	end
	local hrp = rider.char and rider.char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false -- back to where the server has it
	end
end

vfx.rideSync.OnClientEvent:Connect(function(player, kind, mountCF, riderCF, speed, scale)
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
	if rider.kind ~= kind then
		vfx.dropMount(rider)
	end
	if kind ~= "" and not rider.entity and Animals:FindFirstChild(kind) then
		local p = mountCF.Position
		rider.entity = newEntity(p.X, p.Z, 0, kind)
		rider.entity.animal:setSaddled(true)
		rider.entity.dodge = 0
		rider.kind = kind
		rider.shown = nil
	end
end)

-- A rider's lasso: a rope from their hand to the animal's neck while it flies out
-- and they're pulled across.
function vfx.remoteRope(rider, entity)
	if rider.rope then
		rider.rope:Destroy()
	end
	local hand = rider.char and rider.char:FindFirstChild("RightGripAttachment", true)
	local root = entity.animal.model.PrimaryPart
	if not hand or not root then
		return
	end
	local knot = Instance.new("Attachment")
	knot.Parent = root
	local rope = Instance.new("Beam")
	rope.Attachment0, rope.Attachment1 = hand, knot
	rope.Width0, rope.Width1 = 0.28, 0.28
	rope.Color = ColorSequence.new(Color3.fromRGB(222, 184, 120))
	rope.FaceCamera = true
	rope.Parent = knot
	rider.rope = knot
	task.delay(THROW_TIME + TRANSFER_TIME, function()
		if rider.rope == knot then
			rider.rope = nil
		end
		knot:Destroy()
	end)
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
	if what == "take" or what == "lasso" or what == "knock" then
		local key = tonumber(a)
		local entity = key and herd[key]
		if entity and transfer and transfer.target == entity then
			return -- you're lassoing it too: it stays yours
		end
		if what == "lasso" then
			if rider then
				vfx.dropMount(rider) -- their old mount runs on, as yours does
				if entity then
					vfx.remoteRope(rider, entity)
				end
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
		local cfg = Config.Abilities[entity.kind]
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
			rider.fx = vfx.breathFx(entity, cfg)
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
			if hrp then
				hrp.Anchored = true
				hrp.CFrame = entity.animal:getSeatCFrame() * SEAT_OFFSET
			end
		elseif hrp then
			local want = rider.riderCF + ahead
			hrp.Anchored = true
			hrp.CFrame = if (hrp.Position - want.Position).Magnitude < 30 then hrp.CFrame:Lerp(want, ease) else want
		end
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
	-- The waiting eggs twitch now and then: something's alive in there (only
	-- the ones near enough to see).
	local camPos = camera.CFrame.Position
	for nest, waiting in waitingEggs do
		if waiting.egg.model.Parent then
			waiting.nextTwitch -= dt
			if waiting.nextTwitch <= 0 and (nest.EggSpot.Position - camPos).Magnitude > VIEW then
				waiting.nextTwitch = rng:NextNumber(EGG_TWITCH_EVERY[1], EGG_TWITCH_EVERY[2])
			elseif waiting.nextTwitch <= 0 then
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
	vfx.sendRide()
	vfx.updateRiders(dt)
	Dust.update(dt)
	rideStick.set((phase == "outbound" or phase == "return") and mount ~= nil and not cutscene and not heroLeap)
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
		Hud.setSelected(if rideShown and rideModel then vfx.kindOf(rideModel) else nil) -- and its card, top left
		return
	end
	if mount and mount ~= vfx.riddenMount then
		-- On a new animal: it goes in your animal dictionary (Hatchery.server, AnimalDex).
		vfx.riddenMount = mount
		ReplicatedStorage:WaitForChild("Ridden"):FireServer(mount.kind)
	end
	updateAbility(dt)
	vfx.updateScared(dt)
	vfx.updateSprint(dt)
	vfx.updateScale(dt)
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
	if actionTarget == "egg" then
		Outline.set(nearEgg.egg.model, Outline.NEST)
	else
		Outline.set(if actionTarget then actionTarget.animal.model else nil)
	end
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
	-- Bigger pets fill more of the view: the camera pulls back RideZoomPerTier
	-- times further for each size tier above small (Config.PetTiers).
	local zoomTo = if mount then Config.RideZoomPerTier ^ (vfx.mountTier() - 1) else 1
	vfx.camZoom = (vfx.camZoom or 1) + (zoomTo - (vfx.camZoom or 1)) * (1 - math.exp(-3 * dt))
	local z = vfx.camZoom
	local desired = CFrame.lookAt((basis * CFrame.new(0, 38 * z, 18 * z)).Position, (basis * CFrame.new(0, 0, -24)).Position)
	camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-8 * dt))
	-- Racing home with the egg: a wider field of view to sell the speed, eased in.
	local fov = if phase == "return" then 70 + Config.ReturnFovKick else 70
	camera.FieldOfView += (fov - camera.FieldOfView) * (1 - math.exp(-3 * dt))
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
	if carried then
		carried.part.Parent = workspace
	end
	phase, hold, grace = revive.phase, holdTime(mount), Config.ContinueGrace
	humanoid.PlatformStand = false
	humanoid.Sit = true
	Hud.resume(phase == "return")
end)

Hud.init(onAction, goHome, rideFromHome, vfx.askContinue)

player.CharacterAdded:Connect(function()
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
