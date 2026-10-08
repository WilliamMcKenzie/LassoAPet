-- Lasso training (Config.Training, QM Oct 8: new-loops): a stitched horse dummy on a
-- pole at home. Stand near it on foot and you lasso it over and over: the loop spins
-- overhead, flies out and cinches on its neck, and each catch asks the server for
-- lasso strength (TrainLasso; Training.server counts it into the "Lasso" attribute,
-- which the HUD shows over the gold).
--
-- Every pen has its own dummy (Design's, one per biome: Props/TrainingByBiome) by its
-- front corner, facing out (TrainingSpot), and you train at your own pen's (your "Pen"
-- attribute), on foot (QM, Oct 8: sitting in a chair wasn't fun): a ring round it on
-- the floor, and anywhere in the ring you lasso it, turned to face it wherever you
-- walk. Step out and you stop. Each plays its idle, and yours its hit on each catch.
-- Built on each client like the podium snake, so they can animate (Motor6D.Transform
-- doesn't replicate). The lasso is its own copy of the rider's (Lasso holds one character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)
local TrainingByBiome = require(ReplicatedStorage.Shared.Props.TrainingByBiome)
local TrainingSpot = require(ReplicatedStorage.Shared.TrainingSpot)

local lassoModule = script.Parent.Lasso:Clone()
lassoModule.Name = "TrainingLassoInstance"
lassoModule.Parent = script
local Lasso = require(lassoModule)

local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 } -- the animals'
local training = Config.Training
local player = Players.LocalPlayer
local trainLasso = ReplicatedStorage:WaitForChild("TrainLasso")
local trainingState = ReplicatedStorage:WaitForChild("TrainingState") -- (others see you train: their copies of this)

-- The dummies -------------------------------------------------------------------
-- Each pen's is its biome's (Props/TrainingByBiome: the owner's pen level picks it,
-- 1 for a free pen), swapped when that changes. Each faces -Z with its foot at y 0 in
-- its own space; its entry's `neck` is where the loop closes (centre in model space,
-- cinched radius). The bigger ones stand further out so their bases stay ~2 studs
-- clear of the fence, and have bigger rings.
local dummies = {} -- [pen] = { entry, level, model, bones, ring, out, radius, place, idleT, hitT }

local function noCollide(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false -- like the animals
			part.CanQuery = false
			part.CanTouch = false
		end
	end
end

-- How far a built model (at the origin, facing -Z) reaches: behind its root along +Z
-- near the ground (its base: the part that has to clear the fence), and to either side.
local function reach(model)
	local back, side = 0, 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local extent = Vector3.new(
				math.abs(part.CFrame.RightVector.X * part.Size.X) + math.abs(part.CFrame.UpVector.X * part.Size.Y) + math.abs(part.CFrame.LookVector.X * part.Size.Z),
				0,
				math.abs(part.CFrame.RightVector.Z * part.Size.X) + math.abs(part.CFrame.UpVector.Z * part.Size.Y) + math.abs(part.CFrame.LookVector.Z * part.Size.Z)
			) / 2
			side = math.max(side, math.abs(part.Position.X) + extent.X)
			if part.Position.Y - part.Size.Y / 2 < 3 then
				back = math.max(back, part.Position.Z + extent.Z)
			end
		end
	end
	return back, side
end

-- The ring you train in (QM, Oct 8): white blocks on the floor round the pole, only
-- in front of the fence (`out` studs behind the pole, +Z in its space: the pen's
-- behind it). Built round the origin, placed with the dummy. Only yours is shown.
local RING = { Segments = 72, Width = 1, Height = 0.2, Idle = 0.35 } -- Idle: its transparency till you're in it
local function buildRing(radius, out)
	local ring = Instance.new("Model")
	ring.Name = "TrainingRing"
	for i = 0, RING.Segments - 1 do
		local a = (i + 0.5) / RING.Segments * 2 * math.pi
		local x, z = radius * math.cos(a), radius * math.sin(a)
		if z < out - 1 then
			local part = Instance.new("Part")
			part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
			part.Size = Vector3.new(RING.Width, RING.Height, 2 * math.pi * radius / RING.Segments + 0.05)
			part.Color = Color3.new(1, 1, 1)
			part.Material = Enum.Material.SmoothPlastic
			part.Transparency = RING.Idle
			part.CFrame = CFrame.new(x, RING.Height / 2 + 0.02, z) * CFrame.Angles(0, -a, 0) -- (its length along the ring)
			part.Parent = ring
		end
	end
	ring.WorldPivot = CFrame.identity
	return ring
end

local function levelOf(pen)
	local owner = pen:GetAttribute("Owner") and Players:GetPlayerByUserId(pen:GetAttribute("Owner"))
	local level = owner and owner:GetAttribute("PenLevel") or 1
	return math.clamp(level, 1, #TrainingByBiome)
end

local function build(pen, level)
	local old = dummies[pen]
	if old then
		old.model:Destroy()
		old.ring:Destroy()
	end
	local entry = TrainingByBiome[level]
	local model, _, bones = Rig.fromData(entry.dummy, "TrainingDummy" .. entry.name, STUD_TEXTURE)
	model.Name = "TrainingDummy"
	noCollide(model)
	local back, side = reach(model)
	local radius = math.max(training.Radius, math.max(back, side) + 8) -- (room to walk round the bigger ones)
	local dummy = {
		entry = entry,
		level = level,
		model = model,
		bones = bones,
		out = back + 2, -- (QM: right up against the fence, ~2 studs clear)
		radius = radius,
		ring = buildRing(radius, back + 2),
		idleT = math.random() * entry.dummy.animations.idle.length,
		hitT = math.huge,
	}
	dummies[pen] = dummy
	return dummy
end

local function place(dummy, pen)
	local spot = TrainingSpot.of(pen, dummy.out)
	local yours = pen.Name == "Pen" .. tostring(player:GetAttribute("Pen"))
	if spot then
		if dummy.place ~= spot then
			dummy.place = spot
			dummy.model.PrimaryPart.CFrame = spot -- (Root is at the model's origin, its foot)
			dummy.ring:PivotTo(spot)
		end
		dummy.model.Parent = workspace
		dummy.ring.Parent = if yours then workspace else nil
		if yours then
			-- Just inside the ring's front, where you'd step in (the tutorial's arrows lead
			-- here; this client only).
			player:SetAttribute("TrainingAt", (spot * CFrame.new(0, 0, 3 - dummy.radius)).Position)
		end
	else
		dummy.place = nil
		dummy.model.Parent = nil
		dummy.ring.Parent = nil
	end
end

-- Keeps every pen's dummy its owner's biome's, and in its spot as the pen grows.
task.spawn(function()
	local pens = workspace:WaitForChild("Pens")
	while true do
		for _, pen in pens:GetChildren() do
			local level = levelOf(pen)
			local dummy = dummies[pen]
			if not dummy or dummy.level ~= level then
				dummy = build(pen, level)
			end
			place(dummy, pen)
		end
		task.wait(0.5)
	end
end)

-- Its idle on a loop, and its hit once per catch.
local function animate(dummy, dt)
	local animations = dummy.entry.dummy.animations
	local hit = animations.hit
	local clip, t
	if hit and dummy.hitT < hit.length then
		dummy.hitT += dt
		clip, t = hit, math.min(dummy.hitT, hit.length)
	else
		dummy.idleT = (dummy.idleT + dt) % animations.idle.length
		clip, t = animations.idle, dummy.idleT
	end
	for bone, motor in dummy.bones do
		local track = clip.tracks[bone]
		if motor and track then
			local x, y, z = 0, 0, 0
			if track.position then
				x, y, z = Rig.sample(track.position, t)
			end
			local rx, ry, rz = 0, 0, 0
			if track.rotation then
				rx, ry, rz = Rig.sample(track.rotation, t)
			end
			motor.Transform = CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz)
		elseif motor then
			motor.Transform = CFrame.identity
		end
	end
end

-- Your own pen's dummy, if you have a pen and it's standing.
local function mine()
	local index = player:GetAttribute("Pen")
	local pen = index and workspace.Pens:FindFirstChild("Pen" .. index)
	local dummy = pen and dummies[pen]
	return if dummy and dummy.place then dummy else nil
end

-- "+N" with the lasso icon popping out beside your head on each catch (PlusPopup).
local Hud = require(script.Parent.Hud)
local PlusPopup = require(script.Parent.PlusPopup)
local Sounds = require(script.Parent.Sounds)
local function popCatch(char, amount)
	PlusPopup.at(char, amount, Hud.lassoIcon, PlusPopup.BURST)
end

-- Training ----------------------------------------------------------------------
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
local whooshed = false -- this throw's whoosh has played
local perThrow, owed = 1, 0 -- catches each throw counts for (past MinCycle), and the fraction owed
local CATCH_AT = training.Swing + training.Throw + training.Pull * 0.35 -- the loop's cinched on its neck
local character -- the character the lasso's started on, while training
local t = 0 -- seconds into this catch
local counted = false
local lassoLevel -- the pen level whose lasso you're throwing (LassoTiers)
local TURN = 10 -- how quickly you turn to face the dummy (per second, eased)

-- In your dummy's ring, on foot (not riding: Ride anchors you), alive, not in the
-- tutorial. The ring stops at the fence: not from inside your pen.
local function near(dummy)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not dummy or not hrp or not humanoid or humanoid.Health <= 0 or hrp.Anchored or humanoid.PlatformStand or humanoid.Sit then
		return nil
	end
	if not char:FindFirstChild("RightGripAttachment", true) then -- (the tutorial ends here now: QM)
		return nil
	end
	local at = dummy.place:PointToObjectSpace(hrp.Position)
	return if Vector2.new(at.X, at.Z).Magnitude <= dummy.radius and at.Z < dummy.out then char else nil
end

-- You stop training: the rope goes, you turn freely again, and everyone else stops
-- seeing you throw (the server's "Training" attribute).
local function stop()
	if character then
		Lasso.stop()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
		character = nil
		trainingState:FireServer(false)
	end
end

RunService.PreSimulation:Connect(function(dt)
	local char0 = player.Character
	local at0 = char0 and char0:FindFirstChild("HumanoidRootPart")
	for _, dummy in dummies do
		if dummy.place and at0 and (at0.Position - dummy.place.Position).Magnitude < 300 then
			animate(dummy, dt) -- (not while you're out riding: too far to see them move)
		end
	end
	local dummy = mine()
	local char = near(dummy)
	if char ~= character then
		stop()
		if char then
			character = char
			lassoLevel = player:GetAttribute("PenLevel") or 1
			Lasso.start(char, 1, lassoLevel) -- (your pen level's lasso: LassoTiers)
			t, counted, whooshed = 0, false, false
			char:FindFirstChildOfClass("Humanoid").AutoRotate = false -- (turned to the dummy below)
			trainingState:FireServer(true)
		end
	end
	-- Your ring lights up while you're in it.
	local lit = character ~= nil
	if dummy and dummy.lit ~= lit then
		dummy.lit = lit
		for _, part in dummy.ring:GetChildren() do
			part.Transparency = if lit then 0 else RING.Idle
		end
	end
	if character and (player:GetAttribute("PenLevel") or 1) ~= lassoLevel then
		lassoLevel = player:GetAttribute("PenLevel") or 1
		Lasso.start(character, 1, lassoLevel) -- upgraded mid-throw: the new lasso, carrying on (QM)
	end
	if not character then
		return
	end
	-- Facing the dummy wherever you walk in the ring (QM, Oct 8): you walk where you
	-- steer, turned to it the whole time.
	local hrp = character.HumanoidRootPart
	local at = hrp.Position
	local look = Vector3.new(dummy.place.Position.X, at.Y, dummy.place.Position.Z)
	if (look - at).Magnitude > 0.5 then
		hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(at, look), math.min(dt * TURN, 1))
	end
	local neck = dummy.entry.neck
	local target = { cframe = dummy.place * CFrame.new(neck.center), radius = neck.radius }
	-- Stronger, quicker (the swing spins faster too), shown no quicker than MinCycle a
	-- throw: past that each throw is speed / shown catches (perThrow).
	local speed = TrainingSpot.speed(player:GetAttribute("Lasso"))
	local shown = math.min(speed, CYCLE / training.MinCycle)
	perThrow = speed / shown
	dt *= shown
	-- The catch counts once the loop's cinched (CATCH_AT into the cycle), even if a
	-- long frame at a high speed steps right over the pull.
	t += dt
	if not counted and t >= CATCH_AT then
		counted = true
		if dummy.hitT > 0.3 then -- (at high speeds the hit isn't restarted every catch: it'd only judder)
			dummy.hitT = 0
		end
		owed += perThrow
		local n = math.floor(owed)
		owed -= n
		if n >= 1 then
			trainLasso:FireServer(n)
			popCatch(character, n * TrainingSpot.perCatch(player:GetAttribute("PenLevel")))
		end
	end
	if t >= CYCLE then
		t, counted, whooshed = t % CYCLE, false, false
	end
	-- A whoosh as each throw leaves your hand (QM: training's one sound), one a throw
	-- however many catches it counts for, its pitch a little off each time.
	if not whooshed and t >= training.Swing then
		whooshed = true
		Sounds.play("training_whoosh", 0.6, 0.94 + math.random() * 0.12)
	end
	if t < training.Swing then
		Lasso.swing(dt)
	elseif t < training.Swing + training.Throw then
		Lasso.throw((t - training.Swing) / training.Throw, target)
	elseif t < training.Swing + training.Throw + training.Pull then
		local k = (t - training.Swing - training.Throw) / training.Pull
		Lasso.pull(k, target)
	else
		Lasso.hide()
	end
end)

-- Everyone else training (their "Training" attribute, from the server): their throws at
-- their own pen's dummy played here, as they'd see them (no +N popups: those are theirs).
-- Each has a copy of the Lasso module (it holds one character). Only near ones.
local OTHERS_NEAR = 300
local others = {} -- [player] = { module, Lasso, t, counted, level }
local function dropOther(p)
	local o = others[p]
	if o then
		o.Lasso.stop()
		o.module:Destroy()
		others[p] = nil
	end
end
Players.PlayerRemoving:Connect(dropOther)
RunService.PreSimulation:Connect(function(dt)
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, p in Players:GetPlayers() do
		local char = p ~= player and p:GetAttribute("Training") and p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local index = p:GetAttribute("Pen")
		local pen = index and workspace.Pens:FindFirstChild("Pen" .. index)
		local dummy = pen and dummies[pen]
		local near = hrp and me and dummy and dummy.place and (hrp.Position - me.Position).Magnitude < OTHERS_NEAR
		local o = others[p]
		if not near or not char:FindFirstChild("RightGripAttachment", true) then
			dropOther(p)
			continue
		end
		local level = p:GetAttribute("PenLevel") or 1
		if not o or o.char ~= char then
			dropOther(p)
			local module = script.Parent.Lasso:Clone()
			module.Name = "TrainingLasso" .. p.UserId
			module.Parent = script
			o = { module = module, Lasso = require(module), t = 0, counted = false, char = char }
			others[p] = o
			o.level = level
			o.Lasso.start(char, 1, level)
		elseif o.level ~= level then
			o.level = level
			o.Lasso.start(char, 1, level)
		end
		local speed = TrainingSpot.speed(p:GetAttribute("Lasso"))
		local step = dt * math.min(speed, CYCLE / training.MinCycle)
		o.t += step
		if not o.counted and o.t >= CATCH_AT then
			o.counted = true
			if dummy.hitT > 0.3 then
				dummy.hitT = 0
			end
		end
		if o.t >= CYCLE then
			o.t, o.counted = o.t % CYCLE, false
		end
		local neck = dummy.entry.neck
		local target = { cframe = dummy.place * CFrame.new(neck.center), radius = neck.radius }
		if o.t < training.Swing then
			o.Lasso.swing(step)
		elseif o.t < training.Swing + training.Throw then
			o.Lasso.throw((o.t - training.Swing) / training.Throw, target)
		elseif o.t < training.Swing + training.Throw + training.Pull then
			o.Lasso.pull((o.t - training.Swing - training.Throw) / training.Pull, target)
		else
			o.Lasso.hide()
		end
	end
	for p in others do
		if not p.Parent then
			dropOther(p)
		end
	end
end)

script.Destroying:Connect(stop)
