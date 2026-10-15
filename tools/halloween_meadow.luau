-- The Halloween world's Meadow recoloured to match its base (QM, Oct 15): the rocks in
-- QM's purple greys (as he set the base's: the lighter piece 147,117,155, the darker
-- 128,102,135), and the ground, walls and wall tops as Config's World 4 block paints them
-- in game (so Studio shows it too). Run in Studio (Edit) on the Halloween Place; re-running is fine.
local rgb = Color3.fromRGB
local LIGHT, DARK = rgb(147, 117, 155), rgb(128, 102, 135)
local C = {
	Ground = { rgb(121, 65, 137), rgb(113, 61, 130) },
	Grass = { rgb(100, 55, 105), rgb(92, 51, 97) },
	Dirt = { rgb(159, 136, 179), rgb(153, 130, 174) },
	Wall = { rgb(63, 38, 77), rgb(74, 44, 87) },
}
local CAP = rgb(240, 128, 200)
local W = workspace.World
local function inMeadow(p)
	return p.Position.Z < 0 and p.Position.Z > -2168
end
local function paint(p, c)
	p.Color = c[1]
	for _, t in p:GetChildren() do
		if t:IsA("Texture") then
			t.Color3 = c[2]
		end
	end
end
local rocks, floor, walls = 0, 0, 0
for _, model in W.Obstacles:GetChildren() do
	if model.Name:sub(1, 4) == "Rock" then
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and inMeadow(p) and (p.Name == "Rock" or p.Name == "Rock1" or p.Name == "Rock2") then
				p.Color = if p.Name == "Rock2" then DARK else LIGHT
				rocks += 1
			end
		end
	end
end
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and inMeadow(p) and C[p.Name] then
		paint(p, C[p.Name])
		floor += 1
	end
end
for _, p in W.Walls:GetChildren() do
	if p:IsA("BasePart") and inMeadow(p) then
		if p.Name == "Cap" then
			p.Color = CAP
			walls += 1
		elseif p.Name == "Wall" then
			paint(p, C.Wall)
			walls += 1
		end
	end
end
return string.format("%d rock pieces, %d floor parts, %d wall parts", rocks, floor, walls)
