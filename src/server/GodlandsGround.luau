-- The Godlands floor (QM, Oct 3): its tracks (GodlandsTracks, from
-- tools/godlands_concept.py) laid end to end in a random order each time the
-- server starts, so a run gets some ice stretches and some lava ones. World.server
-- builds it into World.Ground before the world is marked ready.
--
-- Each track is one snow floor part with dark stone plates a stud up and the
-- track's liquid (ice, or glowing lava) flush on top of it; WorldColors paints
-- them by name like the other biomes' patches (Config.Biomes Godlands.Patches).
-- Terrain pieces saved on flat floor that land on a stone tile are lifted onto it.
--
--   GodlandsGround.build(world, zStart, length) -- zStart: the biome's near edge

local Tracks = require(script.Parent.GodlandsTracks)

local CHECKER = "rbxassetid://84747779882944" -- the floor's 4-stud checker (every Ground part's "Checker")
local STUDS = "rbxassetid://7447638591"
local STONE_UP = 1
local LIQUID_TOP = 0.05 -- the ice and lava sit just over the snow
-- The checker texture tiles from one corner of a part's top face, so a part that
-- starts on an odd 4-stud tile gets its checker shifted to line up with the rest
-- of the floor. This is the corner it starts from: -1 = the low x / low z side.
-- (If the checker breaks along part edges in the Godlands, flip these.)
local ORIGIN_X, ORIGIN_Z = -1, -1

local GodlandsGround = {}

local function texture(part, image, studs, offset, zIndex)
	local t = Instance.new("Texture")
	t.Name = if image == CHECKER then "Checker" else "Texture"
	t.Texture = image
	t.Face = Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = studs, studs
	t.OffsetStudsU = offset
	t.ZIndex = zIndex
	t.Parent = part
end

-- One floor part covering x0..x1, z1..z0 (z0 > z1), its top at `top`.
local function floorPart(name, x0, x1, z0, z1, top, bottom, folder)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Inlet
	for _, side in { "Front", "Back", "Left", "Right" } do
		p[side .. "Surface"] = Enum.SurfaceType.Studs
	end
	if name == "Lava" then
		p.Material = Enum.Material.Neon
	end
	p.Size = Vector3.new(x1 - x0, top - bottom, z0 - z1)
	p.CFrame = CFrame.new((x0 + x1) / 2, (top + bottom) / 2, (z0 + z1) / 2)
	local cx = if ORIGIN_X < 0 then x0 else x1
	local cz = if ORIGIN_Z < 0 then z1 else z0
	local odd = (math.floor(cx / Tracks.Tile + 0.5) + math.floor(cz / Tracks.Tile + 0.5)) % 2
	texture(p, CHECKER, Tracks.Tile * 2, odd * Tracks.Tile, 1)
	texture(p, STUDS, 1, 0, 2)
	p.Parent = folder
	return p
end

-- Greedy merge of a grid's tiles of one glyph into rectangles: { i0, j0, i1, j1 }, ends exclusive.
local function rects(rows, glyph)
	local nz, nx = #rows, #rows[1]
	local done = {}
	local function at(i, j)
		return not done[j * 64 + i] and string.sub(rows[j], i, i) == glyph
	end
	local out = {}
	for i = 1, nx do
		for j = 1, nz do
			if at(i, j) then
				local j1 = j
				while j1 <= nz and at(i, j1) do
					j1 += 1
				end
				local i1 = i + 1
				while i1 <= nx do
					local all = true
					for jj = j, j1 - 1 do
						if not at(i1, jj) then
							all = false
							break
						end
					end
					if not all then
						break
					end
					i1 += 1
				end
				for ii = i, i1 - 1 do
					for jj = j, j1 - 1 do
						done[jj * 64 + ii] = true
					end
				end
				table.insert(out, { i, j, i1, j1 })
			end
		end
	end
	return out
end

function GodlandsGround.build(world, zStart, length)
	local folder = world.Ground
	local rng = Random.new()
	local order = {}
	for k = 1, #Tracks.Tracks do
		table.insert(order, rng:NextInteger(1, k), k) -- a shuffle: every track once, in a random order
	end
	local tile = Tracks.Tile
	local halfWidth = #Tracks.Grids[1][1] * tile / 2
	local placed = {} -- { z0, z1, rows } per track laid
	local slot = 0
	while slot * Tracks.Length < length do
		local track = Tracks.Tracks[order[slot % #order + 1]]
		local rows = Tracks.Grids[track.Grid]
		local z0 = zStart - slot * Tracks.Length
		floorPart("Ground", -halfWidth, halfWidth, z0, z0 - Tracks.Length, 0, -2, folder)
		for _, kind in { { "#", "Stone", STONE_UP, -2 }, { "~", track.Liquid, LIQUID_TOP, -LIQUID_TOP } } do
			for _, r in rects(rows, kind[1]) do
				local x0, x1 = -halfWidth + (r[1] - 1) * tile, -halfWidth + (r[3] - 1) * tile
				local za, zb = z0 - (r[2] - 1) * tile, z0 - (r[4] - 1) * tile
				floorPart(kind[2], x0, x1, za, zb, kind[3], kind[4], folder)
			end
		end
		table.insert(placed, { z0 = z0, rows = rows })
		slot += 1
	end
	world:SetAttribute("GodlandsTracks", table.concat(order, ","))

	-- Terrain pieces on stone stand on it.
	local zEnd = zStart - length
	for _, model in world.Obstacles:GetChildren() do
		local base = model:IsA("Model") and model:FindFirstChild("Base")
		local z = base and base.Position.Z
		if z and z < zStart and z > zEnd then
			local t = placed[math.floor((zStart - z) / Tracks.Length) + 1]
			local row = t and t.rows[math.floor((t.z0 - z) / tile) + 1]
			local i = math.floor((base.Position.X + halfWidth) / tile) + 1
			if row and string.sub(row, i, i) == "#" then
				model:PivotTo(model:GetPivot() + Vector3.new(0, STONE_UP, 0))
			end
		end
	end
end

return GodlandsGround
