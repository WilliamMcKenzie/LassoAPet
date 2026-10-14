-- World 3's stone walls (QM, Oct 14): tools/world3_runes.py's carved rune band as a Texture named
-- "Engraving" on the inside face of every wall part of the base and Pirate Cove (the course's Walls
-- and the base's BaseWallLow/Mid/BaseWall), lined up along each wall and at the same height
-- whatever band a part is. Re-running is fine. Run in Studio (Edit, execute_luau) on World 3.
local W = workspace.World.Walls
local IMAGE = "rbxassetid://114990465586883" -- assets/world3/WallRunes.png
local PERIOD, HEIGHT = 64, 48
local ZMIN = -4336
local names = { Wall = true, BaseWallLow = true, BaseWallMid = true, BaseWall = true }
-- the base's middle, which its walls face
local sum, n = Vector3.zero, 0
for _, p in W:GetChildren() do
	if p:IsA("BasePart") and p.Name:find("^Base") then sum += p.Position; n += 1 end
end
local baseMiddle = if n > 0 then sum / n else Vector3.new(0, 24, 128)
local done = 0
for _, p in W:GetChildren() do
	if not (p:IsA("BasePart") and names[p.Name] and p.Position.Z > ZMIN) then continue end
	local old = p:FindFirstChild("Engraving")
	if old then old:Destroy() end
	local target = if p.Name:find("^Base") then Vector3.new(baseMiddle.X, p.Position.Y, baseMiddle.Z) else Vector3.new(0, p.Position.Y, p.Position.Z)
	-- (whichever side faces in: a one-column part is as wide as it is thick, so don't guess from its size)
	local ids = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Right, Enum.NormalId.Left }
	local face, normal
	for _, id in ids do
		local nrm = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id))
		if not normal or nrm:Dot(target - p.Position) > normal:Dot(target - p.Position) then face, normal = id, nrm end
	end
	local length = if face == Enum.NormalId.Front or face == Enum.NormalId.Back then p.Size.X else p.Size.Z
	local u = (-normal):Cross(Vector3.yAxis)
	local start = p.Position:Dot(u) - length / 2
	local top = p.Position.Y + p.Size.Y / 2
	local t = Instance.new("Texture")
	t.Name = "Engraving"
	t.Texture = IMAGE
	t.Face = face
	t.StudsPerTileU, t.StudsPerTileV = PERIOD, HEIGHT
	t.OffsetStudsU = (-start) % PERIOD
	t.OffsetStudsV = (HEIGHT - top) % HEIGHT -- (so the band sits at the same height on every part, whatever its top)
	t.ZIndex = 2
	t.Parent = p
	done += 1
end
return done .. " walls engraved"
