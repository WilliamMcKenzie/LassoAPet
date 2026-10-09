-- Speed lines as particles (QM, Oct 9): the Creator Store's "Speedlines" (asset
-- 18461351396: an invisible part with a ParticleEmitter on an Attachment), built here
-- with the same settings so it lives in the repo. It sits a little in front of the
-- camera every frame (QM's script: Offset studs, 13 on a narrower screen, less with a
-- wider view), and its rate follows the speed of what you're riding. Config.SpeedLines.
--
--   SpeedLines.update(speed) -- studs/s of your mount; 0 off a ride (no lines)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SpeedLines = {}

local cfg = Config.SpeedLines
local part, emitter

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
	emitter.Lifetime = NumberRange.new(2)
	emitter.Speed = NumberRange.new(20, 25)
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
	-- (in the workspace, not the camera: when Roblox swaps the camera after a respawn the
	-- old one goes, and the lines went with it for good, Oct 9)
	part.Parent = workspace
end

function SpeedLines.update(speed)
	if not cfg.On then
		if emitter then
			emitter.Rate = 0
		end
		return
	end
	if not part or not part:IsDescendantOf(workspace) then -- (rebuilt if anything took it away)
		build()
	end
	local camera = workspace.CurrentCamera
	local view = camera.ViewportSize
	local offset = if view.X / math.max(view.Y, 1) > 1.5 then cfg.Offset else cfg.NarrowOffset
	-- (QM's: the camera's own turn, moved forward along its look)
	part.CFrame = camera.CFrame + camera.CFrame.LookVector * (offset / (camera.FieldOfView / 70))
	emitter.Rate = cfg.Rate * math.clamp(speed / cfg.Speed, 0, cfg.MaxScale)
end

return SpeedLines
