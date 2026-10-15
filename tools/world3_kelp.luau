-- World 3 kelp and sea fan colours (QM, Oct 15): Kelp_1 29,122,137, Kelp_2 33,138,155; SeaFan_1-3
-- 161,133,255 / 154,126,242 / 127,105,201, in the course and in
-- ServerStorage.World3Assets (what tools/world3_props.luau places on a re-run).
local C = {
	Kelp = { Kelp_1 = Color3.fromRGB(29, 122, 137), Kelp_2 = Color3.fromRGB(33, 138, 155) },
	Staghorn = { Staghorn_1 = Color3.fromHex("54F7E0"), Staghorn_2 = Color3.fromHex("54F7E0") }, -- (QM, Oct 15)
	Anemone = { Anemone_1 = Color3.fromHex("D38AE0"), Anemone_2 = Color3.fromHex("D38AE0"), Anemone_3 = Color3.fromHex("D38AE0"), Anemone_4 = Color3.fromHex("D38AE0") }, -- (QM, Oct 15)
	BrainCoral = { BrainCoral_1 = Color3.fromRGB(154, 126, 242), BrainCoral_2 = Color3.fromRGB(132, 109, 209) }, -- (QM, Oct 15)
	SeaFan = { SeaFan_1 = Color3.fromRGB(161, 133, 255), SeaFan_2 = Color3.fromRGB(154, 126, 242), SeaFan_3 = Color3.fromRGB(127, 105, 201) },
}
local n = 0
for _, root in { workspace, game.ServerStorage:FindFirstChild("World3Assets") } do
	for _, d in root and root:GetDescendants() or {} do
		local c = d:IsA("BasePart") and C[d.Parent.Name] and C[d.Parent.Name][d.Name]
		if c then
			d.Color = c
			n += 1
		end
	end
end
return n .. " kelp and coral parts recoloured"
