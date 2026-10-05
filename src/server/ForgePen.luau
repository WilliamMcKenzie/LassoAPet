-- The Badlands pen (QM, Oct 5, take C of tools/badlands_pen.py): a small forge. A
-- low studded red stone wall with battlements, a lava channel round the inside,
-- a gate arch with a lava seam and lava running down its pillars, and a pillar
-- with a lava pot on each corner.
--
--   ForgePen.build(sizeModel) -- a copy of a pen's SizeK model (its markers) with the forge for its fence

local ForgePen = {}

local GATE = 10 -- the gap's width (tools/pens.py GATE)
local STONE = { Color3.fromRGB(78, 38, 29), Color3.fromRGB(88, 43, 32) }
local DARK = { Color3.fromRGB(62, 28, 22), Color3.fromRGB(74, 34, 26) }
local LAVA = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) } -- the Godlands' lava (QM)
local STUDS, STUD_TILE = "rbxassetid://7447638591", 0.5
local MIN_STUD_FACE = 0.75
local STUD_FACES = {
	{ Enum.NormalId.Right, "Y", "Z" },
	{ Enum.NormalId.Top, "X", "Z" },
	{ Enum.NormalId.Back, "X", "Y" },
	{ Enum.NormalId.Left, "Y", "Z" },
	{ Enum.NormalId.Front, "X", "Y" },
}
local MARKERS = { Spawn = true, Sign = true, Area = true, Tiles = true, Slots = true }

local function block(parent, frame, name, lo, hi, color, glow)
	local size = hi - lo
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = not glow
	p.CanTouch, p.CanQuery = false, false
	p.CastShadow = not glow
	p.Size = size
	p.CFrame = frame * CFrame.new((lo + hi) / 2)
	p.Color = color
	p.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if not glow then
		for _, face in STUD_FACES do
			if math.min(size[face[2]], size[face[3]]) >= MIN_STUD_FACE then
				local t = Instance.new("Texture")
				t.Name = "Studs"
				t.Texture = STUDS
				t.Face = face[1]
				t.StudsPerTileU, t.StudsPerTileV = STUD_TILE, STUD_TILE
				t.Parent = p
			end
		end
	end
	p.Parent = parent
	return p
end

function ForgePen.build(size)
	local model = size:Clone()
	for _, child in model:GetChildren() do
		if not MARKERS[child.Name] then
			child:Destroy()
		end
	end
	model:SetAttribute("Forge", true)
	local tiles, spawn = model:FindFirstChild("Tiles"), model:FindFirstChild("Spawn")
	if not (tiles and spawn) then
		return model
	end
	-- The pen's own frame: centred on its tiles, the open side toward -Z (where its Spawn is).
	local centre = Vector3.new(tiles.Position.X, 0, tiles.Position.Z)
	local out = spawn.Position - centre
	out = if math.abs(out.X) > math.abs(out.Z) then Vector3.new(math.sign(out.X), 0, 0) else Vector3.new(0, 0, math.sign(out.Z))
	local frame = CFrame.lookAt(centre, centre + out)
	local s = math.min(tiles.Size.X, tiles.Size.Z)
	local h = s / 2 -- local x -h..h, z -h (the open side) .. h
	local V = Vector3.new
	local function wall(ax, az, bx, bz)
		local length = math.max(math.abs(bx - ax), math.abs(bz - az))
		local n = math.max(1, math.ceil(length / 4 - 1e-6))
		local alongX = math.abs(bx - ax) > math.abs(bz - az)
		for k = 0, n - 1 do
			local x0, z0 = ax + (bx - ax) * k / n, az + (bz - az) * k / n
			local x1, z1 = ax + (bx - ax) * (k + 1) / n, az + (bz - az) * (k + 1) / n
			local lo = if alongX then V(math.min(x0, x1), 0, z0 - 1) else V(x0 - 1, 0, math.min(z0, z1))
			local hi = if alongX then V(math.max(x0, x1), 0, z0 + 1) else V(x0 + 1, 0, math.max(z0, z1))
			for row = 0, 1 do
				block(model, frame, "ForgeWall", V(lo.X, row * 2, lo.Z), V(hi.X, row * 2 + 2, hi.Z), STONE[(k + row) % 2 + 1])
			end
			if k % 2 == 0 then -- a battlement every other block
				local c = (lo + hi) / 2
				block(model, frame, "Merlon", V(c.X - 1, 4, c.Z - 1), V(c.X + 1, 5.5, c.Z + 1), DARK[2])
			end
		end
	end
	local g = GATE / 2
	wall(-h, -h, -g, -h)
	wall(g, -h, h, -h)
	wall(-h, -h, -h, h)
	wall(h, -h, h, h)
	wall(-h, h, h, h)
	-- the lava channel just inside the wall, flush with the floor
	local a, b = 2, 3.5
	for _, r in {
		{ -h + a, -h + a, -g - 1, -h + b },
		{ g + 1, -h + a, h - a, -h + b },
		{ -h + a, -h + a, -h + b, h - a },
		{ h - b, -h + a, h - a, h - a },
		{ -h + a, h - b, h - a, h - a },
	} do
		block(model, frame, "Lava", V(r[1], 0.15, r[2]), V(r[3], 0.45, r[4]), LAVA[1], true)
	end
	-- the gate arch: two pillars, a beam with a lava seam, lava down the pillars
	for _, side in { -1, 1 } do
		local x = side * (g + 1.5)
		block(model, frame, "Pillar", V(x - 1.5, 0, -h - 1.5), V(x + 1.5, 10, -h + 1.5), DARK[1])
		block(model, frame, "Lava", V(x - side * 1.6 - 0.2, 2, -h - 2), V(x - side * 1.6 + 0.2, 9, -h - 1.2), LAVA[1], true)
	end
	block(model, frame, "Beam", V(-g - 3, 10, -h - 1.8), V(g + 3, 12.5, -h + 1.8), STONE[2])
	block(model, frame, "Lava", V(-g - 1, 10.9, -h - 2.15), V(g + 1, 11.5, -h - 1.75), LAVA[1], true)
	-- a pillar with a lava pot on each corner
	for _, c in { { -h, -h }, { h, -h }, { -h, h }, { h, h } } do
		block(model, frame, "Pillar", V(c[1] - 2, 0, c[2] - 2), V(c[1] + 2, 8, c[2] + 2), DARK[1])
		block(model, frame, "Bowl", V(c[1] - 2.5, 8, c[2] - 2.5), V(c[1] + 2.5, 9, c[2] + 2.5), STONE[2])
		block(model, frame, "Lava", V(c[1] - 2, 9, c[2] - 2), V(c[1] + 2, 9.6, c[2] + 2), LAVA[1], true)
	end
	return model
end

return ForgePen
