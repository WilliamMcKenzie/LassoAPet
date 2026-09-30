-- The outline on whatever the lasso would catch (an animal or the egg).
--
--   Outline.set(model) -- outline this model; nil clears it
--   Outline.update()   -- every frame, after the target has moved
--
-- Config.LayeredOutline picks the style. Layered: a thin white line hugging the
-- target with a thicker black line around it. The white line is a Highlight.
-- Roblox draws Highlight lines at one fixed width and only on visible parts, so
-- the black line is an "inside-out hull": a black copy of each of the target's
-- blocks, puffed out by 2 * Config.OutlineWidth, with its mesh mirrored so only
-- its far (inside) faces draw. The target hides the middle of the hull, leaving a
-- black rim around its edges. The copies follow the blocks as they animate.
-- Off: the old thin yellow line.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local layered = Config.LayeredOutline
local HULL_COLOR = Color3.new(0, 0, 0)
local THIN = 0.2 -- plates thinner than this (eyes, patches) get no hull: its rim would stick out of the body

local inner = Instance.new("Highlight")
inner.FillTransparency = 1
inner.OutlineColor = Color3.new(1, 1, 1)
inner.OutlineTransparency = 0
inner.DepthMode = Enum.HighlightDepthMode.Occluded
inner.Enabled = false
inner.Parent = workspace

local hullModel = Instance.new("Model")
hullModel.Name = "OutlineHull"
hullModel.Parent = workspace

local target
local blocks = {} -- { part = the target's block, copy = its hull block }

local function hullBlock(part)
	local copy = Instance.new("Part")
	copy.Name = "Hull"
	copy.Anchored = true
	copy.CanCollide = false
	copy.CanQuery = false
	copy.CanTouch = false
	copy.CastShadow = false
	copy.Material = Enum.Material.SmoothPlastic
	copy.Color = HULL_COLOR
	copy.TopSurface = Enum.SurfaceType.Smooth
	copy.BottomSurface = Enum.SurfaceType.Smooth
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = if part:IsA("WedgePart") then Enum.MeshType.Wedge else Enum.MeshType.Brick
	-- Mirrored across X (blocks and wedges are symmetric that way): flips the
	-- faces inside out, so the near faces are culled and only the far ones draw.
	mesh.Scale = Vector3.new(-1, 1, 1)
	mesh.Parent = copy
	copy.Parent = hullModel
	return copy
end

local Outline = {}

function Outline.set(model)
	if model == target then
		return
	end
	target = model
	inner.Adornee = model
	inner.Enabled = model ~= nil
	table.clear(blocks)
	hullModel:ClearAllChildren()
	if not model or not layered then
		return
	end
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 1 then
			continue
		end
		local size = part.Size
		if math.min(size.X, size.Y, size.Z) < THIN then
			continue
		end
		table.insert(blocks, { part = part, copy = hullBlock(part) })
	end
	Outline.update()
end

function Outline.update()
	if not target then
		return
	end
	local puff = Vector3.one * (4 * Config.OutlineWidth)
	for _, b in blocks do
		b.copy.Size = b.part.Size + puff
		b.copy.CFrame = b.part.CFrame
	end
end

return Outline
