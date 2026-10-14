-- The tutorial's tap hand (assets/ui/TapHand.png), pulsing: for pointing at a button
-- or a spot (the quests' hints: QM, Oct 11). TapHand.new(height) makes one, not
-- parented; its Position is its fingertip.
--
-- One at a time (QM, Oct 13: two at once is confusing): every hand that would show (visible,
-- on a screen that's on) asks Client/Focus, with the priority in its "Focus" attribute
-- (Focus.P; a plain hand's Focus.P.Hand) and goal in "FocusGoal", and only one that has it
-- is drawn: the rest,
-- and the hands under an arrow that has it, stay see-through till it goes.
-- TapHand.register(image) counts another one in (the Tutorial's own). Whoever shows a hand
-- keeps setting Visible as before.
--
-- The spotlight (QM, Oct 13: only for buying World 2 from the bar, and opening and claiming
-- the starter quest): a hand with the "Spotlight" attribute, while it's the one shown,
-- darkens the whole screen but for a box round what it points at (its parent), and is
-- drawn again over the dark. The dark doesn't take clicks.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Focus = require(script.Parent.Focus)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

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
		Focus.want(image, false)
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
-- (one see-through box round the target, its border a huge dark stroke out over the rest
-- of the screen: one piece, so no seams, QM)
local hole = Instance.new("Frame")
hole.BackgroundTransparency = 1
hole.BorderSizePixel = 0
hole.Active = false
local dark = Instance.new("UIStroke")
dark.Color = Color3.new(0, 0, 0)
dark.Transparency = DIM
dark.Thickness = 4000
dark.LineJoinMode = Enum.LineJoinMode.Miter
dark.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
dark.Parent = hole
hole.Parent = gui
local copy = Instance.new("ImageLabel") -- (the hand, over the dark)
copy.BackgroundTransparency = 1
copy.ZIndex = 2
copy.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function spotlight(image)
	local target = Config.World == 1 and image and image:GetAttribute("Spotlight") and image.Parent -- (World 1 only: by World 2 they know their way, QM)
	gui.Enabled = typeof(target) == "Instance" and target:IsA("GuiObject") -- (Spotlight false: none)
	if not gui.Enabled then
		return
	end
	-- (AbsolutePosition's the same frame for every ScreenGui; a Position here is from this
	-- one's corner, which is above the screen's when it's under the top bar)
	local corner = gui.AbsolutePosition
	local low = target.AbsolutePosition - Vector2.new(PAD, PAD) - corner
	local size = target.AbsoluteSize + Vector2.new(PAD, PAD) * 2
	hole.Position = UDim2.fromOffset(math.round(low.X), math.round(low.Y))
	hole.Size = UDim2.fromOffset(math.round(size.X), math.round(size.Y))
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
	for _, image in all do
		Focus.want(image, showing(image), image:GetAttribute("Focus") or Focus.P.Hand, image:GetAttribute("FocusGoal"))
	end
	current = nil
	for _, image in all do
		if Focus.has(image) then
			current = image
			break
		end
	end
	for _, image in all do
		image.ImageTransparency = if image == current then 0 else 1
	end
	spotlight(current)
end)

return TapHand
