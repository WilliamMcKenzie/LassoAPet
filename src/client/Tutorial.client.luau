-- The first-time tutorial (QM, Oct 11), after the intro (Client/Intro). One thing at a
-- time: a tap hand on what to touch, arrows on the ground to where to go, QM's guide
-- bar along the top saying what to do (CAPTIONS), and only the UI each step needs (BaseUi stays hidden, the HUD is "bare": Hud.setTutorial).
--
--   1. egg    a Horse egg in your inventory: the tap hand on its square; once it's in
--             your hand, the tap hand over your pen: place it.
--   2. hatch  it's ready at once (Config.TutorialHatchTime): arrows to it, and its
--             prompt hatches it when you're by it.
--   3. ride   arrows to your Horse; its RIDE prompt when you're by it.
--   4. out    the first ride (TutorialRide, which Ride runs): no BOSS IN timer, nothing
--             crashes you, no Unicorns, no sprinting yet, and arrows to the nearest
--             animal. The moment one's in lasso reach, time slows (a sigmoid, all but
--             stopping) till you lasso it. Then, on a computer, QM's Sprint guide and
--             the same slow-down till you sprint (a phone or controller sprints by
--             pushing the stick right out). WAIT_FOR_BOSS seconds after that, BOSS IN
--             shows with BOSS_SECONDS on it: still in the Meadow, so the Chicken.
--   5. gate   home with an egg, it goes in your pen and hatches by itself (Hatchery);
--             the camera zooms to the Desert's gate (the next goal) and back. Done:
--             TutorialDone, and the rest of the UI comes back.
--
-- A ride that comes home with nothing goes back to step 3. Runs whenever the "Tutorial"
-- attribute is on (a new player, or "/tutorial").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local Inventory = require(script.Parent.Inventory)
local TutorialRide = require(script.Parent.TutorialRide)
local CameraHint = require(script.Parent.CameraHint)
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TAP = "rbxassetid://134865745295413" -- assets/ui/TapHand.png (QM's)
local TAP_SIZE = 96 -- px tall (it's 488 x 610)
local TAP_TIP = Vector2.new(0.365, 0.03) -- the fingertip, in the picture
-- QM's Sprint guide (assets/ui/SprintGuide.png, 3846 x 162), in four upright strips, each
-- uploaded at full size (an upload's at most 1024 wide): SprintGuide1-4.png, left to right.
local SPRINT_GUIDE = {
	size = Vector2.new(3846, 162),
	strips = { { "rbxassetid://128484192846174", 962 }, { "rbxassetid://118018475359108", 962 }, { "rbxassetid://139647408711436", 961 }, { "rbxassetid://114889489768256", 961 } },
}
-- QM's guide bars along the top, one per step, laid out like the Sprint guide (QM, Oct 11):
-- each is 3846 x 142, a see-through black bar (alpha 77) across the screen with the words
-- in the middle. The bar's drawn here (a Frame); only the words are uploads, cut out of
-- QM's art at x 1411..2435 (assets/ui/TutorialGuide1-5.png, 1024 x 142, an upload's widest).
local GUIDE_BAR = { size = Vector2.new(3846, 142), from = 1411, width = 1024, transparency = 1 - 77 / 255 }
local CAPTIONS = {
	clickEgg = "rbxassetid://90551038508587", -- assets/ui/TutorialGuide1.png "Click on the egg": the egg in your inventory
	placeEgg = "rbxassetid://83311618092760", -- assets/ui/TutorialGuide2.png "Place the egg": holding it
	hatchEgg = "rbxassetid://84547643672529", -- assets/ui/TutorialGuide3.png "Hatch your egg": it's in your pen, waiting to be hatched
	ride = "rbxassetid://71738076831384", -- assets/ui/TutorialGuide4.png "Ride your horse!": your Horse is out
	lasso = "rbxassetid://104793392329968", -- assets/ui/TutorialGuide5.png "Lasso an animal": the first ride, till your first throw
}
local SLOW_FLOOR = 0.02 -- the slow-down's bottom (x speed): all but stopped
local SLOW_TIME = 0.5 -- seconds into the slow-down for its middle (the sigmoid's)
local SLOW_STEEP = 9 -- how sharp its turn is
local WAIT_FOR_BOSS = 5 -- seconds after you sprint till BOSS IN shows (QM)
local BOSS_SECONDS = 5 -- and how long it gives you
local GATE_IN, GATE_HOLD, GATE_OUT = 0.8, 1.25, 0.65 -- seconds the camera takes to the Desert's gate, stays, and comes back (QM: twice as fast)
local NEW_PET_WAIT = 12 -- seconds after a ride for its egg to hatch in your pen

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
end

local function hrp()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local funnelSent = {} -- (each step once a visit: the server keeps only the first anyway)
local function funnel(step)
	local remote = ReplicatedStorage:FindFirstChild("FunnelStep")
	if remote and not funnelSent[step] then
		funnelSent[step] = true
		remote:FireServer("tutorial", step) -- (Funnel.server's onboarding funnel)
	end
end

-- The tap hand: on the screen, pulsing, over a GUI object or a point in the world.
local gui = Instance.new("ScreenGui")
gui.Name = "Tutorial"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 40
local tap = Instance.new("ImageLabel")
tap.BackgroundTransparency = 1
tap.Image = TAP
tap.Size = UDim2.fromOffset(math.round(TAP_SIZE * 488 / 610), TAP_SIZE)
tap.Visible = false
local tapScale = Instance.new("UIScale")
tapScale.Parent = tap
tap.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- QM's Sprint guide: a bar along the top (computers only).
local sprintGuide = Instance.new("Frame")
sprintGuide.BackgroundTransparency = 1
local stripFrom = 0
for _, strip in SPRINT_GUIDE.strips do
	local piece = Instance.new("ImageLabel")
	piece.BackgroundTransparency = 1
	piece.Image = strip[1]
	piece.Position = UDim2.fromScale(stripFrom / SPRINT_GUIDE.size.X, 0)
	piece.Size = UDim2.fromScale(strip[2] / SPRINT_GUIDE.size.X, 1)
	piece.Parent = sprintGuide
	stripFrom += strip[2]
end
sprintGuide.AnchorPoint = Vector2.new(0.5, 0)
sprintGuide.Position = UDim2.fromScale(0.5, 0.12)
sprintGuide.Size = UDim2.fromScale(1, 1)
local guideRatio = Instance.new("UIAspectRatioConstraint")
guideRatio.AspectRatio = SPRINT_GUIDE.size.X / SPRINT_GUIDE.size.Y
guideRatio.Parent = sprintGuide
sprintGuide.Visible = false
sprintGuide.Parent = gui

-- QM's guide bar for the step you're on, along the top (as the Sprint guide).
local caption = Instance.new("Frame")
caption.BackgroundColor3 = Color3.new(0, 0, 0)
caption.BackgroundTransparency = GUIDE_BAR.transparency
caption.BorderSizePixel = 0
caption.AnchorPoint = Vector2.new(0.5, 0)
caption.Position = UDim2.fromScale(0.5, 0.12)
caption.Size = UDim2.fromScale(1, 1)
caption.Visible = false
local captionRatio = Instance.new("UIAspectRatioConstraint")
captionRatio.AspectRatio = GUIDE_BAR.size.X / GUIDE_BAR.size.Y
captionRatio.Parent = caption
local words = Instance.new("ImageLabel")
words.BackgroundTransparency = 1
words.AnchorPoint = Vector2.new(0.5, 0.5) -- (a UIScale grows it about its anchor: from its middle, QM)
words.Position = UDim2.fromScale((GUIDE_BAR.from + GUIDE_BAR.width / 2) / GUIDE_BAR.size.X, 0.5)
words.Size = UDim2.fromScale(GUIDE_BAR.width / GUIDE_BAR.size.X, 1)
words.Parent = caption
local captionScale = Instance.new("UIScale") -- (the words pulse: QM)
captionScale.Parent = words
caption.Parent = gui
local captionOn -- the CAPTIONS key on show, or nil
-- QM's banner (Oct 11, in place of the guide bars along the top): a blue band wider than the
-- screen with the words on it, as viggle-chess's PhaseBanner (QM, Oct 11): the band stays
-- put and fades in and out, while the words sweep straight across it from off the left to
-- off the right, fast at both edges and slowest in the middle (never stopping). Its ends
-- never show.
local BANNER = {
	strips = { { "133460716318344", 863 }, { "123588848079137", 862 }, { "71619753997099", 862 } }, -- assets/ui/PromptBanner1-3.png (QM's longer PromptBanner.png, 2587 x 113, in thirds: an upload's at most 1024 wide)
	size = Vector2.new(2587, 113),
	width = 1.3, -- x the screen's width (so its ends are always off it)
	at = 0.17, -- its middle, down the screen
	travel = 0.6, -- the words go from this far left of the middle to this far right, x the screen's width
	speed = { 2.592, 0.136 }, -- A, B: the words' speed A (2u - 1)^2 + B of their average (A / 3 + B = 1)
	fade = 0.16, -- of the sweep fading in, and again out
	time = 3, -- seconds, the whole sweep (QM)
}
local BANNER_WORDS = { -- the words, as QM drew them, and their size in pixels
	ride = { "138620110562195", Vector2.new(354, 49) }, -- assets/ui/BannerRideHorse.png "Ride your horse!"
}
local banner = Instance.new("Frame") -- (its pictures fade together: a CanvasGroup this wide didn't draw)
banner.BackgroundTransparency = 1
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Size = UDim2.fromScale(BANNER.width, 1)
banner.Visible = false
local bannerImages = {}
local bannerRatio = Instance.new("UIAspectRatioConstraint")
bannerRatio.AspectRatio = BANNER.size.X / BANNER.size.Y
bannerRatio.Parent = banner
do
	local from = 0
	for _, strip in BANNER.strips do
		local piece = Instance.new("ImageLabel")
		piece.BackgroundTransparency = 1
		piece.Image = "rbxassetid://" .. strip[1]
		piece.Position = UDim2.fromScale(from / BANNER.size.X, 0)
		piece.Size = UDim2.fromScale(strip[2] / BANNER.size.X, 1)
		piece.ImageTransparency = 1
		piece.Parent = banner
		table.insert(bannerImages, piece)
		from += strip[2]
	end
end
local bannerWords = Instance.new("ImageLabel")
bannerWords.BackgroundTransparency = 1
bannerWords.AnchorPoint = Vector2.new(0.5, 0.5)
bannerWords.Position = UDim2.fromScale(0.5, 0.5)
bannerWords.ZIndex = 2
bannerWords.ImageTransparency = 1
bannerWords.Parent = banner
table.insert(bannerImages, bannerWords)
banner.Parent = gui
task.spawn(function() -- (the band and its words, loaded before they're needed: QM)
	local labels = table.clone(bannerImages) -- (as images: a bare id string fails to preload)
	for _, words in BANNER_WORDS do
		local label = Instance.new("ImageLabel")
		label.Image = "rbxassetid://" .. words[1]
		table.insert(labels, label)
	end
	pcall(game:GetService("ContentProvider").PreloadAsync, game:GetService("ContentProvider"), labels)
end)
local bannerShown = {} -- [key] = true once it's been up
local bannerSweep -- its RenderStepped connection while it's up
local function showBanner(key)
	local words = BANNER_WORDS[key]
	if not words or bannerShown[key] then
		return
	end
	bannerShown[key] = true
	bannerWords.Image = "rbxassetid://" .. words[1]
	-- (the words as tall as QM drew them on the band: 49 of its 113)
	local tall = words[2].Y / BANNER.size.Y
	bannerWords.Size = UDim2.fromScale(tall * words[2].X / words[2].Y * BANNER.size.Y / BANNER.size.X, tall)
	local A, B = BANNER.speed[1], BANNER.speed[2]
	local started = os.clock()
	banner.Position = UDim2.fromScale(0.5, BANNER.at)
	banner.Visible = true
	if bannerSweep then
		bannerSweep:Disconnect()
	end
	local sweep
	sweep = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		local u = math.min(t / BANNER.time, 1)
		local along = A * ((2 * u - 1) ^ 3 + 1) / 6 + B * u -- 0 to 1 (the speed's integral)
		bannerWords.Position = UDim2.fromScale(0.5 + (2 * along - 1) * BANNER.travel / BANNER.width, 0.5)
		local shown = math.clamp(math.min(u / BANNER.fade, (1 - u) / BANNER.fade), 0, 1)
		for _, image in bannerImages do
			image.ImageTransparency = 1 - shown
		end
		if u >= 1 then
			sweep:Disconnect()
			banner.Visible = false
		end
	end)
	bannerSweep = sweep
end

-- The tutorial's prompts (QM, Oct 11): no guide bars any more; only "Ride your horse!",
-- as a banner, for now.
local function say(key)
	captionOn = nil
	if key == "ride" then
		showBanner("ride")
	end
end

local tapAt -- a GuiObject, a Vector3 in the world, or nil
local function pointAt(target)
	tapAt = target
end

-- The arrows on the ground, from you to a spot (as Ride's guide).
local guideFrom, guideTo = Instance.new("Attachment"), Instance.new("Attachment")
local beam = Instance.new("Beam")
beam.Texture = "rbxassetid://101032148634562" -- assets/ui/GuideArrow.png
beam.TextureMode = Enum.TextureMode.Static
beam.TextureLength = 5
beam.TextureSpeed = 1.2
beam.Width0, beam.Width1 = 4, 4
beam.FaceCamera = false
beam.LightEmission = 1
beam.LightInfluence = 0
beam.ZOffset = 6
beam.Color = ColorSequence.new(Color3.fromRGB(255, 236, 120))
beam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.08, 0.15),
	NumberSequenceKeypoint.new(0.9, 0.15),
	NumberSequenceKeypoint.new(1, 1),
})
beam.Attachment0, beam.Attachment1 = guideFrom, guideTo
beam.Enabled = false
beam.Parent = guideFrom
guideFrom.Parent, guideTo.Parent = workspace.Terrain, workspace.Terrain
local guideAt -- a Vector3 (or a model, followed) to lead you to, or nil
local function guide(target)
	guideAt = target
end

-- QM's big white arrow over the egg in your pen, bobbing, once it's placed, then over
-- the pet that hatches, each till you're close enough for its prompt (QM, Oct 11).
local ARROW = "rbxassetid://127821178410489" -- assets/ui/TutorialArrow.png
local ARROW_SIZE = 7 -- studs
local ARROW_UP = 14 -- (QM) studs over the egg's root, at the bottom of its bob
local ARROW_UP_PET = 20 -- and over the pet's (QM)
local eggArrow = Instance.new("BillboardGui")
eggArrow.Name = "TutorialEggArrow"
eggArrow.Size = UDim2.fromScale(ARROW_SIZE, ARROW_SIZE)
eggArrow.AlwaysOnTop = true
eggArrow.LightInfluence = 0
eggArrow.Enabled = false
local arrowImage = Instance.new("ImageLabel")
arrowImage.BackgroundTransparency = 1
arrowImage.Image = ARROW
arrowImage.Size = UDim2.fromScale(1, 1)
arrowImage.Parent = eggArrow
eggArrow.ResetOnSpawn = false
eggArrow.Parent = player:WaitForChild("PlayerGui") -- (a BillboardGui draws from the PlayerGui, not inside a ScreenGui)
local arrowOver -- the egg model it's over, or nil

RunService.RenderStepped:Connect(function()
	-- The egg arrow, bobbing.
	local root = arrowOver and arrowOver.Parent and (arrowOver.PrimaryPart or arrowOver:FindFirstChildWhichIsA("BasePart", true))
	eggArrow.Adornee = root
	eggArrow.Enabled = root ~= nil and not player:GetAttribute("Cutscene")
	local up = if arrowOver and arrowOver:IsA("Model") and not arrowOver.Name:match("Egg$") then ARROW_UP_PET else ARROW_UP
	eggArrow.StudsOffsetWorldSpace = Vector3.new(0, up + math.abs(math.sin(os.clock() * 3)) * 1.5, 0)
	-- The tap hand.
	local show, flip = false, false
	if typeof(tapAt) == "Instance" and tapAt:IsA("GuiObject") and tapAt.Visible then
		local c = tapAt.AbsolutePosition + tapAt.AbsoluteSize / 2
		tap.Position = UDim2.fromOffset(c.X, c.Y + game:GetService("GuiService"):GetGuiInset().Y)
		show, flip = true, true -- (upside down over the inventory: reaching down from above, QM)
	elseif typeof(tapAt) == "Vector3" then
		local p, on = camera:WorldToViewportPoint(tapAt)
		if on then
			tap.Position = UDim2.fromOffset(p.X, p.Y)
			show = true
		end
	end
	tap.Visible = show and not player:GetAttribute("Cutscene")
	caption.Visible = captionOn ~= nil and not player:GetAttribute("Cutscene")
	captionScale.Scale = 1 + 0.06 * math.sin(os.clock() * 5)
	-- (the fingertip on the spot, either way up: Rotation turns it about its middle)
	tap.Rotation = if flip then 180 else 0
	tap.AnchorPoint = if flip then Vector2.one - TAP_TIP else TAP_TIP
	tapScale.Scale = 1 + 0.12 * math.sin(os.clock() * 6)
	-- The arrows.
	local root = hrp()
	local target = guideAt
	if typeof(target) == "Instance" then
		target = if target.Parent then target:GetPivot().Position else nil
	end
	if root and target and not Hud.isRiding() and not player:GetAttribute("Cutscene") then
		local from = Vector3.new(root.Position.X, 0, root.Position.Z)
		local to = Vector3.new(target.X, 0, target.Z)
		local along = to - from
		if along.Magnitude > 6 then
			along = along.Unit
			from += along * 3
			local side = along:Cross(Vector3.yAxis)
			guideFrom.WorldCFrame = CFrame.fromMatrix(Vector3.new(from.X, 1.4, from.Z), along, side)
			guideTo.WorldCFrame = CFrame.fromMatrix(Vector3.new(to.X, 1.4, to.Z), along, side)
			beam.Enabled = true
		else
			beam.Enabled = false
		end
	else
		beam.Enabled = false
	end
end)

-- What's in your pen: its egg models and your pets.
local function penEgg()
	local pen = myPen()
	local area = pen and pen:FindFirstChild("Area")
	local folder = workspace:FindFirstChild("PenContents")
	if not area or not folder then
		return nil
	end
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m.Name:match("Egg$") and not m:GetAttribute("Ghost") then -- (not Pen's ghost of the egg you're holding)
			local p = area.CFrame:PointToObjectSpace(m:GetPivot().Position)
			if math.abs(p.X) <= area.Size.X / 2 and math.abs(p.Z) <= area.Size.Z / 2 then
				return m
			end
		end
	end
	return nil
end

local function myPets()
	local list = {}
	for model in PenPets.pets do
		if model.Parent then
			table.insert(list, model)
		end
	end
	local starter = PenPets.starter
	if starter and starter.animal and starter.animal.model.Parent then
		table.insert(list, starter.animal.model)
	end
	return list
end

local function eggTool()
	for _, holder in { player.Character, player:FindFirstChild("Backpack") } do
		for _, t in if holder then holder:GetChildren() else {} do
			if t:IsA("Tool") and t:GetAttribute("EggKind") then
				return t, holder == player.Character
			end
		end
	end
	return nil
end

local function clear()
	arrowOver = nil
	pointAt(nil)
	guide(nil)
	say(nil)
	player:SetAttribute("NoSprint", nil)
	player:SetAttribute("NoLasso", nil)
	player:SetAttribute("LassoGuide", nil)
	sprintGuide.Visible = false
	TutorialRide.active, TutorialRide.timeScale, TutorialRide.holdFrozen = false, 1, false
	TutorialRide.bossSeconds, TutorialRide.bossStarted, TutorialRide.invulnerable = nil, nil, false
end

-- Slows time (a sigmoid down to SLOW_FLOOR, never quite stopping) while waitFor()
-- is false and you're still riding; back to full speed once it's true.
local function slowUntil(waitFor)
	local since = os.clock()
	while TutorialRide.active and Hud.isRiding() and not waitFor() do
		local t = os.clock() - since
		local k = 1 / (1 + math.exp(-SLOW_STEEP * (t - SLOW_TIME)))
		TutorialRide.timeScale = 1 - (1 - SLOW_FLOOR) * k
		RunService.Heartbeat:Wait()
	end
	TutorialRide.timeScale = 1
end

-- The camera zooms to the Desert's gate (the next goal) and back (QM, Oct 11: just the
-- Desert again, not the whole course, and twice as fast).
local function showGate()
	CameraHint.show(Vector3.new(0, 10, -Config.Biomes[1].Length), Vector3.new(0, 26, 80), GATE_IN, GATE_HOLD, GATE_OUT)
end

local running = false
local function run()
	if running then
		return
	end
	running = true
	bannerShown = {} -- (a new run, "/tutorial" too, shows its banners again)
	-- After the intro (or straight away without one).
	if Config.Intro ~= false then
		while player:GetAttribute("Tutorial") and not player:GetAttribute("IntroDone") do
			task.wait(0.2)
		end
	end
	local function on()
		return player:GetAttribute("Tutorial") == true
	end
	while not pcall(Hud.setTutorial, "bare") do -- (once the HUD's built)
		task.wait(0.5)
	end
	funnel("place")

	-- 1. Place your egg: the tap hand on it, then on your pen.
	local function placeEgg()
		local tool, held = eggTool()
		local pen = myPen()
		local area = pen and pen:FindFirstChild("Area")
		if tool and not held then
			pointAt(Inventory.slot(tool.Name))
			guide(nil)
			say("clickEgg")
		elseif tool and held and area then
			funnel("hold")
			pointAt(area.Position + Vector3.new(0, area.Size.Y / 2 + 1, 0))
			guide(area.Position)
			say("placeEgg")
		else
			pointAt(nil)
			guide(nil)
			say(nil)
		end
	end

	-- (the "Ride your horse!" banner only once this run has seen your egg in the pen: a
	-- horse there at login, before your data's in, isn't one you hatched)
	local sawEgg = false
	while on() do
		-- 1. Place it, 2. hatch it, 3. ride it: whichever you're at (a "/tutorial" mid-way
		-- puts you back at 1 without this loop starting again).
		while on() and not Hud.isRiding() do
			local egg = penEgg()
			local pets = myPets()
			-- (the arrow: over the egg, then the pet out of it, till you're close enough for its prompt: QM)
			arrowOver = if egg and #pets == 0 then (if player:GetAttribute("EggPromptUp") then nil else egg)
				elseif #pets > 0 and not player:GetAttribute("RidePromptUp") and not pets[1]:GetAttribute("Hatching") then pets[1] -- (once it's fully out: QM)
				else nil
			if egg and #pets == 0 then
				pointAt(nil)
				guide(egg)
				sawEgg = true
				say("hatchEgg")
			elseif #pets > 0 then
				pointAt(nil)
				guide(pets[1])
				if sawEgg and not pets[1]:GetAttribute("Hatching") then -- (once it's out of the egg, so you see it)
					say("ride")
				end
			else
				placeEgg()
			end
			task.wait(0.1)
		end
		if not on() then
			break
		end
		-- 4. The first ride.
		funnel("ride")
		guide(nil)
		local before = #myPets()
		TutorialRide.active, TutorialRide.holdFrozen, TutorialRide.invulnerable = true, true, true
		player:SetAttribute("NoSprint", true)
		player:SetAttribute("LassoGuide", true)
		say(nil) -- (no "Lasso an animal" bar: the arrows are enough, QM)
		local firstThrow, firstMount = TutorialRide.throws, TutorialRide.mounts
		-- Till your first lasso: time all but stops while an animal's in reach. (The
		-- arrows go as soon as it's thrown: QM.)
		while on() and Hud.isRiding() and TutorialRide.throws <= firstThrow do
			if TutorialRide.canLasso then
				funnel("reach")
				slowUntil(function()
					return TutorialRide.throws > firstThrow or not TutorialRide.canLasso
				end)
			end
			RunService.Heartbeat:Wait()
		end
		player:SetAttribute("LassoGuide", nil)
		say(nil)
		-- (and the sprint step waits for you to land on it, or a miss)
		local thrown = os.clock()
		while on() and Hud.isRiding() and TutorialRide.mounts <= firstMount and os.clock() - thrown < 3 do
			task.wait(0.1)
		end
		funnel("lasso")
		player:SetAttribute("NoSprint", nil)
		-- (no Sprint step any more: pets always sprint on the way out, QM Oct 11)
		-- A few more seconds, then BOSS IN, short.
		local waitStart = os.clock()
		while on() and Hud.isRiding() and os.clock() - waitStart < WAIT_FOR_BOSS do
			task.wait(0.1)
		end
		TutorialRide.bossSeconds, TutorialRide.holdFrozen = BOSS_SECONDS, false
		funnel("boss")
		while on() and Hud.isRiding() do
			task.wait(0.1)
		end
		clear()
		if not on() then
			break
		end
		-- 5. Home with an egg: it hatches in your pen; then the Desert's gate.
		local waited = os.clock()
		while on() and #myPets() <= before and os.clock() - waited < NEW_PET_WAIT do
			task.wait(0.2)
		end
		if #myPets() > before then
			task.wait(1)
			showGate()
			funnel("tour")
			local done = ReplicatedStorage:FindFirstChild("TutorialDone")
			if done then
				done:FireServer()
			end
			break
		end
		-- (nothing brought home: ride again)
	end
	clear()
	pcall(Hud.setTutorial, nil)
	running = false
end

local function check()
	if player:GetAttribute("Tutorial") == true then
		bannerShown = {} -- ("/tutorial" again: its banners show again)
		task.spawn(run)
	else
		clear()
		if not running then
			pcall(Hud.setTutorial, nil)
		end
	end
end
player:GetAttributeChangedSignal("Tutorial"):Connect(check)
check()
