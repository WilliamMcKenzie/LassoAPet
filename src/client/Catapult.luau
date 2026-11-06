-- The catapult's launch (design/catapult, tools/catapult_meshes.py): the arm snaps
-- forward to the stop bar, bounces, the rock flies off in an arc, the arm winds back
-- down and a new rock appears in the bucket. Same timings as the preview GIF.
--
--   Catapult.launch(model)  -- model: a Catapult Model (see below); returns when done
--
-- The Model's pivot is the middle of its base (it throws toward its -Z). Inside it:
--   Arm   a Model of the CatapultArm pieces, its pivot at the axle (as the .obj's origin)
--   Rock  the CatapultRock MeshPart (anchored), sitting in the bucket
-- The arm is posed from the model's pivot each frame, so the catapult can sit anywhere.

local RunService = game:GetService("RunService")

local ARM_PIVOT = Vector3.new(0, 4.2, 1.6) -- the axle, in the catapult's space
local ARM_COCKED = 14 -- degrees the arm is raised off the +Z horizontal, resting
local ARM_FIRED = 104 -- degrees at the stop bar
local ROCK_AT = Vector3.new(0, 1.55 + 1.15 * 0.8, 9.4) -- in the arm's space
local RELEASE = 0.26 -- s: the rock leaves just before the arm hits the stop bar
local ROCK_SPEED = 55 -- studs/s
local ROCK_GRAVITY = 35 -- studs/s^2
local ROCK_LIFE = 2 -- s the thrown rock flies before it's gone

local Catapult = {}

local function armAngle(t)
	if t < 0.28 then
		local u = t / 0.28
		return ARM_COCKED + (ARM_FIRED - ARM_COCKED) * u * u * u
	end
	t -= 0.28
	if t < 0.3 then
		return ARM_FIRED - 9 * math.sin(math.pi * t / 0.3) * math.exp(-t * 6)
	end
	t -= 0.3
	if t < 0.35 then
		return ARM_FIRED
	end
	t -= 0.35
	if t < 1.1 then
		local u = t / 1.1
		u = u * u * (3 - 2 * u)
		return ARM_FIRED + (ARM_COCKED - ARM_FIRED) * u
	end
	return ARM_COCKED
end
local DURATION = 0.28 + 0.3 + 0.35 + 1.1

local function armCFrame(base, deg)
	-- +Z lifts toward +Y: a negative turn about X
	return base * CFrame.new(ARM_PIVOT) * CFrame.Angles(-math.rad(deg), 0, 0)
end

function Catapult.pose(model, deg)
	local arm = model:FindFirstChild("Arm")
	local cf = armCFrame(model:GetPivot(), deg or ARM_COCKED)
	if arm then
		arm:PivotTo(cf)
	end
	return cf
end

function Catapult.launch(model)
	local base = model:GetPivot()
	local arm = model:FindFirstChild("Arm")
	local rock = model:FindFirstChild("Rock")
	local released, thrown, start, velocity, from
	local t0 = os.clock()
	while true do
		local t = os.clock() - t0
		local cf = armCFrame(base, armAngle(math.min(t, DURATION)))
		if arm then
			arm:PivotTo(cf)
		end
		if rock and not released then
			if t < RELEASE then
				rock.CFrame = cf * CFrame.new(ROCK_AT)
			else
				-- let go along the bucket's path, a copy flies off and the bucket refills
				local a = (armCFrame(base, armAngle(RELEASE)) * CFrame.new(ROCK_AT)).Position
				local b = (armCFrame(base, armAngle(RELEASE + 1 / 120)) * CFrame.new(ROCK_AT)).Position
				released = true
				velocity = (b - a).Unit * ROCK_SPEED
				from = a
				start = t
				thrown = rock:Clone()
				thrown.Name = "ThrownRock"
				thrown.Parent = workspace
				rock.Transparency = 1
			end
		end
		if thrown then
			local s = t - start
			if s > ROCK_LIFE then
				thrown:Destroy()
				thrown = nil
			else
				thrown.CFrame = CFrame.new(from + velocity * s + Vector3.new(0, -0.5 * ROCK_GRAVITY * s * s, 0))
					* CFrame.Angles(s * 6, 0, s * 2)
			end
		end
		if t >= DURATION and thrown == nil then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if rock then
		rock.CFrame = armCFrame(base, ARM_COCKED) * CFrame.new(ROCK_AT)
		rock.Transparency = 0
	end
end

return Catapult
