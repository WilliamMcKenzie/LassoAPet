-- Particle auras on animals (QM, Nov 6): the "Aura Pack Premium" Toolbox pack's (asset
-- 75779654972403, by Sanzzzzz) emitters rebuilt here, recoloured, on an invisible box over
-- the animal's body so they flare all along it (the pack's are for an R15 character, about
-- 5 studs tall: sizes, speeds and pulls scale by the animal's height over that).
-- Config.Auras[kind] names the aura an animal wears; Animals/Horse adds it as it builds one.
--
--   Auras.attach(model, kind)  -- adds Config.Auras[kind]'s aura to a freshly built animal

local Config = require(script.Parent.Config)

local Auras = {}

local CHARACTER = 5 -- studs: the R15 character the pack's numbers are for

local function seq(points)
	local keys = {}
	for _, p in points do
		table.insert(keys, ColorSequenceKeypoint.new(p[1], Color3.fromRGB(p[2], p[3], p[4])))
	end
	return ColorSequence.new(keys)
end

local function nums(points, k)
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2] * (k or 1), (p[3] or 0) * (k or 1)))
	end
	return NumberSequence.new(keys)
end

-- the Saiyan aura (5 emitters), in the Alpha Snake's glowing green instead of orange
local GREEN = seq({ { 0, 210, 255, 190 }, { 0.215, 140, 255, 120 }, { 0.61, 90, 240, 90 }, { 1, 20, 150, 40 } })
local GREEN_FLARE = seq({ { 0, 40, 255, 80 }, { 0.052, 170, 255, 120 }, { 0.304, 70, 240, 90 }, { 1, 20, 150, 40 } })
local FLAME_ALPHA = { { 0, 1 }, { 0.0296, 0.3825 }, { 0.1195, 0.1475 }, { 0.4846, 0 }, { 0.7708, 0.2514 }, { 0.9068, 0.5738 }, { 1, 1 } }
local SPARK_SIZE = { { 0, 0 }, { 0.1438, 0.2516 }, { 0.3522, 1.761, 0.5346 }, { 0.8359, 0.1258 }, { 1, 0 } }
local SPARK_ALPHA = { { 0, 1 }, { 0.181, 0.15 }, { 0.3221, 0 }, { 0.6518, 0.175 }, { 0.8558, 0.8625 }, { 1, 1 } }
local AURAS = {
	SaiyanGreen = {
		{ -- the body's flames
			Texture = "rbxassetid://13013256540", Color = GREEN,
			Size = { { 0, 0 }, { 0.0915, 1.3798 }, { 0.2351, 2.7065 }, { 1, 4.3516 } }, Transparency = FLAME_ALPHA,
			Lifetime = NumberRange.new(0.1, 0.5), Rate = 25, Speed = 0.066, Rotation = NumberRange.new(-180, 180),
			Acceleration = 38.4856, LightEmission = -5, Brightness = 60, ZOffset = -2,
			Orientation = Enum.ParticleOrientation.FacingCamera, Flipbook = Enum.ParticleFlipbookLayout.Grid4x4,
		},
		{ -- sparks shooting up
			Texture = "rbxassetid://17006181290", Color = GREEN_FLARE, Size = SPARK_SIZE, Transparency = SPARK_ALPHA,
			Lifetime = NumberRange.new(0.2, 0.5), Rate = 200, Speed = NumberRange.new(20, 50), Spread = Vector2.new(180, -180),
			Rotation = NumberRange.new(90), Acceleration = 475, Drag = 10, VelocityInheritance = 1, TimeScale = 0.5,
			LightEmission = -5, Brightness = 15, ZOffset = 0.95, LockedToPart = true,
			Orientation = Enum.ParticleOrientation.VelocityParallel, Flipbook = Enum.ParticleFlipbookLayout.Grid4x4,
		},
		{ -- the big flames behind
			Texture = "rbxassetid://13013256540", Color = GREEN,
			Size = { { 0, 0 }, { 0.0915, 1.9869 }, { 0.2351, 3.8973 }, { 1, 6.2663 } }, Transparency = FLAME_ALPHA,
			Lifetime = NumberRange.new(0.1, 0.5), Rate = 25, Speed = 0.096, Rotation = NumberRange.new(-180, 180),
			Acceleration = 55.4193, LightEmission = 0, Brightness = 15, ZOffset = 1,
			Orientation = Enum.ParticleOrientation.FacingCamera, Flipbook = Enum.ParticleFlipbookLayout.Grid4x4,
		},
		{ -- streaks
			Texture = "rbxassetid://8133845150", Color = GREEN_FLARE, Size = SPARK_SIZE, Transparency = SPARK_ALPHA,
			Lifetime = NumberRange.new(0.2, 0.25), Rate = 200, Speed = NumberRange.new(20, 50), Spread = Vector2.new(180, -180),
			Rotation = NumberRange.new(90), Acceleration = 475, Drag = 10, VelocityInheritance = 1, TimeScale = 0.5,
			LightEmission = 1, Brightness = 15, ZOffset = 0.95, LockedToPart = true,
			Orientation = Enum.ParticleOrientation.VelocityParallel, Loop = true,
		},
		{ -- the glow
			Texture = "rbxassetid://116213970344441", Color = seq({ { 0, 90, 240, 90 }, { 1, 90, 240, 90 } }),
			Size = { { 0, 4.9005 }, { 1, 4.9005 } }, Transparency = { { 0, 1 }, { 0.5088, 0.2842 }, { 1, 1 } },
			Lifetime = NumberRange.new(0.2), Rate = 10, Speed = 0.098, Rotation = NumberRange.new(0),
			LightEmission = 0.5, Brightness = 5, ZOffset = 0,
			Orientation = Enum.ParticleOrientation.FacingCameraWorldUp, Flipbook = Enum.ParticleFlipbookLayout.Grid2x2,
		},
	},
}

function Auras.attach(model, kind)
	local aura = AURAS[Config.Auras and Config.Auras[kind] or ""]
	local root = model.PrimaryPart
	if not aura or not root then
		return nil
	end
	local cf, size = model:GetBoundingBox()
	local k = math.max(size.Y, math.max(size.X, size.Z) * 0.4) / CHARACTER
	local box = Instance.new("Part")
	box.Name = "Aura"
	box.Transparency = 1
	box.CanCollide, box.CanQuery, box.CanTouch = false, false, false
	box.Massless = true
	box.Anchored = false
	box.Size = size * 0.8
	box.CFrame = cf
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, box
	weld.Parent = box
	for i, e in aura do
		local p = Instance.new("ParticleEmitter")
		p.Name = "Aura" .. i
		p.Texture = e.Texture
		p.Color = e.Color
		p.Size = nums(e.Size, k)
		p.Transparency = nums(e.Transparency)
		p.Lifetime = e.Lifetime
		p.Rate = e.Rate
		p.Speed = if typeof(e.Speed) == "NumberRange" then NumberRange.new(e.Speed.Min * k, e.Speed.Max * k) else NumberRange.new(e.Speed * k)
		p.SpreadAngle = e.Spread or Vector2.zero
		p.Rotation = e.Rotation
		p.Acceleration = Vector3.new(0, (e.Acceleration or 0) * k, 0)
		p.Drag = e.Drag or 0
		p.VelocityInheritance = e.VelocityInheritance or 0
		p.TimeScale = e.TimeScale or 1
		p.LightEmission = e.LightEmission
		p.LightInfluence = 0
		p.Brightness = e.Brightness
		p.ZOffset = e.ZOffset
		p.LockedToPart = e.LockedToPart == true
		p.Orientation = e.Orientation
		p.EmissionDirection = Enum.NormalId.Top
		p.Shape = Enum.ParticleEmitterShape.Box
		p.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		if e.Flipbook then
			p.FlipbookLayout = e.Flipbook
			p.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		elseif e.Loop then
			p.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		end
		p.Parent = box
	end
	box.Parent = model
	return box
end

return Auras
