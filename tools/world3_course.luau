-- World 3's course (QM, Oct 14; draft): the walls for its four biomes, Pirate Cove, Garden,
-- Candyland and Cnidaria. Made by tools/world3_course.py: edit that and re-make this, not
-- this. Run in Studio (Edit, execute_luau) on the World 3 Place (workspace.World), FIRST,
-- then tools/world3_piratecove.luau, world3_garden.luau, world3_candyland.luau and
-- world3_cnidaria.luau. Re-running is fine. The base (z > 0) is left alone.
-- 1. Clears World 2's copied course past the start line: its floor (and World.Funnel's),
--    its side walls and caps, its obstacles and props (World 2's: World 3's come later).
-- 2. Lays the side walls along the course's new shape: not one straight funnel but straight
--    pieces between the points of world3_course.py PROFILE, widening and narrowing (never
--    past 137, World 1's and World 2's widest). Walls 8 thick, 48 tall, caps 10 wide on top.
-- No far wall: the course ends at the finish line, into the void, as Worlds 1 and 2 do.
local W = workspace.World
local END = -18048
-- { centre x, centre z, length, yaw } per wall piece (its inner face on the course's edge)
local WALLS = {
	{ -63.999, -239.933, 488.067, -3.124928 },
	{ 63.999, -239.933, 488.067, 3.124928 },
	{ -81.99, -679.721, 408.979, -3.071707 },
	{ 81.99, -679.721, 408.979, 3.071707 },
	{ -96.0, -1160.0, 568.0, 3.141593 },
	{ 96.0, -1160.0, 568.0, 3.141593 },
	{ -83.993, -1640.24, 408.719, 3.081664 },
	{ 83.993, -1640.24, 408.719, -3.081664 },
	{ -74.0, -2039.96, 408.02, -3.131593 },
	{ 74.0, -2039.96, 408.02, 3.131593 },
	{ -93.987, -2459.674, 449.47, -3.059956 },
	{ 93.987, -2459.674, 449.47, 3.059956 },
	{ -112.0, -2960.0, 568.0, 3.141593 },
	{ 112.0, -2960.0, 568.0, 3.141593 },
	{ -97.994, -3500.215, 528.753, 3.087798 },
	{ 97.994, -3500.215, 528.753, -3.087798 },
	{ -82.0, -4048.028, 584.014, 3.134648 },
	{ 82.0, -4048.028, 584.014, -3.134648 },
	{ -92.994, -4567.776, 472.728, -3.085617 },
	{ 92.994, -4567.776, 472.728, 3.085617 },
	{ -95.996, -5020.182, 448.454, 3.096169 },
	{ 95.996, -5020.182, 448.454, -3.096169 },
	{ -86.0, -5480.0, 488.0, 3.141593 },
	{ 86.0, -5480.0, 488.0, 3.141593 },
	{ -103.989, -5959.701, 489.348, -3.066733 },
	{ 103.989, -5959.701, 489.348, 3.066733 },
	{ -122.0, -6520.0, 648.0, 3.141593 },
	{ 122.0, -6520.0, 648.0, 3.141593 },
	{ -108.995, -7100.2, 528.65, 3.091634 },
	{ 108.995, -7100.2, 528.65, -3.091634 },
	{ -94.0, -7664.026, 616.013, 3.135014 },
	{ 94.0, -7664.026, 616.013, -3.135014 },
	{ -104.993, -8183.76, 440.782, -3.08148 },
	{ 104.993, -8183.76, 440.782, 3.08148 },
	{ -118.0, -8640.0, 488.0, 3.141593 },
	{ 118.0, -8640.0, 488.0, 3.141593 },
	{ -107.996, -9100.182, 448.454, 3.096169 },
	{ 107.996, -9100.182, 448.454, -3.096169 },
	{ -114.993, -9599.758, 569.031, -3.080953 },
	{ 114.993, -9599.758, 569.031, 3.080953 },
	{ -132.0, -10200.0, 648.0, 3.141593 },
	{ 132.0, -10200.0, 648.0, 3.141593 },
	{ -119.996, -10780.184, 528.554, 3.095472 },
	{ 119.996, -10780.184, 528.554, -3.095472 },
	{ -106.0, -11424.021, 776.01, 3.136384 },
	{ 106.0, -11424.021, 776.01, -3.136384 },
	{ -118.995, -12103.798, 600.76, -3.09096 },
	{ 118.995, -12103.798, 600.76, 3.09096 },
	{ -137.5, -12699.953, 608.041, -3.129927 },
	{ 137.5, -12699.953, 608.041, 3.129927 },
	{ -128.497, -13320.156, 648.488, 3.10255 },
	{ 128.497, -13320.156, 648.488, -3.10255 },
	{ -116.0, -13980.0, 688.0, 3.141593 },
	{ 116.0, -13980.0, 688.0, 3.141593 },
	{ -128.497, -14659.853, 688.459, -3.104844 },
	{ 128.497, -14659.853, 688.459, 3.104844 },
	{ -141.0, -15420.0, 848.0, 3.141593 },
	{ 141.0, -15420.0, 848.0, 3.141593 },
	{ -131.498, -16180.112, 688.265, 3.113659 },
	{ 131.498, -16180.112, 688.265, -3.113659 },
	{ -128.999, -16899.926, 768.129, -3.123174 },
	{ 128.999, -16899.926, 768.129, 3.123174 },
	{ -134.0, -17664.021, 776.01, 3.136384 },
	{ 134.0, -17664.021, 776.01, -3.136384 },
}

local function past(inst) -- in the course, past the start line
	local cf, size = inst:GetPivot(), inst:IsA("BasePart") and inst.Size or Vector3.zero
	return cf.Position.Z + math.max(size.X, size.Z) / 2 < 0 and cf.Position.Z < -10
end
local cleared = { floor = 0, walls = 0, things = 0 }
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z < 0 and p.Position.Z + p.Size.Z / 2 <= 0.5 then
		p:Destroy()
		cleared.floor += 1
	end
end
if W:FindFirstChild("Funnel") then
	W.Funnel:Destroy()
end
local wallTemplate, capTemplate
for _, p in W.Walls:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z < -10 then
		if p.Name == "Cap" then
			capTemplate = capTemplate or p:Clone()
		else
			wallTemplate = wallTemplate or p:Clone()
		end
		p:Destroy()
		cleared.walls += 1
	end
end
assert(wallTemplate and capTemplate, "no course walls in World.Walls to copy the look of (already run? then World.Walls has World3Wall pieces: fine)")
for _, folder in { W:FindFirstChild("Obstacles"), W:FindFirstChild("Decor") and W.Decor:FindFirstChild("Props") } do
	for _, m in folder and folder:GetChildren() or {} do
		if past(m) then
			m:Destroy()
			cleared.things += 1
		end
	end
end

for _, t in { wallTemplate, capTemplate } do
	for k in t:GetAttributes() do
		t:SetAttribute(k, nil)
	end
end
for _, w in WALLS do
	local x, z, length, yaw = w[1], w[2], w[3], w[4]
	local turn = CFrame.Angles(0, yaw, 0)
	local wall = wallTemplate:Clone()
	wall.Size = Vector3.new(8, 48, length)
	wall.CFrame = CFrame.new(x, 24, z) * turn
	wall:SetAttribute("World3Wall", true)
	wall.Parent = W.Walls
	local cap = capTemplate:Clone()
	cap.Size = Vector3.new(10, 2, length)
	cap.CFrame = CFrame.new(x, 49, z) * turn
	cap:SetAttribute("World3Wall", true)
	cap.Parent = W.Walls
end
return string.format("cleared %d floor parts, %d walls, %d obstacles/props; laid %d wall pieces to z %d",
	cleared.floor, cleared.walls, cleared.things, #WALLS, END)
