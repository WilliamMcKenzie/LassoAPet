-- A puff of little white blocks bursting out along the ground: the "poof" an
-- animal pops in with.
--
--   Poof.at(position)  -- position on the ground

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local COUNT = 8
local LIFE = 0.4 -- seconds
local COLOR = Color3.fromRGB(255, 255, 255)

local Poof = {}

function Poof.at(position)
	local rng = Random.new()
	for i = 1, COUNT do
		local angle = (i + rng:NextNumber(-0.3, 0.3)) / COUNT * math.pi * 2
		local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local size = rng:NextNumber(0.9, 1.4)
		local part = Instance.new("Part")
		part.Name = "Poof"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = COLOR
		part.Size = Vector3.one * size
		part.CFrame = CFrame.new(position + out * 1.2 + Vector3.new(0, size / 2, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		part.Parent = workspace
		local goal = part.CFrame * CFrame.Angles(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
		TweenService:Create(part, TweenInfo.new(LIFE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = goal + out * rng:NextNumber(3, 4.5) + Vector3.new(0, rng:NextNumber(0.8, 2), 0),
			Size = Vector3.one * 0.05,
			Transparency = 0.4,
		}):Play()
		Debris:AddItem(part, LIFE + 0.05)
	end
end

return Poof
