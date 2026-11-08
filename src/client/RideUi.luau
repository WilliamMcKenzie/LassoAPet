-- The riding UI (QM, Oct 10: v4, QM's UI guide; no buttons: E on the lasso's prompt is
-- the only control, LassoPrompt), in place of the old riding HUD (Config.RideHud off).
-- Hud hands its riding calls on to this.
--   Top centre: "BOSS IN" over the bar (QM, Oct 10: the red one): the dark bar, and the
--     red one over it cut off at the ride's time left; the seconds left in the middle
--     ("15.6s", Fredoka One), white, turning red from half the time left down to none.
--     Under half left, the bar (not the seconds) pulses in and out (PULSE: QM, Oct 10).
--     It all bounces in as it shows (POP_TIME), once you're over the start line (Ride).
-- Laid out on a RefWidth-wide screen (Config.BaseUi; the art's drawn at it).
--
--   RideUi.show(visible)
--   RideUi.setHold(fraction, _, total)  -- of total (Config.RideSeconds) seconds left (nil: no bar)
--   (setDistance, setSprint, setAbility, setAction, sprintHeld, abilityPressed: nothing)
--   RideUi.autoLasso                    -- the Auto Lasso toggle's on (bottom left: QM's Figma
--     AutoLasso/Toggle, Nov 8); Ride lassos anything faster than your mount while it is

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ART = { -- assets/ui/ride_hud/*.png, drawn at the RefWidth screen's size
	progress = { id = "rbxassetid://140037705020050", size = Vector2.new(646, 91) }, -- BossBar.png (QM's FILLED 2: a bar of its own, stretched to the time left)
	progressGrey = { id = "rbxassetid://90506809044433", size = Vector2.new(646, 91) }, -- BossBarEmpty.png (QM's DISABLED 1)
}
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
-- (RefWidth px, from QM's guide, Oct 10: a 1522 x 826 shot, so its height is 1042 here)
local TOP = 108 -- the bar off the top
local BAR_WIDTH = 646
local RED_FROM = 0.5 -- the seconds turn from white to red from this much time left down to none (QM)
local RED = Color3.fromRGB(255, 60, 80)
-- Under From left, the bar's scale: in to In over InTime s, out to Out over OutTime s (QM).
local PULSE = { From = 0.5, In = 0.97, Out = 1.03, InTime = 0.5, OutTime = 0.7 }
local POP_TIME = 0.4 -- its bounce in, s
local TITLE = "BOSS IN" -- (QM, Oct 10; was "Lasso will break", "Boss will spawn")
local TITLE_Y, TITLE_TEXT = 69, 46 -- the title's middle off the top, its size
local TIME_FONT = Font.fromEnum(Enum.Font.FredokaOne) -- (the bar's not Montserrat: QM)
local TIME_TEXT = 42
local STROKE = 4

local RideUi = {}

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
if Config.NativeUi.On then
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- (the native UI's layers sit over their parents, as in Fight to Steal an Egg)
end
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
local BAR_MIDDLE = TOP + BAR_WIDTH * ART.progress.size.Y / ART.progress.size.X / 2
local bar = picture(root, ART.progressGrey, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0, BAR_MIDDLE), BAR_WIDTH) -- (from its middle: it pulses about it)
bar.Name = "Time"
local clip = Instance.new("Frame")
clip.Name = "Fill"
clip.BackgroundTransparency = 1
clip.ClipsDescendants = true
clip.Size = UDim2.fromScale(1, 1)
clip.Parent = bar
-- The fill: the filled bar over the empty one, just cut off at the time left (QM, Oct 10).
local fill = picture(clip, ART.progress, Vector2.zero, UDim2.new())
fill.Size = bar.Size -- (the bar's, whatever the cut)
local barScale = Instance.new("UIScale")
barScale.Parent = bar
-- The native UI's look (Config.NativeUi, QM Nov 6): Fight to Steal an Egg's boss bar (its red
-- over the maroon, weld studs and bevel, black outline) in place of the art, 634 x 60.
if Config.NativeUi.On then
	local HudKit = require(script.Parent.HudKit)
	bar.Image, fill.Image = "", ""
	bar.Size = UDim2.fromOffset(634, 60)
	fill.Size = bar.Size
	BAR_WIDTH = 634
	HudKit.back(bar, "BossEmpty", { Name = "NativeBack", ZIndex = 1 })
	clip.ZIndex = 2
	HudKit.back(fill, "BossRed", { Name = "NativeFill", ZIndex = 2 })
end
-- (on its own over the bar's middle, so it doesn't pulse with it)
local seconds = text(root, TIME_TEXT)
seconds.FontFace = TIME_FONT
seconds.UIStroke:Destroy() -- (plain white: QM's guide)
seconds.Name = "Seconds"
seconds.Position = UDim2.new(0.5, 0, 0, BAR_MIDDLE)
seconds.ZIndex = 2
local titleScale, secondsScale = Instance.new("UIScale"), Instance.new("UIScale")
titleScale.Parent, secondsScale.Parent = title, seconds

-- The Auto Lasso toggle, bottom left (QM's Figma, page AutoLasso, frame Toggle, Nov 8). Off:
-- the red knob on the left of the dark track; on: it slides right and turns green. Where the
-- base HUD's cash row is (NativeHud, hidden while riding), at its scale (QM, Nov 8): the
-- switch as tall as the cash icon, the label the cash number's size. Laid out in NativeHud's
-- design px; the switch's Figma px go through k so its 94 is SWITCH_H.
RideUi.autoLasso = false
do
	local HudKit = require(script.Parent.HudKit)
	local NativeHud = require(script.Parent.NativeHud)
	local fig = HudKit.fig
	local SWITCH_H = fig(120) -- (the cash icon's art, inside its 160 box)
	local k = SWITCH_H / 94
	local function px(n)
		return math.max(math.round(n * k), 1)
	end
	-- its own root at NativeHud's scale (the bar's root is RefWidth px)
	local hudRoot = Instance.new("Frame")
	hudRoot.Name = "HudRoot"
	hudRoot.BackgroundTransparency = 1
	hudRoot.Parent = gui
	local fit = Instance.new("UIScale")
	fit.Parent = hudRoot
	local function refit()
		local h = gui.AbsoluteSize.Y
		if h < 1 then
			h = workspace.CurrentCamera.ViewportSize.Y
		end
		fit.Scale = NativeHud.scaleFor(h)
		hudRoot.Size = UDim2.fromScale(1 / fit.Scale, 1 / fit.Scale)
	end
	refit()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	local function gradient(parent, top, bottom, alphaTop, alphaBottom)
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(0.159, top),
			ColorSequenceKeypoint.new(1, bottom),
		})
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, alphaTop),
			NumberSequenceKeypoint.new(0.159, alphaTop),
			NumberSequenceKeypoint.new(1, alphaBottom),
		})
		g.Parent = parent
		return g
	end
	-- (Figma's inner shadows: a light band top and left, a shade band bottom and right)
	local function bevel(parent, light, shade)
		local w = px(8)
		for _, e in {
			{ Color3.new(1, 1, 1), light, UDim2.new(), UDim2.new(1, 0, 0, w) },
			{ Color3.new(1, 1, 1), light, UDim2.fromOffset(0, w), UDim2.new(0, w, 1, -w) },
			{ Color3.new(0, 0, 0), shade, UDim2.new(0, w, 1, -w), UDim2.new(1, -w, 0, w) },
			{ Color3.new(0, 0, 0), shade, UDim2.new(1, -w, 0, w), UDim2.new(0, w, 1, -2 * w) },
		} do
			local strip = Instance.new("Frame")
			strip.BorderSizePixel = 0
			strip.BackgroundColor3 = e[1]
			strip.BackgroundTransparency = e[2]
			strip.Position, strip.Size = e[3], e[4]
			strip.Parent = parent
		end
	end
	local function box(parent, outlineColor)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, px(5))
		corner.Parent = f
		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.Color = outlineColor
		outline.Thickness = px(8)
		outline.Parent = f
		f.Parent = parent
		return f, outline
	end

	local toggle = Instance.new("TextButton")
	toggle.Name = "AutoLasso"
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.BackgroundTransparency = 1
	-- (the cash row's: bottom 81 up, 160 tall, the icon 11 in; the switch centred on it)
	toggle.AnchorPoint = Vector2.new(0, 0.5)
	toggle.Position = UDim2.new(0, fig(11), 1, -fig(81) - fig(80))
	toggle.Size = UDim2.fromOffset(px(238) + fig(24) + fig(300), px(94))
	toggle.Parent = hudRoot

	-- the track: black at 50% fading to 40%, black outline
	local track = box(toggle, Color3.new(0, 0, 0))
	track.Name = "Track"
	track.Size = UDim2.fromOffset(px(238), px(94))
	track.BackgroundColor3 = Color3.new(0, 0, 0)
	gradient(track, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0.5, 0.6)
	bevel(track, 0.9, 0.75)

	-- the knob: 72 px, 11 in from the track's edges
	local INSET, KNOB = 11, 72
	local knob, knobOutline = box(track, Color3.fromHex("651513"))
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(px(KNOB), px(KNOB))
	local fill = gradient(knob, Color3.fromHex("ff0000"), Color3.fromHex("d90000"), 0, 0)
	bevel(knob, 0.75, 0.75)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextSize = fig(60) -- (the cash number's: HudKit.label)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "Auto Lasso"
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, px(238) + fig(24), 0.5, 0)
	label.Size = UDim2.fromOffset(fig(300), fig(72))
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = STROKE
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = toggle

	local SLIDE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function paint(animate)
		local on = RideUi.autoLasso
		local to = UDim2.fromOffset(px(if on then 238 - INSET - KNOB else INSET), px(INSET))
		if animate then
			game:GetService("TweenService"):Create(knob, SLIDE, { Position = to }):Play()
		else
			knob.Position = to
		end
		local top, bottom = Color3.fromHex(if on then "0aff00" else "ff0000"), Color3.fromHex(if on then "00c800" else "d90000")
		fill.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(0.159, top),
			ColorSequenceKeypoint.new(1, bottom),
		})
		knobOutline.Color = Color3.fromHex(if on then "136515" else "651513")
	end
	paint(false)
	toggle.Activated:Connect(function()
		RideUi.autoLasso = not RideUi.autoLasso
		paint(true)
	end)
end

-- Back out (overshoots a little, then settles), 0..1 over 0..1.
local function backOut(x)
	local c = 1.70158
	return 1 + (c + 1) * (x - 1) ^ 3 + c * (x - 1) ^ 2
end
local shownAt -- when the bar last came up (nil: hidden)

function RideUi.show(visible)
	gui.Enabled = visible
end

function RideUi.setHold(fraction, _tired, total)
	bar.Visible = fraction ~= nil
	title.Visible = fraction ~= nil
	seconds.Visible = fraction ~= nil
	if not fraction then
		shownAt = nil
	elseif not shownAt then
		shownAt = os.clock()
	end
	if fraction then
		local pop = backOut(math.min((os.clock() - shownAt) / POP_TIME, 1))
		titleScale.Scale, secondsScale.Scale = pop, pop
		local f = math.clamp(fraction, 0, 1)
		clip.Size = UDim2.new(0, BAR_WIDTH * f, 1, 0)
		seconds.TextColor3 = RED:Lerp(Color3.new(1, 1, 1), math.clamp(f / RED_FROM, 0, 1))
		seconds.Text = string.format("%.1fs", f * (total or Config.RideSeconds)) -- (total: the bar's length in seconds, if not a ride's)
		local t = os.clock() % (PULSE.InTime + PULSE.OutTime)
		local k = if t < PULSE.InTime then 1 - t / PULSE.InTime else (t - PULSE.InTime) / PULSE.OutTime -- (1 = out, 0 = in)
		k = 0.5 - math.cos(k * math.pi) / 2 -- (eased)
		barScale.Scale = pop * (if f < PULSE.From then PULSE.In + (PULSE.Out - PULSE.In) * k else 1)
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
