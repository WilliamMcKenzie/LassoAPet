-- The base's HUD in Fight to Steal an Egg's native style (QM, Nov 6: "instead of using PNG's
-- for the UI make it natively", World 1 first: Config.NativeUi). Its client/Hud's layout:
--   the Goal panel, top left (client/GoalPanel: your quests, one at a time);
--   the green Shop and blue Index buttons, left middle;
--   the orange Pets button (a square, the paw), right middle, and the red Eggs one under it;
--   your cash, bottom left: the cash icon on a black band fading out, the number in green
--   italics; your luck above it. Gains pop "+N" beside them (client/GainPopups).
-- BaseUi builds it in place of its own art and wires it up (clicks, cash, quests); shown
-- whenever BaseUi is. Laid out in design px (1080 tall) and scaled to the screen by the
-- Root's UIScale (Config.NativeUi.Scale). QM's Figma is 2190 tall: its numbers go through fig.
--
--   local hud = NativeHud.build() -> { gui, root, buttons = { Shop, Index, Pets, Eggs }, cash, goal }

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HudKit = require(script.Parent.HudKit)
local HudImages = require(script.Parent.HudImages)
local GoalPanel = require(script.Parent.GoalPanel)
local Ui = require(script.Parent.Ui)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local NativeHud = {}

local DESIGN_HEIGHT = 1080
local ICON_OUTLINE = 3 -- the Shop and Index icons' black outline (white art: drawn here)
local fig = HudKit.fig

-- the Root's scale on a screen h px tall
function NativeHud.scaleFor(h)
	local cfg = Config.NativeUi.Scale
	local k = (h / DESIGN_HEIGHT) ^ (cfg.Curve or 1)
	return math.clamp(k, cfg.Min or 0, cfg.Max or math.huge)
end

-- a ScreenGui with a Root scaled as the HUD's, for the popups (over the HUD, which hides
-- while one's up: BaseUi's Modal). Made once.
local popupRoot
function NativeHud.popupRoot()
	if popupRoot then
		return popupRoot
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "NativePopups"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = Ui.make(gui, "Root", "Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
	local fit = Ui.make(root, "Fit", "UIScale")
	local function resize()
		local h = gui.AbsoluteSize.Y
		if h < 1 then
			h = workspace.CurrentCamera.ViewportSize.Y
		end
		fit.Scale = NativeHud.scaleFor(h)
		root.Size = UDim2.fromScale(1 / fit.Scale, 1 / fit.Scale)
	end
	resize()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	popupRoot = root
	return root
end

-- the world behind a popup hazy, like frosted glass (QM: popups use glass blur), while any
-- of `who` holds it
local haze, hazeTint
local hazing = {}
function NativeHud.haze(who, on)
	do
		return -- (QM, Nov 6: no glass blur behind popups any more)
	end
	local camera = workspace.CurrentCamera
	if not haze then
		haze = Instance.new("BlurEffect")
		haze.Name = "NativeHaze"
		haze.Size = 0
		hazeTint = Instance.new("ColorCorrectionEffect")
		hazeTint.Name = "NativeHaze"
	end
	haze.Parent, hazeTint.Parent = camera, camera
	hazing[who] = on or nil
	local k = if next(hazing) then 1 else 0
	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(haze, info, { Size = 14 * k }):Play()
	TweenService:Create(hazeTint, info, { Brightness = 0.06 * k, Contrast = -0.15 * k, Saturation = -0.35 * k }):Play()
end

function NativeHud.build(handlers)
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "NativeHud"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	-- everything inside the root is in design px; its UIScale fits it to the screen
	local root = Ui.make(gui, "Root", "Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
	local fit = Ui.make(root, "Fit", "UIScale")
	local function resize()
		local h = gui.AbsoluteSize.Y
		if h < 1 then
			h = workspace.CurrentCamera.ViewportSize.Y
		end
		fit.Scale = NativeHud.scaleFor(h)
		-- (scaled down, so made bigger by the same factor to fill the screen)
		root.Size = UDim2.fromScale(1 / fit.Scale, 1 / fit.Scale)
	end
	resize()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)

	local art, label, button = HudKit.art, HudKit.label, HudKit.button
	local buttons = {}

	-- Shop and Index, left middle: 384 x 128, the icon (88) 49 in, the name 174 in. Their
	-- white icons sit on black copies of themselves nudged ICON_OUTLINE px out all round
	for i, name in { "Shop", "Index" } do
		local b = button(root, name .. "Button", 384, 128, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, fig(30), 0.5, (i - 1) * fig(172)),
		}, if name == "Shop" then "Green" else "Blue")
		local holder = Ui.make(b, name .. "Icon", "Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, fig(49), 0.5, 0),
			Size = UDim2.fromOffset(fig(88), fig(88)),
			ZIndex = 2,
		})
		art(holder, name .. "Icon", { Size = UDim2.fromScale(1, 1), ZIndex = 2 })
		for k = 1, 8 do
			local a = (k - 1) * math.pi / 4
			art(holder, "Outline" .. k, {
				Image = HudImages[name .. "Icon"] or "",
				ImageColor3 = HudKit.BLACK,
				Position = UDim2.fromOffset(math.round(math.cos(a) * ICON_OUTLINE), math.round(math.sin(a) * ICON_OUTLINE)),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 1,
			})
		end
		label(b, "Label", {
			Text = name,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, fig(174), 0.5, 0),
			Size = UDim2.fromOffset(fig(190), fig(73)),
			ZIndex = 2,
		})
		buttons[name] = b
	end

	-- Pets, right middle: a 128 square, the paw (96) in it
	local pets = button(root, "PetsButton", 128, 128, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -fig(30), 0.5, 0),
	}, "Orange")
	art(pets, "PetsIcon", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(fig(96), fig(96)),
		ZIndex = 2,
	})
	buttons.Pets = pets

	-- Eggs, under Pets (QM, Nov 6): the red square, the egg (96) in it (client/NativeEggs)
	local eggs = button(root, "EggsButton", 128, 128, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -fig(30), 0.5, fig(163)),
	}, "Red")
	art(eggs, "EggsIcon", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(fig(96), fig(96)),
		ZIndex = 2,
	})
	buttons.Eggs = eggs

	-- cash, bottom left: a 160 icon on a black band fading out to the right, the number in
	-- green italics
	local row = Ui.make(root, "Cash", "Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -fig(81)),
		Size = UDim2.fromOffset(fig(411), fig(160)),
	})
	local band = Ui.make(row, "Band", "Frame", {
		BackgroundColor3 = HudKit.BLACK,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, fig(44)),
		Size = UDim2.new(1, 0, 0, fig(72)),
	})
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.54, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = band
	art(row, "CashIcon", {
		Position = UDim2.fromOffset(fig(11), 0),
		Size = UDim2.fromOffset(fig(160), fig(160)),
		ZIndex = 2,
	})
	local cash = label(row, "Value", {
		Text = "0",
		FontFace = HudKit.ITALIC,
		TextColor3 = Color3.fromRGB(0, 255, 0),
		Position = UDim2.fromOffset(fig(185), fig(44)),
		Size = UDim2.fromOffset(fig(230), fig(72)),
		ZIndex = 3,
	})
	-- (each gain pops "+N" right of the number and bounces the icon: client/GainPopups, QM Nov 7)
	local GainPopups = require(script.Parent.GainPopups)
	GainPopups.init(row, "Cash", cash, Color3.fromRGB(0, 255, 0), 44, {
		attribute = "Gold",
		text = function(amount) -- (Hud's money, no "$": as the counter; required here, Hud needs us)
			return (require(script.Parent.Hud).money(amount):gsub("%$", ""))
		end,
	})

	-- luck, just above cash (QM, Nov 7: where Fight to Steal an Egg's Power is: its row, 256 up,
	-- band 66, the number at 177, white): the clover, "x1". Tap it for the rebirth popup.
	local luckRow = Ui.make(root, "Luck", "Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -fig(256)),
		Size = UDim2.fromOffset(fig(411), fig(160)),
	})
	local luckBand = Ui.make(luckRow, "Band", "Frame", {
		BackgroundColor3 = HudKit.BLACK,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, fig(66)),
		Size = UDim2.new(1, 0, 0, fig(72)),
	})
	local luckFade = Instance.new("UIGradient")
	luckFade.Transparency = fade.Transparency
	luckFade.Parent = luckBand
	art(luckRow, "LuckIcon", {
		Position = UDim2.fromOffset(fig(11), 0),
		Size = UDim2.fromOffset(fig(160), fig(160)),
		ZIndex = 2,
	})
	local luck = label(luckRow, "Value", {
		Text = "x1",
		FontFace = HudKit.ITALIC,
		TextColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(fig(177), fig(66)),
		Size = UDim2.fromOffset(fig(230), fig(72)),
		ZIndex = 3,
	})
	local luckButton = Ui.make(luckRow, "Tap", "TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
	})
	GainPopups.init(luckRow, "Luck", luck, Color3.new(1, 1, 1), 66, {
		attribute = "LuckBonus",
		min = 0.01, -- (luck comes in quarters)
		text = function(amount)
			return (string.format("%.2f", amount):gsub("%.?0+$", ""))
		end,
	})
	-- the 100x Luck Event (Config.LuckEvent, QM Nov 7): while it's on the number's the boosted
	-- luck in rolling rainbow, the time left beside it
	local luckRainbow = Instance.new("UIGradient")
	luckRainbow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 160, 50)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 235, 70)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 220, 90)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 70)),
	})
	luckRainbow.Enabled = false
	luckRainbow.Parent = luck
	local luckTimer = label(luckRow, "EventTimer", {
		Text = "",
		FontFace = HudKit.ITALIC,
		Visible = false,
		Position = UDim2.new(1, fig(14), 0, fig(66)),
		Size = UDim2.fromOffset(fig(170), fig(72)),
		ZIndex = 3,
	})
	local luckShown
	local function showLuck()
		local text = Config.luckText(Config.luck(player))
		if text ~= luckShown then
			luckShown = text
			luck.Text = text
		end
	end
	player:GetAttributeChangedSignal("LuckBonus"):Connect(showLuck)
	showLuck()
	game:GetService("RunService").Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		local left = Config.luckEventLeft(now)
		showLuck()
		luckRainbow.Enabled = left ~= nil
		luckTimer.Visible = left ~= nil
		if left then
			local s = math.ceil(left)
			luckTimer.Text = string.format("%d:%02d", s // 60, s % 60)
			luckRainbow.Offset = Vector2.new((now * 0.6) % 2 - 1, 0) -- (rolls along)
		end
	end)
	luckButton.Activated:Connect(function()
		require(script.Parent.RebirthPopup).open()
	end)

	local goal = GoalPanel.init(root, handlers)
	return { gui = gui, root = root, buttons = buttons, cash = cash, luck = luck, goal = goal }
end

return NativeHud
