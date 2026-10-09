-- The arc home base (QM, Oct 9; design/base_arc/SPEC.md). Made by tools/arc_base.py
-- from design/base_arc/arc_layout.json: edit those and re-make it, not this.
-- Run in Studio's command bar (Edit, not Play) on the place. Re-running is fine.

local W, D = 176, 264
local YARD = Vector3.new(0, 0, 90)
local world = workspace.World

-- The walls and caps: { name, which, centre, size }.
local WALLS = {
	{ "Wall", "back", Vector3.new(0, 24, 268), Vector3.new(368, 48, 8) },
	{ "Cap", "back", Vector3.new(0, 49, 267), Vector3.new(368, 2, 10) },
	{ "Wall", "left", Vector3.new(-180, 24, 128), Vector3.new(8, 48, 272) },
	{ "Cap", "left", Vector3.new(-179, 49, 132), Vector3.new(10, 2, 260) },
	{ "Wall", "right", Vector3.new(180, 24, 128), Vector3.new(8, 48, 272) },
	{ "Cap", "right", Vector3.new(179, 49, 132), Vector3.new(10, 2, 260) },
	{ "Wall", "frontleft", Vector3.new(-116, 24, -4), Vector3.new(120, 48, 8) },
	{ "Cap", "frontleft", Vector3.new(-119, 49, -3), Vector3.new(130, 2, 10) },
	{ "Wall", "frontright", Vector3.new(116, 24, -4), Vector3.new(120, 48, 8) },
	{ "Cap", "frontright", Vector3.new(119, 49, -3), Vector3.new(130, 2, 10) },
}
-- The floor: { dirt (1) or grass (0), low x, low z, size x, size z }, on 8-stud cells.
local FLOOR = {
	{ 0, -176, 0, 152, 8 },
	{ 1, -24, 0, 16, 96 },
	{ 0, -8, 0, 184, 8 },
	{ 0, -176, 8, 136, 8 },
	{ 1, -40, 8, 16, 152 },
	{ 1, -8, 8, 32, 88 },
	{ 0, 24, 8, 152, 16 },
	{ 0, -176, 16, 128, 16 },
	{ 1, -48, 16, 8, 184 },
	{ 1, 24, 24, 16, 144 },
	{ 0, 40, 24, 136, 16 },
	{ 0, -176, 32, 120, 8 },
	{ 1, -56, 32, 8, 56 },
	{ 0, -176, 40, 112, 8 },
	{ 1, -64, 40, 8, 112 },
	{ 1, 40, 40, 8, 160 },
	{ 0, 48, 40, 128, 8 },
	{ 0, -176, 48, 104, 8 },
	{ 1, -72, 48, 8, 112 },
	{ 1, 48, 48, 16, 112 },
	{ 0, 64, 48, 112, 8 },
	{ 0, -176, 56, 96, 8 },
	{ 1, -80, 56, 8, 64 },
	{ 1, 64, 56, 8, 104 },
	{ 0, 72, 56, 104, 8 },
	{ 0, -176, 64, 80, 48 },
	{ 1, -96, 64, 16, 40 },
	{ 1, 72, 64, 24, 24 },
	{ 0, 96, 64, 80, 48 },
	{ 0, -56, 88, 8, 16 },
	{ 1, 72, 88, 16, 40 },
	{ 0, 88, 88, 8, 184 },
	{ 1, -24, 96, 8, 64 },
	{ 0, -16, 96, 24, 8 },
	{ 1, 8, 96, 16, 72 },
	{ 0, -96, 104, 16, 16 },
	{ 1, -56, 104, 8, 56 },
	{ 1, -16, 104, 24, 64 },
	{ 0, -176, 112, 24, 160 },
	{ 1, -152, 112, 24, 24 },
	{ 0, -128, 112, 32, 160 },
	{ 0, 96, 112, 32, 160 },
	{ 1, 128, 112, 24, 24 },
	{ 0, 152, 112, 24, 160 },
	{ 0, -96, 120, 8, 152 },
	{ 1, -88, 120, 8, 16 },
	{ 0, -80, 120, 8, 8 },
	{ 1, -80, 128, 8, 8 },
	{ 1, 72, 128, 8, 32 },
	{ 0, 80, 128, 8, 144 },
	{ 0, -152, 136, 8, 136 },
	{ 1, -144, 136, 8, 8 },
	{ 0, -136, 136, 8, 136 },
	{ 0, -88, 136, 16, 8 },
	{ 0, 128, 136, 8, 136 },
	{ 1, 136, 136, 8, 8 },
	{ 0, 144, 136, 8, 136 },
	{ 0, -144, 144, 8, 128 },
	{ 0, -88, 144, 8, 128 },
	{ 1, -80, 144, 8, 16 },
	{ 0, 136, 144, 8, 128 },
	{ 0, -64, 152, 8, 40 },
	{ 0, -80, 160, 16, 48 },
	{ 0, -56, 160, 8, 24 },
	{ 0, -40, 160, 24, 16 },
	{ 1, 48, 160, 8, 8 },
	{ 0, 56, 160, 24, 32 },
	{ 0, -16, 168, 8, 104 },
	{ 1, -8, 168, 16, 24 },
	{ 0, 8, 168, 32, 8 },
	{ 0, 48, 168, 8, 16 },
	{ 1, -40, 176, 8, 16 },
	{ 0, -32, 176, 16, 96 },
	{ 0, 8, 176, 24, 96 },
	{ 1, 32, 176, 8, 8 },
	{ 1, -56, 184, 8, 16 },
	{ 0, 32, 184, 8, 88 },
	{ 1, 48, 184, 8, 16 },
	{ 1, -64, 192, 8, 8 },
	{ 0, -40, 192, 8, 80 },
	{ 0, -8, 192, 16, 80 },
	{ 1, 56, 192, 8, 8 },
	{ 0, 64, 192, 16, 16 },
	{ 0, -64, 200, 24, 8 },
	{ 0, 40, 200, 24, 8 },
	{ 0, -80, 208, 8, 64 },
	{ 1, -72, 208, 32, 16 },
	{ 1, 40, 208, 32, 16 },
	{ 0, 72, 208, 8, 64 },
	{ 1, -72, 224, 24, 8 },
	{ 0, -48, 224, 8, 48 },
	{ 0, 40, 224, 8, 48 },
	{ 1, 48, 224, 24, 8 },
	{ 0, -72, 232, 8, 40 },
	{ 1, -64, 232, 16, 8 },
	{ 1, 48, 232, 16, 8 },
	{ 0, 64, 232, 8, 40 },
	{ 0, -64, 240, 16, 32 },
	{ 0, 48, 240, 16, 32 },
}
-- Meadow props: { model, x, z, yaw (degrees) }.
local PROPS = {
	{ "BoulderSplit", -120, 256, 2 },
	{ "Bush", -111.4, 254.9, 18 },
	{ "Stone", -120.5, 245.6, 283 },
	{ "BoulderSplit", 120, 256, 123 },
	{ "Bush", 110, 256.7, 178 },
	{ "Bush", 118.7, 244.6, 300 },
	{ "Bush", -42.3, 180.6, 70 },
	{ "Stone", -43.8, 170.9, 117 },
	{ "Bush", 42.3, 180.6, 33 },
	{ "Stone", 33.8, 175.6, 337 },
	{ "Bush", -96.6, 115.9, 131 },
	{ "Stone", -90.1, 108.4, 63 },
	{ "Bush", 96.6, 115.9, 0 },
	{ "Stone", 87.3, 119.1, 22 },
}
-- The big rocks (design/base_arc/*.rbxmx): their parts { name, size x3, CFrame x12
-- in the model's frame, r, g, b, collides (1/0) }, and where they go { model, x, z, yaw }.
local ROCK_MODELS = {
	CornerCrag = {
		{ "Crag", 22, 28, 22, 11, 14, 11, 0.975006, 0.079087, 0.207627, -0.069661, 0.996197, -0.052336, -0.210976, 0.036564, 0.976807, 150, 156, 170, 1 },
		{ "Crag", 20.4, 0.8, 20.4, 12.1388, 28.3452, 11.5265, 0.975006, 0.079087, 0.207627, -0.069661, 0.996197, -0.052336, -0.210976, 0.036564, 0.976807, 98, 200, 74, 1 },
		{ "Crag", 15, 18, 14, 27, 9, 8, 0.963063, -0.118249, -0.241922, 0.121869, 0.992546, 0, 0.240119, -0.029483, 0.970296, 150, 156, 170, 1 },
		{ "Crag", 13.4, 0.8, 12.4, 25.8885, 18.3299, 7.72286, 0.963063, -0.118249, -0.241922, 0.121869, 0.992546, 0, 0.240119, -0.029483, 0.970296, 176, 182, 194, 1 },
		{ "Crag", 14, 19, 15, 8, 9.5, 27, 0.927184, -0.039157, 0.372554, 0, 0.994522, 0.104528, -0.374607, -0.096917, 0.922105, 150, 156, 170, 1 },
		{ "Crag", 12.4, 0.8, 13.4, 7.61235, 19.3458, 26.0405, 0.927184, -0.039157, 0.372554, 0, 0.994522, 0.104528, -0.374607, -0.096917, 0.922105, 176, 182, 194, 1 },
		{ "Crag", 12, 9, 12, 22, 4.5, 22, 0.789689, -0.015225, 0.613319, 0.086824, 0.992404, -0.087156, -0.607333, 0.122077, 0.785012, 118, 124, 140, 1 },
		{ "Crag", 10.4, 0.8, 10.4, 21.9254, 9.36278, 22.5982, 0.789689, -0.015225, 0.613319, 0.086824, 0.992404, -0.087156, -0.607333, 0.122077, 0.785012, 176, 182, 194, 1 },
		{ "Crag", 6, 4.4, 6, 37, 2.2, 5, 0.892539, -0.157379, 0.422618, 0.173648, 0.984808, 0, -0.416198, 0.073387, 0.906308, 118, 124, 140, 1 },
		{ "Crag", 6, 4.4, 6, 5, 2.2, 37, 0.866025, -0.069587, -0.495134, 0, 0.990268, -0.139173, 0.5, 0.120527, 0.857597, 150, 156, 170, 1 },
		{ "Crag", 4, 3.2, 4, 30, 1.6, 30, 0.984808, 0, 0.173648, 0, 1, 0, -0.173648, 0, 0.984808, 150, 156, 170, 1 },
		{ "Crag", 2.4, 0.8, 2.4, 30, 3.6, 30, 0.984808, 0, 0.173648, 0, 1, 0, -0.173648, 0, 0.984808, 176, 182, 194, 1 },
		{ "Bush", 6.72, 2.88, 5.76, 11, 30.44, 11, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 5.28, 1.68, 4.32, 11, 32.72, 11, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 2.88, 0.96, 2.4, 11, 34.04, 11, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 0.72, 1.92, 3.36, 7.28, 30.44, 11, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 0.72, 1.92, 3.36, 14.72, 30.44, 11, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 5.04, 2.16, 4.32, 33, 1.08, 16, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 3.96, 1.26, 3.24, 33, 2.79, 16, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 2.16, 0.72, 1.8, 33, 3.78, 16, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 0.54, 1.44, 2.52, 30.21, 1.08, 16, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 0.54, 1.44, 2.52, 35.79, 1.08, 16, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 5.04, 2.16, 4.32, 16, 1.08, 34, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 3.96, 1.26, 3.24, 16, 2.79, 34, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 2.16, 0.72, 1.8, 16, 3.78, 34, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 0.54, 1.44, 2.52, 13.21, 1.08, 34, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 0.54, 1.44, 2.52, 18.79, 1.08, 34, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
	},
	WallShelf = {
		{ "Shelf", 16, 14, 13, -13, 7, 6.5, 0.983828, -0.113166, 0.138834, 0.104274, 0.992099, 0.069756, -0.145631, -0.054152, 0.987856, 150, 156, 170, 1 },
		{ "Shelf", 14.4, 0.8, 11.4, -13.8374, 14.3415, 6.09928, 0.983828, -0.113166, 0.138834, 0.104274, 0.992099, 0.069756, -0.145631, -0.054152, 0.987856, 176, 182, 194, 1 },
		{ "Shelf", 18, 20, 14, 3, 10, 7, 0.991718, 0.074832, -0.104385, -0.069661, 0.996197, 0.052336, 0.107905, -0.044631, 0.993159, 150, 156, 170, 1 },
		{ "Shelf", 16.4, 0.8, 12.4, 3.77825, 20.3605, 6.53584, 0.991718, 0.074832, -0.104385, -0.069661, 0.996197, 0.052336, 0.107905, -0.044631, 0.993159, 98, 200, 74, 1 },
		{ "Shelf", 12, 11, 12, 17, 5.5, 7.5, 0.930548, -0.13078, 0.34202, 0.139173, 0.990268, 0, -0.338692, 0.0476, 0.939693, 118, 124, 140, 1 },
		{ "Shelf", 10.4, 0.8, 10.4, 16.2284, 11.3426, 7.78084, 0.930548, -0.13078, 0.34202, 0.139173, 0.990268, 0, -0.338692, 0.0476, 0.939693, 176, 182, 194, 1 },
		{ "Shelf", 5, 4, 5, -23, 2, 9, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025, 150, 156, 170, 1 },
		{ "Shelf", 4, 3.6, 4, 9, 1.8, 16, 0.939693, 0, -0.34202, 0, 1, 0, 0.34202, 0, 0.939693, 150, 156, 170, 1 },
		{ "Shelf", 2.4, 0.8, 2.4, 9, 4, 16, 0.939693, 0, -0.34202, 0, 1, 0, 0.34202, 0, 0.939693, 176, 182, 194, 1 },
		{ "Bush", 5.04, 2.16, 4.32, -4, 1.08, 14.5, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 3.96, 1.26, 3.24, -4, 2.79, 14.5, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 2.16, 0.72, 1.8, -4, 3.78, 14.5, 1, 0, 0, 0, 1, 0, 0, 0, 1, 98, 200, 74, 1 },
		{ "Bush", 0.54, 1.44, 2.52, -6.79, 1.08, 14.5, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
		{ "Bush", 0.54, 1.44, 2.52, -1.21, 1.08, 14.5, 1, 0, 0, 0, 1, 0, 0, 0, 1, 70, 168, 58, 1 },
	},
}
local ROCKS = {
	{ "CornerCrag", -176, 264, 90 },
	{ "CornerCrag", 176, 264, 180 },
	{ "WallShelf", -76, 264, 180 },
	{ "WallShelf", 76, 264, 180 },
	{ "WallShelf", -176, 140, 90 },
	{ "WallShelf", 176, 140, -90 },
}
-- Bull pads: { pen, x, z }.
local BULLS = {

}

-- Walls: the home base's are the ones round z 0..the old depth; which is which by where they are.
local function which(p)
	local c = p.Position
	if c.Z > 20 and math.abs(c.X) < 40 then
		return "back"
	elseif c.Z > 20 and c.X < 0 then
		return "left"
	elseif c.Z > 20 then
		return "right"
	elseif c.Z > -10 and c.Z < 0 and math.abs(c.X) > 56 then
		return if c.X < 0 then "frontleft" else "frontright"
	end
	return nil
end
local moved = 0
for _, p in world.Walls:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "Wall" or p.Name == "Cap") and p.Position.Z + p.Size.Z / 2 > -10 then
		local w = which(p)
		for _, spec in WALLS do
			if spec[1] == p.Name and spec[2] == w then
				p.Size, p.CFrame = spec[4], CFrame.new(spec[3])
				moved += 1
			end
		end
	end
end

-- The floor: the old single home Ground part (or a previous run's rectangles) goes.
local template
for _, p in world.Ground:GetChildren() do
	if p:IsA("BasePart") and (p:GetAttribute("ArcBase") or (p.Name == "Ground" and p.Position.Z > 0 and p.Size.X > 200)) then
		template = template or p:Clone()
		p:Destroy()
	end
end
assert(template, "no home Ground part to copy the look of")
for _, t in template:GetChildren() do
	if not t:IsA("Texture") then
		t:Destroy()
	end
end
template:SetAttribute("ArcBase", true)
for _, r in FLOOR do
	local dirt, x, z, sx, sz = r[1] == 1, r[2], r[3], r[4], r[5]
	local top = if dirt then -1 else 0
	local p = template:Clone()
	p.Name = if dirt then "Dirt" else "Ground"
	p.Size = Vector3.new(sx, top + 2, sz)
	p.CFrame = CFrame.new(x + sx / 2, (top - 2) / 2, z + sz / 2)
	-- (on 8-stud cells every corner starts on a whole checker square: no offsets, like the course)
	p.Parent = world.Ground
end

-- The floor's top under (x, z): 0 on grass, -1 on dirt.
local function topAt(x, z)
	for _, r in FLOOR do
		if r[1] == 1 and x >= r[2] and x < r[2] + r[4] and z >= r[3] and z < r[3] + r[5] then
			return -1
		end
	end
	return 0
end

-- Meadow props round the walls.
local decor = world:FindFirstChild("BaseDecor") or Instance.new("Folder")
decor.Name = "BaseDecor"
decor:ClearAllChildren()
local templates = {}
for _, o in world.Obstacles:GetChildren() do
	local cf = if o:IsA("Model") then o:GetPivot() elseif o:IsA("BasePart") then o.CFrame else nil
	if cf and cf.Z < 0 and cf.Z > -760 and not templates[o.Name] then
		templates[o.Name] = o
	end
end
local placed = 0
for _, r in PROPS do
	local from = templates[r[1]]
	if from then
		local copy = from:Clone()
		for _, name in { "FunnelPivot", "FunnelScale", "FunnelCF", "FunnelSize" } do
			copy:SetAttribute(name, nil)
		end
		-- standing on the floor as the original does: its invisible Base's top on the
		-- floor's (a turned model's bounding box reaches lower than its parts: Oct 9,
		-- standing that on the floor left them floating)
		local pivot = if copy:IsA("Model") then copy:GetPivot() else copy.CFrame
		local base = copy:FindFirstChild("Base")
		local up = if base and base:IsA("BasePart") then pivot.Y - (base.Position.Y + base.Size.Y / 2) else pivot.Y
		local cf = CFrame.new(r[2], topAt(r[2], r[3]) + up, r[3]) * CFrame.Angles(0, math.rad(r[4]), 0)
		if copy:IsA("Model") then
			copy:PivotTo(cf)
		else
			copy.CFrame = cf
		end
		copy.Parent = decor
		placed += 1
	end
end
-- The big rocks: built from their parts, studded all over (0.5-stud studs, as Design's),
-- pivot at their own origin, then placed and turned.
local STUDS = "rbxassetid://7447638591"
local rocks = 0
for _, r in ROCKS do
	local m = Instance.new("Model")
	m.Name = r[1]
	for _, s in ROCK_MODELS[r[1]] or {} do
		local p = Instance.new("Part")
		p.Name = s[1]
		p.Anchored = true
		p.CanCollide = s[20] == 1
		p.Material = Enum.Material.SmoothPlastic
		for _, surface in { "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do
			p[surface] = Enum.SurfaceType.Smooth
		end
		p.Size = Vector3.new(s[2], s[3], s[4])
		p.CFrame = CFrame.new(s[5], s[6], s[7], s[8], s[9], s[10], s[11], s[12], s[13], s[14], s[15], s[16])
		p.Color = Color3.fromRGB(s[17], s[18], s[19])
		for _, face in Enum.NormalId:GetEnumItems() do
			local t = Instance.new("Texture")
			t.Texture = STUDS
			t.Face = face
			t.StudsPerTileU, t.StudsPerTileV = 0.5, 0.5
			t.Parent = p
		end
		p.Parent = m
	end
	m.WorldPivot = CFrame.new()
	m:PivotTo(CFrame.new(r[2], 0, r[3]) * CFrame.Angles(0, math.rad(r[4]), 0))
	m.Parent = decor
	rocks += 1
end
decor.Parent = world

-- Bull pads (placeholders): a red mat 18 across, a post and a bull on it, facing the yard.
local pads = world:FindFirstChild("BullPads") or Instance.new("Folder")
pads.Name = "BullPads"
pads:ClearAllChildren()
local function block(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Parent = parent
	return p
end
if #BULLS == 0 then
	pads:Destroy() -- (none for now: BULL_PADS in tools/arc_base.py)
	pads = nil
end
for _, r in BULLS do
	local at = Vector3.new(r[2], topAt(r[2], r[3]), r[3])
	local face = CFrame.lookAt(at, Vector3.new(YARD.X, at.Y, YARD.Z))
	local m = Instance.new("Model")
	m.Name = "BullPad" .. r[1]
	m:SetAttribute("Pen", r[1])
	block(m, "Mat", Vector3.new(0.4, 18, 18), face * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(210, 60, 60), Enum.PartType.Cylinder)
	block(m, "Post", Vector3.new(1, 4, 1), face * CFrame.new(0, 2.4, 0), Color3.fromRGB(90, 90, 100))
	block(m, "Bull", Vector3.new(3, 2.4, 5.5), face * CFrame.new(0, 5.6, 0), Color3.fromRGB(120, 72, 44))
	block(m, "Head", Vector3.new(2.2, 2, 2), face * CFrame.new(0, 6.2, -3.4), Color3.fromRGB(110, 64, 38))
	m.PrimaryPart = m.Mat
	m.Parent = pads
end
if pads then
	pads.Parent = world
end

return string.format("arc base: %d walls moved, %d floor parts, %d props, %d big rocks, %d bull pads", moved, #FLOOR, placed, rocks, #BULLS)
