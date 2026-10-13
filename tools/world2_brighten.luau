-- World 2's grass and pine needles 40% darker (QM, Oct 13; tried 20% brighter first): the
-- first biome's and the base's Ground and Grass (part and checker), the pines' needles and
-- the grass tufts. Run in Studio (Edit) on the World 2 Place (workspace.World) or World 1's
-- copy (World2) right after tools/world2_base.luau and world2_meadow_ground.luau (which lay
-- the floor in its first colours); the needles and tufts are reset to theirs here.
local ROOT = workspace:FindFirstChild("World2") or workspace.World
local K = 0.6
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
local rgb = Color3.fromRGB
local NEEDLES = { rgb(231, 182, 88), rgb(214, 166, 74), rgb(242, 196, 104), rgb(222, 172, 80) } -- (tools/world2_base_plants.luau's)
local TUFTS = { rgb(231, 182, 88), rgb(214, 166, 74) }
for _, m in ROOT.BaseDecor.Plants:GetChildren() do
	for i, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			local k = tonumber(p.Name:match("_(%d+)$"))
			if m.Name == "GrassTuft" then
				p.Color = up(TUFTS[i % 2 + 1])
				n += 1
			elseif m.Name:match("^Pine") and k and k > 1 then
				p.Color = up(NEEDLES[(k - 2) % #NEEDLES + 1])
				n += 1
			end
		end
	end
end
return n .. " brightened"
