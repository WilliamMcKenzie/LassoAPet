-- Procedural gait animator for four-legged rigs built by Rig.
-- Blends idle, trot and gallop from speed, and leans into turns.
-- Expects Motor6Ds named Body, Neck, Head, EarL, EarR, Tail1, Tail2 and
-- Upper/Lower + FL, FR, HL, HR. Missing ones are skipped.

local Quadruped = {}
Quadruped.__index = Quadruped

local TAU = 2 * math.pi
local LEGS = { "FL", "FR", "HL", "HR" }
local JOINTS = { "Body", "Neck", "Head", "EarL", "EarR", "Tail1", "Tail2" }
for _, leg in ipairs(LEGS) do
	table.insert(JOINTS, "Upper" .. leg)
	table.insert(JOINTS, "Lower" .. leg)
end

local function clamp01(x)
	return math.max(0, math.min(1, x))
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function blank()
	local pose = {}
	for _, name in ipairs(JOINTS) do
		pose[name] = { 0, 0, 0, 0, 0, 0 } -- x, y, z, rx, ry, rz
	end
	return pose
end

local function blend(a, b, t)
	for name, pa in pairs(a) do
		local pb = b[name]
		for i = 1, 6 do
			pa[i] = lerp(pa[i], pb[i], t)
		end
	end
	return a
end

-- One leg cycle: the hip swings forward while the lower leg folds, then
-- plants and pushes back straight.
local function legs(pose, phase, g)
	for _, leg in ipairs(LEGS) do
		local fore = leg:sub(1, 1) == "F"
		local theta = TAU * (phase + g.legPhase[leg])
		local swing = math.sin(theta)
		local lift = math.max(0, math.cos(theta))
		pose["Upper" .. leg][4] = (fore and g.hipSwing.fore or g.hipSwing.hind) * swing
		pose["Lower" .. leg][4] = (fore and g.kneeFlex.fore or g.kneeFlex.hind) * lift * lift
	end
end

function Quadruped.new(motors, gaits)
	return setmetatable({
		motors = motors,
		gaits = gaits,
		clock = 0,
		phase = 0,
		speed = 0,
		turn = 0,
	}, Quadruped)
end

function Quadruped:idlePose()
	local t = self.clock
	local p = blank()
	p.Body[2] = 0.05 * math.sin(t * 1.6)
	p.Neck[4] = 0.06 * math.sin(t * 0.5)
	p.Neck[5] = 0.3 * math.sin(t * 0.37) * math.sin(t * 0.13)
	p.Head[4] = 0.08 * math.sin(t * 0.7 + 1)
	local swish = math.max(0, math.sin(t * 0.6)) ^ 2
	p.Tail1[6] = 0.35 * math.sin(t * 4) * swish
	p.Tail2[6] = 0.45 * math.sin(t * 4 - 0.9) * swish
	p.EarL[4] = 0.5 * math.max(0, math.sin(t * 1.3)) ^ 12
	p.EarR[4] = 0.5 * math.max(0, math.sin(t * 1.1 + 2)) ^ 12
	-- resting one hind hoof
	p.UpperHL[4] = 0.08
	p.LowerHL[4] = 0.3
	p.Body[6] = 0.02
	return p
end

function Quadruped:runPose(g, phase)
	local p = blank()
	legs(p, phase, g)
	local theta = TAU * phase * g.bounces
	p.Body[2] = g.bob * (0.5 + 0.5 * math.sin(theta))
	p.Body[4] = g.pitch * math.sin(theta - 1.2)
	p.Neck[4] = g.neckNod * math.sin(theta + 0.6)
	p.Head[4] = -0.5 * g.neckNod * math.sin(theta + 0.6)
	p.EarL[4] = g.earsBack
	p.EarR[4] = g.earsBack
	p.Tail1[4] = -g.tailLift + g.tailWave * math.sin(theta)
	p.Tail2[4] = -0.4 * g.tailLift + g.tailWave * math.sin(theta - 1)
	return p
end

function Quadruped:update(dt, speed, turn)
	local gaits = self.gaits
	local k = clamp01(dt * 6)
	self.speed = lerp(self.speed, math.max(0, speed or 0), k)
	self.turn = lerp(self.turn, math.clamp(turn or 0, -1, 1), k)
	self.clock += dt

	local s = self.speed
	local trot, gallop = gaits.trot, gaits.gallop
	local moving = clamp01(s / trot.speed)
	local galloping = clamp01((s - trot.speed) / (gallop.speed - trot.speed))

	local rate = lerp(
		math.clamp(s / trot.stride, trot.minRate, trot.maxRate),
		math.clamp(s / gallop.stride, gallop.minRate, gallop.maxRate),
		galloping
	)
	self.phase = (self.phase + rate * dt * moving) % 1

	local pose = blend(self:runPose(trot, self.phase), self:runPose(gallop, self.phase), galloping)
	pose = blend(self:idlePose(), pose, moving)

	-- lean and look into the turn (+turn = right)
	local lean = self.turn * lerp(0.4, 1, galloping)
	pose.Body[6] -= 0.18 * lean
	pose.Neck[5] -= 0.25 * self.turn
	pose.Head[5] -= 0.15 * self.turn
	pose.Tail1[6] += 0.3 * lean

	for name, motor in pairs(self.motors) do
		local q = pose[name]
		if q then
			motor.Transform = CFrame.new(q[1], q[2], q[3]) * CFrame.Angles(q[4], q[5], q[6])
		end
	end
end

return Quadruped
