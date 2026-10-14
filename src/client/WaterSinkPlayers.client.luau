-- Players on foot sink a bit in water (QM, Oct 14; Config.WaterSink, as RotMG): standing over
-- Water or DeepWater (Ground.waterAt), every character here is drawn that fraction of its
-- height lower, easing in and out. Only the look: its root joint's C0 moves the body down
-- under the HumanoidRootPart, which (and so the physics) stays put. Riders sink with their
-- mount instead (Client/WaterSink), so a seated character is left alone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local Ground = require(ReplicatedStorage.Shared.Ground)

local SINK = Config.WaterSink or {}
local RATE = SINK.Rate or 6
if not (SINK.Water or SINK.DeepWater) then
	return
end

local sinking = {} -- [root joint] = { c0 = its own C0, sink = studs now, height = the body's }

local function rootJoint(character)
	local lower = character:FindFirstChild("LowerTorso")
	local joint = lower and lower:FindFirstChild("Root") -- (R15)
	if not joint then
		local root = character:FindFirstChild("HumanoidRootPart")
		joint = root and root:FindFirstChild("RootJoint") -- (R6)
	end
	return if joint and joint:IsA("Motor6D") then joint else nil
end

RunService.RenderStepped:Connect(function(dt)
	local k = 1 - math.exp(-RATE * dt)
	local seen = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local joint = humanoid and root and rootJoint(character)
		if joint then
			local water = not humanoid.Sit and humanoid.FloorMaterial ~= Enum.Material.Air and Ground.waterAt(root.Position.X, root.Position.Z)
			local fraction = water and SINK[water] or 0
			local s = sinking[joint]
			if fraction > 0 or s then
				if not s then
					s = { c0 = joint.C0, sink = 0, height = character:GetExtentsSize().Y }
					sinking[joint] = s
				end
				seen[joint] = true
				local want = fraction * s.height
				s.sink += (want - s.sink) * k
				if want == 0 and s.sink < 0.01 then
					joint.C0 = s.c0
					sinking[joint] = nil
				else
					joint.C0 = CFrame.new(0, -s.sink, 0) * s.c0
				end
			end
		end
	end
	for joint, s in sinking do -- (gone: respawned, left, or seated on a mount)
		if not seen[joint] then
			if joint.Parent then
				joint.C0 = s.c0
			end
			sinking[joint] = nil
		end
	end
end)
