-- Reads World 1's course out of the open Studio place (Edit mode) for the map editor
-- (tools/mapeditor; QM, Nov 6): tools/mapeditor/export.py runs it and writes maps/world1.map
-- and maps/world1.palette.json. MODE (set by export.py above this line) is "all" or "palette".
--
--   floor   World.Ground and World.Funnel parts south of the start line (z < 0), one cell
--           (4 studs) at a time: a tile is { key (the part's Name: Ground, Dirt, Lava...), top }
--   walls   World.Walls (Wall sides, Cap tops) and the Meadow's cliffs (World.Cliffs West/East)
--           become wall tiles { key (sides), cap, top }: any height, so they mix and match
--   objects World.Obstacles, Decor and Nests: each gets a MapId attribute so the editor's
--           moves come back to the same model; one of each kind is kept in
--           ServerStorage.MapTemplates for placing new ones
--   palette each biome's colours from Config (as WorldColors paints them in Play), its
--           border, and the objects' top-down outlines for drawing them
-- The base (z > 0), World.Barriers and World.Cliffs.Far are left out: the editor doesn't touch them.

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local MODE = MODE or "all"
local CELL, X0, Z0, COLS, ROWS = 4, -260, -21760, 130, 5440

local world = workspace:FindFirstChild("World")
assert(world, "no workspace.World")

-- fresh Config (it reads the borders as they are now)
local tmp = Instance.new("Folder")
tmp.Name = "MapExportTemp"
game:GetService("ReplicatedStorage").Shared:Clone().Parent = tmp
tmp.Parent = ServerStorage
local okConfig, Config = pcall(require, tmp.Shared.Config)
tmp:Destroy()
assert(okConfig, tostring(Config))

local function rgb(c)
	return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end
local function num(v)
	return math.round(v * 100) / 100
end

-- ---- palette --------------------------------------------------------------------------------
local palette = { saturation = Config.TerrainSaturation or 1, biomes = {}, borders = {} }
local edge = 0
for i, biome in Config.Biomes do
	local keys = { Ground = { rgb(biome.GroundColors[1]), rgb(biome.GroundColors[2]) }, Wall = { rgb(biome.WallColors[1]), rgb(biome.WallColors[2]) } }
	for name, pair in biome.Patches or {} do
		keys[name] = { rgb(pair[1]), rgb(pair[2]) }
	end
	local depths = nil
	if biome.Depths then
		depths = {}
		for _, stop in biome.Depths do
			local d = { at = stop.At, keys = {} }
			for name, pair in stop do
				if type(pair) == "table" and typeof(pair[1]) == "Color3" and typeof(pair[2]) == "Color3" then
					d.keys[name] = { rgb(pair[1]), rgb(pair[2]) }
				end
			end
			table.insert(depths, d)
		end
	end
	table.insert(palette.biomes, {
		name = biome.Name,
		prefix = if i == 1 then "" else biome.Name,
		keys = keys,
		cap = if biome.CapColor then rgb(biome.CapColor) else nil,
		depths = depths,
		start = edge,
	})
	if i > 1 then
		palette.borders[biome.Name] = edge
	end
	edge -= biome.Length
end
palette.borders.End = -Config.CourseLength + Config.FinishFromEnd
-- the colours the place has on World now (a test's live tuning), over Config's
palette.attributes = {}
for k, v in world:GetAttributes() do
	if typeof(v) == "Color3" then
		palette.attributes[k] = rgb(v)
	end
end

-- (the answer goes back in pieces: studio.py's chunked run sets OFFSET and CHUNK)
local function answer(t)
	local all = HttpService:JSONEncode(t)
	OFFSET, CHUNK = OFFSET or 0, CHUNK or #all
	return string.sub(all, OFFSET + 1, OFFSET + CHUNK) .. "\n" .. #all
end

if MODE == "palette" then
	return answer({ palette = palette })
end

-- ---- the grid --------------------------------------------------------------------------------
local tiles, tileIndex = {}, {}
local function tileFor(t)
	local key = (if t.wall then "W|" .. t.key .. "|" .. t.cap else "F|" .. t.key) .. "|" .. num(t.top) .. "|" .. (t.material or "") .. "|" .. tostring(t.nocollide or false)
	local i = tileIndex[key]
	if not i then
		table.insert(tiles, t)
		i = #tiles
		tileIndex[key] = i -- (export.py gives each its letter)
	end
	return i
end

local N = COLS * ROWS
local kind = table.create(N, 0)
local topAt = table.create(N, -math.huge)
local isWall = table.create(N, false)

local function cellRange(x0, z0, x1, z1)
	local c0 = math.max(0, math.floor((x0 - X0) / CELL + 0.5))
	local c1 = math.min(COLS, math.floor((x1 - X0) / CELL + 0.5))
	local r0 = math.max(0, math.floor((z0 - Z0) / CELL + 0.5))
	local r1 = math.min(ROWS, math.floor((z1 - Z0) / CELL + 0.5))
	return c0, c1, r0, r1
end

local function material(p)
	return if p.Material == Enum.Material.Plastic or p.Material == Enum.Material.SmoothPlastic then nil else p.Material.Name
end

-- floors (axis-aligned, on the 4-stud grid)
for _, folderName in { "Ground", "Funnel" } do
	for _, p in (world:FindFirstChild(folderName) and world[folderName]:GetChildren() or {}) do
		if p:IsA("BasePart") and p.Position.Z < 0 then
			local top = p.Position.Y + p.Size.Y / 2
			local t = tileFor({ key = p.Name, top = num(top), material = material(p), nocollide = if p.CanCollide then nil else true })
			local c0, c1, r0, r1 = cellRange(p.Position.X - p.Size.X / 2, p.Position.Z - p.Size.Z / 2, p.Position.X + p.Size.X / 2, p.Position.Z + p.Size.Z / 2)
			for r = r0, r1 - 1 do
				for c = c0, c1 - 1 do
					local i = r * COLS + c + 1
					if top > topAt[i] then
						kind[i], topAt[i] = t, top
					end
				end
			end
		end
	end
end

-- walls: sides first, then the caps on top of them (cells a side covers only)
local side, sideTop, cap, capTop = {}, {}, {}, {}
local function eachCell(p, f)
	local cf, s = p.CFrame, p.Size
	local lo, hi = Vector3.new(math.huge, 0, math.huge), Vector3.new(-math.huge, 0, -math.huge)
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			local w = cf:PointToWorldSpace(Vector3.new(dx * s.X / 2, 0, dz * s.Z / 2))
			lo = Vector3.new(math.min(lo.X, w.X), 0, math.min(lo.Z, w.Z))
			hi = Vector3.new(math.max(hi.X, w.X), 0, math.max(hi.Z, w.Z))
		end
	end
	local c0, c1, r0, r1 = cellRange(lo.X - CELL, lo.Z - CELL, hi.X + CELL, hi.Z + CELL)
	for r = r0, r1 - 1 do
		for c = c0, c1 - 1 do
			local centre = Vector3.new(X0 + (c + 0.5) * CELL, cf.Position.Y, Z0 + (r + 0.5) * CELL)
			local l = cf:PointToObjectSpace(centre)
			if math.abs(l.X) <= s.X / 2 + 0.01 and math.abs(l.Z) <= s.Z / 2 + 0.01 then
				f(r * COLS + c + 1)
			end
		end
	end
end
local sides, caps = {}, {}
for _, p in world.Walls:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z < 0 then
		table.insert(if p.Name == "Cap" then caps else sides, p)
	end
end
local cliffs = world:FindFirstChild("Cliffs")
for _, f in (if cliffs then { cliffs:FindFirstChild("West"), cliffs:FindFirstChild("East") } else {}) do
	for _, p in f:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(if p.Name == "Cliff" then sides else caps, p)
		end
	end
end
for _, p in sides do
	local top = p.Position.Y + p.Size.Y / 2 -- (walls aren't tipped over: their Y is up)
	eachCell(p, function(i)
		if top > (sideTop[i] or -math.huge) then
			side[i], sideTop[i] = p.Name, top
		end
	end)
end
for _, p in caps do
	local top = p.Position.Y + p.Size.Y / 2
	eachCell(p, function(i)
		if side[i] and top > (capTop[i] or -math.huge) then
			cap[i], capTop[i] = p.Name, top
		end
	end)
end
for i, key in side do
	local top = math.max(sideTop[i], capTop[i] or -math.huge)
	kind[i] = tileFor({ wall = true, key = key, cap = cap[i] or key, top = num(top) })
	topAt[i] = top
	isWall[i] = true
end

-- rows, run-length coded for the trip out: "tile:run,..." (tile 0 is nothing)
local rows = table.create(ROWS)
for r = 0, ROWS - 1 do
	local out, run, last = {}, 0, nil
	for c = 0, COLS - 1 do
		local k = kind[r * COLS + c + 1]
		if k == last then
			run += 1
		else
			if last then
				table.insert(out, last .. ":" .. run)
			end
			last, run = k, 1
		end
	end
	table.insert(out, last .. ":" .. run)
	rows[r + 1] = table.concat(out, ",")
end

local function floorAt(x, z)
	local c, r = math.floor((x - X0) / CELL), math.floor((z - Z0) / CELL)
	if c < 0 or r < 0 or c >= COLS or r >= ROWS then
		return 0
	end
	local t = topAt[r * COLS + c + 1]
	return if t == -math.huge then 0 else t
end

-- ---- objects ------------------------------------------------------------------------------------
local templates = ServerStorage:FindFirstChild("MapTemplates")
if not templates then
	templates = Instance.new("Folder")
	templates.Name = "MapTemplates"
	templates.Parent = ServerStorage
end
local used, n = {}, 0
for _, folderName in { "Obstacles", "Decor", "Nests" } do
	for _, m in (world:FindFirstChild(folderName) and world[folderName]:GetChildren() or {}) do
		local id = m:GetAttribute("MapId")
		if id then
			used[id] = true
			n = math.max(n, tonumber(string.match(id, "%d+")) or 0)
		end
	end
end
local function yawOf(cf)
	local look = cf.LookVector
	return math.deg(math.atan2(-look.X, -look.Z))
end
local objects, items = {}, {}
for _, folderName in { "Obstacles", "Decor", "Nests" } do
	local folder = world:FindFirstChild(folderName)
	local group = templates:FindFirstChild(folderName)
	if folder and not group then
		group = Instance.new("Folder")
		group.Name = folderName
		group.Parent = templates
	end
	for _, m in (folder and folder:GetChildren() or {}) do
		if (m:IsA("Model") or m:IsA("BasePart")) and m:GetPivot().Position.Z < 0 then
			local id = m:GetAttribute("MapId")
			if not id or used[id] == "taken" then
				n += 1
				id = "o" .. n
				m:SetAttribute("MapId", id)
			end
			used[id] = "taken"
			local pivot = m:GetPivot()
			table.insert(objects, {
				id = id,
				group = folderName,
				item = m.Name,
				x = num(pivot.Position.X),
				z = num(pivot.Position.Z),
				y = num(pivot.Position.Y - floorAt(pivot.Position.X, pivot.Position.Z)),
				yaw = num(yawOf(pivot)),
				scale = if m:IsA("Model") then num(m:GetScale()) else nil,
			})
			local itemKey = folderName .. "/" .. m.Name
			if not items[itemKey] then
				local template = group:FindFirstChild(m.Name)
				if not template then
					template = m:Clone()
					template:SetAttribute("MapId", nil)
					-- (at the origin, turned to yaw 0; any tilt it had stays)
					template:PivotTo(CFrame.Angles(0, -math.rad(yawOf(pivot)), 0) * (pivot - pivot.Position))
					template.Parent = group
				end
				-- its outline from above (template space: yaw 0, scale as saved), lowest first
				local parts = {}
				local base = template:GetPivot()
				local scale = if template:IsA("Model") then template:GetScale() else 1
				for _, p in (if template:IsA("BasePart") then { template } else template:GetDescendants()) do
					if p:IsA("BasePart") and p.Transparency < 0.9 then
						local l = base:ToObjectSpace(p.CFrame)
						local round = p:IsA("MeshPart") or (p:IsA("Part") and p.Shape ~= Enum.PartType.Block)
						table.insert(parts, {
							num(l.Position.X / scale), num(l.Position.Z / scale), num(p.Size.X / scale), num(p.Size.Z / scale),
							num(yawOf(l)), rgb(p.Color), num((l.Position.Y + p.Size.Y / 2) / scale), if round then 1 else 0,
						})
					end
				end
				table.sort(parts, function(a, b)
					return a[7] < b[7]
				end)
				while #parts > 80 do
					table.remove(parts, 1)
				end
				items[itemKey] = { group = folderName, item = m.Name, parts = parts }
			end
		end
	end
end
local itemList = {}
for _, v in items do
	table.insert(itemList, v)
end
-- (templates kept from earlier exports, for kinds no longer on the map)
for _, group in templates:GetChildren() do
	for _, t in group:GetChildren() do
		if not items[group.Name .. "/" .. t.Name] then
			table.insert(itemList, { group = group.Name, item = t.Name, parts = {} })
		end
	end
end

local borders = {}
local bfolder = world:FindFirstChild("Borders")
for _, p in (bfolder and bfolder:GetChildren() or {}) do
	if p:IsA("BasePart") then
		borders[p.Name] = num(p.Position.Z)
	end
end

return answer({
	palette = palette,
	items = itemList,
	map = {
		cell = CELL,
		origin = { X0, Z0 },
		size = { COLS, ROWS },
		borders = borders,
		tiles = tiles,
		objects = objects,
		rle = rows,
	},
})
