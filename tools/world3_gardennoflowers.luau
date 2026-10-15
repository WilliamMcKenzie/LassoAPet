-- World 3 (QM, Oct 15): no pink patches in the Garden: every Flowers tile (top 2) becomes the light
-- lawn round it (Grass, top 1).
local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Name = "ConfigCopy"; m.Parent = game.ReplicatedStorage.Shared
local C = require(m); m:Destroy()
local g = C.Biomes[2].Patches.Grass
local n = 0
for _, p in workspace.World.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Name == "Flowers" and p.Position.Z <= -4336 and p.Position.Z > -7968 then
		p.Name = "Grass"
		local top = p.Position.Y + p.Size.Y / 2
		local drop = top - 1
		p.Size -= Vector3.new(0, drop, 0)
		p.Position -= Vector3.new(0, drop / 2, 0)
		p.Color = g[1]
		for _, t in p:GetChildren() do if t.Name == "Checker" then t.Color3 = g[2] end end
		n += 1
	end
end
return n .. " pink patches turned to lawn"
