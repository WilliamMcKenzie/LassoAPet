-- World 3 Candyland (QM, Oct 15): stand each Candyland prop on the floor tile under its pivot
-- (cream at top 1, the pink and mint patches and the candy cane at 2). Run after
-- tools/world3_candyland.luau, in Edit, QM not in Play. Re-running is fine.
local W = workspace.World
local Z0, Z1 = -7968, -11808
local tiles = {}
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("World3Biome") == "Candyland" then
		table.insert(tiles, p)
	end
end
local function topAt(x, z)
	local best
	for _, p in tiles do
		local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
		if x >= lo.X and x <= hi.X and z >= lo.Z and z <= hi.Z and (not best or hi.Y > best) then
			best = hi.Y
		end
	end
	return best
end
local moved = 0
for _, folder in { W.Obstacles, W.Decor:FindFirstChild("Props") } do
	for _, m in folder and folder:GetChildren() or {} do
		if m:GetAttribute("World3Prop") == "Candyland" then
			local cf = m:GetPivot()
			local top = cf.Z < Z0 and cf.Z > Z1 and topAt(cf.X, cf.Z)
			if top and math.abs(cf.Y - top) > 0.01 then
				m:PivotTo(cf + Vector3.new(0, top - cf.Y, 0))
				moved += 1
			end
		end
	end
end
return moved .. " Candyland props stood on the tile under them"
