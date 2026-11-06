-- Each biome's fog (QM, Nov 6; Shared/BiomeFog): eases to the fog of the biome the camera's
-- looking at, from workspace.Fog. A place without workspace.Fog keeps Lighting's own.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BiomeFog = require(ReplicatedStorage.Shared.BiomeFog)

local camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function(dt)
	BiomeFog.step(camera.Focus.Position.Z, dt)
end)
