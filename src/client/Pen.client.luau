-- Eggs and pets in the pens, for every pen on the server.
--
-- The server (Hatchery) says what's on each pen spot through the slot parts'
-- attributes: "Egg" + "HatchAt" for an egg, "Pet" for a hatched pet. This draws
-- them: an egg with a countdown that twitches now and then, then the hatch
-- (the egg shakes, its top pops off, the pet jumps out onto the spot), and pets
-- idling on their spots.
--
-- It also runs placing: pick an egg in the Eggs panel and every free spot in
-- your pen shows a see-through egg; click or tap one to put the egg there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer
local placeEgg = ReplicatedStorage:WaitForChild("PlaceEgg")

local FIRST_SLOT = 2 -- Slot1 is where the pet you ride waits
local EGG_CENTER = 1.6 -- egg pivot height above the ground (Egg.luau)
local TOP_POPS = 1.58 -- seconds into the hatch animation when the top flies off
local JUMP_TIME = 0.6
local JUMP_HEIGHT = 5
local TWITCH_EVERY = { 3, 6 }
local rng = Random.new()

local folder = Instance.new("Folder")
folder.Name = "PenContents"
folder.Parent = workspace

local shown = {} -- [slot] = { egg?, timer?, pet?, jump? }
local classes = {}

local function slotIndex(slot)
	return tonumber(slot.Name:match("^Slot(%d+)$"))
end

local function ground(slot)
	return Vector3.new(slot.Position.X, slot.Position.Y - slot.Size.Y / 2, slot.Position.Z)
end

-- Pets face out of the pen, toward its open side (where the owner spawns).
local function facing(slot)
	local pen = slot:FindFirstAncestorOfClass("Model")
	local spawn = pen and pen:FindFirstChild("Spawn")
	if not spawn then
		return 0
	end
	local d = spawn.Position - slot.Position
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
	gui.Adornee = parent
	gui.Parent = parent
	return text
end

local function clear(slot)
	local s = shown[slot]
	if not s then
		return
	end
	if s.egg then
		s.egg.model:Destroy()
	end
	if s.pet then
		s.pet.animal.model:Destroy()
	end
	shown[slot] = nil
end

local function showEgg(slot, kind)
	clear(slot)
	local egg = Egg.new(kind)
	egg.model:PivotTo(CFrame.new(ground(slot) + Vector3.new(0, EGG_CENTER, 0)) * CFrame.Angles(0, facing(slot), 0))
	egg.model.Parent = folder
	shown[slot] = { egg = egg, kind = kind, timer = newTimer(egg.model.PrimaryPart), nextTwitch = rng:NextNumber(unpack(TWITCH_EVERY)) }
end

local function showPet(slot, kind)
	clear(slot)
	local pet = newPet(kind)
	pet.animal.model.Parent = folder
	placePet(pet, ground(slot), facing(slot))
	shown[slot] = { pet = pet, kind = kind }
end

-- The egg on `slot` hatched: play the hatch, then the pet jumps out onto the spot.
local function hatch(slot, kind)
	local s = shown[slot]
	if not s or not s.egg or s.hatching then
		showPet(slot, kind)
		return
	end
	s.hatching = true
	s.timer.Parent:Destroy() -- the countdown
	s.egg:play("hatch")
	task.delay(TOP_POPS, function()
		if shown[slot] ~= s then
			return
		end
		local pet = newPet(kind)
		pet.scale = 0.2
		pet.animal:setScale(pet.scale)
		pet.animal.model.Parent = folder
		s.pet, s.jump = pet, 0
		placePet(pet, ground(slot) + Vector3.new(0, EGG_CENTER, 0), facing(slot))
		-- The empty shell sinks away once the pet is out.
		task.delay(JUMP_TIME, function()
			if shown[slot] == s and s.egg then
				local egg = s.egg
				s.egg = nil
				for _, part in egg.model:GetDescendants() do
					if part:IsA("BasePart") then
						TweenService:Create(part, TweenInfo.new(0.5), { Transparency = 1 }):Play()
					end
				end
				task.delay(0.6, function()
					egg.model:Destroy()
				end)
			end
		end)
	end)
end

local function refresh(slot)
	local index = slotIndex(slot)
	if not index or index < FIRST_SLOT then
		return
	end
	local eggKind, petKind = slot:GetAttribute("Egg"), slot:GetAttribute("Pet")
	local s = shown[slot]
	if eggKind then
		if not (s and s.egg and s.kind == eggKind and not s.hatching) then
			showEgg(slot, eggKind)
		end
	elseif petKind then
		if s and s.kind == petKind and s.egg and not s.hatching then
			hatch(slot, petKind)
		elseif not (s and s.kind == petKind and s.pet) and not (s and s.hatching) then
			showPet(slot, petKind)
		end
	else
		clear(slot)
	end
end

local function watchPen(pen)
	local slots = pen:WaitForChild("Slots")
	for _, slot in slots:GetChildren() do
		refresh(slot)
		-- Egg and Pet change together when an egg hatches; look once both have.
		local pending = false
		for _, name in { "Egg", "Pet" } do
			slot:GetAttributeChangedSignal(name):Connect(function()
				if not pending then
					pending = true
					task.defer(function()
						pending = false
						refresh(slot)
					end)
				end
			end)
		end
	end
end

for _, pen in workspace:WaitForChild("Pens"):GetChildren() do
	task.spawn(watchPen, pen)
end

local function countdown(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	for slot, s in shown do
		if s.egg then
			if not s.hatching then
				s.timer.Text = countdown((slot:GetAttribute("HatchAt") or now) - now)
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
			local at = ground(slot)
			if s.jump then
				-- Out of the egg in an arc, growing to full size, landing on the spot.
				s.jump = math.min(s.jump + dt / JUMP_TIME, 1)
				local t = s.jump
				pet.scale = 0.2 + 0.8 * (1 - (1 - t) ^ 3)
				pet.animal:setScale(pet.scale)
				pet.hop = EGG_CENTER * (1 - t) + JUMP_HEIGHT * 4 * t * (1 - t)
				if t >= 1 then
					s.jump, s.hatching = nil, nil
				end
			end
			pet.animal:update(dt, 0, 0)
			placePet(pet, at, facing(slot))
		end
	end
end)

-- Placing an egg: ghosts on your free spots until one is clicked.
local ghosts = {}

local function stopPlacing()
	for _, ghost in ghosts do
		ghost:Destroy()
	end
	table.clear(ghosts)
end

local function myPen()
	local index = player:GetAttribute("Pen")
	return index and workspace.Pens:FindFirstChild("Pen" .. index)
end

Hud.onPickEgg = function(kind)
	stopPlacing()
	local pen = myPen()
	if not pen then
		return
	end
	for _, slot in pen.Slots:GetChildren() do
		local index = slotIndex(slot)
		if index and index >= FIRST_SLOT and not slot:GetAttribute("Egg") and not slot:GetAttribute("Pet") then
			local ghost = Egg.new(kind).model
			ghost:PivotTo(CFrame.new(ground(slot) + Vector3.new(0, EGG_CENTER, 0)) * CFrame.Angles(0, facing(slot), 0))
			for _, part in ghost:GetDescendants() do
				if part:IsA("BasePart") then
					part.Transparency = 0.6
					part.CanCollide = false
				end
			end
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 200
			click.MouseClick:Connect(function()
				stopPlacing()
				placeEgg:FireServer(kind, index)
			end)
			click.Parent = ghost
			ghost.Parent = folder
			table.insert(ghosts, ghost)
		end
	end
end

Hud.onEggsToggled = function(open)
	if open then
		stopPlacing()
	end
end

local function showInventory()
	local ok, inventory = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Eggs") or "{}")
	Hud.setEggInventory(ok and inventory or {})
end
player:GetAttributeChangedSignal("Eggs"):Connect(showInventory)
showInventory()
