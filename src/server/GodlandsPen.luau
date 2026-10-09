-- The Godlands pen (QM, Oct 6): the biggest pen's fence in lava and dark stone,
-- with a band of studded dark stone round the inside of the fence on the snow
-- floor (PenLevel paints the floor in the Godlands' snow). Built from the pen's
-- biggest size at server start, so it lives in the repo and can't be lost from
-- the place (the hand-built one was, on Oct 5).
--
--   GodlandsPen.build(sizeModel) -- a copy of a pen's SizeK model (its markers too), restyled

local GodlandsPen = {}

local LAVA = { Color3.fromRGB(255, 72, 0), Color3.fromRGB(255, 120, 10) } -- Neon, the Godlands' lava
local DARK = Color3.fromRGB(62, 60, 72) -- dark stone (the Godlands' Stone patch and PostColor)
local DARK_EDGE = Color3.fromRGB(76, 74, 88)
local STUDS, STUD_TILE = "rbxassetid://7447638591", 0.5
local BORDER = 4 -- studs: one floor tile wide
local FLOOR_TOP = 0.3 -- PenLevel's floor
local MARKERS = { Spawn = true, Sign = true, Area = true, Tiles = true, Slots = true }

local function studs(part)
	local t = Instance.new("Texture")
	t.Name = "Studs"
	t.Texture = STUDS
	t.Face = Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = STUD_TILE, STUD_TILE
	t.Transparency = 0.6
	t.Parent = part
end

local function slab(parent, name, size, cframe, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery, p.CanTouch = false, false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Color = color
	p.Size = size
	p.CFrame = cframe
	studs(p)
	p.Parent = parent
	return p
end

function GodlandsPen.build(sizeModel)
	local model = sizeModel:Clone()
	local k = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not MARKERS[part.Name] and not (part.Parent and part.Parent.Name == "Slots") then
			if part.Name == "Rail" then
				k += 1
				part.Material = Enum.Material.Neon
				part.Color = LAVA[k % 2 + 1]
			elseif part.Name == "Brace" then
				part.Material = Enum.Material.SmoothPlastic
				part.Color = DARK_EDGE
			end -- (Posts: PenLevel paints them the Godlands' PostColor, dark stone)
		end
	end
	-- Studded dark stone round the inside of the fence.
	local tiles = model:FindFirstChild("Tiles")
	if tiles then
		local s, c = tiles.Size, tiles.Position
		local h = 0.2 -- standing a little proud of the floor
		local function strip(dx, dz, sx, sz)
			slab(model, "Border", Vector3.new(sx, h, sz), CFrame.new(c.X, FLOOR_TOP + h / 2, c.Z) * tiles.CFrame.Rotation * CFrame.new(dx, 0, dz), DARK) -- (in the pen's frame)
		end
		strip(0, -(s.Z - BORDER) / 2, s.X, BORDER)
		strip(0, (s.Z - BORDER) / 2, s.X, BORDER)
		strip(-(s.X - BORDER) / 2, 0, BORDER, s.Z - 2 * BORDER)
		strip((s.X - BORDER) / 2, 0, BORDER, s.Z - 2 * BORDER)
	end
	model:SetAttribute("Godlands", true)
	return model
end

return GodlandsPen
