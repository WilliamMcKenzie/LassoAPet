-- A new lasso with every pen upgrade (QM, Oct 8): tier n is pen level n's, themed on
-- that biome, each one flashier than the last. Lasso.luau wears it (riding, training,
-- the HOLD ON! rope: RopeHang): the rope's colours and glow, sparkles along the loop,
-- a trail behind it as it flies, and a burst where it lands. Beams and short
-- particle bursts only (phones: no Highlight).
--
--   LassoTiers.get(level) -- the tier for a pen level (past the last: the last)
--
-- A tier: name; rope = { colours (ColorSequence keypoints or a rainbow), glow
-- (LightEmission 0..1), width (x the plain rope's) }; sparkle / trail / burst =
-- particle settings (nil: none), burst also `count`.

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local TIERS = {
	{ -- Meadow: the plain rope, a puff of dust where it lands
		name = "Rope",
		rope = { from = rgb(222, 184, 120), to = rgb(222, 184, 120), glow = 0, width = 1 },
		burst = { texture = SMOKE, color = rgb(200, 180, 140), size = 1.2, lifetime = 0.5, speed = 6, count = 8, light = 0 },
	},
	{ -- Desert: a golden rope glinting with sand
		name = "Golden Lasso",
		rope = { from = rgb(255, 196, 40), to = rgb(255, 238, 150), glow = 0.35, width = 1.15 },
		sparkle = { texture = SPARKLE, color = rgb(255, 214, 90), size = 0.5, lifetime = 0.6, speed = 1.5, rate = 6, light = 0.6 },
		trail = { texture = SMOKE, color = rgb(232, 196, 120), size = 0.9, lifetime = 0.45, speed = 1, rate = 40, light = 0 },
		burst = { texture = SPARKLE, color = rgb(255, 210, 70), size = 1, lifetime = 0.6, speed = 14, count = 18, light = 0.8 },
	},
	{ -- Tundra: an icy blue rope shedding frost shards
		name = "Frost Lasso",
		rope = { from = rgb(120, 220, 255), to = rgb(225, 250, 255), glow = 0.55, width = 1.25 },
		sparkle = { texture = SPARKLE, color = rgb(170, 235, 255), size = 0.6, lifetime = 0.8, speed = 2, rate = 10, light = 0.8, spin = true },
		trail = { texture = SPARKLE, color = rgb(200, 245, 255), size = 0.7, lifetime = 0.5, speed = 2, rate = 50, light = 0.9, spin = true },
		burst = { texture = SPARKLE, color = rgb(150, 230, 255), size = 1.4, lifetime = 0.7, speed = 18, count = 26, light = 1, spin = true },
	},
	{ -- Ocean: an aqua rope trailing bubbles, a splash where it lands
		name = "Tide Lasso",
		rope = { from = rgb(20, 190, 230), to = rgb(130, 255, 235), glow = 0.65, width = 1.35 },
		sparkle = { texture = SPARKLE, color = rgb(150, 245, 255), size = 0.45, lifetime = 1, speed = 1, rate = 12, light = 0.7, rise = 4 },
		trail = { texture = SMOKE, color = rgb(190, 250, 255), size = 1, lifetime = 0.5, speed = 3, rate = 60, light = 0.3 },
		burst = { texture = SMOKE, color = rgb(170, 245, 255), size = 1.8, lifetime = 0.6, speed = 20, count = 30, light = 0.4, rise = -20 },
	},
	{ -- Godlands: a glowing rainbow rope, crackling, a blast of light where it lands
		name = "Godly Lasso",
		rope = { rainbow = true, glow = 1, width = 1.5 },
		sparkle = { texture = SPARKLE, color = rgb(255, 250, 220), size = 0.8, lifetime = 0.35, speed = 6, rate = 22, light = 1, spin = true },
		trail = { texture = FIRE, color = rgb(255, 230, 140), size = 1.1, lifetime = 0.35, speed = 2, rate = 80, light = 1 },
		burst = { texture = SPARKLE, color = rgb(255, 255, 255), size = 2, lifetime = 0.5, speed = 30, count = 40, light = 1, spin = true },
	},
}

local LassoTiers = {}

function LassoTiers.get(level)
	return TIERS[math.clamp(math.floor(tonumber(level) or 1), 1, #TIERS)]
end

-- A ParticleEmitter for these settings (Rate 0: emit by hand).
function LassoTiers.emitter(p, parent)
	local e = Instance.new("ParticleEmitter")
	e.Texture = p.texture
	e.Color = ColorSequence.new(p.color)
	e.LightEmission = p.light or 0
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, p.size), NumberSequenceKeypoint.new(1, p.size * 0.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(p.lifetime * 0.7, p.lifetime)
	e.Speed = NumberRange.new(p.speed * 0.5, p.speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = p.rate or 0
	e.Drag = 3
	e.Acceleration = Vector3.new(0, p.rise or 0, 0)
	if p.spin then
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-240, 240)
	end
	e.LockedToPart = false
	e.Parent = parent
	return e
end

-- The rope's colour for a beam `i` of `n` round the loop at time t (a rainbow turns).
function LassoTiers.ropeColor(tier, i, n, t)
	local rope = tier.rope
	if rope.rainbow then
		local h = ((i or 0) / (n or 1) + (t or 0) * 0.35) % 1
		return ColorSequence.new(Color3.fromHSV(h, 0.75, 1), Color3.fromHSV((h + 1 / (n or 1)) % 1, 0.75, 1))
	end
	return ColorSequence.new(rope.from, rope.to)
end

return LassoTiers
