-- Your pet's sprint trails (QM, Oct 4; what's left of the Godlands' hazards, Oct 10):
-- your Sludge's sprint lays sludge that gets the stampede animals it catches stuck,
-- falling behind; your Soul Horse's lays spikes that kill the animals that run into them
-- (Config.SprintSpecials: Goo, SpikeTrail). Never you. Ride.client drives it:
--
--   PetTrails.update(dt, herd, mount, riding, trail) -- each frame, after the stampede moves
--       (trail: your pet's sprint special's Kind while it lays one, "Goo" or "SpikeTrail")
--   PetTrails.offset(key)  -- x, z a stampede animal stuck in your sludge is off its place
--   PetTrails.clear()      -- the ride's over: everything goes
--   PetTrails.spiked       -- set by Ride: spiked(entity, dx) kills a stampede animal on your spikes

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ground = require(ReplicatedStorage.Shared.Ground)

local PetTrails = {}

local SPIKE = {
	EVERY = 5, -- studs the horse runs between spikes
	LIFE = 1, -- up this long (QM), then sink
	RISE = 0.12,
	SINK = 0.25,
	WIDTH = 2.8,
	HEIGHT = 4.5,
	COLOR = Color3.fromRGB(96, 150, 255), -- the Soul Horse's ghostly blue
	BEHIND = 8, -- studs behind your Soul Horse its spikes go in
}
local SLUDGE = {
	EVERY = 7, -- studs between puddles
	LIFE = 4,
	FADE = 0.6, -- shrinking away at the end of its life
	RADIUS = 4,
	COLOR = Color3.fromRGB(104, 112, 40), -- the Sludge's olive
}
local GOO = {
	STUCK = 1.5, -- seconds a stampede animal that ran into your sludge crawls
	SLOW = 0.2, -- x its speed meanwhile: it falls behind the stampede
}

local spikes = {} -- { parts, up, t, x, z }
local spikedKeys = {} -- [key] = true: stampede animals already killed on your spikes
local puddles = {} -- { part, t, x, z, r }
local gooLeft, gooLag = {}, {} -- [key]: a stampede animal stuck in your sludge (seconds left), and how far behind it fell
local mine -- your trail's state: how far you've run since its last spike or puddle
local holder = Instance.new("Folder")
holder.Name = "PetTrails"
holder.Parent = workspace

local function part(class, size, color, parent)
	local p = Instance.new(class)
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Size, p.Color = size, color
	p.Parent = parent or holder
	return p
end

-- A flat disc lying on the ground (a cylinder on its side).
local FLAT = CFrame.Angles(0, 0, math.pi / 2)
local function disc(x, z, radius, color, lift)
	local p = part("Part", Vector3.new(0.3, radius * 2, radius * 2), color)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(x, Ground.heightAt(x, z) + (lift or 0.1), z) * FLAT
	return p
end

local function footprint(entity)
	local _, size = entity.animal.model:GetBoundingBox()
	return size.X / 2 * 0.8, size.Z / 2 * 0.8
end

local SPIKE_PEAK = Vector3.new(1, 0, -1) -- a CornerWedgePart's peak, seen from above
local function spike(x, z)
	local w, h = SPIKE.WIDTH, SPIKE.HEIGHT
	local floor = Ground.heightAt(x, z)
	local s = { t = 0, x = x, z = z, parts = {}, up = {} }
	-- four corner wedges, each with its peak over the middle: a pyramid (as the Soul Horse's Spikes)
	for sx = -1, 1, 2 do
		for sz = -1, 1, 2 do
			local turn = 0
			for k = 0, 3 do
				local v = CFrame.Angles(0, k * math.pi / 2, 0) * SPIKE_PEAK
				if math.sign(v.X) == -sx and math.sign(v.Z) == -sz then
					turn = k * math.pi / 2
				end
			end
			local p = part("CornerWedgePart", Vector3.new(w / 2, h, w / 2), SPIKE.COLOR)
			local up = CFrame.new(x + sx * w / 4, floor + h / 2, z + sz * w / 4) * CFrame.Angles(0, turn, 0)
			p.CFrame = up - Vector3.new(0, h, 0)
			table.insert(s.parts, p)
			table.insert(s.up, up)
		end
	end
	table.insert(spikes, s)
end

local function updateSpikes(dt)
	for i = #spikes, 1, -1 do
		local s = spikes[i]
		s.t += dt
		local t = s.t
		local down -- studs below fully up
		if t < SPIKE.RISE then
			down = SPIKE.HEIGHT * (1 - t / SPIKE.RISE)
		elseif t > SPIKE.LIFE then
			down = SPIKE.HEIGHT * math.min((t - SPIKE.LIFE) / SPIKE.SINK, 1)
		end
		if t > SPIKE.LIFE + SPIKE.SINK then
			for _, p in s.parts do
				p:Destroy()
			end
			table.remove(spikes, i)
		elseif down or not s.settled then
			s.settled = down == nil
			for k, p in s.parts do
				p.CFrame = s.up[k] - Vector3.new(0, down or 0, 0)
			end
		end
	end
end

local function puddle(x, z)
	local p = disc(x, z, SLUDGE.RADIUS, SLUDGE.COLOR, 0.12)
	table.insert(puddles, { part = p, t = 0, x = x, z = z, r = SLUDGE.RADIUS })
end

local function updatePuddles(dt)
	for i = #puddles, 1, -1 do
		local d = puddles[i]
		d.t += dt
		local left = SLUDGE.LIFE - d.t
		if left <= 0 then
			d.part:Destroy()
			table.remove(puddles, i)
		elseif left < SLUDGE.FADE then
			d.r = SLUDGE.RADIUS * left / SLUDGE.FADE
			d.part.Size = Vector3.new(0.3, d.r * 2, d.r * 2)
		end
	end
end

function PetTrails.update(dt, herd, mount, riding, trailKind)
	if not riding or not mount then
		herd, trailKind = {}, nil
	end
	if trailKind == "Goo" or trailKind == "SpikeTrail" then
		-- Your Sludge or Soul Horse sprinting: its sludge or spike trail, every so many studs.
		-- Spikes go in just behind you.
		mine = mine or {}
		local dx, dz = mount.x - (mine.x or mount.x), mount.z - (mine.z or mount.z)
		mine.run = (mine.run or 0) + math.sqrt(dx * dx + dz * dz)
		mine.x, mine.z = mount.x, mount.z
		if trailKind == "Goo" and mine.run >= SLUDGE.EVERY then
			mine.run = 0
			puddle(mount.x, mount.z)
		elseif trailKind == "SpikeTrail" and mine.run >= SPIKE.EVERY then
			mine.run = 0
			spike(mount.x, mount.z + SPIKE.BEHIND)
		end
	else
		mine = nil
	end
	-- Stampede animals running into your spikes are killed (whatever their size).
	for _, sp in spikes do
		if sp.t > SPIKE.RISE * 0.5 and sp.t < SPIKE.LIFE and PetTrails.spiked then
			for key, entity in herd do
				local dx, dz = entity.x - sp.x, entity.z - sp.z
				if key >= 0 and entity ~= mount and not spikedKeys[key] and not entity.popping and not entity.event
					and math.abs(dx) < 40 and math.abs(dz) < 40 then
					local hx, hz = footprint(entity)
					if math.abs(dx) < hx + SPIKE.WIDTH / 2 and math.abs(dz) < hz + SPIKE.WIDTH / 2 then
						spikedKeys[key] = true
						PetTrails.spiked(entity, dx)
					end
				end
			end
		end
	end
	for key in spikedKeys do
		if not herd[key] then
			spikedKeys[key] = nil
		end
	end
	-- Stampede animals running into your sludge get stuck and fall behind.
	for key, left in gooLeft do
		gooLeft[key] = if left > dt then left - dt else nil
		local entity = herd[key]
		if entity then
			gooLag[key] = (gooLag[key] or 0) + (entity.speed or 0) * (1 - GOO.SLOW) * dt
		end
	end
	if #puddles > 0 then
		for key, entity in herd do
			if key >= 0 and not entity.popping and not entity.event then
				for _, d in puddles do
					local dx, dz = entity.x - d.x, entity.z - d.z
					if dx * dx + dz * dz < (d.r + 1.5) ^ 2 then
						gooLeft[key] = GOO.STUCK
						break
					end
				end
			end
		end
	end
	for key in gooLag do
		if not herd[key] then
			gooLag[key], gooLeft[key] = nil, nil -- gone (out of view, lassoed or knocked away)
		end
	end
	updateSpikes(dt)
	updatePuddles(dt)
end

function PetTrails.offset(key)
	return 0, gooLag[key] or 0 -- (it runs toward -z: falling behind is +z)
end

function PetTrails.clear()
	for _, s in spikes do
		for _, p in s.parts do
			p:Destroy()
		end
	end
	for _, d in puddles do
		d.part:Destroy()
	end
	spikes, puddles = {}, {}
	gooLeft, gooLag, mine, spikedKeys = {}, {}, nil, {}
end

return PetTrails
