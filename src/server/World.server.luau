-- Builds the greybox world at server start: the home base, the stampede
-- corridor with its faint checkerboard, studded hills, obstacles and the egg nest.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local rng = Random.new(7)
local world = Instance.new("Folder")
world.Name = "World"
world.Parent = workspace

local STONE = Color3.fromRGB(150, 150, 146)
local WOOD = Color3.fromRGB(124, 84, 54)
local LEAF = Color3.fromRGB(76, 150, 62)
local WHITE = Color3.fromRGB(245, 245, 240)

local function block(parent, size, position, color, name)
	local part = Instance.new("Part")
	part.Name = name or "Block"
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Studs
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
local function groundRect(x0, x1, z0, z1)
	for x = x0, x1 - tile, tile do
		for z = z1 - tile, z0, -tile do
			local shade = (math.floor(x / tile) + math.floor(z / tile)) % 2 + 1
			local part = block(ground, Vector3.new(tile, 2, tile), Vector3.new(x + tile / 2, -1, z + tile / 2), Config.GroundColors[shade], "Tile")
			part.CanQuery = true
		end
	end
end
-- One wide plain under everything, so the edges of the map never show the void.
block(ground, Vector3.new(2048, 2, 2048), Vector3.new(0, -1.05, -Config.CourseLength / 2), Color3.fromRGB(88, 150, 64), "Plain")
groundRect(-Config.CourseHalfWidth, Config.CourseHalfWidth, -Config.CourseLength, 0)
groundRect(-Config.HomeHalfWidth, Config.HomeHalfWidth, 0, Config.HomeDepth)

-- Hills: stepped studded blocks along both sides of the corridor.
local hills = folder("Hills")
local HILL_SHADES = { Color3.fromRGB(92, 158, 66), Color3.fromRGB(84, 146, 60), Color3.fromRGB(76, 134, 56) }
local SEGMENT = 32
for side = -1, 1, 2 do
	for z = -Config.CourseLength, -SEGMENT, SEGMENT do
		local x = Config.CourseHalfWidth
		for step = 1, 3 do
			local width = 16 + step * 4
			local height = step * 4 + math.floor(math.noise(z / 90, step, side) * 6 + 0.5) * 2
			height = math.max(height, step * 3)
			block(hills, Vector3.new(width, height, SEGMENT), Vector3.new(side * (x + width / 2), height / 2, z + SEGMENT / 2), HILL_SHADES[step])
			x += width
		end
	end
end

local function tree(parent, position, scale)
	local model = Instance.new("Model")
	model.Name = "Tree"
	block(model, Vector3.new(2, 6, 2) * scale, position + Vector3.new(0, 3 * scale, 0), WOOD)
	block(model, Vector3.new(8, 4, 8) * scale, position + Vector3.new(0, 7 * scale, 0), LEAF)
	block(model, Vector3.new(5, 3, 5) * scale, position + Vector3.new(0, 10.5 * scale, 0), LEAF)
	model.Parent = parent
	return model
end

local function rock(parent, position)
	local model = Instance.new("Model")
	model.Name = "Rock"
	local w = rng:NextInteger(3, 5) * 2
	block(model, Vector3.new(w, 4, w - 2), position + Vector3.new(0, 2, 0), STONE)
	block(model, Vector3.new(w - 3, 3, w - 4), position + Vector3.new(0.5, 5.5, 0), STONE)
	model.Parent = parent
	return model
end

-- Scenery on the hills.
local scenery = folder("Scenery")
for z = -Config.CourseLength + 20, -40, 60 do
	for side = -1, 1, 2 do
		if rng:NextNumber() < 0.7 then
			local x = side * (Config.CourseHalfWidth + rng:NextNumber(24, 46))
			local ray = workspace:Raycast(Vector3.new(x, 100, z), Vector3.new(0, -200, 0))
			tree(scenery, Vector3.new(x, ray and ray.Position.Y or 12, z), rng:NextNumber(1, 1.4))
		end
	end
end

-- Obstacles inside the corridor. The ride reads their bounding boxes.
local obstacles = folder("Obstacles")
for z = -120, -Config.CourseLength + 40, -44 do
	if math.abs(z - Config.NestZ) > 50 and rng:NextNumber() < 0.75 then
		local x = rng:NextNumber(-Config.CourseHalfWidth + 8, Config.CourseHalfWidth - 8)
		local position = Vector3.new(x, 0, z + rng:NextNumber(-10, 10))
		if rng:NextNumber() < 0.6 then
			rock(obstacles, position)
		else
			tree(obstacles, position, 1)
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
		local rail = block(home, Vector3.new(0.6, 0.6, length), Vector3.zero, WHITE, "Rail")
		rail.CFrame = cf + Vector3.new(0, y, 0)
	end
	for i = 0, math.floor(length / 8) do
		local p = from + (to - from).Unit * math.min(i * 8, length)
		block(home, Vector3.new(1, 4, 1), p + Vector3.new(0, 2, 0), WHITE, "Post")
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
	block(pen, Vector3.new(14, 0.6, 14), Vector3.new(x, 0.3, z), Color3.fromRGB(196, 170, 120), "PetSlot")
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

Lighting.ClockTime = 14
world:SetAttribute("Ready", true)
