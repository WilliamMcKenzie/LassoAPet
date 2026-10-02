-- Eggs and pets in the pens, for every pen on the server.
--
-- The server (Hatchery) puts what's in each pen on the pen's "Contents"
-- attribute: JSON of { [id] = { x, z, egg, hatchAt } or { x, z, pet } }, x and z
-- from the centre of the pen's Area. This draws it: eggs with a countdown that
-- twitch now and then, the hatch (the egg shakes, its top pops off, the pet
-- jumps out onto the spot), and pets ambling around inside their pen.
--
-- It also runs placing: while an egg from your inventory is equipped, a
-- see-through egg follows the mouse over your pen; click or tap to put it down.
-- Your own pets go on PenPets' list, so RIDE (Ride.client) can ride any of them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Config = require(ReplicatedStorage.Shared.Config)
local PenPets = require(script.Parent.PenPets)

local player = Players.LocalPlayer
local placeEgg = ReplicatedStorage:WaitForChild("PlaceEgg")

local EGG_CENTER = 1.6 -- egg pivot height above the ground (Egg.luau)
local TOP_POPS = 1.58 -- seconds into the hatch animation when the top flies off
local JUMP_TIME = 0.6
local JUMP_HEIGHT = 5
local TWITCH_EVERY = { 3, 6 }
-- Same limits as the server's (Hatchery), so the ghost only shows where it can go.
local EDGE = 2
local WANDER_SPEED = 6 -- studs/s, a walk (same as the pet you ride, in Ride.client)
-- Pens further than this from the camera aren't animated (out on a ride, say):
-- their pets and eggs stand still until you're back, then carry on.
local FAR = 300
local rng = Random.new()

local folder = Instance.new("Folder")
folder.Name = "PenContents"
folder.Parent = workspace

local shown = {} -- [pen] = { [id] = { kind, at, yaw, egg?, timer?, pet?, jump?, hatching? } }
local contents = {} -- [pen] = the decoded Contents
local classes = {}

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace.Pens:FindFirstChild("Pen" .. index)
end

-- World ground point for (x, z) from the centre of the pen's Area.
local function groundAt(pen, x, z)
	local area = pen.Area
	return Vector3.new(area.Position.X + x, area.Position.Y - area.Size.Y / 2, area.Position.Z + z)
end

-- Pets face out of the pen, toward its open side (where the owner spawns).
local function facing(pen)
	local d = pen.Spawn.Position - pen.Area.Position
	return math.atan2(-d.X, -d.Z)
end

local function newPet(kind)
	classes[kind] = classes[kind] or require(Animals[kind])
	local animal = classes[kind].new()
	animal:setSaddled(false)
	return { animal = animal, rootY = animal.model.PrimaryPart.Position.Y, scale = 1, hop = 0 }
end

local function placePet(pet, at, yaw)
	pet.animal.model.PrimaryPart.CFrame = CFrame.new(at.X, at.Y + pet.rootY * pet.scale + pet.hop, at.Z) * CFrame.Angles(0, yaw, 0)
end

-- Your own pets can be ridden, and clicked to pick which. Animal parts aren't
-- queryable (so they never block the lasso or the mouse), so these ones are made so.
local mine = PenPets.pets -- [model] = { id, kind }
local function makeRideable(pen, id, pet, kind)
	if pen ~= myPen() then
		return
	end
	for _, part in pet.animal.model:GetDescendants() do
		if part:IsA("BasePart") and part ~= pet.animal.model.PrimaryPart then
			part.CanQuery = true
		end
	end
	mine[pet.animal.model] = { id = id, kind = kind }
	pet.animal.model.Destroying:Connect(function()
		mine[pet.animal.model] = nil
	end)
end

-- Pets amble between random spots inside their pen's fence, resting a while at
-- each. `margin` keeps big pets' bodies off the fence.
local function wander(pen, s, dt)
	local pet, w = s.pet, s.wander
	local speed, turn = 0, 0
	if w.rest > 0 then
		w.rest -= dt
		if w.rest <= 0 then
			local area = pen.Area
			local hx = math.max(0, area.Size.X / 2 - w.margin)
			local hz = math.max(0, area.Size.Z / 2 - w.margin)
			w.tx = area.Position.X + rng:NextNumber(-hx, hx)
			w.tz = area.Position.Z + rng:NextNumber(-hz, hz)
		end
	else
		local dx, dz = w.tx - s.at.X, w.tz - s.at.Z
		if dx * dx + dz * dz < 1 then
			w.rest = rng:NextNumber(2, 5)
		else
			-- yaw 0 faces -z, so the heading toward (dx, dz) is atan2(-dx, -dz)
			local diff = (math.atan2(-dx, -dz) - s.yaw + math.pi) % (2 * math.pi) - math.pi
			s.yaw += math.clamp(diff, -3 * dt, 3 * dt)
			turn = -math.clamp(diff, -1, 1) -- turn is + to the right, which is -yaw
			speed = WANDER_SPEED * math.max(0, math.cos(diff)) -- turn on the spot first
			s.at -= Vector3.new(math.sin(s.yaw), 0, math.cos(s.yaw)) * speed * dt
		end
	end
	pet.animal:update(dt, speed, turn)
end

local function startWander(s)
	local _, size = s.pet.animal.model:GetBoundingBox()
	s.wander = { rest = rng:NextNumber(1, 4), margin = EDGE + math.min(size.X, size.Z) / 2 }
end

local function newTimer(parent)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0) -- above the egg (the egg's root is at its base)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 28
	text.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = text
	text.Parent = gui
	gui.Parent = parent
	return text
end

local function remove(s)
	if s.egg then
		s.egg.model:Destroy()
	end
	if s.pet then
		s.pet.animal.model:Destroy()
	end
end

-- How big an egg is by now: it grows from 1x when placed to Config.EggGrowScale
-- when it hatches.
local function eggScale(s, now)
	classes[s.kind] = classes[s.kind] or require(Animals[s.kind])
	local total = Config.HatchTime[classes[s.kind].Rarity] or Config.HatchTime.Uncommon
	local grown = math.clamp(1 - ((s.hatchAt or now) - now) / total, 0, 1)
	return 1 + (Config.EggGrowScale - 1) * grown
end

-- scale: how far it's grown (eggScale). s.scale is that times the egg's own size
-- (bigger animals' eggs are bigger, Egg.sizeOf): how big it really is.
local function sizeEgg(s, scale)
	s.grown = scale
	scale *= s.egg.size
	s.scale = scale
	s.egg.model:ScaleTo(scale)
	s.egg.model:PivotTo(CFrame.new(s.at + Vector3.new(0, EGG_CENTER * scale, 0)) * CFrame.Angles(0, s.yaw, 0))
	if s.timer.Parent then
		s.timer.Parent.StudsOffsetWorldSpace = Vector3.new(0, 4.6 * scale, 0)
	end
end

local function showEgg(pen, id, item)
	local s = { kind = item.egg, at = groundAt(pen, item.x, item.z), yaw = facing(pen), hatchAt = item.hatchAt }
	s.egg = Egg.new(item.egg)
	s.egg.model:PivotTo(CFrame.new(s.at + Vector3.new(0, EGG_CENTER, 0)) * CFrame.Angles(0, s.yaw, 0))
	s.egg.model.Parent = folder
	s.timer = newTimer(s.egg.model.PrimaryPart)
	s.nextTwitch = rng:NextNumber(unpack(TWITCH_EVERY))
	sizeEgg(s, eggScale(s, workspace:GetServerTimeNow()))
	shown[pen][id] = s
end

local function showPet(pen, id, item)
	local s = { kind = item.pet, at = groundAt(pen, item.x, item.z), yaw = facing(pen) }
	s.pet = newPet(item.pet)
	makeRideable(pen, id, s.pet, item.pet)
	s.pet.animal.model.Parent = folder
	placePet(s.pet, s.at, s.yaw)
	startWander(s)
	shown[pen][id] = s
end

-- The egg hatched: play the hatch, then the pet jumps out onto the spot.
local function hatch(pen, id, s)
	s.hatching = true
	s.timer.Parent:Destroy() -- the countdown
	s.egg:play("hatch")
	task.delay(TOP_POPS, function()
		if shown[pen][id] ~= s then
			return
		end
		local pet = newPet(s.kind)
		makeRideable(pen, id, pet, s.kind)
		pet.scale = 0.2
		pet.animal:setScale(pet.scale)
		pet.animal.model.Parent = folder
		s.pet, s.jump = pet, 0
		placePet(pet, s.at, s.yaw)
		-- The empty shell fades away once the pet is out.
		task.delay(JUMP_TIME, function()
			local egg = s.egg
			if shown[pen][id] ~= s or not egg then
				return
			end
			s.egg = nil
			for _, part in egg.model:GetDescendants() do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 1 }):Play()
				end
			end
			task.delay(0.6, function()
				egg.model:Destroy()
			end)
		end)
	end)
end

local function refresh(pen)
	local ok, items = pcall(HttpService.JSONDecode, HttpService, pen:GetAttribute("Contents") or "{}")
	items = ok and typeof(items) == "table" and items or {}
	contents[pen] = items
	local list = shown[pen]
	for id, s in list do
		local item = items[id]
		if not item then
			remove(s)
			list[id] = nil
		elseif item.pet and s.egg and not s.hatching then
			hatch(pen, id, s)
		elseif item.pet and s.pet and not s.jump and item.pet ~= s.kind then
			remove(s) -- swapped with the pet you ride
			list[id] = nil
		end
	end
	for id, item in items do
		if not list[id] then
			if item.egg then
				showEgg(pen, id, item)
			elseif item.pet then
				showPet(pen, id, item)
			end
		end
	end
end

for _, pen in workspace:WaitForChild("Pens"):GetChildren() do
	shown[pen] = {}
	pen:WaitForChild("Area")
	pen:GetAttributeChangedSignal("Contents"):Connect(function()
		refresh(pen)
	end)
	refresh(pen)
end

local function countdown(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Placing: the equipped egg Tool, and the see-through egg that shows where it'll go.
local holding, ghost
local mouse = player:GetMouse()

-- Where in your pen the screen point (x, y) (GUI pixels, as the mouse reports
-- them) looks at, as (x, z) from the Area's centre, if an egg can go there.
local function spotAt(screenX, screenY)
	local pen = myPen()
	if not pen then
		return nil
	end
	-- Where the mouse ray meets the pen floor's plane. (Not mouse.Hit: that stops
	-- on whatever's in the way first, a fence rail, your character, the pet
	-- waiting to be ridden, and then the spot was off or missing.)
	local area = pen.Area
	local ray = workspace.CurrentCamera:ScreenPointToRay(screenX, screenY)
	local floorY = area.Position.Y + area.Size.Y / 2
	if math.abs(ray.Direction.Y) < 1e-3 then
		return nil
	end
	local t = (floorY - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return nil
	end
	local hit = ray.Origin + ray.Direction * t - area.Position
	if math.abs(hit.X) > area.Size.X / 2 - EDGE or math.abs(hit.Z) > area.Size.Z / 2 - EDGE then
		return nil
	end
	return hit.X, hit.Z
end

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local camPos = workspace.CurrentCamera.CFrame.Position
	for pen, list in shown do
		if (pen.Area.Position - camPos).Magnitude > FAR then
			continue
		end
		for _, s in list do
			if s.egg then
				if not s.hatching then
					s.timer.Text = countdown((s.hatchAt or now) - now)
					local scale = eggScale(s, now)
					if math.abs(scale - s.grown) > 0.004 then
						sizeEgg(s, scale)
					end
					s.nextTwitch -= dt
					if s.nextTwitch <= 0 and not s.egg:isPlaying() then
						s.egg:play("twitch")
						s.nextTwitch = rng:NextNumber(unpack(TWITCH_EVERY))
					end
				end
				s.egg:update(dt)
			end
			local pet = s.pet
			if pet then
				if s.jump then
					-- Out of the egg in an arc, growing to full size, landing on the spot.
					s.jump = math.min(s.jump + dt / JUMP_TIME, 1)
					local t = s.jump
					pet.scale = 0.2 + 0.8 * (1 - (1 - t) ^ 3)
					pet.animal:setScale(pet.scale)
					pet.hop = EGG_CENTER * (s.scale or 1) * (1 - t) + JUMP_HEIGHT * 4 * t * (1 - t)
					if t >= 1 then
						s.jump, s.hatching = nil, nil
						startWander(s)
					end
				end
				if s.wander then
					wander(pen, s, dt)
				else
					pet.animal:update(dt, 0, 0)
				end
				placePet(pet, s.at, s.yaw)
			end
		end
	end
	if ghost then
		local x, z = spotAt(mouse.X, mouse.Y)
		ghost.Parent = if x then folder else nil
		if x then
			local pen = myPen()
			ghost:PivotTo(CFrame.new(groundAt(pen, x, z) + Vector3.new(0, EGG_CENTER * ghost:GetScale(), 0)) * CFrame.Angles(0, facing(pen), 0))
		end
	end
end)

local function setGhost(kind)
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if not kind then
		return
	end
	ghost = Egg.new(kind).model
	for _, part in ghost:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0.6
			part.CanCollide = false
			part.CanQuery = false -- so the mouse sees the ground under it
		end
	end
end

local hooked = {} -- tools already wired up (each equip puts the tool in the character again)

local function hold(tool)
	holding = tool
	setGhost(tool:GetAttribute("EggKind"))
	if hooked[tool] then
		return
	end
	hooked[tool] = true
	local function drop()
		if holding == tool then
			holding = nil
			setGhost(nil)
		end
	end
	tool.Destroying:Connect(function()
		hooked[tool] = nil
		drop()
	end)
	tool.Unequipped:Connect(drop)
end

-- A click or tap on your pen while holding an egg puts it down there. (Read
-- straight from the input, not the Tool's Activated, which some clicks never fire.)
local function placeAt(screenX, screenY)
	if not holding or holding.Parent ~= player.Character then
		return
	end
	local x, z = spotAt(screenX, screenY)
	if x then
		placeEgg:FireServer(holding:GetAttribute("EggKind"), x, z)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		placeAt(input.Position.X, input.Position.Y)
	end
end)

-- Taps on phones and tablets. With a tool out, a tap on the world can reach
-- InputBegan already marked processed (the engine uses it to activate the tool),
-- and placing never worked on mobile. TouchTapInWorld only flags taps on the UI.
UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
	if not processedByUI then
		placeAt(position.X, position.Y)
	end
end)

local function watchCharacter(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("EggKind") then
			hold(child)
		end
	end)
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	watchCharacter(player.Character)
end

-- The camera on spawning ---------------------------------------------------------
-- On spawning at your pen (Pens.server stands you at its Spawn facing in), the
-- camera starts behind you looking down into the pen, SPAWN_PITCH degrees down and
-- SPAWN_DISTANCE studs back (QM's pick), instead of Roblox's default low angle.

local SPAWN_PITCH = 34
local SPAWN_DISTANCE = 24
local SPAWN_WAIT = 3 -- seconds to wait for the server to move you to your pen

local camera = workspace.CurrentCamera

local function atSpawn(hrp)
	local pens = workspace:FindFirstChild("Pens")
	local pen = pens and pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
	local spawn = pen and pen:FindFirstChild("Spawn")
	return spawn and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(spawn.Position.X, 0, spawn.Position.Z)).Magnitude < 12 -- (Pens.server stands you 10 out)
end

local function onSpawn(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		return
	end
	local started = os.clock()
	while not atSpawn(hrp) do
		if os.clock() - started > SPAWN_WAIT or not hrp.Parent then
			return -- no pen: leave the default camera
		end
		RunService.Heartbeat:Wait()
	end
	-- The camera puts itself behind a new character at its own angle a moment after
	-- it spawns: wait for that, then hold ours for a few frames so it sticks.
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	while camera.CameraSubject ~= humanoid and os.clock() - started < SPAWN_WAIT do
		RunService.Heartbeat:Wait()
	end
	task.wait(0.1)
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.01 or not hrp.Parent then
		return
	end
	look = look.Unit
	local pitch = math.rad(SPAWN_PITCH)
	-- The camera keeps its own zoom: raising the minimum pushes it out to SPAWN_DISTANCE,
	-- and it stays there once the minimum's back.
	local minZoom = player.CameraMinZoomDistance
	player.CameraMinZoomDistance = SPAWN_DISTANCE
	for _ = 1, 5 do
		local focus = hrp.Position + Vector3.new(0, 1.5, 0)
		camera.CFrame = CFrame.lookAt(focus - look * SPAWN_DISTANCE * math.cos(pitch) + Vector3.yAxis * SPAWN_DISTANCE * math.sin(pitch), focus)
		RunService.RenderStepped:Wait()
	end
	player.CameraMinZoomDistance = minZoom
end

player.CharacterAdded:Connect(onSpawn)
if player.Character then
	task.spawn(onSpawn, player.Character)
end
