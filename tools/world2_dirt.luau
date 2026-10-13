-- World 2 base and Meadow dirt in World 1's base dirt colours (QM, Oct 13). Run in Studio (Edit) after the floor scripts.
local R = workspace:FindFirstChild("World2") or workspace.World
local a, b = Color3.fromRGB(206, 146, 84), Color3.fromRGB(222, 164, 100)
local n = 0
for _, p in R.Ground:GetChildren() do
	if p.Name == "Dirt" and p.Position.Z > -2168 then
		p.Color = a
		for _, t in p:GetChildren() do if t.Name == "Checker" then t.Color3 = b end end
		n += 1
	end
end
return n .. " dirt tiles"
