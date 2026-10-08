-- Lasso training (Config.Training, QM Oct 8: new-loops): a stitched horse dummy on a
-- pole at home. Stand near it on foot and you lasso it over and over: the loop spins
-- overhead, flies out and cinches on its neck, and each catch asks the server for
-- lasso strength (TrainLasso; Training.server counts it into the "Lasso" attribute,
-- which the HUD shows over the gold).
--
-- The dummy is Design's Props/TrainingDummy when it's in, playing its idle and its
-- hit on each catch; until then a placeholder of blocks with the same neck. Built on
-- each client like the podium snake, so it can animate (Motor6D.Transform doesn't
-- replicate). The lasso is its own copy of the rider's (Lasso holds one character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)

local lassoModule = script.Parent.Lasso:Clone()
lassoModule.Name = "TrainingLassoInstance"
lassoModule.Parent = script
local Lasso = require(lassoModule)

local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 } -- the animals'
local training = Config.Training
local player = Players.LocalPlayer
local trainLasso = ReplicatedStorage:WaitForChild("TrainLasso")

-- The dummy ---------------------------------------------------------------------
-- Faces -Z with its foot at y 0 in its own space; `neck` is where the loop closes
-- (centre in model space, cinched radius).
local model, bones, animations
local neck = { center = Vector3.new(0, 12.27, -1.04), radius = 1.35 }
local place = CFrame.new(training.Position) * CFrame.Angles(0, math.rad(training.Yaw), 0)

local props = ReplicatedStorage.Shared:FindFirstChild("Props")
local designed = props and props:FindFirstChild("TrainingDummy")
if designed then
	local TrainingDummy = require(designed)
	local data = TrainingDummy.model or TrainingDummy.data
	model, _, bones = Rig.fromData(data, "TrainingDummy", STUD_TEXTURE)
	animations = data.animations
	if TrainingDummy.neck then
		neck = TrainingDummy.neck
	end
	model.PrimaryPart.CFrame = place * CFrame.new(model.PrimaryPart.Position) -- (built at its model-space spot)
else
	-- Placeholder: a wooden pole with a sackcloth horse leaping off its top.
	model = Instance.new("Model")
	local function block(name, size, cframe, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.Size = size
		part.CFrame = place * cframe
		part.Color = color
		part.Material = material or Enum.Material.Fabric
		part.Parent = model
		return part
	end
	local wood, sack, stitch = Color3.fromRGB(120, 78, 44), Color3.fromRGB(196, 164, 112), Color3.fromRGB(70, 50, 34)
	local pole = block("Pole", Vector3.new(1, 9, 1), CFrame.new(0, 4.5, 0), wood, Enum.Material.Wood)
	block("Foot", Vector3.new(4, 0.6, 4), CFrame.new(0, 0.3, 0), wood, Enum.Material.Wood)
	local leap = CFrame.new(0, 10, 0) * CFrame.Angles(math.rad(18), 0, 0) -- nose up, mid-leap
	block("Body", Vector3.new(2.6, 2.6, 5), leap, sack)
	block("Neck", Vector3.new(1.6, 3, 1.6), CFrame.new(neck.center) * CFrame.Angles(math.rad(-25), 0, 0), sack)
	block("Head", Vector3.new(1.8, 1.8, 3), CFrame.new(neck.center + Vector3.new(0, 1.9, -1.3)), sack)
	for _, side in { -1, 1 } do
		block("Eye", Vector3.new(0.1, 0.7, 0.7), CFrame.new(neck.center + Vector3.new(side * 0.92, 2.2, -1.6)) * CFrame.Angles(math.rad(45), 0, 0), stitch)
		block("Eye", Vector3.new(0.1, 0.7, 0.7), CFrame.new(neck.center + Vector3.new(side * 0.92, 2.2, -1.6)) * CFrame.Angles(math.rad(-45), 0, 0), stitch)
		block("Leg", Vector3.new(0.7, 2.6, 0.7), leap * CFrame.new(side * 0.9, -1.6, -1.9) * CFrame.Angles(math.rad(-50), 0, 0), sack)
		block("Leg", Vector3.new(0.7, 2.6, 0.7), leap * CFrame.new(side * 0.9, -1.6, 1.9) * CFrame.Angles(math.rad(50), 0, 0), sack)
	end
	block("Tail", Vector3.new(0.5, 0.5, 2), leap * CFrame.new(0, 0.6, 3.2) * CFrame.Angles(math.rad(30), 0, 0), stitch)
	model.PrimaryPart = pole
end
model.Name = "TrainingDummy"
for _, part in model:GetDescendants() do
	if part:IsA("BasePart") then
		part.CanCollide = not designed and (part.Name == "Pole" or part.Name == "Foot") -- (Design's: none, like the animals)
		part.CanQuery = false
		part.CanTouch = false
	end
end
model.Parent = workspace

local target = { cframe = place * CFrame.new(neck.center), radius = neck.radius }

-- Its idle on a loop, and its hit once per catch (Design's dummy only).
local idleT, hitT = 0, math.huge
local function animate(dt)
	if not animations or not bones then
		return
	end
	local hit = animations.hit
	local clip, t
	if hit and hitT < hit.length then
		hitT += dt
		clip, t = hit, math.min(hitT, hit.length)
	elseif animations.idle then
		idleT = (idleT + dt) % animations.idle.length
		clip, t = animations.idle, idleT
	end
	if not clip then
		return
	end
	for bone, motor in bones do
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

-- Training ----------------------------------------------------------------------
local CYCLE = training.Swing + training.Throw + training.Pull + training.Rest
local character -- the character the lasso's started on, while training
local t = 0 -- seconds into this catch
local counted = false

local function canTrain()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 or hrp.Anchored or humanoid.Sit or humanoid.PlatformStand then
		return nil -- (riding: Ride anchors you and sits you on the animal)
	end
	if player:GetAttribute("Tutorial") or not char:FindFirstChild("RightGripAttachment", true) then
		return nil
	end
	local flat = (hrp.Position - training.Position) * Vector3.new(1, 0, 1)
	return if flat.Magnitude <= training.Radius then char else nil
end

local function stop()
	if character then
		Lasso.stop()
		character = nil
	end
end

RunService.PreSimulation:Connect(function(dt)
	animate(dt)
	local char = canTrain()
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
		local look = Vector3.new(training.Position.X, at.Y, training.Position.Z)
		if (look - at).Magnitude > 0.5 then
			hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(at, look), math.min(dt * 8, 1))
		end
	end
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
			hitT = 0
			trainLasso:FireServer()
		end
	else
		Lasso.hide()
	end
end)

script.Destroying:Connect(stop)
