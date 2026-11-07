-- The 100x Luck Event's sign (Config.LuckEvent, QM Nov 7): a long beam across the course's
-- mouth, wall to wall, and a board in its middle. Builds workspace.LuckEventSign; its "Board"
-- part is what Client/LuckEvent draws the title and countdown on. The event itself is only
-- the clock (Config.luckEventLeft): Config.luck multiplies everyone's luck while it's on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapData = require(ReplicatedStorage.Shared.MapData)
local MapFile = require(ReplicatedStorage.Shared.MapFile)
local Studs = require(ReplicatedStorage.Shared.Studs)

local S = Config.LuckEvent.Sign
local ground = MapFile.groundAt(MapData, 0, S.Z + 12) -- (the base's floor, just in front of it)
local mid = CFrame.new(0, ground + S.Height, S.Z)
local span = 2 * Config.CourseHalfWidth + 8 -- (its ends into the walls)

local model = Instance.new("Model")
model.Name = "LuckEventSign"

local function block(name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false -- (rides and the Slingshot pass through)
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Size = size
	p.CFrame = cf
	Studs.apply(p, 0.5)
	p.Locked = true
	p.Parent = model
	return p
end

-- the beam: a trimmed plank, as the reference's
block("BeamTrim", Vector3.new(span, 4.4, 1.6), mid * CFrame.new(0, 1, 0), S.Trim)
block("Beam", Vector3.new(span - 2, 3.2, 2), mid * CFrame.new(0, 1, 0), S.Color)
-- the board: a darker frame, the face inset
block("Frame", Vector3.new(S.Width + 2, S.BoardHeight + 2, 2.4), mid, S.Trim)
local board = block("Board", Vector3.new(S.Width, S.BoardHeight, 3), mid, S.Color)
model.PrimaryPart = board
model.Parent = workspace
