-- World 3's base (QM, Oct 14): a ring of sand right round the walls, then a ring of damp sand, then
-- wet sand wherever the next ring would be water, so the floor always meets the wall at sand.
local CS = game:GetService("CollectionService")
local G = workspace.World.Ground
local CELL = 8
local I0, I1, J0, J1 = -27, 26, 0, 39 -- the base's cells inside its walls (x -216..216, z 0..320)
local KINDS = { Ground = true, DampSand = true, WetSand = true, Water = true }
local function key(i, j) return i * 100000 + j end
local kind, templates, olds = {}, {}, {}
for _, p in G:GetChildren() do
	if p:IsA("BasePart") and KINDS[p.Name] and p.Position.Z > 0 then
		local lo = p.Position - p.Size / 2
		for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
			for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
				kind[key(math.floor(x / CELL), math.floor(z / CELL))] = p.Name
			end
		end
		if not templates[p.Name] then
			local t = p:Clone()
			for _, tag in CS:GetTags(t) do CS:RemoveTag(t, tag) end
			for a in t:GetAttributes() do t:SetAttribute(a, nil) end
			templates[p.Name] = { part = t, top = p.Position.Y + p.Size.Y / 2 }
		end
		table.insert(olds, p)
	end
end
local function ring(i, j) return math.min(i - I0, I1 - i, j - J0, J1 - j) end -- 0 = against a wall
local changed = 0
for i = I0, I1 do
	for j = J0, J1 do
		local k, r = key(i, j), ring(i, j)
		local want = if r == 0 then "Ground" elseif r == 1 then "DampSand" elseif r == 2 and kind[k] == "Water" then "WetSand" else kind[k]
		if want and want ~= kind[k] then kind[k] = want; changed += 1 end
	end
end
-- sand never touches wet sand: any that does turns damp (8 ways)
local fix = {}
for i = I0, I1 do
	for j = J0, J1 do
		if kind[key(i, j)] == "Ground" then
			for di = -1, 1 do for dj = -1, 1 do if kind[key(i + di, j + dj)] == "WetSand" then fix[key(i, j)] = true end end end
		end
	end
end
for k in fix do kind[k] = "DampSand"; changed += 1 end
-- (the course's mouth: cells at the front edge that weren't base floor stay as they were)
for _, p in olds do p:Destroy() end
local rows = {}
for i = I0, I1 do for j = J0, J1 do local k = kind[key(i, j)] if k then rows[j] = rows[j] or {}; rows[j][i] = k end end end
local made = 0
local function lay(name, i0, i1, j0, j1)
	local t = templates[name]
	local p = t.part:Clone()
	p.Size = Vector3.new((i1 - i0 + 1) * CELL, t.part.Size.Y, (j1 - j0 + 1) * CELL)
	p.Position = Vector3.new((i0 + i1 + 1) / 2 * CELL, t.top - t.part.Size.Y / 2, (j0 + j1 + 1) / 2 * CELL)
	p.Parent = G
	made += 1
end
local js = {} for j in rows do table.insert(js, j) end table.sort(js)
local prev = {}
for _, j in js do
	local row = rows[j]
	local is = {} for i in row do table.insert(is, i) end table.sort(is)
	local runs, r = {}, nil
	for _, i in is do
		if r and i == r[3] + 1 and row[i] == r[1] then r[3] = i else r = { row[i], i, i }; table.insert(runs, r) end
	end
	local nextPrev = {}
	for _, r in runs do
		local rk = r[1] .. ":" .. r[2] .. ":" .. r[3]
		local p = prev[rk]
		if p and p[5] == j - 1 then p[5] = j; nextPrev[rk] = p; prev[rk] = nil else nextPrev[rk] = { r[1], r[2], r[3], j, j } end
	end
	for _, p in prev do lay(p[1], p[2], p[3], p[4], p[5]) end
	prev = nextPrev
end
for _, p in prev do lay(p[1], p[2], p[3], p[4], p[5]) end
for _, t in templates do t.part:Destroy() end
return changed .. " cells changed; " .. #olds .. " parts -> " .. made
