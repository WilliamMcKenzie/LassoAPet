local lineup = workspace:FindFirstChild("HalloweenPropsLineup")
local props = game.ServerStorage.HalloweenProps
local s = workspace.World.SpawnLocation
local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Include params.FilterDescendantsInstances = { workspace.World.Ground }
local order = { "LanternTree", "Scarecrow", "HayBale", "HayStack" }
local z, widths, total = s.Position.Z + 90, {}, 0
for _, n in order do
	local o = lineup:FindFirstChild(n) if o then o:Destroy() end
	local _, sz = props[n]:GetBoundingBox() widths[n] = math.max(sz.X, sz.Z) total += widths[n] + 8
end
local x = s.Position.X - total / 2
for _, n in order do
	local m = props[n]:Clone()
	local cx = x + widths[n] / 2
	local hit = workspace:Raycast(Vector3.new(cx, 60, z), Vector3.new(0, -120, 0), params)
	m:PivotTo(CFrame.new(cx, hit and hit.Position.Y or 0, z) * CFrame.Angles(0, math.pi, 0))
	m.Parent = lineup
	x += widths[n] + 8
end
return #order .. " harvest props in the lineup"
