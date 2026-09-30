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
	gold = { id = "rbxassetid://75090734827129", size = Vector2.new(262, 263) },
	eggs = { id = "rbxassetid://76827079745406", size = Vector2.new(264, 277) },
	coin = { id = "rbxassetid://99312860837685", size = Vector2.new(256, 256) },
	-- TAKE EGG for rarer eggs (takeEgg itself is the Uncommon one).
	takeEggRare = { id = "rbxassetid://137561422342054", size = Vector2.new(960, 434) },
	takeEggEpic = { id = "rbxassetid://114155984376753", size = Vector2.new(960, 434) },
	takeEggLegendary = { id = "rbxassetid://93889609154413", size = Vector2.new(960, 434) },
	sprint = { id = "rbxassetid://104509002348710", size = Vector2.new(618, 524) },
	-- Egg reveal cards (assets/ui). TODO(Mac session): upload and fill in the ids.
	-- cardLeft is where the card's rounded body starts in the image (the rarity
	-- cards' banners stick out past it); the body is 975 x 1175 from y = 12 in all.
	unknownEgg = { id = "", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg.png, 1/10
	unknownEgg1 = { id = "", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg1.png, 1/100
	unknownEgg2 = { id = "", size = Vector2.new(1000, 1223), cardLeft = 12 }, -- UnknownEgg2.png, 1/1000
	cardUncommon = { id = "", size = Vector2.new(1229, 1223), cardLeft = 127 }, -- UncommonEggRNG.png
	cardRare = { id = "", size = Vector2.new(1134, 1217), cardLeft = 82 }, -- RareEggRNG.png
	cardEpic = { id = "", size = Vector2.new(1244, 1227), cardLeft = 154 }, -- EpicEggRNG.png
	cardLegendary = { id = "", size = Vector2.new(1171, 1227), cardLeft = 90 }, -- LegendaryEggRNG.png
	-- Egg renders for the card, cropped to the egg (assets/ui/<Kind>EggRender.png).
	eggPinto = { id = "", size = Vector2.new(496, 788) }, -- PintoEggRender.png
}

local BUTTON_WIDTH = 256
local SPRINT_WIDTH = 164 -- about 2/3 of TAKE EGG's width, as in the mockup
local BAR_WIDTH = 352
local ICON_HEIGHT = 80 -- Gold
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

local card, cardFace, cardEgg, cardScale -- egg reveal card, its image, the egg on it, and its UIScale
local reveal = 0 -- bumped to stop a running reveal
local sprint, sprintInput -- the Sprint button, and the touch or click holding it down
local gui, homeGui, rideRoot, homeRoot, rootScale, holdFrame, holdClip, distance, action, message, home, banner, ride, gold, pets, eggs, rideCash, gained, dodge, dodgePulse, vignette, sunburst, actionScale

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
local function setCash(amount)
	rideAmount = amount
	rideCash.text.Text = amount .. "$"
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
	cardFace = image(card, "unknownEgg", UDim2.new(), UDim2.new())
	cardFace.AnchorPoint = Vector2.zero
	cardFace.ZIndex = 3
	cardEgg = image(card, "eggPinto", UDim2.new(), UDim2.fromScale(0.5, 0.5))
	cardEgg.ZIndex = 4
	Instance.new("UIScale").Parent = cardEgg
	card.Parent = rideRoot

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
	gold = button(homeRoot, "gold", fit("gold", nil, ICON_HEIGHT), Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN))
	local eggsSize = fit("eggs", nil, SIDE_ICON_HEIGHT)
	eggs = button(homeRoot, "eggs", eggsSize, Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN))
	pets = button(homeRoot, "pets", fit("pets", nil, SIDE_ICON_HEIGHT), Vector2.new(1, 1), UDim2.new(1, -MARGIN, 1, -MARGIN - eggsSize.Y.Offset - 8))

	-- Load every image now, so the first BUCKED OFF isn't still downloading while it animates.
	task.spawn(function()
		local ids = {}
		for _, entry in IMAGES do
			if entry.id ~= "" then -- not uploaded yet
				table.insert(ids, entry.id)
			end
		end
		game:GetService("ContentProvider"):PreloadAsync(ids)
	end)
end

function Hud.show(visible)
	gui.Enabled = visible
	reveal += 1
	card.Visible = false
	if not visible then
		message.Text = ""
		banner.Visible = false
		home.Visible = false
	end
	ride.Visible = false -- comes back when the ride prompt shows again
	gold.Visible = not visible
	pets.Visible = not visible
	eggs.Visible = not visible
	gained.row.Visible = false
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
	local entry = IMAGES[key]
	cardFace.Image = entry.id
	cardFace.Size = UDim2.fromOffset(entry.size.X * CARD_SCALE, entry.size.Y * CARD_SCALE)
	cardFace.Position = UDim2.fromOffset(-entry.cardLeft * CARD_SCALE, -CARD_TOP * CARD_SCALE)
end

-- Back home with an egg: a gacha-style card pops up, flicks through the unknown
-- eggs, slowing down, then lands on the egg's rarity card and the egg pops in.
-- Returns how long it takes until the card is gone (nil if there's no card for
-- that rarity, e.g. Common).
function Hud.eggReveal(rarity, kind)
	local final = RARITY_CARDS[rarity]
	if not final then
		return nil
	end
	reveal += 1
	local token = reveal
	local flicks = Config.EggRevealFlicks
	local first, last = Config.EggRevealFirstGap, Config.EggRevealLastGap
	local gaps, spin = {}, 0
	for i = 1, flicks do
		-- Each gap a constant factor longer than the one before: fast, then slowing.
		gaps[i] = first * (last / first) ^ ((i - 1) / math.max(flicks - 1, 1))
		spin += gaps[i]
	end

	setCardFace(UNKNOWN_CARDS[1])
	cardEgg.Visible = false
	card.Rotation = 0
	card.Visible = true
	cardScale.Scale = 0
	TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	task.spawn(function()
		for i = 1, flicks do
			task.wait(gaps[i])
			if reveal ~= token then
				return
			end
			if i < flicks then
				setCardFace(UNKNOWN_CARDS[i % #UNKNOWN_CARDS + 1])
				-- A little tick on every flick.
				cardScale.Scale = 1.06
				TweenService:Create(cardScale, TweenInfo.new(0.1), { Scale = 1 }):Play()
			end
		end
		-- The real card lands: punch, wobble and shake, then the egg pops in.
		setCardFace(final)
		cardScale.Scale = 1.3
		card.Rotation = -5
		TweenService:Create(cardScale, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
		TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		local egg = IMAGES["egg" .. tostring(kind)] or IMAGES.eggPinto
		local eggHeight = CARD_BODY.Y * CARD_SCALE * CARD_EGG_HEIGHT
		cardEgg.Image = egg.id
		cardEgg.Size = UDim2.fromOffset(eggHeight * egg.size.X / egg.size.Y, eggHeight)
		cardEgg.Visible = true
		cardEgg.UIScale.Scale = 0
		TweenService:Create(cardEgg.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local rest = UDim2.fromScale(0.5, 0.53)
		for i = 10, 1, -1 do
			card.Position = rest + UDim2.fromOffset(math.random(-i, i), math.random(-i, i))
			task.wait(0.03)
		end
		card.Position = rest
		task.wait(Config.EggRevealHold - 0.3)
		if reveal ~= token then
			return
		end
		TweenService:Create(cardScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
	end)
	return spin + Config.EggRevealHold + 0.3
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

-- Home button, shown after a failed ride with the cash gained; sends you back home.
function Hud.showHome(visible)
	home.Visible = visible
	gained.row.Visible = visible
	if visible then
		gained.text.Text = "+" .. rideAmount .. "$"
		gained.scale.Scale = 0
		TweenService:Create(gained.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
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
	popup.text.Text = "+" .. amount .. "$"
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

return Hud
