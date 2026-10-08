-- Lasso training (Config.Training, QM Oct 8: new-loops): a stitched horse dummy on a
-- pole at home. Stand near it on foot and you lasso it over and over: the loop spins
-- overhead, flies out and cinches on its neck, and each catch asks the server for
-- lasso strength (TrainLasso; Training.server counts it into the "Lasso" attribute,
-- which the HUD shows over the gold).
--
-- Every pen has its own dummy (Design's, one per biome: Props/TrainingByBiome) by its
-- front corner, facing out (TrainingSpot), and a chair beside it; you train at
-- your own pen's (your "Pen" attribute): walk up and you sit in the chair and lasso
-- from it. Jump off and you stand until you've walked away and come back. Each
-- plays its idle, and yours its hit on each catch. Built on each client like the
-- podium snake, so they can animate (Motor6D.Transform doesn't replicate). The lasso
-- is its own copy of the rider's (Lasso holds one character).

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

-- The dummies -------------------------------------------------------------------
-- Each pen's is its biome's (Props/TrainingByBiome: the owner's pen level picks it,
-- 1 for a free pen), swapped when that changes. Each faces -Z with its foot at y 0 in
-- its own space; its entry's `neck` is where the loop closes (centre in model space,
-- cinched radius). The bigger ones stand further out so their bases stay ~2 studs
-- clear of the fence, and their chairs further along.
local dummies = {} -- [pen] = { entry, level, model, bones, chair, seat, back, side, place, idleT, hitT }

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

-- The chair, with an invisible seat on its plank that you're welded to sitting in it.
local function buildChair(entry)
	local chair = Rig.fromData(entry.chair, "TrainingChair" .. entry.name, STUD_TEXTURE)
	noCollide(chair)
	local seat = Instance.new("Part")
	seat.Name = "Seat"
	seat.Size = TrainingByBiome.seat.size
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanQuery = false
	seat.CanTouch = false
	seat.CFrame = chair.PrimaryPart.CFrame * TrainingByBiome.seat.cframe
	-- (a Weld with its offset given, not a WeldConstraint: that takes the offset the parts
	-- have when it first goes live in workspace, by which time the chair had been moved
	-- to the pen and the seat hadn't, so it stayed at the origin: the start line)
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = chair.PrimaryPart, seat
	weld.C0 = TrainingByBiome.seat.cframe
	weld.Parent = seat
	seat.Anchored = false
	seat.Massless = true
	seat.Parent = chair
	return chair, seat
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
		old.chair:Destroy()
	end
	local entry = TrainingByBiome[level]
	local model, _, bones = Rig.fromData(entry.dummy, "TrainingDummy" .. entry.name, STUD_TEXTURE)
	model.Name = "TrainingDummy"
	noCollide(model)
	local back, side = reach(model)
	local chair, seat = buildChair(entry)
	local chairBack, chairSide = reach(chair)
	local dummy = {
		entry = entry,
		level = level,
		model = model,
		bones = bones,
		chair = chair,
		seat = seat,
		out = back + 2, -- (QM: right up against the fence, ~2 studs clear)
		along = math.max(training.Chair, side + math.max(chairBack, chairSide) + 2),
		idleT = math.random() * entry.dummy.animations.idle.length,
		hitT = math.huge,
	}
	dummies[pen] = dummy
	return dummy
end

local function place(dummy, pen)
	local spot = TrainingSpot.of(pen, dummy.out)
	local chair = TrainingSpot.chair(pen, dummy.out, dummy.along)
	if spot and chair then
		if dummy.place ~= spot then
			dummy.place = spot
			dummy.model.PrimaryPart.CFrame = spot -- (Root is at the model's origin, its foot)
			dummy.chair.PrimaryPart.CFrame = chair -- (the seat's welded on, and comes too)
		end
		dummy.model.Parent = workspace
		dummy.chair.Parent = workspace
	else
		dummy.place = nil
		dummy.model.Parent = nil
		dummy.chair.Parent = nil
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
local function popCatch(char, amount)
	PlusPopup.at(char, amount, Hud.lassoIcon)
end

-- Training ----------------------------------------------------------------------
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
local CATCH_AT = training.Swing + training.Throw + training.Pull * 0.35 -- the loop's cinched on its neck
local character -- the character the lasso's started on, while training
local t = 0 -- seconds into this catch
local counted = false
local sitWeld -- you, welded into your chair
local stoodUp = false -- jumped out of the chair: no sitting again till you've walked off

-- Near your dummy, on foot (not riding: Ride anchors you), alive, not in the tutorial.
local function near(dummy)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not dummy or not hrp or not humanoid or humanoid.Health <= 0 or hrp.Anchored or humanoid.PlatformStand then
		return nil
	end
	if player:GetAttribute("Tutorial") or not char:FindFirstChild("RightGripAttachment", true) then
		return nil
	end
	local flat = (hrp.Position - dummy.place.Position) * Vector3.new(1, 0, 1)
	return if flat.Magnitude <= math.max(training.Radius, dummy.along + 4) then char else nil -- (the chair's always in reach)
end

local function standUp()
	if sitWeld then
		sitWeld:Destroy()
		sitWeld = nil
	end
	player:SetAttribute("TrainingSeat", nil)
end

-- Into the chair, facing the dummy (the seat faces the chair's -Z, at it).
local function sitDown(char, dummy)
	local hrp = char.HumanoidRootPart
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid.Sit then
		return -- (in some other seat)
	end
	local above = hrp.Size.Y / 2 + 0.4 * char:GetScale() -- the root's height over the plank, seated
	hrp.CFrame = dummy.seat.CFrame * CFrame.new(0, above, 0)
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1 = dummy.seat, hrp
	weld.C0 = CFrame.new(0, above, 0)
	weld.Parent = dummy.seat
	sitWeld = weld
	humanoid.Sit = true
	-- Sitting here isn't riding: the merge menu and pet plates stay (this client only).
	player:SetAttribute("TrainingSeat", true)
end

local function stop()
	if character then
		Lasso.stop()
		character = nil
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
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if sitWeld and not (char and humanoid.Sit and sitWeld.Part0 == dummy.seat and sitWeld.Part1 == char.HumanoidRootPart) then
		standUp() -- jumped off (or respawned, or the pen moved)
		stoodUp = char ~= nil
	end
	if not char then
		stoodUp = false
	elseif not sitWeld and not stoodUp then
		sitDown(char, dummy)
	end
	if not sitWeld then
		char = nil -- you lasso from the chair
	end
	if char ~= character then
		stop()
		if char then
			character = char
			Lasso.start(char, 1)
			t, counted = 0, false
		end
	end
	if not character then
		return
	end
	local neck = dummy.entry.neck
	local target = { cframe = dummy.place * CFrame.new(neck.center), radius = neck.radius }
	dt *= TrainingSpot.speed(player:GetAttribute("Lasso")) -- stronger, quicker (the swing spins faster too)
	-- The catch counts once the loop's cinched (CATCH_AT into the cycle), even if a
	-- long frame at a high speed steps right over the pull.
	t += dt
	if not counted and t >= CATCH_AT then
		counted = true
		if dummy.hitT > 0.3 then -- (at high speeds the hit isn't restarted every catch: it'd only judder)
			dummy.hitT = 0
		end
		trainLasso:FireServer()
		popCatch(character, TrainingSpot.perCatch(player:GetAttribute("PenLevel")))
	end
	if t >= CYCLE then
		t, counted = t % CYCLE, false
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

script.Destroying:Connect(function()
	stop()
	standUp()
end)
