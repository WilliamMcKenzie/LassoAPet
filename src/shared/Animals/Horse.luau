-- Horse: the free starter mount.
-- Shape, colour and motion knobs all live in this file so the style can be
-- tuned in one place. Units are studs; the horse faces -Z.
--
--   local horse = Horse.new()
--   horse.model.Parent = workspace
--   horse:update(dt, speed, turn) -- every frame; speed in studs/s, turn -1..1 (+ = right)
--   horse:getSeatCFrame()         -- where the rider's hips go
--   horse:setSaddled(true)

local Rig = require(script.Parent.Rig)
local Quadruped = require(script.Parent.Quadruped)

local COAT = Color3.fromRGB(205, 112, 48)
local MUZZLE = Color3.fromRGB(245, 212, 168)
local HAIR = Color3.fromRGB(96, 56, 34)
local HOOF = Color3.fromRGB(60, 50, 45)
local EYE_WHITE = Color3.fromRGB(250, 250, 250)
local PUPIL = Color3.fromRGB(35, 35, 50)
local BLANKET = Color3.fromRGB(235, 70, 70)
local LEATHER = Color3.fromRGB(110, 70, 44)

-- Classic stud decal from the Creator Store (asset 7447638611), tiled at half-stud size.
local STUD_TEXTURE = { image = "rbxassetid://7447638591", tile = 0.5 }

local BODY_HEIGHT = 5 -- body center above the ground
local SEAT = CFrame.new(0, 2.4, 0.2) -- rider hips, relative to the body center

local GAITS = {
	trot = {
		speed = 16, -- studs/s where the trot is fully in
		stride = 9, -- studs per cycle
		minRate = 1.2,
		maxRate = 2,
		bounces = 2, -- body bounces per cycle
		legPhase = { FL = 0, HR = 0, FR = 0.5, HL = 0.5 },
		hipSwing = { fore = 0.45, hind = 0.4 },
		kneeFlex = { fore = -1.1, hind = -0.7 },
		bob = 0.2,
		pitch = 0.02,
		neckNod = 0.05,
		earsBack = 0.1,
		tailLift = 0.25,
		tailWave = 0.08,
	},
	gallop = {
		speed = 40,
		stride = 16,
		minRate = 1.6,
		maxRate = 2.8,
		bounces = 1,
		legPhase = { HL = 0, HR = 0.1, FL = 0.45, FR = 0.55 },
		hipSwing = { fore = 0.8, hind = 0.65 },
		kneeFlex = { fore = -1.5, hind = -0.9 },
		bob = 0.5,
		pitch = 0.1,
		neckNod = 0.14,
		earsBack = 0.4,
		tailLift = 0.45,
		tailWave = 0.25,
	},
}

local function v(x, y, z)
	return Vector3.new(x, y, z)
end

local function at(x, y, z, pitch)
	return CFrame.new(x, y, z) * CFrame.Angles(pitch or 0, 0, 0)
end

-- Chunky, toy-like proportions: big square head, short thick legs.
local function addLeg(parts, leg, x, z)
	table.insert(parts, { name = "Upper" .. leg, parent = "Body", joint = at(x, -1.2, z), offset = v(0, -0.8, 0), size = v(1.2, 2, 1.3), color = COAT, animated = true })
	table.insert(parts, { name = "Lower" .. leg, parent = "Upper" .. leg, joint = at(0, -0.6, 0), offset = v(0, -0.9, 0), size = v(1, 1.8, 1), color = COAT, animated = true })
	table.insert(parts, { name = "Hoof" .. leg, parent = "Lower" .. leg, joint = at(0, -1.1, 0), size = v(1.15, 0.8, 1.15), color = HOOF })
end

local function parts()
	local list = {
		{ name = "Body", parent = "Root", joint = at(0, BODY_HEIGHT, 0), size = v(3.4, 3.2, 5.4), color = COAT, animated = true },

		{ name = "Neck", parent = "Body", joint = at(0, 1, -2.2, -0.35), offset = v(0, 1, 0), size = v(1.8, 2.4, 1.9), color = COAT, animated = true },
		{ name = "Mane", parent = "Neck", joint = at(0, 0.4, 1), size = v(0.7, 2.6, 0.7), color = HAIR },

		-- The head sits level so the eyes look straight ahead.
		{ name = "Head", parent = "Neck", joint = at(0, 1.2, -0.2, 0.35), offset = v(0, 0.5, -0.8), size = v(2.4, 2.3, 2.6), color = COAT, animated = true },
		{ name = "Muzzle", parent = "Head", joint = at(0, -0.55, -1.5), size = v(2, 1.2, 0.8), color = MUZZLE },
		{ name = "EyeL", parent = "Head", joint = at(-0.6, 0.45, -1.33), size = v(0.9, 1, 0.12), color = EYE_WHITE, plain = true },
		{ name = "EyeR", parent = "Head", joint = at(0.6, 0.45, -1.33), size = v(0.9, 1, 0.12), color = EYE_WHITE, plain = true },
		{ name = "PupilL", parent = "Head", joint = at(-0.48, 0.28, -1.4), size = v(0.45, 0.55, 0.1), color = PUPIL, plain = true },
		{ name = "PupilR", parent = "Head", joint = at(0.48, 0.28, -1.4), size = v(0.45, 0.55, 0.1), color = PUPIL, plain = true },
		{ name = "Forelock", parent = "Head", joint = at(0, 1.25, -0.5), size = v(0.9, 0.3, 1), color = HAIR },
		{ name = "EarL", parent = "Head", joint = at(-0.75, 1.15, 0.6), offset = v(0, 0.45, 0), size = v(0.5, 0.9, 0.4), color = COAT, animated = true },
		{ name = "EarR", parent = "Head", joint = at(0.75, 1.15, 0.6), offset = v(0, 0.45, 0), size = v(0.5, 0.9, 0.4), color = COAT, animated = true },

		{ name = "Tail1", parent = "Body", joint = at(0, 1.2, 2.7, -0.6), offset = v(0, -0.8, 0), size = v(0.9, 1.6, 0.9), color = HAIR, animated = true },
		{ name = "Tail2", parent = "Tail1", joint = at(0, -0.8, 0, 0.35), offset = v(0, -0.9, 0), size = v(1.1, 1.8, 1.1), color = HAIR, animated = true },

		{ name = "Blanket", parent = "Body", joint = at(0, 1.75, 0.2), size = v(3.6, 0.3, 2.8), color = BLANKET, saddle = true },
		{ name = "Saddle", parent = "Body", joint = at(0, 2.05, 0.2), size = v(2.4, 0.5, 2), color = LEATHER, saddle = true },
		{ name = "Horn", parent = "Body", joint = at(0, 2.4, -0.6), size = v(0.6, 0.6, 0.4), color = LEATHER, saddle = true },
	}
	addLeg(list, "FL", -1.05, -1.8)
	addLeg(list, "FR", 1.05, -1.8)
	addLeg(list, "HL", -1.05, 1.8)
	addLeg(list, "HR", 1.05, 1.8)
	return list
end

local Horse = {}
Horse.__index = Horse
Horse.Gaits = GAITS

function Horse.new()
	local spec = parts()
	local model, byName, motors = Rig.build({ name = "Horse", studTexture = STUD_TEXTURE, parts = spec })

	local saddle = {}
	for _, def in ipairs(spec) do
		if def.saddle then
			table.insert(saddle, byName[def.name])
		end
	end

	local self = setmetatable({
		model = model,
		body = byName.Body,
		saddleParts = saddle,
		animator = Quadruped.new(motors, GAITS),
	}, Horse)
	self:setSaddled(false)
	return self
end

function Horse:update(dt, speed, turn)
	self.animator:update(dt, speed, turn)
end

function Horse:getSeatCFrame()
	return self.body.CFrame * SEAT
end

function Horse:setSaddled(saddled)
	for _, part in ipairs(self.saddleParts) do
		part.Transparency = saddled and 0 or 1
	end
end

return Horse
