-- The riding UI (QM, Oct 10: v4, QM's UI guide; no buttons: E on the lasso's prompt is
-- the only control, LassoPrompt), in place of the old riding HUD (Config.RideHud off).
-- Hud hands its riding calls on to this.
--   Top centre: "Lasso will break" over the bar: the grey bar, and the green one over it
--     cut off at the ride's time left, the seconds left in the middle ("15.6s").
-- Laid out on a RefWidth-wide screen (Config.BaseUi; the art's drawn at it).
--
--   RideUi.show(visible)
--   RideUi.setHold(fraction)            -- of Config.RideSeconds left (nil: no bar)
--   (setDistance, setSprint, setAbility, setAction, sprintHeld, abilityPressed: nothing)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ART = { -- assets/ui/ride_hud/*.png, drawn at the RefWidth screen's size
	progress = { id = "rbxassetid://112989626785487", size = Vector2.new(646, 110) }, -- ProgressPlain.png (Progress.png without its bicep)
	progressGrey = { id = "rbxassetid://77709328494221", size = Vector2.new(646, 110) }, -- ProgressDisabledPlain.png
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
-- (RefWidth px, from QM's guide, Oct 10: a 1578 x 858 shot, so its height is 1044 here)
local TOP = 116 -- the bar off the top
local BAR_WIDTH = 646
local FILL_FROM, FILL_TO = 0.015, 0.983 -- the bar's inner fill, of its width
local TITLE = "Lasso will break"
local TITLE_Y, TITLE_TEXT = 73, 46 -- the title's middle off the top, its size
local TIME_TEXT = 44
local STROKE = 4

local RideUi = {}

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RideUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui
local uiScale = Instance.new("UIScale")
uiScale.Parent = root
local function resize()
	local view = gui.AbsoluteSize
	uiScale.Scale = view.X / Config.BaseUi.RefWidth * (Config.HudScale or 1)
	root.Size = UDim2.fromOffset(view.X / uiScale.Scale, view.Y / uiScale.Scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()

local function picture(parent, art, anchor, position, width)
	local p = Instance.new("ImageLabel")
	p.BackgroundTransparency = 1
	p.Image = art.id
	width = width or art.size.X
	p.Size = UDim2.fromOffset(width, width * art.size.Y / art.size.X)
	p.AnchorPoint = anchor
	p.Position = position
	p.Parent = parent
	return p
end

local function text(parent, size)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextSize = size
	label.TextColor3 = Color3.new(1, 1, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, size)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = STROKE
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

local title = text(root, TITLE_TEXT)
title.Name = "Title"
title.Text = TITLE
title.Position = UDim2.new(0.5, 0, 0, TITLE_Y)

-- The bar.
local bar = picture(root, ART.progressGrey, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, TOP), BAR_WIDTH)
bar.Name = "Time"
local clip = Instance.new("Frame")
clip.Name = "Fill"
clip.BackgroundTransparency = 1
clip.ClipsDescendants = true
clip.Size = UDim2.fromScale(1, 1)
clip.Parent = bar
local green = picture(clip, ART.progress, Vector2.zero, UDim2.new())
green.Size = bar.Size
local seconds = text(bar, TIME_TEXT)
seconds.Name = "Seconds"
seconds.Position = UDim2.fromScale(0.5, 0.5)
seconds.ZIndex = 2

function RideUi.show(visible)
	gui.Enabled = visible
end

function RideUi.setHold(fraction)
	bar.Visible = fraction ~= nil
	title.Visible = fraction ~= nil
	if fraction then
		local f = math.clamp(fraction, 0, 1)
		clip.Size = UDim2.fromScale(if f <= 0 then 0 else FILL_FROM + (FILL_TO - FILL_FROM) * f, 1)
		seconds.Text = string.format("%.1fs", f * Config.RideSeconds)
	end
end

function RideUi.setDistance() end
function RideUi.setSprint() end
function RideUi.setAbility() end
function RideUi.setAction() end
function RideUi.sprintHeld()
	return false
end
function RideUi.abilityPressed()
	return false
end

return RideUi
