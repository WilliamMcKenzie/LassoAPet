-- Riding HUD built from QM's images: the Hold bar with the distance on it, one
-- action button (TAKE EGG or LASSO), a center message, and the home buttons
-- (RIDE, Gold, Pets, Upgrade Pen). Layout follows QM's mockups.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Inventory = require(script.Parent.Inventory)
local PetsPanel = require(script.Parent.PetsPanel)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Hud = {}

local FONT = Enum.Font.FredokaOne
local STROKE = 6
local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 72, 72)

-- Uploaded from QM's ui_assets; size is each image's native pixel size.
local IMAGES = {
	takeEgg = { id = "rbxassetid://104292931687556", size = Vector2.new(960, 434) },
	lasso = { id = "rbxassetid://94121512214531", size = Vector2.new(960, 358) },
	lassoDisabled = { id = "rbxassetid://83416502851504", size = Vector2.new(960, 358) },
	ride = { id = "rbxassetid://108897443176698", size = Vector2.new(960, 308) },
	home = { id = "rbxassetid://91332218189700", size = Vector2.new(960, 364) },
	dodge = { id = "rbxassetid://96827860827213", size = Vector2.new(1423, 115) },
	sunburst = { id = "rbxassetid://130261551778736", size = Vector2.new(1995, 1996) }, -- white rays, behind TAKE EGG
	vignette = { id = "rbxassetid://102545209742676", size = Vector2.new(512, 512) }, -- white; clear to 60% out, full only in the corners
	buckedOff = { id = "rbxassetid://114839635512682", size = Vector2.new(1015, 300) },
	crash = { id = "rbxassetid://137889269113133", size = Vector2.new(632, 230) },
	barFilled = { id = "rbxassetid://82401653732533", size = Vector2.new(1292, 220) },
	barEmpty = { id = "rbxassetid://128272625286546", size = Vector2.new(1292, 220) },
	pets = { id = "rbxassetid://90844952883979", size = Vector2.new(254, 256) },
	eggs = { id = "rbxassetid://76827079745406", size = Vector2.new(264, 277) },
	coin = { id = "rbxassetid://99312860837685", size = Vector2.new(256, 256) },
	upgradePen = { id = "rbxassetid://120690804030353", size = Vector2.new(1152, 284) }, -- UpgradePenActive.png
	upgradePenDisabled = { id = "rbxassetid://134427342737800", size = Vector2.new(1158, 285) }, -- UpgradePenDisabled.png
	-- TAKE EGG for rarer eggs (takeEgg itself is the Uncommon one).
	takeEggRare = { id = "rbxassetid://137561422342054", size = Vector2.new(960, 434) },
	takeEggEpic = { id = "rbxassetid://114155984376753", size = Vector2.new(960, 434) },
	takeEggLegendary = { id = "rbxassetid://93889609154413", size = Vector2.new(960, 434) },
	sprint = { id = "rbxassetid://104509002348710", size = Vector2.new(618, 524) },
	ability = { id = "rbxassetid://95632395593874", size = Vector2.new(618, 524) }, -- Ability.png
	abilityCooldown = { id = "rbxassetid://86071723052223", size = Vector2.new(618, 524) }, -- AbilityCooldown.png
	-- Egg reveal cards (assets/ui).
	-- cardLeft is where the card's rounded body starts in the image (the rarity
	-- cards' banners stick out past it); the body is 975 x 1175 from y = 12 in all.
	unknownEgg = { id = "rbxassetid://77096507947185", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg.png, 1/10
	unknownEgg1 = { id = "rbxassetid://113381581343322", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg1.png, 1/100
	unknownEgg2 = { id = "rbxassetid://111066508903972", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg2.png, 1/1000
	cardUncommon = { id = "rbxassetid://73673910929091", size = Vector2.new(1229, 1223), cardLeft = 127 }, -- UncommonEggRNG.png
	cardRare = { id = "rbxassetid://112042125080788", size = Vector2.new(1134, 1217), cardLeft = 82 }, -- RareEggRNG.png
	cardEpic = { id = "rbxassetid://94491197892789", size = Vector2.new(1244, 1227), cardLeft = 154 }, -- EpicEggRNG.png
	cardLegendary = { id = "rbxassetid://124659626997084", size = Vector2.new(1171, 1227), cardLeft = 90 }, -- LegendaryEggRNG.png
	-- Egg renders for the card, cropped to the egg (assets/ui/<Kind>EggRender.png).
	eggPinto = { id = "rbxassetid://79525419811481", size = Vector2.new(496, 788) }, -- PintoEggRender.png
	eggPig = { id = "rbxassetid://139970505549400", size = Vector2.new(496, 730) }, -- PigEggRender.png
	eggFish = { id = "rbxassetid://105098230793344", size = Vector2.new(586, 810) }, -- FishEggRender.png
	eggRhino = { id = "rbxassetid://139482781062355", size = Vector2.new(496, 735) }, -- RhinoEggRender.png
	eggUnicorn = { id = "rbxassetid://85066893166855", size = Vector2.new(496, 859) }, -- UnicornEggRender.png
	eggCactus = { id = "rbxassetid://95599437590618", size = Vector2.new(635, 766) }, -- CactusEggRender.png
	eggScorpion = { id = "rbxassetid://138046936786400", size = Vector2.new(599, 770) }, -- ScorpionEggRender.png
	eggSandworm = { id = "rbxassetid://96884572036784", size = Vector2.new(502, 765) }, -- SandwormEggRender.png
	eggSnake = { id = "rbxassetid://71071272639782", size = Vector2.new(502, 807) }, -- SnakeEggRender.png
	eggPenguin = { id = "rbxassetid://135143840112034", size = Vector2.new(582, 709) }, -- PenguinEggRender.png
	eggSnowman = { id = "rbxassetid://105231134861157", size = Vector2.new(675, 772) }, -- SnowmanEggRender.png
	eggPolarBear = { id = "rbxassetid://123542177444935", size = Vector2.new(603, 728) }, -- PolarBearEggRender.png
	eggIceWyvern = { id = "rbxassetid://89731193669575", size = Vector2.new(650, 855) }, -- IceWyvernEggRender.png
	eggSpineLizard = { id = "rbxassetid://98567631088826", size = Vector2.new(502, 934) }, -- SpineLizardEggRender.png
	eggBoar = { id = "rbxassetid://121234341393694", size = Vector2.new(502, 751) }, -- BoarEggRender.png
	eggWhiteWolf = { id = "rbxassetid://134686819748938", size = Vector2.new(502, 749) }, -- WhiteWolfEggRender.png
	eggTroll = { id = "rbxassetid://111845214220812", size = Vector2.new(522, 714) }, -- TrollEggRender.png
	eggIceGolem = { id = "rbxassetid://102264545247873", size = Vector2.new(502, 866) }, -- IceGolemEggRender.png
	eggIceDrake = { id = "rbxassetid://97792373754275", size = Vector2.new(502, 807) }, -- IceDrakeEggRender.png
	eggIcebringer = { id = "rbxassetid://108999142038756", size = Vector2.new(502, 774) }, -- IcebringerEggRender.png
}

local BUTTON_WIDTH = 256
local SPRINT_WIDTH = 164 -- about 2/3 of TAKE EGG's width, as in the mockup
local BAR_WIDTH = 352
local ICON_HEIGHT = 80 -- Gold
local UPGRADE_WIDTH = 300 -- Upgrade Pen, top right
local SIDE_ICON_HEIGHT = 80 -- Pets and Eggs, a little smaller in the mockup
local MARGIN = 24
local REFERENCE_WIDTH = 1320 -- screen width the sizes above are drawn for

-- Action text from the ride -> which image the action button shows.
local ACTIONS = { ["GRAB EGG"] = "takeEgg", LASSO = "lasso" }
-- The TAKE EGG image by the egg's rarity; anything else uses takeEgg (Uncommon).
local EGG_BUTTONS = { Rare = "takeEggRare", Epic = "takeEggEpic", Legendary = "takeEggLegendary" }

-- Banners drawn as images instead of text.
local BANNERS = { ["BUCKED OFF"] = "buckedOff", ["CRASH!"] = "crash" }
local BANNER_SCALE = 0.55 -- banner images show at this share of their pixel size

-- Egg reveal card, sized and placed as in QM's reference screenshot: the card's
-- body is 22% of the screen's width, centred a little below the middle, and the
-- egg sits in the card's centre at 37% of its height.
local CARD_BODY = Vector2.new(975, 1175) -- the rounded body, in image pixels
local CARD_TOP = 12 -- body's top edge in every card image
local CARD_WIDTH = 296
local CARD_SCALE = CARD_WIDTH / CARD_BODY.X
local CARD_EGG_HEIGHT = 0.37
local UNKNOWN_CARDS = { "unknownEgg", "unknownEgg1", "unknownEgg2" }
local RARITY_CARDS = { Uncommon = "cardUncommon", Rare = "cardRare", Epic = "cardEpic", Legendary = "cardLegendary" }

-- Banner colors: bad news red, good news yellow, anything else white.
local TONES = {
	["CRASH!"] = RED,
	["BUCKED OFF"] = RED,
	["TOO FAR!"] = RED,
}

local card, cardEgg, cardScale, cardFlash, cardBurst -- egg reveal card, the egg on it, its UIScale, the white flash and sunburst behind it
local cardFaces, cardShown = {}, nil -- one stacked image per card, and the one showing
local reveal = 0 -- bumped to stop a running reveal
local sprint, sprintInput -- the Sprint button, and the touch or click holding it down
local ability, abilityPressed, abilityFill, abilityTime -- the Ability button, a press not yet used, the ready part and the countdown
local gui, homeGui, rideRoot, homeRoot, rootScale, holdFrame, holdClip, distance, action, message, home, banner, ride, gold, pets, upgrade, upgradeShown, rideCash, gained, dodge, dodgePulse, vignette, abilityTint, sunburst, actionScale

-- Money as "$950", "$1.2k", "$104k", "$3.5M", "$2B": from 1000 up, a suffix
-- with at most one decimal (and none from 100 of a unit up).
local SUFFIXES = { "k", "M", "B", "T", "Qa", "Qi" }
local function money(amount)
	amount = math.floor(amount)
	local sign = if amount < 0 then "-" else ""
	local n, suffix = math.abs(amount), ""
	for _, s in SUFFIXES do
		if n < 1000 then
			break
		end
		n /= 1000
		suffix = s
	end
	if suffix == "" then
		return sign .. "$" .. n
	end
	-- Round down, so 999,999 reads $999k rather than $1000k.
	local text = if n >= 100 then tostring(math.floor(n)) else (string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", ""))
	return sign .. "$" .. text .. suffix
end

-- Text outlines, kept at a whole number of screen pixels. The HUD's UIScale scales
-- them too, and at fractional widths the dot UIStroke leaves in small letter
-- holes (the 6 in "63 m") comes out oversized.
local strokes = {}
local function roundStroke(stroke)
	local scale = rootScale or 1
	stroke.Thickness = math.max(1, math.round(strokes[stroke] * scale)) / scale
end

local function label(parent, size, position, textSize, thickness)
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
	strokes[s] = thickness or STROKE
	roundStroke(s)
	s.Destroying:Connect(function()
		strokes[s] = nil
	end)
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
		for stroke in strokes do
			roundStroke(stroke)
		end
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

-- Coin with the amount beside it, the text overlapping the coin's edge
-- (QM's MoreGold look). Used for this ride's cash and for the fail screen's total.
local function cashRow(parent, coinSize, textSize, anchor, position)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.AnchorPoint = anchor
	row.Position = position
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, -coinSize * 0.2)
	layout.Parent = row
	local coin = image(row, "coin", UDim2.fromOffset(coinSize, coinSize), UDim2.new())
	coin.ZIndex = 1
	local text = label(row, UDim2.fromOffset(0, coinSize), UDim2.new(), textSize, 4)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.LayoutOrder = 1
	text.ZIndex = 3 -- the text overlaps the coin's edge, drawn on top
	local scale = Instance.new("UIScale")
	scale.Parent = row
	row.Parent = parent
	return { row = row, coin = coin, text = text, scale = scale }
end

-- The ride's cash reads "N$"; the fail screen's reads "+N$".
local rideAmount = 0
local noCash = false -- Hud.setCash(nil): this fail screen shows no cash
local function setCash(amount)
	rideAmount = amount
	rideCash.text.Text = money(amount)
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

	-- Distance, on the bar.
	distance = label(rideRoot, UDim2.fromOffset(BAR_WIDTH, barSize.Y.Offset), holdFrame.Position, 40, 4)
	distance.Name = "Distance"
	distance.ZIndex = 2

	-- Ride back: only DODGE THE STAMPEDE!, pulsing between 90% and 110%, and a red
	-- vignette that fades out over the last stretch home.
	dodge = image(rideRoot, "dodge", fit("dodge", 440), UDim2.fromScale(0.5, 0.15))
	dodge.Visible = false
	Instance.new("UIScale").Parent = dodge
	dodgePulse = TweenService:Create(dodge.UIScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 })
	vignette = image(rideRoot, "vignette", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	vignette.ImageColor3 = Config.VignetteColor
	-- A second vignette an ability tints the screen with (the Snake's blue haze).
	abilityTint = image(rideRoot, "vignette", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	abilityTint.ImageTransparency = 1
	abilityTint.Visible = false
	vignette.ZIndex = 0
	vignette.Visible = false

	message = label(rideRoot, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)
	banner = image(rideRoot, "buckedOff", fit("buckedOff", IMAGES.buckedOff.size.X * BANNER_SCALE), message.Position)
	banner.Visible = false
	Instance.new("UIScale").Parent = banner

	action, actionScale = button(rideRoot, "lasso", fit("lasso", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onAction)
	action.Name = "Action"
	action.ZIndex = 2
	-- Slowly turning sunburst behind TAKE EGG (Config.TakeEggSunburst).
	local eggHeight = fit("takeEgg", BUTTON_WIDTH).Y.Offset
	sunburst = image(rideRoot, "sunburst", UDim2.fromOffset(BUTTON_WIDTH * 1.5, BUTTON_WIDTH * 1.5), UDim2.new(0.5, 0, 1, -MARGIN - eggHeight / 2))
	sunburst.ImageTransparency = 0.25
	sunburst.Visible = false

	home = button(rideRoot, "home", fit("home", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onHome)
	home.Visible = false
	-- Sprint, bottom left: held down, not clicked. Remembers the touch or click that
	-- pressed it, so sliding a finger off the button doesn't drop the sprint.
	sprint = button(rideRoot, "sprint", fit("sprint", SPRINT_WIDTH), Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN))
	sprint.Visible = false
	sprint.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sprintInput = input
		end
	end)
	-- Ability, bottom right (only for a pet that has one): held down like Sprint.
	-- Grey while it cools down, the ready (red) picture filling in from the top
	-- with the seconds left on it.
	local abilitySize = fit("ability", SPRINT_WIDTH)
	ability = image(rideRoot, "abilityCooldown", abilitySize, UDim2.new(1, -MARGIN, 1, -MARGIN))
	ability.Name = "ability"
	ability.AnchorPoint = Vector2.new(1, 1)
	ability.Active = true
	ability.Visible = false
	abilityFill = Instance.new("Frame")
	abilityFill.BackgroundTransparency = 1
	abilityFill.ClipsDescendants = true
	abilityFill.Size = UDim2.fromScale(1, 1)
	abilityFill.Parent = ability
	local ready = image(abilityFill, "ability", abilitySize, UDim2.new())
	ready.AnchorPoint = Vector2.zero
	abilityTime = label(ability, UDim2.fromScale(1, 0.4), UDim2.fromScale(0.58, 0.55), 40, 5)
	abilityTime.ZIndex = 2
	local abilityScale = Instance.new("UIScale")
	abilityScale.Parent = ability
	ability.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			abilityPressed = true
			TweenService:Create(abilityScale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
		end
	end)
	ability.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(abilityScale, TweenInfo.new(0.08), { Scale = 1 }):Play()
		end
	end)
	-- Egg reveal card: a frame the size of the card's body, with the card image
	-- placed so its body fills the frame and the egg render on top.
	card = Instance.new("Frame")
	card.Name = "EggCard"
	card.BackgroundTransparency = 1
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.fromOffset(CARD_BODY.X * CARD_SCALE, CARD_BODY.Y * CARD_SCALE)
	card.Position = UDim2.fromScale(0.5, 0.53)
	card.ZIndex = 3
	card.Visible = false
	cardScale = Instance.new("UIScale")
	cardScale.Parent = card
	-- Every card is its own image, stacked and already loaded; a flick only swaps
	-- which one is opaque, in the same frame, so there's no blank frame or size jump.
	for _, key in { "unknownEgg", "unknownEgg1", "unknownEgg2", "cardUncommon", "cardRare", "cardEpic", "cardLegendary" } do
		local entry = IMAGES[key]
		-- Sized as a share of the card's body, so squashing the card squashes its images.
		local face = image(card, key, UDim2.fromScale(entry.size.X / CARD_BODY.X, entry.size.Y / CARD_BODY.Y), UDim2.fromScale(-entry.cardLeft / CARD_BODY.X, -CARD_TOP / CARD_BODY.Y))
		face.Name = key
		face.AnchorPoint = Vector2.zero
		face.ZIndex = 3
		face.ImageTransparency = 1
		cardFaces[key] = face
	end
	cardEgg = image(card, "eggPinto", UDim2.new(), UDim2.fromScale(0.5, 0.5))
	cardEgg.ZIndex = 4
	Instance.new("UIScale").Parent = cardEgg
	card.Parent = rideRoot
	-- Behind the card: a white flash over the screen and the sunburst, for the pop.
	cardFlash = Instance.new("Frame")
	cardFlash.Name = "EggFlash"
	cardFlash.BackgroundColor3 = WHITE
	cardFlash.BorderSizePixel = 0
	cardFlash.AnchorPoint = Vector2.new(0.5, 0.5)
	cardFlash.Position = UDim2.fromScale(0.5, 0.5)
	cardFlash.Size = UDim2.fromScale(1.2, 1.2)
	cardFlash.ZIndex = 2
	cardFlash.Visible = false
	cardFlash.Parent = rideRoot
	cardBurst = image(rideRoot, "sunburst", UDim2.fromOffset(CARD_WIDTH * 2.6, CARD_WIDTH * 2.6), card.Position)
	cardBurst.Name = "EggBurst"
	cardBurst.ZIndex = 2
	cardBurst.Visible = false
	Instance.new("UIScale").Parent = cardBurst

	gained = cashRow(rideRoot, 84, 58, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.57))
	rideCash = cashRow(rideRoot, 60, 46, Vector2.new(0, 0.5), UDim2.new(0.5, BAR_WIDTH / 2 + 8, 0, holdFrame.Position.Y.Offset))

	-- Home buttons, always on screen outside a ride; Gold stays during rides too.
	homeGui = Instance.new("ScreenGui")
	homeGui.Name = "HomeHud"
	homeGui.ResetOnSpawn = false
	homeGui.IgnoreGuiInset = true
	homeGui.Parent = playerGui
	homeRoot = root(homeGui)
	ride = button(homeRoot, "ride", fit("ride", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onRide)
	ride.Visible = false
	-- Gold: the coin with the account's total over its bottom edge, like QM's Gold mockup.
	gold = button(homeRoot, "coin", UDim2.fromOffset(ICON_HEIGHT, ICON_HEIGHT), Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN))
	local total = label(gold, UDim2.fromOffset(0, ICON_HEIGHT * 0.4), UDim2.new(0.5, 0, 1, 2), 44, 5)
	total.AnchorPoint = Vector2.new(0.5, 1)
	total.AutomaticSize = Enum.AutomaticSize.X
	total.ZIndex = 2
	local player = Players.LocalPlayer
	local function showGold()
		total.Text = money(player:GetAttribute("Gold") or 0)
	end
	player:GetAttributeChangedSignal("Gold"):Connect(showGold)
	showGold()
	-- Pets sits just over the coin, centred on it.
	pets = button(homeRoot, "pets", fit("pets", nil, SIDE_ICON_HEIGHT), Vector2.new(0.5, 1),
		UDim2.new(0, MARGIN + ICON_HEIGHT / 2, 1, -MARGIN - ICON_HEIGHT - 8), PetsPanel.open)
	Inventory.init(homeRoot)
	-- The Pets panel hides the rest of the home UI while it's open.
	PetsPanel.init({ money = money, hideHud = function(hidden)
		homeRoot.Visible = not hidden
	end })

	-- Upgrade Pen, top right: buys your pen's next level (UpgradePen). Green and
	-- throbbing when you have the gold, grey when you don't; the price overlaps the
	-- bottom of the coin drawn on its right end. Hidden once there's no next level.
	local upgradePen = game:GetService("ReplicatedStorage"):WaitForChild("UpgradePen")
	local upgradeSize = fit("upgradePen", UPGRADE_WIDTH)
	local upgradeScale
	-- Anchored at its middle so the throb grows it evenly.
	upgrade, upgradeScale = button(homeRoot, "upgradePen", upgradeSize, Vector2.new(0.5, 0.5),
		UDim2.new(1, -MARGIN - upgradeSize.X.Offset / 2, 0, MARGIN + upgradeSize.Y.Offset / 2))
	local price = label(upgrade, UDim2.fromOffset(0, 30), UDim2.fromScale(0.855, 0.66), 30, 4)
	price.AutomaticSize = Enum.AutomaticSize.X
	local cost -- gold for the next level, nil at the top level
	local function refreshUpgrade()
		local nextBiome = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
		cost = nextBiome and nextBiome.UnlockCost
		upgradeShown = cost ~= nil
		upgrade.Visible = upgradeShown and gold.Visible
		if cost then
			price.Text = money(cost)
			upgrade.Image = IMAGES[if (player:GetAttribute("Gold") or 0) >= cost then "upgradePen" else "upgradePenDisabled"].id
		end
	end
	local buying = false
	upgrade.Activated:Connect(function()
		if buying or not cost or (player:GetAttribute("Gold") or 0) < cost then
			return
		end
		buying = true
		pcall(upgradePen.InvokeServer, upgradePen)
		buying = false
	end)
	player:GetAttributeChangedSignal("Gold"):Connect(refreshUpgrade)
	player:GetAttributeChangedSignal("PenLevel"):Connect(refreshUpgrade)
	refreshUpgrade()
	-- The throb, while it's affordable (and not while it's held down).
	local pressed = false
	upgrade.MouseButton1Down:Connect(function()
		pressed = true
	end)
	for _, event in { upgrade.MouseButton1Up, upgrade.MouseLeave } do
		event:Connect(function()
			pressed = false
		end)
	end
	local throbbing = false
	RunService.RenderStepped:Connect(function()
		local affordable = cost ~= nil and (player:GetAttribute("Gold") or 0) >= cost
		if affordable and not pressed and upgrade.Visible then
			throbbing = true
			upgradeScale.Scale = 1 + 0.06 * (0.5 - 0.5 * math.cos(os.clock() * math.pi * 2 / 0.9))
		elseif throbbing and not pressed then
			throbbing = false
			upgradeScale.Scale = 1
		end
	end)

	-- Load every image now, so the first BUCKED OFF or egg RNG card isn't still
	-- downloading while it animates. Downloading alone isn't enough: Roblox only
	-- readies an image for drawing the first time it's on screen, which stalls
	-- that frame. So each image also stays drawn in the corner at 1 pixel and
	-- nearly invisible, keeping it ready for the moment it's needed.
	local warm = Instance.new("Frame")
	warm.Name = "Preload"
	warm.BackgroundTransparency = 1
	warm.Size = UDim2.fromOffset(1, 1)
	warm.Parent = homeGui
	local labels = {}
	for key, entry in IMAGES do
		if entry.id ~= "" then -- not uploaded yet
			local l = Instance.new("ImageLabel")
			l.Name = key
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromOffset(1, 1)
			l.Image = entry.id
			l.ImageTransparency = 0.99
			l.Parent = warm
			table.insert(labels, l)
		end
	end
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync(labels)
	end)
end

function Hud.show(visible)
	gui.Enabled = visible
	reveal += 1
	card.Visible = false
	cardFlash.Visible = false
	cardBurst.Visible = false
	if not visible then
		message.Text = ""
		banner.Visible = false
		home.Visible = false
	end
	ride.Visible = false -- comes back when the ride prompt shows again
	gold.Visible = not visible
	pets.Visible = not visible
	upgrade.Visible = upgradeShown and not visible
	Inventory.setVisible(not visible) -- your eggs, hidden while riding
	gained.row.Visible = false
	noCash = false
	rideCash.row.Visible = true
	Hud.setReturning(false)
	Hud.setVignette(0)
	actionScale.Scale = 1
	setCash(0)
end

-- Shows or hides the Sprint button (on the way out only).
function Hud.setSprint(visible)
	sprint.Visible = visible
	if not visible then
		sprintInput = nil
	end
end

-- The Ability button: nil hides it (the pet has no ability); otherwise ready is
-- 0..1 of the cooldown done (1 = ready) and seconds is the time left on it.
function Hud.setAbility(ready, seconds)
	ability.Visible = ready ~= nil
	if not ready then
		abilityPressed = nil
		return
	end
	abilityFill.Size = UDim2.fromScale(1, ready)
	abilityTime.Text = if ready < 1 and seconds then math.ceil(seconds) .. "s" else ""
end

-- Whether the Ability button was pressed since the last call (each press counts
-- once, however quick the tap).
function Hud.abilityPressed()
	local pressed = abilityPressed
	abilityPressed = nil
	return pressed == true
end

-- Whether the Sprint button is being held down right now.
function Hud.sprintHeld()
	if sprintInput and (sprintInput.UserInputState == Enum.UserInputState.End or sprintInput.UserInputState == Enum.UserInputState.Cancel) then
		sprintInput = nil
	end
	return sprintInput ~= nil
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

-- text = nil hides the button; ready = false shows LASSO's disabled image;
-- rarity picks TAKE EGG's colours.
function Hud.setAction(text, ready, rarity)
	action.Visible = text ~= nil
	if text then
		local key = ACTIONS[text]
		if key == "lasso" and not ready then
			key = "lassoDisabled"
		elseif key == "takeEgg" then
			key = EGG_BUTTONS[rarity] or key
		end
		action.Image = IMAGES[key].id
		action.Size = fit(key, BUTTON_WIDTH)
	end
	-- TAKE EGG pulses so it can't be missed.
	local egg = text ~= nil and ACTIONS[text] == "takeEgg"
	sunburst.Visible = egg and Config.TakeEggSunburst
	if egg then
		actionScale.Scale = 1 + 0.07 * math.sin(os.clock() * math.pi * 3)
		sunburst.Rotation = os.clock() * 25
	end
end

-- Slams a banner image in: drops from big to size fast, squashes, and shakes.
local function slam(target, key, width)
	target.Image = IMAGES[key].id
	target.Size = fit(key, width or IMAGES[key].size.X * BANNER_SCALE)
	target.Visible = true
	target.ImageTransparency = 1
	target.Rotation = -4
	local scale = target.UIScale
	scale.Scale = 3
	local rest = target.Position
	TweenService:Create(target, TweenInfo.new(0.12), { ImageTransparency = 0 }):Play()
	local drop = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
	drop.Completed:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
		TweenService:Create(target, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		task.spawn(function()
			for i = 14, 1, -1 do
				target.Position = rest + UDim2.fromOffset(math.random(-i, i) * 2, math.random(-i, i) * 2)
				task.wait(0.03)
			end
			target.Position = rest
		end)
	end)
	drop:Play()
end

function Hud.flash(text, seconds)
	-- Fail screens hide the ride's cash and the ride back's look; the Home screen shows what was gained instead.
	if TONES[text] == RED then
		rideCash.row.Visible = false
		Hud.setVignette(0)
	end
	banner.Visible = false
	if BANNERS[text] then
		message.Text = ""
		slam(banner, BANNERS[text])
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

local function setCardFace(key)
	if cardShown then
		cardFaces[cardShown].ImageTransparency = 1
	end
	cardFaces[key].ImageTransparency = 0
	cardShown = key
end

-- Damped spring from 1 toward 0: starts at 1, overshoots past 0 and settles.
-- Drives every bounce below (squash and stretch, overshoot, wobble).
local function spring(t, frequency, decay)
	return math.exp(-decay * t) * math.cos(t * frequency * math.pi * 2)
end

local CARD_REST = UDim2.fromScale(0.5, 0.53)
local ENTER_TIME = 0.5 -- drop in, land, bounce
local ANTICIPATION = 0.14 -- squash down before the pop
local EXIT_SWELL = 0.12 -- swell and squash before popping out
local EXIT_TIME = 0.42

-- Back home with an egg: a gacha-style card drops in, rolls through the unknown
-- eggs (slow, then faster and faster), squashes down and pops onto the egg's
-- rarity card, and the egg springs out onto it. Returns how long it takes until
-- the card is gone (nil if there's no card for that rarity, e.g. Common).
function Hud.eggReveal(rarity, kind)
	local final = RARITY_CARDS[rarity]
	if not final then
		return nil
	end
	reveal += 1
	local token = reveal
	local flicks = Config.EggRevealFlicks
	local first, last = Config.EggRevealFirstGap, Config.EggRevealLastGap
	local gaps, roll = {}, 0
	for i = 1, flicks do
		-- Each gap a constant factor shorter than the one before: slow, then a blur.
		gaps[i] = first * (last / first) ^ ((i - 1) / math.max(flicks - 1, 1))
		roll += gaps[i]
	end
	local hold = Config.EggRevealHold

	local baseW, baseH = CARD_BODY.X * CARD_SCALE, CARD_BODY.Y * CARD_SCALE
	local egg = IMAGES["egg" .. tostring(kind)]
	if not egg or egg.id == "" then
		egg = IMAGES.eggPinto -- until that egg's render is uploaded
	end
	local eggH = CARD_EGG_HEIGHT
	local eggW = eggH * baseH * egg.size.X / egg.size.Y / baseW

	-- Pose the card: stretch sx, sy (1 = rest), keeping its bottom edge planted
	-- when it squashes, plus a lift in pixels and a tilt.
	local function pose(sx, sy, lift, rotation)
		card.Size = UDim2.fromOffset(baseW * sx, baseH * sy)
		card.Position = CARD_REST + UDim2.fromOffset(0, baseH * (1 - sy) / 2 - lift)
		card.Rotation = rotation
	end
	local function poseEgg(scale, sx, sy, lift)
		cardEgg.UIScale.Scale = scale
		cardEgg.Size = UDim2.fromScale(eggW * sx, eggH * sy)
		cardEgg.Position = UDim2.new(0.5, 0, 0.5, -lift)
	end
	-- Runs step(t) every frame for a duration; false if the reveal was cancelled.
	local function play(duration, step)
		local t = 0
		while t < duration do
			step(t)
			t += RunService.Heartbeat:Wait()
			if reveal ~= token then
				return false
			end
		end
		step(duration)
		return true
	end

	-- The HUD preloads every image at game start; ask again for this reveal's in
	-- case the ride was quicker than the download (a no-op once they're cached).
	local ready = false
	task.spawn(function()
		local ids = { IMAGES[final].id, egg.id }
		for _, key in UNKNOWN_CARDS do
			table.insert(ids, IMAGES[key].id)
		end
		game:GetService("ContentProvider"):PreloadAsync(ids)
		ready = true
	end)
	setCardFace(UNKNOWN_CARDS[1])
	-- The egg stays visible at scale 0 so its image loads during the roll.
	cardEgg.Image = egg.id
	cardEgg.Visible = true
	poseEgg(0, 1, 1, 0)
	cardFlash.Visible = false
	cardBurst.Visible = false
	cardScale.Scale = 1
	pose(1, 1, 600, 0)
	card.Visible = true

	task.spawn(function()
		-- 1. Drop in from above, stretched by the fall, squash on landing, bounce.
		local fall = 0.2
		if not play(ENTER_TIME, function(t)
			if t < fall then
				local u = t / fall
				pose(0.88, 1.18, 600 * (1 - u * u), 0)
			else
				local d = spring(t - fall, 3.2, 7)
				pose(1 + 0.22 * d, 1 - 0.22 * d, 0, 0)
			end
		end) then
			return
		end

		-- 2. Roll: the faces flick faster and faster while the card shakes and
		-- swells with the tension. The flicks themselves are clean swaps.
		local nextFlick, flick = gaps[1], 1
		if not play(roll, function(t)
			while flick < flicks and t >= nextFlick do
				setCardFace(UNKNOWN_CARDS[flick % #UNKNOWN_CARDS + 1])
				flick += 1
				nextFlick += gaps[flick]
			end
			local u = t / roll
			local tension = u * u
			cardScale.Scale = 1 + 0.08 * tension
			pose(1, 1, 0, math.sin(t * 55) * 4 * tension)
		end) then
			return
		end

		-- Never pop onto a card or egg that hasn't downloaded (it would flash blank):
		-- keep rolling fast until both have, for at most a second. (Not IsLoaded:
		-- the rarity card is hidden until the pop, and a hidden image never reports
		-- loaded, so that always sat out the full second.)
		local waited = 0
		while waited < 1 and not ready do
			setCardFace(UNKNOWN_CARDS[flick % #UNKNOWN_CARDS + 1])
			flick += 1
			waited += RunService.Heartbeat:Wait() + RunService.Heartbeat:Wait()
			if reveal ~= token then
				return
			end
		end

		-- 3. Anticipation: squash down hard for a beat.
		if not play(ANTICIPATION, function(t)
			local u = math.sin(t / ANTICIPATION * math.pi / 2)
			cardScale.Scale = 1.08 - 0.08 * u
			pose(1 + 0.2 * u, 1 - 0.25 * u, 0, 0)
		end) then
			return
		end

		-- 4. Pop: the real card, stretched tall and big, springs back with a
		-- wobble, behind a white flash and the sunburst; the screen shakes.
		setCardFace(final)
		cardFlash.Visible = true
		cardBurst.Visible = Config.EggRevealBurst
		cardEgg.Visible = true
		poseEgg(0, 1, 1, 0)
		local eggDelay = 0.12 -- the egg follows through just after the card
		play(hold, function(t)
			local d = spring(t, 2.4, 6)
			cardScale.Scale = 1 + 0.35 * d
			local shake = math.max(0, 1 - t / 0.35) * 8
			local squash = spring(t, 3.5, 7)
			pose(1 - 0.18 * squash, 1 + 0.22 * squash, math.random(-1, 1) * shake, -8 * spring(t, 1.8, 5))
			card.Position += UDim2.fromOffset(math.random(-1, 1) * shake, 0)
			cardFlash.BackgroundTransparency = 0.25 + 0.75 * math.min(t / 0.35, 1)
			cardBurst.UIScale.Scale = math.min(t / 0.25, 1) * (1 + 0.1 * spring(t, 2, 5))
			cardBurst.Rotation = t * 30
			-- Egg: springs out of the card stretched, squashes, then breathes.
			local e = t - eggDelay
			if e < 0 then
				poseEgg(0, 1, 1, 0)
			else
				local grow = 1 - spring(e, 2.2, 6)
				local es = spring(e, 3.8, 6)
				local breath = math.sin(e * 4) * 0.03 * math.min(e, 1)
				poseEgg(grow, 1 - 0.25 * es - breath, 1 + 0.3 * es + breath, 0)
			end
		end)
		if reveal ~= token then
			return
		end
		cardFlash.Visible = false

		-- 5. Exit, the entrance in reverse: the card swells and squashes down, then
		-- pops out, stretching tall as it shrinks away. The egg goes first, just
		-- ahead of the card, and the sunburst fades with them.
		play(EXIT_TIME, function(t)
			cardBurst.UIScale.Scale = 1 - math.min(t / (EXIT_TIME * 0.7), 1)
			cardBurst.Rotation += 1
			if t < EXIT_SWELL then
				local a = math.sin(t / EXIT_SWELL * math.pi / 2)
				cardScale.Scale = 1 + 0.08 * a
				pose(1 + 0.15 * a, 1 - 0.18 * a, 0, 0)
				poseEgg(1, 1 + 0.2 * a, 1 - 0.2 * a, 0)
				return
			end
			local v = (t - EXIT_SWELL) / (EXIT_TIME - EXIT_SWELL)
			cardScale.Scale = (1.08 + 0.2 * v) * (1 - v * v)
			pose(1 - 0.15 * v, 1 + 0.22 * v, 40 * v, 0)
			local e = math.min(v / 0.6, 1) -- the egg is gone by 60% of the way
			poseEgg(1 - e * e, 1 - 0.2 * e, 1 + 0.3 * e, 0)
		end)
		if reveal == token then
			card.Visible = false
			cardBurst.Visible = false
		end
	end)
	return ENTER_TIME + roll + ANTICIPATION + hold + EXIT_TIME
end

-- Cutscenes hide the whole ride HUD.
-- The ride HUD slides off screen for the egg close-up. It isn't disabled:
-- re-enabling a ScreenGui rebuilds all its text and images in one frame, which
-- hitched as the cutscene ended.
function Hud.setCutscene(on)
	rideRoot.Position = if on then UDim2.fromScale(0.5, 3) else UDim2.fromScale(0.5, 0.5)
end

-- RIDE shows only while you're close enough to your animal (replaces the [E] prompt).
function Hud.showRide(visible)
	ride.Visible = visible and not gui.Enabled
	Inventory.setVisible(not ride.Visible and not gui.Enabled) -- the RIDE button takes its place
end

-- Ride back home: DODGE THE STAMPEDE! slams in, then pulses; no cash or distance.
function Hud.setReturning(returning)
	dodgePulse:Cancel()
	dodge.Visible = false
	if returning then
		slam(dodge, "dodge", 440)
		task.delay(1, function()
			if dodge.Visible then
				-- Ease down to 90%, then pulse 90%..110%.
				local down = TweenService:Create(dodge.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Scale = 0.9 })
				down.Completed:Connect(function(state)
					if state == Enum.PlaybackState.Completed and dodge.Visible then
						dodgePulse:Play()
					end
				end)
				down:Play()
			end
		end)
	end
	rideCash.row.Visible = not returning
	distance.Visible = not returning
end

-- Ride back's red vignette: 1 full, 0 gone. It and DODGE THE STAMPEDE! go once it's 0.
-- It breathes slowly, in time with the text's pulse.
function Hud.setVignette(strength)
	local breath = 1 - Config.VignettePulse * (0.5 + 0.5 * math.sin(os.clock() * math.pi / 0.6))
	vignette.Visible = strength > 0
	vignette.ImageTransparency = 1 - strength * Config.VignetteOpacity * breath
	if strength <= 0 and dodge.Visible then
		dodgePulse:Cancel()
		dodge.Visible = false
	end
end

-- The ability's screen tint: 0 = none, 1 = full, in `color`.
function Hud.setAbilityTint(strength, color)
	abilityTint.Visible = strength > 0.01
	abilityTint.ImageTransparency = 1 - strength
	if color then
		abilityTint.ImageColor3 = color
	end
end

-- Home button, shown after a failed ride with the cash gained; sends you back home.
function Hud.showHome(visible)
	home.Visible = visible
	gained.row.Visible = visible and not noCash
	if visible and not noCash then
		gained.text.Text = "+" .. money(rideAmount)
		gained.scale.Scale = 0
		TweenService:Create(gained.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

-- nil: no cash at all this time (run over on foot): the ride's cash and the
-- fail screen's "+$N" stay hidden until the next ride.
function Hud.setCash(amount)
	noCash = amount == nil
	rideCash.row.Visible = not noCash
end

-- Cash gained this ride.
function Hud.setCoins(amount)
	setCash(amount)
	rideCash.scale.Scale = 1.25
	TweenService:Create(rideCash.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- "+1" with a coin that pops in at a screen point, floats up and fades.
-- Same pattern as the common DevForum coin-popup recipe: pop with Back easing, rise with Quad, fade out.
function Hud.coinPopup(screenPoint, amount)
	screenPoint /= rootScale -- screen pixels -> HUD root pixels
	-- Same coin and "+N$" as the fail screen, a bit smaller.
	local popup = cashRow(homeRoot, 64, 44, Vector2.new(0.5, 0.5), UDim2.fromOffset(screenPoint.X, screenPoint.Y))
	popup.text.Text = "+" .. money(amount)
	popup.scale.Scale = 0

	TweenService:Create(popup.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(popup.row, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y - 80),
	}):Play()
	task.delay(0.65, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(popup.text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(popup.text.UIStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(popup.coin, fade, { ImageTransparency = 1 }):Play()
	end)
	task.delay(1.05, function()
		popup.row:Destroy()
	end)
end

-- The same popup in the world: "+N$" over `part`, `height` studs above its
-- centre, following it as it moves and rising a few studs as it fades.
function Hud.coinPopupAt(part, height, amount)
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(200, 80)
	board.Adornee = part
	board.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	board.LightInfluence = 0
	board.AlwaysOnTop = true
	board.MaxDistance = 150
	board.ResetOnSpawn = false
	local popup = cashRow(board, 48, 34, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5))
	popup.text.Text = "+" .. money(amount)
	popup.scale.Scale = 0
	board.Parent = homeGui.Parent

	TweenService:Create(popup.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(board, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, height + 3, 0),
	}):Play()
	task.delay(0.65, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(popup.text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(popup.text.UIStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(popup.coin, fade, { ImageTransparency = 1 }):Play()
	end)
	task.delay(1.05, function()
		board:Destroy()
	end)
end

return Hud
