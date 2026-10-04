-- The Godlands' wild animals are dangerous to ride alongside (QM, Oct 4: "get as
-- far as you CAN"). Only the stampede's own animals in the Godlands do this, never
-- your pet, and only near you (each player sees their own):
--
--   Soul Horse  leaves a trail of spikes behind it, each up for a second: hit one and you crash
--   Sludge      leaves puddles of sludge: ride into one and you're stuck, crawling, for a moment
--   Beholder    now and then a purple circle swells round it, then bursts: caught in it, your
--               steering is flipped for a few seconds (CONFUSED)
--   War Elephant now and then stamps and turns on you (a red lane on the ground shows where),
--               then charges down it (the Rhino's charge VFX): hit and you're knocked out
--   Leviathan   now and then rears up (a red "!") and hunts you for a few seconds, a little
--               faster than you but slow to turn, so you can swerve out of its way
--
-- Ride.client drives it:
--   Hazards.update(dt, herd, mount, riding, goo)  -- each frame, after the stampede moves
--       (goo: your Sludge's sprint is on (Config.SprintSpecials): it lays the same sludge,
--       which gets stampede animals stuck instead of you)
--   Hazards.offset(key)       -- x, z a charging or hunting animal is off its place in the stampede
--   Hazards.hit(mount, grace) -- the tip for a crash this frame, if any (gets you stuck in sludge too)
--   Hazards.steerSign()       -- -1 while you're confused
--   Hazards.slow()            -- x your speed while you're stuck
--   Hazards.clear()           -- the ride's over: everything goes
--   Hazards.chargeFx          -- set by Ride: chargeFx(entity) -> instances (the Rhino's charge)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Godlands = require(ReplicatedStorage.Shared.Godlands)
local Ground = require(ReplicatedStorage.Shared.Ground)

local Hazards = {}

-- (Timings and sizes are guesses for QM to tune. Seconds and studs.)
local REACH = 200 -- animals further than this from you (along the course) do nothing
local SPIKE = {
	EVERY = 5, -- studs the horse runs between spikes
	LIFE = 1, -- up this long (QM), then sink
	RISE = 0.12,
	SINK = 0.25,
	WIDTH = 2.8,
	HEIGHT = 4.5,
	COLOR = Color3.fromRGB(96, 150, 255), -- the Soul Horse's ghostly blue
}
local SLUDGE = {
	EVERY = 7, -- studs between puddles
	LIFE = 4,
	FADE = 0.6, -- shrinking away at the end of its life
	RADIUS = 4,
	STUCK = 0.8, -- seconds you stay stuck after leaving the puddle
	SLOW = 0.2, -- x your speed while stuck
	COLOR = Color3.fromRGB(104, 112, 40), -- the Sludge's olive
}
local AURA = {
	EVERY = { 7, 11 },
	WARN = 1.5, -- the circle swelling to its full size
	RADIUS = 28,
	CONFUSE = 3, -- QM: "like 3s"
	NEAR = 70, -- only starts when you're this close
	COLOR = Color3.fromRGB(170, 60, 255),
}
local CHARGE = {
	EVERY = { 5, 9 },
	WARN = 1.3, -- stamping, the red lane tracking you
	SPEED = 95,
	LENGTH = { 50, 120 },
	WIDTH = 9,
	NEAR = 70,
	COLOR = Color3.fromRGB(255, 50, 40),
}
local HUNT = {
	EVERY = { 7, 11 },
	WARN = 1,
	TIME = 3, -- QM: "only lasts like 3s"
	EXTRA = 10, -- studs/s faster than you
	MIN_SPEED = 50,
	TURN = 2.4, -- radians/s: slow enough to swerve out of its way
	NEAR = 60,
}
local SETTLE = 1.2 -- how quickly a charger or hunter drifts back to its place in the stampede
local GOO = {
	STUCK = 1.5, -- seconds a stampede animal that ran into your Sludge's sludge crawls
	SLOW = 0.2, -- x its speed meanwhile: it falls behind the stampede
}
local KINDS = { SoulHorse = "spikes", Sludge = "sludge", Beholder = "aura", WarElephant = "charge", Leviathan = "hunt" }

local player = Players.LocalPlayer
local rng = Random.new()
local watched = {} -- [key] = state of a hazardous stampede animal near you
local spikes = {} -- { parts, up, t, x, z }
local puddles = {} -- { part, t, x, z, r, mine }: mine = your Sludge's, which never gets you stuck
local gooLeft, gooLag = {}, {} -- [key]: a stampede animal stuck in your sludge (seconds left), and how far behind it fell
local fading = {} -- one-off effects: { part, t, life, size0, size1, transparency0 }
local confused, stuck = 0, 0
local holder = Instance.new("Folder")
holder.Name = "GodlandsHazards"
holder.Parent = workspace

-- The CONFUSED / STUCK label and the purple tint.
local gui = Instance.new("ScreenGui")
gui.Name = "Hazards"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Enabled = false
local tint = Instance.new("Frame")
tint.Size = UDim2.fromScale(1, 1)
tint.BorderSizePixel = 0
tint.BackgroundColor3 = AURA.COLOR
tint.BackgroundTransparency = 1
tint.Parent = gui
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.3)
label.Size = UDim2.fromScale(0.5, 0.09)
label.BackgroundTransparency = 1
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.new(0, 0, 0)
stroke.Parent = label
gui.Parent = player:WaitForChild("PlayerGui")

local function between(range)
	return rng:NextNumber(range[1], range[2])
end

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

-- A red "!" over an animal that's about to come for you.
local function warning(entity)
	local root = entity.animal.model.PrimaryPart
	local _, size = entity.animal.model:GetBoundingBox()
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(5, 5)
	b.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 4, 0)
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = "!"
	t.TextColor3 = CHARGE.COLOR
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	t.Parent = b
	b.Adornee = root
	b.Parent = root
	return b
end

-- The animal's footprint, for the hit checks: its half width and half length.
local function footprint(entity)
	local _, size = entity.animal.model:GetBoundingBox()
	return size.X / 2 * 0.8, size.Z / 2 * 0.8
end

local function tidy(st)
	for _, name in { "lane", "flag", "ring" } do
		if st[name] then
			st[name]:Destroy()
			st[name] = nil
		end
	end
	if st.fx then
		for _, inst in st.fx do
			inst:Destroy()
		end
		st.fx = nil
	end
end

local function drop(key)
	local st = watched[key]
	watched[key] = nil
	tidy(st)
	local e = st.entity
	e.face, e.rush = nil, nil
	if st.hopping and not e.popping then
		e.hop = 0
	end
end

-- Spikes and puddles --------------------------------------------------------

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

local function puddle(x, z, mine)
	local p = disc(x, z, SLUDGE.RADIUS, SLUDGE.COLOR, 0.12)
	table.insert(puddles, { part = p, t = 0, x = x, z = z, r = SLUDGE.RADIUS, mine = mine })
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

local function updateFading(dt)
	for i = #fading, 1, -1 do
		local f = fading[i]
		f.t += dt
		local a = math.min(f.t / f.life, 1)
		f.part.Size = f.size0:Lerp(f.size1, a)
		f.part.Transparency = f.transparency0 + (1 - f.transparency0) * a
		if a >= 1 then
			f.part:Destroy()
			table.remove(fading, i)
		end
	end
end

-- Each kind's step ----------------------------------------------------------

-- Drops spikes or puddles every so many studs it runs.
local function trail(st, entity, every, drop_)
	local dx, dz = entity.x - (st.lastX or entity.x), entity.z - (st.lastZ or entity.z)
	st.run = (st.run or 0) + math.sqrt(dx * dx + dz * dz)
	st.lastX, st.lastZ = entity.x, entity.z
	if st.run >= every and not entity.popping then
		st.run = 0
		if not st.tail then
			local _, half = footprint(entity)
			st.tail = half
		end
		drop_(entity.x, entity.z + st.tail) -- at its tail (it runs toward -z)
	end
end

local function aura(st, entity, dt, mount)
	local dx, dz = mount.x - entity.x, mount.z - entity.z
	if st.stage == "idle" then
		st.wait -= dt
		if st.wait <= 0 and dx * dx + dz * dz < AURA.NEAR * AURA.NEAR and not entity.popping then
			st.stage, st.t = "warn", 0
			st.ring = disc(entity.x, entity.z, 1, AURA.COLOR, 0.15)
			st.ring.Material = Enum.Material.Neon
		end
		return
	end
	st.t += dt
	local a = math.min(st.t / AURA.WARN, 1)
	local r = AURA.RADIUS * (0.3 + 0.7 * a)
	st.ring.Size = Vector3.new(0.3, r * 2, r * 2)
	st.ring.CFrame = CFrame.new(entity.x, Ground.heightAt(entity.x, entity.z) + 0.15, entity.z) * FLAT
	st.ring.Transparency = 0.55 + 0.25 * math.cos(st.t * 14) -- pulsing faster
	if a >= 1 then
		-- Burst: anyone inside is confused.
		if dx * dx + dz * dz < AURA.RADIUS * AURA.RADIUS then
			confused = AURA.CONFUSE
		end
		table.insert(fading, {
			part = st.ring,
			t = 0,
			life = 0.35,
			size0 = st.ring.Size,
			size1 = Vector3.new(0.3, AURA.RADIUS * 2.4, AURA.RADIUS * 2.4),
			transparency0 = 0.2,
		})
		st.ring = nil
		st.stage, st.wait = "idle", between(AURA.EVERY)
	end
end

local function settle(st, dt)
	local k = math.exp(-SETTLE * dt)
	st.ox *= k
	st.oz *= k
end

local function charge(st, entity, dt, mount)
	local dx, dz = mount.x - entity.x, mount.z - entity.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if st.stage == "idle" then
		settle(st, dt)
		st.wait -= dt
		if st.wait <= 0 and dist < CHARGE.NEAR and not entity.popping then
			st.stage, st.t = "warn", 0
			st.lane = part("Part", Vector3.new(CHARGE.WIDTH, 0.2, 1), CHARGE.COLOR)
			st.lane.Material = Enum.Material.Neon
			st.flag = warning(entity)
		end
		return
	end
	if st.stage == "warn" then
		settle(st, dt)
		st.t += dt
		-- Stamping and turning toward you, the lane following you, then it locks.
		st.dirX, st.dirZ = dx / math.max(dist, 0.1), dz / math.max(dist, 0.1)
		st.length = math.clamp(dist + 30, CHARGE.LENGTH[1], CHARGE.LENGTH[2])
		entity.face = math.atan2(-st.dirX, -st.dirZ)
		entity.hop = math.abs(math.sin(st.t * math.pi * 3)) * 1.2
		st.hopping = true
		local from = Vector3.new(entity.x, Ground.heightAt(entity.x, entity.z) + 0.2, entity.z)
		local dir = Vector3.new(st.dirX, 0, st.dirZ)
		st.lane.Size = Vector3.new(CHARGE.WIDTH, 0.2, st.length)
		st.lane.CFrame = CFrame.lookAt(from, from + dir) * CFrame.new(0, 0, -st.length / 2)
		st.lane.Transparency = 0.5 + 0.25 * math.cos(st.t * 16)
		if st.t >= CHARGE.WARN then
			st.stage, st.left = "go", st.length
			entity.hop, st.hopping = 0, nil
			st.flag:Destroy()
			st.flag = nil
			if Hazards.chargeFx then
				st.fx = Hazards.chargeFx(entity)
			end
		end
		return
	end
	-- Charging down the lane.
	local step = math.min(CHARGE.SPEED * dt, st.left)
	st.left -= step
	st.ox += st.dirX * step
	st.oz += st.dirZ * step + entity.speed * dt -- (its place in the stampede runs on toward -z meanwhile)
	entity.rush = CHARGE.SPEED
	st.danger = "Knocked out by a charging War Elephant!"
	if st.left <= 0 then
		tidy(st)
		entity.face, entity.rush, st.danger = nil, nil, nil
		st.stage, st.wait = "idle", between(CHARGE.EVERY)
	end
end

local function hunt(st, entity, dt, mount)
	local dx, dz = mount.x - entity.x, mount.z - entity.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if st.stage == "idle" then
		settle(st, dt)
		st.wait -= dt
		if st.wait <= 0 and dist < HUNT.NEAR and not entity.popping then
			st.stage, st.t = "warn", 0
			st.flag = warning(entity)
		end
		return
	end
	local want = math.atan2(-dx, -dz)
	if st.stage == "warn" then
		settle(st, dt)
		st.t += dt
		-- Rearing up, turning to you.
		st.heading = want
		entity.face = want
		entity.hop = math.sin(math.min(st.t / HUNT.WARN, 1) * math.pi) * 2.5
		st.hopping = true
		if st.t >= HUNT.WARN then
			st.stage, st.t = "go", 0
			entity.hop, st.hopping = 0, nil
		end
		return
	end
	st.t += dt
	local diff = (want - st.heading + math.pi) % (2 * math.pi) - math.pi
	st.heading += math.clamp(diff, -HUNT.TURN * dt, HUNT.TURN * dt)
	local speed = math.max(HUNT.MIN_SPEED, (mount.speed or 0) + HUNT.EXTRA)
	st.ox += -math.sin(st.heading) * speed * dt
	st.oz += -math.cos(st.heading) * speed * dt + entity.speed * dt
	entity.face, entity.rush = st.heading, speed
	st.danger = "Caught by a hunting Leviathan!"
	if st.t >= HUNT.TIME then
		tidy(st)
		entity.face, entity.rush, st.danger = nil, nil, nil
		st.stage, st.wait = "idle", between(HUNT.EVERY)
	end
end

-- The API -------------------------------------------------------------------

function Hazards.update(dt, herd, mount, riding, goo)
	local seen = {}
	if not riding or not mount then
		herd = {} -- crashed (or not riding): the animals calm down, the spikes and sludge play out
		confused, stuck, goo = 0, 0, false
	end
	if goo then
		-- Your Sludge sprinting: its sludge trail, every so many studs (Hazards.mine is its trail state).
		Hazards.mine = Hazards.mine or {}
		local m = Hazards.mine
		local dx, dz = mount.x - (m.x or mount.x), mount.z - (m.z or mount.z)
		m.run = (m.run or 0) + math.sqrt(dx * dx + dz * dz)
		m.x, m.z = mount.x, mount.z
		if m.run >= SLUDGE.EVERY then
			m.run = 0
			puddle(mount.x, mount.z, true)
		end
	else
		Hazards.mine = nil
	end
	-- Stampede animals running into your sludge get stuck and fall behind.
	local anyMine = false
	for _, d in puddles do
		anyMine = anyMine or d.mine
	end
	for key, left in gooLeft do
		gooLeft[key] = if left > dt then left - dt else nil
		local entity = herd[key]
		if entity then
			gooLag[key] = (gooLag[key] or 0) + (entity.speed or 0) * (1 - GOO.SLOW) * dt
		end
	end
	if anyMine then
		for key, entity in herd do
			if key >= 0 and not entity.popping and not entity.event then
				for _, d in puddles do
					local dx, dz = entity.x - d.x, entity.z - d.z
					if d.mine and dx * dx + dz * dz < (d.r + 1.5) ^ 2 then
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
	for key, entity in herd do
		local kind = KINDS[entity.kind]
		if kind and key >= 0 and math.abs(entity.z - mount.z) < REACH and Godlands.segmentAt(entity.z) then
			local st = watched[key]
			if st and st.entity ~= entity then
				drop(key)
				st = nil
			end
			if not st then
				st = { entity = entity, kind = kind, stage = "idle", ox = 0, oz = 0 }
				st.wait = if kind == "aura" then between(AURA.EVERY) * 0.4
					elseif kind == "charge" then between(CHARGE.EVERY) * 0.4
					elseif kind == "hunt" then between(HUNT.EVERY) * 0.4
					else 0
				watched[key] = st
			end
			seen[key] = true
			if kind == "spikes" then
				trail(st, entity, SPIKE.EVERY, spike)
			elseif kind == "sludge" then
				trail(st, entity, SLUDGE.EVERY, puddle)
			elseif kind == "aura" then
				aura(st, entity, dt, mount)
			elseif kind == "charge" then
				charge(st, entity, dt, mount)
			else
				hunt(st, entity, dt, mount)
			end
		end
	end
	for key in watched do
		if not seen[key] then
			drop(key)
		end
	end
	updateSpikes(dt)
	updatePuddles(dt)
	updateFading(dt)
	confused = math.max(confused - dt, 0)
	stuck = math.max(stuck - dt, 0)
	local text = if confused > 0 then "CONFUSED!" elseif stuck > 0 then "STUCK!" else nil
	gui.Enabled = text ~= nil
	if text then
		label.Text = text
		label.TextColor3 = if confused > 0 then Color3.fromRGB(230, 190, 255) else Color3.fromRGB(214, 224, 120)
		local pulse = 1 + 0.06 * math.sin(os.clock() * 10)
		label.Size = UDim2.fromScale(0.5 * pulse, 0.09 * pulse)
		tint.BackgroundColor3 = if confused > 0 then AURA.COLOR else SLUDGE.COLOR
		tint.BackgroundTransparency = 0.8 + 0.05 * math.sin(os.clock() * 6)
	end
end

function Hazards.offset(key)
	local st = watched[key]
	local lag = gooLag[key] or 0 -- (it runs toward -z: falling behind is +z)
	if st then
		return st.ox, st.oz + lag
	end
	return 0, lag
end

function Hazards.hit(mount, grace)
	local x, z = mount.x, mount.z
	for _, d in puddles do
		local dx, dz = x - d.x, z - d.z
		if not d.mine and dx * dx + dz * dz < d.r * d.r then
			stuck = SLUDGE.STUCK
		end
	end
	if grace then
		return nil
	end
	local reachX, reachZ = SPIKE.WIDTH / 2 + 1.3, SPIKE.WIDTH / 2 + 2.4 -- (the pads Ride's obstacle check uses)
	for _, s in spikes do
		if s.t > SPIKE.RISE * 0.5 and s.t < SPIKE.LIFE and math.abs(x - s.x) < reachX and math.abs(z - s.z) < reachZ then
			return "Spiked by a Soul Horse's trail!"
		end
	end
	for _, st in watched do
		if st.danger then
			local e = st.entity
			local hx, hz = footprint(e)
			local yaw = e.face or 0
			local dx, dz = x - e.x, z - e.z
			-- into the animal's own axes (yaw 0 faces -z)
			local c, s = math.cos(yaw), math.sin(yaw)
			local side, along = dx * c - dz * s, dx * s + dz * c
			if math.abs(side) < hx + 1.3 and math.abs(along) < hz + 2.4 then
				return st.danger
			end
		end
	end
	return nil
end

function Hazards.steerSign()
	return if confused > 0 then -1 else 1
end

function Hazards.slow()
	return if stuck > 0 then SLUDGE.SLOW else 1
end

function Hazards.clear()
	for key in watched do
		drop(key)
	end
	for _, s in spikes do
		for _, p in s.parts do
			p:Destroy()
		end
	end
	for _, d in puddles do
		d.part:Destroy()
	end
	for _, f in fading do
		f.part:Destroy()
	end
	spikes, puddles, fading = {}, {}, {}
	gooLeft, gooLag, Hazards.mine = {}, {}, nil
	confused, stuck = 0, 0
	gui.Enabled = false
end

return Hazards
