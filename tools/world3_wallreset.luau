-- World 3 (QM, Oct 14): the base's walls back to one plain part per wall (no bands, no runes),
-- wooden brown from Config (BaseWall). Engravings come off every wall.
local W = workspace.World.Walls
local parts = {}
for _, p in W:GetChildren() do
	if p:IsA("BasePart") and (p.Name == "BaseWallLow" or p.Name == "BaseWallMid" or p.Name == "BaseWall") then table.insert(parts, p) end
end
local byX, byZ = {}, {}
local function r(v) return math.floor(v * 2 + 0.5) / 2 end
for _, p in parts do
	local x, z = r(p.Position.X), r(p.Position.Z)
	byX[x] = (byX[x] or 0) + 1; byZ[z] = (byZ[z] or 0) + 1
end
local groups = {}
for _, p in parts do
	local x, z = r(p.Position.X), r(p.Position.Z)
	local k = if (byZ[z] or 0) >= (byX[x] or 0) and p.Size.X >= p.Size.Z then "Z" .. z elseif (byX[x] or 0) > (byZ[z] or 0) or p.Size.Z > p.Size.X then "X" .. x else "Z" .. z
	groups[k] = groups[k] or {}
	table.insert(groups[k], p)
end
local template = parts[1]:Clone()
for _, c in template:GetChildren() do if c.Name == "Engraving" then c:Destroy() end end
local made = 0
for k, list in groups do
	local alongX = k:sub(1, 1) == "Z"
	local spans = {}
	for _, p in list do
		local c = if alongX then p.Position.X else p.Position.Z
		local half = (if alongX then p.Size.X else p.Size.Z) / 2
		table.insert(spans, { c - half, c + half })
	end
	table.sort(spans, function(a, b) return a[1] < b[1] end)
	local segs, cur = {}, nil
	for _, s in spans do
		if cur and s[1] <= cur[2] + 0.01 then cur[2] = math.max(cur[2], s[2]) else cur = { s[1], s[2] }; table.insert(segs, cur) end
	end
	local ref = list[1]
	local thick = if alongX then ref.Size.Z else ref.Size.X
	for _, sgm in segs do
		local p = template:Clone()
		p.Name = "BaseWall"
		local len, mid = sgm[2] - sgm[1], (sgm[1] + sgm[2]) / 2
		p.Size = if alongX then Vector3.new(len, 48, thick) else Vector3.new(thick, 48, len)
		p.Position = if alongX then Vector3.new(mid, 24, ref.Position.Z) else Vector3.new(ref.Position.X, 24, mid)
		p.Parent = W
		made += 1
	end
end
for _, p in parts do p:Destroy() end
template:Destroy()
local stripped = 0
for _, p in W:GetChildren() do local e = p:FindFirstChild("Engraving") if e then e:Destroy(); stripped += 1 end end
return #parts .. " band parts -> " .. made .. " walls; " .. stripped .. " other engravings removed"
