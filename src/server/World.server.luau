-- The map itself (ground, corridor walls, obstacles, home base, pen and egg
-- nest) is a saved model: src/world/World.rbxmx, synced by Rojo into
-- Workspace.World, so it can be edited by hand in Studio. This script only sets
-- the sky, picks the Godlands' tracks, puts the finish line at the end of the
-- course, turns on the live colour attributes and marks the world ready.

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
-- The endless Godlands has no end, so no finish line.
local Config = require(ReplicatedStorage.Shared.Config)
local endless = Config.CourseLength == math.huge
local startLine = world:FindFirstChild("StartLine")
if startLine and not endless then
	local finish = startLine:Clone()
	finish.Name = "FinishLine"
	local z = startLine:GetBoundingBox().Position.Z
	finish:PivotTo(CFrame.new(0, 0, -Config.CourseLength + Config.FinishFromEnd - z) * startLine:GetPivot())
	finish.Parent = world
end

-- The Godlands: each client builds the tracks near it (Client/GodlandsStream), in
-- the order this server's seed picks (Shared/Godlands). Anything saved in the map
-- past its line (walls, pieces, the far wall) is in the way, so it goes.
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Godlands = require(ReplicatedStorage.Shared.Godlands)
if Godlands.start then
	world:SetAttribute("GodlandsSeed", Random.new():NextInteger(1, 1000000))
	for _, folderName in { "Ground", "Walls", "Obstacles", "Decor" } do
		local folder = world:FindFirstChild(folderName)
		for _, child in folder and folder:GetChildren() or {} do
			local box = if child:IsA("Model") then child:GetBoundingBox().Position elseif child:IsA("BasePart") then child.Position else nil
			if box and box.Z < Godlands.start then
				child:Destroy()
			end
		end
	end
end

-- Resize the medium and large obstacles to their tier's size (Config.ObstacleScale),
-- about the middle of their footprint on the floor, so they stay put and grounded.
for _, model in world.Obstacles:GetChildren() do
	local scale = model:IsA("Model") and Config.ObstacleScale[model.Name]
	local base = scale and model:FindFirstChild("Base")
	if base then
		model.WorldPivot = CFrame.new(base.Position + Vector3.new(0, base.Size.Y / 2, 0))
		model:ScaleTo(scale)
	end
end

-- Nothing past the finish line: the floor and walls stop at it, so the leap over
-- it goes out into open sky. Parts that cross the line are cut back to it.
local finishZ = -Config.CourseLength + Config.FinishFromEnd
for _, folderName in if endless then {} else { "Ground", "Walls", "Obstacles", "Decor" } do
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
WorldColors.watch(world)
world:SetAttribute("Ready", true)
