-- The riding UI (QM, Oct 10: v4, QM's UI guide; no buttons: E on the lasso's prompt is
-- the only control, LassoPrompt), in place of the old riding HUD (Config.RideHud off).
-- Hud hands its riding calls on to this.
--   Top centre: "BOSS IN" over the bar (QM, Oct 10: the red one): the dark bar, and the
--     red one over it cut off at the ride's time left; the seconds left in the middle
--     ("15.6s", Fredoka One), white, turning red from half the time left down to none.
--     Under half left, the bar (not the seconds) pulses in and out (PULSE: QM, Oct 10).
-- Laid out on a RefWidth-wide screen (Config.BaseUi; the art's drawn at it).
--
--   RideUi.show(visible)
--   RideUi.setHold(fraction)            -- of Config.RideSeconds left (nil: no bar)
--   (setDistance, setSprint, setAbility, setAction, sprintHeld, abilityPressed: nothing)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ART = { -- assets/ui/ride_hud/*.png, drawn at the RefWidth screen's size
	progress = { id = "rbxassetid://107856418081919", size = Vector2.new(646, 91) }, -- BossBar.png (QM's FILLED)
	progressGrey = { id = "rbxassetid://102078867817834", size = Vector2.new(646, 91) }, -- BossBarEmpty.png (QM's DISABLED)
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
-- (RefWidth px, from QM's guide, Oct 10: a 1522 x 826 shot, so its height is 1042 here)
local TOP = 108 -- the bar off the top
local BAR_WIDTH = 646
local FILL_FROM, FILL_TO = 6 / 646, 640 / 646 -- the bar's inner fill, of its width
local RED_FROM = 0.5 -- the seconds turn from white to red from this much time left down to none (QM)
local RED = Color3.fromRGB(255, 60, 80)
local PULSE = { From = 0.5, In = 0.9, Out = 1.05, Time = 0.8 } -- under From left: the bar's scale between In and Out, every Time s
local TITLE = "BOSS IN" -- (QM, Oct 10; was "Lasso will break", "Boss will spawn")
local TITLE_Y, TITLE_TEXT = 69, 46 -- the title's middle off the top, its size
local TIME_FONT = Font.fromEnum(Enum.Font.FredokaOne) -- (the bar's not Montserrat: QM)
local TIME_TEXT = 42
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
local fill = picture(clip, ART.progress, Vector2.zero, UDim2.new())
fill.Size = bar.Size
local barScale = Instance.new("UIScale")
barScale.Parent = bar
-- (on its own over the bar's middle, so it doesn't pulse with it)
local seconds = text(root, TIME_TEXT)
seconds.FontFace = TIME_FONT
seconds.UIStroke:Destroy() -- (plain white: QM's guide)
seconds.Name = "Seconds"
seconds.Position = UDim2.new(0.5, 0, 0, TOP + BAR_WIDTH * ART.progress.size.Y / ART.progress.size.X / 2)
seconds.ZIndex = 2

function RideUi.show(visible)
	gui.Enabled = visible
end

function RideUi.setHold(fraction)
	bar.Visible = fraction ~= nil
	title.Visible = fraction ~= nil
	seconds.Visible = fraction ~= nil
	if fraction then
		local f = math.clamp(fraction, 0, 1)
		clip.Size = UDim2.fromScale(if f <= 0 then 0 else FILL_FROM + (FILL_TO - FILL_FROM) * f, 1)
		seconds.TextColor3 = RED:Lerp(Color3.new(1, 1, 1), math.clamp(f / RED_FROM, 0, 1))
		seconds.Text = string.format("%.1fs", f * Config.RideSeconds)
		local k = 0.5 - math.cos(os.clock() / PULSE.Time * 2 * math.pi) / 2 -- (0 -> 1 -> 0, eased)
		barScale.Scale = if f < PULSE.From then PULSE.In + (PULSE.Out - PULSE.In) * k else 1
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
