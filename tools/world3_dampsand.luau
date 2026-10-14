-- A damp-sand band (QM, Oct 14): every sand ("Ground") cell of World 3's base and Pirate Cove that
-- touches wet sand (8 ways) becomes DampSand, so sand never meets wet sand directly.
local G = workspace.World.Ground
local CELL, ZMIN = 8, -4336
local cells, wet, sandParts = {}, {}, {}
local template, ox, oz
local function key(i, j) return i * 100000 + j end
for _, p in G:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z > ZMIN and (p.Name == "Ground" or p.Name == "WetSand" or p.Name == "DampSand") then
		local lo = p.Position - p.Size / 2
		ox, oz = ox or lo.X % CELL, oz or lo.Z % CELL
		for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
			for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
				local i, j = math.floor((x - ox) / CELL), math.floor((z - oz) / CELL)
				if p.Name == "WetSand" then wet[key(i, j)] = true else cells[key(i, j)] = { i, j } end
			end
		end
		if p.Name ~= "WetSand" then table.insert(sandParts, p); template = template or (p.Name == "Ground" and p) end
	end
end
local damp, n = {}, 0
for k, c in cells do
	for di = -1, 1 do for dj = -1, 1 do
		if wet[key(c[1] + di, c[2] + dj)] then damp[k] = true end
	end end
	if damp[k] then n += 1 end
end
template = template:Clone()
for _, p in sandParts do p:Destroy() end
-- greedy rectangles: runs along x, merged down z
local rows = {}
for k, c in cells do
	local kind = if damp[k] then "DampSand" else "Ground"
	rows[c[2]] = rows[c[2]] or {}
	rows[c[2]][c[1]] = kind
end
local open, made = {}, 0
local function lay(kind, i0, i1, j0, j1)
	local p = template:Clone()
	p.Name = kind
	p.Size = Vector3.new((i1 - i0 + 1) * CELL, template.Size.Y, (j1 - j0 + 1) * CELL)
	p.Position = Vector3.new(ox + (i0 + i1 + 1) / 2 * CELL, template.Position.Y, oz + (j0 + j1 + 1) / 2 * CELL)
	p.Parent = G
	made += 1
end
local js = {} for j in rows do table.insert(js, j) end table.sort(js)
local prev = {} -- [runkey] = {kind,i0,i1,j0,jlast}
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
		if p and p[5] == j - 1 then p[5] = j; nextPrev[rk] = p; prev[rk] = nil
		else nextPrev[rk] = { r[1], r[2], r[3], j, j } end
	end
	for _, p in prev do lay(p[1], p[2], p[3], p[4], p[5]) end
	prev = nextPrev
end
for _, p in prev do lay(p[1], p[2], p[3], p[4], p[5]) end
return "damp cells " .. n .. ", sand parts " .. #sandParts .. " -> " .. made .. " (offset " .. ox .. "," .. oz .. ")"
