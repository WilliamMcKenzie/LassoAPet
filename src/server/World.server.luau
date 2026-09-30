-- The map itself (ground, corridor walls, obstacles, home base, pen and egg
-- nest) is a saved model: src/world/World.rbxmx, synced by Rojo into
-- Workspace.World, so it can be edited by hand in Studio. This script only sets
-- the sky, puts the finish line at the end of the course, turns on the live
-- colour attributes and marks the world ready.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local world = workspace:WaitForChild("World")

-- Bright, cloudless kid-friendly sky.
for _, child in Lighting:GetChildren() do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
		child:Destroy()
	end
end
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if clouds then
	clouds:Destroy()
end
local sky = Instance.new("Sky")
sky.CelestialBodiesShown = false
sky.StarCount = 0
-- Plain gradient skybox generated for this game (deep blue overhead, lighter at the horizon).
local SKY_SIDE = "rbxassetid://101714504952971"
for _, face in { "Bk", "Ft", "Lf", "Rt" } do
	sky["Skybox" .. face] = SKY_SIDE
end
sky.SkyboxUp = "rbxassetid://73730341040940"
sky.SkyboxDn = "rbxassetid://98351643334543"
sky.Parent = Lighting
-- The finish line: a copy of the start line at the end of the last biome
-- (Config.FinishFromEnd before the far wall), so it moves as biomes are added.
local Config = require(ReplicatedStorage.Shared.Config)
local startLine = world:FindFirstChild("StartLine")
if startLine then
	local finish = startLine:Clone()
	finish.Name = "FinishLine"
	local z = startLine:GetBoundingBox().Position.Z
	finish:PivotTo(CFrame.new(0, 0, -Config.CourseLength + Config.FinishFromEnd - z) * startLine:GetPivot())
	finish.Parent = world
end

-- Nothing past the finish line: the floor and walls stop at it, so the leap over
-- it goes out into open sky. Parts that cross the line are cut back to it.
local finishZ = -Config.CourseLength + Config.FinishFromEnd
for _, folderName in { "Ground", "Walls", "Obstacles", "Decor" } do
	local folder = world:FindFirstChild(folderName)
	for _, part in folder and folder:GetDescendants() or {} do
		if part:IsA("BasePart") then
			local near = part.Position.Z + part.Size.Z / 2
			local far = part.Position.Z - part.Size.Z / 2
			if near <= finishZ then
				part:Destroy()
			elseif far < finishZ and part.CFrame.Rotation == CFrame.identity then
				local keep = near - finishZ
				part.Size = Vector3.new(part.Size.X, part.Size.Y, keep)
				part.CFrame = CFrame.new(part.Position.X, part.Position.Y, finishZ + keep / 2)
			end
		end
	end
end
require(ReplicatedStorage.Shared.WorldColors).watch(world)
world:SetAttribute("Ready", true)
