-- Minimal riding HUD: Hold bar, distance, one action button, a center message.
-- Every outline (text, buttons, bar) uses the same black STROKE so the HUD reads as one set.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hud = {}

local FONT = Enum.Font.GothamBlack
local STROKE = 3
local INK = Color3.fromRGB(20, 20, 28)
local WHITE = Color3.new(1, 1, 1)
local DEPTH = 6 -- how far a button's face sits above its shadow, in pixels
local STUD = 14 -- stud grid spacing on buttons, in pixels

local GREEN = Color3.fromRGB(88, 214, 72)
local YELLOW = Color3.fromRGB(255, 198, 36)
local GREY = Color3.fromRGB(150, 156, 168)
local RED = Color3.fromRGB(255, 72, 72)

-- Banner colors: bad news red, good news yellow, anything else white.
local TONES = {
	["CRASH!"] = RED,
	["BUCKED OFF"] = RED,
	["TOO FAR!"] = RED,
	["EGG SAVED!"] = YELLOW,
}

local gui, holdFrame, holdFill, distance, action, message, rideAgain

local function darker(c, k)
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local function lighter(c, k)
	return c:Lerp(WHITE, k)
end

local function outline(parent, mode)
	local s = Instance.new("UIStroke")
	s.Thickness = STROKE
	s.Color = INK
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

-- A grid of tiny round studs, each a lighter dot over a darker drop, like a brick seen from above.
local function studs(parent, width, height)
	local layer = Instance.new("Frame")
	layer.Name = "Studs"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.Parent = parent
	local d = STUD * 0.5
	for x = STUD * 0.5, width, STUD do
		for y = STUD * 0.5, height, STUD do
			for _, dot in { { 1.5, 0 }, { 0, 1 } } do
				local f = Instance.new("Frame")
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Position = UDim2.fromOffset(x, y + dot[1])
				f.Size = UDim2.fromOffset(d, d)
				f.BorderSizePixel = 0
				f.BackgroundColor3 = dot[2] == 1 and WHITE or Color3.new(0, 0, 0)
				f.BackgroundTransparency = dot[2] == 1 and 0.82 or 0.86
				corner(f, UDim.new(1, 0))
				f.Parent = layer
			end
		end
	end
	return layer
end

-- Chunky brick button: a dark shadow slab under a studded face, both with the shared outline.
-- The face drops onto the shadow while pressed.
local function button(name, size, color, textSize, onActivated)
	local w, h = size.X.Offset, size.Y.Offset
	local root = Instance.new("TextButton")
	root.Name = name
	root.Size = UDim2.fromOffset(w, h + DEPTH)
	root.BackgroundTransparency = 1
	root.Text = ""
	root.AutoButtonColor = false

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Position = UDim2.fromOffset(0, DEPTH)
	shadow.Size = UDim2.fromOffset(w, h)
	shadow.BorderSizePixel = 0
	corner(shadow, UDim.new(0, 12))
	outline(shadow, Enum.ApplyStrokeMode.Border)
	shadow.Parent = root

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.Size = UDim2.fromOffset(w, h)
	face.BorderSizePixel = 0
	face.ClipsDescendants = true
	corner(face, UDim.new(0, 12))
	outline(face, Enum.ApplyStrokeMode.Border)
	face.Parent = root

	-- Top-lit: brighter at the top, base color at the bottom.
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Parent = face

	studs(face, w, h)

	-- Inner rim highlight so the face reads as a raised block.
	local rim = Instance.new("Frame")
	rim.BackgroundTransparency = 1
	rim.Position = UDim2.fromOffset(3, 3)
	rim.Size = UDim2.new(1, -6, 1, -6)
	corner(rim, UDim.new(0, 9))
	local rimStroke = Instance.new("UIStroke")
	rimStroke.Thickness = 2
	rimStroke.Color = WHITE
	rimStroke.Transparency = 0.55
	rimStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rimStroke.Parent = rim
	rim.Parent = face

	local text = label(face, UDim2.new(1, -16, 1, -8), UDim2.fromScale(0.5, 0.5), textSize)
	text.Name = "Label"
	text.TextWrapped = true
	text.ZIndex = 2

	local function setColor(c)
		face.BackgroundColor3 = c
		shade.Color = ColorSequence.new(lighter(c, 0.25), c)
		shadow.BackgroundColor3 = darker(c, 0.6)
	end
	setColor(color)

	local function press(down)
		face.Position = UDim2.fromOffset(0, down and DEPTH - 2 or 0)
	end
	root.MouseButton1Down:Connect(function()
		press(true)
	end)
	root.MouseButton1Up:Connect(function()
		press(false)
	end)
	root.MouseLeave:Connect(function()
		press(false)
	end)
	root.Activated:Connect(onActivated)

	return { root = root, label = text, setColor = setColor }
end

function Hud.init(onAction, onRideAgain)
	gui = Instance.new("ScreenGui")
	gui.Name = "RideHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	holdFrame = Instance.new("Frame")
	holdFrame.AnchorPoint = Vector2.new(0.5, 0)
	holdFrame.Position = UDim2.new(0.5, 0, 0, 56)
	holdFrame.Size = UDim2.fromOffset(260, 20)
	holdFrame.BackgroundColor3 = Color3.fromRGB(46, 48, 60)
	holdFrame.BorderSizePixel = 0
	holdFrame.ClipsDescendants = true
	corner(holdFrame, UDim.new(1, 0))
	outline(holdFrame, Enum.ApplyStrokeMode.Border)
	holdFrame.Parent = gui
	holdFill = Instance.new("Frame")
	holdFill.Size = UDim2.fromScale(1, 1)
	holdFill.BorderSizePixel = 0
	corner(holdFill, UDim.new(1, 0))
	local gloss = Instance.new("UIGradient")
	gloss.Rotation = 90
	gloss.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	gloss.Parent = holdFill
	holdFill.Parent = holdFrame

	distance = label(gui, UDim2.fromOffset(260, 34), UDim2.new(0.5, 0, 0, 100), 28)
	message = label(gui, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)

	action = button("Action", UDim2.fromOffset(150, 110), YELLOW, 28, onAction)
	action.root.AnchorPoint = Vector2.new(1, 1)
	action.root.Position = UDim2.new(1, -40, 1, -40)
	action.root.Parent = gui

	rideAgain = button("RideAgain", UDim2.fromOffset(280, 76), GREEN, 34, onRideAgain)
	rideAgain.root.AnchorPoint = Vector2.new(0.5, 0.5)
	rideAgain.root.Position = UDim2.fromScale(0.5, 0.48)
	rideAgain.label.Text = "RIDE AGAIN"
	rideAgain.root.Visible = false
	rideAgain.root.Parent = gui
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
		holdFill.BackgroundColor3 = fraction < 0.3 and RED or GREEN
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

return Hud
