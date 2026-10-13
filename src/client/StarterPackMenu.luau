-- The Starter Pack popup (QM, Oct 13: his mockup; a look test, Buy does nothing yet): the
-- Starter Pack button (PassButtons) opens it. As the Worlds menu: a dark rounded panel,
-- its title across the top edge, the X on its top right corner, the world behind hazy like
-- frosted glass and every other bit of UI gone while it's up. "Amazing Deal!", QM's two
-- cards (150k cash, the Snake), each with the sunburst turning behind it, and his Buy
-- button (Robux 19) under them.
--
--   StarterPackMenu.open()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local StarterPackMenu = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide (QM's mockup x 0.84)
local CLOSE = "rbxassetid://84920756991403" -- dex/IndexClose.png (the Worlds menu's X)
local SUNBURST = "rbxassetid://85834206672187" -- assets/ui/Sunburst.png (QM's)
local ART = { -- assets/ui/starterpack (QM's)
	cash = "rbxassetid://111300482619596", -- Cash.png (267x275): "150k"
	snake = "rbxassetid://82082521618286", -- Snake.png (267x275): "SNAKE"
	buy = "rbxassetid://79299508640873", -- Buy.png (220x113): Robux 19
}
local PANEL = Vector2.new(796, 479)
local CARD = Vector2.new(172, 177)
local CARD_Y = 214 -- the cards' middle, from the panel's top
local BUY = Vector2.new(141, 72)
local BUY_Y = 387
local SPIN = 25 -- the sunbursts' degrees a second
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local GOLD = Color3.fromRGB(255, 209, 64) -- "Amazing Deal!"

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local open = false

local function pressable(button)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local press = TweenInfo.new(0.08)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.95 }):Play()
	end)
	for _, event in { button.MouseButton1Up, button.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
end

local function label(parent, text, color, size, position, stroke)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = MONTSERRAT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = position
	l.Size = size
	l.ZIndex = 3
	local s = Instance.new("UIStroke")
	s.Thickness = stroke
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "StarterPackMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -1 -- (as the other menus)
gui.Enabled = false
local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
root.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL.X, PANEL.Y)
panel.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
panel.BackgroundTransparency = 0.15
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 11)
corner.Parent = panel
local edge = Instance.new("UIStroke")
edge.Color = Color3.fromRGB(16, 16, 16)
edge.Thickness = 4
edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
edge.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

label(panel, "Starter Pack", Color3.new(1, 1, 1), UDim2.fromOffset(300, 46), UDim2.new(0.5, 0, 0, -3), 3)
label(panel, "Amazing Deal!", GOLD, UDim2.fromOffset(300, 36), UDim2.new(0.5, 0, 0, 90), 3)

local closeButton = Instance.new("ImageButton")
closeButton.Name = "Close"
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Image = CLOSE
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Position = UDim2.new(1, -5, 0, 6)
closeButton.Size = UDim2.fromOffset(71, 71)
closeButton.ZIndex = 4
pressable(closeButton)
closeButton.Parent = panel

-- The two cards, the sunburst turning behind each.
local bursts = {}
for i, art in { ART.cash, ART.snake } do
	local x = if i == 1 then 0.378 else 0.622
	local burst = Instance.new("ImageLabel")
	burst.Name = "Sunburst"
	burst.BackgroundTransparency = 1
	burst.Image = SUNBURST
	burst.ImageTransparency = 0.15
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.new(x, 0, 0, CARD_Y)
	burst.Size = UDim2.fromOffset(CARD.X * 1.7, CARD.X * 1.7)
	burst.ZIndex = 1
	burst.Parent = panel
	table.insert(bursts, burst)
	local card = Instance.new("ImageLabel")
	card.Name = if i == 1 then "Cash" else "Snake"
	card.BackgroundTransparency = 1
	card.Image = art
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(x, 0, 0, CARD_Y)
	card.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	card.ZIndex = 2
	card.Parent = panel
end

local buy = Instance.new("ImageButton")
buy.Name = "Buy"
buy.BackgroundTransparency = 1
buy.AutoButtonColor = false
buy.Image = ART.buy
buy.AnchorPoint = Vector2.new(0.5, 0.5)
buy.Position = UDim2.new(0.5, 0, 0, BUY_Y)
buy.Size = UDim2.fromOffset(BUY.X, BUY.Y)
buy.ZIndex = 3
pressable(buy)
buy.Parent = panel
gui.Parent = player:WaitForChild("PlayerGui")

-- The world behind hazy (as the Worlds menu's).
local HAZE = { blur = 14, brightness = 0.06, contrast = -0.15, saturation = -0.35 }
local blur = Instance.new("BlurEffect")
blur.Name = "StarterPackHaze"
blur.Size = 0
blur.Enabled = false
blur.Parent = camera
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "StarterPackHaze"
tint.Enabled = false
tint.Parent = camera
local hazeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function haze(on)
	local k = if on then 1 else 0
	blur.Enabled, tint.Enabled = true, true
	TweenService:Create(blur, hazeTween, { Size = HAZE.blur * k }):Play()
	local t = TweenService:Create(tint, hazeTween, { Brightness = HAZE.brightness * k, Contrast = HAZE.contrast * k, Saturation = HAZE.saturation * k })
	t.Completed:Connect(function()
		if not open then
			blur.Enabled, tint.Enabled = false, false
		end
	end)
	t:Play()
end

-- Every other bit of UI goes while it's up (as the Worlds menu).
local hidden, holdHidden = {}, nil
local function hideOthers(on)
	if holdHidden then
		holdHidden:Disconnect()
		holdHidden = nil
	end
	if on then
		player:SetAttribute("Cutscene", true) -- (BaseUi and the guides keep themselves off)
		local function hideAll()
			for _, g in player.PlayerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and g ~= gui then
					g.Enabled = false
					if not table.find(hidden, g) then
						table.insert(hidden, g)
					end
				end
			end
		end
		hideAll()
		holdHidden = RunService.RenderStepped:Connect(hideAll)
	else
		for _, g in hidden do
			g.Enabled = true
		end
		table.clear(hidden)
		player:SetAttribute("Cutscene", nil)
	end
end

local function setScale(scale)
	panelScale.Scale = scale
end

function StarterPackMenu.open()
	if open then
		return
	end
	open = true
	hideOthers(true)
	gui.Enabled = true
	haze(true)
	ModalPop.open(setScale)
end

local function close()
	if not open then
		return
	end
	open = false
	hideOthers(false)
	haze(false)
	ModalPop.close(setScale, function()
		gui.Enabled = false
	end)
end
closeButton.Activated:Connect(close)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		for _, burst in bursts do
			burst.Rotation = os.clock() * SPIN % 360
		end
	end
end)

return StarterPackMenu
