-- The tutorial's last step, "Train your lasso for big pets" (QM, Oct 8: a third of new
-- players never sat down): QM's white arrow on the screen, pointing down into your
-- training ring and bobbing over it. Off screen, it sits at the nearest edge, turned
-- to point the way there. Tutorial.update drives it every frame.
--
--   TrainArrow.update(at) -- at: just inside the ring's front (world: Training.client's "TrainingAt"), or nil to hide it

local Players = game:GetService("Players")

local IMAGE = "rbxassetid://89957123476396" -- assets/ui/TrainArrow.png (256 px, pointing down)
local SIZE = require(game:GetService("ReplicatedStorage").Shared.Config).TrainArrowSize -- px
local ABOVE = 4 -- studs over that spot the arrow's tip points at
local BOB = SIZE / 10 -- px up and down
local EDGE = 70 -- px in from the screen's edge when the spot's off screen

local TrainArrow = {}

local gui, arrow
local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "TrainArrow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 4
	arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.Image = IMAGE
	arrow.Size = UDim2.fromOffset(SIZE, SIZE)
	arrow.AnchorPoint = Vector2.new(0.5, 1) -- its tip (it points down), so it bobs over the spot
	arrow.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function TrainArrow.update(at)
	if not at then
		if gui then
			gui.Enabled = false
		end
		return
	end
	if not gui then
		build()
	end
	gui.Enabled = true
	local camera = workspace.CurrentCamera
	local view = camera.ViewportSize
	local point, onScreen = camera:WorldToViewportPoint(at + Vector3.new(0, ABOVE, 0))
	local bob = math.sin(os.clock() * math.pi * 2 * 1.2) * BOB
	if onScreen then
		arrow.AnchorPoint = Vector2.new(0.5, 1)
		arrow.Rotation = 0
		arrow.Position = UDim2.fromOffset(point.X, point.Y - math.abs(bob))
		return
	end
	-- Off screen (or behind you): at the edge, pointing the way to it.
	local centre = view / 2
	local dir = Vector2.new(point.X, point.Y) - centre
	if point.Z < 0 then
		dir = -dir -- (behind the camera the projection flips)
	end
	if dir.Magnitude < 1 then
		dir = Vector2.new(0, 1)
	end
	dir = dir.Unit
	local half = centre - Vector2.new(EDGE, EDGE)
	local k = math.min(half.X / math.max(math.abs(dir.X), 1e-3), half.Y / math.max(math.abs(dir.Y), 1e-3))
	local spot = centre + dir * k - dir * math.abs(bob)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) - 90 -- (the art points down: +90 degrees from +x)
	arrow.Position = UDim2.fromOffset(spot.X, spot.Y)
end

return TrainArrow
