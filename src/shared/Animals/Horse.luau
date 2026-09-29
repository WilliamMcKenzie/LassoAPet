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

local COAT = Color3.fromRGB(163, 104, 63)
local MUZZLE = Color3.fromRGB(122, 77, 48)
local HAIR = Color3.fromRGB(56, 40, 32)
local HOOF = Color3.fromRGB(44, 36, 32)
local EYE = Color3.fromRGB(20, 20, 20)
local BLANKET = Color3.fromRGB(151, 60, 52)
local LEATHER = Color3.fromRGB(92, 58, 38)

local STUDS = Enum.SurfaceType.Studs
local STUD_FACES = {
	Top = STUDS,
	Front = STUDS,
	Back = STUDS,
	Left = STUDS,
	Right = STUDS,
	Bottom = Enum.SurfaceType.Inlet,
}

local BODY_HEIGHT = 6 -- body center above the ground
local SEAT = CFrame.new(0, 2.2, 0.2) -- rider hips, relative to the body center

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

local function addLeg(parts, leg, x, z)
	table.insert(parts, { name = "Upper" .. leg, parent = "Body", joint = at(x, -1.2, z), offset = v(0, -0.9, 0), size = v(1, 2.4, 1.2), color = COAT, animated = true })
	table.insert(parts, { name = "Lower" .. leg, parent = "Upper" .. leg, joint = at(0, -1.2, 0), offset = v(0, -1, 0), size = v(0.8, 2.3, 0.8), color = COAT, animated = true })
	table.insert(parts, { name = "Hoof" .. leg, parent = "Lower" .. leg, joint = at(0, -1.4, 0), size = v(1, 0.6, 1), color = HOOF })
end

local function parts()
	local list = {
		{ name = "Body", parent = "Root", joint = at(0, BODY_HEIGHT, 0), size = v(3, 3, 6.4), color = COAT, animated = true },

		{ name = "Neck", parent = "Body", joint = at(0, 1, -2.6, -0.55), offset = v(0, 1.5, 0), size = v(1.6, 3.4, 1.8), color = COAT, animated = true },
		{ name = "Mane", parent = "Neck", joint = at(0, 0.3, 0.95), size = v(0.5, 3.4, 0.6), color = HAIR },

		{ name = "Head", parent = "Neck", joint = at(0, 1.5, -0.1, 0.2), offset = v(0, 0.35, -0.9), size = v(1.6, 1.7, 3), color = COAT, animated = true },
		{ name = "Muzzle", parent = "Head", joint = at(0, -0.25, -1.75), size = v(1.5, 1.3, 1.1), color = MUZZLE },
		{ name = "EyeL", parent = "Head", joint = at(-0.81, 0.35, -0.3), size = v(0.2, 0.45, 0.45), color = EYE },
		{ name = "EyeR", parent = "Head", joint = at(0.81, 0.35, -0.3), size = v(0.2, 0.45, 0.45), color = EYE },
		{ name = "EarL", parent = "Head", joint = at(-0.5, 0.85, 0.7), offset = v(0, 0.4, 0), size = v(0.45, 0.8, 0.35), color = COAT, animated = true },
		{ name = "EarR", parent = "Head", joint = at(0.5, 0.85, 0.7), offset = v(0, 0.4, 0), size = v(0.45, 0.8, 0.35), color = COAT, animated = true },

		{ name = "Tail1", parent = "Body", joint = at(0, 1.1, 3.2, -0.6), offset = v(0, -0.8, 0), size = v(0.8, 1.8, 0.8), color = HAIR, animated = true },
		{ name = "Tail2", parent = "Tail1", joint = at(0, -0.8, 0, 0.35), offset = v(0, -0.9, 0), size = v(1, 2, 1), color = HAIR, animated = true },

		{ name = "Blanket", parent = "Body", joint = at(0, 1.6, 0.2), size = v(3.2, 0.3, 2.8), color = BLANKET, saddle = true },
		{ name = "Saddle", parent = "Body", joint = at(0, 1.95, 0.2), size = v(2.2, 0.5, 2), color = LEATHER, saddle = true },
		{ name = "Horn", parent = "Body", joint = at(0, 2.3, -0.6), size = v(0.6, 0.6, 0.4), color = LEATHER, saddle = true },
	}
	addLeg(list, "FL", -0.95, -2.4)
	addLeg(list, "FR", 0.95, -2.4)
	addLeg(list, "HL", -0.95, 2.4)
	addLeg(list, "HR", 0.95, 2.4)
	return list
end

local Horse = {}
Horse.__index = Horse
Horse.Gaits = GAITS

function Horse.new()
	local spec = parts()
	local model, byName, motors = Rig.build({ name = "Horse", studFaces = STUD_FACES, parts = spec })

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
