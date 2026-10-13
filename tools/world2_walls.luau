-- Run in Studio (Edit, execute_luau) on the place with World2, after the floors
-- (tools/world2_*.luau). Re-running is fine.
-- World 2's walls (QM, Oct 13):
--   * Engravings on the inside face of each wall: gold Greek keys and panels in the base's
--     and the Meadow's marble, and lapis, red and bronze glyphs in the Ancient Tomb's gold.
--     Each is a Texture named "Engraving" over the wall's checker (no parts), from the
--     see-through pixel art tools/world2_walls.py draws (assets/world2/WallMarble.png,
--     WallTomb.png): upload those and put their ids in ENGRAVE below first.
--   * The Crimson Lands' wall colours (the others' are painted by
--     their floor scripts). In game the walls take Config's WallColors and CapColor; these
--     only show them here in Edit.
local W = workspace.World2
local OFFSET = 1000
local rgb = Color3.fromRGB
local PERIOD, HEIGHT = 64, 48 -- each image's studs along and up (the wall's height)
-- { near z, far z, image }: walls whose middle is in near..far (the base's are z > 0)
local ENGRAVE = {
	{ math.huge, -2168, "rbxassetid://0" }, -- WallMarble.png: the base and the Meadow
	{ -14064, -21744, "rbxassetid://0" }, -- WallTomb.png: the Ancient Tomb
}
-- { near z, far z, wall, checker, cap }
local PAINT = {
	{ -2168, -3984, rgb(91, 50, 54), rgb(82, 44, 48), rgb(72, 39, 42) }, -- the Crimson Lands: dark rose stone
	-- (the Woodland Maze: QM set its own in Studio, dark brown with autumn-leaf tops; Config keeps them)
}
-- If the engravings jump where one wall part meets the next along a wall, set this to -1.
local FLIP = 1
local BASE_MIDDLE = Vector3.new(OFFSET, 24, 128) -- the base's walls face it

local function within(z, list)
	for _, r in list do
		if z <= r[1] and z > r[2] then
			return r
		end
	end
	return nil
end

-- The face of a wall that looks in at the course (or the base), its world normal and length.
local function insideFace(p)
	local target = if p.Position.Z > -8 then BASE_MIDDLE else Vector3.new(OFFSET, p.Position.Y, p.Position.Z)
	local alongX = p.Size.X > p.Size.Z -- (its long side)
	local ids = if alongX then { Enum.NormalId.Front, Enum.NormalId.Back } else { Enum.NormalId.Right, Enum.NormalId.Left }
	local best, normal
	for _, id in ids do
		local n = p.CFrame:VectorToWorldSpace(Vector3.FromNormalId(id))
		if not normal or n:Dot(target - p.Position) > normal:Dot(target - p.Position) then
			best, normal = id, n
		end
	end
	return best, normal, if alongX then p.Size.X else p.Size.Z
end

local engraved, painted = 0, 0
for _, p in W.Walls:GetChildren() do
	if not p:IsA("BasePart") then
		continue
	end
	local z = p.Position.Z
	local paint = within(z, PAINT)
	if paint then
		if p.Name == "Cap" then
			p.Color = paint[5]
		else
			p.Color = paint[3]
			for _, t in p:GetChildren() do
				if t.Name == "Checker" then
					t.Color3 = paint[4]
				end
			end
		end
		painted += 1
	end
	local old = p:FindFirstChild("Engraving")
	if old then
		old:Destroy()
	end
	local engrave = within(z, ENGRAVE)
	if engrave and p.Name == "Wall" then
		local face, normal, length = insideFace(p)
		-- A texture's U runs to the right as you look at the face (upright, from outside).
		-- Each starts its tile where its face starts, so offset it by where that is along
		-- the wall, and the pattern runs on unbroken from one part to the next.
		local u = (-normal):Cross(Vector3.yAxis)
		local start = p.Position:Dot(u) - length / 2
		local t = Instance.new("Texture")
		t.Name = "Engraving"
		t.Texture = engrave[3]
		t.Face = face
		t.StudsPerTileU, t.StudsPerTileV = PERIOD, HEIGHT
		t.OffsetStudsU = (-FLIP * start) % PERIOD
		t.OffsetStudsV = 0
		t.ZIndex = 2 -- (over the checker)
		t.Parent = p
		engraved += 1
	end
end
return string.format("%d walls engraved, %d walls and caps painted", engraved, painted)
