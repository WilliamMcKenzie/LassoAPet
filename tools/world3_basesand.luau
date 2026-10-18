-- World 3's base floor (QM, Oct 14): sand (top 1) over every cell of the base that isn't water or wet
-- sand, damp sand (top 0) round the wet sand (8 ways). Untagged, so the Pirate Cove floor script
-- (which clears its own World3Biome parts) leaves them alone. The pens' tiles sit 0.2 above the sand.
local CS = game:GetService("CollectionService")
local G = workspace.World.Ground
local CELL = 8
local X0, X1, Z0, Z1 = -216, 216, 0, 320
local function key(i, j) return i * 100000 + j end
local taken, wet = {}, {}
local template
for _, p in G:GetChildren() do
	if p:IsA("BasePart") then
		if p.Position.Z > 0 and (p.Name == "WetSand" or p.Name == "Water" or p.Name == "Ground" or p.Name == "DampSand") then
			local lo = p.Position - p.Size / 2
			for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
				for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
					local k = key(math.floor(x / CELL), math.floor(z / CELL))
					taken[k] = true
					if p.Name == "WetSand" then wet[k] = true end
				end
			end
		end
		if not template and p.Name == "Ground" and p.Position.Z < 0 then template = p end
	end
end
template = template:Clone()
for _, tag in CS:GetTags(template) do CS:RemoveTag(template, tag) end
for name in template:GetAttributes() do template:SetAttribute(name, nil) end
local rows = {}
local nS, nD = 0, 0
for i = X0 / CELL, X1 / CELL - 1 do
	for j = Z0 / CELL, Z1 / CELL - 1 do
		if not taken[key(i, j)] then
			local damp = false
			for di = -1, 1 do for dj = -1, 1 do if wet[key(i + di, j + dj)] then damp = true end end end
			rows[j] = rows[j] or {}
			rows[j][i] = if damp then "DampSand" else "Ground"
			if damp then nD += 1 else nS += 1 end
		end
	end
end
local made = 0
local function lay(kind, i0, i1, j0, j1)
	local p = template:Clone()
	p.Name = kind
	local top = if kind == "DampSand" then 0 else 1
	p.Size = Vector3.new((i1 - i0 + 1) * CELL, template.Size.Y, (j1 - j0 + 1) * CELL)
	p.Position = Vector3.new((i0 + i1 + 1) / 2 * CELL, top - template.Size.Y / 2, (j0 + j1 + 1) / 2 * CELL)
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
template:Destroy()
return string.format("%d sand cells, %d damp cells -> %d parts", nS, nD, made)
