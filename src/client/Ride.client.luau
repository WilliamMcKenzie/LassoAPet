-- The stampede ride, simulated locally: auto-run and steering, lasso transfers,
-- the Hold bar, the egg pickup and turnaround, the oncoming herd, failure and
-- the home boundary.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animal = require(ReplicatedStorage.Shared.Animals.Horse)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Hud = require(script.Parent.Hud)
local Lasso = require(script.Parent.Lasso)

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
local EDGE = Config.CourseHalfWidth - 4

local rng = Random.new()
local herdFolder = Instance.new("Folder")
herdFolder.Name = "Herd"
herdFolder.Parent = workspace

local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.fromRGB(255, 230, 120)
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Enabled = false
highlight.Parent = workspace

-- An entity is an animal plus its position on the course.
-- yaw 0 faces -z (outbound); yaw pi faces +z (home).
local phase = "idle" -- idle | outbound | turning | return | home | ended
local starter, mount, loose
local herd = {}
local hold, grace = 0, 0
local transfer, tumble, carried
local cutscene -- TAKE EGG close-up: { shake } while the egg is lassoed and reeled in
local actionTarget
local turnT, camYaw = 0, 0
local focus = Vector3.zero
local touchSteer, padSteer = 0, 0
local coins = 0 -- cash gained this ride; what the Gold icon shows while riding
local touchStart = {}

local function newEntity(x, z, yaw)
	local animal = Animal.new()
	local entity = {
		animal = animal,
		rootY = animal.model.PrimaryPart.Position.Y,
		x = x,
		z = z,
		yaw = yaw or 0,
		speed = 0,
		latVel = 0,
		targetX = x,
		turn = 0,
	}
	animal:setSaddled(false)
	animal.model.Parent = herdFolder
	return entity
end

local function place(entity, yawOffset)
	entity.animal.model.PrimaryPart.CFrame = CFrame.new(entity.x, entity.rootY, entity.z)
		* CFrame.Angles(0, entity.yaw + yawOffset, 0)
end

local function blockedAt(x, z, padX, padZ)
	for _, o in obstacles do
		if math.abs(o.x - x) < o.hx + padX and math.abs(o.z - z) < o.hz + padZ then
			return true
		end
	end
	return false
end

local function pickX(z)
	local x = 0
	for _ = 1, 8 do
		x = rng:NextNumber(-EDGE, EDGE)
		if not blockedAt(x, z, 5, 12) then
			break
		end
	end
	return x
end

local function respawn(entity, zNear, zFar)
	entity.z = rng:NextNumber(math.min(zNear, zFar), math.max(zNear, zFar))
	entity.x = pickX(entity.z)
	entity.targetX = entity.x
	entity.speed = rng:NextNumber(Config.HerdSpeedMin, Config.HerdSpeedMax)
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
	for _, entity in herd do
		entity.animal.model:Destroy()
	end
	table.clear(herd)
	if mount then
		mount.animal.model:Destroy()
	end
	if loose then
		loose.animal.model:Destroy()
	end
	mount, loose, transfer, tumble = nil, nil, nil, nil
	if carried then
		carried.part:Destroy()
		carried = nil
	end
	Lasso.stop()
	cutscene = nil
	highlight.Adornee = nil
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
	for _ = 1, Config.HerdCount do
		local entity = newEntity(0, 0)
		respawn(entity, -30, -Config.HerdAhead)
		table.insert(herd, entity)
	end
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
	local hrp = character()
	phase = "ended"
	cutscene = nil
	Hud.setCutscene(false)
	loose, mount = mount, nil
	if loose then
		loose.animal:setSaddled(false)
	end
	transfer = nil
	if carried then
		carried.part:Destroy()
		carried = nil
	end
	highlight.Adornee = nil
	tumble = { t = 0, from = hrp.CFrame, side = rng:NextNumber() < 0.5 and -1 or 1 }
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
	old.animal:setSaddled(false)
	old.targetX = old.x
	old.speed = rng:NextNumber(Config.HerdSpeedMin, Config.HerdSpeedMax)
	table.insert(herd, old)
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
	-- Clear the herd right in front of the turnaround so the return starts fair.
	for _, entity in herd do
		if entity.z > mount.z - 10 and entity.z < mount.z + 110 then
			respawn(entity, mount.z + 160, math.min(mount.z + Config.HerdAhead, -30))
		end
	end
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
	for _, entity in herd do
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

-- Keeps a reachable mount ahead of the player on the way out: if nothing will
-- come into lasso range soon, the nearest animal ahead drifts into the player's lane.
local function ensureReachable()
	local nearest, nearestAhead = nil, math.huge
	for _, entity in herd do
		local ahead = mount.z - entity.z
		if ahead > 8 and ahead < 90 and math.abs(entity.x - mount.x) < 30 then
			return
		end
		if ahead > 8 and ahead < nearestAhead then
			nearest, nearestAhead = entity, ahead
		end
	end
	if not nearest or nearestAhead > 160 then
		-- Nothing close enough to steer over: bring the animal furthest behind up ahead.
		nearest = herd[1]
		for _, entity in herd do
			if entity.z > nearest.z then
				nearest = entity
			end
		end
		nearest.z = mount.z - rng:NextNumber(110, 140)
		nearest.x = math.clamp(mount.x + rng:NextNumber(-20, 20), -EDGE, EDGE)
	end
	nearest.targetX = math.clamp(mount.x + rng:NextNumber(-12, 12), -EDGE, EDGE)
	nearest.speed = Config.HerdSpeedMin - 6
end

local function updateHerd(dt)
	local returning = phase == "return" or phase == "home"
	for _, entity in herd do
		entity.z -= entity.speed * dt
		for _, o in obstacles do
			local ahead = entity.z - o.z
			if ahead > 0 and ahead < 40 and math.abs(o.x - entity.x) < o.hx + 4 then
				entity.targetX = o.x + (entity.x >= o.x and 1 or -1) * (o.hx + 6)
			end
		end
		entity.targetX = math.clamp(entity.targetX, -EDGE, EDGE)
		local lat = math.clamp(entity.targetX - entity.x, -1, 1) * 12
		entity.x += lat * dt
		if returning then
			if entity.z < focus.Z - Config.HerdBehind then
				if focus.Z + Config.HerdAhead * 0.6 < -30 then
					respawn(entity, focus.Z + Config.HerdAhead * 0.6, math.min(focus.Z + Config.HerdAhead, -30))
				end
			end
		elseif entity.z > focus.Z + Config.HerdBehind then
			respawn(entity, focus.Z - Config.HerdAhead * 0.5, math.max(focus.Z - Config.HerdAhead, -Config.CourseLength + 40))
		end
		place(entity, -math.atan2(lat, entity.speed))
		entity.animal:update(dt, entity.speed, lat / 12)
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
		mount.animal:update(dt, mount.speed, eased < 1 and -0.6 or 0)
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
	mount.animal:update(dt, mount.speed, mount.latVel * -dir / Config.SteerSpeed)
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
	for _, entity in herd do
		local dx, dz = entity.x - mount.x, entity.z - mount.z
		if math.abs(dx) < 2.6 and math.abs(dz) < 5 then
			if phase == "return" and grace <= 0 then
				return fail("CRASH!")
			elseif phase == "outbound" then
				entity.targetX = mount.x + (dx >= 0 and 5 or -5)
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
		local from = tumble.from.Position
		local ground = Vector3.new(from.X + tumble.side * 9, 3, from.Z + 6 * travelDir() * -1)
		local pos = from:Lerp(ground, t) + Vector3.new(0, math.sin(t * math.pi) * 6, 0)
		hrp.CFrame = CFrame.new(pos) * tumble.from.Rotation * CFrame.Angles(t * math.pi * 2, 0, tumble.side * t * 1.2)
		if t >= 1 then
			tumble = nil
			hrp.Anchored = false
			humanoid.Sit = false
		end
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
			table.remove(herd, table.find(herd, target))
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
	if loose then
		loose.speed = math.max(loose.speed - 30 * dt, 0)
		local look = CFrame.Angles(0, loose.yaw, 0).LookVector
		loose.x += look.X * loose.speed * dt
		loose.z += look.Z * loose.speed * dt
		place(loose, 0)
		loose.animal:update(dt, loose.speed, 0)
	end
	updateHerd(dt)
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
	if phase == "outbound" and mount then
		ensureReachable()
	end
	actionTarget = findTarget()
	highlight.Adornee = if actionTarget == "egg" then nestEgg.model elseif actionTarget then actionTarget.animal.model else nil
	highlight.Enabled = actionTarget ~= nil
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
