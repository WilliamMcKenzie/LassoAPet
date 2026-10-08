-- The course as a funnel (QM, Oct 8): run in Studio's command bar (Edit, not Play) on
-- the place. Each side wall becomes one straight line angled out from the start
-- line; the ground, obstacles and nests spread out to fill the width at their z.
--
--   MODE = "apply": funnel the course (re-running is fine: it puts everything back
--                   first, then funnels it with the numbers below)
--   MODE = "undo":  put everything back as it was
--
-- Keep START, RATE and MAX the same as Config.CourseHalfWidth, CourseWidening and
-- CourseMaxHalfWidth (WorldColors.halfWidth). Every moved part keeps its original
-- CFrame/Size in "FunnelCF"/"FunnelSize" attributes (models "FunnelPivot"), and the
-- floor laid under the widened ground is World.Funnel. After a World push from the
-- repo (src/world/World.rbxmx is the straight course), run this again.
--
-- How x maps at z: inside the start line's half width it's stretched (x * width /
-- START), past it (the walls, things built on them) it's moved out by the same as
-- the edge. Ground patches have both edges mapped and snapped to the 8-stud cells
-- (Shared/Ground's grid; the 4-stud checker keeps its parity), so the pixel art
-- widens with the course; World.Funnel's floor, a little lower, shows in any seam.

local MODE = "apply"
local START, RATE, MAX = 56, 0.005, 137
-- Each biome's obstacles and nests grow with its beasts (QM, Oct 8): its far edge's z
-- and Config.Biomes[i].AnimalSize, the obstacles and nests scaled by that ^ GROW.
local BIOMES = { { -760, 1 }, { -3040, 1.35 }, { -8512, 1.8 }, { -16192, 2.6 } }
local GROW = 0.8
local function grownAt(z)
	for _, b in BIOMES do
		if z > b[1] then
			return b[2] ^ GROW
		end
	end
	return BIOMES[#BIOMES][2] ^ GROW
end
local CELL = 8
local STRIP = 40 -- studs of z per piece of World.Funnel's floor

local world = workspace.World
local function halfWidth(z)
	return math.min(START + RATE * math.max(-z, 0), MAX)
end
local function mapX(x, z)
	local h = halfWidth(z)
	if math.abs(x) <= START then
		return x * h / START
	end
	return x + math.sign(x) * (h - START)
end
local function snap(x)
	return math.floor(x / CELL + 0.5) * CELL
end

-- Put everything back.
local function restore(inst)
	if inst:IsA("BasePart") then
		local cf, size = inst:GetAttribute("FunnelCF"), inst:GetAttribute("FunnelSize")
		if cf then
			inst.Size, inst.CFrame = size, cf
			inst:SetAttribute("FunnelCF", nil)
			inst:SetAttribute("FunnelSize", nil)
		end
	elseif inst:IsA("Model") then
		local scale = inst:GetAttribute("FunnelScale")
		if scale then
			inst:ScaleTo(scale)
			inst:SetAttribute("FunnelScale", nil)
		end
		local pivot = inst:GetAttribute("FunnelPivot")
		if pivot then
			inst:PivotTo(pivot)
			inst:SetAttribute("FunnelPivot", nil)
		end
	end
end
for _, name in { "Ground", "Walls", "Obstacles", "Nests" } do
	for _, inst in world[name]:GetChildren() do
		restore(inst)
	end
end
if world:FindFirstChild("Funnel") then
	world.Funnel:Destroy()
end
if MODE == "undo" then
	return "undone"
end

local function keep(part)
	part:SetAttribute("FunnelCF", part.CFrame)
	part:SetAttribute("FunnelSize", part.Size)
end
local counts = { ground = 0, walls = 0, moved = 0, floor = 0 }

-- Ground: flat patches widen, anything standing on it moves.
local edgeParts = {} -- ground parts that reached the old edge (World.Funnel copies their look)
for _, part in world.Ground:GetChildren() do
	if part:IsA("BasePart") and part.Position.Z < 0 then
		local cf, size = part.CFrame, part.Size
		local z = cf.Position.Z
		keep(part)
		if size.Y <= 3 and math.abs(cf.RightVector.X) > 0.999 then
			local l = snap(mapX(cf.X - size.X / 2, z))
			local r = snap(mapX(cf.X + size.X / 2, z))
			if r - l < CELL then
				r = l + CELL
			end
			part.Size = Vector3.new(r - l, size.Y, size.Z)
			part.CFrame = cf + Vector3.new((l + r) / 2 - cf.X, 0, 0)
			if cf.X + size.X / 2 >= START - 0.1 and math.abs(cf.Y + size.Y / 2) < 0.01 then
				table.insert(edgeParts, part)
			end
		else
			part.CFrame = cf + Vector3.new(mapX(cf.X, z) - cf.X, 0, 0)
		end
		counts.ground += 1
	end
end

-- Walls: the side walls (and their caps) along one straight angled line each, and
-- the far end's wall across stretched to the width there.
for _, part in world.Walls:GetChildren() do
	if part:IsA("BasePart") then
		local cf, size = part.CFrame, part.Size
		local near, far = cf.Z + size.Z / 2, cf.Z - size.Z / 2
		local x = math.abs(cf.X)
		if near <= 0.5 and x > 50 and x < 70 and size.Z > size.X then
			keep(part)
			local side, off = math.sign(cf.X), x - START
			local a = Vector3.new(side * (halfWidth(near) + off), cf.Y, near)
			local b = Vector3.new(side * (halfWidth(far) + off), cf.Y, far)
			part.Size = Vector3.new(size.X, size.Y, (a - b).Magnitude)
			part.CFrame = CFrame.lookAt((a + b) / 2, b)
			counts.walls += 1
		elseif x < 1 and cf.Z < -100 and size.X > size.Z then
			keep(part)
			part.Size = Vector3.new(2 * (halfWidth(cf.Z) + 8), size.Y, size.Z)
			counts.walls += 1
		end
	end
end

-- Obstacles: moved out with the width, the same size.
for _, name in { "Obstacles" } do
	for _, inst in world[name]:GetChildren() do
		local pivot = if inst:IsA("Model") then inst:GetPivot() elseif inst:IsA("BasePart") then inst.CFrame else nil
		if pivot and pivot.Z < 0 then
			local dx = mapX(pivot.X, pivot.Z) - pivot.X
			if inst:IsA("Model") then
				inst:SetAttribute("FunnelPivot", pivot)
				inst:PivotTo(pivot + Vector3.new(dx, 0, 0))
				local grow = grownAt(pivot.Z)
				if grow ~= 1 then
					inst:SetAttribute("FunnelScale", inst:GetScale())
					local at = inst:GetPivot()
					inst:ScaleTo(inst:GetScale() * grow)
					inst:PivotTo(at + Vector3.new(0, at.Y * (grow - 1), 0)) -- (grown from the floor under it, not its middle)
				end
			else
				keep(inst)
				inst.CFrame = pivot + Vector3.new(dx, 0, 0)
			end
			counts.moved += 1
		end
	end
end

-- Nests: out by the walls (QM, Oct 8: too near the middle), NEST_IN studs in from
-- the wall on the side they were on (alternating for those dead centre). Anything
-- in the way there swaps over to where the nest would have been.
local NEST_IN, NEST_CLEAR = 12, 9
local alternate = 1
for _, nest in world.Nests:GetChildren() do
	local pivot = if nest:IsA("Model") then nest:GetPivot() else nil
	if pivot and pivot.Z < 0 then
		local side = math.sign(pivot.X)
		if math.abs(pivot.X) < 1 then
			side, alternate = alternate, -alternate
		end
		local x = side * (halfWidth(pivot.Z) - NEST_IN)
		local was = mapX(pivot.X, pivot.Z)
		for _, inst in world.Obstacles:GetChildren() do
			local at = if inst:IsA("Model") then inst:GetPivot() elseif inst:IsA("BasePart") then inst.CFrame else nil
			if at and math.abs(at.Z - pivot.Z) < NEST_CLEAR and math.abs(at.X - x) < NEST_CLEAR then
				local dx = was - x
				if inst:IsA("Model") then
					inst:PivotTo(at + Vector3.new(dx, 0, 0)) -- (its FunnelPivot still holds where it began)
				else
					inst.CFrame = at + Vector3.new(dx, 0, 0)
				end
			end
		end
		nest:SetAttribute("FunnelPivot", pivot)
		nest:PivotTo(pivot + Vector3.new(x - pivot.X, 0, 0))
		local grow = grownAt(pivot.Z)
		if grow ~= 1 then
			nest:SetAttribute("FunnelScale", nest:GetScale())
			local at = nest:GetPivot()
			nest:ScaleTo(nest:GetScale() * grow)
			nest:PivotTo(at + Vector3.new(0, at.Y * (grow - 1), 0))
		end
		counts.moved += 1
	end
end

-- World.Funnel: a floor a little under the ground, wall to wall, so a seam between
-- widened patches shows ground, not sky. Each strip copies the look (colour,
-- material, textures) of the edge patch nearest it; WorldColors repaints it like
-- the ground ("Ground").
local folder = Instance.new("Folder")
folder.Name = "Funnel"
local last = 0
for _, part in world.Ground:GetChildren() do
	if part:IsA("BasePart") then
		last = math.min(last, part.Position.Z - part.Size.Z / 2)
	end
end
for z0 = 0, last + 0.5, -STRIP do
	local z1 = math.max(z0 - STRIP, last)
	local zc = (z0 + z1) / 2
	local best, bestD = nil, math.huge
	for _, p in edgeParts do
		local d = math.abs(p.Position.Z - zc)
		if d < bestD then
			best, bestD = p, d
		end
	end
	local half = math.ceil(halfWidth(z1) / CELL) * CELL
	local strip = Instance.new("Part")
	strip.Name = if best then best.Name else "Ground"
	strip.Anchored = true
	strip.CanCollide = false
	strip.CanQuery = false
	strip.CanTouch = false
	strip.Size = Vector3.new(2 * half, 2, z0 - z1)
	strip.CFrame = CFrame.new(0, -1.2, zc) -- top 0.2 under the ground's
	if best then
		strip.Color, strip.Material = best.Color, best.Material
		strip.TopSurface = best.TopSurface
		for _, t in best:GetChildren() do
			if t:IsA("Texture") then
				local copy = t:Clone()
				if copy.Name == "Checker" then
					-- (its checker starts from the strip's low-x, low-z corner, as Ground's do)
					local odd = (math.floor(-half / 4 + 0.5) + math.floor(z1 / 4 + 0.5)) % 2
					copy.OffsetStudsU = odd * copy.StudsPerTileU / 2
				end
				copy.Parent = strip
			end
		end
	end
	strip.Parent = folder
	counts.floor += 1
end
folder.Parent = world

return string.format("funnelled: %d ground, %d walls, %d obstacles/nests moved, %d floor strips", counts.ground, counts.walls, counts.moved, counts.floor)
