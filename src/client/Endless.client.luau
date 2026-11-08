-- The endless course past the Ocean Trench (QM, Nov 6; Config.Endless, Shared/Endless): builds the
-- generated terrain near the camera, a 64-stud chunk at a time, ahead of you first, and drops
-- what's fallen far behind. Only this client's copy: every client builds the same course from
-- the seed. Its props in the corridor go in World.Obstacles (this client's own), where the ride
-- smashes and swerves round them as it does the map's (Client/Ride).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Endless = require(Shared.Endless)
local StudStyle = require(Shared.StudStyle)
if not Endless.On then
	return
end

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end
-- (no finish line any more: the course goes on; a place baked before this still has one)
local finishLine = world:FindFirstChild("FinishLine")
if finishLine then
	finishLine:Destroy()
end
local obstacleFolder = world:WaitForChild("Obstacles")

local camera = workspace.CurrentCamera
local root = Instance.new("Folder")
root.Name = "Endless"
root.Parent = workspace

local CELL, CHUNK, START = Endless.CELL, Endless.CHUNK, Endless.START
local AHEAD, BEHIND = 760, 260 -- studs of course built in front of the camera and behind it (the fog ends by 500)
local BUDGET = 0.004 -- seconds of building a frame
-- (Roblox's own Baseplate texture, grid + checker, QM Nov 8: a black overlay, tinted nothing)
local CHECKER, STUDS = "rbxassetid://6372755229", "rbxassetid://7447638591"
-- (walls' sides: the same look with 2x2-stud squares, a grid line between studs, QM Nov 8;
-- assets/terrain/Baseplate2x2.png, black, tiles every 8 studs: walls' studs are 2 studs, StudStyle TileScale)
local WALL_CHECKER, WALL_TILE = "rbxassetid://119843983644581", 8
local FLOOR_BOTTOM, SEAM, CAP_H, CAP_LIP = -2, 0.03, 3, 1
local TOP = { Enum.NormalId.Top }
local ALL = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

-- (a chunk takes several frames: the work yields once it's had BUDGET of one)
local sliceStart = os.clock()
local function pace()
	if os.clock() - sliceStart > BUDGET then
		task.wait()
		sliceStart = os.clock()
	end
end

local colors -- (workspace.WorldColors: the live colours, Shared/WorldColors)
local function color(key)
	colors = colors or workspace:FindFirstChild("WorldColors")
	local c = colors and colors:GetAttribute(key)
	return if typeof(c) == "Color3" then c else Config.WorldColors[key] or Color3.new(1, 0, 1)
end

-- (as Server/Map's: lined up with the world grid, so every part's checker is one board)
local function texture(part, face, image, tile, key, ground)
	local t = Instance.new("Texture")
	if image == CHECKER and face ~= Enum.NormalId.Top then
		image, tile = WALL_CHECKER, WALL_TILE
	end
	t.Name = if image == STUDS then "Studs" else "Checker"
	t.Face = face
	t.Texture = image
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	t.ZIndex = if image == STUDS then 2 else 1
	if image == CHECKER or image == WALL_CHECKER then
		t.Color3, t.Transparency = Color3.new(0, 0, 0), Config.BaseplateTransparency
	elseif key then
		t:SetAttribute("ColorKey", key)
		t.Color3 = color(key)
	end
	local corner = part.Position - part.Size / 2
	if face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		local far = part.Position + part.Size / 2
		local half = if image == STUDS then 0 else tile / 2
		t.OffsetStudsU, t.OffsetStudsV = (half - far.X) % tile, (half - far.Z) % tile
	elseif face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		t.OffsetStudsU, t.OffsetStudsV = corner.X % tile, corner.Y % tile
	else
		t.OffsetStudsU, t.OffsetStudsV = corner.Z % tile, corner.Y % tile
	end
	if image == STUDS then
		StudStyle.apply(t, ground)
	end
	t.Parent = part
	return t
end

local function newPart(parent, key, size, cframe)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide, p.CanTouch = false, false
	p.Material = Enum.Material.SmoothPlastic
	p.MaterialVariant = "Matte"
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p:SetAttribute("ColorKey", key)
	p.Color = color(key)
	p.Parent = parent
	return p
end

-- an axis-aligned box, its checker and studs on `faces`
local function box(parent, x0, y0, z0, x1, y1, z1, key, faces, ground)
	local p = newPart(parent, key, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
	p.CanCollide = true
	for _, face in faces do
		if Config.WorldColors[key .. "Checker"] then
			texture(p, face, CHECKER, 8, key .. "Checker", ground)
		end
		texture(p, face, STUDS, 1, nil, ground)
	end
	return p
end

-- ---- the floor and walls ---------------------------------------------------------------------

local function floorsAndWalls(parent, c)
	local j0 = c * (CHUNK // CELL)
	local floors, walls = Endless.rows(j0, j0 + CHUNK // CELL - 1, pace)
	for _, r in floors do
		pace()
		local t = Endless.TILES[r[5]]
		local x0, x1, z0, z1 = r[1], r[2], r[3], r[4]
		if t.liquid then
			-- a see-through surface you wade through, its bed below (as the map's water)
			local bed = t.top - Config.Map.LiquidSink
			box(parent, x0, FLOOR_BOTTOM - 2, z0, x1, bed, z1, t.key, TOP, true)
			local p = box(parent, x0, bed, z0, x1, t.top - 0.2, z1, t.key, {}, true)
			p.CanCollide = false
			p.Material = Enum.Material.Glass
			p.MaterialVariant = ""
			p.Transparency = 0.35
			texture(p, Enum.NormalId.Top, CHECKER, 8, t.key .. "Checker", true)
		else
			local p = box(parent, x0, FLOOR_BOTTOM, z0, x1, t.top, z1, t.key, if t.top > 0 then ALL else TOP, true)
			-- (a hair bigger all round, so neighbours overlap and no crack shows: as the map's)
			p.Size += Vector3.new(2 * SEAM, 0, 2 * SEAM)
			for _, tex in p:GetChildren() do
				if tex:IsA("Texture") and tex.Face == Enum.NormalId.Top then
					tex.OffsetStudsU = (tex.OffsetStudsU - SEAM) % tex.StudsPerTileU
					tex.OffsetStudsV = (tex.OffsetStudsV - SEAM) % tex.StudsPerTileV
				end
			end
		end
	end
	for _, r in walls do
		pace()
		local x0, x1, z0, z1, key, top, cap, side = r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8]
		-- (its face toward the corridor, and its ends, where the next row's may be lower)
		local inner = if side > 0 then Enum.NormalId.Left else Enum.NormalId.Right
		box(parent, x0, FLOOR_BOTTOM, z0, x1, top - CAP_H, z1, key, { inner, Enum.NormalId.Front, Enum.NormalId.Back }, false)
		local lipIn = if side > 0 then -CAP_LIP else CAP_LIP
		local cx0 = if side > 0 then x0 + lipIn else x0
		local cx1 = if side > 0 then x1 else x1 + lipIn
		box(parent, cx0, top - CAP_H, z0, cx1, top, z1, cap, TOP, false)
	end
end

-- ---- props ----------------------------------------------------------------------------------

local UP = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder's axis is its X: this stands it up
local function cyl(parent, key, height, dia, at)
	local p = newPart(parent, key, Vector3.new(height, dia, dia), at * UP)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent, key, dia, at)
	local p = newPart(parent, key, Vector3.new(dia, dia, dia), at)
	p.Shape = Enum.PartType.Ball
	return p
end
local function neon(p)
	p.Material = Enum.Material.Neon
	p.MaterialVariant = ""
	return p
end

-- a mushroom: a stem and a stepped cap (World 2's living mushrooms' look), spots on top
local function mushroom(m, s, at, capKey, stemKey, glow, r)
	local h = 14 * s
	cyl(m, stemKey, h, 3 * s, at * CFrame.new(0, h / 2, 0))
	cyl(m, capKey, 2.5 * s, 14 * s, at * CFrame.new(0, h + 1.25 * s, 0))
	cyl(m, capKey, 2 * s, 9 * s, at * CFrame.new(0, h + 3.5 * s, 0))
	for k = 1, 3 do
		local a = r:NextNumber(0, 2 * math.pi)
		local d = r:NextNumber(0.8, 3.2) * s
		local spot = newPart(m, stemKey, Vector3.new(1.6 * s, 0.6 * s, 1.6 * s), at * CFrame.new(math.cos(a) * d, h + 4.6 * s, math.sin(a) * d))
		if glow then
			spot.Color = color(glow)
			spot:SetAttribute("ColorKey", glow)
			neon(spot)
		end
	end
end

-- a cluster of crystal prisms leaning out from the middle, one glowing at its heart
local function crystals(m, s, at, key, r, count)
	for k = 1, count do
		local a = (k / count) * 2 * math.pi + r:NextNumber(-0.4, 0.4)
		local lean = if k == 1 then 0 else r:NextNumber(0.2, 0.55)
		local w = r:NextNumber(1.6, 2.8) * s * (if k == 1 then 1.3 else 1)
		local h = r:NextNumber(7, 15) * s * (if k == 1 then 1.25 else 1)
		local base = at * CFrame.new(if k == 1 then 0 else math.cos(a) * 1.5 * s, 0, if k == 1 then 0 else math.sin(a) * 1.5 * s)
		local tilt = CFrame.Angles(0, a, 0) * CFrame.Angles(lean, 0, 0) * CFrame.Angles(0, math.pi / 4, 0)
		local p = newPart(m, key, Vector3.new(w, h, w), base * tilt * CFrame.new(0, h / 2 - 0.5, 0))
		if k == 1 then
			p:SetAttribute("ColorKey", "CavernGlow")
			p.Color = color("CavernGlow")
			neon(p).Transparency = 0.15
		end
	end
end

-- a tall stone with glowing rune bars down both faces
local function runestone(m, s, at, height, r)
	local h = height * s
	local tilt = at * CFrame.Angles(r:NextNumber(-0.08, 0.08), 0, r:NextNumber(-0.08, 0.08))
	newPart(m, "CrimsonStone", Vector3.new(4.5 * s, h, 3 * s), tilt * CFrame.new(0, h / 2 - 0.5, 0))
	for _, face in { -1, 1 } do
		for k = 1, math.max(2, math.floor(h / (3 * s))) do
			local y = 1.5 * s + (k - 1) * 3 * s
			if y > h - 1.5 * s then
				break
			end
			local w = r:NextNumber(1, 3) * s
			neon(newPart(m, "CrimsonRune", Vector3.new(w, 0.6 * s, 0.3), tilt * CFrame.new(r:NextNumber(-0.8, 0.8) * s, y, face * 1.55 * s)))
		end
	end
end

-- Each prop kind: builds into model m at `at` (on the ground, turned), scale s; its footprint's half size.
local BUILD = {
	Column = function(m, s, at)
		local h = 18 * s
		newPart(m, "MarbleStone", Vector3.new(7 * s, 2 * s, 7 * s), at * CFrame.new(0, s, 0))
		cyl(m, "MarbleStone", h, 4.5 * s, at * CFrame.new(0, 2 * s + h / 2, 0))
		newPart(m, "MarbleStone", Vector3.new(7 * s, 1.6 * s, 7 * s), at * CFrame.new(0, 2.8 * s + h, 0))
		return 3.5 * s
	end,
	BrokenColumn = function(m, s, at, r)
		local h = r:NextNumber(5, 11) * s
		newPart(m, "MarbleStone", Vector3.new(7 * s, 2 * s, 7 * s), at * CFrame.new(0, s, 0))
		cyl(m, "MarbleStone", h, 4.5 * s, at * CFrame.new(0, 2 * s + h / 2, 0))
		newPart(m, "MarbleStone", Vector3.new(3 * s, 2 * s, 2.5 * s), at * CFrame.new(5 * s, s, 2 * s) * CFrame.Angles(0, 0.6, 0.3))
		return 3.5 * s
	end,
	Drum = function(m, s, at)
		local p = newPart(m, "MarbleStone", Vector3.new(8 * s, 4.5 * s, 4.5 * s), at * CFrame.new(0, 2.1 * s, 0))
		p.Shape = Enum.PartType.Cylinder
		return 4 * s
	end,
	MarbleBlock = function(m, s, at, r)
		newPart(m, "MarbleStone", Vector3.new(5 * s, 4 * s, 5 * s), at * CFrame.new(0, 1.8 * s, 0) * CFrame.Angles(r:NextNumber(-0.15, 0.15), 0, r:NextNumber(-0.15, 0.15)))
		return 2.8 * s
	end,
	Bush = function(m, s, at, r)
		for k = 1, 3 do
			local d = r:NextNumber(3.5, 5.5) * s
			ball(m, "MarbleBush", d, at * CFrame.new(r:NextNumber(-2, 2) * s, d * 0.35, r:NextNumber(-2, 2) * s))
		end
		return 3 * s
	end,
	GiantShroom = function(m, s, at, r)
		mushroom(m, 1.15 * s, at, "CrimsonShroom", "CrimsonShroomStem", nil, r)
		return 2.5 * s
	end,
	Shroom = function(m, s, at, r)
		mushroom(m, 0.6 * s, at, "CrimsonShroom", "CrimsonShroomStem", nil, r)
		return 1.6 * s
	end,
	SmallShroom = function(m, s, at, r)
		mushroom(m, 0.3 * s, at, "CrimsonShroom", "CrimsonShroomStem", nil, r)
		return 1.2 * s
	end,
	Runestone = function(m, s, at, r)
		runestone(m, s, at, 13, r)
		return 2.5 * s
	end,
	ShortRunestone = function(m, s, at, r)
		runestone(m, s, at, 7, r)
		return 2.5 * s
	end,
	Tuft = function(m, s, at, r)
		for k = 1, 5 do
			local a = k / 5 * 2 * math.pi
			local h = r:NextNumber(2.5, 5) * s
			local p = Instance.new("WedgePart")
			p.Anchored, p.CanCollide, p.CanTouch = true, false, false
			p.Material, p.MaterialVariant = Enum.Material.SmoothPlastic, "Matte"
			p.Size = Vector3.new(0.8 * s, h, 2 * s)
			p.CFrame = at * CFrame.Angles(0, a, 0) * CFrame.new(0, h / 2, 1 * s) * CFrame.Angles(0.25, 0, 0)
			p:SetAttribute("ColorKey", "CrimsonPatch")
			p.Color = color("CrimsonPatch")
			p.Parent = m
		end
		return 2 * s
	end,
	Crystals = function(m, s, at, r)
		crystals(m, s, at, "CavernCrystal", r, 5)
		return 3 * s
	end,
	PinkCrystals = function(m, s, at, r)
		crystals(m, s, at, "CavernPink", r, 5)
		return 3 * s
	end,
	SmallCrystals = function(m, s, at, r)
		crystals(m, 0.5 * s, at, "CavernCrystal", r, 3)
		return 1.5 * s
	end,
	Stalagmite = function(m, s, at, r)
		local y = 0
		for k, w in { 5, 3.6, 2.2, 1 } do
			local h = (if k == 4 then 3 else 4) * s
			newPart(m, "CavernRock", Vector3.new(w * s, h, w * s), at * CFrame.new(0, y + h / 2, 0) * CFrame.Angles(0, r:NextNumber(0, 1.5), 0))
			y += h - 0.3 * s
		end
		return 2.5 * s
	end,
	CavernShroom = function(m, s, at, r)
		mushroom(m, 1.1 * s, at, "CavernShroom", "CavernShroomStem", "CavernGlow", r)
		return 2.5 * s
	end,
}

local function prop(parent, p)
	local build = BUILD[p.kind]
	if not build then
		return
	end
	local m = Instance.new("Model")
	m.Name = p.kind
	local at = CFrame.new(p.x, p.y, p.z) * CFrame.Angles(0, p.yaw, 0)
	local half = build(m, p.scale, at, Random.new(p.seed))
	if p.obstacle then
		-- its footprint, for the ride (Client/Ride reads the "Base" part)
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored, base.CanCollide, base.CanTouch, base.CanQuery = true, false, false, false
		base.Transparency = 1
		base.Size = Vector3.new(2 * half, 1, 2 * half)
		base.CFrame = CFrame.new(p.x, p.y + 0.5, p.z)
		base.Parent = m
		m:SetAttribute("Tier", p.tier)
		m.WorldPivot = CFrame.new(p.x, p.y, p.z)
		m.Parent = obstacleFolder
	else
		m.Parent = parent
	end
	return m
end

-- ---- the set pieces -------------------------------------------------------------------------

local LANDMARK = {
	-- a marble arch over the corridor, its columns on the ledges
	MarbleMeadow = function(m, l)
		local reach = l.w + 10
		for _, side in { -1, 1 } do
			local at = CFrame.new(side * reach, 0, l.z)
			newPart(m, "MarbleStone", Vector3.new(14, 6, 14), at * CFrame.new(0, 3, 0))
			cyl(m, "MarbleStone", 64, 10, at * CFrame.new(0, 38, 0))
			newPart(m, "MarbleStone", Vector3.new(14, 4, 14), at * CFrame.new(0, 72, 0))
		end
		newPart(m, "MarbleStone", Vector3.new(2 * reach + 14, 8, 12), CFrame.new(0, 78, l.z))
		newPart(m, "MarbleStone", Vector3.new(2 * reach + 18, 2, 15), CFrame.new(0, 83, l.z))
		newPart(m, "MarbleCap", Vector3.new(2 * reach + 18, 1.5, 15.6), CFrame.new(0, 84.6, l.z))
	end,
	-- two giant runestones on the ledges and a lintel stone hanging between them
	CrimsonLands = function(m, l)
		local r = Random.new(l.seed)
		local reach = l.w + 10
		for _, side in { -1, 1 } do
			local at = CFrame.new(side * reach, 0, l.z) * CFrame.Angles(0, 0, side * 0.05)
			newPart(m, "CrimsonStone", Vector3.new(14, 90, 9), at * CFrame.new(0, 44, 0))
			for k = 1, 9 do
				neon(newPart(m, "CrimsonRune", Vector3.new(r:NextNumber(3, 8), 1.6, 0.4), at * CFrame.new(r:NextNumber(-2.5, 2.5), 10 + k * 8, -4.6)))
			end
		end
		newPart(m, "CrimsonStone", Vector3.new(2 * reach + 20, 8, 10), CFrame.new(0, 96, l.z))
		neon(newPart(m, "CrimsonRune", Vector3.new(2 * reach, 1, 0.4), CFrame.new(0, 94, l.z - 5.1)))
	end,
	-- a rock bridge across the cavern, stalactites hanging off it and crystals on top
	CrystalCavern = function(m, l)
		local r = Random.new(l.seed)
		local reach = l.w + 34
		newPart(m, "CavernRock", Vector3.new(2 * reach, 10, 24), CFrame.new(0, 70, l.z))
		newPart(m, "CavernWall", Vector3.new(2 * reach - 10, 6, 18), CFrame.new(0, 62, l.z))
		for k = 1, math.floor(reach / 14) do
			local x = r:NextNumber(-reach + 10, reach - 10)
			local y = 59
			for _, w in { 6, 4, 2.2 } do
				local h = r:NextNumber(4, 8)
				newPart(m, "CavernRock", Vector3.new(w, h, w), CFrame.new(x, y - h / 2, l.z + r:NextNumber(-5, 5)) * CFrame.Angles(0, r:NextNumber(0, 1.5), 0))
				y -= h - 0.5
			end
		end
		for k = 1, 4 do
			crystals(m, r:NextNumber(1, 1.6), CFrame.new(r:NextNumber(-reach + 20, reach - 20), 75, l.z + r:NextNumber(-6, 6)), if k % 2 == 0 then "CavernPink" else "CavernCrystal", r, 4)
		end
	end,
}

-- ---- chunks -----------------------------------------------------------------------------

local built = {} -- [chunk] = { folder, obstacles }
local LAST = math.floor(START / CHUNK) - 1 -- the first endless chunk (the course runs toward -z)

local function build(c)
	local f = Instance.new("Folder")
	f.Name = "Chunk" .. c
	local entry = { folder = f, obstacles = {} }
	floorsAndWalls(f, c)
	local z0, z1 = c * CHUNK + CHUNK, c * CHUNK
	for _, p in Endless.props(z0, z1) do
		local m = prop(f, p)
		if m and p.obstacle then
			table.insert(entry.obstacles, m)
		end
		pace()
	end
	for _, l in Endless.landmarks(z0, z1) do
		local m = Instance.new("Model")
		m.Name = "Landmark"
		LANDMARK[l.kind](m, l)
		m.Parent = f
	end
	f.Parent = root
	built[c] = entry
end

local function drop(c)
	local entry = built[c]
	built[c] = nil
	for _, m in entry.obstacles do
		m:Destroy()
	end
	entry.folder:Destroy()
end

-- The chunks wanted now: from `low` (ahead) to `high` (behind), and the one the camera's in.
local function wanted()
	local camZ = camera.CFrame.Position.Z
	return math.floor((camZ - AHEAD) / CHUNK), math.min(math.floor((camZ + BEHIND) / CHUNK), LAST), math.min(math.floor(camZ / CHUNK), LAST)
end

-- the nearest missing chunk, ahead of the camera before behind it, or nil
local function nextChunk()
	local low, high, here = wanted()
	if low > LAST then
		return nil
	end
	for c = here, low, -1 do
		if not built[c] then
			return c
		end
	end
	for c = here + 1, high do
		if not built[c] then
			return c
		end
	end
	return nil
end

RunService.Heartbeat:Connect(function()
	local low, high = wanted()
	for c in built do
		if c < low - 2 or c > high + 2 then
			drop(c)
		end
	end
end)

task.spawn(function()
	while true do
		local c = nextChunk()
		if c then
			sliceStart = os.clock()
			build(c)
		end
		task.wait()
	end
end)
