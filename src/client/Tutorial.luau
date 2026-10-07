-- The first-time tutorial, for a player whose "Tutorial" attribute is set (the
-- server sets it for a new player, Hatchery). One hint at a time at the top of the
-- screen, a trail of glowing arrows on the ground to whatever the hint is about,
-- and only the buttons each step needs (Hud.setTutorial; Ride leaves out Sprint,
-- Ability and the Hold bar):
--
--   1. place "Place your egg in your pen!"  only the inventory, holding your first
--                                            egg; arrows to the pen. It hatches at
--                                            once (Config.TutorialHatchTime). Until
--                                            the egg's in hand it's "Click on the
--                                            egg", with a cursor on its square.
--                                            (Both place hints are QM's pictures.)
--   2. ride  "Ride your Horse!"              arrows to it
--   3. lasso "Press E to LASSO a new ride!"  time slows, ever more, while an animal is
--                                            in reach; no nest egg can be taken yet
--                                            (Ride's eggInRange), so it can't be skipped
--   4. egg   "Follow the arrows..."          the egg guide (Ride's, to the nearest nest's)
--   5. take  "Press E to take the egg!"      time slows, ever more, while it's in reach
--   6. home  (DODGE THE STAMPEDE!)           home with the egg
--   7. place2 the egg goes into the pen by itself (Hatchery's DeliverEgg, balance
--            pass Oct 6: a fifth of new players left here when they had to place it)
--   8. goal  the moment the egg's pet has hatched out, the camera flies to the next
--            biome's gate: "Save $1k to unlock the Desert!". Then it's over: the money
--            starts (Hatchery: pets earn nothing till now, QM Oct 6) and the rest of
--            the HUD (Gold, Upgrade Pen, Pets, Fuse) comes back, none of which shows
--            in the tutorial (QM). The arrows then lead to that new pet until you
--            ride. (No fuse step: too confusing for kids, QM Oct 6 21:15.)
--
-- A failed ride goes back to step 2. Until it's done the stampede runs on your
-- own clock (Ride), so slowing it down never snaps it back.
--
-- Ride drives it: Tutorial.init() once, Tutorial.update(state) every frame,
-- Tutorial.lassoed() on landing on a lassoed animal, and reads Tutorial.active /
-- Tutorial.slowMo / Tutorial.busy.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local Inventory = require(script.Parent.Inventory)
local FuseLesson = require(script.Parent.FuseLesson) -- (fusing's own lesson, once the Desert's unlocked)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local Tutorial = {}
Tutorial.active = false -- the tutorial is running: the "Tutorial" attribute is set
Tutorial.slowMo = nil -- a time scale while LASSO or TAKE EGG waits for its press, lower the longer it waits
Tutorial.busy = false -- the ending's close-ups are on: no riding off

local HINT_Y = 0.25 -- the hint's height on screen (its middle, a share of the screen height)
local FAIL_HINT_Y = 0.1 -- on a fail screen: above the CRASH! / BUCKED OFF banner (Hud, at 0.3)
local LAND_WAIT = 0.7 -- seconds from the hatched pet coming out (Pen.client) to the gate: its jump down (0.6)
local GATE_HOLD = 2.5 -- seconds the camera stays on the gate
-- The flight to the gate and back (flightAt): straight up first, to Clear studs
-- (over the base's and the course's walls, 48 tall with 2-stud caps), leaning Lean
-- studs in toward the base's middle so it clears a cap it starts under, then an
-- arc that climbs Arc more and dives in to the view from Dive studs before it. A
-- straight line from a pen off the corridor's line went through the front wall (QM, Oct 6).
local SWOOP = { Clear = 60, Lean = 16, Arc = 40, Dive = 120 }
local PICTURE_Y = 0.09 -- a hint picture's middle, a share of the screen height (QM's layout)
local PICTURE_WIDTH = 0.25 -- "Click on the egg"'s width, a share of the screen width (0.8x the reference: QM)
local THROB = 0.02 -- a hint picture throbs between 1 - THROB and 1 + THROB times its size (QM)
local CURSOR_THROB = 0.1 -- and the cursor between 1 -/+ this
local THROB_TIME = 1 -- seconds per throb
local RIDE_STEPS = { lasso = true, egg = true, take = true, home = true }
local PLACE_STEPS = { place = true, place2 = true }

local step = "place"
local failed = false -- the ride ended in a crash or buck-off
local lastPhase = "idle"
local slowSince -- os.clock() when LASSO or TAKE EGG began waiting for its press (nil: it isn't)
local hudStage = nil -- what the HUD was last told (Hud.setTutorial)
local done = false -- TutorialDone sent
local newPet = nil -- the pen id of the pet the egg brought home hatched into: once it's over, the arrows lead to it till you ride (QM, Oct 6)
local known = {} -- the pen's items when the ride home began: a new one is the egg brought home
local goalText -- "Save $1k to unlock the Desert!", once the close-ups start
local goalDesert = false -- and it's that one, which QM drew (PICTURES.saveDesert)

local function touch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- The hint: white text with a black outline, top centre. It pops in and then
-- pulses like DODGE THE STAMPEDE! (a UIScale tween). The text size is fixed per
-- screen width: TextScaled re-fits the font to whole sizes every frame the scale
-- changes, which made the pulse step.
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 0.5)
hint.Position = UDim2.fromScale(0.5, HINT_Y)
hint.Size = UDim2.fromScale(0.8, 0.07)
hint.Font = Enum.Font.FredokaOne
hint.TextWrapped = true
hint.TextColor3 = Color3.new(1, 1, 1)
hint.Text = ""
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(0, 0, 0)
stroke.LineJoinMode = Enum.LineJoinMode.Round
stroke.Parent = hint
local hintScale = Instance.new("UIScale")
hintScale.Parent = hint
hint.Parent = gui
local function resize()
	local width = camera.ViewportSize.X
	hint.TextSize = math.round(width / 26)
	stroke.Thickness = math.max(2, math.round(width / 320))
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()

-- QM's hint pictures, in place of the text hint: step 1's "Click on the egg"
-- (with a cursor over the egg's square in the inventory: its tip, CURSOR_TIP on
-- the 256px picture, on the square at CURSOR_AT, CURSOR_SIZE times the square's
-- size), "Place the egg in your pen" once it's in hand (steps 1 and 7) and
-- "Ride your horse!" (step 2, when it's a Horse; another pet gets the text),
-- "Lasso an animal" (step 3), "Take an egg!" (steps 4 and 5) and "Save $1k to
-- unlock the desert!" (step 8, when the Desert's next at $1k). QM draws them
-- all at one letter size, so they're all shown at the scale that makes "Click on
-- the egg" PICTURE_WIDTH wide.
local PICTURES = {
	click = { image = "rbxassetid://93909017403661", width = 935, height = 145 }, -- assets/ui/HintClickEgg.png
	place = { image = "rbxassetid://110142835452075", width = 1473, height = 146 }, -- assets/ui/HintPlaceEgg.png
	rideHorse = { image = "rbxassetid://87420526826729", width = 951, height = 146 }, -- assets/ui/HintRideHorse.png
	lasso = { image = "rbxassetid://91804135266195", width = 942, height = 119 }, -- assets/ui/HintLasso.png
	takeEgg = { image = "rbxassetid://140505417870582", width = 738, height = 145 }, -- assets/ui/HintTakeEgg.png
	-- (cost: the Desert price drawn in it; at any other price the text hint shows instead.
	-- image "": not uploaded yet, the text hint too)
	saveDesert = { image = "rbxassetid://94733777866922", width = 1830, height = 127, cost = 500 }, -- assets/ui/HintSaveDesert.png
}
local picture = Instance.new("ImageLabel")
picture.Name = "HintPicture"
picture.BackgroundTransparency = 1
picture.AnchorPoint = Vector2.new(0.5, 0.5)
picture.Position = UDim2.fromScale(0.5, PICTURE_Y)
picture.Visible = false
local pictureScale = Instance.new("UIScale")
pictureScale.Parent = picture
picture.Parent = gui
local pictureShown -- the PICTURES entry showing
local function sizePicture()
	local entry = pictureShown or PICTURES.click
	local scale = camera.ViewportSize.X * PICTURE_WIDTH / PICTURES.click.width -- per pixel of the picture
	picture.Size = UDim2.fromOffset(entry.width * scale, entry.height * scale)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(sizePicture)
task.spawn(function() -- loaded ahead, so swapping pictures never shows a blank
	local images = {}
	for _, entry in PICTURES do
		if entry.image ~= "" then
			table.insert(images, entry.image)
		end
	end
	game:GetService("ContentProvider"):PreloadAsync(images)
end)
local CURSOR_TIP = Vector2.new(29 / 256, 6 / 256)
local CURSOR_AT = Vector2.new(0.64, 0.55)
local CURSOR_SIZE = 0.63
local cursor = Instance.new("ImageLabel")
cursor.Name = "Cursor"
cursor.BackgroundTransparency = 1
cursor.Image = "rbxassetid://93240211999923" -- assets/ui/TutorialCursor.png
cursor.AnchorPoint = CURSOR_TIP -- so it throbs about its tip
cursor.Visible = false
local cursorScale = Instance.new("UIScale")
cursorScale.Parent = cursor
cursor.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

-- Your first egg's tool, while it's in the backpack and not in your hand.
local function eggToClick()
	local char = player.Character
	if not char or char:FindFirstChildOfClass("Tool") then
		return nil
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, tool in backpack and backpack:GetChildren() or {} do
		if tool:IsA("Tool") and tool:GetAttribute("EggKind") then
			return tool
		end
	end
	return nil
end

-- Shows the hint picture called `name` (nil: none), and the cursor over `target`
-- (a button or the egg's square) if there's one.
local function showPicture(name, target)
	local entry = name and PICTURES[name]
	if entry ~= pictureShown then
		pictureShown = entry
		picture.Image = if entry then entry.image else ""
		sizePicture()
	end
	picture.Visible = entry ~= nil
	cursor.Visible = target ~= nil
	local wave = math.sin(os.clock() * 2 * math.pi / THROB_TIME)
	pictureScale.Scale = 1 + THROB * wave
	cursorScale.Scale = 1 + CURSOR_THROB * wave
	if target then
		local at, size = target.AbsolutePosition - gui.AbsolutePosition, target.AbsoluteSize -- (gui's is above 0 by the top bar)
		cursor.Position = UDim2.fromOffset(at.X + CURSOR_AT.X * size.X, at.Y + CURSOR_AT.Y * size.Y)
		local side = CURSOR_SIZE * math.min(size.X, size.Y)
		cursor.Size = UDim2.fromOffset(side, side)
	end
end

local shown = "" -- the hint's text when it's showing
local pop -- the pop-in tween
local function setHint(text)
	text = text or ""
	if text == shown then
		return
	end
	shown = text
	hint.Text = text
	hint.Visible = text ~= ""
	if pop then
		pop:Cancel()
	end
	if text ~= "" then
		hintScale.Scale = 0
		pop = TweenService:Create(hintScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
		pop:Play()
	end
end

-- The arrows: a beam lying flat on the ground, from just ahead of you to the target.
local beam = Instance.new("Beam")
local from, to = Instance.new("Attachment"), Instance.new("Attachment")
from.Name, to.Name = "TutorialFrom", "TutorialTo"
beam.Name = "TutorialGuide"
beam.Texture = "rbxassetid://101032148634562" -- assets/ui/GuideArrow.png, as the egg guide
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
beam.Attachment0, beam.Attachment1 = from, to
beam.Enabled = false
beam.Parent = from
from.Parent, to.Parent = workspace.Terrain, workspace.Terrain

local function pointTo(target)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not (target and hrp and humanoid) then
		beam.Enabled = false
		return
	end
	local feet = hrp.Position.Y - hrp.Size.Y / 2 - humanoid.HipHeight
	local start = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
	local flat = Vector3.new(target.X, 0, target.Z)
	local gap = flat - start
	if gap.Magnitude < 8 then
		beam.Enabled = false -- there already
		return
	end
	local along = gap.Unit
	start += along * 3
	local side = along:Cross(Vector3.yAxis)
	local y = feet + 0.3
	from.WorldCFrame = CFrame.fromMatrix(Vector3.new(start.X, y, start.Z), along, side)
	to.WorldCFrame = CFrame.fromMatrix(Vector3.new(flat.X, y, flat.Z), along, side)
	beam.Enabled = true
end

local function myPen()
	local index = player:GetAttribute("Pen")
	local pens = workspace:FindFirstChild("Pens")
	return index and pens and pens:FindFirstChild("Pen" .. index)
end

local function contents()
	local pen = myPen()
	local ok, items = pcall(HttpService.JSONDecode, HttpService, pen and pen:GetAttribute("Contents") or "{}")
	return if ok and typeof(items) == "table" then items else {}
end

-- Your pet to ride: the one waiting in the pen (Ride's starter), else where the
-- tutorial egg's pet (a Config.DefaultPet) hatched. Other pets in the pen (from
-- /give) don't count, so they don't skip step 1 or take over "Ride your horse!".
local function myPet(state)
	if state.pet then
		return state.pet, player:GetAttribute("RidePet")
	end
	for model, info in PenPets.pets do
		if model.Parent and info.kind == Config.DefaultPet then
			return model, info.kind
		end
	end
	return nil, nil
end

-- Analytics (Funnel.server): this step was reached. Never waits on the remote.
local function report(name)
	local remote = ReplicatedStorage:FindFirstChild("FunnelStep")
	if remote then
		remote:FireServer("tutorial", name)
	end
end

local function setStep(name)
	if name == step then
		return
	end
	step = name
	report(name)
	if name == "home" then
		table.clear(known)
		for id in contents() do
			known[id] = true
		end
	end
end

local function finish()
	if not done then
		done = true
		ReplicatedStorage:WaitForChild("TutorialDone"):FireServer() -- clears the attribute: Tutorial.init's refresh ends it
	end
end

-- The pet that the egg placed (`id` in the pen) hatched into, once it's out in the
-- pen (Pen.client puts it in PenPets 1.6 s into the hatch), else nil.
local function petOut(id)
	for model, pet in PenPets.pets do
		if pet.id == id and model.Parent then
			return model
		end
	end
	return nil
end

-- Where the camera is `t` (0..1) of the way from `start` to `view` on the flight
-- (SWOOP): up out of the base, then the arc down the corridor, turning evenly.
local function flightAt(start, view, t)
	local from = start.Position
	local lift = from
	if from.Y < SWOOP.Clear then
		local inward = Vector3.new(-from.X, 0, Config.HomeDepth / 2 - from.Z)
		lift = Vector3.new(from.X, SWOOP.Clear, from.Z) + (if inward.Magnitude > 1 then inward.Unit * SWOOP.Lean else Vector3.zero)
	end
	local up = (lift - from).Magnitude
	local share = up / (up + (view.Position - lift).Magnitude) -- the lift's share of the way
	local pos
	if t < share then
		pos = from:Lerp(lift, t / share)
	else
		local s = (t - share) / (1 - share)
		local u = 1 - s
		local p1, p2 = lift + Vector3.new(0, SWOOP.Arc, 0), view.Position + Vector3.new(0, SWOOP.Arc, SWOOP.Dive)
		pos = u * u * u * lift + 3 * u * u * s * p1 + 3 * u * s * s * p2 + s * s * s * view.Position
	end
	return CFrame.new(pos) * start:Lerp(view, t).Rotation
end

-- Flies the camera from `start` to `view` in `seconds`, eased (`back`: the other way).
local function flight(start, view, seconds, back)
	local began = os.clock()
	local t = 0
	while t < 1 do
		t = TweenService:GetValue(math.min((os.clock() - began) / seconds, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		camera.CFrame = flightAt(start, view, if back then 1 - t else t)
		RunService.RenderStepped:Wait()
	end
end

-- Over to the gate after biome `level` and back.
local function gateFlight(level)
	local gateZ = WorldColors.gateZ(level)
	local start = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local view = CFrame.lookAt(Vector3.new(0, 40, gateZ + 70), Vector3.new(0, 8, gateZ))
	flight(start, view, 2)
	task.wait(GATE_HOLD)
	flight(start, view, 1.4, true)
	camera.CameraType = Enum.CameraType.Custom
end

-- The ending: the egg's placed (`id` in the pen) and hatches by itself; the moment
-- its pet's out and landed, the camera flies over to the next biome's gate and back,
-- and it's over.
local function showGoal(id)
	Tutorial.busy = true
	local by = os.clock() + 6 -- (in case it never shows)
	while not petOut(id) and os.clock() < by do
		task.wait()
	end
	task.wait(LAND_WAIT)
	newPet = id
	controls:Disable()
	local level = player:GetAttribute("PenLevel") or 1
	local upNext = Config.Biomes[level + 1]
	if upNext then
		goalText = "Save " .. Hud.money(upNext.UnlockCost) .. " to unlock the " .. upNext.Name .. "!"
		goalDesert = upNext.Name == "Desert" and upNext.UnlockCost == PICTURES.saveDesert.cost and PICTURES.saveDesert.image ~= ""
		report("gate")
		gateFlight(level)
	end
	controls:Enable()
	Tutorial.busy = false
	finish()
end

local function hintFor(state)
	local phase = state.phase
	if phase == "ended" then
		return "Oops! Press HOME to try again."
	elseif PLACE_STEPS[step] then
		return if phase == "idle" then "Place your egg in your pen!" else nil
	elseif step == "goal" then
		return goalText
	elseif step == "ride" then
		local _, kind = myPet(state)
		return if kind and kind ~= "" then "Ride your " .. kind .. "!" else nil
	elseif step == "lasso" then
		return if touch() then "Tap LASSO to jump on a new ride!" else "Press E to LASSO a new ride!"
	elseif step == "egg" then
		return "Follow the arrows to the egg!"
	elseif step == "take" then
		return if touch() then "Tap TAKE EGG!" else "Press E to take the egg!"
	end
	return nil -- home: DODGE THE STAMPEDE! says it
end

-- Every frame, from Ride. state = { phase, target ("egg", an animal or nil: what
-- LASSO / TAKE EGG would grab), pet (the model RIDE rides at home), transfer
-- (being pulled across to a lassoed animal), cutscene (the egg close-up or a
-- hero leap is on) }.
function Tutorial.update(state)
	local phase = state.phase
	local lessonStage, lessonCursor
	if not Tutorial.active then
		lessonStage, lessonCursor = FuseLesson.update(phase, state.cutscene)
	end
	local stage = if Tutorial.active then "bare" else lessonStage
	if stage ~= hudStage then
		hudStage = stage
		Hud.setTutorial(stage)
	end
	if not Tutorial.active then
		slowSince, Tutorial.slowMo = nil, nil
		setHint(nil)
		showPicture(nil, lessonCursor)
		if phase ~= "idle" then
			newPet = nil -- riding: the arrows have done their job
		end
		local pet = newPet and not state.cutscene and petOut(newPet)
		pointTo(pet and pet.PrimaryPart and pet.PrimaryPart.Position)
		lastPhase = phase
		return
	end
	if phase ~= "idle" then
		failed = failed or phase == "ended"
		if step == "place" or step == "ride" then
			setStep("lasso")
		end
		if RIDE_STEPS[step] then
			if phase == "outbound" then
				if step == "egg" and state.target == "egg" then
					setStep("take")
				end
			elseif phase == "turning" or phase == "return" then
				setStep("home")
			end
		end
	elseif lastPhase ~= "idle" then
		-- Back home: with the egg, on to placing it; otherwise another go.
		if RIDE_STEPS[step] then
			setStep(if not failed and step == "home" then "place2" else "ride")
		end
		failed = false
	end
	lastPhase = phase

	if step == "place" and ((player:GetAttribute("RidePet") or "") ~= "" or myPet({}) ~= nil) then
		setStep("ride") -- it's hatched (or there was a pet already)
	elseif step == "place2" then
		for id in contents() do
			if not known[id] then
				setStep("goal") -- placed
				task.spawn(showGoal, id)
				break
			end
		end
	end

	local slow = (step == "lasso" and typeof(state.target) == "table" and not state.transfer)
		or (step == "take" and state.target == "egg")
	if slow and phase == "outbound" then
		-- Time keeps slowing the longer the press takes (QM, Oct 7: at one fixed speed
		-- players outran the egg and rode on into the Desert gate): TutorialSlowMo at
		-- first, a quarter of that after TutorialSlowDeepen seconds, a ninth after twice
		-- that, and so on, till the stampede all but stands still. So the egg (or the
		-- animal) stays in reach however long the button takes to find.
		slowSince = slowSince or os.clock()
		local waited = 1 + (os.clock() - slowSince) / Config.TutorialSlowDeepen
		Tutorial.slowMo = Config.TutorialSlowMo / (waited * waited)
	else
		slowSince, Tutorial.slowMo = nil, nil
	end

	local clickTool = if step == "place" and phase == "idle" and not state.cutscene then eggToClick() else nil
	local pictureName = if state.cutscene or phase == "ended" then nil
		elseif phase ~= "idle" then (if step == "lasso" then "lasso" elseif step == "egg" or step == "take" then "takeEgg" else nil)
		elseif clickTool then "click"
		elseif PLACE_STEPS[step] then "place"
		elseif step == "ride" and select(2, myPet(state)) == "Horse" then "rideHorse"
		elseif step == "goal" and goalText and goalDesert then "saveDesert"
		else nil
	local cursorOn = if clickTool then Inventory.slot(clickTool.Name) else nil
	showPicture(pictureName, cursorOn)
	setHint(if state.cutscene or pictureName then nil else hintFor(state))
	hint.Position = UDim2.fromScale(0.5, if phase == "ended" then FAIL_HINT_Y else HINT_Y) -- over CRASH! / BUCKED OFF

	local target
	if phase == "idle" then
		if step == "ride" then
			local pet = myPet(state)
			target = pet and pet.PrimaryPart and pet.PrimaryPart.Position
		elseif PLACE_STEPS[step] then
			local pen = myPen()
			target = pen and pen:FindFirstChild("Area") and pen.Area.Position
		end
	end
	pointTo(target)
end

-- Landed on a lassoed animal: on to the egg.
function Tutorial.lassoed()
	if Tutorial.active and step == "lasso" then
		setStep("egg")
	end
end

-- What Ride's guide arrows point at on the way out: the nearest animal ahead
-- while "Lasso an animal" is up (and no egg is takeable then), the nearest egg
-- while "Take an egg!" is, and nothing in the other steps. Outside the tutorial,
-- always the egg.
function Tutorial.guideTo()
	if not Tutorial.active then
		return "egg"
	elseif step == "lasso" then
		return "animal"
	elseif step == "egg" or step == "take" then
		return "egg"
	end
	return nil
end

-- Once, from Ride: the tutorial runs while the "Tutorial" attribute is set.
function Tutorial.init()
	local function refresh()
		local on = Config.Tutorial and player:GetAttribute("Tutorial") == true
		if on ~= Tutorial.active then
			Tutorial.active = on
			step, failed, done, goalText = "place", false, false, nil
			if on then
				newPet = nil
				report("place")
			end
		end
	end
	player:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	refresh()
end

return Tutorial
