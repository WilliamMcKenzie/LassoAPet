-- World 2's grass and pine needles 20% brighter (QM, Oct 13): the first biome's and the
-- base's Ground and Grass (part and checker), the pines' needles and the grass tufts.
-- Run once in Studio (Edit) on the World 2 Place (workspace.World) or World 1's copy (World2).
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local K = 1.2
local function up(c)
	return Color3.new(math.min(c.R * K, 1), math.min(c.G * K, 1), math.min(c.B * K, 1))
end
local n = 0
for _, folder in { ROOT.Ground, ROOT.Funnel } do
	for _, p in folder:GetChildren() do
		if (p.Name == "Ground" or p.Name == "Grass") and p.Position.Z > -2168 then
			p.Color = up(p.Color)
			for _, t in p:GetChildren() do
				if t.Name == "Checker" then
					t.Color3 = up(t.Color3)
				end
			end
			n += 1
		end
	end
end
for _, m in ROOT.BaseDecor.Plants:GetChildren() do
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and (m.Name == "GrassTuft" or (m.Name:match("^Pine") and not p.Name:match("_1$"))) then
			p.Color = up(p.Color)
			n += 1
		end
	end
end
return n .. " brightened"
