-- World 3's base: water back in every cell of the base's floor that has no tile (top -2, QM's tile).
local G = workspace.World.Ground
local CELL = 8
local I0, I1, J0, J1 = -27, 26, 0, 39
local C = require((function() local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Parent = game.ReplicatedStorage.Shared; return m end)())
local function key(i, j) return i * 100000 + j end
local have, template = {}, nil
for _, p in G:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z > 0 then
		local lo = p.Position - p.Size / 2
		for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
			for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do have[key(math.floor(x / CELL), math.floor(z / CELL))] = true end
		end
		if not template and p.Name == "WetSand" then template = p end
	end
end
local n = 0
for i = I0, I1 do
	for j = J0, J1 do
		if not have[key(i, j)] then
			local p = template:Clone()
			for _, c in p:GetChildren() do c:Destroy() end
			p.Name = "Water"
			p.Size = Vector3.new(CELL, template.Size.Y, CELL)
			p.Position = Vector3.new(i * CELL + CELL / 2, -2 - template.Size.Y / 2, j * CELL + CELL / 2)
			p.Color = Color3.fromRGB(49, 170, 235)
			local t = Instance.new("Texture")
			t.Name = "Water"; t.Face = Enum.NormalId.Top; t.Texture = C.Water.Image
			t.StudsPerTileU, t.StudsPerTileV = 8, 8; t.Color3 = Color3.fromRGB(150, 200, 255)
			t.Parent = p
			p.Parent = G
			n += 1
		end
	end
end
for _, m in game.ReplicatedStorage.Shared:GetChildren() do if m.Name == "Config" and m ~= game.ReplicatedStorage.Shared.Config then m:Destroy() end end
return n .. " base water cells restored"
