-- The tutorial's tap hand (assets/ui/TapHand.png), pulsing: for pointing at a button
-- or a spot (the quests' hints: QM, Oct 11). TapHand.new(height) makes one, not
-- parented; its Position is its fingertip.
--
-- One at a time (QM, Oct 13: two at once is confusing): of all the hands that would show
-- (visible, on a screen that's on), only one is drawn, the one that came up first; the
-- rest stay see-through till it goes. TapHand.register(image) counts another one in (the
-- Tutorial's own). Whoever shows a hand keeps setting Visible as before.
--
-- The spotlight (QM, Oct 13: only for buying World 2 from the bar, and opening and claiming
-- the starter quest): a hand with the "Spotlight" attribute, while it's the one shown,
-- darkens the whole screen but for a box round what it points at (its parent), and is
-- drawn again over the dark. The dark doesn't take clicks.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TapHand = {}
local hands = {} -- [hand] = its UIScale (ours, which pulse)
local all = {} -- every hand, in the order they were made
local current -- the one shown
local DIM = 0.45 -- the dark's transparency
local PAD = 10 -- px of room round the target

local function track(image)
	table.insert(all, image)
	image.Destroying:Connect(function()
		local i = table.find(all, image)
		if i then
			table.remove(all, i)
		end
	end)
end

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
	hand.Destroying:Connect(function()
		hands[hand] = nil
	end)
	track(hand)
	return hand
end

function TapHand.register(image)
	track(image)
end

local player = Players.LocalPlayer
-- Would it show: visible, and everything it's in too?
local function showing(image)
	if not image.Visible or not image:IsDescendantOf(player.PlayerGui) then
		return false
	end
	local at = image.Parent
	while at and at ~= player.PlayerGui do
		if (at:IsA("GuiObject") and not at.Visible) or (at:IsA("LayerCollector") and not at.Enabled) then
			return false
		end
		at = at.Parent
	end
	return true
end

-- The spotlight's own ScreenGui, over the rest of the HUD.
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
local copy = Instance.new("ImageLabel") -- (the hand, over the dark)
copy.BackgroundTransparency = 1
copy.ZIndex = 2
copy.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function spotlight(image)
	local target = image and image:GetAttribute("Spotlight") and image.Parent
	gui.Enabled = target ~= nil and target:IsA("GuiObject")
	if not gui.Enabled then
		return
	end
	-- (AbsolutePosition's the same frame for every ScreenGui; a Position here is from this
	-- one's corner, which is above the screen's when it's under the top bar)
	local view, corner = gui.AbsoluteSize, gui.AbsolutePosition
	local low = target.AbsolutePosition - Vector2.new(PAD, PAD) - corner
	local high = target.AbsolutePosition + target.AbsoluteSize + Vector2.new(PAD, PAD) - corner
	sides[1].Position, sides[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(view.X, math.max(low.Y, 0))
	sides[2].Position, sides[2].Size = UDim2.fromOffset(0, high.Y), UDim2.fromOffset(view.X, math.max(view.Y - high.Y, 0))
	sides[3].Position, sides[3].Size = UDim2.fromOffset(0, low.Y), UDim2.fromOffset(math.max(low.X, 0), high.Y - low.Y)
	sides[4].Position, sides[4].Size = UDim2.fromOffset(high.X, low.Y), UDim2.fromOffset(math.max(view.X - high.X, 0), high.Y - low.Y)
	local at = image.AbsolutePosition - corner
	copy.Image = image.Image
	copy.Position = UDim2.fromOffset(at.X, at.Y)
	copy.Size = UDim2.fromOffset(image.AbsoluteSize.X, image.AbsoluteSize.Y)
	copy.Rotation = image.Rotation
end

RunService.RenderStepped:Connect(function()
	local s = 1 + 0.12 * math.sin(os.clock() * 6)
	for hand, scale in hands do
		if hand.Visible then
			scale.Scale = s
		end
	end
	if not (current and current.Parent and showing(current)) then
		current = nil
		for _, image in all do
			if showing(image) then
				current = image
				break
			end
		end
	end
	for _, image in all do
		image.ImageTransparency = if image == current then 0 else 1
	end
	spotlight(current)
end)

return TapHand
