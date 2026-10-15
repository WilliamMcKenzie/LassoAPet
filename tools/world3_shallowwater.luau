-- World 3 (QM, Oct 15): a ring of lighter, shallow water one tile wide round the inside of every pool
-- in the base and Pirate Cove (ShallowWater: the water tile see-through over a light turquoise).
local G = workspace.World.Ground
local CELL = 8
local SHALLOW = Color3.fromRGB(140, 225, 225)
local function key(i, j) return i * 100000 + j end
local done = {}
for _, region in { { 0, math.huge }, { -4336, 0 } } do
	local z0, z1 = region[1], region[2]
	local water, olds, template = {}, {}, nil
	local kindOf = {}
	for _, p in G:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Water" or p.Name == "ShallowWater") and p.Position.Z > z0 and p.Position.Z < z1 then
			local lo = p.Position - p.Size / 2
			for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
				for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
					water[key(math.floor(x / CELL), math.floor(z / CELL))] = { math.floor(x / CELL), math.floor(z / CELL) }
				end
			end
			if not template and p.Name == "Water" then template = p:Clone() end
			table.insert(olds, p)
		end
	end
	if not template then continue end
	local rows, nS, nW = {}, 0, 0
	for k, c in water do
		local edge = false
		for di = -1, 1 do for dj = -1, 1 do if not water[key(c[1] + di, c[2] + dj)] then edge = true end end end
		rows[c[2]] = rows[c[2]] or {}
		rows[c[2]][c[1]] = if edge then "ShallowWater" else "Water"
		if edge then nS += 1 else nW += 1 end
	end
	for _, p in olds do p:Destroy() end
	local top = template.Position.Y + template.Size.Y / 2
	local made = 0
	local function lay(name, i0, i1, j0, j1)
		local p = template:Clone()
		p.Name = name
		p.Size = Vector3.new((i1 - i0 + 1) * CELL, template.Size.Y, (j1 - j0 + 1) * CELL)
		p.Position = Vector3.new((i0 + i1 + 1) / 2 * CELL, top - template.Size.Y / 2, (j0 + j1 + 1) / 2 * CELL)
		if name == "ShallowWater" then
			p.Color = SHALLOW
			for _, t in p:GetChildren() do if t:IsA("Texture") and t.Name == "Water" then t.Transparency = 0.45; t.Color3 = Color3.new(1, 1, 1) end end
		end
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
	table.insert(done, string.format("%s: %d shallow, %d deep cells -> %d parts", z0 >= 0 and "base" or "Pirate Cove", nS, nW, made))
end
return table.concat(done, "; ")
