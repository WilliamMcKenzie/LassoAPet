-- Lasso training (Config.Training, QM Oct 8: new-loops): a stitched horse dummy on a
-- pole at home. Stand near it on foot and you lasso it over and over: the loop spins
-- overhead, flies out and cinches on its neck, and each catch asks the server for
-- lasso strength (TrainLasso; Training.server counts it into the "Lasso" attribute,
-- which the HUD shows over the gold).
--
-- Every pen has its own dummy (Design's Props/TrainingDummy) by its front corner,
-- facing out (TrainingSpot); you train at your own pen's (your "Pen" attribute). Each
-- plays its idle, and yours its hit on each catch. Built on each client like the
-- podium snake, so they can animate (Motor6D.Transform doesn't replicate). The lasso
-- is its own copy of the rider's (Lasso holds one character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)
local TrainingDummy = require(ReplicatedStorage.Shared.Props.TrainingDummy)
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
local dummies = {} -- [pen] = { model, bones, place, idleT, hitT }

local function place(dummy, pen)
	local spot = TrainingSpot.of(pen)
	if spot then
		dummy.place = spot
		dummy.model.PrimaryPart.CFrame = spot -- (Root is at the model's origin, its foot)
		dummy.model.Parent = workspace
	else
		dummy.place = nil
		dummy.model.Parent = nil
	end
end

local function build(pen)
	local model, _, bones = Rig.fromData(data, "TrainingDummy", STUD_TEXTURE)
	model.Name = "TrainingDummy"
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false -- like the animals
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	local dummy = { model = model, bones = bones, idleT = math.random() * data.animations.idle.length, hitT = math.huge }
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

local function canTrain(dummy)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 or hrp.Anchored or humanoid.Sit or humanoid.PlatformStand then
		return nil -- (riding: Ride anchors you and sits you on the animal)
	end
	if player:GetAttribute("Tutorial") or not char:FindFirstChild("RightGripAttachment", true) then
		return nil
	end
	local flat = (hrp.Position - dummy.place.Position) * Vector3.new(1, 0, 1)
	return if flat.Magnitude <= training.Radius then char else nil
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
	local char = dummy and canTrain(dummy)
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
	-- Face the dummy while standing still.
	local hrp = character.HumanoidRootPart
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid.MoveDirection.Magnitude < 0.1 then
		local at = hrp.Position
		local look = Vector3.new(dummy.place.X, at.Y, dummy.place.Z)
		if (look - at).Magnitude > 0.5 then
			hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(at, look), math.min(dt * 8, 1))
		end
	end
	local target = { cframe = dummy.place * CFrame.new(neck.center), radius = neck.radius }
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

script.Destroying:Connect(stop)
