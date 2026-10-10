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
	{ 1, -24, 0, 16, 160 },
	{ 0, -8, 0, 184, 8 },
	{ 0, -176, 8, 136, 8 },
	{ 1, -40, 8, 16, 152 },
	{ 1, -8, 8, 32, 160 },
	{ 0, 24, 8, 152, 16 },
	{ 0, -176, 16, 128, 16 },
	{ 1, -48, 16, 8, 184 },
	{ 1, 24, 24, 16, 144 },
	{ 0, 40, 24, 136, 16 },
	{ 0, -176, 32, 120, 8 },
	{ 1, -56, 32, 8, 128 },
	{ 0, -176, 40, 112, 8 },
	{ 1, -64, 40, 8, 112 },
	{ 1, 40, 40, 8, 160 },
	{ 0, 48, 40, 128, 8 },
	{ 0, -176, 48, 104, 8 },
	{ 1, -72, 48, 8, 112 },
	{ 1, 48, 48, 16, 112 },
	{ 0, 64, 48, 112, 8 },
	{ 0, -176, 56, 96, 8 },
	{ 1, -80, 56, 8, 80 },
	{ 1, 64, 56, 8, 104 },
	{ 0, 72, 56, 104, 8 },
	{ 0, -176, 64, 80, 48 },
	{ 1, -96, 64, 16, 40 },
	{ 1, 72, 64, 24, 24 },
	{ 0, 96, 64, 80, 48 },
	{ 1, 72, 88, 16, 40 },
	{ 0, 88, 88, 8, 184 },
	{ 0, -96, 104, 16, 16 },
	{ 0, -176, 112, 24, 160 },
	{ 1, -152, 112, 24, 24 },
	{ 0, -128, 112, 32, 160 },
	{ 0, 96, 112, 32, 160 },
	{ 1, 128, 112, 24, 24 },
	{ 0, 152, 112, 24, 160 },
	{ 0, -96, 120, 8, 152 },
	{ 1, -88, 120, 8, 16 },
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
	{ 1, -16, 160, 8, 8 },
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
-- The rocks (QM, Oct 10: Design's studded low-poly meshes, design/rocks/*.obj, uploaded
-- as meshes): { mesh, x, z, yaw (degrees) }, along the walls and in the corners.
local MESHES = {
	Pebble = 97909332868672,
	Stone = 116242154122535,
	Pillar = 79713364061574,
	Boulder = 109133145406087,
	Twins = 121967427061110,
	Slab = 118417030739444,
	Crag = 105444261900626,
	Cliff = 102261747583883,
}
local ROCKS = {
	{ "Cliff", -158, 248, 30 },
	{ "Cliff", 158, 248, -30 },
	{ "Crag", -128, 254, 190 },
	{ "Crag", 128, 254, -190 },
	{ "Boulder", -141, 233, 70 },
	{ "Boulder", 141, 233, -70 },
	{ "Pillar", -170, 226, 10 },
	{ "Pillar", 170, 226, -10 },
	{ "Stone", -122, 240, 120 },
	{ "Stone", 122, 240, -120 },
	{ "Pebble", -131, 236, 40 },
	{ "Pebble", 131, 236, -40 },
	{ "Pebble", -151, 224, 200 },
	{ "Pebble", 151, 224, -200 },
	{ "Slab", -101, 258, 5 },
	{ "Slab", 101, 258, -5 },
	{ "Twins", -85, 256, 160 },
	{ "Twins", 85, 256, -160 },
	{ "Stone", -93, 249, 30 },
	{ "Stone", 93, 249, -30 },
	{ "Pebble", -73, 258, 80 },
	{ "Pebble", 73, 258, -80 },
	{ "Boulder", -58, 257, 300 },
	{ "Boulder", 58, 257, -300 },
	{ "Crag", -166, 186, 95 },
	{ "Crag", 166, 186, -95 },
	{ "Twins", -168, 206, 80 },
	{ "Twins", 168, 206, -80 },
	{ "Boulder", -167, 161, 20 },
	{ "Boulder", 167, 161, -20 },
	{ "Stone", -159, 170, 250 },
	{ "Stone", 159, 170, -250 },
	{ "Pebble", -158, 151, 130 },
	{ "Pebble", 158, 151, -130 },
	{ "Slab", -169, 136, 90 },
	{ "Slab", 169, 136, -90 },
	{ "Pillar", -170, 119, 0 },
	{ "Pillar", 170, 119, 0 },
	{ "Pebble", -162, 126, 300 },
	{ "Pebble", 162, 126, -300 },
	{ "Boulder", -166, 12, 40 },
	{ "Boulder", 166, 12, -40 },
	{ "Pillar", -172, 24, 160 },
	{ "Pillar", 172, 24, -160 },
	{ "Stone", -155, 8, 200 },
	{ "Stone", 155, 8, -200 },
	{ "Pebble", -147, 5, 20 },
	{ "Pebble", 147, 5, -20 },
	{ "Slab", -133, 6, 0 },
	{ "Slab", 133, 6, 0 },
}
local ROCK_COLOR = Color3.fromRGB(172, 184, 212)
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

-- The rocks round the walls: everything that was in BaseDecor before goes (QM, Oct 10).
local AssetService = game:GetService("AssetService")
local decor = world:FindFirstChild("BaseDecor") or Instance.new("Folder")
decor.Name = "BaseDecor"
decor:ClearAllChildren()
local studs = game:GetService("MaterialService"):FindFirstChild("Studs", true)
local made = {}
local rocks = 0
for _, r in ROCKS do
	local from = made[r[1]]
	if not from then
		from = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. MESHES[r[1]]))
		made[r[1]] = from
	end
	local p = from:Clone()
	p.Name = "Rock" .. r[1]
	p.Anchored = true
	p.Color = ROCK_COLOR
	-- 1-stud studs, the same size as the ground's (QM, Oct 10; the meshes' UVs are drawn
	-- for 0.5-stud ones, but the material sets the size: Shared/Studs' "Studs")
	if studs then
		p.Material = studs.BaseMaterial
		p.MaterialVariant = studs.Name
		p.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.SmoothPlastic)
	else
		p.Material = Enum.Material.SmoothPlastic
	end
	-- (an uploaded mesh keeps its own origin at the part's position, not its box's middle:
	-- the rock's base, at its y 0, goes on the floor, its chunks 0.6 into the ground. Up
	-- by half its height, as first done, they floated: QM, Oct 10)
	p.CFrame = CFrame.new(r[2], topAt(r[2], r[3]), r[3]) * CFrame.Angles(0, math.rad(r[4]), 0)
	p.Parent = decor
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

return string.format("arc base: %d walls moved, %d floor parts, %d rocks, %d bull pads", moved, #FLOOR, rocks, #BULLS)
