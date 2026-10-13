-- Flowing water (QM, Oct 13: as RotMG's): QM's 8 x 8 water tile (assets/world2/WaterTile.png,
-- one pixel a stud) on the top of each water tile, every one slid along together each frame,
-- so the pattern flows across them all as one. Any Texture named "Water" under
-- workspace.World flows (the floor scripts lay them: Config.Water.Image, StudsPerTile
-- 8, on tiles on the 8-stud grid so they line up). Tint it with the Texture's Color3.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)

local WATER = Config.Water
local textures = {}

local function add(texture)
	if texture:IsA("Texture") and texture.Name == "Water" then
		textures[texture] = true
	end
end
local world = workspace:WaitForChild("World")
for _, d in world:GetDescendants() do
	add(d)
end
world.DescendantAdded:Connect(add)
world.DescendantRemoving:Connect(function(d)
	textures[d] = nil
end)

local u, v = 0, 0
RunService.RenderStepped:Connect(function(dt)
	if not next(textures) then
		return
	end
	local tile = WATER.StudsPerTile
	u = (u + WATER.Flow.X * dt) % tile
	v = (v + WATER.Flow.Y * dt) % tile
	for texture in textures do
		texture.OffsetStudsU = u
		texture.OffsetStudsV = v
	end
end)
