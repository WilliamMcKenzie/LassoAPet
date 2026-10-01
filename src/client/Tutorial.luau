-- The first-time tutorial, for a player whose "Tutorial" attribute is set (the
-- server sets it for a new player, Hatchery). One hint at a time at the top of the
-- screen, and a trail of glowing arrows on the ground (like the egg guide) to
-- whatever the hint is about:
--
--   1. ride  "Hop on your Horse!"          arrows to your pet
--   2. dodge "Steer to dodge the rocks!"   (the first ride)
--   3. lasso "Press E to LASSO..."         time slows while an animal is in reach
--   4. egg   "Follow the arrows..."        the egg guide; the first Meadow nest
--                                          always holds a Config.TutorialEgg
--   5. take  "Press E to take the egg!"    time slows while it's in reach
--   6. home  "Dodge the stampede!..."
--   7. place "Click your pen..."           the egg is put in your hand; arrows to the pen
--   8. hatch (Config.TutorialHatchTime)
--   9. earn  "Pets earn you gold!"         arrows to the new pet
--  10. goal  "Save $1k to unlock the Desert!"  the camera flies over to the Desert's gate
--
-- A failed ride goes back to step 1. Until it's done the stampede runs on your
-- own clock (Ride), so slowing it down never snaps it back.
--
-- Ride drives it: Tutorial.update(state) every frame, Tutorial.lassoed() on
-- landing on a lassoed animal, and reads Tutorial.active / Tutorial.slowMo /
-- Tutorial.nest.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local world = workspace:WaitForChild("World")

local Tutorial = {}
Tutorial.active = false -- the tutorial is running: the "Tutorial" attribute is set
Tutorial.slowMo = nil -- a time scale while LASSO or TAKE EGG waits for its press
Tutorial.nest = nil -- the first Meadow nest: while it's empty, this player sees a TutorialEgg in it

local EARN_TIME = 4 -- seconds on "Pets earn you gold!"
local GOAL_HOLD = 4 -- seconds the goal hint stays after the camera's back
local RIDE_STEPS = { ride = true, dodge = true, lasso = true, egg = true, take = true, home = true }

local step = "ride"
local failed = false -- the ride ended in a crash or buck-off
local lastPhase = "idle"
local onChange -- Ride's: shows or hides the nest's tutorial egg
local eggIds = {} -- the eggs placed in the pen during "place", waiting to hatch
local earnAt, petSpot, goalStarted, eggHeld

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

-- The hint: white text with a black outline, top centre, breathing gently.
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
hint.TextScaled = true
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
	stroke.Thickness = math.max(2, math.round(camera.ViewportSize.X / 320))
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
resize()
gui.Parent = player:WaitForChild("PlayerGui")

local shown = "" -- the hint's text when it's showing
local popAt = 0
local function setHint(text)
	text = text or ""
	if text == shown then
		return
	end
	shown = text
	hint.Text = text
	hint.Visible = text ~= ""
	popAt = os.clock()
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

-- Puts an egg in your hand once, so the pen shows where it'll go (Pen.client).
-- The egg reaches the inventory a moment after the ride gets home.
local function holdEgg()
	local tool = eggTool()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if tool and humanoid then
		if tool.Parent ~= player.Character then
			humanoid:EquipTool(tool)
		end
		eggHeld = true
	end
end

local function finish()
	ReplicatedStorage:WaitForChild("TutorialDone"):FireServer() -- clears the attribute: Tutorial.init's refresh ends it
end

-- The camera flies over to the Desert's gate ("LV. 2 REQUIRED") and back.
local function showGoal()
	local gateZ = WorldColors.gateZ(player:GetAttribute("PenLevel"))
	if gateZ == -math.huge or lastPhase ~= "idle" then
		task.wait(GOAL_HOLD)
		finish()
		return
	end
	local start = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	controls:Disable()
	local view = CFrame.lookAt(Vector3.new(0, 40, gateZ + 70), Vector3.new(0, 8, gateZ))
	local out = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = view })
	out:Play()
	out.Completed:Wait()
	task.wait(2.5)
	if lastPhase == "idle" then
		local back = TweenService:Create(camera, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = start })
		back:Play()
		back.Completed:Wait()
	end
	if lastPhase == "idle" then
		camera.CameraType = Enum.CameraType.Custom
		controls:Enable()
	end
	task.wait(GOAL_HOLD)
	finish()
end

local function setStep(name)
	if name == step then
		return
	end
	step = name
	if name == "ride" and onChange then
		onChange() -- the nest's egg is back for another go
	elseif name == "place" then
		eggHeld = false
	elseif name == "earn" then
		earnAt = os.clock()
	end
end

local function hintFor(state)
	local phase = state.phase
	if phase == "ended" then
		return "Oops! Press HOME to try again."
	elseif step == "ride" then
		return "Hop on your " .. (player:GetAttribute("RidePet") or Config.DefaultPet) .. "!"
	elseif step == "dodge" then
		return "Steer to dodge the rocks!"
	elseif step == "lasso" then
		return if touch() then "Tap LASSO to jump on!" else "Press E to LASSO a new ride!"
	elseif step == "egg" then
		return "Follow the arrows to the egg!"
	elseif step == "take" then
		return if touch() then "Tap TAKE EGG!" else "Press E to take the egg!"
	elseif step == "home" then
		return "Dodge the stampede! Get home!"
	elseif phase ~= "idle" then
		return nil -- out riding again before the egg's hatched
	elseif step == "place" then
		return if touch() then "Tap your pen to place your egg!" else "Click your pen to place your egg!"
	elseif step == "hatch" then
		return "Your egg is hatching..."
	elseif step == "earn" then
		return "Pets earn you gold!"
	elseif step == "goal" then
		local upNext = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
		return if upNext then "Save " .. Hud.money(upNext.UnlockCost) .. " to unlock the " .. upNext.Name .. "!" else nil
	end
	return nil
end

-- Every frame, from Ride. state = { phase, target ("egg", an animal or nil: what
-- LASSO / TAKE EGG would grab), pet (the model RIDE rides at home), transfer
-- (being pulled across to a lassoed animal), cutscene (the egg close-up or a
-- hero leap is on) }.
function Tutorial.update(state)
	local phase = state.phase
	if not Tutorial.active then
		Tutorial.slowMo = nil
		setHint(nil)
		beam.Enabled = false
		lastPhase = phase
		return
	end
	if phase ~= "idle" then
		failed = failed or phase == "ended"
		if step == "ride" then
			setStep("dodge")
		end
		if phase == "outbound" then
			if step == "dodge" and typeof(state.target) == "table" then
				setStep("lasso")
			elseif (step == "dodge" or step == "lasso" or step == "egg") and state.target == "egg" then
				setStep("take")
			end
		elseif (phase == "turning" or phase == "return") and RIDE_STEPS[step] then
			setStep("home")
		end
	elseif lastPhase ~= "idle" then
		-- Back home: with the egg, on to placing it; otherwise another go.
		if RIDE_STEPS[step] then
			setStep(if not failed and step == "home" then "place" else "ride")
		end
		failed = false
	end
	lastPhase = phase

	if step == "place" then
		if not eggHeld and phase == "idle" then
			holdEgg()
		end
		for id, item in contents() do
			if item.egg then
				eggIds[id] = true
			end
		end
		if next(eggIds) then
			setStep("hatch")
		end
	elseif step == "hatch" then
		local pen = myPen()
		local area = pen and pen:FindFirstChild("Area")
		for id, item in contents() do
			if eggIds[id] and item.pet then
				petSpot = if area then area.Position + Vector3.new(item.x, 0, item.z) else nil
				setStep("earn")
			end
		end
	elseif step == "earn" and os.clock() - earnAt > EARN_TIME then
		setStep("goal")
	end
	if step == "goal" and not goalStarted and phase == "idle" then
		goalStarted = true
		task.spawn(showGoal)
	end

	local slow = (step == "lasso" and typeof(state.target) == "table" and not state.transfer)
		or (step == "take" and state.target == "egg")
	Tutorial.slowMo = if slow and phase == "outbound" then Config.TutorialSlowMo else nil

	setHint(if state.cutscene then nil else hintFor(state))
	hintScale.Scale = math.min((os.clock() - popAt) / 0.15, 1) * (1 + 0.04 * math.sin(os.clock() * math.pi * 2))
	local target
	if phase == "idle" then
		if step == "ride" then
			target = state.pet and state.pet.PrimaryPart and state.pet.PrimaryPart.Position
		elseif step == "place" then
			local pen = myPen()
			target = pen and pen:FindFirstChild("Area") and pen.Area.Position
		elseif step == "earn" then
			target = petSpot
		end
	end
	pointTo(target)
end

-- Landed on a lassoed animal: on to the egg.
function Tutorial.lassoed()
	if Tutorial.active and (step == "dodge" or step == "lasso") then
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
			step, failed, goalStarted, eggHeld = "ride", false, nil, nil
			table.clear(eggIds)
			changed()
		end
	end
	player:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
	refresh()
end

return Tutorial
