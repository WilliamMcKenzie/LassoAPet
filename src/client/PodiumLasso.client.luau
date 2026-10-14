-- First place celebrates with the gameplay lasso, independently of the rider's.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.Config)

-- Lasso holds one character's state, so the podium needs its own instance.
local lassoModule = script.Parent.Lasso:Clone()
lassoModule.Name = "PodiumLassoInstance"
lassoModule.Parent = script
local Lasso = require(lassoModule)

local avatar, joints
local time = 0

local function pose(name, x, y, z)
	local joint = joints[name]
	if not joint then
		return
	end
	local basis = if joint:IsA("Motor6D") then joint.C0.Rotation else joint.Attachment0.CFrame.Rotation
	joint.Transform = basis:Inverse() * CFrame.Angles(x, y, z) * basis
end

RunService.PreSimulation:Connect(function(dt)
	local podium = workspace:FindFirstChild("Podium")
	local leader = podium and podium:FindFirstChild("Leader")
	if leader ~= avatar then
		Lasso.stop()
		avatar, joints = nil, {}
	end
	if not avatar and leader and leader:FindFirstChild("RightGripAttachment", true) then
		avatar = leader
		for _, joint in avatar:GetDescendants() do
			if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
				joints[joint.Name:gsub(" ", "")] = joint
			end
		end
		Lasso.start(avatar, avatar:GetScale())
	end
	if not avatar then
		return
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and (root.Position - Config.Podium.Position).Magnitude > 300 then
		return
	end
	time += dt
	local sway = math.sin(time * 2)
	local circle = time * math.pi * 2 * 1.32
	Lasso.swing(dt * 0.55, 2.2 * avatar:GetScale())
	-- Pose in the torso's axes: R6 shoulder joints have different local axes.
	pose("RightShoulder", math.rad(165) + math.sin(circle) * 0.07, 0, math.rad(12) + math.cos(circle) * 0.09)
	pose("RightElbow", math.rad(-18) + math.sin(circle) * 0.12, 0, 0)
	-- R15's free arm, waist and legs retain the Stylish animation.
	-- R6 has no knees or elbows, so give its block limbs a gentle weight shift.
	if not joints.Waist then
		pose("LeftShoulder", math.rad(12) + sway * 0.08, 0, math.rad(-12) + sway * 0.04)
		pose("RootJoint", 0, sway * 0.04, sway * 0.025)
		pose("RightHip", sway * 0.04, 0, math.rad(4) - sway * 0.025)
		pose("LeftHip", -sway * 0.04, 0, math.rad(-4) - sway * 0.025)
	end
end)

script.Destroying:Connect(function()
	Lasso.stop()
end)
