-- Rebirth skins (QM, Oct 13): a rebirthed player's pets all wear their rebirth's skin,
-- the whole body (tools/rebirth_skins.py draws the same thing):
--   1 Gold   : bronze to gold, shiny, gold glints rising off it and a warm light
--   2 Diamond: ice blue to white, glassy, glittering shards round it, icy mist at its feet
--   3 Galaxy : deep violet to magenta, a pink and blue nebula round it and twinkling stars
-- Every part keeps its shape and studs; its colour comes off the skin's ramp at the part's
-- own brightness, so a dark mane stays darker than the body and the animal still reads as
-- itself. The googly eyes (Eye, Pupil) and Nostrils keep theirs; Neon parts glow the
-- skin's accent. The aura is ParticleEmitters and a PointLight round it: no Highlight.
--
--   Skins.apply(model, rebirths) -- after Fusion.paint, before setScale; 0/nil: nothing

local Skins = {}

-- The aura's particle images (tools/rebirth_auras.py: assets/particles/*.png). Till
-- they're uploaded ("") Roblox's own sparkles and smoke stand in.
local STAR = "rbxassetid://101417923883570" -- assets/particles/AuraStar.png
local SHARD = "rbxassetid://92755387446581" -- assets/particles/AuraShard.png
local PUFF = "rbxassetid://134638563995635" -- assets/particles/AuraPuff.png
local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Skins.Skins = {
	{
		name = "Gold",
		stops = { rgb(120, 74, 8), rgb(214, 150, 20), rgb(255, 206, 52), rgb(255, 238, 150) },
		span = { 0.15, 0.85 },
		glow = rgb(255, 230, 90),
		reflectance = 0.25,
		light = rgb(255, 200, 80),
	},
	{
		name = "Diamond",
		stops = { rgb(36, 118, 222), rgb(80, 196, 250), rgb(160, 232, 255), rgb(232, 250, 255) },
		span = { 0.1, 0.8 },
		facet = 0.18, -- (every other part a facet lighter)
		glow = rgb(150, 240, 255),
		material = Enum.Material.Glass,
		reflectance = 0.3,
		light = rgb(170, 230, 255),
	},
	{
		name = "Galaxy",
		stops = { rgb(18, 14, 52), rgb(52, 28, 120), rgb(110, 48, 170), rgb(190, 80, 200) },
		span = { 0.1, 0.75 },
		glow = rgb(90, 230, 255),
		light = rgb(180, 90, 255),
	},
}

local KEEP = { "Eye", "Pupil", "Nostril" }

local function kept(name)
	for _, prefix in KEEP do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function ramp(stops, t)
	t = math.clamp(t, 0, 1) * (#stops - 1)
	local i = math.min(math.floor(t), #stops - 2)
	return stops[i + 1]:Lerp(stops[i + 2], t - i)
end

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = "SkinAura"
	e.LightInfluence = 0
	e.SpreadAngle = Vector2.new(180, 180)
	e.Shape = Enum.ParticleEmitterShape.Box -- (filling the aura's box)
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	for key, value in props do
		e[key] = value
	end
	e.Parent = parent
	return e
end

local function size(s)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, s), NumberSequenceKeypoint.new(1, 0) })
end

-- The aura round a pet `extents` (its bounding box size) big: an invisible box over its
-- body, welded to its root (at its feet), that the emitters fill.
local function aura(root, skin, extents)
	local r = math.max(extents.X, extents.Z)
	local box = Instance.new("Part")
	box.Name = "SkinAura"
	box.Size = extents * 0.7
	box.Transparency = 1
	box.CanCollide, box.CanQuery, box.CanTouch, box.Massless, box.Anchored = false, false, false, true, false
	box.CFrame = root.CFrame * CFrame.new(0, extents.Y / 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, box
	weld.Parent = box
	box.Parent = root.Parent
	local light = Instance.new("PointLight")
	light.Color = skin.light
	light.Range = math.clamp(r * 1.5, 8, 30)
	light.Brightness = 1.2
	light.Parent = box
	local star = if STAR ~= "" then STAR else SPARKLES
	local puff = if PUFF ~= "" then PUFF else SMOKE
	if skin.name == "Gold" then
		emitter(box, { -- glints rising off it
			Texture = star, Color = ColorSequence.new(rgb(255, 222, 110)), Rate = 6,
			Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.5, 1.5),
			Acceleration = Vector3.new(0, 3, 0), Size = size(0.7), LightEmission = 1,
		})
	elseif skin.name == "Diamond" then
		emitter(box, { -- shards drifting round it
			Texture = if SHARD ~= "" then SHARD else SPARKLES,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(170, 235, 255)), ColorSequenceKeypoint.new(0.5, rgb(255, 220, 250)), ColorSequenceKeypoint.new(1, rgb(200, 255, 240)) }),
			Rate = 4, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(0.3, 1), Size = size(0.8),
			LightEmission = 0.6, RotSpeed = NumberRange.new(-60, 60), Rotation = NumberRange.new(0, 360),
		})
		emitter(box, { -- icy mist at its feet
			Texture = puff, Color = ColorSequence.new(rgb(210, 245, 255)), Rate = 3,
			Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(0.5, 1.5), Size = size(r * 0.35),
			Transparency = NumberSequence.new(0.7), Acceleration = Vector3.new(0, -2, 0),
		})
	else
		emitter(box, { -- the nebula
			Texture = puff,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 80, 220)), ColorSequenceKeypoint.new(0.5, rgb(150, 80, 255)), ColorSequenceKeypoint.new(1, rgb(90, 200, 255)) }),
			Rate = 3, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(0.2, 0.6), Size = size(r * 0.4),
			Transparency = NumberSequence.new(0.75), LightEmission = 0.8,
		})
		emitter(box, { -- twinkles
			Texture = star,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 255, 255)), ColorSequenceKeypoint.new(1, rgb(160, 240, 255)) }),
			Rate = 8, Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0, 0.5), Size = size(0.5),
			LightEmission = 1,
		})
	end
end

function Skins.apply(model, rebirths)
	local skin = model and rebirths and Skins.Skins[math.min(rebirths, #Skins.Skins)]
	if not skin or model:GetAttribute("Skin") then
		return
	end
	model:SetAttribute("Skin", skin.name)
	local lo, hi = skin.span[1], skin.span[2]
	local n = 0
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 1 or kept(part.Name) then
			continue
		end
		n += 1
		local color
		if part.Material == Enum.Material.Neon then
			color = skin.glow
		else
			local c = part.Color
			local t = lo + (hi - lo) * (0.3 * c.R + 0.55 * c.G + 0.15 * c.B)
			if skin.facet and n % 2 == 0 then
				t += skin.facet
			end
			color = ramp(skin.stops, t)
			part.Material = skin.material or part.Material
			part.Reflectance = skin.reflectance or 0
		end
		for _, texture in part:GetChildren() do
			if texture:IsA("Texture") and texture.Color3 == part.Color then -- (as Fusion.paint: only a tinted one)
				texture.Color3 = color
			end
		end
		part.Color = color
	end
	local root = model.PrimaryPart
	if root then
		local _, extents = model:GetBoundingBox()
		aura(root, skin, extents)
	end
end

return Skins
