-- World 3 (QM, Oct 14): the regular sand ("Ground") of the base and Pirate Cove a stud above the
-- damp sand (top 2, was 1), and everything standing on it lifted with it.
local DRY = false
local G = workspace.World.Ground
local CELL, ZMIN = 8, -4336
local sand = {}
local function key(x, z) return math.floor(x / CELL) * 100000 + math.floor(z / CELL) end
local parts = {}
for _, p in G:GetChildren() do
	if p:IsA("BasePart") and p.Name == "Ground" and p.Position.Z > ZMIN and math.abs(p.Position.Y + p.Size.Y / 2 - 1) < 0.05 then
		table.insert(parts, p)
		local lo = p.Position - p.Size / 2
		for x = lo.X + CELL / 2, lo.X + p.Size.X, CELL do
			for z = lo.Z + CELL / 2, lo.Z + p.Size.Z, CELL do sand[key(x, z)] = true end
		end
	end
end
-- things standing on it: top-level models and loose parts in workspace folders (not the floor or walls)
local skip = { [G] = true, [workspace.World.Walls] = true, [workspace.Terrain] = true, [workspace.CurrentCamera] = true }
local lifted, names = 0, {}
local function consider(inst)
	local cf, size
	if inst:IsA("Model") then cf, size = inst:GetBoundingBox() elseif inst:IsA("BasePart") then cf, size = inst.CFrame, inst.Size else return false end
	local bottom = cf.Position.Y - size.Y / 2
	local at = inst:IsA("Model") and inst:GetPivot().Position or inst.Position
	if at.Z > ZMIN and math.abs(bottom - 1) < 0.35 and sand[key(at.X, at.Z)] then
		if not DRY then
			if inst:IsA("Model") then inst:PivotTo(inst:GetPivot() + Vector3.new(0, 1, 0)) else inst.Position += Vector3.new(0, 1, 0) end
		end
		lifted += 1
		names[inst.Name] = (names[inst.Name] or 0) + 1
		return true
	end
	return false
end
local function walk(folder)
	for _, c in folder:GetChildren() do
		if not skip[c] then
			if c:IsA("Folder") then walk(c) elseif not consider(c) and c:IsA("Model") and not c:FindFirstChildWhichIsA("Humanoid") then
				-- a group model (e.g. BaseDecor.Pirate): its children one by one
				local any = false
				for _, m in c:GetChildren() do if m:IsA("Model") or m:IsA("BasePart") then any = true end end
				if any and #c:GetChildren() > 1 then walk(c) end
			end
		end
	end
end
walk(workspace)
if not DRY then
	for _, p in parts do
		p.Size += Vector3.new(0, 1, 0)
		p.Position += Vector3.new(0, 0.5, 0)
	end
end
local t = {} for k, v in names do table.insert(t, k .. "=" .. v) end table.sort(t)
return (DRY and "DRY " or "") .. #parts .. " sand parts; lifted " .. lifted .. ": " .. table.concat(t, ", ")
