-- Style preview for the horse. Press Play and fly the camera to PREVIEW_AT:
-- one saddled horse idling, one trotting in place, and a herd galloping laps.
-- Local-only parts, so nothing here replicates. Set ENABLED to false once the
-- horse style is settled.

local ENABLED = true
local PREVIEW_AT = Vector3.new(-200, 0, 0)
local HERD = 6
local LAP_RADIUS = 40
local GALLOP = 44

if not ENABLED then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Horse = require(ReplicatedStorage.Shared.Animals.Horse)

local folder = Instance.new("Folder")
folder.Name = "HorsePreview"
folder.Parent = workspace

local pad = Instance.new("Part")
pad.Name = "Pad"
pad.Anchored = true
pad.Size = Vector3.new(24, 1, 24)
pad.CFrame = CFrame.new(PREVIEW_AT - Vector3.new(0, 0.5, 0))
pad.Color = Color3.fromRGB(163, 162, 165)
pad.TopSurface = Enum.SurfaceType.Studs
pad.Parent = folder

local function spawn(cframe, saddled)
	local horse = Horse.new()
	horse:setSaddled(saddled)
	horse.model:PivotTo(cframe)
	horse.model.Parent = folder
	return horse
end

local idle = spawn(CFrame.new(PREVIEW_AT + Vector3.new(-5, 0, 0)) * CFrame.Angles(0, math.rad(-30), 0), true)
local trot = spawn(CFrame.new(PREVIEW_AT + Vector3.new(5, 0, 0)) * CFrame.Angles(0, math.rad(-30), 0), false)

local herd = {}
for i = 1, HERD do
	herd[i] = {
		horse = spawn(CFrame.new(PREVIEW_AT), false),
		angle = i / HERD * 2 * math.pi,
		radius = LAP_RADIUS + (i % 3) * 5,
		speed = GALLOP - (i % 2) * 6,
	}
end

RunService.RenderStepped:Connect(function(dt)
	idle:update(dt, 0, 0)
	trot:update(dt, 16, 0)

	for _, runner in ipairs(herd) do
		local root = runner.horse.model.PrimaryPart
		local before = root.CFrame

		runner.angle += runner.speed / runner.radius * dt
		local a = runner.angle
		local pos = PREVIEW_AT + Vector3.new(math.cos(a), 0, math.sin(a)) * runner.radius
		local heading = Vector3.new(-math.sin(a), 0, math.cos(a))
		root.CFrame = CFrame.lookAt(pos, pos + heading)

		-- how fast we are turning right (+) or left (-)
		local yawRate = (root.CFrame.LookVector - before.LookVector):Dot(before.RightVector) / math.max(dt, 1e-3)
		runner.horse:update(dt, runner.speed, math.clamp(yawRate / 1.5, -1, 1))
	end
end)
