-- A lucky CRIT at a training dummy (Config.Training.Crit; QM, Oct 8: more spectacle):
-- the dummy's yanked off its pole, swung once round its thrower's head and slammed
-- back down with a gold shockwave and sparks. Training.client plays it on your own
-- dummy as you catch it, and on everyone else's as their CRITs come in ("TrainingCrits").
-- Only the dummy's body moves (its "root" bone and all on it): the pole stays put.
--
--   TrainingCrit.start(dummy, character, onSlam) -- begins; onSlam() as it lands
--   TrainingCrit.update(dummy, dt) -- each frame after its animation: moves it, returns where
--     its neck is ({ cframe, radius }, for the rope) and the body, or nil once it's down
--   TrainingCrit.cancel(dummy) -- straight back on its pole (its thrower stopped)
--   TrainingCrit.slam(dummy, mine) -- the landing: shockwave and sparks; mine: a camera shake

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local LassoTiers = require(script.Parent.LassoTiers)
local Sounds = require(script.Parent.Sounds)

local GOLD = Color3.fromHex("FFC41E") -- (the money text's)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local LIFT_END, ORBIT_END = 0.18, 0.78 -- shares of Crit.Time: up off the pole to you, once round your head, then the slam
local SHAKE, SHAKE_TIME = 0.9, 0.35 -- studs the camera jolts, easing off over this long

local TrainingCrit = {}

local function ease(k)
	return if k < 0.5 then 2 * k * k else 1 - (-2 * k + 2) ^ 2 / 2
end

function TrainingCrit.start(dummy, character, onSlam)
	local motor = dummy.bones.root
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not motor or not hrp or not dummy.place then
		onSlam()
		return
	end
	-- Where the body sits on its pole (its root bone), and its neck from there.
	local rest = motor.Part0.CFrame * motor.C0 * motor.C1:Inverse()
	local height = rest.Position.Y - dummy.place.Position.Y
	dummy.crit = {
		t = 0,
		rest = rest,
		neck = rest:ToObjectSpace(dummy.place * CFrame.new(dummy.entry.neck.center)),
		hrp = hrp,
		-- Round your head at this many studs, this high: clear of you, bigger for the big ones.
		reach = math.max(8, dummy.radius - 6),
		lift = height * 0.35 + 2,
		onSlam = onSlam,
	}
end

function TrainingCrit.update(dummy, dt)
	local crit = dummy.crit
	local motor = dummy.bones.root
	if not crit or not motor or not dummy.place or not crit.hrp.Parent then
		TrainingCrit.cancel(dummy)
		return nil
	end
	crit.t += dt
	local k = math.min(crit.t / Config.Training.Crit.Time, 1)
	local rest = crit.rest.Position
	local c = crit.hrp.Position
	local start = math.atan2(rest.X - c.X, rest.Z - c.Z)
	local y = rest.Y + crit.lift
	local function round(a)
		return Vector3.new(c.X + math.sin(a) * crit.reach, y, c.Z + math.cos(a) * crit.reach)
	end
	local at
	if k < LIFT_END then -- up off the pole and over to you
		local e = ease(k / LIFT_END)
		at = rest:Lerp(round(start), e) + Vector3.new(0, math.sin(e * math.pi) * 3, 0)
	elseif k < ORBIT_END then -- once round your head
		local e = (k - LIFT_END) / (ORBIT_END - LIFT_END)
		at = round(start + e * math.pi * 2) + Vector3.new(0, math.sin(e * math.pi * 2) * 1.2, 0)
	else -- slammed back down on its pole
		local e = (k - ORBIT_END) / (1 - ORBIT_END)
		at = round(start):Lerp(rest, e * e) + Vector3.new(0, math.sin(e * math.pi) * 4, 0)
	end
	-- Spinning twice and rocking as it goes, upright again as it lands.
	local body = CFrame.new(at) * CFrame.Angles(0, k * math.pi * 4, 0) * CFrame.Angles(math.sin(k * math.pi) * 0.6, 0, 0) * crit.rest.Rotation
	motor.Transform = (motor.Part0.CFrame * motor.C0):Inverse() * body * motor.C1
	if k >= 1 then
		dummy.crit = nil
		crit.onSlam()
		return nil
	end
	return { cframe = body * crit.neck, radius = dummy.entry.neck.radius }, at
end

function TrainingCrit.cancel(dummy)
	dummy.crit = nil
	local motor = dummy.bones.root
	if motor then
		motor.Transform = CFrame.identity
	end
end

-- A ring flat on the floor round the pole, flying out and fading.
local function wave(dummy, color, delay)
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "CritWave"
	ring.Color3 = color
	ring.Height = 0.1
	ring.Radius = 1.5
	ring.InnerRadius = 0.5
	ring.Transparency = 0.1
	ring.CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(math.pi / 2, 0, 0) -- (lying flat, like Outline's)
	ring.Adornee = dummy.model.PrimaryPart
	ring.Parent = workspace
	local size = dummy.radius * 1.4
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay)
	TweenService:Create(ring, info, { Radius = size, InnerRadius = size - 2, Transparency = 1 }):Play()
	task.delay(0.7 + delay, ring.Destroy, ring)
end

local shakeUntil, shaking = 0, false

function TrainingCrit.slam(dummy, mine)
	dummy.hitT = 0
	local root = dummy.model.PrimaryPart
	if not root then
		return
	end
	wave(dummy, GOLD, 0)
	wave(dummy, Color3.new(1, 1, 1), 0.08)
	local scale = dummy.radius / Config.Training.Radius
	local at = Instance.new("Attachment")
	at.Position = Vector3.new(0, 1, 0)
	at.Parent = root
	local sparks = LassoTiers.emitter({ texture = SPARKLE, color = GOLD, size = 1.4 * scale, lifetime = 0.7, speed = 28 * scale, light = 1, spin = true, rise = -30 }, at)
	sparks:Emit(26)
	task.delay(1, at.Destroy, at)
	if not mine then
		return
	end
	Sounds.play("smash", 0.9)
	Sounds.play("reveal_pop", 0.7, 1.1)
	-- The camera jolts, after it's placed each frame (Ride's camera is Camera + 1).
	shakeUntil = os.clock() + SHAKE_TIME
	if not shaking then
		shaking = true
		RunService:BindToRenderStep("TrainingCritShake", Enum.RenderPriority.Camera.Value + 2, function()
			local left = shakeUntil - os.clock()
			if left <= 0 then
				shaking = false
				RunService:UnbindFromRenderStep("TrainingCritShake")
				return
			end
			local k = SHAKE * left / SHAKE_TIME
			local camera = workspace.CurrentCamera
			camera.CFrame *= CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
		end)
	end
end

return TrainingCrit
