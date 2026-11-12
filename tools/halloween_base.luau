-- The Halloween world's base (QM, Oct 15: "copying world 1 and modifying the base to fit way more
-- pens: same circular level design ... get rid of all assets for now in base, just the layout"):
-- run in Edit on the Halloween place (a copy of World 1). Re-running is fine.
--   - World.BaseDecor and the PortalStone go to ServerStorage.HalloweenStripped (kept, not deleted)
--   - the base grows from x -176..176, z 0..264 to x -W..W, z 0..D: its walls and caps moved,
--     its floor one Grass part (World 1's checker), the front opening (x -56..56) kept for the course
--   - ten pens (Pen1..Pen10: Pen6..10 copies of Pen1) on one arc round the yard's middle C, each
--     turned to face it, as World 1's five are round theirs (tools/pens.py)
local W, D = 310, 492
local C = Vector3.new(0, 0, 182) -- the yard's middle (the front pens just clear of the front wall)
local R = 210 -- each pen's gap from C
local ANGLES = {} -- degrees from +x toward +z: -30 .. 210, the front (the start line) left open
for i = 1, 10 do
	ANGLES[i] = -30 + (i - 1) * 240 / 9
end
-- World 1's arc (tools/pens.py): where each pen's gap is now, to move it from
local OLD_ARC = Vector3.new(0, 0, 96)
local OLD = { { 90, 78 }, { 140, 100 }, { 40, 100 }, { 190, 78 }, { -10, 78 } } -- { angle, gap radius } in claim order

local SS = game:GetService("ServerStorage")
local bin = SS:FindFirstChild("HalloweenStripped") or Instance.new("Folder")
bin.Name = "HalloweenStripped"
bin.Parent = SS
local world = workspace.World
for _, inst in { world:FindFirstChild("BaseDecor"), workspace:FindFirstChild("PortalStone") } do
	if inst then
		inst.Parent = bin
	end
end

-- The walls and their caps.
for _, p in world.Walls:GetChildren() do
	if p:IsA("BasePart") and (p:GetAttribute("W1Lo") or p.Position.Z + p.Size.Z / 2 > -1) then
		-- (World 1's extents, kept on the part the first time, so a re-run starts from them)
		if not p:GetAttribute("W1Lo") then
			p:SetAttribute("W1Lo", p.Position - p.Size / 2)
			p:SetAttribute("W1Hi", p.Position + p.Size / 2)
		end
		local lo, hi = p:GetAttribute("W1Lo"), p:GetAttribute("W1Hi")
		local function set(x0, x1, z0, z1)
			p.Size = Vector3.new(x1 - x0, p.Size.Y, z1 - z0)
			p.Position = Vector3.new((x0 + x1) / 2, p.Position.Y, (z0 + z1) / 2)
		end
		if hi.Z <= 2.5 and lo.X > 0 then -- the front, right of the opening
			set(lo.X, W + (hi.X - 176), lo.Z, hi.Z)
		elseif hi.Z <= 2.5 and hi.X < 0 then -- the front, left of it
			set(-W - (-176 - lo.X), hi.X, lo.Z, hi.Z)
		elseif lo.Z >= 262 then -- the back
			set(-W - (-176 - lo.X), W + (hi.X - 176), D + (lo.Z - 264), D + (hi.Z - 264))
		elseif lo.X >= 174 then -- the right side
			set(W + (lo.X - 176), W + (hi.X - 176), lo.Z, D + (hi.Z - 264))
		elseif hi.X <= -174 then -- the left side
			set(-W - (-176 - lo.X), -W - (-176 - hi.X), lo.Z, D + (hi.Z - 264))
		end
	end
end

-- The floor: World 1's base floor goes (kept), one Grass part in its place.
local floorBin = bin:FindFirstChild("BaseFloor") or Instance.new("Folder")
floorBin.Name = "BaseFloor"
floorBin.Parent = bin
local sample
for _, p in world.Ground:GetChildren() do
	if p:IsA("BasePart") and p.Position.Z > 0 and not p:GetAttribute("HalloweenBase") then
		if p.Name == "Grass" and not sample then
			sample = p
		end
		p.Parent = floorBin
	end
end
local floor
for _, p in world.Ground:GetChildren() do
	if p:GetAttribute("HalloweenBase") then
		floor = p
	end
end
floor = floor or (sample and sample:Clone()) or Instance.new("Part")
floor.Name = "Grass" -- (WorldColors paints it by name: the Meadow's grass)
floor:SetAttribute("HalloweenBase", true)
floor.Anchored = true
floor.Size = Vector3.new(2 * W, 2, D)
floor.Position = Vector3.new(0, -1, D / 2)
floor.Parent = world.Ground

-- The pens: Pen6..10 copies of Pen1, then every pen onto the new arc.
local pens = workspace.Pens
local function gateFrame(arc, angle, r)
	local a = math.rad(angle)
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local gate = arc + out * r
	return CFrame.lookAt(gate, gate - out)
end
local base1 = pens.Pen1
for i = 6, 10 do
	local old = pens:FindFirstChild("Pen" .. i)
	if old then
		old:Destroy()
	end
	local copy = base1:Clone()
	copy.Name = "Pen" .. i
	copy:SetAttribute("Owner", nil)
	copy:SetAttribute("HomeAngle", 90) -- (Pen1's spot, till it's moved below)
	copy.Parent = pens
end
for i = 1, 10 do
	local pen = pens["Pen" .. i]
	-- where it is: World 1's spot (Pen1's for the copies), or where this script put it last time
	local from = if pen:GetAttribute("HalloweenAngle") then gateFrame(Vector3.new(0, 0, pen:GetAttribute("HalloweenCZ") or 170), pen:GetAttribute("HalloweenAngle"), R)
		elseif i <= 5 then gateFrame(OLD_ARC, OLD[i][1], OLD[i][2])
		else gateFrame(OLD_ARC, OLD[1][1], OLD[1][2])
	local to = gateFrame(C, ANGLES[i], R)
	pen:PivotTo(to * from:Inverse() * pen:GetPivot())
	pen:SetAttribute("HalloweenAngle", ANGLES[i])
	pen:SetAttribute("HalloweenCZ", C.Z)
	pen:SetAttribute("HomeAngle", nil)
end
local spawn = world:FindFirstChild("SpawnLocation")
if spawn then
	spawn.Position = Vector3.new(0, spawn.Position.Y, C.Z)
end
return string.format("base x -%d..%d z 0..%d; %d pens; stripped %d", W, W, D, #pens:GetChildren(), #bin:GetChildren())
