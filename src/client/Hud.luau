-- Riding HUD built from QM's images: the Hold bar with the distance on it, one
-- action button (TAKE EGG or LASSO), a center message, and the home buttons
-- (RIDE, Gold, Pets, Eggs). Layout follows QM's mockups.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Hud = {}

local FONT = Enum.Font.FredokaOne
local STROKE = 6
local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 72, 72)
local YELLOW = Color3.fromRGB(255, 190, 30)

-- Uploaded from QM's ui_assets; size is each image's native pixel size.
local IMAGES = {
	takeEgg = { id = "rbxassetid://104292931687556", size = Vector2.new(960, 434) },
	lasso = { id = "rbxassetid://94121512214531", size = Vector2.new(960, 358) },
	lassoDisabled = { id = "rbxassetid://83416502851504", size = Vector2.new(960, 358) },
	ride = { id = "rbxassetid://108897443176698", size = Vector2.new(960, 308) },
	home = { id = "rbxassetid://91332218189700", size = Vector2.new(960, 364) },
	buckedOff = { id = "rbxassetid://123571061022694", size = Vector2.new(1015, 300) },
	barFilled = { id = "rbxassetid://82401653732533", size = Vector2.new(1292, 220) },
	barEmpty = { id = "rbxassetid://128272625286546", size = Vector2.new(1292, 220) },
	pets = { id = "rbxassetid://90844952883979", size = Vector2.new(254, 256) },
	gold = { id = "rbxassetid://75090734827129", size = Vector2.new(262, 263) },
	eggs = { id = "rbxassetid://76827079745406", size = Vector2.new(264, 277) },
	coin = { id = "rbxassetid://104555508261055", size = Vector2.new(1, 1) }, -- +1 popup, Naro Free Icon Pack
}

local BUTTON_WIDTH = 320
local BAR_WIDTH = 440
local ICON_HEIGHT = 80 -- Gold
local SIDE_ICON_HEIGHT = 80 -- Pets and Eggs, a little smaller in the mockup
local MARGIN = 24
local REFERENCE_WIDTH = 1320 -- screen width the sizes above are drawn for

-- Action text from the ride -> which image the action button shows.
local ACTIONS = { ["GRAB EGG"] = "takeEgg", LASSO = "lasso" }

-- Banners drawn as images instead of text.
local BANNERS = { ["BUCKED OFF"] = "buckedOff" }

-- Banner colors: bad news red, good news yellow, anything else white.
local TONES = {
	["CRASH!"] = RED,
	["BUCKED OFF"] = RED,
	["TOO FAR!"] = RED,
	["EGG SAVED!"] = YELLOW,
}

local gui, homeGui, rideRoot, homeRoot, rootScale, holdFrame, holdClip, distance, action, message, home, banner, ride, gold, pets, eggs, goldScale

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
	local s = Instance.new("UIStroke")
	s.Thickness = STROKE
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- Image at its native aspect ratio: pass a width or a height and the other follows.
local function fit(key, width, height)
	local native = IMAGES[key].size
	return UDim2.fromOffset(width or height * native.X / native.Y, height or width * native.Y / native.X)
end

local function image(parent, key, size, position)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.AnchorPoint = Vector2.new(0.5, 0.5)
	i.Size = size
	i.Position = position
	i.Image = IMAGES[key].id
	i.Parent = parent
	return i
end

-- Full-screen frame that everything is laid out in, in pixels of a REFERENCE_WIDTH
-- wide screen. It's scaled to the real screen width, so the HUD keeps the mockup's
-- proportions (Hold bar a third of the screen, action button a quarter).
local function root(screenGui)
	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local camera = workspace.CurrentCamera
	local function resize()
		local screen = camera.ViewportSize
		scale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
		frame.Size = UDim2.fromOffset(screen.X / scale.Scale, screen.Y / scale.Scale)
		rootScale = scale.Scale
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()
	frame.Parent = screenGui
	return frame
end

-- Image button that shrinks a little while pressed.
local function button(parent, key, size, anchor, position, onActivated)
	local root = Instance.new("ImageButton")
	root.Name = key
	root.BackgroundTransparency = 1
	root.AnchorPoint = anchor
	root.Size = size
	root.Position = position
	root.Image = IMAGES[key].id
	local scale = Instance.new("UIScale")
	scale.Parent = root
	local press = TweenInfo.new(0.08)
	root.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.93 }):Play()
	end)
	for _, event in { root.MouseButton1Up, root.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
	if onActivated then
		root.Activated:Connect(onActivated)
	end
	root.Parent = parent
	return root, scale
end

local BOTTOM_CENTER = Vector2.new(0.5, 1)
local BUTTON_SPOT = UDim2.new(0.5, 0, 1, -MARGIN)

-- Gold sits bottom left at home and just right of the Hold bar while riding.
local function placeGold(riding)
	if riding then
		gold.AnchorPoint = Vector2.new(0, 0.5)
		gold.Position = UDim2.new(0.5, BAR_WIDTH / 2 + 8, 0, holdFrame.Position.Y.Offset)
	else
		gold.AnchorPoint = Vector2.new(0, 1)
		gold.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
	end
end

function Hud.init(onAction, onHome, onRide)
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
	rideRoot = root(gui)

	-- Hold bar: the empty bar, with the full bar cropped to the Hold fraction on top.
	-- The full image keeps the bar's size inside the clip, so the crop lines up 1:1.
	local barSize = fit("barEmpty", BAR_WIDTH)
	holdFrame = image(rideRoot, "barEmpty", barSize, UDim2.new(0.5, 0, 0, 16 + barSize.Y.Offset / 2))
	holdFrame.Name = "Hold"
	holdClip = Instance.new("Frame")
	holdClip.Name = "Fill"
	holdClip.BackgroundTransparency = 1
	holdClip.ClipsDescendants = true
	holdClip.Size = UDim2.fromScale(1, 1)
	holdClip.Parent = holdFrame
	local filled = image(holdClip, "barFilled", barSize, UDim2.fromScale(0, 0))
	filled.AnchorPoint = Vector2.zero

	-- Distance sits on the bar but outside it, so it still shows once the bar is gone.
	distance = label(rideRoot, UDim2.fromOffset(BAR_WIDTH, barSize.Y.Offset), holdFrame.Position, 50)
	distance.Name = "Distance"
	distance.UIStroke.Thickness = 4
	distance.ZIndex = 2

	message = label(rideRoot, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)
	banner = image(rideRoot, "buckedOff", fit("buckedOff", 560), message.Position)
	banner.Visible = false
	Instance.new("UIScale").Parent = banner

	action = button(rideRoot, "lasso", fit("lasso", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onAction)
	action.Name = "Action"

	home = button(rideRoot, "home", fit("home", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onHome)
	home.Visible = false

	-- Home buttons, always on screen outside a ride; Gold stays during rides too.
	homeGui = Instance.new("ScreenGui")
	homeGui.Name = "HomeHud"
	homeGui.ResetOnSpawn = false
	homeGui.IgnoreGuiInset = true
	homeGui.Parent = playerGui
	homeRoot = root(homeGui)
	ride = button(homeRoot, "ride", fit("ride", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onRide)
	ride.Visible = false
	gold, goldScale = button(homeRoot, "gold", fit("gold", nil, ICON_HEIGHT), Vector2.zero, UDim2.new())
	local eggsSize = fit("eggs", nil, SIDE_ICON_HEIGHT)
	eggs = button(homeRoot, "eggs", eggsSize, Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN))
	pets = button(homeRoot, "pets", fit("pets", nil, SIDE_ICON_HEIGHT), Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN - eggsSize.Y.Offset - 8))
	placeGold(false)

	-- Load every image now, so the first BUCKED OFF isn't still downloading while it animates.
	task.spawn(function()
		local ids = {}
		for _, entry in IMAGES do
			table.insert(ids, entry.id)
		end
		game:GetService("ContentProvider"):PreloadAsync(ids)
	end)
end

function Hud.show(visible)
	gui.Enabled = visible
	if not visible then
		message.Text = ""
		banner.Visible = false
		home.Visible = false
	end
	gold.Visible = true
	ride.Visible = false -- comes back when the ride prompt shows again
	pets.Visible = not visible
	eggs.Visible = not visible
	placeGold(visible)
end

function Hud.setHold(fraction)
	holdFrame.Visible = fraction ~= nil
	if fraction then
		holdClip.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
	end
end

function Hud.setDistance(text)
	distance.Text = text
end

-- text = nil hides the button; ready = false shows LASSO's disabled image.
function Hud.setAction(text, ready)
	action.Visible = text ~= nil
	if text then
		local key = ACTIONS[text]
		if key == "lasso" and not ready then
			key = "lassoDisabled"
		end
		action.Image = IMAGES[key].id
		action.Size = fit(key, BUTTON_WIDTH)
	end
end

-- Slams a banner image in: drops from big to size fast, squashes, and shakes.
local function slam(key)
	banner.Image = IMAGES[key].id
	banner.Size = fit(key, 560)
	banner.Visible = true
	banner.ImageTransparency = 1
	banner.Rotation = -4
	local scale = banner.UIScale
	scale.Scale = 3
	local rest = banner.Position
	TweenService:Create(banner, TweenInfo.new(0.12), { ImageTransparency = 0 }):Play()
	local drop = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
	drop.Completed:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
		TweenService:Create(banner, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		task.spawn(function()
			for i = 14, 1, -1 do
				banner.Position = rest + UDim2.fromOffset(math.random(-i, i) * 2, math.random(-i, i) * 2)
				task.wait(0.03)
			end
			banner.Position = rest
		end)
	end)
	drop:Play()
end

function Hud.flash(text, seconds)
	-- Fail screens hide the ride's cash.
	if TONES[text] == RED then
		gold.Visible = false
	end
	banner.Visible = false
	if BANNERS[text] then
		message.Text = ""
		slam(BANNERS[text])
		return
	end
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

-- RIDE shows only while you're close enough to your animal (replaces the [E] prompt).
function Hud.showRide(visible)
	ride.Visible = visible and not gui.Enabled
end

function Hud.showGold(visible)
	gold.Visible = visible
end

-- Home button, shown after a failed ride; sends you back home.
function Hud.showHome(visible)
	home.Visible = visible
end

-- The amount is baked into the Gold image for now, so this only pops the icon.
function Hud.setCoins(_amount)
	goldScale.Scale = 1.25
	TweenService:Create(goldScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- "+1" with a coin that pops in at a screen point, floats up and fades.
-- Same pattern as the common DevForum coin-popup recipe: pop with Back easing, rise with Quad, fade out.
function Hud.coinPopup(screenPoint, amount)
	screenPoint /= rootScale -- screen pixels -> HUD root pixels
	local popup = Instance.new("Frame")
	popup.BackgroundTransparency = 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y)
	popup.Size = UDim2.fromOffset(130, 56)
	popup.Parent = homeRoot
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = popup
	local text = label(popup, UDim2.fromOffset(70, 56), UDim2.fromOffset(35, 28), 40)
	text.Text = "+" .. tostring(amount or 1)
	text.TextColor3 = Color3.fromRGB(255, 226, 70)
	text.TextXAlignment = Enum.TextXAlignment.Right
	local icon = image(popup, "coin", UDim2.fromOffset(50, 50), UDim2.fromOffset(100, 28))
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
