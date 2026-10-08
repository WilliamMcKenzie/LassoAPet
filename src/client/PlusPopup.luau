-- A "+N" with an icon popping out beside a character's head, floating up and fading,
-- a little off from the last one (QM, Oct 8, like a treadmill sim's steps): training's
-- lasso catches (Training.client) and HOLD ON!'s taps (HoldOn) look exactly the same.
--
--   PlusPopup.at(character, amount, icon, how) -- amount: a number ("+1", "+1k") or text
--   how (optional): { spread = studs, tilt = degrees, size = { min, max }, burst = true }, e.g.
--   PlusPopup.SCATTER: wider, tilted and sized at random so quick ones don't cluster

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = require(script.Parent.Hud)

local POP_TIME = 0.9

local PlusPopup = {}

-- Each popup a hair nearer the camera than the one before (its StudsOffset's Z, in the
-- camera's frame), so two overlapping never z-fight: the newer one draws on top, whole.
local depth = 0
local function nextDepth()
	depth = (depth + 1) % 400
	return depth * 0.005
end

PlusPopup.SCATTER = { spread = 4, tilt = 14, size = { 0.85, 1.15 } }
-- Each from its own spot round the head, flying off outwards in a random direction
-- (not just up), a little tilted and sized at random (QM, Oct 8: training's, so they
-- don't stack in a column).
PlusPopup.BURST = { burst = true, tilt = 10, size = { 0.85, 1.15 } }

function PlusPopup.at(char, amount, icon, how)
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local rng = Random.new()
	local z = nextDepth()
	local spread = if how and how.spread then how.spread else 2.2
	local from = Vector3.new(rng:NextNumber(-spread, spread), rng:NextNumber(0.6, 0.6 + spread * 0.45), 0)
	local rise = Vector3.new(0, 2.5, 0)
	if how and how.burst then
		local a = rng:NextNumber(0, math.pi * 2)
		local dir = Vector3.new(math.cos(a), math.sin(a), 0)
		from = Vector3.new(0, 0.8, 0) + dir * rng:NextNumber(1.2, 2.6)
		rise = dir * rng:NextNumber(2.2, 3.4)
	end
	local size = if how and how.size then rng:NextNumber(how.size[1], how.size[2]) else 1
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(110, 40)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Adornee = head
	from += Vector3.new(0, 0, z)
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
	if how and how.tilt then
		row.Rotation = rng:NextNumber(-how.tilt, how.tilt)
	end
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = size }):Play()
	local riseInfo = TweenInfo.new(POP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(tag, riseInfo, { StudsOffset = from + rise }):Play()
	local fade = TweenInfo.new(POP_TIME * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, POP_TIME * 0.5)
	TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	if image then
		TweenService:Create(image, fade, { ImageTransparency = 1 }):Play()
	end
	task.delay(POP_TIME + 0.05, tag.Destroy, tag)
end

return PlusPopup
