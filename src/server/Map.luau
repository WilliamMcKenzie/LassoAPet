-- Builds workspace.World, the minimal baseline map (QM, Nov 6: strip the old map, keep
-- the layout as it was, a base and a linear course, walls straight for now; the look is
-- Fight to Steal an Egg's):
--   the base: a grass square behind the start line (Config.HomeHalfWidth either side of
--   x = 0, Config.HomeDepth deep), walled on its back and sides and either side of the
--   course's mouth;
--   the course: one straight corridor, Config.CourseHalfWidth either side of x = 0, from
--   the start line (z = 0) to the finish line (Config.FinishFromEnd before the last
--   biome's end), each biome's stretch in its own colours, walled down both sides.
--
-- Every floor and wall part is SmoothPlastic with the Matte MaterialVariant (no glare), a
-- world-aligned 8-stud checker and the classic stud texture over it, as in Fight to
-- Steal an Egg. Colours come from Config.Biomes (GroundColors, WallColors, CapColor;
-- the base's dirt is the Meadow's Patches.Dirt) and stay live-tunable in Play through
-- the World's attributes (Shared/WorldColors).
--
-- The World keeps the folders the game looks in: Ground, Walls, Obstacles, Nests and
-- Decor (empty for now), and the StartLine and FinishLine models.
--
--   Map.build() -> workspace.World

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local Map = {}

local CHECKER, STUDS = "rbxassetid://84747779882944", "rbxassetid://7447638591"
local FLOOR_BOTTOM = -2
local SEAM = 0.03 -- how far each floor part reaches past its edges, so no gap shows between them
local LIP = 0.25 -- how far a wall's cap overhangs it
local WALL_HEIGHT = 30 -- the cap's top
local WALL_THICK = 4
local CHUNK = 1024 -- longest part (Roblox caps a part at 2048 studs)
local GROUND_STUDS = { tile = 1, transparency = 0.5 } -- (Fight to Steal an Egg's StudStyle)
local WALL_STUDS = { tile = 2, transparency = 0.4 }
local TOP = { Enum.NormalId.Top }
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

-- the matte floor and walls: SmoothPlastic with a fully rough map, so the sun leaves no
-- white glare on it. default.project.json makes it; this is in case the place hasn't got it.
local MATTE = "Matte"
if not MaterialService:FindFirstChild(MATTE) then
	pcall(function()
		local v = Instance.new("MaterialVariant")
		v.Name = MATTE
		v.BaseMaterial = Enum.Material.SmoothPlastic
		v.RoughnessMap = "rbxassetid://134094806969492"
		v.Parent = MaterialService
	end)
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- A Texture on one face, lined up with the world grid so neighbouring parts' checkers and
-- studs meet (axis-aligned parts only).
local function texture(part, face, image, tile)
	local t = Instance.new("Texture")
	t.Name = if image == STUDS then "Studs" else "Checker"
	t.Face = face
	t.Texture = image
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	t.ZIndex = if image == STUDS then 2 else 1
	local corner = part.Position - part.Size / 2
	if face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		-- (a Top texture runs from the part's +x +z corner; the half tile turns the checker
		-- the right way round, which the studs, symmetric, don't need)
		local far = part.Position + part.Size / 2
		local half = if image == STUDS then 0 else tile / 2
		t.OffsetStudsU, t.OffsetStudsV = (half - far.X) % tile, (half - far.Z) % tile
	elseif face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		t.OffsetStudsU, t.OffsetStudsV = corner.X % tile, corner.Y % tile
	else
		t.OffsetStudsU, t.OffsetStudsV = corner.Z % tile, corner.Y % tile
	end
	t.Parent = part
	return t
end

-- An axis-aligned block from (x0, y0, z0) to (x1, y1, z1), in any corner order, with a
-- checker and studs on `faces`. WorldColors paints it by its name and where it stands.
local function box(name, parent, x0, y0, z0, x1, y1, z1, faces, studs)
	x0, x1 = math.min(x0, x1), math.max(x0, x1)
	y0, y1 = math.min(y0, y1), math.max(y0, y1)
	z0, z1 = math.min(z0, z1), math.max(z0, z1)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Locked = true
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Material = Enum.Material.SmoothPlastic
	p.MaterialVariant = MATTE
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for _, face in faces do
		texture(p, face, CHECKER, 8)
		local t = texture(p, face, STUDS, studs.tile)
		t.Transparency = studs.transparency
	end
	p.Parent = parent
	return p
end

-- A floor from z0 to z1 (z0 > z1), x0 to x1, its top at y = 0, cut into CHUNK-long parts.
local function floor(parent, name, x0, x1, z0, z1)
	local z = z0
	while z > z1 + 1e-6 do
		local nextZ = math.max(z - CHUNK, z1)
		box(name, parent, x0 - SEAM, FLOOR_BOTTOM, z + SEAM, x1 + SEAM, 0, nextZ - SEAM, TOP, GROUND_STUDS)
		z = nextZ
	end
end

-- A straight wall and its cap from (x0, z0) to (x1, z1), cut into CHUNK-long parts along z.
local function wall(parent, x0, x1, z0, z1)
	local hi, lo = math.max(z0, z1), math.min(z0, z1)
	local z = hi
	while z > lo + 1e-6 do
		local nextZ = math.max(z - CHUNK, lo)
		box("Wall", parent, x0, FLOOR_BOTTOM, z, x1, WALL_HEIGHT - 1, nextZ, ALL, WALL_STUDS)
		box("Cap", parent, math.min(x0, x1) - LIP, WALL_HEIGHT - 1, z + LIP, math.max(x0, x1) + LIP, WALL_HEIGHT, nextZ - LIP, ALL, WALL_STUDS)
		z = nextZ
	end
end

-- The checkered line across the course at z = 0 (and its copy at the finish).
local function startLine(parent, w)
	local model = Instance.new("Model")
	model.Name = "StartLine"
	local SQUARE = 2
	local n = math.floor(2 * w / SQUARE)
	for row, z in { -1, -3 } do
		for i = 0, n - 1 do
			local square = Instance.new("Part")
			square.Name = "Square"
			square.Anchored = true
			square.CanCollide = false
			square.CanQuery = false
			square.CanTouch = false
			square.Material = Enum.Material.SmoothPlastic
			square.Size = Vector3.new(SQUARE, 0.2, SQUARE)
			square.CFrame = CFrame.new(-w + SQUARE / 2 + i * SQUARE, 0.1, z)
			square.Color = if (i + row) % 2 == 0 then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(35, 35, 40)
			square.Parent = model
		end
	end
	model.Parent = parent
	return model
end

function Map.build()
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Model")
	world.Name = "World"
	local ground = folder("Ground", world)
	local walls = folder("Walls", world)
	folder("Obstacles", world)
	folder("Nests", world)
	folder("Decor", world)

	local W = Config.CourseHalfWidth
	local HW, depth = Config.HomeHalfWidth, Config.HomeDepth
	local finishZ = -Config.CourseLength + Config.FinishFromEnd

	-- the base: grass, walled on its back and sides, and its front either side of the course
	floor(ground, "Ground", -HW, HW, depth, 0)
	wall(walls, -HW - WALL_THICK, -HW, depth + WALL_THICK, -WALL_THICK)
	wall(walls, HW, HW + WALL_THICK, depth + WALL_THICK, -WALL_THICK)
	wall(walls, -HW, HW, depth + WALL_THICK, depth)
	wall(walls, -HW, -W - WALL_THICK, 0, -WALL_THICK)
	wall(walls, W + WALL_THICK, HW, 0, -WALL_THICK)

	-- the course: each biome's stretch, its own floor and walls (WorldColors paints a part by
	-- the biome its middle is in, so no part crosses a biome line)
	for i, biome in Config.Biomes do
		local z0 = WorldColors.biomeStart(i)
		local z1 = math.max(z0 - biome.Length, finishZ)
		if z0 <= finishZ then
			break
		end
		floor(ground, "Ground", -W, W, z0, z1)
		wall(walls, -W - WALL_THICK, -W, z0, z1)
		wall(walls, W, W + WALL_THICK, z0, z1)
	end

	local start = startLine(world, W)
	local finish = start:Clone()
	finish.Name = "FinishLine"
	finish:PivotTo(CFrame.new(0, 0, finishZ + 2) * start:GetPivot())
	finish.Parent = world

	-- the spawn: an invisible point in the base, you land on the floor under it
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(Config.StarterSpot.X, 0.5, Config.StarterSpot.Z)
	spawn.Transparency = 1
	spawn.CanCollide, spawn.CanQuery, spawn.CanTouch = false, false, false
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = world

	-- (whole, so a client that waits for World finds everything in it)
	world.Parent = workspace
	return world
end

return Map
