-- World 3 kelp colours (QM, Oct 15): Kelp_1 29,122,137, Kelp_2 33,138,155, in the course and in
-- ServerStorage.World3Assets (what tools/world3_props.luau places on a re-run).
local C = { Kelp_1 = Color3.fromRGB(29, 122, 137), Kelp_2 = Color3.fromRGB(33, 138, 155) }
local n = 0
for _, root in { workspace, game.ServerStorage:FindFirstChild("World3Assets") } do
	for _, d in root and root:GetDescendants() or {} do
		if d:IsA("BasePart") and d.Parent.Name == "Kelp" and C[d.Name] then
			d.Color = C[d.Name]
			n += 1
		end
	end
end
return n .. " kelp parts recoloured"
