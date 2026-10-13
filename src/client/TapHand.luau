-- The tutorial's tap hand (assets/ui/TapHand.png), pulsing: for pointing at a button
-- or a spot (the quests' hints: QM, Oct 11). TapHand.new(height) makes one, not
-- parented; its Position is its fingertip.
--
-- The spotlight (QM, Oct 13): while any hand's showing, the whole screen darkens but for a
-- box round what it points at (its parent, a button; or, for a hand on something in the
-- world, the spot round its fingertip; round all of them if there's more than one), and
-- the hands are drawn again over the dark. The dark doesn't take clicks, so the target
-- (and anything else) still works. TapHand.register(image, rect) adds another hand (the
-- Tutorial's own): rect() returns its target's AbsolutePosition and AbsoluteSize, or nil
-- for the spot round its fingertip.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TapHand = {}
local hands = {} -- [hand] = its UIScale
local registered = {} -- [image] = its rect function (or false: its parent, or round its fingertip)

local DIM = 0.45 -- the dark's transparency
local PAD = 10 -- px of room round the target
local SPOT = 1.6 -- a spot in the world: a box this many hand heights across

function TapHand.new(height)
	local hand = Instance.new("ImageLabel")
	hand.Name = "TapHand"
	hand.BackgroundTransparency = 1
	hand.Image = "rbxassetid://134865745295413"
	hand.AnchorPoint = Vector2.new(0.365, 0.03) -- (its fingertip)
	hand.Size = UDim2.fromOffset(math.round(height * 488 / 610), height)
	hand.ZIndex = 20
	local scale = Instance.new("UIScale")
	scale.Parent = hand
	hands[hand] = scale
	registered[hand] = false
	hand.Destroying:Connect(function()
		hands[hand] = nil
		registered[hand] = nil
	end)
	return hand
end

function TapHand.register(image, rect)
	registered[image] = rect or false
	image.Destroying:Connect(function()
		registered[image] = nil
	end)
end

-- The spotlight's own ScreenGui, over the rest of the HUD (the Tutorial's is over it).
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TapSpotlight"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Enabled = false
local sides = {}
for i = 1, 4 do
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = DIM
	f.BorderSizePixel = 0
	f.Active = false
	f.Parent = gui
	sides[i] = f
end
local copies = {} -- [hand] = its copy over the dark
gui.Parent = player:WaitForChild("PlayerGui")

-- Is it on screen: visible, and everything it's in too?
local function showing(image)
	if not image.Visible or not image:IsDescendantOf(player.PlayerGui) then
		return false
	end
	local at = image.Parent
	while at and at ~= player.PlayerGui do
		if at:IsA("GuiObject") and not at.Visible then
			return false
		elseif at:IsA("ScreenGui") and not at.Enabled then
			return false
		end
		at = at.Parent
	end
	return image.AbsoluteSize.X > 0
end

local function targetOf(image, rect)
	if rect then
		local at, size = rect()
		if at then
			return at, size -- (screen coordinates already)
		end
	end
	local view = workspace.CurrentCamera.ViewportSize
	local parent = image.Parent
	if parent and parent:IsA("GuiObject") then
		local size = parent.AbsoluteSize
		if size.X * size.Y < view.X * view.Y * 0.25 then -- (a button: not a whole screen)
			return parent.AbsolutePosition, size
		end
	end
	local tip = image.AbsolutePosition + image.AbsoluteSize * image.AnchorPoint
	local spot = image.AbsoluteSize.Y * SPOT
	return tip - Vector2.new(spot, spot) / 2, Vector2.new(spot, spot)
end

RunService.RenderStepped:Connect(function()
	local s = 1 + 0.12 * math.sin(os.clock() * 6)
	for hand, scale in hands do
		if hand.Visible then
			scale.Scale = s
		end
	end
	-- The spotlight.
	local low, high
	local live = {}
	for image, rect in registered do
		if showing(image) then
			local at, size = targetOf(image, rect or nil)
			if at then
				live[image] = true
				low = if low then low:Min(at) else at
				high = if high then high:Max(at + size) else at + size
			end
		end
	end
	gui.Enabled = low ~= nil
	for image, copy in copies do
		if not live[image] then
			copy:Destroy()
			copies[image] = nil
		end
	end
	if not low then
		return
	end
	-- (AbsolutePosition's the same frame for every ScreenGui; a Position here is from this
	-- one's corner, which is above the screen's when it's under the top bar)
	local view = gui.AbsoluteSize
	low -= Vector2.new(PAD, PAD) + gui.AbsolutePosition
	high += Vector2.new(PAD, PAD) - gui.AbsolutePosition
	-- (above, below, left, right of the box)
	sides[1].Position, sides[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(view.X, math.max(low.Y, 0))
	sides[2].Position, sides[2].Size = UDim2.fromOffset(0, high.Y), UDim2.fromOffset(view.X, math.max(view.Y - high.Y, 0))
	sides[3].Position, sides[3].Size = UDim2.fromOffset(0, low.Y), UDim2.fromOffset(math.max(low.X, 0), high.Y - low.Y)
	sides[4].Position, sides[4].Size = UDim2.fromOffset(high.X, low.Y), UDim2.fromOffset(math.max(view.X - high.X, 0), high.Y - low.Y)
	-- The hands again, over the dark (the Tutorial's draws over it already).
	for image in live do
		if image:FindFirstAncestorWhichIsA("ScreenGui").DisplayOrder < gui.DisplayOrder then
			local copy = copies[image]
			if not copy then
				copy = Instance.new("ImageLabel")
				copy.BackgroundTransparency = 1
				copy.Image = image.Image
				copy.ZIndex = 2
				copy.Parent = gui
				copies[image] = copy
			end
			local at = image.AbsolutePosition - gui.AbsolutePosition
			copy.Position = UDim2.fromOffset(at.X, at.Y)
			copy.Size = UDim2.fromOffset(image.AbsoluteSize.X, image.AbsoluteSize.Y)
			copy.Rotation = image.Rotation
		end
	end
end)

return TapHand
