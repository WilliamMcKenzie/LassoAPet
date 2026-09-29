-- The stampede ride, simulated locally: auto-run and steering, lasso transfers,
-- the Hold bar, the egg pickup and turnaround, the stampede, failure and the
-- home boundary.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Hud = require(script.Parent.Hud)
local Lasso = require(script.Parent.Lasso)
local Poof = require(script.Parent.Poof)
local Dust = require(script.Parent.Dust)
local Outline = require(script.Parent.Outline)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end
-- EggSpot marks the centre of the waiting egg. The egg is a rigged model so
-- it can twitch in the nest; it turns its face toward the approaching rider.
local eggSpot = world.Nest.EggSpot
local nestEgg = Egg.new("Horse")
nestEgg.model:PivotTo(eggSpot.CFrame * CFrame.Angles(0, math.pi, 0))
nestEgg.model.Parent = world.Nest
local EGG_TWITCH_EVERY = { 2, 4 } -- seconds between twitches, random in this range
local nextTwitch = 1

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
-- The stampede runs all the time, whether anyone is riding or not: animal n pops
-- in just behind the start line at n * HerdSpawnEvery seconds on the server clock,
-- with its lane and speed drawn from a generator seeded by n, and runs to the far
-- wall. So everyone sees the same stream, and riding never changes it: an animal
-- you lasso just leaves it.
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
local LIFE = START_AFTER + START_EASE + (SPAWN_Z - END_Z) / Config.HerdSpeedMin

local rng = Random.new()
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
local actionTarget
local turnT, camYaw = 0, 0
local focus = Vector3.zero
local touchSteer, padSteer = 0, 0
local coins = 0 -- cash gained this ride; what the Gold icon shows while riding
local touchStart = {}

-- The kinds of animal in the stampede and how often each turns up (Config.HerdMix).
local kinds, mixTotal = {}, 0
for name, weight in Config.HerdMix do
	table.insert(kinds, { name = name, class = require(Animals[name]), weight = weight })
	mixTotal += weight
end
table.sort(kinds, function(a, b)
	return a.name < b.name -- the same order on every client, so every client picks the same animals
end)
local classes = {}
for _, kind in kinds do
	classes[kind.name] = kind.class
	pools[kind.name] = {}
end
classes.Horse = classes.Horse or require(Animals.Horse) -- the starter

local function newEntity(x, z, yaw, kind)
	kind = kind or "Horse"
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
	entity.cruise = rng:NextNumber(Config.HerdSpeedMin, Config.HerdSpeedMax)
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

local function plan(n)
	local p = plans[n]
	if not p then
		local r = Random.new(n)
		p = { x = r:NextNumber(-EDGE, EDGE), speed = r:NextNumber(Config.HerdSpeedMin, Config.HerdSpeedMax) }
		local pick = r:NextNumber(0, mixTotal)
		for _, kind in kinds do
			p.kind = kind.name
			pick -= kind.weight
			if pick < 0 then
				break
			end
		end
		plans[n] = p
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

local function setEggInNest(visible)
	nestEgg.model.Parent = if visible then world.Nest else nil
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
	Hud.setCutscene(false)
	Outline.set(nil)
	setEggInNest(true)
end

local startRide, ridePrompt

local function spawnStarter()
	starter = newEntity(Config.StarterSpot.X, Config.StarterSpot.Z, 0)
	starter.animal:setSaddled(true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ride"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Style = Enum.ProximityPromptStyle.Custom -- draws nothing; E still works, and the RIDE button shows while it's in range
	prompt.Parent = starter.animal.model.PrimaryPart
	prompt.Triggered:Connect(function()
		prompt:Destroy()
		startRide()
	end)
	prompt.PromptShown:Connect(function()
		Hud.showRide(true)
	end)
	prompt.PromptHidden:Connect(function()
		Hud.showRide(false)
	end)
	ridePrompt = prompt
end

local function rideFromHome()
	if phase == "idle" and ridePrompt and ridePrompt.Parent then
		ridePrompt:Destroy()
		startRide()
	end
end

startRide = function()
	local hrp, humanoid = character()
	if not hrp then
		return
	end
	if not starter then
		spawnStarter()
	end
	mount, starter = starter, nil
	mount.animal:setSaddled(true)
	mount.x, mount.z, mount.yaw, mount.speed, mount.latVel = Config.StarterSpot.X, Config.StarterSpot.Z, 0, 0, 0
	phase, hold, grace, camYaw = "outbound", Config.HoldTime, 0, 0
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
	finishRide(Config.StarterSpot.X, Config.StarterSpot.Z)
end

local function startTransfer(target)
	local hrp = character()
	local old = mount
	release(old)
	mount = nil
	transfer = { target = target, old = old, t = 0, stage = "throw", from = hrp.Position }
end

local function grabEgg()
	local egg = Egg.new(nestEgg.kind)
	local part = egg.model
	part:PivotTo(nestEgg.model:GetPivot())
	part.Parent = workspace
	setEggInNest(false)
	carried = { part = part, stage = "throw", t = 0, spin = rng:NextNumber() < 0.5 and -1 or 1 }
	phase, turnT = "turning", 0
	Hud.setAction(nil)
	Hud.setHold(nil)
	-- Cutscene: the camera snaps in on the egg and the UI hides until it's reeled in.
	cutscene = { shake = 0 }
	Hud.setCutscene(true)
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
	if input.UserInputType == Enum.UserInputType.Touch then
		touchStart[input] = input.Position.X
	elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA
		or input.KeyCode == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then
		onAction()
	end
end)

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

local function findTarget()
	if phase ~= "outbound" or transfer or not mount then
		return nil
	end
	local eggPos = eggSpot.Position
	if Vector2.new(eggPos.X - mount.x, eggPos.Z - mount.z).Magnitude < Config.EggRange then
		return "egg"
	end
	local best, bestScore = nil, math.huge
	for _, entity in allAnimals() do
		if entity.popping then
			continue
		end
		local ahead = mount.z - entity.z
		local dx = entity.x - mount.x
		local dist = math.sqrt(ahead * ahead + dx * dx)
		if ahead > -3 and dist < Config.LassoRange then
			local score = dist + math.abs(dx) * 0.5
			if score < bestScore then
				best, bestScore = entity, score
			end
		end
	end
	return best
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

local function moveAnimal(entity, x, z, speed, dt)
	local lat = (x - entity.x) / math.max(dt, 1e-3)
	entity.x, entity.z, entity.speed = x, z, speed
	place(entity, -math.atan2(lat, math.max(speed, 1)))
	animate(entity, dt, speed, lat / 12)
end

-- The stampede follows the shared server clock. Only while this player is slowed
-- down near the egg does their copy run on the ride's slowed time; as soon as the
-- slowdown ends (or the egg cutscene starts, with the camera on the egg), every
-- animal snaps straight back to where it is on the shared clock.
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
	local oldest, newest = math.ceil((herdClock - LIFE) / every), math.floor(herdClock / every)
	local camZ = camera.CFrame.Position.Z
	for n = oldest, newest do
		if taken[n] then
			continue
		end
		local p = plan(n)
		local age = herdClock - n * every
		local dist, speed = run(p.speed, math.max(age - START_AFTER, 0))
		local z = SPAWN_Z - dist
		local entity = herd[n]
		if z <= END_Z or math.abs(z - camZ) > VIEW then
			if entity then
				if z <= END_Z then
					Poof.at(Vector3.new(entity.x, 0, entity.z))
				end
				herd[n] = nil
				putInPool(entity)
			end
			continue
		end
		local x = laneX(p.x, z)
		if not entity then
			entity = takeFromPool(n, x, z, p.kind)
			if not entity then
				continue
			end
			herd[n] = entity
			if age < 0.15 then
				Poof.at(Vector3.new(x, 0, z))
			end
		end
		if age < POP_TIME then
			entity.popping = true
			entity.hop = popHop(age)
			entity.animal:setScale(popScale(age))
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
	for n, entity in herd do
		if n < oldest then
			herd[n] = nil
			putInPool(entity)
		end
	end
	for n in plans do
		if n < oldest then
			plans[n], taken[n] = nil, nil
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
		if z <= END_Z then
			Poof.at(Vector3.new(entity.x, 0, entity.z))
			entity.animal.model:Destroy()
			table.remove(strays, i)
			continue
		end
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
		mount.speed = Config.MountSpeed * (1 - math.sin(turnT * math.pi) * 0.7)
		mount.latVel *= math.exp(-6 * dt)
		local look = CFrame.Angles(0, mount.yaw, 0).LookVector
		mount.x = math.clamp(mount.x + look.X * mount.speed * dt, -EDGE, EDGE)
		mount.z += look.Z * mount.speed * dt
		if turnT >= 1 then
			phase, grace = "return", Config.TurnGrace
			mount.speed = Config.ReturnSpeed
		end
		place(mount, 0)
		animate(mount, dt, mount.speed, eased < 1 and -0.6 or 0)
		return
	end

	local targetSpeed = phase == "home" and 0 or (dir < 0 and Config.MountSpeed or Config.ReturnSpeed)
	local rate = phase == "home" and 30 or 40
	mount.speed += math.clamp(targetSpeed - mount.speed, -rate * dt, rate * dt)
	local steer = phase == "home" and 0 or readSteer()
	local targetLat = steer * Config.SteerSpeed * -dir
	mount.latVel += (targetLat - mount.latVel) * (1 - math.exp(-Config.SteerResponse * dt))
	local edge = mount.z > 0 and Config.HomeHalfWidth - 4 or EDGE
	mount.x = math.clamp(mount.x + mount.latVel * dt, -edge, edge)
	mount.z += dir * mount.speed * dt
	place(mount, math.atan2(mount.latVel * dir, math.max(mount.speed, 1)))
	animate(mount, dt, mount.speed, mount.latVel * -dir / Config.SteerSpeed)
end

local function checkRide(dt)
	grace = math.max(grace - dt, 0)
	if phase == "outbound" and mount.z < 0 and not transfer then
		hold -= dt
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
	if phase == "return" and mount.z >= 0 then
		phase = "home"
		Hud.flash("EGG SAVED!", 2)
		task.delay(2.5, function()
			if phase == "home" then
				finishRide(mount.x, mount.z)
			end
		end)
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
			mount.animal:setSaddled(true)
			mount.latVel = 0
			hold, grace = Config.HoldTime, Config.LandingGrace
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
	if phase == "outbound" then
		Hud.setHold(mount and hold / Config.HoldTime or 1)
		Hud.setDistance(string.format("%d m", math.max(0, math.floor(-focus.Z / STUDS_PER_METRE))))
		if actionTarget == "egg" then
			Hud.setAction("GRAB EGG", true)
		else
			Hud.setAction("LASSO", actionTarget ~= nil)
		end
	end
	if phase == "turning" or phase == "return" or phase == "home" then
		local metres = math.max(0, -focus.Z / STUDS_PER_METRE)
		Hud.setVignette(math.clamp(metres / Config.VignetteFadeMetres, 0, 1))
	end
end

-- Slow motion while the egg is in grab range, so there's time to decide.
local timeScale = 1

RunService.PreSimulation:Connect(function(dt)
	local slow = (phase == "outbound" and actionTarget == "egg") or cutscene ~= nil
	timeScale += ((slow and Config.EggSlowMo or 1) - timeScale) * (1 - math.exp(-10 * dt))
	dt *= timeScale
	-- The waiting egg twitches now and then: something's alive in there.
	if nestEgg.model.Parent then
		nextTwitch -= dt
		if nextTwitch <= 0 then
			nestEgg:play("twitch")
			nextTwitch = rng:NextNumber(EGG_TWITCH_EVERY[1], EGG_TWITCH_EVERY[2])
		end
		nestEgg:update(dt)
	end
	updateHerd(dt, slow and not cutscene)
	Dust.update(dt)
	if phase == "idle" then
		if starter then
			place(starter, 0)
			starter.animal:update(dt, 0, 0)
		end
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
	actionTarget = findTarget()
	Outline.set(if actionTarget == "egg" then nestEgg.model elseif actionTarget then actionTarget.animal.model else nil)
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
	local desired = CFrame.lookAt((basis * CFrame.new(0, 38, 18)).Position, (basis * CFrame.new(0, 0, -24)).Position)
	camera.CFrame = camera.CFrame:Lerp(desired, 1 - math.exp(-8 * dt))
	camera.FieldOfView += (70 - camera.FieldOfView) * (1 - math.exp(-8 * dt))
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

-- Fill the pools a few animals per frame, so joining doesn't hitch: each kind
-- gets its share of POOL_START by its HerdMix weight (at least a couple).
task.spawn(function()
	local built = 0
	for _, kind in kinds do
		for _ = 1, math.max(2, math.round(POOL_START * kind.weight / mixTotal)) do
			putInPool(newEntity(0, 0, 0, kind.name))
			built += 1
			if built % 4 == 0 then
				task.wait()
			end
		end
	end
end)
