-- Your Slingshot (Config.Slingshot, QM Nov 6: Server/Slingshot stands it in front of your
-- pen): walk up to its band and hold E. You and your best pet (Ride's fastest at home) are
-- pulled back on the band, flung over the course and land at the start of biome To (the
-- Desert), riding that pet from there (SlingshotRide.ride: Ride.client's startRide).
-- The bands move on your screen only (Shared/SlingshotPose); the flight is a curve from
-- where the band lets you go, Apex studs up at its middle, Flight seconds long.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local SlingshotPose = require(ReplicatedStorage.Shared.SlingshotPose)
local SlingshotRide = require(script.Parent.SlingshotRide)
local Hud = require(script.Parent.Hud)

local CFG = Config.Slingshot
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local LOAD = Vector3.new(0, 1.6, 17) -- (SlingshotPose's resting pull: where you step on)
local FEET = -1.45 -- your pet's feet under the pull
local SEAT = 2.2 -- your root over your pet's back
local CAM_LAUNCH = Vector3.new(16, 14, 44) -- the camera, in the slingshot's space, while it draws
local CAM_BACK, CAM_UP = 34, 12 -- then behind and over you in the air

local busy = false

-- The slingshot's own frame: its Frame1 part, built at the model's origin, so its CFrame is
-- where the server stood it (a client may not have the Model's WorldPivot).
local function baseOf(model)
	local frame = model:FindFirstChild("Frame1")
	return if frame then frame.CFrame else model:GetPivot()
end

local function character()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and humanoid and humanoid.Health > 0 then
		return hrp, humanoid
	end
	return nil
end

-- A stand-in of your pet to fly with (the real one rides from the landing).
local function petCopy(model)
	local copy = model:Clone()
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	local box, size = copy:GetBoundingBox()
	copy.Parent = workspace
	return copy, box:ToObjectSpace(copy:GetPivot()), size
end

local function restore(hrp, humanoid)
	if hrp then
		hrp.Anchored = false
	end
	if humanoid then
		humanoid.Sit = false
	end
	controls:Enable()
	camera.CameraType = Enum.CameraType.Custom
end

local function launch(model)
	if busy or Hud.isRiding() then
		return
	end
	local hrp, humanoid = character()
	local best = SlingshotRide.bestPet and SlingshotRide.bestPet()
	if not hrp or not best then
		return
	end
	busy = true
	local base = baseOf(model)
	local pet, rel, size = petCopy(best)
	-- your pet stands against the band (its back end on it), you on its back
	local function hold(pull)
		local body = pull * CFrame.new(0, FEET + size.Y / 2, -size.Z / 2)
		pet:PivotTo(body * rel)
		hrp.CFrame = body * CFrame.new(0, size.Y / 2 + SEAT, 0)
		return body
	end
	controls:Disable()
	hrp.Anchored = true
	humanoid.Sit = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt((base * CFrame.new(CAM_LAUNCH)).Position, (base * CFrame.new(0, 8, 4)).Position)

	local landing = Vector3.new(0, 0, WorldColors.biomeStart(CFG.To) - 10)
	local flown = false
	local function fly(pull)
		local from = hold(pull)
		local p0 = from.Position
		local p2 = Vector3.new(landing.X, p0.Y - pull.Position.Y + landing.Y, landing.Z)
		local p1 = (p0 + p2) / 2 + Vector3.new(0, 2 * CFG.Apex, 0) -- (a quadratic curve's middle is half way to this)
		local t0 = os.clock()
		while true do
			local u = math.min((os.clock() - t0) / CFG.Flight, 1)
			local a, b = p0:Lerp(p1, u), p1:Lerp(p2, u)
			local at = a:Lerp(b, u)
			local ahead = (b - a)
			local body = CFrame.lookAt(at, at + (if ahead.Magnitude > 0.01 then ahead else -Vector3.zAxis))
			pet:PivotTo(body * rel)
			hrp.CFrame = body * CFrame.new(0, size.Y / 2 + SEAT, 0)
			local flat = Vector3.new(ahead.X, 0, ahead.Z)
			local back = if flat.Magnitude > 0.01 then flat.Unit else -Vector3.zAxis
			camera.CFrame = CFrame.lookAt(at - back * CAM_BACK + Vector3.new(0, CAM_UP, 0), at)
			if u >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		pet:Destroy()
		hrp.CFrame = CFrame.new(landing + Vector3.new(0, 3, 0))
		local riding = SlingshotRide.ride and SlingshotRide.ride(landing.X, landing.Z)
		if not riding then
			restore(hrp, humanoid)
		end
		flown = true
	end

	SlingshotPose.launch(model, hold, function(pull)
		fly(pull)
	end, base)
	while not flown do
		task.wait()
	end
	busy = false
end

-- The prompt on your own slingshot's band, where it rests.
local function setup(model)
	local owner = model:GetAttribute("Owner") or tonumber(model.Name) -- (the server names it by its owner's UserId too)
	if owner ~= player.UserId or model:FindFirstChild("LaunchSpot", true) then
		return
	end
	local frame = model:WaitForChild("Frame1", 30)
	if not frame then
		return
	end
	local spot = Instance.new("Attachment")
	spot.Name = "LaunchSpot"
	spot.CFrame = CFrame.new(LOAD + Vector3.new(0, 2, 0)) -- (Frame1 sits at the slingshot's pivot)
	spot.Parent = frame
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Launch"
	prompt.ActionText = "Launch"
	prompt.ObjectText = "Slingshot"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.6
	prompt.Style = Enum.ProximityPromptStyle.Custom -- (Roblox's look without its panel: PromptUi)
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
	prompt.Triggered:Connect(function()
		if not (SlingshotRide.bestPet and SlingshotRide.bestPet()) then
			-- (no pet at home to fly with: say so on the prompt for a moment)
			prompt.ObjectText = "Bring a pet home first!"
			task.delay(2, function()
				prompt.ObjectText = "Slingshot"
			end)
			return
		end
		launch(model)
	end)
	task.spawn(function()
		while model.Parent do
			prompt.Enabled = not busy and not Hud.isRiding()
			task.wait(0.25)
		end
	end)
end

local folder = workspace:WaitForChild("Slingshots")
folder.ChildAdded:Connect(setup)
for _, model in folder:GetChildren() do
	task.spawn(setup, model)
end
