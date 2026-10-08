-- A "+N" with an icon popping out beside a character's head, floating up and fading,
-- a little off from the last one (QM, Oct 8, like a treadmill sim's steps): training's
-- lasso catches (Training.client) and HOLD ON!'s taps (HoldOn) look exactly the same.
--
--   PlusPopup.at(character, amount, icon) -- amount: a number ("+1", "+1k") or text

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = require(script.Parent.Hud)

local POP_TIME = 0.9

local PlusPopup = {}

function PlusPopup.at(char, amount, icon)
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local rng = Random.new()
	local from = Vector3.new(rng:NextNumber(-2.2, 2.2), rng:NextNumber(0.6, 1.6), 0)
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(110, 40)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Adornee = head
	tag.StudsOffset = from
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = tag
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = tag
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = row
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromOffset(0, 40)
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 30
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = "+" .. (if type(amount) == "number" then (Hud.money(amount):gsub("%$", "")) else tostring(amount))
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = text
	text.Parent = row
	local image
	if icon and icon ~= "" then
		image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromOffset(34, 34)
		image.Image = icon
		image.LayoutOrder = 1
		image.Parent = row
	end
	tag.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local rise = TweenInfo.new(POP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(tag, rise, { StudsOffset = from + Vector3.new(0, 2.5, 0) }):Play()
	local fade = TweenInfo.new(POP_TIME * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, POP_TIME * 0.5)
	TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	if image then
		TweenService:Create(image, fade, { ImageTransparency = 1 }):Play()
	end
	task.delay(POP_TIME + 0.05, tag.Destroy, tag)
end

return PlusPopup
