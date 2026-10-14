-- Hoof dust: every time a galloping animal lands, little cream blocks burst out
-- from its hooves, arc up and shrink away where they were kicked.
--
--   Dust.kick(rootCFrame, scale) -- the animal's ground-level root, facing -Z
--   Dust.update(dt)              -- every frame (with the ride's time scale)

local COLOR = Color3.fromRGB(255, 252, 240)
local LIFE = 0.55 -- seconds
local PER_HOOF = 2
-- Hooves on the horse, in studs from its root (x, z); front legs at -z.
local HOOVES = { Vector3.new(-1.05, 0, -2.15), Vector3.new(1.05, 0, -2.15), Vector3.new(-1.05, 0, 2.75), Vector3.new(1.05, 0, 2.75) }

local rng = Random.new()
local folder = Instance.new("Folder")
folder.Name = "Dust"
folder.Parent = workspace

local live = {}
local spare = {}

local function newBlock()
	local part = table.remove(spare)
	if not part then
		part = Instance.new("Part")
		part.Name = "Dust"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = COLOR
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
	end
	part.Parent = folder
	return part
end

local Dust = {}

function Dust.kick(root, scale)
	scale = scale or 1
	for _, hoof in HOOVES do
		local side = if hoof.X > 0 then 1 else -1
		for _ = 1, PER_HOOF do
			local offset = Vector3.new(side * rng:NextNumber(1.5, 3.5), 0, rng:NextNumber(0.5, 2.5)) * scale
			table.insert(live, {
				part = newBlock(),
				t = 0,
				from = root * (hoof * scale),
				out = root:VectorToWorldSpace(offset),
				up = rng:NextNumber(1.2, 2.6) * scale,
				size = rng:NextNumber(0.9, 1.4) * scale,
				spin = CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi)),
				turn = Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-6, 6), rng:NextNumber(-6, 6)),
			})
		end
	end
end

function Dust.update(dt)
	for i = #live, 1, -1 do
		local b = live[i]
		b.t += dt
		local f = b.t / LIFE
		if f >= 1 then
			b.part.Parent = nil
			table.insert(spare, b.part)
			live[i] = live[#live]
			live[#live] = nil
			continue
		end
		-- Bursts out fast and slows (ease out), hops up and drops, shrinking all the while.
		local s = b.size * (1 - f) ^ 0.7
		local spread = 1 - (1 - f) ^ 2
		local height = b.up * math.sin(math.pi * math.min(f * 1.3, 1))
		b.part.Size = Vector3.one * math.max(s, 0.05)
		b.part.CFrame = CFrame.new(b.from + b.out * spread + Vector3.new(0, s / 2 + height, 0))
			* b.spin * CFrame.Angles(b.turn.X * b.t, b.turn.Y * b.t, b.turn.Z * b.t)
	end
end

return Dust
