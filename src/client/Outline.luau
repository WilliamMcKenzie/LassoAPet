-- The marker on whatever the lasso would catch (an animal or the egg) or RIDE
-- would ride: a thin white ring on the ground round it.
--
-- (It used to be a Highlight outline. Moving a Highlight onto another model makes
-- the engine redraw that whole model, studs and all, which hitched hard on phones:
-- sprinting past the herd moved it several times a second. The ring is a handle
-- adornment, drawn on its own, so moving it costs nothing.)
--
--   Outline.set(model, fit) -- mark this model; nil clears it. fit (optional):
--                           -- { lift, radius } overrides, e.g. Outline.NEST
--   Outline.ring(model, color) -- a ring of its own round this model (Destroy it when done)
--   Outline.box(model) -- its bounding box as (CFrame from its root, size), measured once

local COLOR = Color3.new(1, 1, 1)
local LIFT = 0.15 -- studs above the model's root (animals' and eggs' roots are at their feet)

local ring = Instance.new("CylinderHandleAdornment")
ring.Name = "TargetRing"
ring.Color3 = COLOR
ring.Transparency = 0.1
ring.Height = 0.1
ring.AlwaysOnTop = false
ring.Visible = false
ring.Parent = workspace

-- [model] = { scale, box, size }: a model's bounding box from its root, measured
-- once (measuring walks every block, too slow to do every frame for every pet)
-- and again only if the model is rescaled. Animation moves the real box a little.
local boxes = setmetatable({}, { __mode = "k" })

local target

local Outline = {}

-- A nest egg's ring sits on the nest's rim (its top is ~1 stud above the egg's
-- base) and round the whole nest (~7 studs across), or it'd be hidden in the bowl.
Outline.NEST = { lift = 1.1, radius = 4.2 }

function Outline.box(model)
	local scale = model:GetScale()
	local cached = boxes[model]
	if not cached or cached.scale ~= scale then
		local box, size = model:GetBoundingBox()
		cached = { scale = scale, box = model.PrimaryPart.CFrame:ToObjectSpace(box), size = size }
		boxes[model] = cached
	end
	return cached.box, cached.size
end

-- Sizes ring `r` to go round `model` (whose root is `root`) and puts it there.
local function fitRing(r, model, root, fit)
	local box, size = Outline.box(model)
	local radius = math.max(0.5 * math.max(size.X, size.Z) * 0.75 + 1, fit and fit.radius or 0)
	r.Radius = radius
	r.InnerRadius = radius - math.clamp(radius * 0.12, 0.5, 2)
	-- (A cylinder adornment runs along its Z axis: turned to lie flat.)
	r.CFrame = CFrame.new(box.X, fit and fit.lift or LIFT, box.Z) * CFrame.Angles(math.pi / 2, 0, 0)
	r.Adornee = root
end

function Outline.set(model, fit)
	if model == target then
		return
	end
	target = model
	local root = model and model.PrimaryPart
	if not root then
		ring.Visible = false
		ring.Adornee = nil
		return
	end
	fitRing(ring, model, root, fit)
	ring.Visible = true
end

function Outline.ring(model, color)
	local r = ring:Clone()
	r.Name = "Ring"
	r.Color3 = color or COLOR
	if model.PrimaryPart then
		fitRing(r, model, model.PrimaryPart)
		r.Visible = true
	end
	r.Parent = workspace
	return r
end

return Outline
