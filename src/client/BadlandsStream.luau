-- Builds the Badlands round the camera (Shared/Badlands): its floor a stretch at a
-- time, its angled walls, and the lava geysers on them. Only you see what's
-- built here.
--
-- The geysers go off on a loop from the server clock, so everyone sees the same
-- ones fire: a moment of the mouth swelling and spitting (the warning), then a
-- jet of lava arcs out across the corridor for a couple of seconds. Riding into
-- a jet is a crash (Ride.client asks hit()).
--
--   BadlandsStream.update(z)       -- each frame, with the camera's z
--   BadlandsStream.hit(x, z)       -- whether a geyser's jet is on that spot right now

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badlands = require(ReplicatedStorage.Shared.Badlands)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local Map = Badlands.map

local CHECKER = "rbxassetid://84747779882944" -- the floor's 4-stud checker (as in GodlandsStream)
local FLOOR_STUDS = "rbxassetid://7447638591"
local STUDS, STUD_TILE = "rbxassetid://7447638591", 0.5
local MIN_STUD_FACE = 0.75
local STUD_FACES = {
	{ Enum.NormalId.Right, "Y", "Z" },
	{ Enum.NormalId.Top, "X", "Z" },
	{ Enum.NormalId.Back, "X", "Y" },
	{ Enum.NormalId.Left, "Y", "Z" },
	{ Enum.NormalId.Front, "X", "Y" },
}
local ORIGIN_X, ORIGIN_Z = -1, -1 -- the checker's corner (GodlandsStream's; flip both there and here if it breaks)
local CHUNK = 480 -- studs of floor built at a time
local AHEAD, BEHIND = 2, 1 -- chunks kept built in front of and behind the camera's
local PARTS_PER_FRAME = 250
local BAND = 16 -- the floor slab under the sand is cut into bands this long, each as wide as the walls there

-- Geysers (guesses for QM to tune; seconds and studs)
local GEYSER = {
	PERIOD = 7, -- one go every this many seconds
	STAGGER = 2.3, -- each geyser down the wall goes off this much after the one before
	WARN = 1.2, -- the mouth swells and spits first
	SPRAY = 2.2, -- the jet is out this long
	GROW = 0.35, -- seconds for the jet to reach across
	REACH = 72, -- how far it goes before it lands
	MOUTH = 8, -- studs out from the wall to the mouth
	HEIGHT = 6, -- the mouth's height
	HALF_WIDTH = 3, -- half the jet's width for crashes
	NEAR = 420, -- jets exist only for geysers this close to the camera
	STONE = { Color3.fromRGB(78, 38, 29), Color3.fromRGB(88, 43, 32) },
	RIM = Color3.fromRGB(117, 56, 38),
	LAVA = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) }, -- the Godlands' lava (QM)
}

local BadlandsStream = {}

local world = workspace:WaitForChild("World")
local folder = Instance.new("Folder")
folder.Name = "Badlands"
folder.Parent = workspace

local built = {} -- [k] = { folder, done }
local queue = {}
local job
local fixed -- the walls and geyser vents, built once

local templates = {}
for _, part in world:WaitForChild("Walls"):GetChildren() do
	if part:IsA("BasePart") and math.abs(part.Position.X) > 50 and part.Size.Z > 50 then
		templates[part.Name] = templates[part.Name] or part
	end
end

local function texture(part, image, studs, face, offset, zIndex)
	local t = Instance.new("Texture")
	t.Name = if image == CHECKER then "Checker" elseif studs == 1 then "Texture" else "Studs"
	t.Texture = image
	t.Face = face
	t.StudsPerTileU, t.StudsPerTileV = studs, studs
	t.OffsetStudsU = offset or 0
	t.ZIndex = zIndex or 1
	t.Parent = part
end

local function floorPart(name, x0, x1, z0, z1, top, bottom, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Inlet
	for _, side in { "Front", "Back", "Left", "Right" } do
		p[side .. "Surface"] = Enum.SurfaceType.Studs
	end
	if name == "Lava" then
		p.Material = Enum.Material.Neon
	end
	p.Size = Vector3.new(x1 - x0, top - bottom, z0 - z1)
	p.CFrame = CFrame.new((x0 + x1) / 2, (top + bottom) / 2, (z0 + z1) / 2)
	local cx = if ORIGIN_X < 0 then x0 else x1
	local cz = if ORIGIN_Z < 0 then z1 else z0
	local odd = (math.floor(cx / Map.Tile + 0.5) + math.floor(cz / Map.Tile + 0.5)) % 2
	texture(p, CHECKER, Map.Tile * 2, Enum.NormalId.Top, odd * Map.Tile, 1)
	texture(p, FLOOR_STUDS, 1, Enum.NormalId.Top, 0, 2)
	WorldColors.paintGround(world, p)
	p.Parent = parent
	return p
end

local function block(name, size, cframe, color, parent, glow)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.CastShadow = not glow
	p.Size, p.CFrame = size, cframe
	p.Color = color
	p.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if not glow then
		for _, face in STUD_FACES do
			if math.min(size[face[2]], size[face[3]]) >= MIN_STUD_FACE then
				texture(p, STUDS, STUD_TILE, face[1])
			end
		end
	end
	p.Parent = parent
	return p
end

-- Greedy merge of a glyph's tiles in rows j0..j1 into rectangles { i0, j0, i1, j1 } (ends exclusive).
local function rects(j0, j1, glyph)
	local rows = Map.Grid
	local nx = #rows[1]
	local done = {}
	local function at(i, j)
		return not done[j * 256 + i] and string.sub(rows[j], i, i) == glyph
	end
	local out = {}
	for i = 1, nx do
		for j = j0, j1 do
			if at(i, j) then
				local e = j
				while e <= j1 and at(i, e) do
					e += 1
				end
				local i1 = i + 1
				while i1 <= nx do
					local all = true
					for jj = j, e - 1 do
						if not at(i1, jj) then
							all = false
							break
						end
					end
					if not all then
						break
					end
					i1 += 1
				end
				for ii = i, i1 - 1 do
					for jj = j, e - 1 do
						done[jj * 256 + ii] = true
					end
				end
				table.insert(out, { i, j, i1, e })
			end
		end
	end
	return out
end

-- Floor chunk k: the stretch CHUNK * k .. CHUNK * (k + 1) studs past the line.
local function build(k)
	local entry = built[k]
	local tile, half = Map.Tile, Map.HalfWidth
	local count = 0
	local function tick(n)
		count += n
		if count >= PARTS_PER_FRAME then
			count = 0
			coroutine.yield()
		end
	end
	local a0 = k * CHUNK
	local a1 = math.min(a0 + CHUNK, Map.Length)
	-- The sand: a slab per band, as wide as the walls there (plus what's under them).
	for a = a0, a1 - 1, BAND do
		local lo, hi = math.huge, -math.huge
		for _, s in { a, a + BAND / 2, math.min(a + BAND, a1) - 0.01 } do
			local l, r = Badlands.edgesAt(Badlands.start - s - 0.005)
			if l then
				lo, hi = math.min(lo, l), math.max(hi, r)
			end
		end
		lo = math.max(math.floor((lo - 8) / tile) * tile, -half)
		hi = math.min(math.ceil((hi + 8) / tile) * tile, half)
		floorPart("Ground", lo, hi, Badlands.start - a, Badlands.start - math.min(a + BAND, a1), 0, -2, entry.folder)
		tick(1)
	end
	local j0, j1 = a0 // tile + 1, math.min(a1 // tile, #Map.Grid)
	for _, kind in { { "#", "Stone", Badlands.STONE_UP, -2 }, { "~", "Lava", Badlands.LAVA_TOP, -Badlands.LAVA_TOP } } do
		for _, r in rects(j0, j1, kind[1]) do
			local x0, x1 = -half + (r[1] - 1) * tile, -half + (r[3] - 1) * tile
			floorPart(kind[2], x0, x1, Badlands.start - (r[2] - 1) * tile, Badlands.start - (r[4] - 1) * tile, kind[3], kind[4], entry.folder)
			tick(1)
		end
	end
	entry.done = true
end

-- The walls: one straight run per Map.Walls segment a side, turned to its angle,
-- with a post at each bend so the joins close. Copies of the other biomes' walls.
local function wallRun(name, ax, az, bx, bz, out, size, y, parent)
	local template = templates[name]
	if not template then
		return
	end
	local d = Vector3.new(bx - ax, 0, bz - az)
	local length = d.Magnitude
	if length < 0.5 then
		return
	end
	local n = Vector3.new(-d.Z, 0, d.X).Unit
	if n.X * out < 0 then
		n = -n
	end
	local mid = Vector3.new((ax + bx) / 2, y, (az + bz) / 2) + n * (size.X / 2)
	local p = template:Clone()
	p.Size = Vector3.new(size.X, size.Y, length + (if name == "Cap" then 0 else 0.2))
	p.CFrame = CFrame.lookAt(mid, mid + d)
	WorldColors.paintWall(world, p)
	p.Parent = parent
end

local function buildFixed()
	fixed = Instance.new("Folder")
	fixed.Name = "Fixed"
	fixed.Parent = folder
	local walls = Map.Walls
	for side, out in { -1, 1 } do
		local col = side + 1 -- left x is Walls[i][2], right x [3]
		for i = 2, #walls do
			local a, b = walls[i - 1], walls[i]
			local az, bz = Badlands.start - a[1], Badlands.start - b[1]
			wallRun("Wall", a[col], az, b[col], bz, out, Vector3.new(8, 48, 0), 24, fixed)
			wallRun("Cap", a[col], az, b[col], bz, out, Vector3.new(10, 2, 0), 49, fixed)
			if i < #walls then -- a post closes the bend
				local wall = templates.Wall
				if wall then
					local post = wall:Clone()
					post.Size = Vector3.new(8, 48, 8)
					post.CFrame = CFrame.new(b[col] + out * 4, 24, bz)
					WorldColors.paintWall(world, post)
					post.Parent = fixed
				end
			end
		end
	end
	-- The geyser vents: a stepped red stone cone out of the wall, a rim, a glowing mouth.
	for i, g in Badlands.geysers do
		local model = Instance.new("Model")
		model.Name = "Geyser"
		local cf, y = g.cframe, GEYSER.HEIGHT
		local x = 0
		for k, s in { { 10, 3 }, { 8, 2.5 }, { 6, 2 } } do
			block("Vent", Vector3.new(s[2], s[1], s[1]), cf * CFrame.new(x + s[2] / 2, y, 0), GEYSER.STONE[k % 2 + 1], model)
			x += s[2]
		end
		local m = GEYSER.MOUTH
		for _, r in { { 2.5, 0, Vector3.new(1, 1, 6) }, { -2.5, 0, Vector3.new(1, 1, 6) }, { 0, 2.5, Vector3.new(1, 4, 1) }, { 0, -2.5, Vector3.new(1, 4, 1) } } do
			block("Rim", r[3], cf * CFrame.new(m, y + r[1], r[2]), GEYSER.RIM, model)
		end
		g.mouth = block("Mouth", Vector3.new(0.6, 4, 4), cf * CFrame.new(m - 0.2, y, 0), GEYSER.LAVA[2], model, true)
		block("Drip", Vector3.new(0.6, y - 1, 1.2), cf * CFrame.new(0.4, (y - 1) / 2, 1.5), GEYSER.LAVA[1], model, true)
		block("Drip", Vector3.new(0.6, y - 3, 1), cf * CFrame.new(0.4, (y - 3) / 2, -2), GEYSER.LAVA[1], model, true)
		g.index = i
		model.Parent = fixed
	end
end

-- The jet's height t studs out from the mouth: up a little, then down to the floor.
local function arc(t)
	return GEYSER.HEIGHT + 0.25 * t - 0.0045 * t * t
end

-- Where geyser g is in its loop now: "idle", "warn" (with how far through) or "spray" (with how far out the jet is, 0..1).
local function stateOf(g, now)
	local t = (now + (g.index or 0) * GEYSER.STAGGER) % GEYSER.PERIOD
	if t < GEYSER.WARN then
		return "warn", t / GEYSER.WARN
	elseif t < GEYSER.WARN + GEYSER.SPRAY then
		return "spray", math.clamp((t - GEYSER.WARN) / GEYSER.GROW, 0, 1)
	end
	return "idle", 0
end

local function makeJet(g)
	local jet = {}
	for i = 0, math.floor(GEYSER.REACH / 3) do
		local t = i * 3
		local h = arc(t)
		if h < 0.5 then
			break
		end
		local w = 3.6 + 0.04 * t
		local p = block("Jet", Vector3.new(3.2, w, w), g.cframe * CFrame.new(GEYSER.MOUTH + t + 1.5, h, math.sin(t * 0.35) * 0.6), GEYSER.LAVA[i % 2 + 1], folder, true)
		p.Transparency = 1
		table.insert(jet, { part = p, t = t })
	end
	local splash = block("Splash", Vector3.new(8, 0.4, 8), g.cframe * CFrame.new(GEYSER.MOUTH + GEYSER.REACH, 0.25, 0), GEYSER.LAVA[2], folder, true)
	splash.Transparency = 1
	g.jet, g.splash = jet, splash
end

local function dropJet(g)
	for _, s in g.jet do
		s.part:Destroy()
	end
	g.splash:Destroy()
	g.jet, g.splash = nil, nil
end

local function animate(z)
	local now = workspace:GetServerTimeNow()
	for _, g in Badlands.geysers do
		local near = math.abs(g.cframe.Position.Z - z) < GEYSER.NEAR
		if near and not g.jet then
			makeJet(g)
		elseif not near and g.jet then
			dropJet(g)
		end
		if g.jet then
			local state, f = stateOf(g, now)
			local reach = if state == "spray" then f * GEYSER.REACH else 0
			for _, s in g.jet do
				s.part.Transparency = if s.t <= reach then 0 else 1
			end
			g.splash.Transparency = if state == "spray" and f >= 1 then 0 else 1
			-- the warning: the mouth swells and flickers
			local swell = if state == "warn" then 1 + 0.35 * f + 0.1 * math.sin(now * 40) else 1
			g.mouth.Size = Vector3.new(0.6, 4 * swell, 4 * swell)
		end
	end
end

local function drop(k)
	local entry = built[k]
	built[k] = nil
	local i = table.find(queue, k)
	if i then
		table.remove(queue, i)
	end
	if job and job.k == k then
		job = nil
	end
	entry.folder:Destroy()
end

function BadlandsStream.update(z)
	if not Badlands.start then
		return
	end
	local along = Badlands.start - z
	local inRange = along > -CHUNK and along < Map.Length + CHUNK
	if inRange and not fixed then
		buildFixed()
	end
	local here = math.floor(along / CHUNK)
	local last = math.ceil(Map.Length / CHUNK) - 1
	local lo, hi = math.max(here - BEHIND, 0), math.min(here + AHEAD, last)
	if not inRange then
		lo, hi = math.huge, -math.huge
	end
	for k in built do
		if k < lo or k > hi then
			drop(k)
		end
	end
	for k = lo, hi do
		if not built[k] then
			local f = Instance.new("Folder")
			f.Name = "Chunk" .. k
			f.Parent = folder
			built[k] = { folder = f }
			table.insert(queue, k)
		end
	end
	if not job and #queue > 0 then
		table.sort(queue, function(a, c)
			return math.abs(a - here) < math.abs(c - here)
		end)
		local k = table.remove(queue, 1)
		job = { k = k, co = coroutine.create(build) }
	end
	if job then
		local ok, err = coroutine.resume(job.co, job.k)
		if not ok then
			warn("[Badlands] building chunk " .. job.k .. " failed: " .. tostring(err))
		end
		if not ok or coroutine.status(job.co) == "dead" then
			job = nil
		end
	end
	if fixed then
		animate(z)
	end
end

-- Whether a geyser's jet is on (x, z) right now.
function BadlandsStream.hit(x, z)
	if not Badlands.contains(z) then
		return false
	end
	local now = workspace:GetServerTimeNow()
	for _, g in Badlands.geysers do
		if math.abs(g.cframe.Position.Z - z) < GEYSER.REACH + GEYSER.MOUTH then
			local state, f = stateOf(g, now)
			if state == "spray" then
				local p = g.cframe:PointToObjectSpace(Vector3.new(x, 0, z))
				if p.X > GEYSER.MOUTH and p.X < GEYSER.MOUTH + f * GEYSER.REACH and math.abs(p.Z) < GEYSER.HALF_WIDTH then
					return true
				end
			end
		end
	end
	return false
end

return BadlandsStream
