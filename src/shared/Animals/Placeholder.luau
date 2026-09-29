-- Placeholder block horse. Stands in until the polished animal module lands.
-- Interface every animal module follows:
--   Animal.new() -> animal
--   animal.model            Model; PrimaryPart is an anchored root at ground level facing -Z
--   animal:update(dt, speed, turn)   speed in studs/s, turn in -1..1
--   animal:getSeatCFrame()  world CFrame where the rider's hips sit
--   animal:setSaddled(bool)

local Placeholder = {}
Placeholder.__index = Placeholder

local BODY = Color3.fromRGB(196, 128, 78)
local DARK = Color3.fromRGB(84, 54, 38)
local SADDLE = Color3.fromRGB(122, 74, 42)

local function block(model, name, size, cframe, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Parent = model
	return part
end

local function joint(part0, part1, pivot)
	local motor = Instance.new("Motor6D")
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:Inverse() * pivot
	motor.C1 = part1.CFrame:Inverse() * pivot
	motor.Parent = part1
	return motor
end

function Placeholder.new()
	local model = Instance.new("Model")
	model.Name = "Horse"

	local root = block(model, "Root", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), BODY)
	root.Transparency = 1
	root.Anchored = true
	model.PrimaryPart = root

	local body = block(model, "Body", Vector3.new(3, 2.6, 5.4), CFrame.new(0, 4.5, 0), BODY)
	local bodyJoint = joint(root, body, CFrame.new(0, 4.5, 0))

	local legs = {}
	for i, spec in { { -0.95, -1.9, 0 }, { 0.95, -1.9, 0.5 }, { -0.95, 1.9, 0.5 }, { 0.95, 1.9, 0 } } do
		local leg = block(model, "Leg" .. i, Vector3.new(0.95, 3.4, 0.95), CFrame.new(spec[1], 1.9, spec[2]), BODY)
		local hoof = block(model, "Hoof" .. i, Vector3.new(1, 0.5, 1), CFrame.new(spec[1], 0.25, spec[2]), DARK)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = leg, hoof, hoof
		legs[i] = { joint = joint(body, leg, CFrame.new(spec[1], 3.6, spec[2])), phase = spec[3] }
	end

	local neck = block(model, "Neck", Vector3.new(1.3, 2.8, 1.6), CFrame.new(0, 6.3, -2.6) * CFrame.Angles(-0.45, 0, 0), BODY)
	local neckJoint = joint(body, neck, CFrame.new(0, 5.4, -2.3))
	local head = block(model, "Head", Vector3.new(1.4, 1.5, 2.6), CFrame.new(0, 7.5, -3.8) * CFrame.Angles(-0.25, 0, 0), BODY)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = neck, head, head
	block(model, "Tail", Vector3.new(0.6, 2.4, 0.6), CFrame.new(0, 4.6, 3.2) * CFrame.Angles(-0.5, 0, 0), DARK)
	local saddle = block(model, "Saddle", Vector3.new(2.4, 0.5, 2), CFrame.new(0, 6.05, -0.3), SADDLE)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= root and part.Name ~= "Body" and not part:FindFirstChildWhichIsA("Motor6D") and not part:FindFirstChildWhichIsA("WeldConstraint") then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1, w.Parent = body, part, part
		end
	end

	return setmetatable({
		model = model,
		root = root,
		body = body,
		saddle = saddle,
		bodyJoint = bodyJoint,
		neckJoint = neckJoint,
		legs = legs,
		phase = math.random(),
	}, Placeholder)
end

function Placeholder:update(dt, speed, turn)
	local gait = math.clamp(speed / 20, 0, 1)
	self.phase = (self.phase + dt * (0.6 + speed / 22)) % 1
	local t = self.phase * math.pi * 2
	for _, leg in self.legs do
		leg.joint.Transform = CFrame.Angles(math.sin(t + leg.phase * math.pi * 2) * 0.7 * gait, 0, 0)
	end
	self.bodyJoint.Transform = CFrame.new(0, math.abs(math.sin(t)) * 0.35 * gait, 0)
		* CFrame.Angles(math.sin(t) * 0.06 * gait, 0, -turn * 0.12)
	self.neckJoint.Transform = CFrame.Angles(-math.sin(t) * 0.12 * gait, turn * 0.2, 0)
end

function Placeholder:getSeatCFrame()
	return self.body.CFrame * CFrame.new(0, 1.9, -0.3)
end

function Placeholder:setSaddled(saddled)
	self.saddle.Transparency = saddled and 0 or 1
end

return Placeholder
