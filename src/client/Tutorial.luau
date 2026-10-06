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
--   3. lasso "Press E to LASSO a new ride!"  time slows while an animal is in reach
--   4. egg   "Follow the arrows..."          the egg guide; the first Meadow nest
--                                            always holds a Config.TutorialEgg
--   5. take  "Press E to take the egg!"      time slows while it's in reach
--   6. home  (DODGE THE STAMPEDE!)           home with the egg
--   7. place2 the egg goes into the pen by itself (Hatchery's DeliverEgg, balance
--            pass Oct 6: a fifth of new players left here when they had to place it).
--            Placing it starts the money: until now pets earn nothing (Hatchery)
--   8. goal  once that egg's hatched, the camera flies to the next biome's gate: "Save $1k to unlock the
--            Desert!". Then it's over and the rest of the HUD (Gold, Upgrade Pen,
--            Pets) comes back: none of it shows in the tutorial (QM).
--
-- A failed ride goes back to step 2. Until it's done the stampede runs on your
-- own clock (Ride), so slowing it down never snaps it back.
--
-- Ride drives it: Tutorial.update(state) every frame, Tutorial.lassoed() on
-- landing on a lassoed animal, and reads Tutorial.active / Tutorial.slowMo /
-- Tutorial.nest / Tutorial.busy.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local Inventory = require(script.Parent.Inventory)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local world = workspace:WaitForChild("World")

local Tutorial = {}
Tutorial.active = false -- the tutorial is running: the "Tutorial" attribute is set
Tutorial.slowMo = nil -- a time scale while LASSO or TAKE EGG waits for its press
Tutorial.nest = nil -- the first Meadow nest: while it's empty, this player sees a TutorialEgg in it
Tutorial.busy = false -- the ending's close-ups are on: no riding off

local HINT_Y = 0.25 -- the hint's height on screen (its middle, a share of the screen height)
local FAIL_HINT_Y = 0.1 -- on a fail screen: above the CRASH! / BUCKED OFF banner (Hud, at 0.3)
local GOAL_WAIT = 3.2 -- seconds after the egg hatches (Pen.client's hatch takes about 2.2) before the camera flies to the gate
local GATE_HOLD = 2.5 -- seconds the camera stays on the gate
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
local onChange -- Ride's: shows or hides the nest's tutorial egg
local hudStage = nil -- what the HUD was last told (Hud.setTutorial)
local done = false -- TutorialDone sent
local known = {} -- the pen's items when the ride home began: a new one is the egg brought home
local goalText -- "Save $1k to unlock the Desert!", once the close-ups start
local goalDesert = false -- and it's that one, which QM drew (PICTURES.saveDesert)

-- The first Meadow nest: the one nearest the start line. Not the EventNest
-- (Events.server), parked under the start line between events: picked, the
-- tutorial egg sat 500 studs down there and TAKE EGG came up on leaving home.
do
	local best = -math.huge
	for _, nest in world:WaitForChild("Nests"):GetChildren() do
		local spot = nest:FindFirstChild("EggSpot")
		local z = spot and spot.Position.Z
		if z and nest.Name ~= "EventNest" and WorldColors.biomeAt(z) == 1 and z > best then
			Tutorial.nest, best = nest, z
		end
	end
end

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
	saveDesert = { image = "rbxassetid://116651352653628", width = 1733, height = 127 }, -- assets/ui/HintSaveDesert.png
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
		table.insert(images, entry.image)
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

-- Shows the hint picture called `name` (nil: none), and the cursor over `tool`'s
-- square if there's a tool.
local function showPicture(name, tool)
	local entry = name and PICTURES[name]
	if entry ~= pictureShown then
		pictureShown = entry
		picture.Image = if entry then entry.image else ""
		sizePicture()
	end
	local slot = tool and Inventory.slot(tool.Name)
	picture.Visible = entry ~= nil
	cursor.Visible = slot ~= nil
	local wave = math.sin(os.clock() * 2 * math.pi / THROB_TIME)
	pictureScale.Scale = 1 + THROB * wave
	cursorScale.Scale = 1 + CURSOR_THROB * wave
	if slot then
		local at, size = slot.AbsolutePosition - gui.AbsolutePosition, slot.AbsoluteSize -- (gui's is above 0 by the top bar)
		cursor.Position = UDim2.fromOffset(at.X + CURSOR_AT.X * size.X, at.Y + CURSOR_AT.Y * size.Y)
		cursor.Size = UDim2.fromOffset(CURSOR_SIZE * size.X, CURSOR_SIZE * size.X)
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
	if name == "ride" and onChange then
		onChange() -- the nest's egg is back for another go
	elseif name == "home" then
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

-- The ending: once the egg placed (`id` in the pen) has hatched and its pet
-- jumped out, the camera flies over to the next biome's gate and back, and it's over.
local function showGoal(id)
	Tutorial.busy = true
	while contents()[id] and contents()[id].egg do
		task.wait(0.2)
	end
	task.wait(GOAL_WAIT)
	controls:Disable()
	local level = player:GetAttribute("PenLevel") or 1
	local upNext = Config.Biomes[level + 1]
	if upNext then
		goalText = "Save " .. Hud.money(upNext.UnlockCost) .. " to unlock the " .. upNext.Name .. "!"
		goalDesert = upNext.Name == "Desert" and upNext.UnlockCost == 1000
		report("gate")
		local gateZ = WorldColors.gateZ(level)
		local start = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
		local view = CFrame.lookAt(Vector3.new(0, 40, gateZ + 70), Vector3.new(0, 8, gateZ))
		local out = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = view })
		out:Play()
		out.Completed:Wait()
		task.wait(GATE_HOLD)
		local back = TweenService:Create(camera, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = start })
		back:Play()
		back.Completed:Wait()
		camera.CameraType = Enum.CameraType.Custom
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
	local stage = if Tutorial.active then "bare" else nil
	if stage ~= hudStage then
		hudStage = stage
		Hud.setTutorial(stage)
	end
	if not Tutorial.active then
		Tutorial.slowMo = nil
		setHint(nil)
		showPicture(nil)
		beam.Enabled = false
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
				if (step == "lasso" or step == "egg") and state.target == "egg" then
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
				setStep("goal") -- placed: the money starts
				task.spawn(showGoal, id)
				break
			end
		end
	end

	local slow = (step == "lasso" and typeof(state.target) == "table" and not state.transfer)
		or (step == "take" and state.target == "egg")
	Tutorial.slowMo = if slow and phase == "outbound" then Config.TutorialSlowMo else nil

	local clickTool = if step == "place" and phase == "idle" and not state.cutscene then eggToClick() else nil
	local pictureName = if state.cutscene or phase == "ended" then nil
		elseif phase ~= "idle" then (if step == "lasso" then "lasso" elseif step == "egg" or step == "take" then "takeEgg" else nil)
		elseif clickTool then "click"
		elseif PLACE_STEPS[step] then "place"
		elseif step == "ride" and select(2, myPet(state)) == "Horse" then "rideHorse"
		elseif step == "goal" and goalText and goalDesert then "saveDesert"
		else nil
	showPicture(pictureName, clickTool)
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
-- while "Lasso an animal" is up, the nearest egg while "Take an egg!" is, and
-- nothing in the other steps. Outside the tutorial, always the egg.
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

-- changed() is called whenever the nest's tutorial egg should show or go.
function Tutorial.init(changed)
	onChange = changed
	local function refresh()
		local on = Config.Tutorial and player:GetAttribute("Tutorial") == true
		if on ~= Tutorial.active then
			Tutorial.active = on
			step, failed, done, goalText = "place", false, false, nil
			if on then
				report("place")
			end
			changed()
		end
	end
	player:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	refresh()
end

return Tutorial
