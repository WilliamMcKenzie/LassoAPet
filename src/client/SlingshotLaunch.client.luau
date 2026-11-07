-- Your Slingshot (Config.Slingshot, QM Nov 6: Server/Slingshot stands it in front of your
-- pen): walk up to its band and hold E, and pick a biome (Client/SlingshotMenu: the ones
-- you've unlocked, or unlock the next). You and your best pet (Ride's fastest at home) are
-- pulled back on the band, flung over the course and land at that biome's start, riding
-- that pet from there (SlingshotRide.ride: Ride.client's startRide).
-- The bands move on your screen only (Shared/SlingshotPose); the flight is a curve from
-- where the band lets you go, Apex studs up at its middle, Flight seconds long. In the air
-- you steer left and right as on the way out of your pen (Config.SteerSpeed, SteerResponse:
-- A/D, the arrows, a stick or a phone's joystick), and land where you've steered to.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local SlingshotPose = require(ReplicatedStorage.Shared.SlingshotPose)
local SlingshotRide = require(script.Parent.SlingshotRide)
local SlingshotMenu = require(script.Parent.SlingshotMenu)
local Hud = require(script.Parent.Hud)
local Sounds = require(script.Parent.Sounds)

local CFG = Config.Slingshot
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local controls = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()

local FEET = -1.45 -- your pet's feet under the pull
local SEAT = 2.2 -- your root over your pet's back
local CAM_LAUNCH = Vector3.new(16, 14, 44) -- the camera, in the slingshot's space, while it draws
local CAM_BACK, CAM_UP = 34, 12 -- then behind and over you in the air

local busy = false

-- Left/right in the air: -1..1 (the keys, and the move vector: a stick or a phone's joystick).
local function steerInput()
	local keys = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		keys -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		keys += 1
	end
	return math.clamp(keys + controls:GetMoveVector().X, -1, 1)
end

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
	SlingshotRide.flying = false
	controls:Enable()
	camera.CameraType = Enum.CameraType.Custom
end

local function launch(model, to, chosen)
	if busy or Hud.isRiding() then
		return
	end
	local hrp, humanoid = character()
	if chosen and not chosen.Parent then
		chosen = nil
	end
	local best = chosen or (SlingshotRide.bestPet and SlingshotRide.bestPet())
	if not hrp or not best then
		return
	end
	busy = true
	SlingshotRide.flying = true -- (Ride.client: you're not on foot, nothing throws you off)
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

	to = to or CFG.To
	local landing = Vector3.new(0, 0, WorldColors.biomeStart(to) - 10)
	local flown = false
	local function fly(pull)
		local from = hold(pull)
		local p0 = from.Position
		local p2 = Vector3.new(landing.X, p0.Y - pull.Position.Y + landing.Y, landing.Z)
		-- (a nearer biome: a lower shot; every shot takes exactly Flight seconds in the air)
		local far = Vector3.new(p2.X - p0.X, 0, p2.Z - p0.Z).Magnitude
		local apex = math.clamp(far / 8, 40, CFG.Apex)
		local flight = CFG.Flight
		local p1 = (p0 + p2) / 2 + Vector3.new(0, 2 * apex, 0) -- (a quadratic curve's middle is half way to this)
		-- steering: x off the curve, easing toward SteerSpeed x your input (as Ride's way out
		-- of your pen), kept inside the course where you land
		local side, latVel = 0, 0
		local room = math.max(WorldColors.halfWidth(landing.Z) - 8, 0)
		controls:Enable() -- (anchored: the move vector only steers, as Ride's rideStick)
		-- off the band: a whoosh, then the wind while you fly (speed lines and the white
		-- trail: Ride.client's, while SlingshotRide.flying)
		Sounds.play("sprint_tier", 1)
		Sounds.play("sprint_whoosh", 1)
		Sounds.setSprintWind(true, 2)
		local t0, last = os.clock(), os.clock()
		while true do
			local now = os.clock()
			local dt = math.min(now - last, 0.1)
			last = now
			local u = math.min((now - t0) / flight, 1)
			local nimble = CFG.Steer or 1
			latVel += (steerInput() * Config.SteerSpeed * nimble - latVel) * (1 - math.exp(-Config.SteerResponse * nimble * dt))
			side = math.clamp(side + latVel * dt, -room - landing.X, room - landing.X)
			local a, b = p0:Lerp(p1, u), p1:Lerp(p2, u)
			-- the lift (CFG.Lift): steeply up off the band, back to nothing by the landing
			local lift = CFG.Lift or 0
			local s = math.sin(math.pi * u)
			local at = a:Lerp(b, u) + Vector3.new(side, lift * s ^ 0.6, 0)
			local uc = math.clamp(u, 0.02, 0.98)
			local climb = lift * 0.6 * math.sin(math.pi * uc) ^ -0.4 * math.cos(math.pi * uc) * math.pi / flight
			local ahead = (b - a) * (2 / flight) + Vector3.new(latVel, climb, 0) -- (its velocity: facing the way it really goes)
			-- spinning: CFG.Spins whole barrel rolls, eased in and out, so you land upright
			local roll = 2 * math.pi * (CFG.Spins or 0) * (1 - math.cos(math.pi * u)) / 2
			local body = CFrame.lookAt(at, at + (if ahead.Magnitude > 0.01 then ahead else -Vector3.zAxis)) * CFrame.Angles(0, 0, roll)
			pet:PivotTo(body * rel)
			hrp.CFrame = body * CFrame.new(0, size.Y / 2 + SEAT, 0)
			local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			local back = if flat.Magnitude > 0.01 then flat.Unit else -Vector3.zAxis
			camera.CFrame = CFrame.lookAt(at - back * CAM_BACK + Vector3.new(0, CAM_UP, 0), at)
			if u >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		controls:Disable()
		pet:Destroy()
		Sounds.setSprintWind(false)
		Sounds.play("smash", 0.6)
		local x = landing.X + side
		hrp.CFrame = CFrame.new(x, landing.Y + 3, landing.Z)
		SlingshotRide.pet = chosen -- (Ride.client rides this one, not the fastest)
		local riding = SlingshotRide.ride and SlingshotRide.ride(x, landing.Z, to)
		SlingshotRide.pet = nil
		SlingshotRide.flying = false
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

-- The Launch prompt (a native ProximityPrompt the server puts on the slingshot, Server/Slingshot):
-- yours works; anyone else's is switched off on your screen.
local function setup(model)
	local owner = model:GetAttribute("Owner") or tonumber(model.Name) -- (the server names it by its owner's UserId too)
	local frame = model:WaitForChild("Frame1", 30)
	local prompt = frame and frame:WaitForChild("Launch", 30)
	if not prompt then
		return
	end
	if owner ~= player.UserId then
		prompt.Enabled = false
		return
	end
	prompt.Triggered:Connect(function()
		if busy or Hud.isRiding() then
			return
		end
		SlingshotMenu.open(function(to)
			if not (SlingshotRide.bestPet and SlingshotRide.bestPet()) then
				-- (no pet at home to fly with: say so on the prompt for a moment)
				prompt.ObjectText = "Bring a pet home first!"
				task.delay(2, function()
					prompt.ObjectText = "Slingshot"
				end)
				return
			end
			launch(model, to)
		end)
	end)
	task.spawn(function()
		while model.Parent do
			prompt.Enabled = not busy and not Hud.isRiding()
			-- (walked away from it, or riding: its menu goes)
			local hrp = character()
			if SlingshotMenu.atSlingshot() and (busy or Hud.isRiding() or not hrp or (hrp.Position - frame.Position).Magnitude > prompt.MaxActivationDistance + 14) then
				SlingshotMenu.close()
			end
			task.wait(0.25)
		end
	end)
end

local folder = workspace:WaitForChild("Slingshots")

-- Holding E on one of your pets after the tutorial (Ride.client, QM Nov 7): the same menu,
-- from wherever you are. Meadow rides that pet out of your pen as before; any other biome
-- flings you and that pet off your slingshot to it.
SlingshotRide.menu = function(pet, rideHere)
	if busy or Hud.isRiding() then
		return
	end
	local mine
	for _, model in folder:GetChildren() do
		if (model:GetAttribute("Owner") or tonumber(model.Name)) == player.UserId and model:FindFirstChild("Frame1") then
			mine = model
		end
	end
	if not mine then
		rideHere()
		return
	end
	SlingshotMenu.open(function(to)
		if to <= 1 then
			rideHere()
		else
			launch(mine, to, pet)
		end
	end, math.min(player:GetAttribute("PenLevel") or 1, #Config.Biomes), true) -- (scrolled to the farthest unlocked, the hand on its GO!: QM)
end
folder.ChildAdded:Connect(setup)
for _, model in folder:GetChildren() do
	task.spawn(setup, model)
end
