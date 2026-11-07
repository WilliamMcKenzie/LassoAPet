-- A block in the map's look (QM, Nov 7: the Top Earners frame and the LIMITEDS stand "more in
-- line with our theme"): matte, an 8-stud checker of a slightly different shade and the studs
-- on its faces, as Server/Map's walls and caps. Plain Parts, so nothing to upload.
--
--   VoxelBlock.new(name, parent, cframe, size, color, checker?, faces?)
--   VoxelBlock.at(parent, origin, name, x0, y0, z0, x1, y1, z1, color, checker?, faces?)
--     (a box between two corners in origin's space)

local StudStyle = require(script.Parent.StudStyle)

local CHECKER, STUDS = "rbxassetid://84747779882944", StudStyle.IMAGE
local ALL = Enum.NormalId:GetEnumItems()

local VoxelBlock = {}

-- a checker shade a little lighter than `color` (what the map's *Checker colours are)
function VoxelBlock.shade(color, k)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v * (k or 1.07), 0, 1))
end

local function texture(part, face, image, tile, color, z)
	local t = Instance.new("Texture")
	t.Name = if image == STUDS then "Studs" else "Checker"
	t.Face, t.Texture = face, image
	t.StudsPerTileU, t.StudsPerTileV = tile, tile
	t.ZIndex = z
	if color then
		t.Color3 = color
	end
	if image == STUDS then
		t.Transparency = StudStyle.transparency()
	end
	t.Parent = part
end

function VoxelBlock.new(name, parent, cframe, size, color, checker, faces)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size, p.CFrame = size, cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.MaterialVariant = "Matte" -- (Server/Map makes it: no white glare off the sun)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CastShadow = true
	for _, face in faces or ALL do
		if checker ~= false then
			texture(p, face, CHECKER, 8, checker or VoxelBlock.shade(color), 1)
		end
		texture(p, face, STUDS, 1, nil, 2)
	end
	p.Locked = true
	p.Parent = parent
	return p
end

function VoxelBlock.at(parent, origin, name, x0, y0, z0, x1, y1, z1, color, checker, faces)
	x0, x1 = math.min(x0, x1), math.max(x0, x1)
	y0, y1 = math.min(y0, y1), math.max(y0, y1)
	z0, z1 = math.min(z0, z1), math.max(z0, z1)
	return VoxelBlock.new(
		name,
		parent,
		origin * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
		Vector3.new(x1 - x0, y1 - y0, z1 - z0),
		color,
		checker,
		faces
	)
end

return VoxelBlock
