-- World 3 (QM, Oct 15): the shallow ring only about 10% lighter than the water: the same tile, opaque,
-- tinted 10% brighter, over a 10% lighter blue.
local n = 0
for _, p in workspace.World.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Name == "ShallowWater" then
		p.Color = Color3.fromRGB(70, 180, 237)
		for _, t in p:GetChildren() do
			if t:IsA("Texture") and t.Name == "Water" then t.Transparency = 0; t.Color3 = Color3.fromRGB(165, 220, 255) end
		end
		n += 1
	end
end
return n .. " shallow water parts toned"
