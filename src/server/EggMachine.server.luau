-- The Egg Machine in the home base (Config.Gacha): a studded gacha machine with
-- a glass dome full of the exclusive eggs. Walking up to it shows ROLL (the
-- RollPrompt; it draws nothing, the HUD does), and the roll itself is
-- Hatchery's RollGacha. Built here rather than in the map, so tuning it needs
-- no map reload.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)

local STUDS = "rbxassetid://7447638591" -- the classic stud decal the animals use
local STUD_TILE = 0.5

local PINK = Color3.fromRGB(255, 92, 160)
local YELLOW = Color3.fromRGB(255, 204, 64)
local PURPLE = Color3.fromRGB(150, 92, 230)
local DARK = Color3.fromRGB(46, 40, 60)

local gacha = Config.Gacha
local origin = CFrame.new(gacha.Position) * CFrame.Angles(0, math.pi, 0) -- front faces the start line (-z)

local machine = Instance.new("Model")
machine.Name = "EggMachine"

-- A studded block, `size` big, centred at `at` in the machine's frame.
local function block(name, size, at, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = origin * at
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	if shape ~= Enum.PartType.Ball then
		for _, face in Enum.NormalId:GetEnumItems() do
			local texture = Instance.new("Texture")
			texture.Texture = STUDS
			texture.StudsPerTileU = STUD_TILE
			texture.StudsPerTileV = STUD_TILE
			texture.Face = face
			texture.Parent = part
		end
	end
	part.Parent = machine
	return part
end

-- Base, body and a trim band, then the glass dome on top with its cap.
block("Base", Vector3.new(12, 1.5, 12), CFrame.new(0, 0.75, 0), PURPLE)
local body = block("Body", Vector3.new(9, 6, 9), CFrame.new(0, 4.5, 0), PINK)
block("Trim", Vector3.new(9.6, 1, 9.6), CFrame.new(0, 7.5, 0), YELLOW)
local dome = block("Dome", Vector3.new(9, 9, 9), CFrame.new(0, 11, 0), Color3.fromRGB(190, 236, 255), Enum.PartType.Ball)
dome.Material = Enum.Material.Glass
dome.Transparency = 0.55
dome.CanCollide = false
block("Cap", Vector3.new(3, 1.2, 3), CFrame.new(0, 15.6, 0), YELLOW)
block("Knob", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, 15.6 + 1.8, 0), PINK, Enum.PartType.Ball)

-- On the front: the coin slot, the crank and the chute the egg rolls out of.
block("Slot", Vector3.new(1.6, 0.4, 0.3), CFrame.new(-2.2, 6, 4.6), DARK)
block("Crank", Vector3.new(2.6, 2.6, 0.8), CFrame.new(2, 5.4, 4.8), YELLOW, Enum.PartType.Cylinder).CFrame = origin
	* CFrame.new(2, 5.4, 4.8) * CFrame.Angles(0, math.pi / 2, 0)
block("Handle", Vector3.new(0.6, 2.2, 0.6), CFrame.new(2, 6.2, 5.4), PINK)
block("Chute", Vector3.new(3.6, 2.4, 0.4), CFrame.new(0, 2.8, 4.6), DARK)
block("ChuteLip", Vector3.new(4.4, 0.6, 1.4), CFrame.new(0, 1.8, 5), YELLOW)

-- The exclusive eggs piled in the dome, so it's clear what you're rolling for
-- (the Legendary ones until there are exclusives).
local spots = {
	CFrame.new(-1.9, 8.9, 0.9) * CFrame.Angles(0, 0.4, 0.25),
	CFrame.new(1.9, 8.9, 1.1) * CFrame.Angles(0, -0.6, -0.2),
	CFrame.new(0, 8.9, -1.9) * CFrame.Angles(0.2, 2.2, 0),
	CFrame.new(0.2, 11.2, 0.4) * CFrame.Angles(0.15, 0.2, 0.1),
	CFrame.new(-1.6, 10.9, -1.5) * CFrame.Angles(-0.2, 1.2, 0.3),
}
local exclusives = {}
for kind in if next(gacha.Pool.Exclusive or {}) then gacha.Pool.Exclusive else gacha.Pool.Legendary do
	table.insert(exclusives, kind)
end
table.sort(exclusives)
for i, at in spots do
	local kind = exclusives[(i - 1) % math.max(#exclusives, 1) + 1]
	if not kind then
		break
	end
	local egg = Egg.new(kind).model
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	egg:ScaleTo(0.7)
	egg:PivotTo(origin * at)
	egg.Parent = machine
end

-- The price, floating over the dome.
local sign = Instance.new("BillboardGui")
sign.Name = "Price"
sign.Size = UDim2.fromOffset(200, 60)
sign.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
sign.MaxDistance = 150
sign.Adornee = machine:FindFirstChild("Knob")
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Size = UDim2.fromScale(1, 1)
text.Font = Enum.Font.FredokaOne
text.TextScaled = true
text.TextColor3 = Color3.new(1, 1, 1)
local price = gacha.Price
text.Text = if price >= 1000 then "$" .. (string.format("%.1f", price / 1000):gsub("%.0$", "")) .. "k" else "$" .. price
local stroke = Instance.new("UIStroke")
stroke.Thickness = 4
stroke.Parent = text
text.Parent = sign
sign.Parent = machine

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "RollPrompt"
prompt.ActionText = "Roll"
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = gacha.Reach
prompt.Style = Enum.ProximityPromptStyle.Custom
prompt.Parent = body

machine.PrimaryPart = body
machine.Parent = workspace
