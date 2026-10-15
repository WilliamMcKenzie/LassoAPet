-- World 3 (QM, Oct 15): a ring of lighter, shallow water one tile wide round the inside of every pool
-- in the base and Pirate Cove (4 ways, so diagonal corners keep their depth). New parts are laid
-- first, the old water parts removed after. Rerunnable.
local G = workspace.World.Ground
local CELL = 8
local SHALLOW, DEEP, TINT = Color3.fromRGB(95, 205, 215), Color3.fromRGB(49, 170, 235), Color3.fromRGB(150, 200, 255)
local IMAGE = (function() local m = game.ReplicatedStorage.Shared.Config:Clone(); m.Name = "ConfigCopy"; m.Parent = game.ReplicatedStorage.Shared; local C = require(m); m:Destroy(); return C.Water.Image end)()
local function key(i, j) return i * 100000 + j end
local out = {}
for _, region in { { 0, math.huge, nil }, { -4336, 0, "PirateCove" } } do
	local z0, z1, biome = region[1], region[2], region[3]
	local water, olds, top, depth, base = {}, {}, nil, nil, nil
	for _, p in G:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Water" or p.Name == "ShallowWater") and p.Position.Z > z0 and p.Position.Z < z1 then
			local lo = p.Position - p.Size / 2
			for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
				for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
					local i, j = math.floor(x / CELL), math.floor(z / CELL)
					water[key(i, j)] = { i, j }
				end
			end
			top = top or (p.Position.Y + p.Size.Y / 2)
			depth = depth or p.Size.Y
			base = base or p
			table.insert(olds, p)
		end
	end
	if not base then continue end
	local rows, nS, nW = {}, 0, 0
	for _, c in water do
		local edge = false
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			if not water[key(c[1] + d[1], c[2] + d[2])] then edge = true end
		end
		rows[c[2]] = rows[c[2]] or {}
		rows[c[2]][c[1]] = if edge then "ShallowWater" else "Water"
		if edge then nS += 1 else nW += 1 end
	end
	local made = 0
	local function lay(name, i0, i1, j0, j1)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Material = base.Material
		p.MaterialVariant = base.MaterialVariant
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size = Vector3.new((i1 - i0 + 1) * CELL, depth, (j1 - j0 + 1) * CELL)
		p.Position = Vector3.new((i0 + i1 + 1) / 2 * CELL, top - depth / 2, (j0 + j1 + 1) / 2 * CELL)
		p.Color = if name == "ShallowWater" then SHALLOW else DEEP
		local t = Instance.new("Texture")
		t.Name = "Water"; t.Face = Enum.NormalId.Top; t.Texture = IMAGE
		t.StudsPerTileU, t.StudsPerTileV = 8, 8
		t.Color3 = if name == "ShallowWater" then Color3.new(1, 1, 1) else TINT
		t.Transparency = if name == "ShallowWater" then 0.3 else 0
		t.Parent = p
		if biome then p:SetAttribute("World3Biome", biome) end
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
	for _, p in olds do p:Destroy() end
	table.insert(out, string.format("%s: %d shallow, %d deep cells -> %d parts", biome or "base", nS, nW, made))
end
return table.concat(out, "; ")
