-- The top-3 podium (Config.Podium): the Roblox avatars of the three players who
-- rode furthest from base, standing on gold, silver and bronze steps in the gap
-- between the right corner pen and the start line.
--
-- Distance is the HUD's: metres past the start line (4 studs a metre), read off
-- each rider's RideSync (Riders.server passes those on; this only listens).
-- Everyone's best is kept all time in the OrderedDataStore "BestDistance"
-- ("u" .. UserId = metres), only ever raised. The server checks each ride (QM, Oct 4):
-- it only counts if it set out from home (the first sync near the start line) and
-- never went faster than MAX_SPEED between syncs (no pet gets near it, whatever it's
-- merged or boosted to); a ride that breaks either (a teleport, the /biome warp, a
-- speed hack) doesn't count until that player is home again.
-- The podium re-reads the top 3 every Refresh seconds, mixed with this server's
-- own bests so far, so it works in Studio without API access too.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STUDS_PER_METRE = 4 -- Ride.client's
local MAX_SPEED = 1500 -- studs a second: 44 x 8 (MergeMaxSpeed) x 2 (sprint) x 2 (a boost), and some
local SLACK = 60 -- studs of leeway on top, for sync jitter
local START_NEAR = -200 -- a ride's first sync must be closer to home than this (z)
local FLUSH = 30 -- seconds between saving raised bests
local STUDS = "rbxassetid://7447638591" -- the classic stud decal the animals use
local STUD_TILE = 0.5

local podium = Config.Podium
local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "BestDistance")
if not ok then
	store = nil
end

local best = {} -- [userId] = metres, this server's riders
local names = {} -- [userId] = name
local dirty = {} -- [userId] = true: best raised since the last save
local lastZ = {} -- [player] = rider z at their last sync
local lastAt = {} -- [player] = os.clock() of their last sync
local warped = {} -- [player] = true: teleported this ride, not counted till home

ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _mountCFrame, riderCFrame)
	if type(kind) ~= "string" or typeof(riderCFrame) ~= "CFrame" then
		return
	end
	local z = riderCFrame.Position.Z
	if z ~= z or math.abs(z) > 1e7 then
		return
	end
	local now = os.clock()
	if not lastZ[player] then
		if z < START_NEAR then
			warped[player] = true -- didn't set out from home
		end
	elseif math.abs(z - lastZ[player]) > MAX_SPEED * (now - lastAt[player]) + SLACK then
		warped[player] = true
	end
	lastZ[player], lastAt[player] = z, now
	if z > 0 then
		warped[player] = nil -- home again
		return
	end
	if warped[player] then
		return
	end
	local metres = math.floor(-z / STUDS_PER_METRE)
	local id = player.UserId
	if metres > (best[id] or 0) then
		best[id] = metres
		names[id] = player.DisplayName
		dirty[id] = true
	end
end)

-- A ride's over: the next one has to set out from home again.
ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
	if what == "end" then
		lastZ[player], lastAt[player] = nil, nil
	end
end)

local function save(id)
	if not dirty[id] then
		return
	end
	dirty[id] = nil
	if not store or id <= 0 then -- (Studio's test players have negative ids)
		return
	end
	local metres = best[id]
	pcall(store.UpdateAsync, store, "u" .. id, function(old)
		return if metres > (tonumber(old) or 0) then metres else nil
	end)
end

task.spawn(function()
	while true do
		task.wait(FLUSH)
		for id in dirty do
			save(id)
		end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	lastZ[player], lastAt[player], warped[player] = nil, nil, nil
	save(player.UserId)
end)
game:BindToClose(function()
	for id in dirty do
		save(id)
	end
end)

-- The podium: 2nd on the left, 1st in the middle, 3rd on the right (as you look
-- at it from the base), numbers on their fronts.
local origin = CFrame.new(podium.Position) * CFrame.Angles(0, math.pi, 0) -- front faces into the base (+z)
local model = Instance.new("Model")
model.Name = "Podium"

local function block(name, size, at, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = origin * at
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for _, face in Enum.NormalId:GetEnumItems() do
		local texture = Instance.new("Texture")
		texture.Texture = STUDS
		texture.StudsPerTileU = STUD_TILE
		texture.StudsPerTileV = STUD_TILE
		texture.Face = face
		texture.Parent = part
	end
	part.Parent = model
	return part
end

local function text(parent, size, value)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = value
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = parent
	return label
end

local STEP_W, STEP_D = 5.6, 6
local STEPS = { -- rank: x (in the podium's frame, + = the viewer's left), height, colour
	{ x = 0, h = 4.5, color = Color3.fromRGB(255, 204, 40) },
	{ x = STEP_W, h = 3, color = Color3.fromRGB(200, 208, 222) },
	{ x = -STEP_W, h = 2, color = Color3.fromRGB(222, 132, 64) },
}
block("Base", Vector3.new(STEP_W * 3 + 1, 0.6, STEP_D + 1), CFrame.new(0, 0.3, 0), Color3.fromRGB(62, 62, 72))
for rank, step in STEPS do
	local part = block("Step" .. rank, Vector3.new(STEP_W, step.h, STEP_D), CFrame.new(step.x, 0.6 + step.h / 2, 0), step.color)
	local number = Instance.new("SurfaceGui")
	number.Face = Enum.NormalId.Front -- the podium's front, toward the base
	number.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	number.PixelsPerStud = 40
	number.LightInfluence = 0
	text(number, UDim2.fromScale(1, 0.9), tostring(rank)).Position = UDim2.fromScale(0, 0.05)
	number.Parent = part
	step.top = 0.6 + step.h
end

local title = Instance.new("BillboardGui")
title.Name = "Title"
title.Size = UDim2.fromOffset(320, 44)
-- Over the winner's name: about where a usual avatar's head is, lifted past the name sign.
title.StudsOffsetWorldSpace = Vector3.new(0, STEPS[1].h / 2 + 5.5 * podium.AvatarScale + 1.5, 0)
title.SizeOffset = Vector2.new(0, 1.3)
title.MaxDistance = 200
title.Adornee = model:FindFirstChild("Step1")
text(title, UDim2.fromScale(1, 1), "FURTHEST RIDES")
title.Parent = model

model.Parent = workspace

-- Who's standing on each step: { id, metres, avatar, sign }.
local standing = {}

local function sign(parent, adornee, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Name"
	gui.Size = UDim2.fromOffset(180, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.5, 0)
	gui.MaxDistance = 150
	gui.Adornee = adornee
	local name = text(gui, UDim2.fromScale(1, 0.55), "")
	local metres = text(gui, UDim2.fromScale(1, 0.45), "")
	metres.Position = UDim2.fromScale(0, 0.55)
	metres.TextColor3 = Color3.fromRGB(150, 255, 140)
	gui.Parent = parent
	return gui, name, metres
end

local function idle(avatar)
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local animation = Instance.new("Animation")
	animation.AnimationId = if humanoid.RigType == Enum.HumanoidRigType.R15
		then "rbxassetid://507766666" -- the default R15 idle
		else "rbxassetid://180435571" -- the default R6 idle
	pcall(function()
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end)
end

local function stand(rank, id, metres, name)
	local spot = standing[rank]
	if spot and spot.id == id then
		spot.metresText.Text = string.format("%d m", metres)
		return
	end
	if spot then
		spot.holder:Destroy()
		standing[rank] = nil
	end
	if not id then
		return
	end
	local okModel, avatar = pcall(Players.CreateHumanoidModelFromUserId, Players, id)
	if not okModel or not avatar then
		return
	end
	local step = STEPS[rank]
	avatar.Name = "Avatar"
	for _, part in avatar:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	avatar:ScaleTo(podium.AvatarScale)
	-- Feet on the step, facing the base.
	local box, size = avatar:GetBoundingBox()
	local pivot = avatar:GetPivot()
	local feet = origin * CFrame.new(step.x, step.top, 0) -- (a character looks along its -z, as origin does)
	avatar:PivotTo(feet * CFrame.new(0, size.Y / 2 + (pivot.Position.Y - box.Position.Y), 0))
	local holder = Instance.new("Model")
	holder.Name = "Rank" .. rank
	avatar.Parent = holder
	local _, nameText, metresText = sign(holder, model:FindFirstChild("Step" .. rank), step.h / 2 + size.Y)
	nameText.Text = name
	metresText.Text = string.format("%d m", metres)
	holder.Parent = model
	idle(avatar)
	standing[rank] = { id = id, holder = holder, metresText = metresText }
end

local function nameOf(id)
	if not names[id] then
		local okName, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
		names[id] = okName and name or "?"
	end
	return names[id]
end

local function refresh()
	local scores = {} -- [userId] = metres
	if store then
		local okPages, pages = pcall(store.GetSortedAsync, store, false, 3)
		if okPages then
			for _, entry in pages:GetCurrentPage() do
				local id = tonumber(string.match(entry.key, "^u(%d+)$"))
				if id then
					scores[id] = entry.value
				end
			end
		end
	end
	for id, metres in best do
		scores[id] = math.max(scores[id] or 0, metres)
	end
	local top = {}
	for id, metres in scores do
		if metres > 0 then
			table.insert(top, { id = id, metres = metres })
		end
	end
	table.sort(top, function(a, b)
		return a.metres > b.metres
	end)
	for rank = 1, 3 do
		local entry = top[rank]
		if entry then
			stand(rank, entry.id, entry.metres, nameOf(entry.id))
		else
			stand(rank, nil)
		end
	end
end

task.spawn(function()
	while true do
		refresh()
		task.wait(podium.Refresh)
	end
end)
