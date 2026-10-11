-- A biome's own sky (QM, Oct 11: the Volcano's lava orange): while the camera's over a
-- biome with a Sky (Config.Biomes[i].Sky, a flat image), the Sky's six faces show it;
-- anywhere else they're put back as World.server made them. A Skybox can't be tinted,
-- so it's a swap at the biome's line.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local FACES = { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }
local usual -- [face] = World.server's image
local showing -- the biome sky up now (nil: the usual)

RunService.RenderStepped:Connect(function()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		return
	end
	local z = workspace.CurrentCamera.CFrame.Position.Z
	local want = if z < 0 then Config.Biomes[WorldColors.biomeAt(z)].Sky else nil
	if want == showing then
		return
	end
	if not usual then
		usual = {}
		for _, face in FACES do
			usual[face] = sky["Skybox" .. face]
		end
	end
	for _, face in FACES do
		sky["Skybox" .. face] = want or usual[face]
	end
	showing = want
end)
