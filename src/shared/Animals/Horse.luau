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
-- Every other animal (Pinto, Pig, Fish, Rhino, Unicorn) shares all of this and
-- only swaps the model data, plus its seat and neck-loop points if they differ
-- from the horse's (designs/animals/meta.json):
--   Horse.variant("Pinto", PintoModel, "Uncommon")
--   Horse.variant("Pig", PigModel, "Uncommon", { seat = ..., neck = { center = ..., radius = ... } })
--
-- Idle, walk and gallop are blended by speed. The gallop is a leap: front legs
-- reach forward and hind legs back while the horse is in the air. The blocks
-- only ever rotate one way from rest (front legs and neck forward, hind legs
-- back), so blending never shows hidden faces.

local Config = require(script.Parent.Parent.Config)
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
-- nil for animals without legs (the Fish), which never kick up dust.
local function landAt(data)
	local legs = data.animations.gallop.tracks.LegFL
	if not (legs and legs.rotation) then
		return nil
	end
	local reached = false
	for _, key in legs.rotation.keys do
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

-- How big a model reads, in studs: the square root of its box's two biggest sides
-- multiplied (Config.PetSmallSize).
local function silhouette(data)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, part in data.parts do
		if not part.hidden then
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = part.cframe:GetComponents()
			local h = part.size / 2
			local e = Vector3.new(
				math.abs(r00) * h.X + math.abs(r01) * h.Y + math.abs(r02) * h.Z,
				math.abs(r10) * h.X + math.abs(r11) * h.Y + math.abs(r12) * h.Z,
				math.abs(r20) * h.X + math.abs(r21) * h.Y + math.abs(r22) * h.Z
			)
			local c = Vector3.new(x, y, z)
			lo, hi = lo:Min(c - e), hi:Max(c + e)
		end
	end
	local d = hi - lo
	local sides = { d.X, d.Y, d.Z }
	table.sort(sides)
	return math.sqrt(sides[2] * sides[3])
end

-- The size that makes an animal of this tier read TierGrowth x the tier below.
local function tierSize(name, data)
	local tier = Config.PetTiers[name] or 1
	local size = Config.PetSmallSize * Config.TierGrowth ^ (tier - 1) / silhouette(data)
	return math.round(size * 100) / 100 -- one template per animal (Rig caches by size)
end

local Horse = {} -- the methods every variant shares

-- A kind of animal: its own model data and rarity, Horse's methods.
-- points (optional): { seat = Vector3, neck = { center = Vector3, radius = number },
-- seatOnNeck = true (the seat rides on the neck bone, e.g. a squid's mantle, which
-- its run swings about: the rider moves with it but stays upright),
-- size = number (the whole animal scaled up from its model; by default sized to its
-- tier, Config.PetTiers) }
local function variant(name, data, rarity, points)
	points = points or {}
	local class = setmetatable({
		Name = name,
		Rarity = rarity, -- sets the coins for lassoing one (Config.RarityCoins)
		data = data,
		landAt = landAt(data),
		seat = points.seat or SEAT,
		seatOnNeck = points.seatOnNeck,
		neckLoop = points.neck or NECK_LOOP,
		size = points.size or tierSize(name, data),
	}, { __index = Horse })
	class.__index = class

	function class.new()
		local model, byName, bones, pivots = Rig.fromData(data, name, STUD_TEXTURE, class.size)

		local clocks = {}
		for anim in pairs(data.animations) do
			clocks[anim] = 0
		end

		-- Reused every frame (see update): one { x, y, z, rx, ry, rz } per bone.
		local pose = {}
		for bone in pairs(bones) do
			pose[bone] = { 0, 0, 0, 0, 0, 0 }
		end
		pose.root = pose.root or { 0, 0, 0, 0, 0, 0 }

		return setmetatable({
			model = model,
			root = byName.rootBone,
			neck = byName.neckBone,
			pivots = pivots,
			bones = bones,
			clocks = clocks,
			pose = pose,
			-- What ScaleTo calls this model's own size (class.size, if the copy kept
			-- its template's scale factor), so setScale works either way.
			baseScale = model:GetScale(),
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
	-- No tables made here: this runs for every animal every frame, and fresh
	-- tables each time pile up garbage that the collector stops the game to clear.
	local wIdle, wWalk, wGallop = 1 - moving, moving * (1 - galloping), moving * galloping
	local rWalk, rGallop = math.clamp(s / WALK_SPEED, 0.6, 1.8), math.clamp(s / GALLOP_SPEED, 0.8, 1.4)

	local before = self.clocks.gallop
	local pose = self.pose
	for _, p in pairs(pose) do
		p[1], p[2], p[3], p[4], p[5], p[6] = 0, 0, 0, 0, 0, 0
	end
	for name, anim in pairs(self.data.animations) do
		local w, rate = 0, 1
		if name == "idle" then
			w = wIdle
		elseif name == "walk" then
			w, rate = wWalk, rWalk
		elseif name == "gallop" then
			w, rate = wGallop, rGallop
		end
		self.clocks[name] = (self.clocks[name] + dt * rate) % anim.length
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
	local rootPose = pose.root
	rootPose[6] -= LEAN * self.turn * (0.4 + 0.6 * galloping)

	local sc = self.scale * self.size -- animation offsets are in studs at the model's own size
	for bone, motor in pairs(self.bones) do
		local p = pose[bone]
		motor.Transform = CFrame.new(p[1] * sc, p[2] * sc, p[3] * sc) * CFrame.Angles(p[4], p[5], p[6])
	end

	local after = self.clocks.gallop
	local land = self.landAt
	if not land then
		return false
	end
	local crossed = if after >= before then before < land and after >= land else before < land or after >= land
	return crossed and wGallop > 0.5
end

function Horse:getSeatCFrame()
	if self.seatOnNeck then
		local at = self.neck.CFrame * CFrame.new((self.seat - self.pivots.neck) * self.size)
		return CFrame.new(at.Position) * self.root.CFrame.Rotation
	end
	return self.root.CFrame * CFrame.new((self.seat - self.pivots.root) * self.size)
end

function Horse:getNeck()
	local loop = self.neckLoop
	return { cframe = self.neck.CFrame * CFrame.new((loop.center - self.pivots.neck) * self.size), radius = loop.radius * self.size }
end

function Horse:setSaddled(_saddled) end

-- Model:ScaleTo scales relative to the current size, so keep it well above the
-- smallest part size (0.001): the thinnest plates are 0.05 studs.
local MIN_SCALE = 0.05

-- s is relative to the animal's own size (its `size` point).
function Horse:setScale(s)
	s = math.max(s, MIN_SCALE)
	if s ~= self.scale then
		self.model:ScaleTo(s * self.baseScale)
		self.scale = s
	end
end

local Common = variant("Horse", HorseModel, "Common")
Common.variant = variant
return Common
