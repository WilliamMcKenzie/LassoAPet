-- Builds the endless Godlands round the camera (QM, Oct 3: "just keeps going
-- laying down one of those 4 tracks at random over and over"). Shared/Godlands
-- says which track goes where; this lays the ones near you, a few parts a frame,
-- and takes away the ones you've left behind. Each track brings its floor, its
-- walls and its terrain pieces. Only you see what's built here.
--
--   GodlandsStream.update(z)        -- each frame, with the camera's z
--   GodlandsStream.onPieces = function(list, added) -- the ride's crash checks:
--       list of { x, z, hx, hz, tier, center, parts } as they're built and taken away

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Godlands = require(ReplicatedStorage.Shared.Godlands)
local Tracks = require(ReplicatedStorage.Shared.GodlandsTracks)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Studs = require(ReplicatedStorage.Shared.Studs)

local CHECKER = "rbxassetid://84747779882944" -- the floor's 4-stud checker (every Ground part's "Checker")
local FLOOR_STUDS = "rbxassetid://7447638591"
local PIECE_STUDS, PIECE_STUD_TILE = "rbxassetid://7447638591", 0.5 -- tools/partlib.py STUD_IMAGE / STUD_TILE
local MIN_STUD_FACE = 0.75 -- thinner faces get no studs (tools/course_layout.py)
local STUD_FACES = { -- the faces that get studs, and the two size axes each spans
	{ Enum.NormalId.Right, "Y", "Z" },
	{ Enum.NormalId.Top, "X", "Z" },
	{ Enum.NormalId.Back, "X", "Y" },
	{ Enum.NormalId.Left, "Y", "Z" },
	{ Enum.NormalId.Front, "X", "Y" },
}
-- The checker texture tiles from one corner of a part's top face, so a part that
-- starts on an odd 4-stud tile gets its checker shifted to line up with the rest
-- of the floor. This is the corner it starts from: -1 = the low x / low z side.
-- (If the checker breaks along part edges in the Godlands, flip these.)
local ORIGIN_X, ORIGIN_Z = -1, -1
local AHEAD, BEHIND = 2, 1 -- tracks kept built in front of and behind the camera's
local PARTS_PER_FRAME = 250

local GodlandsStream = {}

local world = workspace:WaitForChild("World")
local folder = Instance.new("Folder")
folder.Name = "Godlands"
folder.Parent = workspace

local built = {} -- [k] = { folder, pieces, done }
local queue = {} -- tracks waiting to be built
local job -- { k, co }: the coroutine building one of them

-- The walls are copies of the other biomes' (with their checker), one per side.
local templates = {}
for _, part in world:WaitForChild("Walls"):GetChildren() do
	if part:IsA("BasePart") and math.abs(part.Position.X) > 50 and part.Size.Z > 50 then
		templates[part.Name .. (if part.Position.X > 0 then 1 else -1)] = part
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

local function block(name, size, cframe, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
	p.Size, p.CFrame = size, cframe
	p.Parent = parent
	return p
end

-- One floor part covering x0..x1, z1..z0 (z0 > z1), from bottom up to top.
local function floorPart(name, x0, x1, z0, z1, top, bottom, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
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
	local odd = (math.floor(cx / Tracks.Tile + 0.5) + math.floor(cz / Tracks.Tile + 0.5)) % 2
	texture(p, CHECKER, Tracks.Tile * 2, Enum.NormalId.Top, odd * Tracks.Tile, 1)
	texture(p, FLOOR_STUDS, 1, Enum.NormalId.Top, 0, 2)
	WorldColors.paintGround(world, p)
	p.Parent = parent
	return p
end

-- Greedy merge of a grid's tiles of one glyph into rectangles: { i0, j0, i1, j1 }, ends exclusive.
local function rects(rows, glyph)
	local nz, nx = #rows, #rows[1]
	local done = {}
	local function at(i, j)
		return not done[j * 64 + i] and string.sub(rows[j], i, i) == glyph
	end
	local out = {}
	for i = 1, nx do
		for j = 1, nz do
			if at(i, j) then
				local j1 = j
				while j1 <= nz and at(i, j1) do
					j1 += 1
				end
				local i1 = i + 1
				while i1 <= nx do
					local all = true
					for jj = j, j1 - 1 do
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
					for jj = j, j1 - 1 do
						done[jj * 64 + ii] = true
					end
				end
				table.insert(out, { i, j, i1, j1 })
			end
		end
	end
	return out
end

-- One terrain piece (Tracks.Kit) standing at (x, y, z), turned yaw degrees.
local function piece(name, x, y, z, yaw, parent)
	local kit = Tracks.Kit[name]
	local g = Godlands.pieceScale -- (grown with the Godlands' beasts, from the floor up)
	local model = Instance.new("Model")
	model.Name = name
	local at = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	local parts = {}
	for _, row in kit.Parts do
		local size = Vector3.new(row[2], row[3], row[4]) * g
		local cf = at * CFrame.new(row[5] * g, row[6] * g, row[7] * g, row[8], row[9], row[10], row[11], row[12], row[13], row[14], row[15], row[16])
		local p = block(row[1], size, cf, model)
		p.Color = Color3.fromRGB(row[17], row[18], row[19])
		p.Material = if row[1] == "Lava" then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if not row[20] and not (row[1] ~= "Lava" and Studs.apply(p, PIECE_STUD_TILE)) then
			for _, face in STUD_FACES do
				if math.min(size[face[2]], size[face[3]]) >= MIN_STUD_FACE then
					texture(p, PIECE_STUDS, PIECE_STUD_TILE, face[1])
				end
			end
		end
		table.insert(parts, { part = p, cframe = cf, transparency = 0 })
	end
	model.Parent = parent
	local hx = (kit.HalfX or kit.Radius * 0.8) * g -- the footprint the other biomes' pieces have (their "Base")
	local hz = (kit.HalfZ or kit.Radius * 0.8) * g
	if kit.HalfX and math.abs(math.sin(math.rad(yaw))) > 0.7 then
		hx, hz = hz, hx -- a wall piece turned side on
	end
	return {
		x = x,
		z = z,
		hx = hx,
		hz = hz,
		tier = kit.Tier,
		center = Vector3.new(x, y + 2 * g, z),
		parts = parts,
	}
end

-- Builds track k, yielding every so often so a frame never stalls on it.
local function build(k)
	local entry = built[k]
	local track = Godlands.track(k)
	local rows = Tracks.Grids[track.Grid]
	local z0 = Godlands.segmentStart(k)
	local half, gh, tile = Godlands.halfWidth, Godlands.gridHalf, Tracks.Tile
	local count = 0
	local function tick(n)
		count += n
		if count >= PARTS_PER_FRAME then
			count = 0
			coroutine.yield()
		end
	end
	floorPart("Ground", -half, half, z0, z0 - Tracks.Length, 0, -2, entry.folder)
	for _, kind in { { "#", "Stone", Godlands.STONE_UP, -2 }, { "~", track.Liquid, Godlands.LIQUID_TOP, -Godlands.LIQUID_TOP } } do
		for _, r in rects(rows, kind[1]) do
			local x0, x1 = Godlands.worldX(-gh + (r[1] - 1) * tile), Godlands.worldX(-gh + (r[3] - 1) * tile)
			floorPart(kind[2], x0, x1, z0 - (r[2] - 1) * tile, z0 - (r[4] - 1) * tile, kind[3], kind[4], entry.folder)
			tick(1)
		end
	end
	local zc = z0 - Tracks.Length / 2
	for _, side in { -1, 1 } do
		for _, w in { { "Wall", Vector3.new(8, 48, Tracks.Length), Vector3.new(side * (half + 4), 24, zc) },
			{ "Cap", Vector3.new(10, 2, Tracks.Length - 1), Vector3.new(side * (half + 3), 49, zc + 0.5) } } do
			local template = templates[w[1] .. side]
			if template then
				local p = template:Clone()
				p.Size, p.CFrame = w[2], CFrame.new(w[3])
				WorldColors.paintWall(world, p)
				p.Parent = entry.folder
			end
		end
	end
	local pieces = {}
	for _, row in Tracks.Pieces[track.Grid] do
		table.insert(pieces, piece(row[1], row[2] * Godlands.widen, row[5], z0 + row[3], row[4], entry.folder))
		tick(#Tracks.Kit[row[1]].Parts)
	end
	entry.pieces = pieces
	entry.done = true
	if GodlandsStream.onPieces then
		GodlandsStream.onPieces(pieces, true)
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
		job = nil -- half built: its folder goes with the rest
	end
	if entry.pieces and GodlandsStream.onPieces then
		GodlandsStream.onPieces(entry.pieces, false)
	end
	entry.folder:Destroy()
end

function GodlandsStream.update(z)
	if not Godlands.start or not world:GetAttribute("GodlandsSeed") then
		return
	end
	-- The tracks to have: from BEHIND the camera's to AHEAD past it (just the first
	-- ones while the camera is still before the line).
	local here = Godlands.segmentAt(z) or (if z < Godlands.start + Tracks.Length then -1 else nil)
	local lo, hi = math.huge, -math.huge
	if here then
		lo, hi = math.max(here - BEHIND, 0), here + AHEAD
	end
	for k in built do
		if k < lo or k > hi then
			drop(k)
		end
	end
	for k = math.max(lo, 0), hi do
		if not built[k] then
			local f = Instance.new("Folder")
			f.Name = "Track" .. k
			f.Parent = folder
			built[k] = { folder = f }
			table.insert(queue, k)
		end
	end
	-- A slice of building this frame: the track under way, else the nearest waiting.
	if not job and #queue > 0 then
		table.sort(queue, function(a, c)
			return math.abs(a - (here or 0)) < math.abs(c - (here or 0))
		end)
		local k = table.remove(queue, 1)
		job = { k = k, co = coroutine.create(build) }
	end
	if job then
		local ok, err = coroutine.resume(job.co, job.k)
		if not ok then
			warn("[Godlands] building track " .. job.k .. " failed: " .. tostring(err))
		end
		if not ok or coroutine.status(job.co) == "dead" then
			job = nil
		end
	end
end

return GodlandsStream
