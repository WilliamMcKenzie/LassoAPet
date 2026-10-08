-- Holding on for dear life (QM, Oct 8: the new lasso, phase 1): once the loop's round
-- the lassoed animal's neck, the rider is yanked off their old mount and hangs off
-- the end of the rope, flying behind the animal as it runs, before hopping on
-- (Ride.client's transfer: throw -> hang -> pull). Config.LassoHang.
--
-- It has to feel fast and high-stakes, not floaty (QM): the rider is locked directly
-- behind the animal on its heading, high up with the rope rising to them from the
-- neck, following its turns near-instantly. The speed comes from the shaking: quick
-- small jolts, a hard tug on the rope every so often, the body streamed straight back
-- (head and arms to the animal, belly down) with the legs fluttering.
--
--   local hang = RopeHang.start(fromPosition, character)
--   RopeHang.update(hang, dt, neckPosition, heading) -> the rider's root CFrame this frame
--   RopeHang.pose(hang)                              -- arms up the rope, legs fluttering
--   RopeHang.stop(hang)                              -- limbs back to normal

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

function RopeHang.start(from, character)
	return {
		pos = from,
		t = 0,
		tug = 0, -- seconds since the last hard tug
		kick = 0, -- the tug's jolt, dying away
		joints = joints(character),
		seed = math.random() * 100,
	}
end

function RopeHang.update(hang, dt, neck, heading)
	local cfg = Config.LassoHang
	hang.t += dt
	heading = Vector3.new(heading.X, 0, heading.Z)
	heading = if heading.Magnitude > 0.01 then heading.Unit else -Vector3.zAxis
	local side = heading:Cross(Vector3.yAxis)

	-- Straight behind, high up: the rope rises from the neck to you.
	local back = math.sqrt(math.max(cfg.Rope * cfg.Rope - cfg.Height * cfg.Height, 1))
	local want = neck - heading * back + Vector3.new(0, cfg.Height, 0)
	hang.pos = hang.pos:Lerp(want, 1 - math.exp(-cfg.Follow * dt))

	-- A hard tug every TugEvery seconds or so: yanked forward, then streaming back.
	hang.tug += dt
	if hang.tug >= cfg.TugEvery * (0.7 + 0.6 * math.abs(math.sin(hang.t * 7.3 + hang.seed))) then
		hang.tug, hang.kick = 0, 1
	end
	hang.kick *= math.exp(-12 * dt)

	-- Quick small jolts (not slow sway).
	local t, s = hang.t + hang.seed, cfg.Shake
	local jolt = side * (math.sin(t * 23) * 0.6 + math.sin(t * 37) * 0.4) * s
		+ Vector3.yAxis * (math.sin(t * 29) * 0.6 + math.sin(t * 17) * 0.4) * s
		+ heading * hang.kick * cfg.Tug
	local pos = hang.pos + jolt

	-- Stretched straight back along the heading: head to the animal, belly down, a
	-- little rattle in the roll and pitch.
	local cf = CFrame.fromMatrix(pos, side, heading, Vector3.yAxis)
	return cf * CFrame.Angles(math.sin(t * 19) * 0.06 - hang.kick * 0.25, 0, math.sin(t * 27) * 0.08)
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
	local t = hang.t + hang.seed
	local grip = math.sin(t * 21) * 0.05
	-- Both hands up on the rope over the head, pulled straight (the right one holds the end).
	pose(hang, "RightShoulder", math.pi * 0.97 + grip, 0, -0.08)
	pose(hang, "LeftShoulder", math.pi * 0.97 - grip, 0, 0.08)
	pose(hang, "RightElbow", 0.1, 0, 0)
	pose(hang, "LeftElbow", 0.1, 0, 0)
	-- Legs streaming straight back, fluttering fast in the wind.
	local flutter = math.sin(t * 24)
	pose(hang, "RightHip", flutter * 0.18, 0, 0.05)
	pose(hang, "LeftHip", -flutter * 0.18, 0, -0.05)
	pose(hang, "RightKnee", -0.1 - math.max(flutter, 0) * 0.2, 0, 0)
	pose(hang, "LeftKnee", -0.1 - math.max(-flutter, 0) * 0.2, 0, 0)
	pose(hang, "Waist", 0, 0, 0)
end

function RopeHang.stop(hang)
	for _, joint in hang.joints do
		joint.Transform = CFrame.identity
	end
end

return RopeHang
