-- Horse: the free starter mount.
-- The shape, bones and animations come from QM's Blockbench model
-- (designs/horses/Horse9_Leap.bbmodel), converted into HorseModel.luau by
-- tools/bbmodel_to_luau.py. Units are studs; the horse faces -Z.
--
--   local horse = Horse.new()
--   horse.model.Parent = workspace
--   horse:update(dt, speed, turn) -- every frame; speed in studs/s, turn -1..1 (+ = right);
--                                 -- returns true on the frame a gallop leap lands
--   horse:getSeatCFrame()         -- where the rider's hips go
--   horse:setSaddled(true)        -- no saddle on this design; kept for callers
--   horse:getNeck()               -- { cframe, radius } for a lasso loop around the neck
--   horse:setScale(s)             -- grow or shrink the whole horse about its feet (pop-ins)
--
-- Variants (the Pinto) share all of this and only swap the model data:
--   Horse.variant("Pinto", PintoModel, "Uncommon")
--
-- Idle, walk and gallop are blended by speed. The gallop is a leap: front legs
-- reach forward and hind legs back while the horse is in the air. The blocks
-- only ever rotate one way from rest (front legs and neck forward, hind legs
-- back), so blending never shows hidden faces.

local Rig = require(script.Parent.Rig)
local HorseModel = require(script.Parent.HorseModel)

-- Classic stud decal from the Creator Store (asset 7447638611), tiled at half-stud size.
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }

local SEAT = Vector3.new(0, 7.3, 1) -- rider hips, on the back stripe
local NECK_LOOP = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 }

-- Blending by speed (studs/s)
local WALK_IN = 6 -- idle -> walk fully in
local GALLOP_FROM, GALLOP_IN = 12, 24 -- walk -> gallop
local WALK_SPEED = 8 -- walk plays at 1x at this speed
local GALLOP_SPEED = 36 -- gallop plays at 1x at this speed
local LEAN = 0.18 -- body roll into turns, radians at full gallop

-- When a gallop leap lands: the front legs are back at rest after reaching out.
local function landAt(data)
	local reached = false
	for _, key in data.animations.gallop.tracks.LegFL.rotation.keys do
		if key[2] ~= 0 then
			reached = true
		elseif reached then
			return key[1]
		end
	end
	return 0
end

local function clamp01(x)
	return math.max(0, math.min(1, x))
end

local Horse = {} -- the methods every variant shares

-- A kind of horse: its own model data and rarity, Horse's methods.
local function variant(name, data, rarity)
	local class = setmetatable({
		Name = name,
		Rarity = rarity, -- sets the coins for lassoing one (Config.RarityCoins)
		data = data,
		landAt = landAt(data),
	}, { __index = Horse })
	class.__index = class

	function class.new()
		local model, byName, bones, pivots = Rig.fromData(data, name, STUD_TEXTURE)

		local clocks = {}
		for anim in pairs(data.animations) do
			clocks[anim] = 0
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
			scale = 1,
		}, class)
	end

	return class
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

	local before = self.clocks.gallop
	local pose = {}
	for name, anim in pairs(self.data.animations) do
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
					local x, y, z = Rig.sample(track.position, t)
					p[1] += x * w
					p[2] += y * w
					p[3] += z * w
				end
				if track.rotation then
					local x, y, z = Rig.sample(track.rotation, t)
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

	local sc = self.scale -- animation offsets are in studs at full size
	for bone, motor in pairs(self.bones) do
		local p = pose[bone]
		motor.Transform = if p then CFrame.new(p[1] * sc, p[2] * sc, p[3] * sc) * CFrame.Angles(p[4], p[5], p[6]) else CFrame.identity
	end

	local after = self.clocks.gallop
	local land = self.landAt
	local crossed = if after >= before then before < land and after >= land else before < land or after >= land
	return crossed and weights.gallop > 0.5
end

function Horse:getSeatCFrame()
	return self.root.CFrame * CFrame.new(SEAT - self.pivots.root)
end

function Horse:getNeck()
	return { cframe = self.neck.CFrame * CFrame.new(NECK_LOOP.center - self.pivots.neck), radius = NECK_LOOP.radius }
end

function Horse:setSaddled(_saddled) end

-- Model:ScaleTo scales relative to the current size, so keep it well above the
-- smallest part size (0.001): the thinnest plates are 0.05 studs.
local MIN_SCALE = 0.05

function Horse:setScale(s)
	s = math.max(s, MIN_SCALE)
	if s ~= self.scale then
		self.model:ScaleTo(s)
		self.scale = s
	end
end

local Common = variant("Horse", HorseModel, "Common")
Common.variant = variant
return Common
