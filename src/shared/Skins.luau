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
--   Skins.apply(animal, rebirths) -- after Fusion.paint; 0/nil: nothing. It also makes the pet
--                                 -- Config.Rebirth.Scale x bigger (QM: 1.5x, Animal:grow)

local Config = require(script.Parent.Config)

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
		-- (Oct 13: came out flat lemon yellow under the game's Lighting: deeper, toward amber,
		-- and a polished-metal texture of highlight and shadow bands and glints over it)
		stops = { rgb(92, 48, 0), rgb(168, 100, 8), rgb(212, 142, 22), rgb(240, 190, 70) },
		span = { 0.1, 0.75 },
		texture = "rbxassetid://111669458824464", -- assets/particles/GoldSheen.png
		glow = rgb(255, 230, 90),
		reflectance = 0.25,
		light = rgb(255, 200, 80),
	},
	{
		name = "Diamond",
		-- (Oct 13: came out pale ice with no facets, and Glass lost the studs: deeper blue, the
		-- studs' own material, and a cut-facets-and-sparkles texture over it)
		stops = { rgb(24, 80, 168), rgb(56, 132, 214), rgb(104, 184, 240), rgb(176, 222, 252) },
		span = { 0.05, 0.75 },
		facet = 0.18, -- (every other part a facet lighter)
		texture = "rbxassetid://108987125795271", -- assets/particles/DiamondFacets.png
		glow = rgb(150, 240, 255),
		reflectance = 0.3,
		light = rgb(170, 230, 255),
	},
	{
		name = "Galaxy",
		-- (darker than the mockup's: the game's Lighting brightens and saturates colours, so
		-- the mockup's ramp came out flat bright purple: QM, Oct 13)
		-- (second try, Oct 13: still read royal blue in game, so darker again and toward magenta)
		stops = { rgb(16, 6, 26), rgb(36, 12, 56), rgb(64, 22, 92), rgb(120, 44, 140) },
		span = { 0.05, 0.6 },
		texture = "rbxassetid://88920972936817", -- assets/particles/GalaxyStars.png: stars and nebula wisps over its faces
		glow = rgb(90, 230, 255),
		light = rgb(180, 90, 255),
	},
}

local KEEP = { "Eye", "Pupil", "Nostril" }
local TEXTURE_TILE = 5 -- studs a tile of a skin's texture covers
local TEXTURE_MIN = 1 -- studs: faces smaller than this either way go without (fewer Textures)
local FACES = {
	{ Enum.NormalId.Top, "X", "Z" }, { Enum.NormalId.Front, "X", "Y" }, { Enum.NormalId.Back, "X", "Y" },
	{ Enum.NormalId.Left, "Z", "Y" }, { Enum.NormalId.Right, "Z", "Y" },
} -- (not the Bottom: it's never seen)

-- The skin's texture (the Galaxy's stars, the Gold's sheen, the Diamond's facets) over a part's bigger faces, untinted.
local function textured(part, image)
	for _, face in FACES do
		if part.Size[face[2]] >= TEXTURE_MIN and part.Size[face[3]] >= TEXTURE_MIN then
			local t = Instance.new("Texture")
			t.Name = "SkinTexture"
			t.Texture = image
			t.Face = face[1]
			t.StudsPerTileU, t.StudsPerTileV = TEXTURE_TILE, TEXTURE_TILE
			t.OffsetStudsU, t.OffsetStudsV = (part.Position.X * 0.37) % TEXTURE_TILE, (part.Position.Y * 0.53) % TEXTURE_TILE -- (so neighbouring parts don't line up)
			t.ZIndex = 2
			t.Parent = part
		end
	end
end

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
	box.Size = extents * (if skin.name == "Galaxy" then 1.05 else 0.7) -- (the galaxy's stars sit on its body too)
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
		emitter(box, { -- the nebula, hugging it
			Texture = puff,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 80, 220)), ColorSequenceKeypoint.new(0.5, rgb(150, 80, 255)), ColorSequenceKeypoint.new(1, rgb(90, 200, 255)) }),
			Rate = 5, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(0, 0.3), Size = size(r * 0.6),
			Transparency = NumberSequence.new(0.45), LightEmission = 1, LockedToPart = true,
		})
		-- (QM, Oct 13: the mockup's stars on the body) a sky of still stars sprinkled over
		-- and round it, riding with it, each twinkling in and out. Particles rather than a
		-- star Texture on every face: the studs went to a material to get rid of those.
		emitter(box, {
			Texture = star,
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 255, 255)), ColorSequenceKeypoint.new(0.6, rgb(255, 210, 250)), ColorSequenceKeypoint.new(1, rgb(160, 240, 255)) }),
			Rate = math.clamp(extents.X * extents.Y * extents.Z / 6, 15, 60), Lifetime = NumberRange.new(1.5, 3),
			Speed = NumberRange.new(0, 0), Size = size(0.45), LightEmission = 1, LockedToPart = true,
			ZOffset = 0.5, -- (a touch toward the camera: the ones on the body show over it)
		})
		emitter(box, { -- a few big twinkles
			Texture = star, Color = ColorSequence.new(rgb(255, 255, 255)), Rate = 3,
			Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0, 0), Size = size(1.3),
			LightEmission = 1, LockedToPart = true, ZOffset = 0.5,
		})
	end
end

function Skins.apply(animal, rebirths)
	local model = animal and animal.model
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
		if skin.texture and skin.texture ~= "" and part.Material ~= Enum.Material.Neon then
			textured(part, skin.texture)
		end
	end
	local root = model.PrimaryPart
	if root then
		local _, extents = model:GetBoundingBox()
		aura(root, skin, extents)
	end
	if animal.grow then
		animal:grow(Config.Rebirth.Scale)
	end
end

return Skins
