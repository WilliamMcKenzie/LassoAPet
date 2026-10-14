-- World 3 (QM, Oct 14): the light sand (Ground) a stud above the dark (WetSand). Under the
-- pens (their biggest size) dark sand turns light, so a pen's floor sits flat on it; the pens,
-- the spawn and the portal go up the stud with it. Run once (it checks: GroundLifted).
local W = workspace.World
if W:GetAttribute("GroundLifted") then return "already lifted" end
local LIGHT = { Color3.fromRGB(240, 218, 160), Color3.fromRGB(230, 206, 146) }
local feet = {}
for _, pen in workspace.Pens:GetChildren() do
	local t = pen.Sizes.Size13.Tiles
	table.insert(feet, { t.CFrame, t.Size })
end
local function underPen(x, z, m)
	for _, f in feet do
		local p = f[1]:PointToObjectSpace(Vector3.new(x, f[1].Position.Y, z))
		if math.abs(p.X) < f[2].X / 2 + m and math.abs(p.Z) < f[2].Z / 2 + m then return true end
	end
	return false
end
local split, turned = 0, 0
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("ArcBase") and p.Name == "WetSand" then
		local lo = p.Position - p.Size / 2
		local any = false
		for x = lo.X + 4, lo.X + p.Size.X, 8 do for z = lo.Z + 4, lo.Z + p.Size.Z, 8 do if underPen(x, z, 4) then any = true end end end
		if any then
			for x = lo.X + 4, lo.X + p.Size.X, 8 do
				for z = lo.Z + 4, lo.Z + p.Size.Z, 8 do
					local c = p:Clone()
					c.Size = Vector3.new(8, p.Size.Y, 8)
					c.Position = Vector3.new(x, p.Position.Y, z)
					if underPen(x, z, 4) then
						c.Name = "Ground"
						c.Color = LIGHT[1]
						for _, t in c:GetChildren() do if t.Name == "Checker" then t.Color3 = LIGHT[2] end end
						turned += 1
					end
					c.Parent = W.Ground
				end
			end
			p:Destroy()
			split += 1
		end
	end
end
local lifted = 0
for _, p in W.Ground:GetChildren() do
	if p:IsA("BasePart") and p:GetAttribute("ArcBase") and p.Name == "Ground" then
		p.Size += Vector3.new(0, 1, 0)
		p.Position += Vector3.new(0, 0.5, 0)
		lifted += 1
	end
end
for _, d in workspace.Pens:GetDescendants() do
	if d:IsA("BasePart") then d.Position += Vector3.new(0, 1, 0) end
end
local sp = W:FindFirstChild("SpawnLocation", true)
if sp then sp.Position += Vector3.new(0, 1, 0) end
local gate = W.BaseDecor:FindFirstChild("PortalGate")
if gate then gate:PivotTo(gate:GetPivot() + Vector3.new(0, 1, 0)) end
W:SetAttribute("GroundLifted", true)
return string.format("%d dark sand pieces under pens split, %d cells turned light, %d light sand parts lifted", split, turned, lifted)
