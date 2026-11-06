-- The base's HUD in Fight to Steal an Egg's native style (QM, Nov 6: "instead of using PNG's
-- for the UI make it natively", World 1 first: Config.NativeUi). Its client/Hud's layout:
--   the Goal panel, top left (client/GoalPanel: your quests, one at a time);
--   the green Shop and blue Index buttons, left middle;
--   the orange Pets button (a square, the paw), right middle, and the red Eggs one under it;
--   your cash, bottom left: the cash icon on a black band fading out, the number in green
--   italics.
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
		Position = UDim2.new(0, 0, 1, -fig(256)), -- (up in Fight to Steal an Egg's Power spot: QM, Nov 6)
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

	local goal = GoalPanel.init(root, handlers)
	return { gui = gui, root = root, buttons = buttons, cash = cash, goal = goal }
end

return NativeHud
