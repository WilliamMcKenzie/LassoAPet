-- Eggs and pets in the pens, for every pen on the server.
--
-- The server (Hatchery) puts what's in each pen on the pen's "Contents"
-- attribute: JSON of { [id] = { x, z, egg, hatchAt } or { x, z, pet } }, x and z
-- from the centre of the pen's Area. This draws it: eggs with a countdown that
-- twitch now and then ("Ready" once it's up: an egg waits for you to hold F by it,
-- HatchEgg, QM Oct 6; till then the same prompt sells the paid hatch), the hatch
-- (the egg shakes, its top pops off, the pet jumps out onto the spot), and pets
-- ambling around inside their pen.
--
-- It also runs placing: while an egg from your inventory is equipped, a
-- see-through egg follows the mouse over your pen; click or tap to put it down.
-- Your own pets go on PenPets' list, so RIDE (Ride.client) can ride any of them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Animals = ReplicatedStorage.Shared.Animals
local Egg = require(ReplicatedStorage.Shared.Eggs.Egg)
local Config = require(ReplicatedStorage.Shared.Config)
local Merge = require(ReplicatedStorage.Shared.Merge)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local PenPets = require(script.Parent.PenPets)
local Sounds = require(script.Parent.Sounds)
local Gamepad = require(script.Parent.Gamepad)

local player = Players.LocalPlayer
local placeEgg = ReplicatedStorage:WaitForChild("PlaceEgg")
local speedupEgg = ReplicatedStorage:WaitForChild("SpeedupEgg")
local hatchEgg = ReplicatedStorage:WaitForChild("HatchEgg")

local EGG_CENTER = 1.6 -- egg pivot height above the ground (Egg.luau)
local TOP_POPS = 1.58 -- seconds into the hatch animation when the top flies off
local JUMP_TIME = 0.6
local TIMER_SIZE = Vector2.new(4, 1.28) -- studs: an egg's "Ready" / countdown (was 5 x 1.6, 20% smaller: QM, Oct 9)
local HATCH_SOUND_PEAK = 0.46 -- seconds into Sounds' egg_hatch (Rewards) where it's loudest (measured, Oct 9)
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

-- World ground point for (x, z) from the centre of the pen's Area, in the pen's
-- frame (the arc base's pens are turned to face the yard).
local function groundAt(pen, x, z)
	local area = pen.Area
	return area.CFrame:PointToWorldSpace(Vector3.new(x, -area.Size.Y / 2, z))
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
local mine = PenPets.pets -- [model] = { id, kind, merged, fuse, income, stats, worth }
local function makeRideable(pen, id, pet, kind, merged, fuse, income, stats, worth, tier)
	if pen ~= myPen() then
		-- Someone else's: no RIDE, but its nameplate and ring show as yours do (QM, Oct 7).
		local model = pet.animal.model
		PenPets.others[model] = { kind = kind, merged = merged or 1, fuse = fuse, income = income, stats = stats }
		model.Destroying:Connect(function()
			PenPets.others[model] = nil
		end)
		return
	end
	for _, part in pet.animal.model:GetDescendants() do
		if part:IsA("BasePart") and part ~= pet.animal.model.PrimaryPart then
			part.CanQuery = true
		end
	end
	mine[pet.animal.model] = { id = id, kind = kind, merged = merged or 1, fuse = fuse, income = income, stats = stats, worth = worth, tier = tier }
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
			local to = area.CFrame:PointToWorldSpace(Vector3.new(rng:NextNumber(-hx, hx), 0, rng:NextNumber(-hz, hz))) -- (in the pen's frame)
			w.tx, w.tz = to.X, to.Z
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
	if s.inView then
		pet.animal:update(dt, speed, turn)
	end
end

local function startWander(s)
	local _, size = s.pet.animal.model:GetBoundingBox()
	s.wander = { rest = rng:NextNumber(1, 4), margin = EDGE + math.min(size.X, size.Z) / 2 }
end

local function newTimer(parent)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(TIMER_SIZE.X, TIMER_SIZE.Y) -- (studs: in the world like the pets' plates, smaller as you zoom out: QM, Oct 9)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0) -- above the egg (the egg's root is at its base)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Enabled = false -- (on only near you: nearTimer)
	gui.AlwaysOnTop = true -- (drawn over the egg, never hidden behind it: QM, Oct 9)
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3 -- (as the pets' plates)
	stroke.Parent = text
	text.Parent = gui
	gui.Parent = parent
	return text
end

-- QM's big white arrow (Client/Tutorial's) bobbing over each of your eggs that's ready
-- to hatch, till you're close enough for its prompt (QM, Oct 11). Not in the tutorial:
-- it has its own.
local READY_ARROW = "rbxassetid://127821178410489" -- assets/ui/TutorialArrow.png
local function readyArrow(s, show)
	if show and not s.arrow then
		local gui = Instance.new("BillboardGui")
		gui.Name = "ReadyArrow"
		gui.Size = UDim2.fromScale(7, 7)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = READY_ARROW
		image.Size = UDim2.fromScale(1, 1)
		image.Parent = gui
		gui.ResetOnSpawn = false
		gui.Parent = player:WaitForChild("PlayerGui")
		s.arrow = gui
	end
	if s.arrow then
		local root = show and s.egg and s.egg.model.PrimaryPart
		s.arrow.Adornee = root
		s.arrow.Enabled = root ~= nil
		s.arrow.StudsOffsetWorldSpace = Vector3.new(0, 14 + math.abs(math.sin(os.clock() * 3)) * 1.5, 0)
	end
end

local function remove(s)
	if s.arrow then
		s.arrow:Destroy()
		s.arrow = nil
	end
	if s.speedupAttachment then s.speedupAttachment:Destroy() end
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
	local total = Config.PetHatchTime[s.kind] or Config.HatchTime[classes[s.kind].Rarity] or Config.HatchTime.Uncommon
	local grown = math.clamp(1 - ((s.hatchAt or now) - now) / total, 0, 1)
	return 1 + (Config.EggGrowScale - 1) * grown
end

-- scale: how far it's grown (eggScale). s.scale is that times the egg's own size
-- (bigger animals' eggs are bigger, Egg.sizeOf): how big it really is.
local function sizeEgg(s, scale)
	s.grown = scale
	scale *= s.egg.size * (s.eggScale or 1)
	s.scale = scale
	s.egg.model:ScaleTo(scale)
	Egg.fitStuds(s.egg.model)
	s.egg.model:PivotTo(CFrame.new(s.at + Vector3.new(0, EGG_CENTER * scale, 0)) * CFrame.Angles(0, s.yaw, 0))
	if s.timer.Parent then
		s.timer.Parent.StudsOffsetWorldSpace = Vector3.new(0, 4.6 * scale, 0)
	end
end

-- The merge view (FuseMenu's "MergeView" attribute, QM Oct 11): your pen's eggs hide
-- while it's up, their timers too (nearTimer).
local function hideEgg(egg, hidden)
	for _, d in egg.model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function showEgg(pen, id, item)
	local s = { kind = item.egg, merged = item.merged or 1, eggScale = item.eggScale, at = groundAt(pen, item.x, item.z), yaw = facing(pen), hatchAt = item.hatchAt }
	s.egg = Egg.new(item.egg)
	shown[pen][id] = s -- tracked at once: if anything below fails, the next refresh still clears it
	s.egg.model:PivotTo(CFrame.new(s.at + Vector3.new(0, EGG_CENTER, 0)) * CFrame.Angles(0, s.yaw, 0))
	s.egg.model.Parent = folder
	if player:GetAttribute("MergeView") and pen == myPen() then
		hideEgg(s.egg, true)
	end
	s.timer = newTimer(s.egg.model.PrimaryPart)
	if pen == myPen() and pen:GetAttribute("Owner") == player.UserId then
		-- One prompt on the egg: hold F for the paid hatch while it's counting down,
		-- and F to hatch it once it's ready (QM; the frame loop below switches it over).
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SpeedupEgg"
		prompt:SetAttribute("ObjectColor", Config.RarityColors[Fusion.rarity(item.egg)]) -- (the name in its animal's rarity colour, as Ride's: PromptUi, QM Oct 10)
		prompt.ObjectText = item.egg .. " Egg"
		prompt.ActionText = "Hatch" -- (counting down, the time left instead, below; held then, it's the paid hatch)
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.35
		prompt.Style = Enum.ProximityPromptStyle.Custom -- (Roblox's look without its panel: PromptUi)
		prompt.MaxActivationDistance = Config.SpeedupEgg.Range
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		-- Keep the prompt outside the growing model: ScaleTo also scales its range.
		local attachment = Instance.new("Attachment")
		attachment.Name = "EggHatchPrompt"
		attachment.Position = pen.Area.CFrame:PointToObjectSpace(s.at + Vector3.new(0, 2, 0))
		attachment.Parent = pen.Area
		s.speedupAttachment = attachment
		prompt.Parent = attachment
		prompt.Triggered:Connect(function()
			if s.hatching or pen ~= myPen() then
				return
			end
			if (s.hatchAt or 0) <= workspace:GetServerTimeNow() then
				hatchEgg:FireServer(id)
			else
				speedupEgg:FireServer(id)
			end
		end)
		s.speedupPrompt = prompt
	end

	s.nextTwitch = rng:NextNumber(unpack(TWITCH_EVERY))
	sizeEgg(s, eggScale(s, workspace:GetServerTimeNow()))
end

local function showPet(pen, id, item)
	local s = { kind = item.pet, merged = item.merged or 1, fuse = item.fuse, at = groundAt(pen, item.x, item.z), yaw = facing(pen) }
	s.pet = newPet(item.pet)
	shown[pen][id] = s -- tracked at once: if anything below fails, the next refresh still clears it
	Fusion.paint(s.pet.animal.model, item.pet, item.fuse) -- a hybrid wears its donor's colours (Shared/Fusion)
	s.pet.scale = Merge.size(item.pet, item.merged) * Fusion.scale(item.pet, item.fuse, item.tier) -- a merged pet is bigger (Shared/Merge)
	s.pet.animal:setScale(s.pet.scale)
	makeRideable(pen, id, s.pet, item.pet, item.merged, item.fuse, item.income, item.stats, item.worth, item.tier)
	-- Just merged (PenPets.merges): it waits unseen while the pets going into it are
	-- pulled up, then pops out up there and drops down onto the spot under it.
	local merge = pen == myPen() and ((item.merged or 1) > 1 or item.fuse) and PenPets.mergeFor(Fusion.key(item.pet, item.fuse))
	if merge then
		s.drop, s.full = merge, s.pet.scale
		s.at = Vector3.new(merge.at.X, s.at.Y, merge.at.Z)
		placePet(s.pet, s.at, s.yaw)
		return
	end
	s.pet.animal.model.Parent = folder
	placePet(s.pet, s.at, s.yaw)
	startWander(s)
end

-- The egg hatched: play the hatch, then the pet jumps out onto the spot.
local function hatch(pen, id, s)
	s.hatching = true
	if s.speedupAttachment then
		s.speedupAttachment:Destroy()
		s.speedupAttachment, s.speedupPrompt = nil, nil
	end
	if pen == myPen() then
		-- Timed so its climax lands as the pet jumps out, not as the hatch starts (QM, Oct 9).
		task.delay(math.max(TOP_POPS - HATCH_SOUND_PEAK, 0), Sounds.play, "egg_hatch")
	end
	s.timer.Parent:Destroy() -- the countdown
	if s.arrow then
		s.arrow:Destroy()
		s.arrow = nil
	end
	s.egg:play("hatch")
	task.delay(TOP_POPS, function()
		if shown[pen][id] ~= s then
			return
		end
		local pet = newPet(s.kind)
		makeRideable(pen, id, pet, s.kind, s.merged)
		s.full = Merge.size(s.kind, s.merged) -- (a special egg's pet can hatch merged: the Giant Horse)
		pet.scale = 0.2 * s.full
		pet.animal:setScale(pet.scale)
		pet.animal.model.Parent = folder
		s.pet, s.jump = pet, 0
		pet.animal.model:SetAttribute("Hatching", true) -- (till it's landed: Client/Tutorial's arrow waits)
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

-- The pet someone else rides waits in their pen too, but it isn't in Contents
-- (the server keeps it on the owner as "RidePet"), and only its owner's Ride.client
-- draws it. So for everyone else it's drawn here, on the pen's first spot, while
-- it's home: not while it's out on a ride ("PetOut", Riders.server).
local function ridePetOf(pen)
	local owner = Players:GetPlayerByUserId(pen:GetAttribute("Owner") or 0)
	local kind = owner and owner ~= player and owner:GetAttribute("RidePet")
	local slot = pen:FindFirstChild("Slots") and pen.Slots:FindFirstChild("Slot1")
	if not (kind and kind ~= "" and Animals:FindFirstChild(kind) and slot) or owner:GetAttribute("PetOut") then
		return nil
	end
	local fuse = owner:GetAttribute("RideFuse")
	local stats = owner:GetAttribute("RideStats") -- (a hybrid's Speed, Stamina)
	return {
		pet = kind,
		merged = owner:GetAttribute("RideMerged"),
		fuse = if fuse and Animals:FindFirstChild(fuse) then fuse else nil,
		income = owner:GetAttribute("RideIncome"),
		stats = if typeof(stats) == "Vector2" then { Speed = stats.X, Stamina = stats.Y } else nil,
		x = pen.Area.CFrame:PointToObjectSpace(slot.Position).X, -- (in the pen's frame)
		z = pen.Area.CFrame:PointToObjectSpace(slot.Position).Z,
	}
end

local function refresh(pen)
	local ok, items = pcall(HttpService.JSONDecode, HttpService, pen:GetAttribute("Contents") or "{}")
	items = ok and typeof(items) == "table" and items or {}
	contents[pen] = items
	items = table.clone(items)
	items.ride = ridePetOf(pen)
	local list = shown[pen]
	for id, s in list do
		local item = items[id]
		if not item then
			remove(s)
			list[id] = nil
		elseif item.pet and s.egg and not s.hatching then
			hatch(pen, id, s)
		elseif item.pet and s.pet and not s.jump and (item.pet ~= s.kind or item.fuse ~= s.fuse or (item.merged or 1) ~= (s.merged or 1)) then
			remove(s) -- swapped with the pet you ride, merged or fused (shown again below)
			list[id] = nil
		elseif item.pet and s.pet and (mine[s.pet.animal.model] or PenPets.others[s.pet.animal.model]) then -- (fused into a hybrid that looks the same)
			local info = mine[s.pet.animal.model] or PenPets.others[s.pet.animal.model]
			info.stats, info.income, info.worth = item.stats, item.income, item.worth
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
	pen:GetAttributeChangedSignal("Owner"):Connect(function()
		refresh(pen)
	end)
	refresh(pen)
end

-- Someone else's ride pet changed, set off or came home: redraw their pen.
local function watchRidePet(other)
	if other == player then
		return
	end
	for _, name in { "RidePet", "RideMerged", "RideFuse", "PetOut" } do
		other:GetAttributeChangedSignal(name):Connect(function()
			for pen in shown do
				if pen:GetAttribute("Owner") == other.UserId then
					refresh(pen)
				end
			end
		end)
	end
end
Players.PlayerAdded:Connect(watchRidePet)
for _, other in Players:GetPlayers() do
	watchRidePet(other)
end

-- An egg's time left: "2h" from an hour up (whole hours, QM), else "m:ss".
local function countdown(seconds)
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%dh", seconds // 3600)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Placing: the equipped egg Tool, and the see-through egg that shows where it'll go.
local holding, ghost
local placeAt -- (below: puts the held egg down at a screen point)
local mouse = player:GetMouse()

-- Where in your pen the screen point (x, y) (GUI pixels, as the mouse reports
-- them) looks at, as (x, z) from the Area's centre, if an egg can go there.
local function spotAt(screenX, screenY)
	local pen = myPen()
	if not pen or (pen:GetAttribute("PetCount") or 0) >= (pen:GetAttribute("PetCap") or math.huge) then
		return nil -- (no pen, or it's full: Config.PenCapacity)
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
	local hit = area.CFrame:PointToObjectSpace(ray.Origin + ray.Direction * t) -- (in the pen's frame)
	if math.abs(hit.X) > area.Size.X / 2 - EDGE or math.abs(hit.Z) > area.Size.Z / 2 - EDGE then
		return nil
	end
	return hit.X, hit.Z
end

-- The screen point an egg goes down at: the mouse's (or the last tap's); with a
-- controller, the ground a few studs in front of you.
local PAD_AHEAD = 6
local function pointer()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pen = myPen()
	if Gamepad.active and hrp and pen then
		local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		local ahead = hrp.Position + (if look.Magnitude > 1e-3 then look.Unit else Vector3.zero) * PAD_AHEAD
		local floorY = pen.Area.Position.Y + pen.Area.Size.Y / 2
		local screen = workspace.CurrentCamera:WorldToScreenPoint(Vector3.new(ahead.X, floorY, ahead.Z))
		return screen.X, screen.Y
	end
	return mouse.X, mouse.Y
end

-- Whether any of a pen (with room for big pets over its fence) can be on screen.
-- Off screen, its pets and eggs keep their places but aren't animated or moved:
-- posing a pet's blocks is most of its cost, and at home most pens are out of view.
local PEN_ROOM = 30 -- studs past the fence's corners
local function penInView(pen)
	local camera = workspace.CurrentCamera
	local area = pen.Area
	local radius = Vector2.new(area.Size.X, area.Size.Z).Magnitude / 2 + PEN_ROOM
	local at = camera.CFrame:PointToObjectSpace(area.Position)
	local depth = -at.Z
	if depth < -radius then
		return false
	end
	local tanY = math.tan(math.rad(camera.FieldOfView) / 2)
	local size = camera.ViewportSize
	local tanX = tanY * size.X / math.max(size.Y, 1)
	return math.abs(at.X) <= depth * tanX + radius * math.sqrt(1 + tanX * tanX)
		and math.abs(at.Y) <= depth * tanY + radius * math.sqrt(1 + tanY * tanY)
end

-- An egg's "Ready" / countdown shows only while you're near it, as the pets' plates do
-- (PetPlates: in at TIMER_REACH studs, out past TIMER_LEAVE, popping in; QM, Oct 9).
local TIMER_REACH, TIMER_LEAVE = 16, 19
-- While one of your eggs' prompts is up, everything else floating over the pen hides
-- (QM, Oct 10): the eggs' timers here, the pets' plates (PetPlates) and RIDE (Ride), on
-- this client's "EggPromptUp" attribute.
local eggPrompts = {}
ProximityPromptService.PromptShown:Connect(function(prompt)
	if prompt.Name == "SpeedupEgg" then
		eggPrompts[prompt] = true
		player:SetAttribute("EggPromptUp", true)
	end
end)
ProximityPromptService.PromptHidden:Connect(function(prompt)
	if eggPrompts[prompt] then
		eggPrompts[prompt] = nil
		player:SetAttribute("EggPromptUp", next(eggPrompts) ~= nil)
	end
end)

player:GetAttributeChangedSignal("MergeView"):Connect(function()
	local pen = myPen()
	for _, s in (pen and shown[pen]) or {} do
		if s.egg then
			hideEgg(s.egg, player:GetAttribute("MergeView") == true)
		end
	end
end)

local function nearTimer(s, hrp)
	local root = s.egg.model.PrimaryPart
	local d = if hrp and root then ((root.Position - hrp.Position) * Vector3.new(1, 0, 1)).Magnitude else math.huge
	local on = d <= (if s.timerOn then TIMER_LEAVE else TIMER_REACH) and not player:GetAttribute("EggPromptUp") -- (none while an egg's prompt is up: QM)
		and not player:GetAttribute("MergeView") -- (nor in the merge view: FuseMenu, QM)
	if on ~= s.timerOn then
		s.timerOn = on
		local gui = s.timer.Parent
		if gui then -- (gone with its egg, mid-hatch)
			gui.Enabled = on
		end
		if on then
			local pop = s.timer:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			pop.Scale = 0
			pop.Parent = s.timer
			TweenService:Create(pop, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local camPos = workspace.CurrentCamera.CFrame.Position
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for pen, list in shown do
		if (pen.Area.Position - camPos).Magnitude > FAR then
			continue
		end
		local inView = penInView(pen)
		for _, s in list do
			s.inView = inView
			if s.egg and (inView or s.hatching) then
				if not s.hatching then
					local ready = (s.hatchAt or now) <= now
					if s.speedupPrompt then
						s.speedupPrompt.Enabled = pen == myPen() and pen:GetAttribute("Owner") == player.UserId and (ready or not player:GetAttribute("Tutorial")) -- (the tutorial: hatch it, no speeding up)
					end
					s.timer.Text = if ready then "Ready" else countdown((s.hatchAt or now) - now)
					readyArrow(s, ready and pen == myPen() and not player:GetAttribute("Tutorial") and not player:GetAttribute("EggPromptUp")
						and not player:GetAttribute("MergeView") and not player:GetAttribute("Cutscene"))
					if s.speedupPrompt then
						-- (its action: the time left, as over the egg, till it's ready: QM, Oct 10)
						local action = if ready then "Hatch" else s.timer.Text
						if s.speedupPrompt.ActionText ~= action then
							s.speedupPrompt.ActionText = action
						end
					end
					nearTimer(s, hrp)
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
					pet.scale = (0.2 + 0.8 * (1 - (1 - t) ^ 3)) * (s.full or 1)
					pet.animal:setScale(pet.scale)
					pet.hop = EGG_CENTER * (s.scale or 1) * (1 - t) + JUMP_HEIGHT * 4 * t * (1 - t)
					if t >= 1 then
						s.jump, s.hatching = nil, nil
						pet.animal.model:SetAttribute("Hatching", nil)
						startWander(s)
					end
				end
				if s.drop then
					local t = os.clock() - s.drop.landAt
					if t >= 0 then
						if not s.dropPopped then
							s.dropPopped = true
							Sounds.play("merge_pop")
						end
						local size, hop, landed = PenPets.drop(t, s.drop.at.Y - s.at.Y)
						pet.animal.model.Parent = folder
						pet.scale, pet.hop = s.full * size, hop
						pet.animal:setScale(pet.scale)
						if landed then
							s.drop, pet.hop = nil, 0
							startWander(s)
						end
					end
					pet.animal:update(dt, 0, 0)
				elseif s.wander then
					wander(pen, s, dt)
				elseif inView or s.jump then
					pet.animal:update(dt, 0, 0)
				end
				if inView or s.jump or s.drop then
					placePet(pet, s.at, s.yaw)
				end
			end
		end
	end
	if ghost then
		local x, z = spotAt(pointer())
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
	local special = Config.SpecialEggs[kind]
	ghost = Egg.new(if special then special.Pet else kind).model
	ghost:SetAttribute("Ghost", true) -- (not a placed egg: Client/Tutorial looks for those)
	if special and special.EggScale then
		ghost:ScaleTo(special.EggScale) -- (the Giant Horse's egg is 3x)
		Egg.fitStuds(ghost)
	end
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
	-- On a phone or tablet a tap puts the egg straight down where you tapped (QM: there's no
	-- pointer to preview it with). The tap reaches the egg as the tool's Activated, and
	-- the mouse is moved to the tap.
	tool.Activated:Connect(function()
		if Gamepad.active then
			placeAt(pointer()) -- (RT: in front of you)
		elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			placeAt(mouse.X, mouse.Y)
		end
	end)
	tool.Unequipped:Connect(drop)
end

-- A click or tap on your pen while holding an egg puts it down there. (Read
-- straight from the input, not the Tool's Activated, which some clicks never fire.)
local lastPlaced = 0
function placeAt(screenX, screenY)
	if not holding or holding.Parent ~= player.Character or os.clock() - lastPlaced < 0.3 then
		return -- (one tap can come in two ways on a phone: place it once)
	end
	local x, z = spotAt(screenX, screenY)
	if x then
		lastPlaced = os.clock()
		placeEgg:FireServer(holding:GetAttribute("EggKind"), x, z)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		placeAt(input.Position.X, input.Position.Y)
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 and holding then
		placeAt(pointer()) -- a controller's RT (also the tool's Activated: placed once)
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
