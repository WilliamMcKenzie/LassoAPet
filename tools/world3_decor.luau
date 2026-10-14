-- World 3 (QM, Oct 14): after tools/world3_base.luau, the base decor out 1.2x from (0, 0) with the walls and pens (tools/pens.py WORLD=3), kept on the floor; any now in a lagoon dropped. Run once, in Edit on the World 3 Place.
local W = workspace.World
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { W.Ground }
local function floor(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 50, z), Vector3.new(0, -100, 0), params)
	return hit and hit.Position.Y or 0, hit and hit.Instance.Name
end
local list = {}
for _, c in W.BaseDecor:GetChildren() do
	if c:IsA("Folder") then for _, m in c:GetChildren() do table.insert(list, m) end else table.insert(list, c) end
end
local moved, wet = 0, {}
for _, m in list do
	local pv = m:GetPivot()
	local p = pv.Position
	local before = floor(p.X, p.Z)
	local nx, nz = p.X * 1.2, p.Z * 1.2
	local after, kind = floor(nx, nz)
	m:PivotTo(pv + Vector3.new(nx - p.X, after - before, nz - p.Z))
	moved += 1
	if kind == "Water" then table.insert(wet, m.Name .. string.format("(%.0f,%.0f)", nx, nz)) end
end
local dropped = 0
for _, m in list do
	local p = m:GetPivot().Position
	local _, kind = floor(p.X, p.Z)
	if kind == "Water" then m:Destroy() dropped += 1 end
end
return moved .. " moved out 1.2x, " .. dropped .. " in a lagoon dropped"
