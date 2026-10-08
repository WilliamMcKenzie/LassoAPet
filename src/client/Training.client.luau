-- Lasso training (Config.Training, QM Oct 8: new-loops): a stitched horse dummy on a
-- pole at home. Stand near it on foot and you lasso it over and over: the loop spins
-- overhead, flies out and cinches on its neck, and each catch asks the server for
-- lasso strength (TrainLasso; Training.server counts it into the "Lasso" attribute,
-- which the HUD shows over the gold).
--
-- Every pen has its own dummy (Design's Props/TrainingDummy) by its front corner,
-- facing out (TrainingSpot), and a chair beside it (Props/TrainingChair); you train at
-- your own pen's (your "Pen" attribute): walk up and you sit in the chair and lasso
-- from it. Jump off and you stand until you've walked away and come back. Each
-- plays its idle, and yours its hit on each catch. Built on each client like the
-- podium snake, so they can animate (Motor6D.Transform doesn't replicate). The lasso
-- is its own copy of the rider's (Lasso holds one character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)
local TrainingDummy = require(ReplicatedStorage.Shared.Props.TrainingDummy)
local TrainingChair = require(ReplicatedStorage.Shared.Props.TrainingChair)
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
-- Each faces -Z with its foot at y 0 in its own space; `neck` is where the loop
-- closes (centre in model space, cinched radius).
local data = TrainingDummy.model
local neck = TrainingDummy.neck
local dummies = {} -- [pen] = { model, bones, place, idleT, hitT, chair, seat }

local function place(dummy, pen)
	local spot = TrainingSpot.of(pen)
	local chair = TrainingSpot.chair(pen)
	if spot and chair then
		dummy.place = spot
		dummy.model.PrimaryPart.CFrame = spot -- (Root is at the model's origin, its foot)
		dummy.model.Parent = workspace
		dummy.chair.PrimaryPart.CFrame = chair -- (the seat's welded on, and comes too)
		dummy.chair.Parent = workspace
	else
		dummy.place = nil
		dummy.model.Parent = nil
		dummy.chair.Parent = nil
	end
end

local function noCollide(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false -- like the animals
			part.CanQuery = false
			part.CanTouch = false
		end
	end
end

-- The chair, with an invisible seat on its plank that you're welded to sitting in it.
local function buildChair()
	local chair = Rig.fromData(TrainingChair.model, "TrainingChair", STUD_TEXTURE)
	noCollide(chair)
	local seat = Instance.new("Part")
	seat.Name = "Seat"
	seat.Size = TrainingChair.seat.size
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanQuery = false
	seat.CanTouch = false
	seat.CFrame = chair.PrimaryPart.CFrame * TrainingChair.seat.cframe
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = chair.PrimaryPart, seat
	weld.Parent = seat
	seat.Anchored = false
	seat.Massless = true
	seat.Parent = chair
	return chair, seat
end

local function build(pen)
	local model, _, bones = Rig.fromData(data, "TrainingDummy", STUD_TEXTURE)
	model.Name = "TrainingDummy"
	noCollide(model)
	local chair, seat = buildChair()
	local dummy = { model = model, bones = bones, idleT = math.random() * data.animations.idle.length, hitT = math.huge, chair = chair, seat = seat }
	dummies[pen] = dummy
	place(dummy, pen)
	-- The pen grows with its level (a new SizeK model): move out with it.
	local sizes = pen:WaitForChild("Sizes")
	for _, signal in { sizes.ChildAdded, sizes.ChildRemoved } do
		signal:Connect(function()
			task.defer(place, dummy, pen)
		end)
	end
end

for _, pen in workspace:WaitForChild("Pens"):GetChildren() do
	task.spawn(build, pen)
end

-- Its idle on a loop, and its hit once per catch.
local function animate(dummy, dt)
	local animations = data.animations
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

-- Training ----------------------------------------------------------------------
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
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
	return if flat.Magnitude <= training.Radius then char else nil
end

local function standUp()
	if sitWeld then
		sitWeld:Destroy()
		sitWeld = nil
	end
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
	local target = { cframe = dummy.place * CFrame.new(neck.center), radius = neck.radius }
	dt *= TrainingSpot.speed(player:GetAttribute("Lasso")) -- stronger, quicker (the swing spins faster too)
	t += dt
	if t >= CYCLE then
		t, counted = t - CYCLE, false
	end
	if t < training.Swing then
		Lasso.swing(dt)
	elseif t < training.Swing + training.Throw then
		Lasso.throw((t - training.Swing) / training.Throw, target)
	elseif t < training.Swing + training.Throw + training.Pull then
		local k = (t - training.Swing - training.Throw) / training.Pull
		Lasso.pull(k, target)
		if not counted and k > 0.35 then -- cinched: that's a catch
			counted = true
			dummy.hitT = 0
			trainLasso:FireServer()
		end
	else
		Lasso.hide()
	end
end)

script.Destroying:Connect(function()
	stop()
	standUp()
end)
