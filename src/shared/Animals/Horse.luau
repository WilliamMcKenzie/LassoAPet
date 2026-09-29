-- Horse: the free starter mount.
-- The shape, bones and animations come from QM's Blockbench model
-- (designs/horses/Horse7_ToyRig.bbmodel), converted into HorseModel.luau by
-- tools/bbmodel_to_luau.py. Units are studs; the horse faces -Z.
--
--   local horse = Horse.new()
--   horse.model.Parent = workspace
--   horse:update(dt, speed, turn) -- every frame; speed in studs/s, turn -1..1 (+ = right)
--   horse:getSeatCFrame()         -- where the rider's hips go
--   horse:setSaddled(true)        -- no saddle on this design; kept for callers
--   horse:getNeck()               -- { cframe, radius } for a lasso loop around the neck
--
-- Idle, walk and gallop are blended by speed. The blocks only ever rotate one
-- way from rest (legs and neck forward), so blending never shows hidden faces.

local Rig = require(script.Parent.Rig)
local HorseModel = require(script.Parent.HorseModel)

-- Classic stud decal from the Creator Store (asset 7447638611), tiled at half-stud size.
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }

local SEAT = Vector3.new(0, 7.3, 1) -- rider hips, behind the mane
local NECK_LOOP = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 }

-- Blending by speed (studs/s)
local WALK_IN = 6 -- idle -> walk fully in
local GALLOP_FROM, GALLOP_IN = 12, 24 -- walk -> gallop
local WALK_SPEED = 8 -- walk plays at 1x at this speed
local GALLOP_SPEED = 36 -- gallop plays at 1x at this speed
local LEAN = 0.18 -- body roll into turns, radians at full gallop

local function clamp01(x)
	return math.max(0, math.min(1, x))
end

local function sample(track, t)
	local keys = track.keys
	local n = #keys
	if t <= keys[1][1] then
		return keys[1][2], keys[1][3], keys[1][4]
	end
	if t >= keys[n][1] then
		return keys[n][2], keys[n][3], keys[n][4]
	end
	local i = 1
	while keys[i + 1][1] < t do
		i += 1
	end
	local a, b = keys[i], keys[i + 1]
	local u = (t - a[1]) / (b[1] - a[1])
	local out = {}
	for c = 2, 4 do
		if track.smooth then
			-- Catmull-Rom through the neighbouring keys, like Blockbench
			local p0 = keys[math.max(i - 1, 1)][c]
			local p1, p2 = a[c], b[c]
			local p3 = keys[math.min(i + 2, n)][c]
			out[c - 1] = 0.5
				* (2 * p1 + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u)
		else
			out[c - 1] = a[c] + (b[c] - a[c]) * u
		end
	end
	return out[1], out[2], out[3]
end

local function spec()
	local list = {}
	local pivots = {}
	for _, bone in ipairs(HorseModel.bones) do
		local parentPivot = bone.parent and pivots[bone.parent] or Vector3.zero
		pivots[bone.name] = bone.pivot
		table.insert(list, {
			name = bone.name .. "Bone",
			parent = bone.parent and bone.parent .. "Bone" or "Root",
			joint = CFrame.new(bone.pivot - parentPivot),
			size = Vector3.new(0.2, 0.2, 0.2),
			color = Color3.new(1, 1, 1),
			hidden = true,
			animated = true,
		})
	end
	for _, part in ipairs(HorseModel.parts) do
		table.insert(list, {
			name = part.name,
			parent = part.bone .. "Bone",
			joint = CFrame.new(-pivots[part.bone]) * part.cframe,
			size = part.size,
			color = part.color,
			class = part.class,
			plain = part.plain,
		})
	end
	return list, pivots
end

local Horse = {}
Horse.__index = Horse
Horse.Rarity = "Common" -- sets the coins for lassoing one (Config.RarityCoins)

function Horse.new()
	local list, pivots = spec()
	local model, byName, motors = Rig.build({ name = "Horse", studTexture = STUD_TEXTURE, parts = list })

	local bones = {}
	for _, bone in ipairs(HorseModel.bones) do
		bones[bone.name] = motors[bone.name .. "Bone"]
	end

	local clocks = {}
	for name in pairs(HorseModel.animations) do
		clocks[name] = 0
	end

	return setmetatable({
		model = model,
		root = byName.rootBone,
		neck = byName.neckBone,
		pivots = pivots,
		bones = bones,
		clocks = clocks,
		speed = 0,
		turn = 0,
	}, Horse)
end

function Horse:update(dt, speed, turn)
	local k = clamp01(dt * 6)
	self.speed += (math.max(0, speed or 0) - self.speed) * k
	self.turn += (math.clamp(turn or 0, -1, 1) - self.turn) * k
	local s = self.speed

	local moving = clamp01(s / WALK_IN)
	local galloping = clamp01((s - GALLOP_FROM) / (GALLOP_IN - GALLOP_FROM))
	local weights = {
		idle = 1 - moving,
		walk = moving * (1 - galloping),
		gallop = moving * galloping,
	}
	local rates = {
		idle = 1,
		walk = math.clamp(s / WALK_SPEED, 0.6, 1.8),
		gallop = math.clamp(s / GALLOP_SPEED, 0.8, 1.4),
	}

	local pose = {}
	for name, anim in pairs(HorseModel.animations) do
		self.clocks[name] = (self.clocks[name] + dt * (rates[name] or 1)) % anim.length
		local w = weights[name] or 0
		if w > 0 then
			local t = self.clocks[name]
			for bone, track in pairs(anim.tracks) do
				local p = pose[bone]
				if not p then
					p = { 0, 0, 0, 0, 0, 0 } -- x, y, z, rx, ry, rz
					pose[bone] = p
				end
				if track.position then
					local x, y, z = sample(track.position, t)
					p[1] += x * w
					p[2] += y * w
					p[3] += z * w
				end
				if track.rotation then
					local x, y, z = sample(track.rotation, t)
					p[4] += x * w
					p[5] += y * w
					p[6] += z * w
				end
			end
		end
	end

	-- roll into turns (+turn = right)
	local rootPose = pose.root or { 0, 0, 0, 0, 0, 0 }
	pose.root = rootPose
	rootPose[6] -= LEAN * self.turn * (0.4 + 0.6 * galloping)

	for bone, motor in pairs(self.bones) do
		local p = pose[bone]
		motor.Transform = if p then CFrame.new(p[1], p[2], p[3]) * CFrame.Angles(p[4], p[5], p[6]) else CFrame.identity
	end
end

function Horse:getSeatCFrame()
	return self.root.CFrame * CFrame.new(SEAT - self.pivots.root)
end

function Horse:getNeck()
	return { cframe = self.neck.CFrame * CFrame.new(NECK_LOOP.center - self.pivots.neck), radius = NECK_LOOP.radius }
end

function Horse:setSaddled(_saddled) end

return Horse
