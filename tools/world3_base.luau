-- World 3's home base, a tropical island (QM, Oct 14). Made by tools/world3_base.py: edit
-- that and re-make this, not this. Run in Studio (Edit, execute_luau) on the World 3 Place
-- (workspace.World). Re-running is fine.
-- 1.2x the old base (x -216..216, z 0..328) so the pens can grow to 104: the base's walls
-- move out to it. Water with sand islands round the pens, joined to a central sandbar, wet
-- sand round the shores, and lagoons of the flowing water tile (a Texture named "Water", Client/WaterFlow) a
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
	{ 3, -216, 0, 8, 104 },
	{ 1, -216, 104, 24, 8 },
	{ 0, -216, 112, 112, 24 },
	{ 1, -216, 136, 64, 8 },
	{ 3, -216, 144, 24, 56 },
	{ 1, -216, 200, 32, 8 },
	{ 0, -216, 208, 216, 16 },
	{ 1, -216, 224, 16, 8 },
	{ 3, -216, 232, 8, 96 },
	{ 3, -208, 0, 104, 16 },
	{ 1, -208, 16, 8, 88 },
	{ 1, -208, 232, 24, 8 },
	{ 3, -208, 240, 8, 88 },
	{ 1, -200, 16, 32, 8 },
	{ 0, -200, 24, 16, 16 },
	{ 1, -200, 40, 8, 64 },
	{ 0, -200, 224, 416, 8 },
	{ 1, -200, 240, 24, 16 },
	{ 3, -200, 256, 8, 72 },
	{ 0, -192, 40, 32, 72 },
	{ 3, -192, 144, 8, 48 },
	{ 1, -192, 192, 32, 8 },
	{ 1, -192, 256, 32, 8 },
	{ 3, -192, 264, 8, 64 },
	{ 1, -184, 24, 40, 8 },
	{ 0, -184, 32, 24, 8 },
	{ 3, -184, 144, 8, 40 },
	{ 1, -184, 184, 40, 8 },
	{ 0, -184, 200, 8, 8 },
	{ 0, -184, 232, 376, 8 },
	{ 1, -184, 264, 24, 8 },
	{ 3, -184, 272, 8, 56 },
	{ 1, -176, 144, 32, 8 },
	{ 3, -176, 152, 16, 24 },
	{ 1, -176, 176, 40, 8 },
	{ 1, -176, 200, 8, 8 },
	{ 0, -176, 240, 232, 16 },
	{ 1, -176, 272, 32, 16 },
	{ 3, -176, 288, 16, 40 },
	{ 3, -168, 16, 64, 8 },
	{ 0, -168, 200, 88, 8 },
	{ 1, -160, 32, 16, 16 },
	{ 0, -160, 48, 64, 64 },
	{ 3, -160, 152, 8, 16 },
	{ 1, -160, 168, 16, 8 },
	{ 0, -160, 192, 80, 8 },
	{ 0, -160, 256, 56, 16 },
	{ 1, -160, 288, 32, 16 },
	{ 3, -160, 304, 8, 24 },
	{ 0, -152, 136, 48, 8 },
	{ 1, -152, 152, 8, 16 },
	{ 1, -152, 304, 8, 16 },
	{ 3, -152, 320, 8, 8 },
	{ 3, -144, 24, 16, 8 },
	{ 1, -144, 32, 24, 8 },
	{ 0, -144, 40, 64, 8 },
	{ 0, -144, 144, 40, 32 },
	{ 0, -144, 184, 64, 8 },
	{ 0, -144, 272, 32, 16 },
	{ 0, -144, 304, 8, 8 },
	{ 1, -144, 312, 8, 16 },
	{ 0, -136, 176, 64, 8 },
	{ 1, -136, 304, 8, 16 },
	{ 3, -136, 320, 72, 8 },
	{ 1, -128, 24, 40, 8 },
	{ 0, -128, 288, 8, 8 },
	{ 1, -128, 296, 8, 16 },
	{ 3, -128, 312, 64, 8 },
	{ 0, -120, 32, 40, 8 },
	{ 1, -120, 288, 8, 16 },
	{ 3, -120, 304, 56, 8 },
	{ 0, -112, 272, 8, 8 },
	{ 1, -112, 280, 8, 16 },
	{ 3, -112, 296, 48, 8 },
	{ 3, -104, 0, 8, 8 },
	{ 1, -104, 8, 24, 16 },
	{ 0, -104, 112, 8, 8 },
	{ 1, -104, 120, 8, 32 },
	{ 0, -104, 152, 8, 24 },
	{ 1, -104, 256, 8, 32 },
	{ 3, -104, 288, 40, 8 },
	{ 1, -96, 0, 8, 8 },
	{ 0, -96, 48, 8, 56 },
	{ 1, -96, 104, 8, 40 },
	{ 0, -96, 144, 8, 8 },
	{ 1, -96, 152, 16, 16 },
	{ 0, -96, 168, 32, 8 },
	{ 1, -96, 256, 8, 24 },
	{ 3, -96, 280, 32, 8 },
	{ 0, -88, 0, 24, 8 },
	{ 0, -88, 24, 16, 8 },
	{ 0, -88, 48, 8, 8 },
	{ 1, -88, 56, 16, 16 },
	{ 0, -88, 72, 8, 16 },
	{ 1, -88, 88, 32, 32 },
	{ 3, -88, 120, 16, 16 },
	{ 1, -88, 136, 8, 16 },
	{ 1, -88, 256, 8, 16 },
	{ 3, -88, 272, 24, 8 },
	{ 0, -80, 8, 8, 16 },
	{ 1, -80, 32, 16, 24 },
	{ 1, -80, 72, 8, 16 },
	{ 3, -80, 136, 16, 16 },
	{ 1, -80, 152, 24, 8 },
	{ 0, -80, 160, 24, 8 },
	{ 1, -80, 184, 8, 24 },
	{ 1, -80, 256, 16, 8 },
	{ 3, -80, 264, 8, 8 },
	{ 0, -72, 8, 8, 8 },
	{ 1, -72, 16, 24, 16 },
	{ 3, -72, 56, 16, 32 },
	{ 1, -72, 120, 24, 8 },
	{ 3, -72, 128, 8, 8 },
	{ 1, -72, 176, 8, 16 },
	{ 3, -72, 192, 16, 8 },
	{ 1, -72, 200, 24, 8 },
	{ 1, -72, 264, 16, 8 },
	{ 1, -64, 0, 8, 16 },
	{ 0, -64, 32, 8, 8 },
	{ 1, -64, 40, 16, 8 },
	{ 3, -64, 48, 32, 8 },
	{ 1, -64, 128, 16, 8 },
	{ 3, -64, 136, 8, 8 },
	{ 1, -64, 144, 16, 8 },
	{ 1, -64, 168, 8, 16 },
	{ 3, -64, 184, 48, 8 },
	{ 0, -64, 256, 112, 8 },
	{ 1, -64, 272, 8, 56 },
	{ 1, -56, 0, 40, 8 },
	{ 3, -56, 8, 24, 8 },
	{ 1, -56, 32, 8, 8 },
	{ 3, -56, 56, 8, 24 },
	{ 1, -56, 80, 16, 16 },
	{ 0, -56, 96, 8, 16 },
	{ 1, -56, 112, 8, 8 },
	{ 1, -56, 136, 8, 8 },
	{ 0, -56, 152, 8, 8 },
	{ 1, -56, 160, 8, 16 },
	{ 3, -56, 176, 40, 8 },
	{ 1, -56, 192, 24, 8 },
	{ 0, -56, 264, 104, 64 },
	{ 3, -48, 16, 16, 32 },
	{ 3, -48, 56, 8, 16 },
	{ 1, -48, 72, 16, 8 },
	{ 1, -48, 96, 8, 8 },
	{ 0, -48, 104, 8, 48 },
	{ 1, -48, 152, 8, 16 },
	{ 3, -48, 168, 32, 8 },
	{ 0, -48, 200, 8, 8 },
	{ 3, -40, 56, 8, 8 },
	{ 1, -40, 64, 16, 8 },
	{ 0, -40, 80, 80, 8 },
	{ 1, -40, 88, 8, 8 },
	{ 0, -40, 96, 88, 48 },
	{ 1, -40, 144, 16, 16 },
	{ 3, -40, 160, 24, 8 },
	{ 1, -40, 200, 112, 8 },
	{ 1, -32, 8, 8, 56 },
	{ 0, -32, 72, 8, 8 },
	{ 0, -32, 88, 72, 8 },
	{ 3, -32, 192, 16, 8 },
	{ 0, -24, 8, 40, 64 },
	{ 1, -24, 72, 8, 8 },
	{ 0, -24, 144, 40, 8 },
	{ 1, -24, 152, 16, 8 },
	{ 0, -16, 0, 40, 8 },
	{ 0, -16, 72, 48, 8 },
	{ 1, -16, 160, 8, 40 },
	{ 0, -8, 152, 8, 40 },
	{ 1, -8, 192, 24, 8 },
	{ 1, 0, 152, 16, 40 },
	{ 1, 0, 208, 32, 8 },
	{ 0, 0, 216, 216, 8 },
	{ 0, 16, 8, 8, 32 },
	{ 1, 16, 40, 16, 8 },
	{ 0, 16, 48, 8, 24 },
	{ 1, 16, 144, 16, 16 },
	{ 3, 16, 160, 24, 40 },
	{ 1, 24, 0, 8, 40 },
	{ 1, 24, 48, 8, 24 },
	{ 1, 32, 0, 32, 8 },
	{ 3, 32, 8, 184, 16 },
	{ 1, 32, 24, 8, 8 },
	{ 3, 32, 32, 32, 32 },
	{ 1, 32, 64, 8, 16 },
	{ 0, 32, 144, 16, 8 },
	{ 1, 32, 152, 16, 8 },
	{ 0, 32, 208, 144, 8 },
	{ 3, 40, 24, 88, 8 },
	{ 3, 40, 64, 32, 8 },
	{ 1, 40, 72, 8, 24 },
	{ 1, 40, 160, 16, 8 },
	{ 3, 40, 168, 8, 32 },
	{ 3, 48, 72, 24, 8 },
	{ 1, 48, 80, 24, 16 },
	{ 0, 48, 96, 8, 8 },
	{ 1, 48, 104, 48, 8 },
	{ 0, 48, 112, 8, 16 },
	{ 1, 48, 128, 8, 24 },
	{ 0, 48, 152, 8, 8 },
	{ 1, 48, 168, 16, 8 },
	{ 3, 48, 176, 8, 24 },
	{ 1, 48, 256, 16, 40 },
	{ 0, 48, 296, 8, 24 },
	{ 1, 48, 320, 16, 8 },
	{ 1, 56, 96, 40, 8 },
	{ 1, 56, 112, 8, 24 },
	{ 3, 56, 136, 32, 8 },
	{ 1, 56, 144, 8, 16 },
	{ 0, 56, 160, 8, 8 },
	{ 1, 56, 176, 24, 8 },
	{ 3, 56, 184, 8, 16 },
	{ 0, 56, 240, 128, 8 },
	{ 1, 56, 248, 24, 8 },
	{ 1, 56, 296, 8, 24 },
	{ 3, 64, 0, 152, 8 },
	{ 1, 64, 32, 24, 24 },
	{ 3, 64, 56, 8, 8 },
	{ 1, 64, 112, 8, 8 },
	{ 3, 64, 120, 24, 16 },
	{ 3, 64, 144, 24, 8 },
	{ 1, 64, 152, 8, 16 },
	{ 0, 64, 168, 8, 8 },
	{ 1, 64, 184, 16, 16 },
	{ 1, 64, 256, 24, 8 },
	{ 3, 64, 264, 16, 64 },
	{ 1, 72, 56, 8, 32 },
	{ 0, 72, 88, 144, 8 },
	{ 3, 72, 112, 8, 8 },
	{ 3, 72, 152, 16, 8 },
	{ 1, 72, 160, 24, 16 },
	{ 0, 72, 200, 96, 8 },
	{ 1, 80, 56, 8, 16 },
	{ 0, 80, 72, 112, 16 },
	{ 1, 80, 112, 24, 8 },
	{ 0, 80, 176, 64, 24 },
	{ 0, 80, 248, 104, 8 },
	{ 1, 80, 264, 16, 8 },
	{ 3, 80, 272, 8, 56 },
	{ 1, 88, 32, 32, 16 },
	{ 0, 88, 48, 96, 24 },
	{ 1, 88, 120, 8, 40 },
	{ 0, 88, 256, 72, 8 },
	{ 1, 88, 272, 16, 8 },
	{ 3, 88, 280, 8, 48 },
	{ 0, 96, 96, 120, 16 },
	{ 1, 96, 120, 8, 8 },
	{ 0, 96, 128, 48, 48 },
	{ 0, 96, 264, 56, 8 },
	{ 1, 96, 280, 8, 16 },
	{ 3, 96, 296, 16, 32 },
	{ 0, 104, 112, 112, 16 },
	{ 0, 104, 272, 40, 16 },
	{ 1, 104, 288, 16, 8 },
	{ 1, 112, 296, 40, 8 },
	{ 3, 112, 304, 8, 24 },
	{ 1, 120, 32, 16, 8 },
	{ 0, 120, 40, 56, 8 },
	{ 0, 120, 288, 24, 8 },
	{ 1, 120, 304, 32, 8 },
	{ 3, 120, 312, 16, 16 },
	{ 1, 128, 24, 64, 8 },
	{ 0, 136, 32, 40, 8 },
	{ 1, 136, 312, 8, 8 },
	{ 3, 136, 320, 80, 8 },
	{ 0, 144, 128, 8, 8 },
	{ 1, 144, 136, 24, 16 },
	{ 0, 144, 152, 8, 24 },
	{ 1, 144, 176, 8, 8 },
	{ 0, 144, 184, 32, 16 },
	{ 1, 144, 272, 16, 24 },
	{ 3, 144, 312, 72, 8 },
	{ 1, 152, 128, 32, 8 },
	{ 1, 152, 152, 8, 24 },
	{ 0, 152, 176, 16, 8 },
	{ 1, 152, 264, 40, 8 },
	{ 3, 152, 296, 64, 16 },
	{ 3, 160, 152, 56, 16 },
	{ 1, 160, 168, 16, 8 },
	{ 1, 160, 256, 16, 8 },
	{ 1, 160, 272, 8, 16 },
	{ 3, 160, 288, 56, 8 },
	{ 1, 168, 136, 48, 8 },
	{ 3, 168, 144, 8, 8 },
	{ 1, 168, 176, 16, 8 },
	{ 1, 168, 200, 32, 8 },
	{ 1, 168, 272, 8, 8 },
	{ 3, 168, 280, 48, 8 },
	{ 1, 176, 32, 24, 16 },
	{ 1, 176, 144, 32, 8 },
	{ 3, 176, 168, 40, 8 },
	{ 1, 176, 184, 8, 16 },
	{ 1, 176, 208, 40, 8 },
	{ 0, 176, 256, 8, 8 },
	{ 3, 176, 272, 40, 8 },
	{ 1, 184, 48, 24, 8 },
	{ 0, 184, 56, 8, 16 },
	{ 0, 184, 128, 32, 8 },
	{ 3, 184, 176, 32, 16 },
	{ 1, 184, 192, 8, 8 },
	{ 1, 184, 240, 8, 24 },
	{ 3, 192, 24, 24, 8 },
	{ 1, 192, 56, 16, 32 },
	{ 3, 192, 192, 24, 8 },
	{ 1, 192, 232, 8, 16 },
	{ 3, 192, 248, 24, 24 },
	{ 3, 200, 32, 16, 8 },
	{ 1, 200, 40, 8, 8 },
	{ 3, 200, 200, 16, 8 },
	{ 1, 200, 232, 16, 8 },
	{ 3, 200, 240, 16, 8 },
	{ 3, 208, 40, 8, 32 },
	{ 1, 208, 72, 8, 16 },
	{ 3, 208, 144, 8, 8 },
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
-- (On a rerun that part can be a lagoon, so take the checker from the rest of the ground.)
template:ClearAllChildren()
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and not p:GetAttribute("ArcBase") and p:FindFirstChild("Checker") then
		for _, t in p:GetChildren() do
			if t:IsA("Texture") then
				t:Clone().Parent = template
			end
		end
		break
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
	if inst ~= spawn and not inst.Name:match("^Portal") and kindAt(at.X, at.Z) == 3 then
		inst:Destroy() -- (in a lagoon; never the PortalGate, the game needs it)
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
