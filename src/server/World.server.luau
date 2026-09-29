-- Builds the greybox world at server start: the home base, the stampede
-- corridor with its faint checkerboard, checkered canyon walls, obstacles and the egg nest.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local rng = Random.new(7)
local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace

local STONE = Color3.fromRGB(150, 150, 146)
local WOOD = Color3.fromRGB(124, 84, 54)
local WHITE = Color3.fromRGB(245, 245, 240)
local FENCE = Color3.fromRGB(150, 70, 44)

local function block(parent, size, position, color, name)
	local part = Instance.new("Part")
	part.Name = name or "Block"
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	-- Studs on every visible face, like classic Roblox bricks.
	for _, face in { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do
		part[face] = Enum.SurfaceType.Studs
	end
	part.BottomSurface = Enum.SurfaceType.Inlet
	part.Parent = parent
	return part
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or world
	return f
end

-- Ground: two close greens in a checkerboard, so it reads as flat grass with a faint grid.
local ground = folder("Ground")
local tile = Config.Tile
-- Checkerboards are one part each: the part is the first shade and a white/clear
-- checker mask texture tinted with the second shade paints the other squares.
local CHECKER = "rbxassetid://97195484523095"
local STUDS = "rbxassetid://7447638591" -- classic stud decal from the Creator Store
local function checker(part, face, color)
	local texture = Instance.new("Texture")
	texture.Name = "Checker"
	texture.Texture = CHECKER
	texture.Face = face
	texture.StudsPerTileU = tile * 2
	texture.StudsPerTileV = tile * 2
	texture.Color3 = color
	texture.Parent = part
	-- Studs as a texture layer above the checker, so every square is studded.
	part[face.Name .. "Surface"] = Enum.SurfaceType.Smooth
	local studs = Instance.new("Texture")
	studs.Texture = STUDS
	studs.Face = face
	studs.StudsPerTileU = 1
	studs.StudsPerTileV = 1
	studs.ZIndex = 2
	studs.Parent = part
end

local function groundRect(x0, x1, z0, z1)
	local slab = block(ground, Vector3.new(x1 - x0, 2, z1 - z0), Vector3.new((x0 + x1) / 2, -1, (z0 + z1) / 2), Config.GroundColors[1], "Ground")
	checker(slab, Enum.NormalId.Top, Config.GroundColors[2])
end
-- One wide plain under everything, so the edges of the map never show the void.
block(ground, Vector3.new(2048, 2, 2048), Vector3.new(0, -1.2, -Config.CourseLength / 2), Config.GroundColors[1], "Plain")
groundRect(-Config.CourseHalfWidth, Config.CourseHalfWidth, -Config.CourseLength, 0)
groundRect(-Config.HomeHalfWidth, Config.HomeHalfWidth, 0, Config.HomeDepth)

-- Walls: tall dirt walls with a faint brown checkerboard and a grass cap, so the
-- run reads as one long canyon and nothing outside it is visible.
local walls = folder("Walls")
local WALL_HEIGHT, WALL_THICK = 48, 8
local function checkerWall(center, length, alongX, facing)
	-- facing: the direction the inner face points (+1/-1 on the cross axis).
	local size = alongX and Vector3.new(length, WALL_HEIGHT, WALL_THICK) or Vector3.new(WALL_THICK, WALL_HEIGHT, length)
	local wall = block(walls, size, center + Vector3.new(0, WALL_HEIGHT / 2, 0), Config.WallColors[1], "Wall")
	local face
	if alongX then
		face = facing > 0 and Enum.NormalId.Back or Enum.NormalId.Front
	else
		face = facing > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	end
	checker(wall, face, Config.WallColors[2])
	local capSize = alongX and Vector3.new(length, 2, WALL_THICK + 2) or Vector3.new(WALL_THICK + 2, 2, length)
	local capShift = alongX and Vector3.new(0, 0, facing) or Vector3.new(facing, 0, 0)
	block(walls, capSize, center + capShift + Vector3.new(0, WALL_HEIGHT + 1, 0), Config.GroundColors[2], "Cap")
end
local halfW = Config.CourseHalfWidth + WALL_THICK / 2
checkerWall(Vector3.new(-halfW, 0, -Config.CourseLength / 2), Config.CourseLength, false, 1)
checkerWall(Vector3.new(halfW, 0, -Config.CourseLength / 2), Config.CourseLength, false, -1)
checkerWall(Vector3.new(0, 0, -Config.CourseLength - WALL_THICK / 2), Config.CourseHalfWidth * 2 + WALL_THICK * 2, true, 1)

local BUSH = Color3.fromRGB(88, 158, 52)
local STONE_LIGHT = Color3.fromRGB(205, 205, 200)

local function bush(parent, position)
	local model = Instance.new("Model")
	model.Name = "Bush"
	block(model, Vector3.new(8, 3, 6), position + Vector3.new(0, 1.5, 0), BUSH)
	block(model, Vector3.new(5, 2, 4), position + Vector3.new(-0.5, 4, 0.5), BUSH)
	model.Parent = parent
	return model
end

local function rock(parent, position)
	local model = Instance.new("Model")
	model.Name = "Rock"
	local w = rng:NextInteger(3, 4) * 2
	block(model, Vector3.new(w, 3, w - 2), position + Vector3.new(0, 1.5, 0), STONE)
	block(model, Vector3.new(w - 3, 2, w - 4), position + Vector3.new(0.5, 4, 0), STONE)
	model.Parent = parent
	return model
end

-- Small non-blocking decor along the wall feet: reeds and pebbles.
local decor = folder("Decor")
for z = -30, -Config.CourseLength + 20, -36 do
	local side = rng:NextNumber() < 0.5 and -1 or 1
	local x = side * (Config.CourseHalfWidth - rng:NextNumber(3, 10))
	if rng:NextNumber() < 0.5 then
		for i = 1, 3 do
			local h = rng:NextNumber(3, 6)
			local reed = block(decor, Vector3.new(0.4, h, 0.4), Vector3.new(x + i * 0.9 - 1.8, h / 2, z + rng:NextNumber(-1, 1)), BUSH, "Reed")
			reed.CanCollide = false
		end
	else
		for _ = 1, 3 do
			local pebble = block(decor, Vector3.new(1, 0.6, 1), Vector3.new(x + rng:NextNumber(-3, 3), 0.3, z + rng:NextNumber(-3, 3)), STONE_LIGHT, "Pebble")
			pebble.CanCollide = false
		end
	end
end

-- Obstacles inside the corridor. The ride reads their bounding boxes.
local obstacles = folder("Obstacles")
for z = -120, -Config.CourseLength + 40, -44 do
	if math.abs(z - Config.NestZ) > 50 and rng:NextNumber() < 0.75 then
		local x = rng:NextNumber(-Config.CourseHalfWidth + 8, Config.CourseHalfWidth - 8)
		local position = Vector3.new(x, 0, z + rng:NextNumber(-10, 10))
		if rng:NextNumber() < 0.5 then
			rock(obstacles, position)
		else
			bush(obstacles, position)
		end
	end
end

-- Home boundary line across the corridor mouth.
local home = folder("Home")
block(home, Vector3.new(Config.CourseHalfWidth * 2, 0.4, 2), Vector3.new(0, 0.2, 0), WHITE, "Boundary")

-- Fence around the home base, open toward the course.
local function fenceRun(from, to)
	local length = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) / 2, to)
	for _, y in { 1.6, 3 } do
		local rail = block(home, Vector3.new(0.6, 0.6, length), Vector3.zero, FENCE, "Rail")
		rail.CFrame = cf + Vector3.new(0, y, 0)
	end
	for i = 0, math.floor(length / 8) do
		local p = from + (to - from).Unit * math.min(i * 8, length)
		block(home, Vector3.new(1, 4, 1), p + Vector3.new(0, 2, 0), FENCE, "Post")
	end
end
local hw, hd, cw = Config.HomeHalfWidth, Config.HomeDepth, Config.CourseHalfWidth
fenceRun(Vector3.new(-hw, 0, 0), Vector3.new(-cw, 0, 0))
fenceRun(Vector3.new(cw, 0, 0), Vector3.new(hw, 0, 0))
fenceRun(Vector3.new(-hw, 0, 0), Vector3.new(-hw, 0, hd))
fenceRun(Vector3.new(hw, 0, 0), Vector3.new(hw, 0, hd))
fenceRun(Vector3.new(-hw, 0, hd), Vector3.new(hw, 0, hd))

-- Greybox pen: pet slots, cash collector, lasso upgrade.
local pen = folder("Pen", home)
for i = 0, 5 do
	local x = -50 + (i % 3) * 20
	local z = 100 + math.floor(i / 3) * 24
	local slot = block(pen, Vector3.new(16, 0.6, 16), Vector3.new(x, 0.3, z), Config.PlotColors[1], "PetSlot")
	checker(slot, Enum.NormalId.Top, Config.PlotColors[2])
end
block(pen, Vector3.new(8, 3, 8), Vector3.new(40, 1.5, 100), Color3.fromRGB(170, 170, 170), "CashCollector")
block(pen, Vector3.new(8, 3, 8), Vector3.new(40, 1.5, 124), Color3.fromRGB(170, 170, 170), "LassoUpgrade")

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 0.5, 90)
spawn.Color = WHITE
spawn.TopSurface = Enum.SurfaceType.Studs
spawn.Parent = home

-- Egg nest.
local nest = Instance.new("Model")
nest.Name = "Nest"
for i = 0, 7 do
	local angle = i / 8 * math.pi * 2
	local part = block(nest, Vector3.new(2, 1.2, 3), Vector3.zero, WOOD, "Twig")
	part.CFrame = CFrame.new(0, 0.6, Config.NestZ) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, 3)
end
block(nest, Vector3.new(6, 0.4, 6), Vector3.new(0, 0.2, Config.NestZ), Color3.fromRGB(214, 190, 120), "Straw")
local egg = Instance.new("Part")
egg.Name = "Egg"
egg.Anchored = true
egg.CanCollide = false
egg.Size = Vector3.new(2.6, 3.2, 2.6)
egg.Position = Vector3.new(0, 2, Config.NestZ)
egg.Color = Color3.fromRGB(255, 244, 214)
local mesh = Instance.new("SpecialMesh")
mesh.MeshType = Enum.MeshType.Sphere
mesh.Parent = egg
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 226, 150)
glow.Range = 14
glow.Brightness = 2
glow.Parent = egg
egg.Parent = nest
nest.Parent = world

-- Bright, cloudless kid-friendly sky.
for _, child in Lighting:GetChildren() do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
		child:Destroy()
	end
end
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if clouds then
	clouds:Destroy()
end
local sky = Instance.new("Sky")
sky.CelestialBodiesShown = false
sky.StarCount = 0
-- Plain gradient skybox generated for this game (deep blue overhead, lighter at the horizon).
local SKY_SIDE = "rbxassetid://101714504952971"
for _, face in { "Bk", "Ft", "Lf", "Rt" } do
	sky["Skybox" .. face] = SKY_SIDE
end
sky.SkyboxUp = "rbxassetid://73730341040940"
sky.SkyboxDn = "rbxassetid://98351643334543"
sky.Parent = Lighting
require(ReplicatedStorage.Shared.WorldColors).watch(world)
world:SetAttribute("Ready", true)
