-- The map itself (ground, corridor walls, obstacles, home base, pen and egg
-- nest) is a saved model: src/world/World.rbxmx, synced by Rojo into
-- Workspace.World, so it can be edited by hand in Studio. This script only sets
-- the sky, picks the Godlands' tracks, puts the finish line at the end of the
-- course, turns on the live colour attributes and marks the world ready.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local world = workspace:WaitForChild("World")

-- The sky (Config.Sky), with no sun, moon, stars or clouds of Roblox's own.
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
-- One flat colour all round, that shows on screen as #59D9FD (QM, Oct 6). The image
-- itself is #5CB5F1: Lighting's ColorCorrection (Saturation 0.25, Contrast 0.05) and
-- ExposureCompensation 0.5 brighten and saturate the sky too, so it was picked by
-- uploading solid colours and sampling Studio's screen until it read #59D9FE (one off
-- in blue, the nearest it gets). Change those Lighting settings and it needs picking again.
local FLAT = "rbxassetid://81588505365795"
-- Or the Creator Store's free "Anime sky" (asset 13107361022, by bomberman_br): soft
-- cartoon clouds on a pastel blue (QM, Oct 6). Config.Sky picks which.
local ANIME = {
	Bk = "rbxassetid://13107325341", Dn = "rbxassetid://13107329809", Ft = "rbxassetid://13107334845",
	Lf = "rbxassetid://13107337703", Rt = "rbxassetid://13107340396", Up = "rbxassetid://13107344387",
}
for _, face in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do
	sky["Skybox" .. face] = if Config.Sky == "Flat" then FLAT else ANIME[face]
end
sky.Parent = Lighting
-- The finish line: a copy of the start line at the end of the last biome
-- (Config.FinishFromEnd before the far wall), so it moves as biomes are added.
local endless = Config.CourseLength == math.huge
local startLine = world:FindFirstChild("StartLine")
if startLine and not endless and not Config.Endless then
	local finish = startLine:Clone()
	finish.Name = "FinishLine"
	local z = startLine:GetBoundingBox().Position.Z
	finish:PivotTo(CFrame.new(0, 0, -Config.CourseLength + Config.FinishFromEnd - z) * startLine:GetPivot())
	finish.Parent = world
end

local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

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
-- (an endless course, Config.Endless: cut at its Cut instead, and whole models past it
-- go, so nothing's left half there; Client/Endless lays the stretch before it on and on)
if Config.Endless then
	finishZ = Config.Endless.Cut
	for _, folderName in { "Obstacles", "Decor", "Nests" } do
		for _, model in world:FindFirstChild(folderName) and world[folderName]:GetChildren() or {} do
			if model:IsA("Model") and model:GetPivot().Position.Z < finishZ then
				model:Destroy()
			end
		end
	end
end
for _, folderName in if endless then {} else { "Ground", "Walls", "Obstacles", "Decor", "Funnel" } do
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
