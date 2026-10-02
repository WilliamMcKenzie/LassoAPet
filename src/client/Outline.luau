-- The marker on whatever the lasso would catch (an animal or the egg) or RIDE
-- would ride: a dashed white ring on the ground round it, slowly turning (QM's
-- reference, Oct 2).
--
-- (It used to be a Highlight outline. Moving a Highlight onto another model makes
-- the engine redraw that whole model, studs and all, which hitched hard on phones:
-- sprinting past the herd moved it several times a second. The dashes are handle
-- adornments, drawn on their own, so moving and turning them costs next to nothing.)
--
--   Outline.set(model, fit) -- mark this model; nil clears it. fit (optional):
--                           -- { lift, radius } overrides, e.g. Outline.NEST
--   Outline.ring(model, color) -- a ring of its own round this model (:Destroy() it when done)
--   Outline.box(model) -- its bounding box as (CFrame from its root, size), measured once

local RunService = game:GetService("RunService")

local COLOR = Color3.new(1, 1, 1) -- white (QM)
local TRANSPARENCY = 0.2 -- 80% opaque
local DASHES = 10
local DASH_SHARE = 0.6 -- of each dash's slot round the ring; the rest is the gap
local SPIN = 0.8 -- radians a second
local LIFT = 0.15 -- studs above the model's root (animals' and eggs' roots are at their feet)

-- [model] = { scale, box, size }: a model's bounding box from its root, measured
-- once (measuring walks every block, too slow to do every frame for every pet)
-- and again only if the model is rescaled. Animation moves the real box a little.
local boxes = setmetatable({}, { __mode = "k" })

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

local spinning = {} -- [ring] = true, every ring that's showing
local spin = 0

local Ring = {}
Ring.__index = Ring

-- A ring of DASHES arcs (cylinder adornments cut to an Angle), hidden until fitted.
local function newRing(color)
	local r = setmetatable({ dashes = {}, base = CFrame.identity }, Ring)
	for _ = 1, DASHES do
		local dash = Instance.new("CylinderHandleAdornment")
		dash.Name = "RingDash"
		dash.Color3 = color or COLOR
		dash.Transparency = TRANSPARENCY
		dash.Height = 0.1
		dash.Angle = 360 / DASHES * DASH_SHARE
		dash.AlwaysOnTop = false
		dash.Visible = false
		dash.Parent = workspace
		table.insert(r.dashes, dash)
	end
	return r
end

-- Turns the dashes to the ring's current spin.
function Ring:turn()
	for k, dash in self.dashes do
		dash.CFrame = self.base * CFrame.Angles(0, 0, spin + (k - 1) * 2 * math.pi / DASHES)
	end
end

-- Sizes the ring to go round `model` (whose root is `root`) and shows it there.
function Ring:fit(model, root, fit)
	local box, size = Outline.box(model)
	local radius = math.max(0.5 * math.max(size.X, size.Z) * 0.75 + 1, fit and fit.radius or 0)
	-- (A cylinder adornment runs along its Z axis: turned to lie flat.)
	self.base = CFrame.new(box.X, fit and fit.lift or LIFT, box.Z) * CFrame.Angles(math.pi / 2, 0, 0)
	for _, dash in self.dashes do
		dash.Radius = radius
		dash.InnerRadius = radius - math.clamp(radius * 0.12, 0.5, 2)
		dash.Adornee = root
		dash.Visible = true
	end
	self:turn()
	spinning[self] = true
end

function Ring:hide()
	spinning[self] = nil
	for _, dash in self.dashes do
		dash.Visible = false
		dash.Adornee = nil
	end
end

function Ring:Destroy()
	spinning[self] = nil
	for _, dash in self.dashes do
		dash:Destroy()
	end
end

RunService.RenderStepped:Connect(function(dt)
	spin = (spin + SPIN * dt) % (2 * math.pi)
	for r in spinning do
		r:turn()
	end
end)

local ring = newRing()
local target

function Outline.set(model, fit)
	if model == target then
		return
	end
	target = model
	local root = model and model.PrimaryPart
	if root then
		ring:fit(model, root, fit)
	else
		ring:hide()
	end
end

function Outline.ring(model, color)
	local r = newRing(color)
	if model.PrimaryPart then
		r:fit(model, model.PrimaryPart)
	end
	return r
end

return Outline
