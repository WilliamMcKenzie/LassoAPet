-- World 3 stud steps (QM, Oct 15: "make stud differences in candyland and garden. Garden path
-- needs elevation. candyland everything not the cream ground needs elevation."): in place, after
-- the floor scripts. Garden's Path goes from top 1 to 2 (over its Grass at 1, Ground at 0);
-- every Candyland tile but Cream goes from top 1 to 2, and a Candyland prop standing on one goes
-- up with it. Each raised part keeps its bottom and grows a stud. Re-running is fine (only
-- tops at 1 move). Run in Edit, QM not in Play.
local W = workspace.World
local RISE = 1
local function biome(z)
	if z <= -4336 and z > -7968 then return "Garden" end
	if z <= -7968 and z > -11808 then return "Candyland" end
end
local raised, cells = 0, {}
for _, p in W.Ground:GetChildren() do
	local b = p:IsA("BasePart") and biome(p.Position.Z)
	local top = p:IsA("BasePart") and p.Position.Y + p.Size.Y / 2
	if b and math.abs(top - 1) < 0.01 and ((b == "Garden" and p.Name == "Path") or (b == "Candyland" and p.Name ~= "Cream")) then
		p.Size += Vector3.new(0, RISE, 0)
		p.Position += Vector3.new(0, RISE / 2, 0)
		raised += 1
		if b == "Candyland" then table.insert(cells, p) end
	end
end
-- (a prop over a raised Candyland tile: its pivot inside the tile's footprint)
local moved = 0
local function onRaised(pos)
	for _, p in cells do
		local lo, hi = p.Position - p.Size / 2, p.Position + p.Size / 2
		if pos.X >= lo.X and pos.X <= hi.X and pos.Z >= lo.Z and pos.Z <= hi.Z then return true end
	end
end
for _, folder in { W.Obstacles, W.Decor:FindFirstChild("Props") } do
	for _, m in folder and folder:GetChildren() or {} do
		if m:IsA("Model") and m:GetAttribute("World3Prop") == "Candyland" then
			local cf = m:GetPivot()
			if math.abs(cf.Y - 1) < 0.01 and onRaised(cf.Position) then
				m:PivotTo(cf + Vector3.new(0, RISE, 0))
				moved += 1
			end
		end
	end
end
return raised .. " tiles raised a stud, " .. moved .. " Candyland props raised with them"
