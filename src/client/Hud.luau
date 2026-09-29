-- Minimal riding HUD: Hold bar with the distance on it, one action button, a
-- center message, and a coin counter with a +1 popup.
-- Button style follows the free "Studded UI" kit by RBLX Essentials
-- (https://rblx-essentials.itch.io/studded-ui): rounded face, top-lit gradient,
-- a darker bottom band, a fine stud pattern and a dark tinted outline, no drop shadow.
-- Coin icon: Naro Free Icon Pack. Lasso icon: drawn for this game in the same style.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Hud = {}

local FONT = Enum.Font.GothamBlack
local STROKE = 2.5 -- every outline (text, buttons, bar) uses this width
local INK = Color3.fromRGB(20, 20, 28)
local WHITE = Color3.new(1, 1, 1)
local STUD_TILE = 12 -- pixels per stud on buttons and the bar

local IMAGES = {
	coin = "rbxassetid://104555508261055",
	lasso = "rbxassetid://89797380977705",
	stud = "rbxassetid://125672549302143",
}

local GREEN = Color3.fromRGB(80, 206, 64)
local YELLOW = Color3.fromRGB(255, 190, 30)
local GREY = Color3.fromRGB(140, 146, 160)
local RED = Color3.fromRGB(255, 72, 72)

-- Banner colors: bad news red, good news yellow, anything else white.
local TONES = {
	["CRASH!"] = RED,
	["BUCKED OFF"] = RED,
	["TOO FAR!"] = RED,
	["EGG SAVED!"] = YELLOW,
}

local gui, coinGui, holdFrame, holdFill, distance, action, message, rideAgain, coinCount, coinScale

local function darker(c, k)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local function lighter(c, k)
	return c:Lerp(WHITE, k)
end

local function outline(parent, color, mode)
	local s = Instance.new("UIStroke")
	s.Thickness = STROKE
	s.Color = color or INK
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
	return s
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function label(parent, size, position, textSize)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = WHITE
	l.Text = ""
	outline(l)
	l.Parent = parent
	return l
end

local function image(parent, id, size, position)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.AnchorPoint = Vector2.new(0.5, 0.5)
	i.Size = size
	i.Position = position
	i.Image = id
	i.Parent = parent
	return i
end

-- Fine stud pattern, clipped to the same rounded corners as its parent.
local function studs(parent, radius)
	local s = Instance.new("ImageLabel")
	s.Name = "Studs"
	s.BackgroundTransparency = 1
	s.Size = UDim2.fromScale(1, 1)
	s.Image = IMAGES.stud
	s.ScaleType = Enum.ScaleType.Tile
	s.TileSize = UDim2.fromOffset(STUD_TILE, STUD_TILE)
	s.ImageTransparency = 0.45
	s.ZIndex = parent.ZIndex + 1
	corner(s, radius)
	s.Parent = parent
	return s
end

-- Top-lit face with a darker band along the bottom edge.
local function shade(face, color)
	local g = face:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, lighter(color, 0.22)),
		ColorSequenceKeypoint.new(0.8, color),
		ColorSequenceKeypoint.new(0.81, darker(color, 0.8)),
		ColorSequenceKeypoint.new(1, darker(color, 0.8)),
	})
	g.Parent = face
	face.BackgroundColor3 = WHITE
	face.UIStroke.Color = darker(color, 0.35)
end

local function button(name, size, color, textSize, onActivated)
	local radius = UDim.new(0, 14)
	local root = Instance.new("TextButton")
	root.Name = name
	root.Size = size
	root.BackgroundTransparency = 1
	root.Text = ""
	root.AutoButtonColor = false

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	corner(face, radius)
	outline(face, nil, Enum.ApplyStrokeMode.Border)
	studs(face, radius)
	face.Parent = root
	local scale = Instance.new("UIScale")
	scale.Parent = face

	local text = label(face, UDim2.new(1, -12, 0, textSize + 8), UDim2.fromScale(0.5, 0.5), textSize)
	text.Name = "Label"
	text.ZIndex = 4

	local press = TweenInfo.new(0.08)
	root.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.93 }):Play()
	end)
	for _, event in { root.MouseButton1Up, root.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
	root.Activated:Connect(onActivated)

	local function setColor(c)
		shade(face, c)
	end
	setColor(color)
	return { root = root, face = face, label = text, setColor = setColor }
end

function Hud.init(onAction, onRideAgain)
	-- With ShowHud off the HUD is built but never parented, so nothing shows.
	local playerGui = Config.ShowHud and Players.LocalPlayer:WaitForChild("PlayerGui") or nil
	if not Config.ShowHud then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "RideHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = playerGui

	-- Hold bar: dark rounded track, studded green fill, distance written on top.
	local barRadius = UDim.new(1, 0)
	holdFrame = Instance.new("Frame")
	holdFrame.Name = "Hold"
	holdFrame.AnchorPoint = Vector2.new(0.5, 0)
	holdFrame.Position = UDim2.new(0.5, 0, 0, 52)
	holdFrame.Size = UDim2.fromOffset(320, 34)
	holdFrame.BackgroundColor3 = Color3.fromRGB(40, 42, 56)
	holdFrame.BorderSizePixel = 0
	corner(holdFrame, barRadius)
	outline(holdFrame, nil, Enum.ApplyStrokeMode.Border)
	holdFrame.Parent = gui
	local well = Instance.new("Frame")
	well.BackgroundTransparency = 1
	well.Position = UDim2.fromOffset(4, 4)
	well.Size = UDim2.new(1, -8, 1, -8)
	well.Parent = holdFrame
	holdFill = Instance.new("Frame")
	holdFill.Name = "Fill"
	holdFill.Size = UDim2.fromScale(1, 1)
	holdFill.BorderSizePixel = 0
	corner(holdFill, barRadius)
	local fillStroke = outline(holdFill, nil, Enum.ApplyStrokeMode.Border)
	fillStroke.Transparency = 1
	studs(holdFill, barRadius)
	holdFill.Parent = well
	shade(holdFill, GREEN)

	distance = label(holdFrame, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), 20)
	distance.ZIndex = 5

	message = label(gui, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)

	action = button("Action", UDim2.fromOffset(140, 140), YELLOW, 24, onAction)
	image(action.face, IMAGES.lasso, UDim2.fromOffset(84, 84), UDim2.new(0.5, 0, 0, 54)).ZIndex = 3
	action.label.Position = UDim2.new(0.5, 0, 1, -24)
	action.root.AnchorPoint = Vector2.new(1, 1)
	action.root.Position = UDim2.new(1, -40, 1, -40)
	action.root.Parent = gui

	rideAgain = button("RideAgain", UDim2.fromOffset(260, 72), GREEN, 30, onRideAgain)
	rideAgain.root.AnchorPoint = Vector2.new(0.5, 0.5)
	rideAgain.root.Position = UDim2.fromScale(0.5, 0.48)
	rideAgain.label.Text = "RIDE AGAIN"
	rideAgain.root.Visible = false
	rideAgain.root.Parent = gui

	-- Coin counter, always visible, bottom left.
	coinGui = Instance.new("ScreenGui")
	coinGui.Name = "CoinHud"
	coinGui.ResetOnSpawn = false
	coinGui.IgnoreGuiInset = true
	coinGui.Parent = playerGui
	local counter = Instance.new("Frame")
	counter.Name = "Coins"
	counter.BackgroundTransparency = 1
	counter.AnchorPoint = Vector2.new(0, 1)
	counter.Position = UDim2.new(0, 28, 1, -28)
	counter.Size = UDim2.fromOffset(220, 64)
	counter.Parent = coinGui
	coinScale = Instance.new("UIScale")
	coinScale.Parent = counter
	image(counter, IMAGES.coin, UDim2.fromOffset(64, 64), UDim2.fromOffset(32, 32))
	coinCount = label(counter, UDim2.fromOffset(150, 64), UDim2.fromOffset(72 + 75, 32), 38)
	coinCount.TextXAlignment = Enum.TextXAlignment.Left
	coinCount.Text = "0"
end

function Hud.show(visible)
	gui.Enabled = visible
	if not visible then
		message.Text = ""
		rideAgain.root.Visible = false
	end
end

function Hud.setHold(fraction)
	holdFrame.Visible = fraction ~= nil
	if fraction then
		holdFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		shade(holdFill, fraction < 0.3 and RED or GREEN)
	end
end

function Hud.setDistance(text)
	distance.Text = text
end

-- text = nil hides the button; ready = false greys it out.
function Hud.setAction(text, ready)
	action.root.Visible = text ~= nil
	action.label.Text = text or ""
	action.setColor(ready and YELLOW or GREY)
end

function Hud.flash(text, seconds)
	message.Text = text
	message.TextColor3 = TONES[text] or WHITE
	message.TextTransparency = 0
	message.UIStroke.Transparency = 0
	message.Size = UDim2.fromOffset(500, 70)
	TweenService:Create(message, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(600, 80) }):Play()
	if seconds then
		task.delay(seconds, function()
			if message.Text == text then
				local fade = TweenInfo.new(0.3)
				TweenService:Create(message, fade, { TextTransparency = 1 }):Play()
				TweenService:Create(message.UIStroke, fade, { Transparency = 1 }):Play()
			end
		end)
	end
end

function Hud.showRideAgain(visible)
	rideAgain.root.Visible = visible
end

function Hud.setCoins(amount)
	coinCount.Text = tostring(amount)
	coinScale.Scale = 1.25
	TweenService:Create(coinScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- "+1" with a coin that pops in at a screen point, floats up and fades.
-- Same pattern as the common DevForum coin-popup recipe: pop with Back easing, rise with Quad, fade out.
function Hud.coinPopup(screenPoint, amount)
	local popup = Instance.new("Frame")
	popup.BackgroundTransparency = 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y)
	popup.Size = UDim2.fromOffset(130, 56)
	popup.Parent = coinGui
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = popup
	local text = label(popup, UDim2.fromOffset(70, 56), UDim2.fromOffset(35, 28), 40)
	text.Text = "+" .. tostring(amount or 1)
	text.TextColor3 = Color3.fromRGB(255, 226, 70)
	text.TextXAlignment = Enum.TextXAlignment.Right
	local icon = image(popup, IMAGES.coin, UDim2.fromOffset(50, 50), UDim2.fromOffset(100, 28))
	icon.Rotation = -12

	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Rotation = 8 }):Play()
	TweenService:Create(popup, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y - 80),
	}):Play()
	task.delay(0.65, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(text.UIStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(icon, fade, { ImageTransparency = 1 }):Play()
	end)
	task.delay(1.05, function()
		popup:Destroy()
	end)
end

return Hud
