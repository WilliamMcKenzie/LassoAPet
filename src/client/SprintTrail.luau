-- A white trail off the rider while their mount sprints (QM, Oct 9: off the player,
-- not the animal), as long as it is fast: its Lifetime is Config.SprintTrail.Life at a
-- horse's sprint (a short streak) and grows with the speed (up to MaxLife). A flat
-- ribbon as wide as the rider's body (their root part, side to side, x Width), from
-- the middle of them, fading out along its length.
--
--   SprintTrail.update(character, on, speed) -- every frame: the rider (or nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SprintTrail = {}

local current -- { model, trail, a0, a1 }

local function build(model)
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local cfg = Config.SprintTrail
	local half = root.Size.X * cfg.Width / 2
	local a0 = Instance.new("Attachment")
	a0.Name = "SprintTrailLeft"
	a0.Position = Vector3.new(-half, 0, 0) -- (the rider's middle, their left side)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "SprintTrailRight"
	a1.Position = Vector3.new(half, 0, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "SprintTrail"
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, cfg.Transparency),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 0.5
	trail.LightInfluence = 0
	trail.FaceCamera = false -- (flat, side to side: the rider's width)
	trail.MinLength = 0.1
	trail.Enabled = false
	trail.Parent = root
	return { model = model, trail = trail, a0 = a0, a1 = a1 }
end

function SprintTrail.update(model, on, speed)
	local cfg = Config.SprintTrail
	if current and current.model ~= model then
		current.trail:Destroy()
		current.a0:Destroy()
		current.a1:Destroy()
		current = nil
	end
	if not model or not cfg.On then
		return
	end
	current = current or build(model)
	if not current then
		return
	end
	current.trail.Enabled = on
	if on then
		current.trail.Lifetime = math.clamp(cfg.Life * (speed or 0) / cfg.HorseSprint, cfg.Life * 0.5, cfg.MaxLife)
	end
end

return SprintTrail
