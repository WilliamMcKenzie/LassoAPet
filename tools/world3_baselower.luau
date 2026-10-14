-- World 3 (QM, Oct 14): every floor tile of the base (z > 0) a stud lower, and what stands on them with them.
local G = workspace.World.Ground
local CELL = 8
local tops = {}
local function key(x, z) return math.floor(x / CELL) * 100000 + math.floor(z / CELL) end
local tiles = {}
for _, p in G:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z > 0 then
		table.insert(tiles, p)
		local lo = p.Position - p.Size / 2
		local top = p.Position.Y + p.Size.Y / 2
		for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
			for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do
				local k = key(x, z)
				tops[k] = math.max(tops[k] or -math.huge, top)
			end
		end
	end
end
local skip = { [G] = true, [workspace.World.Walls] = true, [workspace.Terrain] = true, [workspace.CurrentCamera] = true }
local moved, names = 0, {}
local function consider(inst)
	local cf, size
	if inst:IsA("Model") then cf, size = inst:GetBoundingBox() elseif inst:IsA("BasePart") then cf, size = inst.CFrame, inst.Size else return false end
	local at = if inst:IsA("Model") then inst:GetPivot().Position else inst.Position
	local top = tops[key(at.X, at.Z)]
	if at.Z > 0 and top and math.abs(cf.Position.Y - size.Y / 2 - top) < 0.6 then
		if inst:IsA("Model") then inst:PivotTo(inst:GetPivot() - Vector3.new(0, 1, 0)) else inst.Position -= Vector3.new(0, 1, 0) end
		moved += 1
		names[inst.Name] = (names[inst.Name] or 0) + 1
		return true
	end
	return false
end
local function walk(folder)
	for _, c in folder:GetChildren() do
		if not skip[c] then
			if c:IsA("Folder") then walk(c)
			elseif not consider(c) and c:IsA("Model") and not c:FindFirstChildWhichIsA("Humanoid") and #c:GetChildren() > 1 then walk(c) end
		end
	end
end
walk(workspace)
for _, p in tiles do p.Position -= Vector3.new(0, 1, 0) end
local t = {} for k, v in names do table.insert(t, k .. "=" .. v) end table.sort(t)
return #tiles .. " tiles lowered; " .. moved .. " things with them: " .. table.concat(t, ", ")
