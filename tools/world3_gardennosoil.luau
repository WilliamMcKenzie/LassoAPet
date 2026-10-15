-- World 3 (QM, Oct 15): no dirt patches in the Garden: every Soil tile becomes the lawn round it
-- (Ground, its top raised from -1 to the lawn's 0).
local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Name = "ConfigCopy"; m.Parent = game.ReplicatedStorage.Shared
local C = require(m); m:Destroy()
local g = C.Biomes[2].GroundColors
local n = 0
for _, p in workspace.World.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Name == "Soil" and p.Position.Z <= -4336 and p.Position.Z > -7968 then
		p.Name = "Ground"
		local top = p.Position.Y + p.Size.Y / 2
		p.Size += Vector3.new(0, -top, 0) -- (top -1 to 0)
		p.Position += Vector3.new(0, -top / 2, 0)
		p.Color = g[1]
		for _, t in p:GetChildren() do if t.Name == "Checker" then t.Color3 = g[2] end end
		n += 1
	end
end
return n .. " dirt patches turned to lawn"
