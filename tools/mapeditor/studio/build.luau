-- Builds World 1's course in the open Studio place (Edit mode) from the map editor's .map
-- (tools/mapeditor; QM, Nov 6). serve.py puts the map above this line as DATA (JSON, rows
-- run-length coded as tile:run) and runs it after every Save; publish the place to keep the result.
--
-- Replaces, south of the start line (z < 0): World.Ground and World.Funnel's floor parts,
-- World.Walls' walls and the Meadow's cliff blocks (World.Cliffs West/East) with parts built
-- from the tiles (a floor tile is one part a stretch, a wall tile a side part and its cap);
-- moves, turns, scales, adds and deletes the objects in World.Obstacles, Decor and Nests by
-- their MapId (new ones are copies of ServerStorage.MapTemplates); sets World.Borders and
-- the colour attributes on World the map changed, then repaints as WorldColors does in Play.
-- The base (z > 0), World.Barriers and World.Cliffs.Far aren't touched. One undo step.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if RunService:IsRunning() then
	return HttpService:JSONEncode({ ok = false, message = "playing" })
end

local STUDS, CHECKER = "rbxassetid://7447638591", "rbxassetid://84747779882944"
local MAX_RUN = 16 -- cells: no floor part longer than 64 studs (colours go by each part's middle)
local WALL_BOTTOM = -4

local data = HttpService:JSONDecode(DATA)
local world = workspace:FindFirstChild("World")
assert(world, "no workspace.World")
local CELL, X0, Z0 = data.cell, data.origin[1], data.origin[2]
local COLS, ROWS = data.size[1], data.size[2]

local kind = table.create(COLS * ROWS, 0)
for r, row in data.rle do
	local c = 0
	for tk, run in string.gmatch(row, "(%d+):(%d+)") do
		local k = tonumber(tk)
		for _ = 1, tonumber(run) do
			if c < COLS then
				kind[(r - 1) * COLS + c + 1] = k
			end
			c += 1
		end
	end
end
local function topAt(x, z)
	local c, r = math.floor((x - X0) / CELL), math.floor((z - Z0) / CELL)
	if c < 0 or r < 0 or c >= COLS or r >= ROWS then
		return 0
	end
	local k = kind[r * COLS + c + 1]
	return if k == 0 then 0 else data.tiles[k].top
end

local recording = ChangeHistoryService:TryBeginRecording("Build map")
local count = { floor = 0, walls = 0, moved = 0, added = 0, removed = 0 }

-- ---- clear what the map owns ----------------------------------------------------------------
for _, name in { "Ground", "Funnel", "Walls" } do
	local folder = world:FindFirstChild(name)
	for _, p in (folder and folder:GetChildren() or {}) do
		if p:IsA("BasePart") and p.Position.Z < 0 then
			p:Destroy()
		end
	end
end
local cliffs = world:FindFirstChild("Cliffs")
for _, name in { "West", "East" } do
	local f = cliffs and cliffs:FindFirstChild(name)
	if f then
		f:Destroy()
	end
end
local ground = world:FindFirstChild("Ground")
local walls = world:FindFirstChild("Walls")

-- ---- tiles to parts ----------------------------------------------------------------------------
local function texture(part, face, image, tile, z, offset)
	local t = Instance.new("Texture")
	t.Name = if image == STUDS then "Texture" else "Checker"
	t.Face = face
	t.Texture = image
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	t.ZIndex = z
	t.OffsetStudsU = offset or 0
	t.Parent = part
end
local SIDES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local function box(name, parent, x0, y0, z0, x1, y1, z1, tile, faces, checker)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Material = if tile.material then Enum.Material[tile.material] else Enum.Material.Plastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide = not tile.nocollide
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	-- (the checker lines up with the world's 8-stud squares: a part starting half a square
	-- off starts its checker half a square in)
	local odd = ((x0 + z0) / CELL) % 2 == 1
	for _, face in faces do
		texture(p, face, STUDS, 1, 2)
		if checker then
			texture(p, face, CHECKER, 8, 1, if odd and face == Enum.NormalId.Top then 4 else 0)
		end
	end
	p.Parent = parent
	return p
end

-- greedy rectangles of one tile, at most MAX_RUN cells each way
local done = table.create(COLS * ROWS, false)
for r = 0, ROWS - 1 do
	for c = 0, COLS - 1 do
		local i = r * COLS + c + 1
		local k = kind[i]
		if k ~= 0 and not done[i] then
			local c1 = c + 1
			while c1 < COLS and c1 - c < MAX_RUN and kind[r * COLS + c1 + 1] == k and not done[r * COLS + c1 + 1] do
				c1 += 1
			end
			local r1 = r + 1
			while r1 < ROWS and r1 - r < MAX_RUN do
				local ok = true
				for cc = c, c1 - 1 do
					local j = r1 * COLS + cc + 1
					if kind[j] ~= k or done[j] then
						ok = false
						break
					end
				end
				if not ok then
					break
				end
				r1 += 1
			end
			for rr = r, r1 - 1 do
				for cc = c, c1 - 1 do
					done[rr * COLS + cc + 1] = true
				end
			end
			local t = data.tiles[k]
			local x0, x1 = X0 + c * CELL, X0 + c1 * CELL
			local z0, z1 = Z0 + r * CELL, Z0 + r1 * CELL
			if t.wall then
				local capT = if t.cap == t.key then 0 elseif t.top - WALL_BOTTOM > 20 then 2 else 1
				box(t.key, walls, x0, WALL_BOTTOM, z0, x1, t.top - capT, z1, t, if capT == 0 then { Enum.NormalId.Top, table.unpack(SIDES) } else SIDES, true)
				if capT > 0 then
					box(t.cap, walls, x0, t.top - capT, z0, x1, t.top, z1, t, { Enum.NormalId.Top, table.unpack(SIDES) }, t.cap ~= "Cap")
				end
				count.walls += 1
			else
				box(t.key, ground, x0, math.min(-2, t.top - 2), z0, x1, t.top, z1, t, { Enum.NormalId.Top }, true)
				count.floor += 1
			end
		end
	end
end

-- ---- borders ---------------------------------------------------------------------------------------
local borders = world:FindFirstChild("Borders")
for name, z in data.borders or {} do
	local p = borders and borders:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		p.CFrame = p.CFrame + Vector3.new(0, 0, z - p.Position.Z)
	end
end

-- ---- colours: the map's on World, the rest from Config (and painted) -------------------------------
for name in string.gmatch(world:GetAttribute("MapColours") or "", "[^,]+") do
	if not (data.colours or {})[name] then
		world:SetAttribute(name, nil)
	end
end
local names = {}
for name, c in data.colours or {} do
	world:SetAttribute(name, Color3.fromRGB(c[1], c[2], c[3]))
	table.insert(names, name)
end
table.sort(names)
world:SetAttribute("MapColours", if #names > 0 then table.concat(names, ",") else nil)

local tmp = Instance.new("Folder")
tmp.Name = "MapBuildTemp"
game:GetService("ReplicatedStorage").Shared:Clone().Parent = tmp
tmp.Parent = ServerStorage
local painted, paintErr = pcall(function()
	local Config = require(tmp.Shared.Config)
	local WorldColors = require(tmp.Shared.WorldColors)
	local defaults = {}
	for i, biome in Config.Biomes do
		local p = WorldColors.prefix(i)
		defaults[p .. "GroundA"], defaults[p .. "GroundB"] = biome.GroundColors[1], biome.GroundColors[2]
		defaults[p .. "WallA"], defaults[p .. "WallB"] = biome.WallColors[1], biome.WallColors[2]
		for name, colors in biome.Patches or {} do
			defaults[p .. name .. "A"], defaults[p .. name .. "B"] = colors[1], colors[2]
		end
	end
	local proxy = { Ground = ground, Walls = walls }
	function proxy:GetAttribute(key)
		local v = world:GetAttribute(key)
		if v == nil then
			return defaults[key]
		end
		return v
	end
	function proxy:FindFirstChild(name)
		return world:FindFirstChild(name)
	end
	WorldColors.apply(proxy)
end)
tmp:Destroy()

-- ---- objects -------------------------------------------------------------------------------------
local templates = ServerStorage:FindFirstChild("MapTemplates")
local byId, top = {}, 0
for _, folderName in { "Obstacles", "Decor", "Nests" } do
	local folder = world:FindFirstChild(folderName)
	for _, m in (folder and folder:GetChildren() or {}) do
		local id = m:GetAttribute("MapId")
		if id then
			byId[id] = m
			top = math.max(top, tonumber(string.match(id, "%d+")) or 0)
		end
	end
end
local function yawOf(cf)
	local look = cf.LookVector
	return math.deg(math.atan2(-look.X, -look.Z))
end
local keep, newIds, missing = {}, {}, {}
for n, o in data.objects do
	local m = o.id and byId[o.id]
	local fresh = false
	if not m then
		local group = templates and templates:FindFirstChild(o.group)
		local template = group and group:FindFirstChild(o.item)
		if not template then
			table.insert(missing, o.group .. "/" .. o.item)
			continue
		end
		m = template:Clone()
		local folder = world:FindFirstChild(o.group)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = o.group
			folder.Parent = world
		end
		m.Parent = folder
		top += 1
		local id = o.id or ("o" .. top)
		if o.id and byId[o.id] == nil and keep[o.id] then
			id = "o" .. top -- (a copy that kept its original's id)
		end
		m:SetAttribute("MapId", id)
		newIds[tostring(n)] = id
		fresh = true
		count.added += 1
	end
	local id = m:GetAttribute("MapId")
	keep[id] = true
	if m:IsA("Model") and o.scale and math.abs(m:GetScale() - o.scale) > 1e-3 then
		m:ScaleTo(o.scale)
	end
	local pivot = m:GetPivot()
	local at = Vector3.new(o.x, topAt(o.x, o.z) + (o.y or 0), o.z)
	local want = CFrame.new(at) * CFrame.Angles(0, math.rad((o.yaw or 0) - yawOf(pivot)), 0) * (pivot - pivot.Position)
	if fresh or (want.Position - pivot.Position).Magnitude > 0.01 or math.abs((o.yaw or 0) - yawOf(pivot)) > 0.05 then
		m:PivotTo(want)
		if not fresh then
			count.moved += 1
		end
	end
end
for id, m in byId do
	if not keep[id] and m.Parent then
		m:Destroy()
		count.removed += 1
	end
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return HttpService:JSONEncode({
	ok = true,
	message = string.format(
		"built %d floor and %d wall pieces; objects: %d moved, %d added, %d removed%s%s",
		count.floor, count.walls, count.moved, count.added, count.removed,
		if #missing > 0 then "; no template for " .. table.concat(missing, ", ") else "",
		if painted then "" else "; repaint failed: " .. tostring(paintErr)
	),
	newIds = newIds,
})
