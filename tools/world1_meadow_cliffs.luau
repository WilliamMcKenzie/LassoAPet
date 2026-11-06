-- World 1's Meadow as open country (QM, Nov 6; his references: a dino-riding game's meadow):
-- instead of two flat 48-stud walls with blank sky past them, stepped block cliffs of
-- mixed heights and setbacks rise from the course's edge, grassy plateaus with pines,
-- boulders and flowers on the low steps, tall tan cliffs behind, and huge mesas further
-- out that the Meadow's Haze (Config: Lighting fog, Client/Ocean) fades to pale shapes.
--
-- Run in Studio's Edit mode on World 1's place (execute_luau or the command bar), then
-- publish. Safe to run again: it rebuilds World.Cliffs from the same seed.
--   * the Meadow's floor becomes one tile: its dirt patches are Ground at height 0
--   * the Meadow's walls move to World.Barriers: still solid, but invisible (no textures),
--     so the course is as wide as before and nobody rides off it
--   * World.Cliffs: the scenery, built here (nothing collides with it)
-- The base is left as it is. Only the Meadow (z 0 to Config's first Length, as built).

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local world = workspace:FindFirstChild("World")
assert(world and world:FindFirstChild("Ground") and world:FindFirstChild("Walls"), "needs World 1's workspace.World")

local Z_NEAR, Z_FAR = -8, -2168 -- the Meadow, from just past the base's front walls to the Desert
local STUDS = "rbxassetid://7447638591" -- (Shared/Studs turns this into the stud material in Play)
local SEED = 1106

local GRASS = Color3.fromRGB(23, 191, 29) -- the Meadow's ground (Config GroundColors[1])
local GRASS_DARK = Color3.fromRGB(20, 172, 26)
local TAN = { Color3.fromRGB(226, 186, 128), Color3.fromRGB(214, 172, 114), Color3.fromRGB(234, 198, 142) }
local MESA = { Color3.fromRGB(232, 200, 150), Color3.fromRGB(222, 188, 136) }
local TRUNK = Color3.fromRGB(150, 98, 58)
local PINE = { Color3.fromRGB(32, 150, 60), Color3.fromRGB(26, 132, 52) }
local FLOWER = { Color3.fromRGB(255, 220, 40), Color3.fromRGB(255, 236, 110) }

-- The course's half width at z (Config.CourseHalfWidth + CourseWidening, as the walls stand).
local function halfWidth(z)
	return math.min(56 + 0.005 * math.max(-z, 0), 137)
end

local recording = ChangeHistoryService:TryBeginRecording("Meadow cliffs")
local rng = Random.new(SEED)
local count = { ground = 0, walls = 0, parts = 0 }

-- 1. one ground tile: the Meadow's dirt (and any other patch) becomes Ground, flush at 0
for _, part in world.Ground:GetChildren() do
	local z = part.Position.Z
	if part:IsA("BasePart") and z < 0 and z > Z_FAR and part.Name ~= "Ground" then
		part.Name = "Ground"
		part.Size = Vector3.new(part.Size.X, 2, part.Size.Z)
		part.Position = Vector3.new(part.Position.X, -1, z)
		count.ground += 1
	end
end

-- 2. the Meadow's side walls: invisible barriers (World.Barriers is outside WorldColors)
local barriers = world:FindFirstChild("Barriers")
if not barriers then
	barriers = Instance.new("Folder")
	barriers.Name = "Barriers"
	barriers.Parent = world
end
for _, part in world.Walls:GetChildren() do
	local z = part.Position.Z
	local angled = part.CFrame.Rotation ~= CFrame.identity
	if part:IsA("BasePart") and angled and z < 0 and z > Z_FAR then
		for _, child in part:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy()
			end
		end
		part.Transparency = 1
		part.CastShadow = false
		part.Name = "Meadow" .. part.Name
		part.Parent = barriers
		count.walls += 1
	end
end

-- 3. the scenery
local old = world:FindFirstChild("Cliffs")
if old then
	old:Destroy()
end
local cliffs = Instance.new("Folder")
cliffs.Name = "Cliffs"
cliffs.Parent = world

local function block(parent, name, x0, y0, z0, x1, y1, z1, color, studs)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0))
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	if studs then
		local t = Instance.new("Texture")
		t.Texture = STUDS
		t.Face = Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV = 1, 1
		t.Parent = p
	end
	p.Parent = parent
	count.parts += 1
	return p
end

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

-- a chunky pine: a trunk and three shrinking blocks of needles
local function pine(parent, x, y, z, s)
	block(parent, "Trunk", x - 0.8 * s, y, z - 0.8 * s, x + 0.8 * s, y + 4 * s, z + 0.8 * s, TRUNK, false)
	local green = pick(PINE)
	local h = y + 3 * s
	for k, w in { 5, 3.6, 2.2 } do
		block(parent, "Needles", x - w * s, h, z - w * s, x + w * s, h + 3 * s, z + w * s, if k == 2 then GRASS_DARK else green, true)
		h += 2.6 * s
	end
end

local function boulder(parent, x, y, z, s)
	local p = block(parent, "Boulder", x - s, y - 0.5, z - s * 0.8, x + s, y + s * 1.2, z + s * 0.8, pick(TAN), true)
	p.CFrame = p.CFrame * CFrame.Angles(0, rng:NextNumber(0, math.pi), rng:NextNumber(-0.15, 0.15))
end

local function flowers(parent, x0, x1, y, z0, z1)
	for _ = 1, rng:NextInteger(3, 7) do
		local x, z = rng:NextNumber(x0, x1), rng:NextNumber(z1, z0)
		block(parent, "Flower", x - 0.5, y, z - 0.5, x + 0.5, y + 0.6, z + 0.5, pick(FLOWER), false)
	end
end

-- Each side: segments along the course, each a stack of steps going out and up. The
-- heights wander from one segment to the next, so the skyline rises unevenly.
for _, side in { -1, 1 } do
	local folder = Instance.new("Folder")
	folder.Name = if side < 0 then "West" else "East"
	folder.Parent = cliffs
	local z = Z_NEAR
	local plateau, middle, tall = 6, 20, 56
	while z > Z_FAR do
		local len = math.min(rng:NextInteger(6, 16) * 4, z - Z_FAR)
		local z0, z1 = z, z - len
		-- (the steps start where the wall's inside face was, rounded out to whole studs)
		local edge = math.ceil(halfWidth(z1)) + 1
		local x = edge
		local function out(depth)
			local a, b = x, x + depth
			x = b
			return side * a, side * b
		end
		local seg = Instance.new("Model")
		seg.Name = "Step"
		seg.Parent = folder
		-- the low grassy plateau (sometimes left out: the cliff then meets the grass)
		plateau = math.clamp(plateau + rng:NextInteger(-1, 1) * 2, 2, 10)
		if rng:NextNumber() < 0.8 then
			local depth = rng:NextInteger(3, 7) * 4
			local a, b = out(depth)
			block(seg, "Cliff", a, -4, z0, b, plateau - 1, z1, pick(TAN), true)
			block(seg, "Grass", a, plateau - 1, z0, b, plateau, z1, GRASS, true)
			local lo, hi = math.min(a, b) + 2, math.max(a, b) - 2
			if rng:NextNumber() < 0.55 then
				pine(seg, rng:NextNumber(lo, hi), plateau, rng:NextNumber(z1 + 4, z0 - 4), rng:NextNumber(0.9, 1.5))
			end
			if rng:NextNumber() < 0.35 then
				boulder(seg, rng:NextNumber(lo, hi), plateau, rng:NextNumber(z1 + 3, z0 - 3), rng:NextNumber(1.5, 3.5))
			end
			if rng:NextNumber() < 0.6 then
				flowers(seg, lo, hi, plateau, z0 - 2, z1 + 2)
			end
		end
		-- the middle step, grass on top
		middle = math.clamp(middle + rng:NextInteger(-2, 2) * 2, plateau + 8, 34)
		do
			local depth = rng:NextInteger(4, 9) * 4
			local a, b = out(depth)
			block(seg, "Cliff", a, -4, z0, b, middle - 1, z1, pick(TAN), true)
			block(seg, "Grass", a, middle - 1, z0, b, middle, z1, GRASS_DARK, true)
			if rng:NextNumber() < 0.45 then
				local lo, hi = math.min(a, b) + 3, math.max(a, b) - 3
				pine(seg, rng:NextNumber(lo, hi), middle, rng:NextNumber(z1 + 4, z0 - 4), rng:NextNumber(1.2, 2))
			end
		end
		-- the tall tan cliff behind
		tall = math.clamp(tall + rng:NextInteger(-3, 3) * 4, middle + 16, 96)
		do
			local depth = rng:NextInteger(10, 20) * 4
			local a, b = out(depth)
			block(seg, "Cliff", a, -4, z0, b, tall, z1, pick(TAN), true)
		end
		z = z1
	end
end

-- the land past the cliffs, and the mesas standing in it (fog does the rest)
local far = Instance.new("Folder")
far.Name = "Far"
far.Parent = cliffs
for _, side in { -1, 1 } do
	for _, span in { { -8, -1200 }, { -1200, -2400 } } do
		block(far, "Land", side * 120, -4, span[1], side * 900, 2, span[2], GRASS_DARK, false)
	end
end
for _ = 1, 46 do
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	local x = side * rng:NextNumber(300, 820)
	local z = rng:NextNumber(-2400, 150)
	local w, d = rng:NextNumber(60, 200), rng:NextNumber(60, 220)
	local h = rng:NextNumber(70, 260)
	local m = Instance.new("Model")
	m.Name = "Mesa"
	m.Parent = far
	block(m, "Mesa", x - w / 2, 0, z - d / 2, x + w / 2, h, z + d / 2, pick(MESA), true)
	-- (a smaller block on top or to one side, so it's not a plain box)
	if rng:NextNumber() < 0.7 then
		local w2, d2 = w * rng:NextNumber(0.3, 0.6), d * rng:NextNumber(0.3, 0.6)
		local ox, oz = rng:NextNumber(-w / 4, w / 4), rng:NextNumber(-d / 4, d / 4)
		block(m, "Mesa", x + ox - w2 / 2, h, z + oz - d2 / 2, x + ox + w2 / 2, h + rng:NextNumber(16, 60), z + oz + d2 / 2, pick(MESA), true)
	end
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return string.format("Meadow: %d ground patches flattened, %d walls made barriers, %d scenery parts", count.ground, count.walls, count.parts)
