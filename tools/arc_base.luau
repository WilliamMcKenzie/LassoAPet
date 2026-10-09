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
	{ 0, -176, 8, 48, 8 },
	{ 1, -128, 8, 8, 120 },
	{ 0, -120, 8, 16, 8 },
	{ 1, -104, 8, 8, 104 },
	{ 0, -96, 8, 56, 8 },
	{ 1, -40, 8, 16, 152 },
	{ 1, -8, 8, 32, 88 },
	{ 0, 24, 8, 88, 8 },
	{ 1, 112, 8, 8, 104 },
	{ 0, 120, 8, 56, 8 },
	{ 0, -176, 16, 40, 8 },
	{ 1, -136, 16, 8, 96 },
	{ 1, -120, 16, 16, 96 },
	{ 1, -96, 16, 8, 8 },
	{ 0, -88, 16, 40, 16 },
	{ 1, -48, 16, 8, 152 },
	{ 0, 24, 16, 80, 8 },
	{ 1, 104, 16, 8, 96 },
	{ 1, 120, 16, 8, 96 },
	{ 0, 128, 16, 48, 8 },
	{ 0, -176, 24, 16, 16 },
	{ 1, -160, 24, 24, 80 },
	{ 0, -96, 24, 8, 8 },
	{ 1, 24, 24, 16, 144 },
	{ 0, 40, 24, 56, 8 },
	{ 1, 96, 24, 8, 88 },
	{ 1, 128, 24, 40, 8 },
	{ 0, 168, 24, 8, 248 },
	{ 1, -96, 32, 16, 16 },
	{ 0, -80, 32, 24, 8 },
	{ 1, -56, 32, 8, 56 },
	{ 0, 40, 32, 40, 8 },
	{ 1, 80, 32, 16, 16 },
	{ 1, 128, 32, 32, 72 },
	{ 0, 160, 32, 8, 8 },
	{ 0, -176, 40, 8, 232 },
	{ 1, -168, 40, 8, 72 },
	{ 0, -80, 40, 16, 8 },
	{ 1, -64, 40, 8, 112 },
	{ 1, 40, 40, 8, 128 },
	{ 0, 48, 40, 32, 8 },
	{ 1, 160, 40, 8, 72 },
	{ 1, -96, 48, 8, 56 },
	{ 0, -88, 48, 16, 8 },
	{ 1, -72, 48, 8, 152 },
	{ 1, 48, 48, 16, 144 },
	{ 0, 64, 48, 24, 8 },
	{ 1, 88, 48, 8, 40 },
	{ 0, -88, 56, 8, 8 },
	{ 1, -80, 56, 8, 64 },
	{ 1, 64, 56, 8, 144 },
	{ 0, 72, 56, 16, 8 },
	{ 1, -88, 64, 8, 40 },
	{ 1, 72, 64, 16, 144 },
	{ 0, -56, 88, 8, 16 },
	{ 0, 88, 88, 8, 32 },
	{ 1, -24, 96, 8, 64 },
	{ 0, -16, 96, 24, 8 },
	{ 1, 8, 96, 16, 72 },
	{ 0, -160, 104, 16, 32 },
	{ 1, -144, 104, 8, 8 },
	{ 0, -96, 104, 16, 16 },
	{ 1, -56, 104, 8, 56 },
	{ 1, -16, 104, 24, 64 },
	{ 0, 128, 104, 16, 40 },
	{ 1, 144, 104, 16, 8 },
	{ 0, -168, 112, 8, 104 },
	{ 0, -144, 112, 16, 32 },
	{ 0, -120, 112, 24, 8 },
	{ 0, 96, 112, 32, 8 },
	{ 0, 144, 112, 24, 16 },
	{ 0, -120, 120, 16, 8 },
	{ 1, -104, 120, 16, 104 },
	{ 0, -88, 120, 16, 8 },
	{ 1, 88, 120, 40, 8 },
	{ 0, -128, 128, 16, 8 },
	{ 1, -112, 128, 8, 96 },
	{ 1, -88, 128, 8, 88 },
	{ 0, -80, 128, 8, 8 },
	{ 1, 88, 128, 24, 96 },
	{ 0, 112, 128, 16, 8 },
	{ 1, 144, 128, 16, 24 },
	{ 0, 160, 128, 8, 8 },
	{ 0, -160, 136, 8, 8 },
	{ 1, -152, 136, 8, 40 },
	{ 0, -128, 136, 8, 8 },
	{ 1, -120, 136, 8, 80 },
	{ 1, -80, 136, 8, 72 },
	{ 1, 112, 136, 8, 80 },
	{ 0, 120, 136, 8, 8 },
	{ 1, 160, 136, 8, 8 },
	{ 1, -160, 144, 8, 8 },
	{ 0, -144, 144, 8, 8 },
	{ 1, -136, 144, 16, 56 },
	{ 1, 120, 144, 16, 56 },
	{ 0, 136, 144, 8, 8 },
	{ 0, 160, 144, 8, 48 },
	{ 0, -160, 152, 8, 120 },
	{ 1, -144, 152, 8, 40 },
	{ 0, -64, 152, 8, 8 },
	{ 1, 136, 152, 16, 24 },
	{ 0, 152, 152, 8, 48 },
	{ 1, -64, 160, 8, 32 },
	{ 0, -56, 160, 8, 8 },
	{ 0, -40, 160, 24, 24 },
	{ 1, -56, 168, 8, 16 },
	{ 0, -48, 168, 8, 56 },
	{ 0, -16, 168, 8, 16 },
	{ 1, -8, 168, 16, 88 },
	{ 0, 8, 168, 40, 16 },
	{ 0, -152, 176, 8, 96 },
	{ 1, 136, 176, 8, 16 },
	{ 0, 144, 176, 8, 48 },
	{ 0, -56, 184, 8, 88 },
	{ 1, -40, 184, 32, 72 },
	{ 1, 8, 184, 32, 72 },
	{ 0, 40, 184, 8, 88 },
	{ 0, -144, 192, 8, 48 },
	{ 0, -64, 192, 8, 80 },
	{ 1, 48, 192, 8, 8 },
	{ 0, 56, 192, 8, 80 },
	{ 0, 136, 192, 8, 80 },
	{ 1, 160, 192, 8, 16 },
	{ 0, -136, 200, 8, 72 },
	{ 1, -128, 200, 8, 8 },
	{ 0, -72, 200, 8, 72 },
	{ 0, 48, 200, 8, 72 },
	{ 0, 64, 200, 8, 24 },
	{ 1, 120, 200, 8, 8 },
	{ 0, 128, 200, 8, 16 },
	{ 1, 152, 200, 8, 8 },
	{ 0, -128, 208, 8, 64 },
	{ 0, -80, 208, 8, 16 },
	{ 0, 72, 208, 8, 64 },
	{ 1, 80, 208, 8, 8 },
	{ 0, 120, 208, 8, 8 },
	{ 0, 152, 208, 16, 16 },
	{ 1, -168, 216, 8, 8 },
	{ 0, -120, 216, 8, 56 },
	{ 0, -88, 216, 8, 16 },
	{ 0, 80, 216, 8, 56 },
	{ 0, 112, 216, 8, 56 },
	{ 1, 120, 216, 16, 16 },
	{ 0, -168, 224, 8, 48 },
	{ 0, -112, 224, 16, 48 },
	{ 1, -96, 224, 8, 32 },
	{ 1, -80, 224, 8, 8 },
	{ 1, -48, 224, 8, 8 },
	{ 1, 64, 224, 8, 32 },
	{ 0, 88, 224, 24, 24 },
	{ 1, 144, 224, 16, 8 },
	{ 0, 160, 224, 8, 8 },
	{ 1, -88, 232, 8, 16 },
	{ 0, -80, 232, 8, 40 },
	{ 0, -48, 232, 8, 40 },
	{ 1, 120, 232, 8, 8 },
	{ 0, 128, 232, 8, 40 },
	{ 0, 144, 232, 8, 40 },
	{ 1, 152, 232, 16, 8 },
	{ 1, -144, 240, 8, 16 },
	{ 0, 120, 240, 8, 32 },
	{ 0, 152, 240, 8, 32 },
	{ 1, 160, 240, 8, 8 },
	{ 0, -88, 248, 8, 24 },
	{ 1, 88, 248, 8, 8 },
	{ 0, 96, 248, 16, 24 },
	{ 0, 160, 248, 8, 24 },
	{ 0, -144, 256, 8, 16 },
	{ 0, -96, 256, 8, 16 },
	{ 0, -40, 256, 80, 16 },
	{ 0, 64, 256, 8, 16 },
	{ 0, 88, 256, 8, 16 },
}
-- Meadow props: { model, x, z, yaw (degrees) }.
local PROPS = {
	{ "BoulderSplit", -168, 256, 291 },
	{ "Bush", -158, 255.4, 147 },
	{ "Bush", -166.5, 246.5, 351 },
	{ "Boulder", 168, 256, 177 },
	{ "BoulderSplit", -168, 150, 7 },
	{ "Bush", -157.4, 148.5, 73 },
	{ "Bush", -168.6, 138.9, 288 },
	{ "Stone", -168.8, 159.5, 182 },
	{ "Boulder", 168, 150, 5 },
	{ "Bush", 167.7, 141.3, 267 },
	{ "Bush", 168.5, 160.6, 231 },
	{ "Boulder", -58, 256, 249 },
	{ "Bush", -47.6, 255.6, 141 },
	{ "Stone", -67.1, 255.6, 339 },
	{ "BoulderSplit", 58, 256, 144 },
	{ "Bush", 47.5, 255.7, 227 },
	{ "Stone", 59.3, 247.3, 68 },
	{ "Boulder", -168, 12, 26 },
	{ "Stone", -156.9, 13, 93 },
	{ "Bush", -168.7, 21.8, 70 },
	{ "Boulder", 168, 12, 334 },
	{ "Stone", 167.7, 22.3, 249 },
	{ "BoulderSplit", -120, 256, 2 },
	{ "Bush", -111.4, 254.9, 18 },
	{ "Stone", -120.5, 245.6, 283 },
	{ "BoulderSplit", 120, 256, 123 },
	{ "Bush", 110, 256.7, 178 },
	{ "Bush", 118.7, 244.6, 300 },
	{ "Boulder", -168, 210, 215 },
	{ "Bush", -157.3, 210.1, 221 },
	{ "Bush", -167.3, 221.4, 94 },
	{ "Boulder", 168, 210, 6 },
	{ "Bush", 157, 210.6, 69 },
	{ "Bush", 168.5, 200, 99 },
	{ "Stone", 168, 221.3, 90 },
	{ "Bush", -42.3, 180.6, 70 },
	{ "Stone", -43.8, 170.9, 117 },
	{ "Bush", 42.3, 180.6, 33 },
	{ "Stone", 33.8, 175.6, 337 },
	{ "Bush", -96.6, 115.9, 131 },
	{ "Stone", -90.1, 108.4, 63 },
	{ "Bush", 96.6, 115.9, 0 },
	{ "Stone", 87.3, 119.1, 22 },
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

return string.format("arc base: %d walls moved, %d floor parts, %d props, %d bull pads", moved, #FLOOR, placed, #BULLS)
