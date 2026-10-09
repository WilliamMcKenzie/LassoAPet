-- Speed lines as particles (QM, Oct 9): the Creator Store's "Speedlines" (asset
-- 18461351396: an invisible part with a ParticleEmitter on an Attachment), built here
-- with the same settings so it lives in the repo. It sits BASE studs in front of the
-- camera, and the lines fly out from there across the screen's plane, showing only
-- once they're RING studs out. Their speed is set each frame so that ring is
-- Config.SpeedLines.Fit of the way to the screen's nearer edges, whatever the window's
-- shape or the view's width (QM, Oct 9: as the asset was, they flew off the top and
-- bottom of a wide window before showing). Its rate follows the speed of what you're
-- riding.
--
--   SpeedLines.update(speed) -- studs/s of your mount; 0 off a ride (no lines)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SpeedLines = {}

local cfg = Config.SpeedLines
local part, emitter
local SPEED = NumberRange.new(20, 25) -- studs/s (the asset's)
local LIFE = 2
local SHOWS_AT = 0.285878 -- of its life, when a line fades in (its Transparency)
local RING = (SPEED.Min + SPEED.Max) / 2 * LIFE * SHOWS_AT -- studs out from the middle where the asset's lines show
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
	emitter.Size = NumberSequence.new(1)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.285878, 1),
		NumberSequenceKeypoint.new(0.386912, 0),
		NumberSequenceKeypoint.new(0.894374, 0),
		NumberSequenceKeypoint.new(0.946039, 0.1),
		NumberSequenceKeypoint.new(0.98163, 0.3125),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(0, 360)
	emitter.LightEmission = 0
	emitter.LightInfluence = 1
	emitter.LockedToPart = true
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Squash = NumberSequence.new(3)
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
	-- Half the screen's nearer extent, per stud ahead: its height, or its width when it's narrower.
	local half = math.tan(math.rad(camera.FieldOfView) / 2) * math.min(aspect, 1)
	part.CFrame = camera.CFrame + camera.CFrame.LookVector * BASE -- (QM's: the camera's own turn)
	-- Lines fast or slow enough to show Fit of the way out to that edge.
	local s = cfg.Fit * half * BASE / RING
	emitter.Speed = NumberRange.new(SPEED.Min * s, SPEED.Max * s)
	if part.Parent ~= camera then
		part.Parent = camera
	end
	emitter.Rate = cfg.Rate * math.clamp(speed / cfg.Speed, 0, cfg.MaxScale)
end

return SpeedLines
