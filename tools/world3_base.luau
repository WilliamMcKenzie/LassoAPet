-- World 3's home base, a tropical island (QM, Oct 14). Made by tools/world3_base.py: edit
-- that and re-make this, not this. Run in Studio (Edit, execute_luau) on the World 3 Place
-- (workspace.World). Re-running is fine.
-- 1.2x the old base (x -216..216, z 0..328) so the pens can grow to 104: the base's walls
-- move out to it. Sand, wet sand on the paths and round the lagoons, grass patches a stud
-- up, and lagoons of the flowing water tile (a Texture named "Water", Client/WaterFlow) a
-- stud down. Replaces the base floor (its ArcBase parts), drops base decor now standing in
-- water or past the new walls' old line, and moves the rest with the floor under it.
-- In game the floor takes Config's Meadow colours by part name: Ground (sand), and the
-- Patches WetSand, Grass and Water (World 3's block in Config).
local W = workspace.World
local rgb = Color3.fromRGB
local WATER_IMAGE = "rbxassetid://77807866797953" -- (Config.Water.Image)
local KINDS = { -- [kind] = { name, top, part colour, checker colour }
	[0] = { "Ground", 0, rgb(240, 218, 160), rgb(230, 206, 146) }, -- sand
	[1] = { "WetSand", 0, rgb(206, 172, 110), rgb(194, 160, 98) },
	[2] = { "Grass", 1, rgb(96, 204, 60), rgb(84, 188, 50) },
	[3] = { "Water", -1, rgb(37, 81, 40), rgb(37, 81, 40) }, -- (its sides match the tile)
}
-- The base's walls and caps: { which, centre, size } (tools/arc_base.luau's, 1.2x out)
local WALLS = {
	{ "back", "Wall", Vector3.new(0, 24, 324), Vector3.new(448, 48, 8) },
	{ "back", "Cap", Vector3.new(0, 49, 323), Vector3.new(448, 2, 10) },
	{ "left", "Wall", Vector3.new(-220, 24, 160), Vector3.new(8, 48, 328) },
	{ "left", "Cap", Vector3.new(-219, 49, 164), Vector3.new(10, 2, 316) },
	{ "right", "Wall", Vector3.new(220, 24, 160), Vector3.new(8, 48, 328) },
	{ "right", "Cap", Vector3.new(219, 49, 164), Vector3.new(10, 2, 316) },
	{ "frontleft", "Wall", Vector3.new(-140, 24, -4), Vector3.new(168, 48, 8) },
	{ "frontleft", "Cap", Vector3.new(-143, 49, -3), Vector3.new(178, 2, 10) },
	{ "frontright", "Wall", Vector3.new(140, 24, -4), Vector3.new(168, 48, 8) },
	{ "frontright", "Cap", Vector3.new(143, 49, -3), Vector3.new(178, 2, 10) },
}
-- { kind, low x, low z, size x, size z } on 8-stud cells
local FLOOR = {
	{ 2, -216, 0, 72, 24 },
	{ 0, -216, 24, 8, 32 },
	{ 2, -216, 56, 16, 32 },
	{ 0, -216, 88, 16, 88 },
	{ 2, -216, 176, 8, 40 },
	{ 0, -216, 216, 432, 8 },
	{ 2, -216, 224, 8, 104 },
	{ 0, -208, 24, 8, 24 },
	{ 2, -208, 48, 8, 8 },
	{ 2, -208, 176, 8, 32 },
	{ 0, -208, 208, 416, 8 },
	{ 0, -208, 224, 424, 8 },
	{ 2, -208, 232, 8, 96 },
	{ 2, -200, 24, 8, 8 },
	{ 0, -200, 32, 8, 136 },
	{ 2, -200, 168, 8, 16 },
	{ 0, -200, 184, 104, 24 },
	{ 0, -200, 232, 96, 40 },
	{ 2, -200, 272, 16, 56 },
	{ 0, -192, 24, 16, 128 },
	{ 2, -192, 152, 32, 24 },
	{ 0, -192, 176, 16, 8 },
	{ 2, -184, 272, 16, 48 },
	{ 0, -184, 320, 272, 8 },
	{ 0, -176, 24, 80, 120 },
	{ 2, -176, 144, 16, 8 },
	{ 2, -176, 176, 8, 8 },
	{ 0, -168, 176, 72, 8 },
	{ 0, -168, 272, 56, 8 },
	{ 2, -168, 280, 8, 32 },
	{ 0, -168, 312, 248, 8 },
	{ 0, -160, 144, 64, 8 },
	{ 2, -160, 152, 8, 16 },
	{ 0, -160, 168, 64, 8 },
	{ 0, -160, 280, 48, 8 },
	{ 2, -160, 288, 8, 16 },
	{ 0, -160, 304, 48, 8 },
	{ 2, -152, 152, 8, 8 },
	{ 0, -152, 160, 48, 8 },
	{ 0, -152, 288, 40, 16 },
	{ 0, -144, 0, 40, 24 },
	{ 0, -144, 152, 48, 8 },
	{ 1, -112, 272, 8, 40 },
	{ 0, -104, 0, 8, 8 },
	{ 2, -104, 8, 32, 8 },
	{ 0, -104, 16, 8, 8 },
	{ 2, -104, 160, 16, 8 },
	{ 0, -104, 232, 168, 24 },
	{ 1, -104, 256, 16, 24 },
	{ 3, -104, 280, 32, 24 },
	{ 1, -104, 304, 40, 8 },
	{ 2, -96, 0, 24, 8 },
	{ 2, -96, 16, 8, 8 },
	{ 0, -96, 24, 16, 32 },
	{ 1, -96, 56, 16, 48 },
	{ 0, -96, 104, 8, 40 },
	{ 2, -96, 144, 8, 16 },
	{ 2, -96, 168, 8, 8 },
	{ 1, -96, 176, 16, 16 },
	{ 0, -96, 192, 24, 16 },
	{ 0, -88, 16, 24, 8 },
	{ 0, -88, 104, 8, 8 },
	{ 2, -88, 112, 8, 40 },
	{ 0, -88, 152, 16, 16 },
	{ 1, -88, 168, 32, 8 },
	{ 1, -88, 256, 8, 16 },
	{ 3, -88, 272, 24, 8 },
	{ 0, -80, 24, 8, 16 },
	{ 1, -80, 40, 8, 24 },
	{ 3, -80, 64, 40, 16 },
	{ 1, -80, 80, 8, 32 },
	{ 2, -80, 112, 24, 32 },
	{ 0, -80, 144, 24, 8 },
	{ 1, -80, 176, 16, 8 },
	{ 0, -80, 184, 8, 8 },
	{ 0, -80, 256, 136, 8 },
	{ 1, -80, 264, 24, 8 },
	{ 0, -72, 0, 16, 16 },
	{ 0, -72, 24, 8, 8 },
	{ 1, -72, 32, 8, 24 },
	{ 3, -72, 56, 40, 8 },
	{ 3, -72, 80, 24, 8 },
	{ 1, -72, 88, 160, 24 },
	{ 1, -72, 152, 48, 16 },
	{ 1, -72, 184, 8, 16 },
	{ 0, -72, 200, 8, 8 },
	{ 3, -72, 280, 8, 16 },
	{ 1, -72, 296, 16, 8 },
	{ 1, -64, 16, 24, 16 },
	{ 0, -64, 32, 8, 8 },
	{ 1, -64, 40, 8, 16 },
	{ 3, -64, 176, 48, 16 },
	{ 1, -64, 192, 8, 16 },
	{ 1, -64, 272, 8, 24 },
	{ 0, -64, 304, 120, 8 },
	{ 0, -56, 0, 40, 8 },
	{ 1, -56, 8, 16, 8 },
	{ 1, -56, 32, 8, 16 },
	{ 3, -56, 48, 24, 8 },
	{ 1, -56, 112, 104, 24 },
	{ 2, -56, 136, 8, 8 },
	{ 1, -56, 144, 32, 8 },
	{ 3, -56, 168, 32, 8 },
	{ 3, -56, 192, 32, 8 },
	{ 1, -56, 200, 64, 8 },
	{ 0, -56, 264, 112, 40 },
	{ 3, -48, 32, 16, 16 },
	{ 1, -48, 80, 104, 8 },
	{ 1, -48, 136, 96, 8 },
	{ 0, -40, 8, 24, 8 },
	{ 1, -40, 16, 16, 8 },
	{ 3, -40, 24, 8, 8 },
	{ 3, -40, 64, 8, 8 },
	{ 1, -40, 72, 72, 8 },
	{ 1, -32, 24, 56, 8 },
	{ 3, -32, 32, 8, 8 },
	{ 1, -32, 40, 56, 32 },
	{ 0, -24, 16, 8, 8 },
	{ 1, -24, 32, 48, 8 },
	{ 0, -24, 144, 16, 16 },
	{ 1, -24, 160, 8, 16 },
	{ 1, -24, 192, 32, 8 },
	{ 1, -16, 0, 32, 24 },
	{ 0, -16, 160, 8, 8 },
	{ 1, -16, 168, 24, 24 },
	{ 1, -8, 144, 16, 24 },
	{ 1, 8, 144, 8, 8 },
	{ 0, 8, 152, 16, 32 },
	{ 2, 8, 184, 24, 16 },
	{ 0, 8, 200, 192, 8 },
	{ 1, 16, 0, 8, 8 },
	{ 0, 16, 8, 32, 8 },
	{ 1, 16, 16, 8, 8 },
	{ 0, 16, 144, 8, 8 },
	{ 0, 24, 0, 56, 8 },
	{ 0, 24, 16, 8, 56 },
	{ 2, 24, 144, 8, 40 },
	{ 0, 32, 16, 8, 16 },
	{ 1, 32, 32, 16, 16 },
	{ 0, 32, 48, 8, 32 },
	{ 1, 32, 144, 24, 8 },
	{ 2, 32, 152, 8, 40 },
	{ 0, 32, 192, 160, 8 },
	{ 1, 40, 16, 8, 16 },
	{ 1, 40, 48, 8, 32 },
	{ 1, 40, 152, 24, 8 },
	{ 2, 40, 160, 8, 24 },
	{ 0, 40, 184, 40, 8 },
	{ 1, 48, 8, 8, 16 },
	{ 3, 48, 24, 24, 56 },
	{ 1, 48, 112, 8, 8 },
	{ 0, 48, 120, 8, 16 },
	{ 2, 48, 136, 40, 8 },
	{ 1, 48, 160, 24, 8 },
	{ 2, 48, 168, 8, 16 },
	{ 1, 56, 8, 40, 8 },
	{ 3, 56, 16, 24, 8 },
	{ 3, 56, 80, 16, 8 },
	{ 0, 56, 112, 152, 8 },
	{ 2, 56, 120, 32, 16 },
	{ 2, 56, 144, 40, 8 },
	{ 1, 56, 168, 24, 8 },
	{ 0, 56, 176, 8, 8 },
	{ 2, 56, 256, 24, 56 },
	{ 0, 64, 152, 8, 8 },
	{ 1, 64, 176, 32, 8 },
	{ 0, 64, 232, 152, 16 },
	{ 2, 64, 248, 8, 8 },
	{ 3, 72, 24, 8, 8 },
	{ 1, 72, 32, 24, 32 },
	{ 3, 72, 64, 8, 16 },
	{ 1, 72, 80, 16, 8 },
	{ 2, 72, 152, 24, 8 },
	{ 0, 72, 160, 16, 8 },
	{ 0, 72, 248, 96, 8 },
	{ 1, 80, 0, 16, 8 },
	{ 1, 80, 16, 16, 16 },
	{ 1, 80, 64, 8, 16 },
	{ 0, 80, 168, 80, 8 },
	{ 1, 80, 184, 16, 8 },
	{ 0, 80, 256, 80, 8 },
	{ 2, 80, 264, 8, 56 },
	{ 1, 88, 64, 8, 8 },
	{ 0, 88, 72, 128, 24 },
	{ 1, 88, 96, 8, 16 },
	{ 0, 88, 120, 120, 24 },
	{ 2, 88, 160, 8, 8 },
	{ 0, 88, 264, 64, 8 },
	{ 2, 88, 272, 8, 56 },
	{ 0, 96, 0, 8, 72 },
	{ 0, 96, 96, 120, 16 },
	{ 0, 96, 144, 56, 24 },
	{ 0, 96, 176, 88, 16 },
	{ 0, 96, 272, 56, 8 },
	{ 2, 96, 280, 8, 8 },
	{ 0, 96, 288, 64, 8 },
	{ 2, 96, 296, 8, 32 },
	{ 2, 104, 0, 48, 32 },
	{ 0, 104, 32, 112, 40 },
	{ 0, 104, 280, 48, 8 },
	{ 0, 104, 296, 56, 8 },
	{ 2, 104, 304, 32, 24 },
	{ 0, 136, 304, 24, 8 },
	{ 2, 136, 312, 8, 16 },
	{ 0, 144, 312, 8, 16 },
	{ 2, 152, 0, 64, 24 },
	{ 0, 152, 24, 40, 8 },
	{ 0, 152, 144, 8, 16 },
	{ 2, 152, 160, 32, 8 },
	{ 1, 152, 264, 16, 24 },
	{ 1, 152, 312, 40, 8 },
	{ 0, 152, 320, 64, 8 },
	{ 0, 160, 144, 32, 8 },
	{ 2, 160, 152, 16, 8 },
	{ 2, 160, 168, 16, 8 },
	{ 1, 160, 256, 56, 8 },
	{ 1, 160, 288, 8, 24 },
	{ 1, 168, 248, 8, 8 },
	{ 1, 168, 264, 8, 16 },
	{ 3, 168, 280, 24, 24 },
	{ 1, 168, 304, 32, 8 },
	{ 0, 176, 152, 40, 8 },
	{ 0, 176, 168, 40, 8 },
	{ 0, 176, 248, 40, 8 },
	{ 1, 176, 264, 8, 8 },
	{ 3, 176, 272, 24, 8 },
	{ 0, 184, 160, 32, 8 },
	{ 2, 184, 176, 32, 16 },
	{ 3, 184, 264, 8, 8 },
	{ 2, 192, 24, 8, 8 },
	{ 2, 192, 144, 24, 8 },
	{ 2, 192, 192, 24, 8 },
	{ 1, 192, 264, 24, 8 },
	{ 3, 192, 280, 8, 16 },
	{ 1, 192, 296, 16, 8 },
	{ 0, 192, 312, 24, 8 },
	{ 0, 200, 24, 16, 8 },
	{ 2, 200, 200, 16, 8 },
	{ 1, 200, 272, 8, 24 },
	{ 0, 200, 304, 16, 8 },
	{ 2, 208, 112, 8, 32 },
	{ 2, 208, 208, 8, 8 },
	{ 0, 208, 272, 8, 32 },
}

local function floorAt(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { W.Ground }
	local hit = workspace:Raycast(Vector3.new(pos.X, 50, pos.Z), Vector3.new(0, -100, 0), params)
	return if hit then hit.Position.Y else 0
end

-- What stands on the base, and the floor's height under it before.
local standing = {}
local function note(inst)
	if inst:IsA("Model") or inst:IsA("BasePart") then
		table.insert(standing, { inst, floorAt(inst:GetPivot().Position) })
	end
end
local decor = W:FindFirstChild("BaseDecor")
for _, inst in decor and decor:GetChildren() or {} do
	if inst:IsA("Folder") then
		for _, m in inst:GetChildren() do
			note(m)
		end
	else
		note(inst)
	end
end
local spawn = W:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("SpawnLocation")
if spawn then
	note(spawn)
end

-- The walls: which is which by where they are (as tools/arc_base.luau).
local moved = 0
for _, p in W.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Cap") and p.Position.Z + p.Size.Z / 2 > -10 then
		local x, z = p.Position.X, p.Position.Z
		local which = if z > 200 and p.Size.X > p.Size.Z then "back"
			elseif p.Size.Z > p.Size.X and x < -100 then "left"
			elseif p.Size.Z > p.Size.X and x > 100 then "right"
			elseif z < 0 and x < 0 then "frontleft"
			elseif z < 0 and x > 0 then "frontright"
			else nil
		for _, w in WALLS do
			if which and w[1] == which and w[2] == p.Name then
				p.Size = w[4]
				p.CFrame = CFrame.new(w[3])
				moved += 1
			end
		end
	end
end

local template
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("ArcBase") then
		template = template or p:Clone()
		p:Destroy()
	end
end
assert(template, "no ArcBase floor in World.Ground to copy the look of")
for _, t in template:GetChildren() do
	if not t:IsA("Texture") then
		t:Destroy()
	end
end
for _, r in FLOOR do
	local k = KINDS[r[1]]
	local x, z, sx, sz = r[2], r[3], r[4], r[5]
	local p = template:Clone()
	p.Name = k[1]
	p.Size = Vector3.new(sx, k[2] + 2, sz)
	p.CFrame = CFrame.new(x + sx / 2, (k[2] - 2) / 2, z + sz / 2)
	p.Color = k[3]
	for _, t in p:GetChildren() do
		if k[1] == "Water" then
			t:Destroy()
		else
			t.Color3 = k[4]
		end
	end
	if k[1] == "Water" then
		local water = Instance.new("Texture")
		water.Name = "Water"
		water.Face = Enum.NormalId.Top
		water.Texture = WATER_IMAGE
		water.StudsPerTileU, water.StudsPerTileV = 8, 8
		water.Parent = p
	end
	p.Parent = W.Ground
end

local function kindAt(x, z)
	for _, r in FLOOR do
		if x >= r[2] and x < r[2] + r[4] and z >= r[3] and z < r[3] + r[5] then
			return r[1]
		end
	end
	return nil
end
local dropped, lifted = 0, 0
for _, s in standing do
	local inst, before = s[1], s[2]
	local at = inst:GetPivot().Position
	if inst ~= spawn and kindAt(at.X, at.Z) == 3 then
		inst:Destroy() -- (in a lagoon)
		dropped += 1
	else
		local dy = floorAt(at) - before
		if math.abs(dy) > 0.01 then
			inst:PivotTo(inst:GetPivot() + Vector3.new(0, dy, 0))
			lifted += 1
		end
	end
end
return string.format("%d floor parts, %d walls moved, %d decor in the water dropped, %d moved with the floor", #FLOOR, moved, dropped, lifted)
