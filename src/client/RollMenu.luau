-- The egg roll menu (QM, Oct 4): the Roll button over Pets opens it. QM's panel
-- (the title, the exclusives' silhouettes and the eggs you can roll, baked into the
-- art), the same size and place as the shop's, with ROLL $1M over the eggs and the
-- shop's green ? on its top-right corner, which flips it to QM's odds art and back
-- (ROLL steps aside while the odds show). The roll itself is Hud's (RollGacha, then
-- the egg card; with too little gold it offers a gold pack instead); clicking
-- anywhere off the panel closes it, like the animal dictionary.
--
--   RollMenu.toggle() / RollMenu.close()
--   RollMenu.onToggle = function(open)     -- Hud hides the rest of the home HUD
--   RollMenu.onRoll = function()           -- ROLL was pressed
--   RollMenu.setHidden(yes)                -- out of the way while the egg card shows

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local ModalPop = require(script.Parent.ModalPop)

local RollMenu = {}

local REFERENCE_WIDTH = 1320 -- Hud's: sizes below are pixels on a screen this wide
-- QM's art. The panel's frame starts FRAME_TOP down its picture (the silhouettes
-- reach up over it); the odds art is padded to the same size, frame for frame.
local PANEL = { id = "rbxassetid://104698392936555", size = Vector2.new(2892, 1900) } -- RollPanel.png
local ODDS = "rbxassetid://110875946388838" -- RollPanelOdds.png
local FRAME_TOP = 305 / 1900
local ODDS_BUTTON = "rbxassetid://83654143211576" -- ShopOddsButton.png (the green ?)
local BUTTON = { id = "rbxassetid://119520152431016", size = Vector2.new(960, 378) } -- RollButton.png (ROLL $1M)
local PANEL_WIDTH = 930 -- the shop's
local BUTTON_WIDTH = PANEL_WIDTH * 0.23 -- as in QM's mockup
local ODDS_SIZE = 64

local player = Players.LocalPlayer
local open, hidden, closing = false, false, false

local gui = Instance.new("ScreenGui")
gui.Name = "RollMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = -2 -- under the HUD, so the Roll button that closes it stays on top (and under the shop's top-up)
gui.Enabled = false

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
local rootScale = Instance.new("UIScale")
rootScale.Parent = root
local camera = workspace.CurrentCamera
local function resize()
	local screen = camera.ViewportSize
	rootScale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
	root.Size = UDim2.fromOffset(screen.X / rootScale.Scale, screen.Y / rootScale.Scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()

-- Its frame sits where the shop's panel does (centred a little below the middle).
local panelHeight = PANEL_WIDTH * PANEL.size.Y / PANEL.size.X
local frameHeight = panelHeight * (1 - FRAME_TOP)
local panel = Instance.new("ImageLabel")
panel.Name = "Panel"
panel.BackgroundTransparency = 1
panel.Image = PANEL.id
panel.AnchorPoint = Vector2.new(0.5, 0.5) -- (so it pops about its middle)
panel.Position = UDim2.new(0.5, 0, 0.52, panelHeight / 2 - (panelHeight * FRAME_TOP + frameHeight / 2))
panel.Size = UDim2.fromOffset(PANEL_WIDTH, panelHeight)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
panel.Parent = root

local roll = Instance.new("ImageButton")
roll.Name = "Roll"
roll.BackgroundTransparency = 1
roll.AutoButtonColor = false
roll.Image = BUTTON.id
roll.AnchorPoint = Vector2.new(0.5, 0.5)
roll.Position = UDim2.fromScale(0.5, 0.85) -- over the eggs
roll.Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_WIDTH * BUTTON.size.Y / BUTTON.size.X)
roll.ZIndex = 2
local rollScale = Instance.new("UIScale")
rollScale.Parent = roll
roll.Parent = panel
local press = TweenInfo.new(0.08)
roll.MouseButton1Down:Connect(function()
	TweenService:Create(rollScale, press, { Scale = 0.93 }):Play()
end)
for _, event in { roll.MouseButton1Up, roll.MouseLeave } do
	event:Connect(function()
		TweenService:Create(rollScale, press, { Scale = 1 }):Play()
	end)
end
roll.Activated:Connect(function()
	if RollMenu.onRoll then
		RollMenu.onRoll()
	end
end)

-- The ? flips the panel to the odds (a paid random item: the odds are shown) and
-- back. QM's odds art matches Config.Gacha's Odds and Pools: keep them in step.
local showingOdds = false
local function setOdds(yes)
	showingOdds = yes
	panel.Image = if yes then ODDS else PANEL.id
	roll.Visible = not yes
end
local flip = Instance.new("ImageButton")
flip.Name = "Odds"
flip.BackgroundTransparency = 1
flip.AutoButtonColor = false
flip.Image = ODDS_BUTTON
flip.AnchorPoint = Vector2.new(0.5, 0.5)
flip.Position = UDim2.new(1, -ODDS_SIZE * 0.3, FRAME_TOP, ODDS_SIZE * 0.3) -- on the frame's top-right corner
flip.Size = UDim2.fromOffset(ODDS_SIZE, ODDS_SIZE)
flip.ZIndex = 3
local flipScale = Instance.new("UIScale")
flipScale.Parent = flip
flip.MouseButton1Down:Connect(function()
	TweenService:Create(flipScale, press, { Scale = 0.93 }):Play()
end)
for _, event in { flip.MouseButton1Up, flip.MouseLeave } do
	event:Connect(function()
		TweenService:Create(flipScale, press, { Scale = 1 }):Play()
	end)
end
flip.Activated:Connect(function()
	setOdds(not showingOdds)
end)
flip.Parent = panel

-- Clicking anywhere off the panel and its button closes it.
local function over(object, at)
	local min, size = object.AbsolutePosition, object.AbsoluteSize
	return at.X >= min.X and at.Y >= min.Y and at.X <= min.X + size.X and at.Y <= min.Y + size.Y
end
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 0
backdrop.Activated:Connect(function(input)
	local at = Vector2.new(input.Position.X, input.Position.Y)
	if not over(panel, at) and not over(flip, at) then
		RollMenu.close()
	end
end)
backdrop.Parent = gui
root.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	gui.Enabled = (open or closing) and not hidden
end

-- It pops in and out (ModalPop), hiding once it has shrunk away.
local function setScale(scale)
	panelScale.Scale = scale
end

function RollMenu.toggle()
	open = not open
	closing = not open and not hidden -- (out of the way for the egg card: it just goes)
	refresh()
	if open then
		setOdds(false) -- the eggs first, every time
		ModalPop.open(setScale)
	else
		ModalPop.close(setScale, function()
			closing = false
			refresh()
		end)
	end
	if RollMenu.onToggle then
		RollMenu.onToggle(open)
	end
end

function RollMenu.close()
	if open then
		RollMenu.toggle()
	end
end

function RollMenu.isOpen()
	return open
end

function RollMenu.setHidden(yes)
	hidden = yes
	refresh()
end

return RollMenu
