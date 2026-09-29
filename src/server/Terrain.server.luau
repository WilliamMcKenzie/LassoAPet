-- Studded terraced hills around the map, built after World.server.
-- The home base and the horse preview sit in a flat valley; the ground steps up
-- in wide grass terraces to a plateau level with the canyon wall tops, so the
-- stampede run reads as a canyon cut into the hills. A few block trees sit on
-- the terraces. Terrace parts join World.Ground, so the live GroundA / GroundB
-- colour attributes repaint them too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end

local hw, hd, cw = Config.HomeHalfWidth, Config.HomeDepth, Config.CourseHalfWidth
local WALL_OUTER = cw + 8 -- outer face of the canyon walls (World.server WALL_THICK = 8)

-- Terraces: distance out from the valley edge and top height. The last one is
-- the plateau, flush with the grass cap on the canyon walls (48 + 2).
-- Keep every edge on the 8-stud grid so the 4-stud checker lines up across parts.
local TIERS = {
	{ margin = 16, height = 8 },
	{ margin = 40, height = 20 },
	{ margin = 72, height = 34 },
	{ margin = 112, height = 50 },
}
-- Flat valleys the terraces rise around: {x0, x1, z0, z1}.
local VALLEYS = {
	{ -hw, hw, 0, hd }, -- home base
	{ -256, -hw, -56, 56 }, -- meadow for the horse preview at (-200, 0, 0)
}
local SLOT = { -WALL_OUTER, WALL_OUTER, -Config.CourseLength - 8, 0 } -- the canyon itself
-- The whole map, in two halves because a part is at most 2048 studs long.
local OUTER = { { -1000, 1000, -1480, 0 }, { -1000, 1000, 0, hd + 640 } }

local TRUNK = Color3.fromRGB(140, 92, 56)
local LEAVES = Color3.fromRGB(52, 150, 48)

-- Axis-aligned rectangle maths ---------------------------------------------

local function expand(r, by)
	return { r[1] - by, r[2] + by, r[3] - by, r[4] + by }
end

-- r minus hole, as up to four non-overlapping rectangles.
local function subtract(r, hole)
	if hole[1] >= r[2] or hole[2] <= r[1] or hole[3] >= r[4] or hole[4] <= r[3] then
		return { r }
	end
	local out = {}
	local function add(x0, x1, z0, z1)
		if x1 > x0 and z1 > z0 then
			table.insert(out, { x0, x1, z0, z1 })
		end
	end
	local mx0, mx1 = math.max(r[1], hole[1]), math.min(r[2], hole[2])
	add(r[1], mx0, r[3], r[4])
	add(mx1, r[2], r[3], r[4])
	add(mx0, mx1, r[3], hole[3])
	add(mx0, mx1, hole[4], r[4])
	return out
end

local function tierRects(tier)
	local holes = { SLOT }
	for _, valley in VALLEYS do
		table.insert(holes, expand(valley, tier.margin))
	end
	local rects = table.clone(OUTER)
	for _, hole in holes do
		local nextRects = {}
		for _, r in rects do
			for _, piece in subtract(r, hole) do
				table.insert(nextRects, piece)
			end
		end
		rects = nextRects
	end
	return rects
end

local tiers = {}
for i, tier in TIERS do
	tiers[i] = { height = tier.height, rects = tierRects(tier) }
end

local function heightAt(x, z)
	for i = #tiers, 1, -1 do
		for _, r in tiers[i].rects do
			if x > r[1] and x < r[2] and z > r[3] and z < r[4] then
				return tiers[i].height
			end
		end
	end
	return 0
end

-- Parts ----------------------------------------------------------------------

local CHECKER = "rbxassetid://84747779882944" -- same white checker mask as World.server
local STUDS = "rbxassetid://7447638591"

local function block(parent, size, position, color, name)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	for _, face in { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do
		part[face] = Enum.SurfaceType.Studs
	end
	part.BottomSurface = Enum.SurfaceType.Inlet
	part.Parent = parent
	return part
end

-- Checker and stud textures on the top face, matching the corridor floor.
local function checkerTop(part)
	local texture = Instance.new("Texture")
	texture.Name = "Checker"
	texture.Texture = CHECKER
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU = Config.Tile * 2
	texture.StudsPerTileV = Config.Tile * 2
	texture.Parent = part
	part.TopSurface = Enum.SurfaceType.Smooth
	local studs = Instance.new("Texture")
	studs.Texture = STUDS
	studs.Face = Enum.NormalId.Top
	studs.StudsPerTileU = 1
	studs.StudsPerTileV = 1
	studs.ZIndex = 2
	studs.Parent = part
end

for _, tier in tiers do
	for _, r in tier.rects do
		local size = Vector3.new(r[2] - r[1], tier.height, r[4] - r[3])
		local center = Vector3.new((r[1] + r[2]) / 2, tier.height / 2, (r[3] + r[4]) / 2)
		checkerTop(block(world.Ground, size, center, Config.GroundColors[1], "Terrace"))
	end
end

-- Block trees on the terraces near home, kept clear of terrace edges.
local scenery = Instance.new("Folder")
scenery.Name = "Scenery"
scenery.Parent = world

local function tree(position)
	local model = Instance.new("Model")
	model.Name = "Tree"
	block(model, Vector3.new(4, 10, 4), position + Vector3.new(0, 5, 0), TRUNK, "Trunk")
	block(model, Vector3.new(16, 6, 16), position + Vector3.new(0, 13, 0), LEAVES, "Leaves")
	block(model, Vector3.new(10, 4, 10), position + Vector3.new(0, 18, 0), LEAVES, "Leaves")
	model.Parent = scenery
end

local rng = Random.new(11)
for x = -288, 288, 48 do
	for z = -192, 432, 48 do
		local px, pz = x + rng:NextNumber(-12, 12), z + rng:NextNumber(-12, 12)
		local h = heightAt(px, pz)
		local clear = h > 0
			and heightAt(px - 10, pz) == h
			and heightAt(px + 10, pz) == h
			and heightAt(px, pz - 10) == h
			and heightAt(px, pz + 10) == h
		if clear and rng:NextNumber() < 0.25 then
			tree(Vector3.new(px, h, pz))
		end
	end
end

WorldColors.apply(world)
