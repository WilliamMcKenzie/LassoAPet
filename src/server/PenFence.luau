-- A pen's fence, built in game (QM, Oct 12): its look is the furthest biome you've
-- unlocked (STYLES, one per biome, in Config.Biomes order), its size your pen level's
-- (tools/pens.py lays out the 13 sizes' markers; PenLevel.server shows one). The same
-- layout as tools/pens.py's fence: posts no more than SPAN apart along each side, a
-- GATE-wide gap in the front (the Tiles marker's -Z side, facing the yard).
-- Uprights are named Post and the long pieces Rail or Brace, so the VIP pass's gold
-- fence repaints them (PenLevel.server); everything else (Wall, Trim) keeps its colours.
--
--   PenFence.build(tiles, biome) -> Model  -- around the Tiles marker, in biome's style

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Studs = require(ReplicatedStorage.Shared.Studs)

local PenFence = {}

local SPAN = 6 -- longest gap between posts
local GATE = 10
local RAILS_Y = { 0.9, 3.3 } -- the braces fit between these rails' faces
local RAIL_H = 0.5
local BRACE_W = 0.4

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WHITE = rgb(245, 245, 240)

-- Each biome's fence (QM, Oct 12: the renders in design/pen_biomes.png).
-- post = { width, height, colour }; cap / foot = { width, height, colour, neon? } on each
-- post; rails = { { y, height, thickness, colour, neon? } }; wall = { height, thickness,
-- colour, transparency? }; braces = colour (an X in every span).
local STYLES = {
	{ -- Meadow: wood, dark posts, orange rails, an X in every span
		post = { 1.2, 4, rgb(62, 62, 72) },
		rails = { { 0.9, 0.5, 0.5, rgb(204, 108, 52) }, { 3.3, 0.5, 0.5, rgb(204, 108, 52) } },
		braces = rgb(204, 108, 52),
	},
	{ -- Desert: a sandstone wall with capped pillars
		post = { 1.8, 3.4, rgb(190, 140, 84) },
		cap = { 2.2, 0.5, rgb(236, 204, 150) },
		wall = { 2.4, 1.2, rgb(214, 170, 110) },
	},
	{ -- Tundra: see-through ice blocks, white posts with blue caps
		post = { 1.6, 3.6, rgb(236, 246, 255) },
		cap = { 2.0, 0.5, rgb(120, 190, 255) },
		wall = { 2.4, 1.2, rgb(170, 220, 255), 0.3 },
	},
	{ -- Ocean: teal posts with pink coral caps, rope rails
		post = { 1.4, 4.0, rgb(40, 170, 170) },
		cap = { 1.9, 0.9, rgb(255, 120, 170) },
		rails = { { 1.6, 0.35, 0.35, rgb(222, 196, 140) }, { 3.0, 0.35, 0.35, rgb(222, 196, 140) } },
	},
	{ -- Volcano: basalt posts with glowing tops, a glowing lava rail
		post = { 1.6, 4.4, rgb(54, 44, 44) },
		cap = { 1.0, 0.6, rgb(255, 120, 30), true },
		rails = { { 1.0, 0.6, 0.6, rgb(70, 56, 54) }, { 2.2, 0.3, 0.3, rgb(255, 110, 30), true }, { 3.4, 0.6, 0.6, rgb(70, 56, 54) } },
	},
	{ -- Jurassic: bone
		post = { 1.0, 4.0, rgb(240, 232, 210) },
		cap = { 1.7, 0.8, rgb(250, 244, 228) },
		foot = { 1.7, 0.8, rgb(250, 244, 228) },
		rails = { { 1.4, 0.5, 0.5, rgb(226, 216, 190) }, { 2.8, 0.5, 0.5, rgb(226, 216, 190) } },
	},
}
PenFence.STYLES = STYLES

function PenFence.build(tiles, biome)
	local st = STYLES[math.clamp(biome or 1, 1, #STYLES)]
	local model = Instance.new("Model")
	model.Name = "Fence"
	local frame = tiles.CFrame - Vector3.new(0, tiles.Position.Y, 0) -- (the pen's frame, on the ground)
	local half = tiles.Size.X / 2

	local function add(name, size, cf, color, neon, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = frame * cf
		p.Color = color
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if neon then
			p.Material = Enum.Material.Neon
		elseif not Studs.apply(p, 0.5) then
			p.TopSurface = Enum.SurfaceType.Studs
		end
		if transparency then
			p.Transparency = transparency
			p.CastShadow = false
		end
		p.Parent = model
		return p
	end

	local pw, ph, pcolor = st.post[1], st.post[2], st.post[3]
	local x0, x1, z0, z1 = -half, half, -half, half
	local runs = { -- start -> end on the ground (x, z), the gap in the front (z0)
		{ Vector2.new(x0, z0), Vector2.new(-GATE / 2, z0) },
		{ Vector2.new(GATE / 2, z0), Vector2.new(x1, z0) },
		{ Vector2.new(x0, z0), Vector2.new(x0, z1) },
		{ Vector2.new(x1, z0), Vector2.new(x1, z1) },
		{ Vector2.new(x0, z1), Vector2.new(x1, z1) },
	}
	local posts = {}
	for _, run in runs do
		local a, b = run[1], run[2]
		local length = (b - a).Magnitude
		local along = (b - a) / length
		local n = math.max(1, math.ceil(length / SPAN - 1e-9))
		local stops = {}
		for k = 0, n do
			local s = a + along * length * k / n
			stops[k] = s
			posts[string.format("%.3f,%.3f", s.X, s.Y)] = s
		end
		local yaw = if math.abs(along.X) > 0.5 then 0 else math.pi / 2 -- (rails run along local X)
		local turn = CFrame.Angles(0, yaw, 0)
		local mid = (a + b) / 2
		for _, rail in st.rails or {} do
			add("Rail", Vector3.new(length, rail[2], rail[3]), CFrame.new(mid.X, rail[1], mid.Y) * turn, rail[4], rail[5])
		end
		if st.wall then
			local w = st.wall
			add("Wall", Vector3.new(length, w[1], w[2]), CFrame.new(mid.X, w[1] / 2, mid.Y) * turn, w[3], nil, w[4])
		end
		if st.braces then -- an X in every span, between the posts and the rails
			local lo, hi = RAILS_Y[1] + RAIL_H / 2, RAILS_Y[2] - RAIL_H / 2
			for k = 0, n - 1 do
				local s0 = stops[k] + along * pw / 2
				local s1 = stops[k + 1] - along * pw / 2
				local w, h = (s1 - s0).Magnitude, hi - lo
				local angle = math.atan2(h, w)
				local c = (s0 + s1) / 2
				for _, side in { { 1, 0.34 }, { -1, 0.3 } } do -- (different depths so the crossing faces never z-fight)
					add("Brace", Vector3.new(math.sqrt(w * w + h * h) - BRACE_W * 0.5, BRACE_W, side[2]),
						CFrame.new(c.X, (lo + hi) / 2, c.Y) * turn * CFrame.Angles(0, 0, side[1] * angle), st.braces)
				end
			end
		end
	end
	for _, s in posts do
		add("Post", Vector3.new(pw, ph, pw), CFrame.new(s.X, ph / 2, s.Y), pcolor)
		if st.cap then
			add("Trim", Vector3.new(st.cap[1], st.cap[2], st.cap[1]), CFrame.new(s.X, ph + st.cap[2] / 2, s.Y), st.cap[3], st.cap[4])
		end
		if st.foot then
			add("Trim", Vector3.new(st.foot[1], st.foot[2], st.foot[1]), CFrame.new(s.X, st.foot[2] / 2, s.Y), st.foot[3])
		end
	end
	return model
end

return PenFence
