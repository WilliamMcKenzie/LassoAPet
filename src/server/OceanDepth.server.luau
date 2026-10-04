-- QM's experiment (Oct 4; Config.Biomes Ocean.Deep): the Ocean's sea floor sinks on a
-- slope as you ride, down to MaxDepth studs by FullAt of the way along, so by the
-- final lava-chasm stretch you swim near the surface over the deep blue.
--
-- Only how it looks moves: each floor part sinks (keeping its riding height in its
-- "RestTop" attribute, which Shared/Ground reads, so you, the animals, eggs and nests
-- stay at the usual height), the walls reach down to the new floor, and every
-- obstacle and nest gets a pillar of its own colour down to the floor (World.OceanDeep),
-- so they stand on something. Deep.Enabled = false leaves the map as it was.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local index
for i, biome in Config.Biomes do
	if biome.Name == "Ocean" then
		index = i
	end
end
local ocean = index and Config.Biomes[index]
local deep = ocean and ocean.Deep
if not deep or not deep.Enabled then
	return
end

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end

local START = WorldColors.biomeStart(index)
local LENGTH = ocean.Length
local END = START - LENGTH

-- How far the floor has sunk at z.
local function depthAt(z)
	local t = math.clamp((START - z) / (LENGTH * deep.FullAt), 0, 1)
	return deep.MaxDepth * t ^ deep.Curve
end

local function inOcean(z)
	return z <= START and z >= END
end

-- The floor: each part sinks by the depth at its middle (the floor's 240-stud bands
-- and its patches step down a little each).
for _, part in world.Ground:GetChildren() do
	if part:IsA("BasePart") and inOcean(part.Position.Z) then
		local d = depthAt(part.Position.Z)
		if d > 0.05 then
			part:SetAttribute("RestTop", part.Position.Y + part.Size.Y / 2)
			part.CFrame += Vector3.new(0, -d, 0)
		end
	end
end

-- The walls reach down to the floor below their deepest end.
for _, part in world.Walls:GetChildren() do
	if part:IsA("BasePart") and part.Size.Y > 10 then
		local near, far = part.Position.Z + part.Size.Z / 2, part.Position.Z - part.Size.Z / 2
		if inOcean(far) or inOcean(near) then
			local d = depthAt(math.max(far, END))
			if d > 0.05 then
				local bottom = part.Position.Y - part.Size.Y / 2
				local top = part.Position.Y + part.Size.Y / 2
				local newBottom = bottom - d
				part.Size = Vector3.new(part.Size.X, top - newBottom, part.Size.Z)
				part.CFrame = part.CFrame.Rotation + Vector3.new(part.Position.X, (top + newBottom) / 2, part.Position.Z)
			end
		end
	end
end

local pillars = Instance.new("Folder")
pillars.Name = "OceanDeep"

-- A pillar under a model, down from y = 0 to the sunk floor, the colour of its
-- lowest visible part.
local function pillarUnder(model, color, material)
	local cf, size = model:GetBoundingBox()
	local d = depthAt(cf.Position.Z)
	if d < 1 then
		return
	end
	local w = math.clamp(math.min(size.X, size.Z) * 0.7, 2, 14)
	local part = Instance.new("Part")
	part.Name = "Pillar"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Size = Vector3.new(w, d, w)
	part.CFrame = CFrame.new(cf.Position.X, -d / 2, cf.Position.Z)
	part.Color = color
	part.Material = material
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = pillars
end

local function lowestPart(model)
	local best
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and (not best or p.Position.Y < best.Position.Y) then
			best = p
		end
	end
	return best
end

for _, folderName in { "Obstacles", "Nests" } do
	local folder = world:FindFirstChild(folderName)
	for _, model in folder and folder:GetChildren() or {} do
		if model:IsA("Model") and model.Name ~= "EventNest" then
			local cf = model:GetBoundingBox()
			if inOcean(cf.Position.Z) then
				local base = lowestPart(model)
				if base then
					pillarUnder(model, base.Color, if base.Material == Enum.Material.Neon then Enum.Material.SmoothPlastic else base.Material)
				end
			end
		end
	end
end

-- Where the Ocean meets the Godlands' raised floor: a cliff face down to the deep,
-- so there's no gap under the Godlands' first track.
local cliff = Instance.new("Part")
cliff.Name = "Cliff"
cliff.Anchored, cliff.CanCollide, cliff.CanQuery, cliff.CanTouch = true, false, false, false
local d = depthAt(END)
cliff.Size = Vector3.new(Config.CourseHalfWidth * 2 + 16, d, 4)
cliff.CFrame = CFrame.new(0, -1 - d / 2, END - 2)
local last = ocean.Depths and ocean.Depths[#ocean.Depths]
cliff.Color = if last and last.Wall then last.Wall[1] else ocean.WallColors[1] -- (the deep end's rock)
cliff.Parent = pillars

pillars.Parent = world
