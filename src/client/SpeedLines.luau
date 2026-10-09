-- Speed lines as particles (QM, Oct 9): the Creator Store's "Speedlines" (asset
-- 18461351396: an invisible part with a ParticleEmitter on an Attachment), built here
-- like it so it lives in the repo, then tuned to QM's reference (Oct 9): a handful of
-- thin, short, slightly see-through streaks round the screen's edges, the middle clear.
-- It sits BASE studs in front of the camera, and the lines fly out from there across
-- the screen's plane, but only show between SHOW_FROM and SHOW_TO of their life. Their
-- speed is set each frame so they start showing Config.SpeedLines.Fit of the way to the
-- screen's wider edges (the sides on a wide window), whatever its shape or the view's
-- width, and run off it from there. Its rate follows the speed of what you're riding.
--
--   SpeedLines.update(speed) -- studs/s of your mount; 0 off a ride (no lines)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SpeedLines = {}

local cfg = Config.SpeedLines
local part, emitter
local SPEED = NumberRange.new(20, 25) -- studs/s (the asset's)
local LIFE = 2
local SHOW_FROM, SHOW_TO = 0.6, 0.9 -- of its life: a line's only seen between these (1.5x as far out at the end)
local RING = (SPEED.Min + SPEED.Max) / 2 * LIFE * SHOW_FROM -- studs out from the middle where lines start showing, at SPEED
local BASE = 10 -- studs ahead of the camera (QM's script)

local function build()
	part = Instance.new("Part")
	part.Name = "Speedlines"
	part.Size = Vector3.new(4, 1, 2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://304846479"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(LIFE)
	emitter.Speed = SPEED
	emitter.Size = NumberSequence.new(cfg.Size)
	local see = cfg.Transparency
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(SHOW_FROM, 1),
		NumberSequenceKeypoint.new(SHOW_FROM + 0.05, see),
		NumberSequenceKeypoint.new(SHOW_TO - 0.05, see),
		NumberSequenceKeypoint.new(SHOW_TO, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(0, 360)
	emitter.LightEmission = 0
	emitter.LightInfluence = 1
	emitter.LockedToPart = true
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Squash = NumberSequence.new(cfg.Squash)
	emitter.ZOffset = 5
	emitter.Rotation = NumberRange.new(90)
	emitter.RotSpeed = NumberRange.new(-0.5, 0.5)
	emitter.Parent = attachment
	part.Parent = workspace.CurrentCamera
end

function SpeedLines.update(speed)
	if not cfg.On then
		if emitter then
			emitter.Rate = 0
		end
		return
	end
	if not part then
		build()
	end
	local camera = workspace.CurrentCamera
	local view = camera.ViewportSize
	local aspect = view.X / math.max(view.Y, 1)
	-- Half the screen's wider extent, per stud ahead: its width, or its height when it's taller.
	local half = math.tan(math.rad(camera.FieldOfView) / 2) * math.max(aspect, 1)
	part.CFrame = camera.CFrame + camera.CFrame.LookVector * BASE -- (QM's: the camera's own turn)
	-- Lines fast or slow enough to start showing Fit of the way out to that edge.
	local s = cfg.Fit * half * BASE / RING
	emitter.Speed = NumberRange.new(SPEED.Min * s, SPEED.Max * s)
	if part.Parent ~= camera then
		part.Parent = camera
	end
	emitter.Rate = cfg.Rate * math.clamp(speed / cfg.Speed, 0, cfg.MaxScale)
end

return SpeedLines
