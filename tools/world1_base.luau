-- World 1's home base floor, redone like World 2's (QM, Oct 13). Made by
-- tools/world1_base.py: edit that and re-make this, not this. Run in Studio (Edit,
-- execute_luau) on World 1's Place, after tools/arc_base.luau. Re-running is fine.
-- Green grass, darker green grass and tan dirt as a gradient: the bright grass never
-- touches the dirt, there's always darker grass between. The bright grass is a stud up,
-- but flat inside the pens (a tile round them) and on the start line's row. Replaces the base floor (its
-- ArcBase parts), drops any plant now standing on dirt, and moves everything else in
-- BaseDecor (and the spawn) up or down by however much the floor under it moved.
-- In game the floor takes Config's Meadow colours: the darker grass is a Patch named
-- Grass (Config.Biomes[1].Patches.Grass), like World 2's.
local W = workspace.World
local OFFSET = 0
local rgb = Color3.fromRGB
local KINDS = { -- [kind] = { name, top, part colour, checker colour }
	[0] = { "Ground", 0, rgb(113, 173, 31), rgb(122, 190, 25) },
	[1] = { "Grass", 0, rgb(92, 146, 30), rgb(100, 160, 26) }, -- the darker green, beside the dirt
	[2] = { "Dirt", -1, rgb(206, 146, 84), rgb(222, 164, 100) },
	[3] = { "Ground", 1, rgb(113, 173, 31), rgb(122, 190, 25) }, -- the light grass a stud up
}
-- { kind, low x, low z, size x, size z } on 8-stud cells
local FLOOR = {
	{ 0, -176, 0, 136, 8 },
	{ 3, -176, 8, 8, 64 },
	{ 0, -176, 72, 24, 48 },
	{ 3, -176, 120, 16, 48 },
	{ 1, -176, 168, 8, 16 },
	{ 0, -176, 184, 112, 8 },
	{ 3, -176, 192, 8, 48 },
	{ 1, -176, 240, 8, 32 },
	{ 3, -168, 8, 8, 16 },
	{ 0, -168, 24, 16, 48 },
	{ 1, -168, 168, 8, 8 },
	{ 0, -168, 176, 120, 8 },
	{ 0, -168, 192, 40, 16 },
	{ 3, -168, 208, 8, 32 },
	{ 1, -168, 240, 8, 8 },
	{ 3, -168, 248, 40, 16 },
	{ 1, -168, 264, 16, 8 },
	{ 3, -160, 8, 8, 8 },
	{ 0, -160, 16, 8, 8 },
	{ 3, -160, 120, 8, 40 },
	{ 0, -160, 160, 64, 16 },
	{ 0, -160, 208, 104, 8 },
	{ 3, -160, 216, 8, 32 },
	{ 1, -152, 8, 8, 16 },
	{ 0, -152, 24, 24, 24 },
	{ 1, -152, 48, 8, 24 },
	{ 0, -152, 72, 32, 40 },
	{ 1, -152, 112, 8, 8 },
	{ 3, -152, 120, 8, 32 },
	{ 0, -152, 152, 56, 8 },
	{ 0, -152, 216, 8, 8 },
	{ 3, -152, 224, 8, 24 },
	{ 3, -152, 264, 96, 8 },
	{ 1, -144, 8, 8, 8 },
	{ 0, -144, 16, 8, 8 },
	{ 1, -144, 48, 16, 16 },
	{ 0, -144, 64, 24, 8 },
	{ 0, -144, 112, 72, 16 },
	{ 3, -144, 128, 8, 16 },
	{ 0, -144, 144, 48, 8 },
	{ 1, -144, 216, 8, 16 },
	{ 3, -144, 232, 8, 16 },
	{ 3, -136, 8, 96, 8 },
	{ 1, -136, 16, 16, 8 },
	{ 3, -136, 128, 16, 8 },
	{ 0, -136, 136, 40, 8 },
	{ 0, -136, 216, 48, 24 },
	{ 3, -136, 240, 8, 8 },
	{ 1, -128, 24, 16, 24 },
	{ 0, -128, 48, 8, 16 },
	{ 0, -128, 192, 56, 8 },
	{ 1, -128, 200, 16, 8 },
	{ 0, -128, 240, 24, 16 },
	{ 3, -128, 256, 8, 8 },
	{ 3, -120, 16, 88, 8 },
	{ 1, -120, 48, 8, 24 },
	{ 0, -120, 72, 32, 16 },
	{ 1, -120, 88, 8, 8 },
	{ 0, -120, 96, 16, 16 },
	{ 0, -120, 128, 40, 8 },
	{ 0, -120, 256, 8, 8 },
	{ 1, -112, 24, 8, 8 },
	{ 0, -112, 32, 8, 40 },
	{ 0, -112, 88, 24, 8 },
	{ 0, -112, 200, 48, 8 },
	{ 3, -112, 256, 16, 8 },
	{ 0, -104, 24, 8, 32 },
	{ 1, -104, 56, 48, 16 },
	{ 1, -104, 96, 16, 16 },
	{ 0, -104, 240, 8, 8 },
	{ 3, -104, 248, 8, 8 },
	{ 0, -96, 24, 8, 24 },
	{ 1, -96, 48, 16, 8 },
	{ 1, -96, 136, 16, 40 },
	{ 3, -96, 240, 48, 8 },
	{ 1, -96, 248, 16, 16 },
	{ 3, -88, 24, 56, 8 },
	{ 0, -88, 32, 24, 16 },
	{ 1, -88, 72, 8, 32 },
	{ 0, -88, 104, 16, 8 },
	{ 0, -88, 216, 8, 16 },
	{ 3, -88, 232, 40, 8 },
	{ 0, -80, 48, 8, 8 },
	{ 1, -80, 72, 8, 8 },
	{ 2, -80, 80, 160, 8 },
	{ 1, -80, 88, 16, 8 },
	{ 0, -80, 96, 8, 8 },
	{ 3, -80, 128, 8, 8 },
	{ 1, -80, 136, 8, 16 },
	{ 2, -80, 152, 24, 8 },
	{ 1, -80, 160, 16, 16 },
	{ 0, -80, 216, 16, 8 },
	{ 3, -80, 224, 32, 8 },
	{ 3, -80, 248, 24, 16 },
	{ 1, -72, 48, 40, 8 },
	{ 2, -72, 72, 144, 8 },
	{ 1, -72, 96, 24, 8 },
	{ 3, -72, 104, 8, 24 },
	{ 1, -72, 128, 8, 16 },
	{ 2, -72, 144, 24, 8 },
	{ 1, -72, 192, 16, 8 },
	{ 3, -64, 32, 8, 8 },
	{ 1, -64, 40, 40, 8 },
	{ 2, -64, 88, 136, 8 },
	{ 1, -64, 104, 8, 32 },
	{ 2, -64, 136, 96, 8 },
	{ 1, -64, 160, 56, 8 },
	{ 0, -64, 168, 8, 8 },
	{ 1, -64, 184, 8, 8 },
	{ 1, -64, 200, 8, 8 },
	{ 3, -64, 216, 16, 8 },
	{ 1, -56, 32, 40, 8 },
	{ 1, -56, 56, 16, 8 },
	{ 2, -56, 64, 112, 8 },
	{ 2, -56, 104, 112, 16 },
	{ 1, -56, 120, 8, 8 },
	{ 2, -56, 128, 112, 8 },
	{ 1, -56, 152, 48, 8 },
	{ 3, -56, 168, 8, 8 },
	{ 0, -56, 184, 32, 24 },
	{ 3, -56, 208, 8, 8 },
	{ 0, -56, 248, 16, 24 },
	{ 2, -48, 96, 104, 8 },
	{ 2, -48, 120, 104, 8 },
	{ 1, -48, 144, 8, 8 },
	{ 1, -48, 168, 40, 16 },
	{ 0, -48, 208, 96, 40 },
	{ 1, -40, 0, 8, 16 },
	{ 2, -40, 56, 88, 8 },
	{ 2, -40, 144, 48, 8 },
	{ 0, -40, 248, 24, 16 },
	{ 1, -40, 264, 96, 8 },
	{ 2, -32, 0, 64, 8 },
	{ 1, -32, 8, 8, 24 },
	{ 2, -32, 48, 80, 8 },
	{ 2, -24, 8, 48, 8 },
	{ 1, -24, 16, 8, 16 },
	{ 2, -24, 40, 48, 8 },
	{ 1, -24, 184, 56, 8 },
	{ 0, -24, 192, 160, 16 },
	{ 2, -16, 16, 40, 24 },
	{ 0, -16, 248, 16, 8 },
	{ 1, -16, 256, 72, 8 },
	{ 2, -8, 152, 16, 24 },
	{ 1, -8, 176, 48, 8 },
	{ 1, 0, 248, 40, 8 },
	{ 1, 8, 144, 40, 32 },
	{ 1, 24, 8, 32, 40 },
	{ 1, 32, 0, 24, 8 },
	{ 1, 32, 136, 8, 8 },
	{ 0, 32, 184, 112, 8 },
	{ 2, 40, 136, 24, 8 },
	{ 0, 40, 176, 112, 8 },
	{ 0, 40, 248, 8, 8 },
	{ 1, 48, 48, 32, 16 },
	{ 2, 48, 144, 24, 8 },
	{ 1, 48, 152, 8, 24 },
	{ 3, 48, 208, 8, 48 },
	{ 0, 56, 0, 48, 8 },
	{ 3, 56, 8, 40, 16 },
	{ 1, 56, 24, 16, 24 },
	{ 1, 56, 64, 40, 8 },
	{ 1, 56, 96, 8, 40 },
	{ 2, 56, 152, 24, 8 },
	{ 1, 56, 160, 8, 16 },
	{ 0, 56, 208, 104, 8 },
	{ 3, 56, 216, 8, 56 },
	{ 1, 64, 96, 32, 8 },
	{ 3, 64, 104, 8, 24 },
	{ 1, 64, 128, 8, 16 },
	{ 2, 64, 160, 8, 8 },
	{ 1, 64, 168, 32, 8 },
	{ 0, 64, 216, 88, 8 },
	{ 3, 64, 224, 16, 48 },
	{ 3, 72, 24, 16, 8 },
	{ 0, 72, 32, 16, 8 },
	{ 1, 72, 40, 8, 8 },
	{ 1, 72, 72, 32, 8 },
	{ 1, 72, 88, 40, 8 },
	{ 1, 72, 104, 16, 8 },
	{ 0, 72, 112, 72, 16 },
	{ 3, 72, 128, 8, 8 },
	{ 1, 72, 136, 32, 16 },
	{ 1, 72, 160, 32, 8 },
	{ 0, 80, 40, 88, 16 },
	{ 1, 80, 56, 16, 8 },
	{ 1, 80, 80, 24, 8 },
	{ 1, 80, 128, 16, 8 },
	{ 1, 80, 152, 24, 8 },
	{ 0, 80, 224, 64, 8 },
	{ 3, 80, 232, 8, 40 },
	{ 0, 88, 24, 8, 8 },
	{ 1, 88, 32, 8, 8 },
	{ 0, 88, 104, 56, 8 },
	{ 0, 88, 232, 48, 8 },
	{ 3, 88, 240, 8, 32 },
	{ 3, 96, 8, 8, 8 },
	{ 1, 96, 16, 8, 16 },
	{ 0, 96, 32, 72, 8 },
	{ 0, 96, 56, 40, 16 },
	{ 0, 96, 96, 8, 8 },
	{ 0, 96, 128, 24, 8 },
	{ 0, 96, 168, 64, 8 },
	{ 0, 96, 240, 32, 8 },
	{ 3, 96, 248, 8, 24 },
	{ 1, 104, 0, 8, 24 },
	{ 0, 104, 24, 64, 8 },
	{ 0, 104, 72, 32, 16 },
	{ 1, 104, 96, 16, 8 },
	{ 0, 104, 136, 32, 32 },
	{ 1, 104, 248, 40, 16 },
	{ 3, 104, 264, 8, 8 },
	{ 1, 112, 0, 8, 16 },
	{ 3, 112, 16, 16, 8 },
	{ 0, 112, 88, 64, 8 },
	{ 1, 112, 264, 8, 8 },
	{ 0, 120, 0, 56, 8 },
	{ 3, 120, 8, 56, 8 },
	{ 0, 120, 96, 56, 8 },
	{ 3, 120, 128, 32, 8 },
	{ 3, 120, 264, 56, 8 },
	{ 0, 128, 16, 32, 8 },
	{ 3, 128, 240, 48, 8 },
	{ 0, 136, 56, 32, 8 },
	{ 1, 136, 64, 8, 16 },
	{ 0, 136, 80, 40, 8 },
	{ 3, 136, 136, 16, 8 },
	{ 0, 136, 144, 8, 24 },
	{ 1, 136, 192, 8, 8 },
	{ 0, 136, 200, 32, 8 },
	{ 3, 136, 232, 40, 8 },
	{ 0, 144, 64, 24, 16 },
	{ 1, 144, 104, 32, 16 },
	{ 3, 144, 120, 8, 8 },
	{ 3, 144, 144, 8, 8 },
	{ 0, 144, 152, 8, 16 },
	{ 1, 144, 184, 16, 8 },
	{ 0, 144, 192, 16, 8 },
	{ 3, 144, 224, 32, 8 },
	{ 3, 144, 248, 32, 16 },
	{ 1, 152, 120, 8, 48 },
	{ 1, 152, 176, 8, 8 },
	{ 3, 152, 216, 24, 8 },
	{ 3, 160, 16, 16, 8 },
	{ 1, 160, 120, 8, 8 },
	{ 3, 160, 128, 8, 8 },
	{ 1, 160, 136, 16, 40 },
	{ 0, 160, 176, 16, 16 },
	{ 1, 160, 192, 8, 8 },
	{ 3, 160, 208, 16, 8 },
	{ 3, 168, 24, 8, 48 },
	{ 0, 168, 72, 8, 8 },
	{ 3, 168, 120, 8, 8 },
	{ 1, 168, 128, 8, 8 },
	{ 3, 168, 192, 8, 16 },
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
		local at = inst:GetPivot().Position
		table.insert(standing, { inst, floorAt(at) })
	end
end
local decor = W:FindFirstChild("BaseDecor")
if decor then
	for _, inst in decor:GetChildren() do
		if inst:IsA("Folder") then
			for _, m in inst:GetChildren() do
				note(m)
			end
		else
			note(inst)
		end
	end
end
local spawn = W:FindFirstChild("SpawnLocation", true) or workspace:FindFirstChild("SpawnLocation")
if spawn then
	note(spawn)
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
	local x, z, sx, sz = r[2] + OFFSET, r[3], r[4], r[5]
	local p = template:Clone()
	p.Name = k[1]
	p.Size = Vector3.new(sx, k[2] + 2, sz)
	p.CFrame = CFrame.new(x + sx / 2, (k[2] - 2) / 2, z + sz / 2)
	p.Color = k[3]
	for _, t in p:GetChildren() do
		t.Color3 = k[4]
	end
	p.Parent = W.Ground
end

local function dirtAt(x, z)
	for _, r in FLOOR do
		if r[1] == 2 and x >= r[2] + OFFSET and x < r[2] + OFFSET + r[4] and z >= r[3] and z < r[3] + r[5] then
			return true
		end
	end
	return false
end
local dropped, moved = 0, 0
for _, s in standing do
	local inst, before = s[1], s[2]
	local at = inst:GetPivot().Position
	if inst.Parent and inst.Parent.Name == "Plants" and dirtAt(at.X, at.Z) then
		inst:Destroy()
		dropped += 1
	else
		local dy = floorAt(at) - before
		if math.abs(dy) > 0.01 then
			inst:PivotTo(inst:GetPivot() + Vector3.new(0, dy, 0))
			moved += 1
		end
	end
end
return string.format("%d floor parts, %d plants on dirt dropped, %d things moved with the floor", #FLOOR, dropped, moved)
