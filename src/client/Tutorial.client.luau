-- The first-time tutorial (QM, Oct 11), after the intro (Client/Intro). One thing at a
-- time, no text: a tap hand on what to touch, arrows on the ground to where to go, and
-- only the UI each step needs (BaseUi stays hidden, the HUD is "bare": Hud.setTutorial).
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
--             the camera flies to the Desert's gate (the next goal) and back. Done:
--             TutorialDone, and the rest of the UI comes back.
--
-- A ride that comes home with nothing goes back to step 3. Runs whenever the "Tutorial"
-- attribute is on (a new player, or "/tutorial").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Hud = require(script.Parent.Hud)
local PenPets = require(script.Parent.PenPets)
local Inventory = require(script.Parent.Inventory)
local TutorialRide = require(script.Parent.TutorialRide)
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TAP = "rbxassetid://134865745295413" -- assets/ui/TapHand.png (QM's)
local TAP_SIZE = 96 -- px tall (it's 488 x 610)
local TAP_TIP = Vector2.new(0.365, 0.03) -- the fingertip, in the picture
local SPRINT_GUIDE = { id = "rbxassetid://109145650505243", size = Vector2.new(1923, 77) } -- assets/ui/SprintGuide.png (QM)
local SLOW_FLOOR = 0.02 -- the slow-down's bottom (x speed): all but stopped
local SLOW_TIME = 0.5 -- seconds into the slow-down for its middle (the sigmoid's)
local SLOW_STEEP = 9 -- how sharp its turn is
local WAIT_FOR_BOSS = 5 -- seconds after you sprint till BOSS IN shows (QM)
local BOSS_SECONDS = 5 -- and how long it gives you
local GATE_HOLD = 2.5 -- seconds the camera stays on the Desert's gate
local NEW_PET_WAIT = 12 -- seconds after a ride for its egg to hatch in your pen

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace:FindFirstChild("Pens") and workspace.Pens:FindFirstChild("Pen" .. index)
end

local function hrp()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function funnel(step)
	local remote = ReplicatedStorage:FindFirstChild("FunnelStep")
	if remote then
		remote:FireServer(step)
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
local sprintGuide = Instance.new("ImageLabel")
sprintGuide.BackgroundTransparency = 1
sprintGuide.Image = SPRINT_GUIDE.id
sprintGuide.AnchorPoint = Vector2.new(0.5, 0)
sprintGuide.Position = UDim2.fromScale(0.5, 0.12)
sprintGuide.Size = UDim2.fromScale(1, 1)
local guideRatio = Instance.new("UIAspectRatioConstraint")
guideRatio.AspectRatio = SPRINT_GUIDE.size.X / SPRINT_GUIDE.size.Y
guideRatio.Parent = sprintGuide
sprintGuide.Visible = false
sprintGuide.Parent = gui

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

RunService.RenderStepped:Connect(function()
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
		if m:IsA("Model") and m.Name:match("Egg$") then
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
	pointAt(nil)
	guide(nil)
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

-- The camera flies up and over to the Desert's gate, holds on it, and comes back.
local function showGate()
	local gateZ = -Config.Biomes[1].Length
	local look = Vector3.new(0, 10, gateZ)
	local view = CFrame.lookAt(look + Vector3.new(0, 26, 80), look)
	local was, wasType = camera.CFrame, camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	player:SetAttribute("Cutscene", true)
	local high = was + Vector3.new(0, 60, 0)
	local function fly(a, b, c, time)
		local t = 0
		while t < time do
			t += RunService.RenderStepped:Wait()
			local u = math.clamp(t / time, 0, 1)
			u = u * u * (3 - 2 * u)
			local p = a.Position:Lerp(b.Position, u):Lerp(b.Position:Lerp(c.Position, u), u)
			camera.CFrame = CFrame.new(p) * a.Rotation:Lerp(c.Rotation, u)
		end
	end
	fly(was, high, view, 1.6)
	task.wait(GATE_HOLD)
	fly(view, high, was, 1.3)
	camera.CameraType = wasType
	player:SetAttribute("Cutscene", nil)
end

local running = false
local function run()
	if running then
		return
	end
	running = true
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

	-- 1. Place your egg.
	while on() and not penEgg() and #myPets() == 0 do
		local tool, held = eggTool()
		local pen = myPen()
		local area = pen and pen:FindFirstChild("Area")
		if tool and not held then
			pointAt(Inventory.slot(tool.Name))
			guide(nil)
		elseif tool and held and area then
			pointAt(area.Position + Vector3.new(0, area.Size.Y / 2 + 1, 0))
			guide(area.Position)
		else
			pointAt(nil)
		end
		task.wait(0.1)
	end

	while on() do
		-- 2. Hatch it, 3. ride it.
		while on() and not Hud.isRiding() do
			local egg = penEgg()
			local pets = myPets()
			pointAt(nil)
			if egg and #pets == 0 then
				guide(egg)
			elseif #pets > 0 then
				guide(pets[1])
			else
				guide(nil)
			end
			task.wait(0.15)
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
		local firstThrow, firstMount = TutorialRide.throws, TutorialRide.mounts
		-- Till your first lasso: time all but stops while an animal's in reach. (The
		-- arrows go as soon as it's thrown: QM.)
		while on() and Hud.isRiding() and TutorialRide.throws <= firstThrow do
			if TutorialRide.canLasso then
				slowUntil(function()
					return TutorialRide.throws > firstThrow or not TutorialRide.canLasso
				end)
			end
			RunService.Heartbeat:Wait()
		end
		player:SetAttribute("LassoGuide", nil)
		-- (and the sprint step waits for you to land on it, or a miss)
		local thrown = os.clock()
		while on() and Hud.isRiding() and TutorialRide.mounts <= firstMount and os.clock() - thrown < 3 do
			task.wait(0.1)
		end
		funnel("lasso")
		player:SetAttribute("NoSprint", nil)
		-- Then sprinting: a computer gets QM's guide, and time slows till Shift.
		if on() and Hud.isRiding() and UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
			sprintGuide.Visible = true
			task.wait(0.4)
			local nextLog = os.clock() + 2
			slowUntil(function()
				local key = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
				if os.clock() > nextLog then -- (QM, Oct 11: Shift didn't end it once; this says why, in the Output)
					nextLog = os.clock() + 2
					print("[Tutorial] waiting to sprint: Shift down", key, "Ride sprinting", TutorialRide.sprinting, "NoSprint", player:GetAttribute("NoSprint"))
				end
				return TutorialRide.sprinting or key
			end)
			sprintGuide.Visible = false
		end
		-- A few more seconds, then BOSS IN, short.
		local waitStart = os.clock()
		while on() and Hud.isRiding() and os.clock() - waitStart < WAIT_FOR_BOSS do
			task.wait(0.1)
		end
		TutorialRide.bossSeconds, TutorialRide.holdFrozen = BOSS_SECONDS, false
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
			funnel("home")
			task.wait(1)
			showGate()
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
