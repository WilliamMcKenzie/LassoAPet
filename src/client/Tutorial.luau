-- The first-time tutorial, for a player whose "Tutorial" attribute is set (the
-- server sets it for a new player, Hatchery). One hint at a time at the top of the
-- screen, a trail of glowing arrows on the ground to whatever the hint is about,
-- QM's golden cursor pulsing on whatever to click, and only the buttons each step
-- needs (Hud.setTutorial; Ride leaves out Sprint, Ability and the Hold bar):
--
--   1. place "Place your egg in your pen!"  only the inventory, holding your first
--                                            egg; the cursor pulses on it, then once
--                                            it's picked shows the drag into the pen.
--                                            It hatches at once (Config.TutorialHatchTime)
--   2. ride  "Ride your Horse!"              arrows to it; the cursor on RIDE
--   3. lasso "Press E to LASSO a new ride!"  time slows while an animal is in reach
--   4. egg   "Follow the arrows..."          the egg guide; the first Meadow nest
--                                            always holds a Config.TutorialEgg
--   5. take  "Press E to take the egg!"      time slows while it's in reach
--   6. home  (DODGE THE STAMPEDE!)           home with the egg, and that's it: the
--                                            egg's in the inventory, as before
--
-- A failed ride goes back to step 2. Until it's done the stampede runs on your
-- own clock (Ride), so slowing it down never snaps it back.
--
-- Ride drives it: Tutorial.update(state) every frame, Tutorial.lassoed() on
-- landing on a lassoed animal, and reads Tutorial.active / Tutorial.slowMo /
-- Tutorial.nest.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Hud = require(script.Parent.Hud)
local Inventory = require(script.Parent.Inventory)
local PenPets = require(script.Parent.PenPets)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local world = workspace:WaitForChild("World")

local Tutorial = {}
Tutorial.active = false -- the tutorial is running: the "Tutorial" attribute is set
Tutorial.slowMo = nil -- a time scale while LASSO or TAKE EGG waits for its press
Tutorial.nest = nil -- the first Meadow nest: while it's empty, this player sees a TutorialEgg in it

local CURSOR = "rbxassetid://89545604097968" -- assets/ui/GoldenCursor.png
local CURSOR_SIZE = 72 -- on a REFERENCE_WIDTH-wide screen, like the HUD
local REFERENCE_WIDTH = 1320
local DRAG_TIME = 2 -- seconds per go of the drag from the inventory to the pen

local step = "place"
local failed = false -- the ride ended in a crash or buck-off
local lastPhase = "idle"
local onChange -- Ride's: shows or hides the nest's tutorial egg
local hudTutorial = false -- what the HUD was last told (Hud.setTutorial)
local done = false -- TutorialDone sent

-- The first Meadow nest: the one nearest the start line.
do
	local best = -math.huge
	for _, nest in world:WaitForChild("Nests"):GetChildren() do
		local spot = nest:FindFirstChild("EggSpot")
		local z = spot and spot.Position.Z
		if z and WorldColors.biomeAt(z) == 1 and z > best then
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
hint.Position = UDim2.fromScale(0.5, 0.25)
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
gui.Parent = player:WaitForChild("PlayerGui")

-- QM's golden cursor: its tip on the spot to click, pulsing like a click.
local cursor = Instance.new("ImageLabel")
cursor.Name = "Cursor"
cursor.BackgroundTransparency = 1
cursor.Image = CURSOR
cursor.AnchorPoint = Vector2.new(0.16, 0.06) -- the tip, in the picture
cursor.ZIndex = 10
cursor.Visible = false
local cursorScale = Instance.new("UIScale")
cursorScale.Parent = cursor
cursor.Parent = gui
local function resizeCursor()
	local size = math.round(CURSOR_SIZE * camera.ViewportSize.X / REFERENCE_WIDTH)
	cursor.Size = UDim2.fromOffset(size, size)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeCursor)
resizeCursor()

-- A point a little below and right of a button's middle, so the button still shows.
local function onButton(button)
	return button.AbsolutePosition + button.AbsoluteSize * 0.6
end

-- Where `world` is on screen, kept inside it.
local function onScreen(world)
	local at, ahead = camera:WorldToViewportPoint(world)
	local size = camera.ViewportSize
	if not ahead then
		at = Vector3.new(size.X - at.X, size.Y, 0) -- behind you: from the bottom edge
	end
	return Vector2.new(math.clamp(at.X, 40, size.X - 40), math.clamp(at.Y, 40, size.Y - 40))
end

-- Each frame: `at` (screen pixels) pulsing, or nil to hide it. pressed scales it
-- down, as if held.
local function showCursor(at, pressed)
	cursor.Visible = at ~= nil
	if at then
		cursor.Position = UDim2.fromOffset(at.X, at.Y)
		cursorScale.Scale = if pressed then 0.85 else 1 - 0.12 * (0.5 + 0.5 * math.sin(os.clock() * math.pi * 3))
	end
end

-- The drag from the inventory to the pen, over and over: press on the slot, carry
-- it across held down, then click in the pen.
local function showDrag(from, to)
	local t = (os.clock() % DRAG_TIME) / DRAG_TIME
	if t < 0.15 then
		showCursor(from, t > 0.08)
	elseif t < 0.7 then
		local k = (t - 0.15) / 0.55
		k = k * k * (3 - 2 * k) -- ease in and out
		showCursor(from:Lerp(to, k), true)
	else
		showCursor(to, t > 0.8 and t < 0.88)
	end
end

local shown = "" -- the hint's text when it's showing
local pulse = TweenService:Create(hintScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.06 })
local pop -- the pop-in tween, which starts the pulse when it's done
local function setHint(text)
	text = text or ""
	if text == shown then
		return
	end
	shown = text
	hint.Text = text
	hint.Visible = text ~= ""
	pulse:Cancel()
	if pop then
		pop:Cancel()
	end
	if text ~= "" then
		hintScale.Scale = 0
		pop = TweenService:Create(hintScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 })
		pop.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and shown == text then
				pulse:Play()
			end
		end)
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

local function eggTool()
	for _, holder in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		for _, tool in holder and holder:GetChildren() or {} do
			if tool:IsA("Tool") and tool:GetAttribute("EggKind") then
				return tool
			end
		end
	end
	return nil
end

-- Your pet to ride: the one waiting in the pen (Ride's starter), else the first
-- egg's pet where it hatched.
local function myPet(state)
	if state.pet then
		return state.pet, player:GetAttribute("RidePet")
	end
	for model, info in PenPets.pets do
		if model.Parent then
			return model, info.kind
		end
	end
	return nil, nil
end

local function setStep(name)
	if name == step then
		return
	end
	step = name
	if name == "ride" and onChange then
		onChange() -- the nest's egg is back for another go
	end
end

local function hintFor(state)
	local phase = state.phase
	if phase == "ended" then
		return "Oops! Press HOME to try again."
	elseif step == "place" then
		return "Place your egg in your pen!"
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
	if Tutorial.active ~= hudTutorial then
		hudTutorial = Tutorial.active
		Hud.setTutorial(hudTutorial)
	end
	if not Tutorial.active then
		Tutorial.slowMo = nil
		setHint(nil)
		showCursor(nil)
		beam.Enabled = false
		lastPhase = phase
		return
	end
	if phase ~= "idle" then
		failed = failed or phase == "ended"
		if step == "place" or step == "ride" then
			setStep("lasso")
		end
		if phase == "outbound" then
			if (step == "lasso" or step == "egg") and state.target == "egg" then
				setStep("take")
			end
		elseif phase == "turning" or phase == "return" then
			setStep("home")
		end
	elseif lastPhase ~= "idle" then
		-- Back home: with the egg, that's the tutorial done; otherwise another go.
		if not failed and step == "home" and not done then
			done = true
			ReplicatedStorage:WaitForChild("TutorialDone"):FireServer() -- clears the attribute: Tutorial.init's refresh ends it
		elseif step ~= "place" then
			setStep("ride")
		end
		failed = false
	end
	lastPhase = phase

	if step == "place" and ((player:GetAttribute("RidePet") or "") ~= "" or next(PenPets.pets) ~= nil) then
		setStep("ride") -- it's hatched (or there was a pet already)
	end

	local slow = (step == "lasso" and typeof(state.target) == "table" and not state.transfer)
		or (step == "take" and state.target == "egg")
	Tutorial.slowMo = if slow and phase == "outbound" then Config.TutorialSlowMo else nil

	setHint(if state.cutscene then nil else hintFor(state))

	-- The cursor: on the button to press, or the egg's drag into the pen.
	local button = if phase == "ended" then Hud.button("home")
		elseif step == "ride" and phase == "idle" then Hud.button("ride")
		elseif Tutorial.slowMo then Hud.button("action")
		else nil
	if button then
		showCursor(onButton(button))
	elseif step == "place" and phase == "idle" then
		local tool = eggTool()
		local slot = tool and Inventory.slotOf(tool)
		local pen = myPen()
		local area = pen and pen:FindFirstChild("Area")
		if slot and area and tool.Parent == player.Character then
			showDrag(onButton(slot), onScreen(area.Position))
		else
			showCursor(if slot then onButton(slot) else nil)
		end
	else
		showCursor(nil)
	end

	local target
	if phase == "idle" then
		if step == "ride" then
			local pet = myPet(state)
			target = pet and pet.PrimaryPart and pet.PrimaryPart.Position
		elseif step == "place" then
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

-- changed() is called whenever the nest's tutorial egg should show or go.
function Tutorial.init(changed)
	onChange = changed
	local function refresh()
		local on = Config.Tutorial and player:GetAttribute("Tutorial") == true
		if on ~= Tutorial.active then
			Tutorial.active = on
			step, failed, done = "place", false, false
			changed()
		end
	end
	player:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	refresh()
end

return Tutorial
