-- The rider's lasso, drawn and animated procedurally (Roblox doesn't share
-- animations between creators, so there's no free lasso animation to use).
-- The right arm is posed through its shoulder joint's Transform (set every frame
-- from PreSimulation, which runs after the Animator), and the rope is a ring of
-- beams plus one beam from the hand to the loop's knot.
--
--   Lasso.start(character, scale, tier) -- tier: LassoTiers' (your pen level's: QM, Oct 8), plain if nil
--   Lasso.swing(dt)                     -- loop spinning over the head
--   Lasso.throw(k, neck)                -- k 0..1: loop flies out and opens over the neck
--   Lasso.pull(k, neck, noRope)         -- k 0..1: loop cinches on the neck, rope taut (noRope: just the loop)
--   Lasso.twirl(dt, object)             -- a caught egg (any part or model) swung round overhead
--   Lasso.gold(on)                      -- the whole rope gold and glowing (training's CRITs), or back
--   Lasso.heldCFrame(object)            -- where a twirled object sits right now
--   Lasso.fitRadius(object)             -- loop radius that fits snugly round a part or model
--   Lasso.hide()
--   Lasso.stop()                        -- removes everything, arm back to normal
--
-- neck = { cframe = neck part CFrame (Y along the neck), radius = cinched loop radius }

local Lasso = {}

-- (from the Client folder by name: Training and the podium run copies of this module)
local LassoTiers = require(game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("LassoTiers"))

local POINTS = 16
local ROPE_COLOR = Color3.fromRGB(222, 184, 120)
local GOLD = Color3.fromHex("FFC41E") -- (the money text's)
local ROPE_WIDTH = 0.28
local SPIN_RATE = 2.4 -- turns per second over the head
local SWING_RADIUS = 2.6
local OPEN_RADIUS = 3.4 -- how wide the loop opens as it drops over the neck
local CINCH_TIME = 0.35 -- share of the pull spent tightening
local TWIRL_RATE = 1.4 -- turns per second with a caught egg
local TWIRL_RADIUS = 4 -- rope length from the hand to the egg
local TWIRL_HEIGHT = 1.6 -- above the hand
local TWIRL_FIT = 2.5 -- loop radius (Lasso.fitRadius) an egg can have before it's swung further out

local folder, anchor, points, knot, hand, handRope, loopBeams
local tier -- LassoTiers' (the rope's look, sparkles, trail and burst)
local sparkles, trail, burst = {}, nil, nil
local burstDone, lastPull = false, math.huge
local shoulder
local spin = 0
local ropeScale = 1
local golden = false

local function beam(a0, a1)
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Width0, b.Width1 = ROPE_WIDTH * ropeScale, ROPE_WIDTH * ropeScale
	b.Color = ColorSequence.new(ROPE_COLOR)
	b.Transparency = NumberSequence.new(0)
	b.FaceCamera = true
	b.Segments = 1
	b.Parent = anchor
	return b
end

local function setVisible(visible)
	for _, b in loopBeams do
		b.Enabled = visible
	end
	handRope.Enabled = visible
	for _, e in sparkles do
		e.Enabled = visible
	end
end

-- The tier's rope: colour (a rainbow turns), glow and width.
local function paintRope()
	if not tier or golden then
		return
	end
	local t = os.clock()
	local width = ROPE_WIDTH * ropeScale * tier.rope.width
	for i, b in loopBeams do
		if tier.rope.rainbow or i == 1 then
			b.Color = LassoTiers.ropeColor(tier, i, POINTS, t)
		else
			b.Color = loopBeams[1].Color
		end
		b.LightEmission, b.LightInfluence = tier.rope.glow, 1 - tier.rope.glow
		b.Width0, b.Width1 = width, width
	end
	handRope.Color = LassoTiers.ropeColor(tier, 0, POINTS, t)
	handRope.LightEmission, handRope.LightInfluence = tier.rope.glow, 1 - tier.rope.glow
	handRope.Width0, handRope.Width1 = width, width
end

-- Sparkles on four points round the loop, the trail and the burst on its knot.
local function dressUp()
	sparkles, trail, burst = {}, nil, nil
	if not tier then
		return
	end
	if tier.sparkle then
		for i = 1, POINTS, POINTS // 4 do
			table.insert(sparkles, LassoTiers.emitter(tier.sparkle, points[i]))
		end
	end
	if tier.trail then
		trail = LassoTiers.emitter(tier.trail, knot)
		trail.Enabled = false
	end
	if tier.burst then
		burst = LassoTiers.emitter(tier.burst, knot)
		burst.Rate = 0
	end
	paintRope()
end

-- Loop of the given radius around center, in the plane with the given normal.
-- The knot sits on the rim at angle `at`, or on the side facing `toward` if given.
local function drawLoop(center, normal, radius, at, toward)
	local up = math.abs(normal.Y) > 0.9 and Vector3.zAxis or Vector3.yAxis
	local basis = CFrame.lookAt(center, center + normal, up)
	if toward and toward.Magnitude > 0.01 then
		local l = basis:VectorToObjectSpace(toward)
		at = math.atan2(l.Y, l.X)
	end
	for i, attachment in points do
		local a = at + (i - 1) / POINTS * math.pi * 2
		attachment.Position = (basis * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)).Position
	end
	knot.Position = points[1].Position
end

-- Right arm: 0 hangs down, pi/2 points forward, pi points straight up.
-- The shoulder is an AnimationConstraint on current avatars, a Motor6D on older
-- ones; both take a Transform.
local function poseArm(raise, roll)
	if shoulder then
		shoulder.Transform = CFrame.Angles(raise, 0, roll or 0)
	end
end

function Lasso.start(character, scale, level)
	Lasso.stop()
	tier = if level then LassoTiers.get(level) else nil
	ropeScale = scale or 1
	spin = 0
	folder = Instance.new("Folder")
	folder.Name = "Lasso"
	anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.identity -- attachment positions are world positions
	anchor.Parent = folder
	points = {}
	for i = 1, POINTS do
		local a = Instance.new("Attachment")
		a.Parent = anchor
		points[i] = a
	end
	knot = Instance.new("Attachment")
	knot.Parent = anchor
	loopBeams = {}
	for i = 1, POINTS do
		loopBeams[i] = beam(points[i], points[i % POINTS + 1])
	end
	hand = character:FindFirstChild("RightGripAttachment", true)
	handRope = beam(hand, knot)
	handRope.Segments = 10
	folder.Parent = workspace

	dressUp()
	local arm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Torso")
	shoulder = arm and (arm:FindFirstChild("RightShoulder") or arm:FindFirstChild("Right Shoulder"))
	setVisible(false)
end

function Lasso.swing(dt, height)
	if not folder then
		return
	end
	spin = (spin + dt * SPIN_RATE * math.pi * 2) % (math.pi * 2)
	poseArm(math.pi * 0.9 + math.sin(spin) * 0.12, math.cos(spin) * 0.15)
	local head = hand.WorldPosition
	local tilt = Vector3.new(math.cos(spin) * 0.12, 1, math.sin(spin) * 0.12).Unit
	drawLoop(head + Vector3.new(0, height or 1.2 * ropeScale, 0), tilt, SWING_RADIUS * ropeScale, spin)
	handRope.CurveSize0, handRope.CurveSize1 = 0, 0
	setVisible(true)
	if trail then
		trail.Enabled = false
	end
	if tier and tier.rope.rainbow then
		paintRope()
	end
end

function Lasso.throw(k, neck)
	if not folder then
		return
	end
	poseArm(math.pi * (0.9 - 0.4 * math.min(k * 2, 1))) -- snaps forward
	local from = hand.WorldPosition + Vector3.new(0, 1.2, 0)
	local to = neck.cframe.Position
	local eased = 1 - (1 - k) * (1 - k)
	local center = from:Lerp(to, eased) + Vector3.new(0, math.sin(k * math.pi) * 4, 0)
	local normal = Vector3.yAxis:Lerp(neck.cframe.UpVector, eased).Unit
	-- Knot on the rim nearest the rider, so the rope trails behind the loop.
	drawLoop(center, normal, SWING_RADIUS + (OPEN_RADIUS - SWING_RADIUS) * eased, 0, hand.WorldPosition - center)
	handRope.CurveSize0 = 2 * (1 - k)
	setVisible(true)
	if trail then
		trail.Enabled = k < 0.98 -- (a trail behind the flying loop)
	end
	if tier and tier.rope.rainbow then
		paintRope()
	end
end

function Lasso.pull(k, neck, noRope)
	if not folder then
		return
	end
	poseArm(math.pi * 0.5)
	local cinch = math.min(k / CINCH_TIME, 1)
	local radius = OPEN_RADIUS + (neck.radius - OPEN_RADIUS) * (1 - (1 - cinch) ^ 3)
	local center = neck.cframe.Position
	drawLoop(center, neck.cframe.UpVector, radius, 0, hand.WorldPosition - center)
	handRope.CurveSize0, handRope.CurveSize1 = 0, 0
	setVisible(true)
	if noRope then
		handRope.Enabled = false
	end
	if trail then
		trail.Enabled = false
	end
	-- The burst where it lands: once a pull, as it cinches.
	if k < lastPull then
		burstDone = false
	end
	lastPull = k
	if burst and not burstDone and k >= CINCH_TIME then
		burstDone = true
		burst:Emit(tier.burst.count)
	end
	if tier and tier.rope.rainbow then
		paintRope()
	end
end

function Lasso.fitRadius(object)
	local size = if object:IsA("Model") then object:GetExtentsSize() else object.Size
	return math.max(size.X, size.Z) / 2 + 0.15
end

-- Flung out on the rope, slightly upward, with its top facing the hand. A big egg
-- (a big animal's, or one from a bigger nest) goes as much further out and higher,
-- so it swings clear of the rider.
function Lasso.heldCFrame(object)
	local extra = if object then math.max(Lasso.fitRadius(object) - TWIRL_FIT, 0) else 0
	local center = hand.WorldPosition + Vector3.new(0, TWIRL_HEIGHT + extra, 0)
	local pos = center + Vector3.new(math.cos(spin), 0.25, math.sin(spin)).Unit * (TWIRL_RADIUS + extra)
	return CFrame.lookAt(pos, center) * CFrame.Angles(-math.pi / 2, 0, 0)
end

function Lasso.twirl(dt, object)
	if not folder then
		return
	end
	spin = (spin + dt * TWIRL_RATE * math.pi * 2) % (math.pi * 2)
	poseArm(math.pi * 0.9 + math.sin(spin) * 0.12, math.cos(spin) * 0.15)
	local cframe = Lasso.heldCFrame(object)
	object:PivotTo(cframe)
	drawLoop(cframe.Position, cframe.UpVector, Lasso.fitRadius(object), 0, hand.WorldPosition - cframe.Position)
	handRope.CurveSize0, handRope.CurveSize1 = 0, 0
	setVisible(true)
	if trail then
		trail.Enabled = false
	end
end

-- A CRIT's rope (Training, QM Oct 8): all gold and glowing, then its tier's again.
function Lasso.gold(on)
	if not folder or on == golden then
		return
	end
	golden = on
	if tier and not on then
		paintRope()
		return
	end
	local color = ColorSequence.new(if on then GOLD else ROPE_COLOR)
	for _, b in loopBeams do
		b.Color = color
		b.LightEmission = if on then 1 else 0
	end
	handRope.Color = color
	handRope.LightEmission = if on then 1 else 0
end

-- The current tier (LassoTiers'), for the HOLD ON! rope (RopeHang) to match.
function Lasso.tier()
	return tier
end

function Lasso.hide()
	if folder then
		setVisible(false)
		if trail then
			trail.Enabled = false
		end
		poseArm(0)
	end
end

function Lasso.stop()
	if shoulder then
		shoulder.Transform = CFrame.identity
	end
	if folder then
		folder:Destroy()
	end
	folder, shoulder, golden = nil, nil, false
end

return Lasso
