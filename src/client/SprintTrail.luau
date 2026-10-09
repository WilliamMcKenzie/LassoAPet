-- A white trail behind your mount while it sprints (QM, Oct 9), as long as it is fast:
-- its Lifetime is Config.SprintTrail.Life at a horse's sprint (a short streak) and
-- grows with the speed (up to MaxLife). It runs through the middle of the animal's
-- body, Width x its height top to bottom, fading out along its length.
--
--   SprintTrail.update(model, on, speed) -- every frame: your mount's model (or nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Outline = require(script.Parent.Outline)

local SprintTrail = {}

local current -- { model, trail, a0, a1 }

local function build(model)
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local cfg = Config.SprintTrail
	local box, size = Outline.box(model) -- (its box, from its root)
	local mid = box.Position
	local half = size.Y * cfg.Width / 2
	local a0 = Instance.new("Attachment")
	a0.Name = "SprintTrailTop"
	a0.Position = mid + Vector3.new(0, half, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "SprintTrailBottom"
	a1.Position = mid - Vector3.new(0, half, 0)
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
	trail.FaceCamera = true
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
