-- The lobby's plants (QM, Oct 12; the rocks thread's meshes, design/plants): trees in
-- clusters of 2 to 4 against the walls (both front corners, by the side boulders, both back
-- corners), flowers in mixed colours and grass tufts at their feet and along the dirt's
-- edges, and stepping-stone trails across the grass ring between the pens and by the start
-- line. Trees, grass and flowers at 2x; stone tiles at 1x on the 4-stud checker.
-- Everything goes on grass only: a spot counts if a ray straight down hits World.Ground
-- at grass height (the dirt's a stud lower), outside every pen at its biggest (88) and
-- clear of rocks, the gate and the podium. Seeded, so a rerun lays out the same.
-- Run in Studio's Edit mode (the command bar or execute_luau). Rebuilds
-- World.BaseDecor.Plants.

local AssetService = game:GetService("AssetService")

local PIECES = { -- [plant] = { { mesh id, colour } } (design/plants/pieces/colours.txt; the greens darker, moss/forest: QM, Oct 12)
	Tree = {
		{ 122716762637835, Color3.fromRGB(124, 86, 56) },
		{ 107212928998143, Color3.fromRGB(62, 128, 54) },
		{ 90105828541940, Color3.fromRGB(76, 144, 62) },
		{ 78902139089312, Color3.fromRGB(52, 112, 46) },
		{ 79271687387611, Color3.fromRGB(88, 156, 70) },
	},
	TreeSmall = {
		{ 89163282445563, Color3.fromRGB(124, 86, 56) },
		{ 109370396013457, Color3.fromRGB(76, 144, 62) },
		{ 109612738147316, Color3.fromRGB(62, 128, 54) },
	},
	GrassTuft = {
		{ 92858311584509, Color3.fromRGB(54, 122, 46) },
		{ 83041187034944, Color3.fromRGB(70, 142, 56) },
	},
	Flower = {
		{ 119180919982842, Color3.fromRGB(58, 120, 48) },
		{ 95410071184502, "petals" },
		{ 86751839950822, "centre" },
	},
	StoneTile = { { 111341018632779, Color3.fromRGB(159, 161, 172) } },
	StoneTile2 = { { 79901946489032, Color3.fromRGB(159, 161, 172) } },
	StoneTile3 = { { 99868534966094, Color3.fromRGB(159, 161, 172) } },
}
local PETALS = { -- (petals, centre)
	{ Color3.fromRGB(255, 148, 190), Color3.fromRGB(255, 196, 40) }, -- pink
	{ Color3.fromRGB(250, 248, 240), Color3.fromRGB(255, 196, 40) }, -- white
	{ Color3.fromRGB(255, 214, 64), Color3.fromRGB(236, 128, 40) }, -- yellow
}
local SCALE = { Tree = 4, TreeSmall = 4, GrassTuft = 2, Flower = 2 } -- (trees 2x again: QM, Oct 12)

-- The pens at their biggest (tools/pens.py: 88 square, facing the yard's middle).
local PENS = { Vector2.new(0, 218), Vector2.new(-110.3, 188.6), Vector2.new(110.3, 188.6), Vector2.new(-120.1, 74.8), Vector2.new(120.1, 74.8) }
local YARD = Vector3.new(0, 0, 96)
local PEN_HALF = 44 + 4

local world = workspace.World
local decor = world.BaseDecor
local old = decor:FindFirstChild("Plants")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "Plants"
folder.Parent = decor
local studs = game:GetService("MaterialService"):FindFirstChild("Studs", true)

local meshes = {} -- [id] = the uploaded MeshPart, cloned for each plant
local function piece(id)
	if not meshes[id] then
		meshes[id] = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id))
	end
	return meshes[id]:Clone()
end

local rng = Random.new(1012)
local placed = {} -- { Vector2, radius }: what's down so far

local function inPen(p)
	for _, c in PENS do
		local frame = CFrame.lookAt(Vector3.new(c.X, 0, c.Y), YARD)
		local l = frame:PointToObjectSpace(Vector3.new(p.X, 0, p.Y))
		if math.abs(l.X) < PEN_HALF and math.abs(l.Z) < PEN_HALF then
			return true
		end
	end
	return false
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { folder }
local function grassAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -120, 0), params)
	return hit and hit.Instance:IsDescendantOf(world.Ground) and hit.Position.Y > -0.5 and hit.Position.Y < 0.5
end

-- A spot of radius r is free: on grass all round, inside the walls, out of the pens,
-- the start area and everything already down.
local function free(p, r)
	if math.abs(p.X) > 172 - r or p.Y < 4 + r or p.Y > 260 - r then
		return false
	end
	if math.abs(p.X) < 66 + r and p.Y < 46 + r then
		return false -- (the start line and its lane)
	end
	for _, d in { Vector2.zero, Vector2.new(r, 0), Vector2.new(-r, 0), Vector2.new(0, r), Vector2.new(0, -r) } do
		local q = p + d
		if inPen(q) or not grassAt(q.X, q.Y) then
			return false
		end
	end
	for _, o in placed do
		if (o[1] - p).Magnitude < o[2] + r then
			return false
		end
	end
	return true
end

local counts = {}
local function put(kind, p, yaw, colours)
	local model = Instance.new("Model")
	model.Name = kind
	local at = CFrame.new(p.X, 0, p.Y) * CFrame.Angles(0, yaw, 0)
	local s = SCALE[kind] or 1
	for _, def in PIECES[kind] do
		local part = piece(def[1])
		part.Anchored = true
		part.CanCollide = kind == "Tree" or kind == "TreeSmall" -- (tufts, flowers and tiles: walk through/over)
		part.CastShadow = kind ~= "StoneTile" and kind ~= "StoneTile2" and kind ~= "StoneTile3"
		part.Color = if def[2] == "petals" then colours[1] elseif def[2] == "centre" then colours[2] else def[2]
		if studs then
			part.Material = studs.BaseMaterial
			part.MaterialVariant = studs.Name
			part.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.SmoothPlastic)
		end
		part.CFrame = at
		part.Parent = model
	end
	model.WorldPivot = at
	if s ~= 1 then
		model:ScaleTo(s) -- (about its pivot, the plant's base, so the pieces stay together)
	end
	model.Parent = folder
	counts[kind] = (counts[kind] or 0) + 1
end

-- Scatter n of kind (radius r) round c within reach, as many as fit in tries.
local function scatter(kind, c, reach, n, r, colours)
	local done, tries = 0, 0
	while done < n and tries < n * 40 do
		tries += 1
		local a, d = rng:NextNumber() * 2 * math.pi, rng:NextNumber() * reach
		local p = c + Vector2.new(math.cos(a), math.sin(a)) * d
		if free(p, r) then
			table.insert(placed, { p, r })
			local col = colours and colours() or nil
			put(kind, p, rng:NextNumber() * 2 * math.pi, col)
			done += 1
		end
	end
	return done
end
local function mixedPetals()
	return PETALS[rng:NextInteger(1, #PETALS)]
end

-- The rocks, the gate and the podium count as taken (the trees stand right by them).
for _, c in decor:GetChildren() do
	if c:IsA("BasePart") then
		table.insert(placed, { Vector2.new(c.Position.X, c.Position.Z), math.max(c.Size.X, c.Size.Z) * 0.45 })
	elseif c:IsA("Model") and c.Name == "PortalGate" then
		local cf, size = c:GetBoundingBox()
		table.insert(placed, { Vector2.new(cf.X, cf.Z), math.max(size.X, size.Z) * 0.55 })
	end
end
table.insert(placed, { Vector2.new(63.5, 24.6), 20 }) -- the podium (Config.Podium) and its snake

-- The tree clusters (QM's mock): both front corners (behind the gate and the podium), each
-- side wall between the side pens by its boulder, both back corners flanking Pen 1.
-- (QM, Oct 12: the front corners just one tree and two tufts each, no flowers: `bare`)
local CLUSTERS = {
	{ Vector2.new(-110, 16), 1, true }, { Vector2.new(110, 16), 1, true },
	{ Vector2.new(-163, 150), 3 }, { Vector2.new(163, 150), 3 },
	{ Vector2.new(-163, 120), 2 }, { Vector2.new(163, 120), 2 },
	{ Vector2.new(-58, 246), 3 }, { Vector2.new(58, 246), 3 },
}
for _, cl in CLUSTERS do
	local c = cl[1]
	if cl[3] then
		scatter("Tree", c, 6, 1, 16)
		scatter("GrassTuft", c, 20, 2, 1.6)
		continue
	end
	local big = rng:NextInteger(1, cl[2])
	scatter("Tree", c, 18, big, 16)
	scatter("TreeSmall", c, 20, cl[2] - big + 1, 11)
	scatter("Flower", c, 22, rng:NextInteger(6, 10), 2, mixedPetals)
	scatter("GrassTuft", c, 20, rng:NextInteger(2, 4), 1.6)
end

-- Flowers and tufts along the dirt's edges: grass spots with dirt a few studs off.
local edges = 0
for _ = 1, 4000 do
	if edges >= 22 then
		break
	end
	local p = Vector2.new(rng:NextNumber(-170, 170), rng:NextNumber(8, 258))
	local nearDirt = false
	for _, d in { Vector2.new(5, 0), Vector2.new(-5, 0), Vector2.new(0, 5), Vector2.new(0, -5) } do
		local q = p + d
		local hit = workspace:Raycast(Vector3.new(q.X, 80, q.Y), Vector3.new(0, -120, 0), params)
		if hit and hit.Instance:IsDescendantOf(world.Ground) and hit.Position.Y < -0.5 then
			nearDirt = true
		end
	end
	if nearDirt and not (p.Y < 50 and math.abs(p.X) > 66) and free(p, 2) then -- (none in the front corners: QM)
		table.insert(placed, { p, 2 })
		if edges % 3 == 2 then
			put("GrassTuft", p, rng:NextNumber() * 2 * math.pi)
		else
			put("Flower", p, rng:NextNumber() * 2 * math.pi, mixedPetals())
		end
		edges += 1
	end
end
-- A few single tufts on open grass.
for _ = 1, 6 do
	scatter("GrassTuft", Vector2.new(rng:NextNumber(-160, 160), rng:NextNumber(60, 250)), 0, 1, 1.6)
end

-- Stepping stones: trails of 3 to 6 tiles stair-stepping diagonally across the grass ring
-- where the yard's dirt meets the grass, leading away from the yard (one in each gap between
-- pens, two by the start line), each tile on a 4-stud checker square (4k + 2). Found by
-- search: a grass start by the dirt, then diagonal steps outward while they stay free.
local TILES = { "StoneTile", "StoneTile2", "StoneTile3" }
local function snap(v)
	return 4 * math.floor(v / 4) + 2
end
local starts = {} -- trail starts so far (kept 40 apart)
local trails = 0
for _ = 1, 20000 do
	if trails >= 8 then
		break
	end
	-- a grass checker square with the yard's dirt within a few studs of it
	local start = Vector2.new(snap(rng:NextNumber(-170, 170)), snap(rng:NextNumber(10, 255)))
	local spaced = true
	for _, o in starts do
		if (o - start).Magnitude < 30 then
			spaced = false
		end
	end
	local nearDirt = nil -- (which way the dirt is)
	if spaced then
		for _, d in { Vector2.new(6, 0), Vector2.new(-6, 0), Vector2.new(0, 6), Vector2.new(0, -6) } do
			local q = start + d
			local hit = workspace:Raycast(Vector3.new(q.X, 80, q.Y), Vector3.new(0, -120, 0), params)
			if hit and hit.Instance:IsDescendantOf(world.Ground) and hit.Position.Y < -0.5 then
				nearDirt = d.Unit
			end
		end
	end
	if nearDirt then
		-- (away from the dirt, stair-stepping to one side as it goes)
		local away, side = -nearDirt * 4, Vector2.new(nearDirt.Y, -nearDirt.X) * 4 * (if rng:NextNumber() < 0.5 then 1 else -1)
		local step = away + side
		local tiles = {}
		local q = start
		local n = rng:NextInteger(3, 6)
		for i = 1, n do
			if not free(q, 1.2) then
				break
			end
			table.insert(tiles, q)
			table.insert(placed, { q, 1.9 })
			q += if i % 2 == 1 then away else side -- (stair-steps)
		end
		if #tiles >= 3 then
			for _, t in tiles do
				put(TILES[rng:NextInteger(1, 3)], t, math.rad(rng:NextInteger(0, 3) * 90 + rng:NextNumber(-8, 8)))
			end
			table.insert(starts, start)
			trails += 1
		else
			for _ = 1, #tiles do
				table.remove(placed)
			end
		end
	end
end

local out = {}
for k, v in counts do
	table.insert(out, k .. " " .. v)
end
return table.concat(out, ", ") .. " | trails " .. trails
