-- The podium (Config.Podium, QM Oct 4): QM's grass snake (Props/GrassSnake), coiled on
-- the ground playing its idle round the cream marble column that first place stands on
-- (Leaderboard.server puts their avatar on the cap). Only a prop: it isn't an animal
-- you can ride or own.
--
-- Built here on each client rather than on the server, so it can play its idle
-- (Motor6D.Transform doesn't replicate). Everyone sees the same snake.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Rig = require(ReplicatedStorage.Shared.Animals.Rig)
local GrassSnake = require(ReplicatedStorage.Shared.Props.GrassSnake)

local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 } -- the animals'
local SnakeModel = GrassSnake.data
local COLUMN = GrassSnake.capTop * Vector3.new(1, 0, 1) -- the column's foot in the model

local podium = Config.Podium
local size = podium.SnakeScale
local model, _, bones = Rig.fromData(SnakeModel, "GrassSnake", STUD_TEXTURE, size)
for _, part in model:GetDescendants() do
	if part:IsA("BasePart") then
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
end
local rootY = model.PrimaryPart.Position.Y
model.PrimaryPart.CFrame = CFrame.new(podium.Position)
	* CFrame.Angles(0, math.rad(podium.SnakeYaw), 0)
	* CFrame.new(-COLUMN * size + Vector3.new(0, rootY, 0))
model.Parent = workspace

local idle = SnakeModel.animations.idle
local player = Players.LocalPlayer
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t = (t + dt) % idle.length
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and (hrp.Position - podium.Position).Magnitude > 300 then
		return -- out riding: too far to see it move
	end
	for bone, track in idle.tracks do
		local motor = bones[bone]
		if motor then
			local x, y, z = 0, 0, 0
			if track.position then
				x, y, z = Rig.sample(track.position, t)
			end
			local rx, ry, rz = 0, 0, 0
			if track.rotation then
				rx, ry, rz = Rig.sample(track.rotation, t)
			end
			-- (offsets are in studs at the model's own size, as Horse:update scales them)
			motor.Transform = CFrame.new(x * size, y * size, z * size) * CFrame.Angles(rx, ry, rz)
		end
	end
end)
