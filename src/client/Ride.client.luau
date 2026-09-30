-- The stampede ride, simulated locally: auto-run and steering, lasso transfers,
-- the Hold bar, the egg pickup and turnaround, the stampede, failure and the
-- home boundary.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
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
-- Egg nests: shared stock kept by the server (Nests.server.luau). Each Nest in
-- World.Nests shows the egg its "Egg" attribute names ("" = empty, taken by
-- someone). EggSpot marks the egg's centre. The egg is a rigged model so it can
-- twitch in the nest; it turns its face toward the approaching rider.
local EGG_TWITCH_EVERY = { 2, 4 } -- seconds between twitches, random in this range
local takeEgg = ReplicatedStorage:WaitForChild("TakeEgg")
local bankCoins = ReplicatedStorage:WaitForChild("BankCoins")
local deliverEgg = ReplicatedStorage:WaitForChild("DeliverEgg")
local ridePet = ReplicatedStorage:WaitForChild("RidePet")
local waitingEggs = {} -- [nest] = { egg, kind, nest, nextTwitch }
local nearEgg -- the waiting egg in grab range, while actionTarget is "egg"

local function rarityOf(kind)
	return require(Animals[kind]).Rarity
end

-- Shows the egg the server says is in `nest`, if any.
local function showNestEgg(nest)
	local kind = nest:GetAttribute("Egg") or ""
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

-- Obstacle footprints from each obstacle's lowest part (a tree's trunk, a rock's base).
local obstacles = {}
for _, model in world.Obstacles:GetChildren() do
	local base
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and (not base or part.Position.Y < base.Position.Y) then
			base = part
		end
	end
	table.insert(obstacles, { x = base.Position.X, z = base.Position.Z, hx = base.Size.X / 2, hz = base.Size.Z / 2 })
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
			endZ = if b == #Config.Biomes then END_Z else endZ + 2,
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
local herdFolder = Instance.new("Folder")
herdFolder.Name = "Herd"
herdFolder.Parent = workspace


-- An entity is an animal plus its position on the course.
-- yaw 0 faces -z (outbound); yaw pi faces +z (home).
local phase = "idle" -- idle | outbound | turning | return | home | ended
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

-- Every kind of animal in any biome's stampede, with its share of the whole herd
-- (for filling the pools).
local classes, shares = {}, {}
for _, stream in streams do
	for _, kind in stream.kinds do
		classes[kind.name] = classes[kind.name] or require(Animals[kind.name])
		pools[kind.name] = pools[kind.name] or {}
		shares[kind.name] = (shares[kind.name] or 0) + kind.weight / stream.total / #streams
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

local function place(entity, yawOffset)
	entity.animal.model.PrimaryPart.CFrame = CFrame.new(entity.x, entity.rootY + (entity.hop or 0), entity.z)
		* CFrame.Angles(0, entity.yaw + yawOffset, 0)
end

-- Scale and hop of an animal `t` seconds into its pop-in: 0 -> overshoot ~1.2 -> 1.
local function popScale(t)
	return 1 - math.exp(-12.6 * t) * math.cos(26 * t)
end

local function popHop(t)
	return if t < POP_HOP_TIME then POP_HOP * math.sin(math.pi * t / POP_HOP_TIME) else 0
end

local function blockedAt(x, z, padX, padZ)
	for _, o in obstacles do
		if math.abs(o.x - x) < o.hx + padX and math.abs(o.z - z) < o.hz + padZ then
			return true
		end
	end
	return false
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
	for _, o in obstacles do
		local reach = o.hx + 6
		local d = x0 - o.x
		if math.abs(d) < reach then
			local side = if d >= 0 then 1 else -1
			if math.abs(o.x + side * reach) > EDGE then
				side = -side
			end
			-- Eases out over the 36 studs before the obstacle and back over the 24 after.
			local w = smoothstep(o.z + o.hz + 40, o.z + o.hz + 4, z) * smoothstep(o.z - o.hz - 28, o.z - o.hz - 4, z)
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
	-- pen can be ridden too (PenPets).
	starter = newEntity(spot.X, spot.Z, penYaw(), player:GetAttribute("RidePet") or Config.DefaultPet)
	setClickable(starter.animal.model, true)
end

-- One prompt, moved onto whichever pet RIDE rides. It draws nothing; E still
-- works, and the RIDE button shows while it's in range.
local rideSpot = Instance.new("Attachment")
rideSpot.Name = "RideSpot"
local ridePrompt = Instance.new("ProximityPrompt")
ridePrompt.ActionText = "Ride"
ridePrompt.RequiresLineOfSight = false
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

-- Flat distance from `at` to the edge of the pet (roughly), so big pets count as near.
local function petDistance(model, at)
	local middle, size = model:GetBoundingBox()
	local d = Vector2.new(middle.X - at.X, middle.Z - at.Z).Magnitude
	return d - math.max(size.X, size.Z) / 2, d
end

-- Every frame at home: bind RIDE to the pet you clicked, else the nearest.
local function updateRideTarget()
	local hrp = character()
	local target
	if hrp then
		local pets = homePets()
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
			-- Measured from the middle of the pet, with more reach for big ones (the
			-- Snake's root is at its tail end, 18 studs from its head).
			local root = target.PrimaryPart
			local middle, size = target:GetBoundingBox()
			rideSpot.CFrame = root.CFrame:ToObjectSpace(middle)
			ridePrompt.MaxActivationDistance = 8 + math.max(size.X, size.Z) / 2
			rideSpot.Parent = root
		else
			rideSpot.Parent = nil
		end
	end
end

local function clearRideTarget()
	rideModel, pickedPet = nil, nil
	rideSpot.Parent = nil
end

local function rideFromHome()
	if phase == "idle" and rideModel and rideShown then
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
	clearRideTarget()
	if fromPen then
		ridePet:FireServer(fromPen.id)
		starter.animal.model:Destroy()
		starter = nil
		mount = newEntity(spot.X, spot.Z, 0, fromPen.kind)
	else
		mount, starter = starter, nil
		setClickable(mount.animal.model, false)
	end
	mount.animal:setSaddled(true)
	leadFromZ = spot.Z - 8
	exitX = penExitX()
	mount.x, mount.z, mount.yaw, mount.speed, mount.latVel = spot.X, spot.Z, 0, 0, 0
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
	spawnStarter()
end

local function fail(reason)
	if phase == "ended" then
		return
	end
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
	local egg = Egg.new(nearEgg.egg.kind)
	local part = egg.model
	part:PivotTo(nearEgg.egg.model:GetPivot())
	part.Parent = workspace
	nearEgg.egg.model.Parent = nil
	takeEgg:FireServer(nearEgg.nest) -- empties the nest for everyone
	carried = { part = part, kind = nearEgg.kind, stage = "throw", t = 0, spin = rng:NextNumber() < 0.5 and -1 or 1 }
	phase, turnT = "turning", 0
	Hud.setAction(nil)
	Hud.setHold(nil)
	-- Cutscene: the camera snaps in on the egg and the UI hides until it's reeled in.
	cutscene = { shake = 0 }
	Hud.setCutscene(true)
end

local function eggInRange(waiting)
	local eggPos = waiting.nest.EggSpot.Position
	return waitingEggs[waiting.nest] == waiting and waiting.egg.model.Parent ~= nil
		and Vector2.new(eggPos.X - mount.x, eggPos.Z - mount.z).Magnitude < Config.LassoRange
end

local function animalInRange(entity)
	if entity == mount or entity.popping then
		return nil
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
	elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA
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
	return phase == "outbound" and (sprintKey or Hud.sprintHeld())
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
local POOL_START = 32
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

local function putInPool(entity)
	entity.animal.model.Parent = nil
	entity.animal:setScale(1)
	entity.hop, entity.popping = 0, nil
	table.insert(pools[entity.kind], entity)
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

local function moveAnimal(entity, x, z, speed, dt)
	local lat = (x - entity.x) / math.max(dt, 1e-3)
	entity.x, entity.z, entity.speed = x, z, speed
	place(entity, -math.atan2(lat, math.max(speed, 1)))
	animate(entity, dt, speed, lat / 12)
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
	local seen = {}
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
			local z = stream.spawnZ - dist
			local entity = herd[key]
			-- The animal being lassoed runs on past the end until it's caught.
			local lassoed = entity and transfer and transfer.target == entity
			if (z <= stream.endZ and not lassoed) or math.abs(z - camZ) > VIEW then
				continue
			end
			local x = laneX(p.x, z)
			if not entity then
				entity = takeFromPool(key, x, z, p.kind)
				if not entity then
					continue
				end
				herd[key] = entity
				if age < 0.15 then
					Poof.at(Vector3.new(x, 0, z))
				end
			end
			seen[key] = true
			-- Pops in at the start, shrinks into nothing over the last SHRINK studs.
			local shrink = if lassoed then 1 else math.clamp((z - stream.endZ) / SHRINK, 0, 1)
			if age < POP_TIME or shrink < 1 then
				entity.popping = true
				entity.hop = if age < POP_TIME then popHop(age) else 0
				entity.animal:setScale((if age < POP_TIME then popScale(age) else 1) * shrink)
			elseif entity.popping then
				entity.popping, entity.hop = nil, 0
				entity.animal:setScale(1)
			end
			-- A nudge from a passing rider fades back out; it never changes the schedule.
			entity.dodge *= math.exp(-1.5 * dt)
			if snapped then
				entity.x = x + entity.dodge -- a snap doesn't swing them sideways
			end
			moveAnimal(entity, math.clamp(x + entity.dodge, -EDGE, EDGE), z, speed, dt)
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
		end
	end
	for i = #strays, 1, -1 do
		local entity = strays[i]
		local yaw = entity.yaw * math.exp(-3 * dt) -- swings round to face downfield
		local turn = math.clamp((entity.yaw - yaw) / math.max(dt, 1e-3) / 3, -1, 1)
		entity.yaw = yaw
		entity.speed += (entity.cruise - entity.speed) * (1 - math.exp(-2 * dt))
		local look = CFrame.Angles(0, yaw, 0).LookVector
		local z = entity.z + look.Z * entity.speed * dt
		-- Shrinks away at the end of the biome it's in, like the stampede.
		local endZ = streamAt(entity.z).endZ
		if z <= endZ then
			entity.animal.model:Destroy()
			table.remove(strays, i)
			continue
		end
		local shrink = math.clamp((z - endZ) / SHRINK, 0, 1)
		entity.popping = if shrink < 1 then true else nil
		entity.animal:setScale(shrink)
		local x = entity.x + look.X * entity.speed * dt
		if math.abs(yaw) > 0.05 then
			entity.lane = x
		end
		-- Swerves round obstacles like the rest of the stampede.
		local lat = math.clamp(laneX(entity.lane, z) - x, -1, 1) * 12
		entity.x, entity.z = math.clamp(x + lat * dt, -EDGE, EDGE), z
		place(entity, -math.atan2(lat, math.max(entity.speed, 1)))
		animate(entity, dt, entity.speed, turn + lat / 12)
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
		mount.hop = math.sin(math.pi * t) ^ 0.6 * Config.HomeLeapHeight
		mount.latVel = 0
		place(mount, 0)
		animate(mount, dt, if t < 1 then mount.speed else 0, 0)
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

local function checkRide(dt)
	grace = math.max(grace - dt, 0)
	if phase == "outbound" and mount.z < 0 and not transfer then
		hold -= dt * (if sprinting() then Config.SprintDrain else 1)
		if hold <= 0 then
			return fail("BUCKED OFF")
		end
	end
	if mount.z < -Config.CourseLength + 40 then
		return fail("TOO FAR!")
	end
	if grace <= 0 and blockedAt(mount.x, mount.z, 1.3, 2.4) then
		return fail("CRASH!")
	end
	for _, entity in allAnimals() do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if not entity.popping and math.abs(dx) < 2.6 and math.abs(dz) < 5 then
			if phase == "return" and grace <= 0 then
				return fail("CRASH!")
			elseif phase == "outbound" and entity.n then
				entity.dodge = math.clamp(entity.dodge + (if dx >= 0 then 1 else -1) * 12 * dt, -6, 6)
			end
		end
	end
	if phase == "return" and mount.z >= START_LINE_Z - LEAP_FROM then
		-- Home with the egg: the hero leap over the line (updateMount), then the reveal.
		phase = "home"
		heroLeap = { t = 0, fromZ = mount.z, toZ = START_LINE_Z + Config.HomeLandPast }
		Hud.setCutscene(true)
	end
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
		local ground = Vector3.new(from.X + tumble.side * 9, LIE_HEIGHT, from.Z - 6 * tumble.dir)
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
			local earned = Config.RarityCoins[mount.animal.Rarity]
			coins += earned
			Hud.setCoins(coins)
			local point = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4, 0))
			Hud.coinPopup(Vector2.new(point.X, point.Y), earned)
		end
		return
	end
	if mount then
		if not humanoid.Sit then
			humanoid.Sit = true
		end
		hrp.CFrame = mount.animal:getSeatCFrame() * SEAT_OFFSET
		focus = Vector3.new(mount.x, 0, mount.z)
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
	Hud.setSprint(phase == "outbound")
	if phase == "outbound" then
		Hud.setHold(mount and hold / holdTime(mount) or 1)
		Hud.setDistance(string.format("%d m", math.max(0, math.floor(-focus.Z / STUDS_PER_METRE))))
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
	local slow = cutscene ~= nil or heroLeap ~= nil
	local slowTo = if heroLeap then Config.HomeSlowMo else Config.EggSlowMo
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
	updateHerd(dt, slow and not cutscene)
	Dust.update(dt)
	if phase == "idle" then
		if starter then
			wander(starter, dt)
		end
		updateRideTarget()
		Outline.set(if rideShown or pickedPet then rideModel else nil) -- the pet RIDE will ride
		Outline.update()
		return
	end
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
		mount.hop = 0
		mount.speed = RUN_OUT_SPEED
		place(mount, 0)
		Dust.kick(mount.animal.model.PrimaryPart.CFrame, mount.animal.scale)
		Hud.setCutscene(false)
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
	local desired = CFrame.lookAt((basis * CFrame.new(0, 38, 18)).Position, (basis * CFrame.new(0, 0, -24)).Position)
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

-- Fill the pools a few animals per frame, so joining doesn't hitch: each kind
-- gets its share of POOL_START by its weight in the biomes' herds (at least a couple).
task.spawn(function()
	local built = 0
	local names = {}
	for name in shares do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		for _ = 1, math.max(2, math.round(POOL_START * shares[name])) do
			putInPool(newEntity(0, 0, 0, name))
			built += 1
			if built % 4 == 0 then
				task.wait()
			end
		end
	end
end)
