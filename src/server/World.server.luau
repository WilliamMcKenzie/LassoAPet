-- The map itself (ground, corridor walls, obstacles, home base, pen and egg
-- nest) is a saved model: src/world/World.rbxmx, synced by Rojo into
-- Workspace.World, so it can be edited by hand in Studio. This script only sets
-- the sky, turns on the live colour attributes and marks the world ready.

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
require(ReplicatedStorage.Shared.WorldColors).watch(world)
world:SetAttribute("Ready", true)
