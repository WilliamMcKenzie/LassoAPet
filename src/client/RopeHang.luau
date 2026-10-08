-- Holding on for dear life (QM, Oct 8: the new lasso, phase 1): once the loop's round
-- the lassoed animal's neck, the rider is yanked off their old mount and hangs off
-- the end of the rope, dragged through the air behind the animal as it runs, before
-- hopping on (Ride.client's transfer: throw -> hang -> pull). Config.LassoHang.
--
-- The rider is a weight on a rope tied to the neck: it swings under gravity (a light
-- one: they're flying, not dragging along the floor), the rope never stretches past
-- its length, the air holds them up behind the animal, and they never touch the
-- ground. So they trail straight out behind at a gallop, swing wide when it turns and
-- slump in when it slows. Both arms reach up the rope, the legs kick.
--
--   local hang = RopeHang.start(fromPosition, neckPosition, character)
--   RopeHang.update(hang, dt, neckPosition) -> the rider's root CFrame this frame
--   RopeHang.pose(hang)                     -- arms up the rope, legs flailing (after the Animator)
--   RopeHang.stop(hang)                     -- limbs back to normal

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local RopeHang = {}

local function joints(character)
	local found = {}
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
			found[joint.Name:gsub(" ", "")] = joint
		end
	end
	return found
end

function RopeHang.start(from, neck, character)
	local cfg = Config.LassoHang
	local away = from - neck
	return {
		pos = from,
		vel = Vector3.zero,
		last = neck,
		length = math.max(cfg.Rope, math.min(away.Magnitude, cfg.Rope * 1.5)), -- reels in to Rope if thrown from further
		t = 0,
		joints = joints(character),
		flail = math.random() * 10,
		cframe = CFrame.lookAt(from, neck),
	}
end

function RopeHang.update(hang, dt, neck)
	local cfg = Config.LassoHang
	dt = math.min(dt, 1 / 20)
	hang.t += dt
	hang.length += (cfg.Rope - hang.length) * (1 - math.exp(-4 * dt))
	local anchorVel = (neck - hang.last) / math.max(dt, 1e-3)
	hang.last = neck

	-- Gravity, the air's drag (relative to still air) and its lift: the faster you're
	-- dragged, the more it holds you up.
	local speed = hang.vel.Magnitude
	local accel = Vector3.new(0, -cfg.Gravity + math.min(speed * cfg.Lift, cfg.Gravity * 0.9), 0) - hang.vel * cfg.Drag
	hang.vel += accel * dt
	local pos = hang.pos + hang.vel * dt

	-- The rope: never longer than its length. Pulled taut, the rider takes the
	-- rope's direction of the anchor's speed (that's the yank).
	local rope = pos - neck
	local d = rope.Magnitude
	if d > hang.length then
		local dir = rope / d
		pos = neck + dir * hang.length
		local radial = hang.vel:Dot(dir) - anchorVel:Dot(dir)
		if radial > 0 then
			hang.vel -= dir * radial
		end
	end
	-- Never down to the floor: a bounce off the air just above it.
	if pos.Y < cfg.MinHeight then
		pos = Vector3.new(pos.X, cfg.MinHeight, pos.Z)
		if hang.vel.Y < 0 then
			hang.vel = Vector3.new(hang.vel.X, -hang.vel.Y * 0.3, hang.vel.Z)
		end
	end
	hang.pos = pos

	-- Stretched out along the rope: head and arms towards the neck, belly down, the
	-- body twisting a little as it swings.
	local up = (neck - pos)
	up = if up.Magnitude > 0.1 then up.Unit else Vector3.yAxis
	local side = up:Cross(Vector3.yAxis)
	side = if side.Magnitude > 0.1 then side.Unit else Vector3.xAxis
	local back = side:Cross(up).Unit
	local twist = math.sin(hang.t * 3.1 + hang.flail) * 0.25
	hang.cframe = CFrame.fromMatrix(pos, side, up, back) * CFrame.Angles(0, twist, 0)
	return hang.cframe
end

-- In the torso's axes, like PodiumLasso's (R6's joints have other local axes).
local function pose(hang, name, x, y, z)
	local joint = hang.joints[name]
	if joint then
		local basis = if joint:IsA("Motor6D") then joint.C0.Rotation else joint.Attachment0.CFrame.Rotation
		joint.Transform = basis:Inverse() * CFrame.Angles(x, y, z) * basis
	end
end

function RopeHang.pose(hang)
	local t = hang.t + hang.flail
	local grip = math.sin(t * 7) * 0.08
	-- Both hands up on the rope over the head (the right one holds the lasso's end).
	pose(hang, "RightShoulder", math.pi * 0.95 + grip, 0, -0.15)
	pose(hang, "LeftShoulder", math.pi * 0.95 - grip, 0, 0.15)
	pose(hang, "RightElbow", 0.25, 0, 0)
	pose(hang, "LeftElbow", 0.25, 0, 0)
	-- Legs kicking, out of step.
	local kick = math.sin(t * 11)
	pose(hang, "RightHip", kick * 0.7, 0, 0.1)
	pose(hang, "LeftHip", -kick * 0.7, 0, -0.1)
	pose(hang, "RightKnee", -0.5 - math.max(kick, 0) * 0.6, 0, 0)
	pose(hang, "LeftKnee", -0.5 - math.max(-kick, 0) * 0.6, 0, 0)
	pose(hang, "Waist", math.sin(t * 5) * 0.12, 0, 0)
end

function RopeHang.stop(hang)
	for _, joint in hang.joints do
		joint.Transform = CFrame.identity
	end
end

return RopeHang
