-- Holding on for dear life (QM, Oct 8: the new lasso, phase 1): once the loop's round
-- the lassoed animal's neck, the rider is yanked off their old mount and hangs off
-- the end of the rope, flying behind the animal as it runs, before hopping on
-- (Ride.client's transfer: throw -> hang -> pull). Config.LassoHang.
--
-- Locked straight behind the animal and high up (QM: fast and high-stakes, never
-- drifting), with the rope waving in the wind round that line: seen from above it
-- ripples side to side in a wave travelling back along it to you (like QM's canvas
-- sine waves: sin(k x - c t), its height breathing over time), and you swing at its
-- end. Not a pure sine (QM): smooth noise in its height and timing and a second,
-- unrelated ripple on top keep the peaks and valleys from repeating. The rope is
-- drawn here as a chain of beams along that curve (the lasso's own hand rope hides).
--
--   local hang = RopeHang.start(fromPosition, character)
--   RopeHang.update(hang, dt, neckPosition, heading) -> the rider's root CFrame this frame
--   RopeHang.pose(hang)                              -- arms up the rope, legs fluttering, the rope drawn
--   RopeHang.stop(hang)                              -- limbs back, rope gone

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local LassoTiers = require(script.Parent.LassoTiers)

local ROPE_COLOR = Color3.fromRGB(222, 184, 120) -- Lasso's
local ROPE_WIDTH = 0.28

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

function RopeHang.start(from, character, tier)
	local cfg = Config.LassoHang
	local anchor = Instance.new("Part")
	anchor.Name = "HangRope"
	anchor.Anchored = true
	anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.identity -- (attachment positions are world positions)
	local points, beams = {}, {}
	for i = 0, cfg.Segments do
		local a = Instance.new("Attachment")
		a.Parent = anchor
		points[i] = a
		if i > 0 then
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = points[i - 1], a
			local width = ROPE_WIDTH * (if tier then tier.rope.width else 1)
			b.Width0, b.Width1 = width, width
			b.Color = if tier then LassoTiers.ropeColor(tier, i, cfg.Segments, 0) else ColorSequence.new(ROPE_COLOR)
			if tier then
				b.LightEmission, b.LightInfluence = tier.rope.glow, 1 - tier.rope.glow
			end
			b.Transparency = NumberSequence.new(0)
			b.FaceCamera = true
			b.Segments = 1
			b.Parent = anchor
			table.insert(beams, b)
		end
	end
	anchor.Parent = workspace
	return {
		pos = from,
		t = 0,
		joints = joints(character),
		hand = character:FindFirstChild("RightGripAttachment", true),
		seed = math.random() * 100,
		anchor = anchor,
		points = points,
		tier = tier, -- (the lasso's: LassoTiers; a rainbow one keeps turning)
		beams = beams,
	}
end

-- The rope's sideways offset at distance s along it from the neck (0 there, growing
-- towards you), at time t: a wave travelling back towards you, plus noise.
local function offset(hang, s, t)
	local cfg = Config.LassoHang
	local k = 2 * math.pi / cfg.WaveLength
	local seed = hang.seed
	-- its height breathes (QM's sin(counter) envelope) and wanders (smooth noise)
	local height = cfg.Wave * (0.75 + 0.25 * math.sin(t * cfg.Breathe * 2 * math.pi + seed))
		* (1 + cfg.Noise * 2 * math.noise(t * 0.7, seed, 0.5))
	local phase = cfg.Noise * 4 * math.noise(t * 0.45, seed, 3.7) -- the peaks come early and late
	local main = math.sin(k * s - k * cfg.WaveSpeed * t + phase)
	local ripple = 0.3 * math.sin(k * 2.37 * s - k * cfg.WaveSpeed * 1.61 * t + seed)
	local grow = math.clamp(s / cfg.Rope, 0, 1) ^ 0.8 -- tied fast at the neck, freest at your end
	return height * grow * (main + ripple)
end

function RopeHang.update(hang, dt, neck, heading)
	local cfg = Config.LassoHang
	hang.t += dt
	heading = Vector3.new(heading.X, 0, heading.Z)
	heading = if heading.Magnitude > 0.01 then heading.Unit else -Vector3.zAxis
	local side = heading:Cross(Vector3.yAxis)
	hang.neck, hang.heading, hang.side = neck, heading, side

	-- Straight behind, high up (the rope rises from the neck to you): locked there,
	-- following its turns near-instantly; the wave swings you about that line.
	local back = math.sqrt(math.max(cfg.Rope * cfg.Rope - cfg.Height * cfg.Height, 1))
	local want = neck - heading * back + Vector3.new(0, cfg.Height, 0)
	hang.pos = hang.pos:Lerp(want, 1 - math.exp(-cfg.Follow * dt))
	local swing = offset(hang, cfg.Rope, hang.t)
	local pos = hang.pos + side * swing

	-- Stretched along the rope's end (head and arms to the animal, belly down), turned
	-- with the wave's slope there and rolling into it.
	local slope = (offset(hang, cfg.Rope, hang.t) - offset(hang, cfg.Rope - 1, hang.t))
	local cf = CFrame.fromMatrix(pos, side, heading, Vector3.yAxis)
	return CFrame.new(pos) * CFrame.Angles(0, -math.atan(slope), 0) * cf.Rotation * CFrame.Angles(0, swing * 0.0625, 0)
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
	local cfg = Config.LassoHang
	local t = hang.t + hang.seed
	-- Both hands up on the rope over the head (the right one holds the end).
	pose(hang, "RightShoulder", math.pi * 0.97, 0, -0.08)
	pose(hang, "LeftShoulder", math.pi * 0.97, 0, 0.08)
	pose(hang, "RightElbow", 0.1, 0, 0)
	pose(hang, "LeftElbow", 0.1, 0, 0)
	-- Legs streaming back, trailing the swing a little and fluttering.
	local flutter = math.sin(t * 9)
	local trail = offset(hang, cfg.Rope, hang.t - 0.15) * 0.0625
	pose(hang, "RightHip", flutter * 0.15, 0, 0.05 + trail)
	pose(hang, "LeftHip", -flutter * 0.15, 0, -0.05 + trail)
	pose(hang, "RightKnee", -0.15 - math.max(flutter, 0) * 0.2, 0, 0)
	pose(hang, "LeftKnee", -0.15 - math.max(-flutter, 0) * 0.2, 0, 0)

	-- The rope: from the neck to your hand along the wave.
	if not hang.neck then
		return
	end
	local from = hang.neck
	local to = if hang.hand then hang.hand.WorldPosition else hang.pos
	local length = cfg.Rope
	local endSwing = offset(hang, length, hang.t)
	for i, a in hang.points do
		local u = i / cfg.Segments
		-- (your hand's already swung out: the wave on top of the straight line to it)
		a.WorldPosition = from:Lerp(to, u) + hang.side * (offset(hang, u * length, hang.t) - u * endSwing)
	end
	if hang.tier and hang.tier.rope.rainbow then
		for i, b in hang.beams do
			b.Color = LassoTiers.ropeColor(hang.tier, i, cfg.Segments, os.clock())
		end
	end
end

function RopeHang.stop(hang)
	for _, joint in hang.joints do
		joint.Transform = CFrame.identity
	end
	hang.anchor:Destroy()
end

return RopeHang
