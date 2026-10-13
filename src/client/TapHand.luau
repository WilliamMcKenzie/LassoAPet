-- The tutorial's tap hand (assets/ui/TapHand.png), pulsing: for pointing at a button
-- or a spot (the quests' hints: QM, Oct 11). TapHand.new(height) makes one, not
-- parented; its Position is its fingertip.
--
-- One at a time (QM, Oct 13: two at once is confusing): of all the hands that would show
-- (visible, on a screen that's on), only one is drawn, the one that came up first; the
-- rest stay see-through till it goes. TapHand.register(image) counts another one in (the
-- Tutorial's own). Whoever shows a hand keeps setting Visible as before.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TapHand = {}
local hands = {} -- [hand] = its UIScale (ours, which pulse)
local all = {} -- every hand, in the order they were made
local current -- the one shown

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
end)

return TapHand
