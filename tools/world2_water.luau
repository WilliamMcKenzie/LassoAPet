-- World 2's ponds flow (QM, Oct 13): every floor part named Water or DeepWater gets QM's
-- water tile (Config.Water.Image) on its top as a Texture named "Water", which
-- Client/WaterFlow slides along; their own stud and checker textures go. The deep water's
-- a shade darker. Run in Studio (Edit) after tools/world2_temple.luau, on the World 2 Place
-- (workspace.World) or World 1's copy (World2). Re-running is fine.
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local IMAGE = "rbxassetid://77807866797953" -- (Config.Water.Image)
local TINT = { Water = Color3.new(1, 1, 1), DeepWater = Color3.fromRGB(170, 170, 170) }
local n = 0
for _, p in ROOT.Ground:GetChildren() do
	local tint = TINT[p.Name]
	if tint then
		for _, t in p:GetChildren() do
			if t:IsA("Texture") or t:IsA("Decal") then
				t:Destroy()
			end
		end
		local water = Instance.new("Texture")
		water.Name = "Water"
		water.Face = Enum.NormalId.Top
		water.Texture = IMAGE
		water.StudsPerTileU, water.StudsPerTileV = 8, 8
		water.Color3 = tint
		water.Parent = p
		n += 1
	end
end
return n .. " water tiles flowing"
