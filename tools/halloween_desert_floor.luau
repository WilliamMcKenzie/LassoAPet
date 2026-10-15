-- A Halloween world biome's floor, the Desert (QM, Oct 15: his picture's pattern: light
-- flagstones down the middle, ragged bands of the middle tone along the walls, the darkest in
-- patches inside those, always ringed by the middle tone; all flush). Made by
-- tools/halloween_desert_floor.py: edit that and re-make this, not this. Run in Studio (Edit,
-- execute_luau) on the Halloween Place. Re-running is fine. Replaces every floor part in
-- World.Ground between the biome's lines and lays these over, the outer columns on under the
-- walls; moves its Obstacles and Decor with the floor under them. In game the colours are
-- Config's World 4 Desert by part name (GroundColors, then its Patches).
local W = workspace.World
local Z0, Z1 = -2168, -2168 - 1816
local rgb = Color3.fromRGB
local LOOK = { -- (as Config's, so Studio shows it)
	Ground = { rgb(126, 180, 210), rgb(116, 170, 202) },
	Stone = { rgb(104, 154, 186), rgb(96, 146, 178) },
	Grass = { rgb(86, 122, 150), rgb(78, 114, 142) },
}
-- { name, low x, low z, size x, size z }
local FLOOR = {
	{ "Stone", -80, -2232, 32, 64 },
	{ "Stone", -48, -2216, 8, 48 },
	{ "Ground", -48, -2232, 88, 16 },
	{ "Ground", -40, -2216, 72, 48 },
	{ "Stone", 32, -2184, 24, 16 },
	{ "Ground", 32, -2216, 8, 32 },
	{ "Stone", 40, -2232, 16, 48 },
	{ "Grass", 56, -2232, 24, 64 },
	{ "Stone", -80, -2296, 32, 64 },
	{ "Ground", -48, -2288, 88, 56 },
	{ "Stone", -48, -2296, 8, 8 },
	{ "Ground", -40, -2296, 80, 8 },
	{ "Stone", 40, -2248, 40, 16 },
	{ "Ground", 40, -2288, 8, 40 },
	{ "Stone", 40, -2296, 40, 8 },
	{ "Stone", 48, -2288, 32, 40 },
	{ "Stone", -80, -2304, 48, 8 },
	{ "Grass", -80, -2360, 24, 56 },
	{ "Stone", -56, -2312, 24, 8 },
	{ "Grass", -56, -2360, 8, 48 },
	{ "Stone", -48, -2360, 16, 48 },
	{ "Ground", -32, -2360, 64, 64 },
	{ "Ground", 32, -2304, 8, 8 },
	{ "Stone", 32, -2336, 48, 32 },
	{ "Ground", 32, -2360, 8, 24 },
	{ "Stone", 40, -2304, 40, 8 },
	{ "Stone", 40, -2360, 40, 24 },
	{ "Grass", -80, -2368, 32, 8 },
	{ "Stone", -80, -2424, 48, 56 },
	{ "Stone", -48, -2368, 16, 8 },
	{ "Ground", -32, -2424, 64, 64 },
	{ "Ground", 32, -2384, 8, 24 },
	{ "Stone", 32, -2424, 48, 40 },
	{ "Stone", 40, -2384, 40, 24 },
	{ "Grass", -80, -2480, 16, 56 },
	{ "Stone", -80, -2488, 40, 8 },
	{ "Stone", -64, -2432, 32, 8 },
	{ "Grass", -64, -2480, 8, 48 },
	{ "Stone", -56, -2480, 16, 48 },
	{ "Ground", -40, -2488, 56, 56 },
	{ "Ground", -32, -2432, 64, 8 },
	{ "Stone", 16, -2448, 16, 16 },
	{ "Ground", 16, -2488, 24, 40 },
	{ "Stone", 32, -2440, 48, 16 },
	{ "Ground", 32, -2448, 16, 8 },
	{ "Ground", 40, -2480, 8, 32 },
	{ "Stone", 40, -2488, 40, 8 },
	{ "Stone", 48, -2448, 32, 8 },
	{ "Ground", 48, -2472, 8, 24 },
	{ "Stone", 48, -2480, 32, 8 },
	{ "Stone", 56, -2472, 24, 24 },
	{ "Stone", -80, -2552, 32, 64 },
	{ "Stone", -48, -2536, 8, 48 },
	{ "Ground", -48, -2552, 80, 16 },
	{ "Stone", -40, -2520, 8, 32 },
	{ "Ground", -40, -2536, 72, 16 },
	{ "Ground", -32, -2520, 64, 32 },
	{ "Ground", 32, -2496, 8, 8 },
	{ "Stone", 32, -2552, 48, 56 },
	{ "Stone", 40, -2496, 40, 8 },
	{ "Stone", -80, -2600, 32, 48 },
	{ "Grass", -80, -2616, 24, 16 },
	{ "Stone", -56, -2616, 24, 16 },
	{ "Ground", -48, -2576, 80, 24 },
	{ "Stone", -48, -2600, 8, 24 },
	{ "Ground", -40, -2592, 80, 16 },
	{ "Stone", -40, -2600, 8, 8 },
	{ "Ground", -32, -2616, 72, 24 },
	{ "Stone", 32, -2568, 48, 16 },
	{ "Ground", 32, -2576, 8, 8 },
	{ "Stone", 40, -2616, 40, 48 },
	{ "Grass", -80, -2680, 16, 64 },
	{ "Grass", -64, -2624, 8, 8 },
	{ "Stone", -64, -2680, 16, 56 },
	{ "Stone", -56, -2624, 24, 8 },
	{ "Stone", -48, -2640, 8, 16 },
	{ "Ground", -48, -2680, 80, 40 },
	{ "Ground", -40, -2640, 72, 16 },
	{ "Ground", -32, -2624, 64, 8 },
	{ "Stone", 32, -2656, 48, 40 },
	{ "Ground", 32, -2680, 8, 24 },
	{ "Stone", 40, -2664, 40, 8 },
	{ "Ground", 40, -2680, 8, 16 },
	{ "Stone", 48, -2680, 32, 16 },
	{ "Grass", -80, -2744, 16, 64 },
	{ "Stone", -64, -2696, 24, 16 },
	{ "Grass", -64, -2744, 8, 48 },
	{ "Stone", -56, -2736, 16, 40 },
	{ "Grass", -56, -2744, 8, 8 },
	{ "Stone", -48, -2744, 24, 8 },
	{ "Ground", -40, -2720, 88, 40 },
	{ "Stone", -40, -2736, 16, 16 },
	{ "Ground", -24, -2744, 72, 24 },
	{ "Stone", 48, -2744, 16, 64 },
	{ "Stone", 64, -2720, 16, 40 },
	{ "Grass", 64, -2744, 16, 24 },
	{ "Grass", -80, -2768, 24, 24 },
	{ "Stone", -80, -2808, 40, 40 },
	{ "Grass", -56, -2752, 8, 8 },
	{ "Stone", -56, -2768, 24, 16 },
	{ "Stone", -48, -2752, 24, 8 },
	{ "Ground", -40, -2784, 88, 16 },
	{ "Stone", -40, -2808, 16, 24 },
	{ "Ground", -32, -2768, 64, 16 },
	{ "Ground", -24, -2752, 56, 8 },
	{ "Ground", -24, -2808, 64, 24 },
	{ "Stone", 32, -2760, 32, 16 },
	{ "Ground", 32, -2768, 16, 8 },
	{ "Stone", 40, -2808, 16, 24 },
	{ "Stone", 48, -2784, 16, 24 },
	{ "Stone", 56, -2800, 8, 16 },
	{ "Grass", 56, -2808, 24, 8 },
	{ "Grass", 64, -2800, 16, 56 },
	{ "Grass", -80, -2872, 16, 64 },
	{ "Stone", -64, -2872, 16, 64 },
	{ "Stone", -48, -2824, 24, 16 },
	{ "Ground", -48, -2872, 88, 48 },
	{ "Ground", -24, -2824, 64, 16 },
	{ "Stone", 40, -2856, 16, 48 },
	{ "Ground", 40, -2872, 8, 16 },
	{ "Stone", 48, -2872, 32, 16 },
	{ "Grass", 56, -2832, 24, 24 },
	{ "Stone", 56, -2856, 24, 24 },
	{ "Grass", -80, -2936, 16, 64 },
	{ "Stone", -64, -2920, 16, 48 },
	{ "Grass", -64, -2936, 8, 16 },
	{ "Stone", -56, -2936, 16, 16 },
	{ "Ground", -48, -2904, 96, 32 },
	{ "Stone", -48, -2920, 8, 16 },
	{ "Ground", -40, -2928, 88, 24 },
	{ "Stone", -40, -2936, 8, 8 },
	{ "Ground", -32, -2936, 72, 8 },
	{ "Stone", 40, -2936, 24, 8 },
	{ "Stone", 48, -2880, 32, 8 },
	{ "Ground", 48, -2904, 8, 24 },
	{ "Stone", 48, -2928, 32, 24 },
	{ "Stone", 56, -2904, 24, 24 },
	{ "Grass", 64, -2936, 16, 8 },
	{ "Grass", -80, -2952, 16, 16 },
	{ "Stone", -80, -3000, 24, 48 },
	{ "Grass", -64, -2944, 8, 8 },
	{ "Stone", -64, -2952, 32, 8 },
	{ "Stone", -56, -2944, 24, 8 },
	{ "Stone", -56, -2968, 8, 16 },
	{ "Ground", -56, -3000, 64, 32 },
	{ "Stone", -48, -2960, 8, 8 },
	{ "Ground", -48, -2968, 56, 8 },
	{ "Ground", -40, -2960, 80, 8 },
	{ "Ground", -32, -2952, 72, 16 },
	{ "Stone", 8, -2976, 48, 16 },
	{ "Ground", 8, -3000, 8, 24 },
	{ "Stone", 16, -2984, 40, 8 },
	{ "Ground", 16, -3000, 8, 16 },
	{ "Stone", 24, -2992, 32, 8 },
	{ "Ground", 24, -3000, 8, 8 },
	{ "Stone", 32, -3000, 32, 8 },
	{ "Stone", 40, -2960, 16, 24 },
	{ "Stone", 56, -2944, 8, 8 },
	{ "Grass", 56, -2992, 24, 48 },
	{ "Grass", 64, -2944, 16, 8 },
	{ "Grass", 64, -3000, 16, 8 },
	{ "Stone", -80, -3064, 24, 64 },
	{ "Ground", -56, -3008, 96, 8 },
	{ "Stone", -56, -3064, 8, 56 },
	{ "Ground", -48, -3016, 96, 8 },
	{ "Stone", -48, -3056, 8, 40 },
	{ "Ground", -48, -3064, 96, 8 },
	{ "Ground", -40, -3056, 88, 40 },
	{ "Stone", 40, -3008, 24, 8 },
	{ "Stone", 48, -3064, 16, 56 },
	{ "Grass", 64, -3048, 16, 48 },
	{ "Stone", 64, -3064, 16, 16 },
	{ "Stone", -80, -3128, 24, 64 },
	{ "Stone", -56, -3072, 8, 8 },
	{ "Ground", -56, -3128, 96, 56 },
	{ "Ground", -48, -3072, 88, 8 },
	{ "Stone", 40, -3128, 40, 64 },
	{ "Stone", -80, -3152, 24, 24 },
	{ "Grass", -80, -3168, 16, 16 },
	{ "Stone", -80, -3192, 40, 24 },
	{ "Stone", -64, -3168, 16, 16 },
	{ "Ground", -56, -3136, 96, 8 },
	{ "Stone", -56, -3152, 8, 16 },
	{ "Ground", -48, -3160, 88, 24 },
	{ "Stone", -48, -3168, 8, 8 },
	{ "Ground", -40, -3192, 72, 32 },
	{ "Ground", 32, -3176, 8, 16 },
	{ "Stone", 32, -3192, 48, 16 },
	{ "Stone", 40, -3176, 40, 48 },
	{ "Stone", -80, -3256, 32, 64 },
	{ "Stone", -48, -3248, 8, 56 },
	{ "Ground", -48, -3256, 80, 8 },
	{ "Ground", -40, -3248, 72, 56 },
	{ "Ground", 32, -3224, 8, 32 },
	{ "Stone", 32, -3256, 48, 32 },
	{ "Stone", 40, -3224, 40, 32 },
	{ "Stone", -80, -3320, 24, 64 },
	{ "Ground", -56, -3296, 24, 40 },
	{ "Stone", -56, -3320, 8, 24 },
	{ "Ground", -48, -3304, 16, 8 },
	{ "Stone", -48, -3320, 8, 16 },
	{ "Ground", -40, -3320, 88, 16 },
	{ "Ground", -32, -3280, 64, 24 },
	{ "Stone", -32, -3304, 16, 24 },
	{ "Ground", -16, -3288, 56, 8 },
	{ "Stone", -16, -3304, 8, 16 },
	{ "Ground", -8, -3304, 48, 16 },
	{ "Stone", 32, -3264, 48, 8 },
	{ "Ground", 32, -3280, 8, 16 },
	{ "Stone", 40, -3296, 40, 32 },
	{ "Ground", 40, -3304, 8, 8 },
	{ "Stone", 48, -3320, 32, 24 },
	{ "Grass", -80, -3344, 16, 24 },
	{ "Stone", -80, -3384, 24, 40 },
	{ "Stone", -64, -3344, 24, 24 },
	{ "Stone", -56, -3360, 8, 16 },
	{ "Ground", -56, -3384, 96, 24 },
	{ "Ground", -48, -3360, 88, 16 },
	{ "Ground", -40, -3344, 88, 24 },
	{ "Ground", 40, -3352, 8, 8 },
	{ "Stone", 40, -3384, 40, 32 },
	{ "Stone", 48, -3352, 32, 32 },
	{ "Stone", -80, -3448, 24, 64 },
	{ "Ground", -56, -3392, 96, 8 },
	{ "Stone", -56, -3448, 8, 56 },
	{ "Ground", -48, -3408, 88, 16 },
	{ "Stone", -48, -3448, 8, 40 },
	{ "Ground", -40, -3448, 80, 40 },
	{ "Stone", 40, -3448, 24, 64 },
	{ "Stone", 64, -3432, 16, 48 },
	{ "Grass", 64, -3448, 16, 16 },
	{ "Stone", -80, -3512, 24, 64 },
	{ "Stone", -56, -3496, 8, 48 },
	{ "Ground", -56, -3512, 112, 16 },
	{ "Stone", -48, -3472, 8, 24 },
	{ "Ground", -48, -3496, 88, 24 },
	{ "Ground", -40, -3472, 80, 24 },
	{ "Stone", 40, -3480, 24, 32 },
	{ "Ground", 40, -3496, 8, 16 },
	{ "Stone", 48, -3496, 32, 16 },
	{ "Stone", 56, -3512, 24, 16 },
	{ "Grass", 64, -3480, 16, 32 },
	{ "Stone", -80, -3576, 24, 64 },
	{ "Ground", -56, -3544, 112, 32 },
	{ "Stone", -56, -3576, 8, 32 },
	{ "Ground", -48, -3552, 104, 8 },
	{ "Stone", -48, -3576, 8, 24 },
	{ "Ground", -40, -3560, 96, 8 },
	{ "Stone", -40, -3576, 8, 16 },
	{ "Ground", -32, -3576, 88, 16 },
	{ "Stone", 56, -3576, 24, 64 },
	{ "Stone", -80, -3592, 40, 16 },
	{ "Grass", -80, -3640, 16, 48 },
	{ "Stone", -64, -3600, 24, 8 },
	{ "Grass", -64, -3640, 8, 40 },
	{ "Stone", -56, -3640, 16, 40 },
	{ "Ground", -40, -3640, 64, 64 },
	{ "Ground", 24, -3632, 8, 56 },
	{ "Stone", 24, -3640, 56, 8 },
	{ "Ground", 32, -3624, 24, 48 },
	{ "Stone", 32, -3632, 48, 8 },
	{ "Stone", 56, -3600, 24, 24 },
	{ "Ground", 56, -3624, 8, 24 },
	{ "Stone", 64, -3624, 16, 24 },
	{ "Grass", -80, -3664, 24, 24 },
	{ "Stone", -80, -3704, 40, 40 },
	{ "Stone", -56, -3664, 16, 24 },
	{ "Ground", -40, -3704, 64, 64 },
	{ "Stone", 24, -3648, 56, 8 },
	{ "Ground", 24, -3704, 24, 56 },
	{ "Ground", 48, -3672, 8, 24 },
	{ "Stone", 48, -3704, 16, 32 },
	{ "Stone", 56, -3672, 24, 24 },
	{ "Stone", 64, -3688, 16, 16 },
	{ "Grass", 64, -3704, 16, 16 },
	{ "Stone", -80, -3720, 40, 16 },
	{ "Grass", -80, -3768, 16, 48 },
	{ "Grass", -64, -3752, 8, 32 },
	{ "Stone", -64, -3768, 24, 16 },
	{ "Stone", -56, -3752, 16, 32 },
	{ "Ground", -40, -3768, 80, 64 },
	{ "Ground", 40, -3736, 8, 32 },
	{ "Stone", 40, -3768, 40, 32 },
	{ "Stone", 48, -3736, 16, 32 },
	{ "Grass", 64, -3720, 16, 16 },
	{ "Stone", 64, -3736, 16, 16 },
	{ "Stone", -80, -3832, 16, 64 },
	{ "Stone", -64, -3792, 8, 24 },
	{ "Ground", -64, -3824, 32, 32 },
	{ "Stone", -64, -3832, 8, 8 },
	{ "Stone", -56, -3784, 8, 16 },
	{ "Ground", -56, -3792, 96, 8 },
	{ "Ground", -56, -3832, 24, 8 },
	{ "Ground", -48, -3784, 88, 16 },
	{ "Ground", -32, -3816, 72, 24 },
	{ "Stone", -32, -3832, 16, 16 },
	{ "Ground", -16, -3832, 56, 16 },
	{ "Stone", 40, -3832, 40, 64 },
	{ "Stone", -80, -3896, 24, 64 },
	{ "Ground", -56, -3840, 96, 8 },
	{ "Stone", -56, -3896, 8, 56 },
	{ "Ground", -48, -3896, 80, 56 },
	{ "Ground", 32, -3872, 16, 32 },
	{ "Stone", 32, -3888, 48, 16 },
	{ "Ground", 32, -3896, 16, 8 },
	{ "Stone", 40, -3840, 40, 8 },
	{ "Stone", 48, -3872, 32, 32 },
	{ "Stone", 48, -3896, 32, 8 },
	{ "Stone", -80, -3960, 24, 64 },
	{ "Stone", -56, -3952, 8, 56 },
	{ "Ground", -56, -3960, 112, 8 },
	{ "Ground", -48, -3952, 48, 56 },
	{ "Ground", 0, -3920, 8, 24 },
	{ "Stone", 0, -3936, 80, 16 },
	{ "Ground", 0, -3952, 8, 16 },
	{ "Ground", 8, -3912, 40, 16 },
	{ "Stone", 8, -3920, 24, 8 },
	{ "Stone", 8, -3944, 24, 8 },
	{ "Ground", 8, -3952, 48, 8 },
	{ "Ground", 32, -3920, 16, 8 },
	{ "Ground", 32, -3944, 24, 8 },
	{ "Stone", 48, -3920, 32, 24 },
	{ "Stone", 56, -3960, 24, 24 },
	{ "Stone", -80, -3984, 24, 24 },
	{ "Ground", -56, -3984, 112, 24 },
	{ "Stone", 56, -3984, 24, 24 },
}

local function floorAt(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { W.Ground }
	local hit = workspace:Raycast(Vector3.new(pos.X, 60, pos.Z), Vector3.new(0, -120, 0), params)
	return if hit then hit.Position.Y else 0
end

local function inDesert(z)
	return z < Z0 and z > Z1
end

-- What stands in the Desert, and the floor's height under it before.
local standing = {}
for _, folder in { W:FindFirstChild("Obstacles"), W:FindFirstChild("Decor") } do
	for _, inst in folder and folder:GetDescendants() or {} do
		if (inst:IsA("Model") and not inst:FindFirstAncestorWhichIsA("Model")) or (inst:IsA("BasePart") and inst.Parent:IsA("Folder")) then
			local at = inst:GetPivot().Position
			if inDesert(at.Z) then
				table.insert(standing, { inst, floorAt(at) })
			end
		end
	end
end

local template, removed = nil, 0
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and inDesert(p.Position.Z) and p.Position.Y < 4 then
		if not template and p:FindFirstChildWhichIsA("Texture") then
			template = p:Clone()
		end
		p:Destroy()
		removed += 1
	end
end
assert(template, "no Desert floor in World.Ground to copy the look of")
template:ClearAllChildren()
local tex = nil
for _, p in W.Ground:GetChildren() do -- (the checker, off any floor part)
	tex = tex or p:FindFirstChildWhichIsA("Texture")
end
local proto = (tex or Instance.new("Texture")):Clone()
for _, r in FLOOR do
	local p = template:Clone()
	p.Name = r[1]
	p.Size = Vector3.new(r[4], 2, r[5])
	p.CFrame = CFrame.new(r[2] + r[4] / 2, -1, r[3] + r[5] / 2)
	p.Color = LOOK[r[1]][1]
	for _, face in { Enum.NormalId.Top } do
		local t = proto:Clone()
		t.Face = face
		t.Color3 = LOOK[r[1]][2]
		t.Parent = p
	end
	p.Parent = W.Ground
end

local moved = 0
for _, s in standing do
	local inst, before = s[1], s[2]
	local dy = floorAt(inst:GetPivot().Position) - before
	if math.abs(dy) > 0.01 then
		inst:PivotTo(inst:GetPivot() + Vector3.new(0, dy, 0))
		moved += 1
	end
end
return string.format("%d old floor parts out, %d laid, %d props moved with the floor", removed, #FLOOR, moved)
