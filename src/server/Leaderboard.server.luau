-- The podium (Config.Podium): the Roblox avatar of the player who rode furthest from
-- base, standing on the cap of QM's cream marble column in the middle of the grass snake's
-- coil (Props/GrassSnake, built by PodiumSnake.client) in the base's right front
-- corner. First place only, and no text for now (QM, Oct 4).
--
-- Distance is the HUD's: metres past the start line (4 studs a metre), read off
-- each rider's RideSync (Riders.server passes those on; this only listens).
-- Everyone's best is kept all time in the OrderedDataStore "BestDistance"
-- ("u" .. UserId = metres), only ever raised. The server checks each ride (QM, Oct 4):
-- it only counts if it set out from home (the first sync near the start line) and
-- never went faster than MAX_SPEED between syncs (no pet gets near it, whatever it's
-- merged or boosted to); a ride that breaks either (a teleport, the /biome warp, a
-- speed hack) doesn't count until that player is home again.
-- The podium re-reads the leader every Refresh seconds, mixed with this server's
-- own bests so far, so it works in Studio without API access too.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GrassSnake = require(ReplicatedStorage.Shared.Props.GrassSnake)

local STUDS_PER_METRE = 4 -- Ride.client's
local MAX_SPEED = 1500 -- studs a second: 44 x 8 (MergeMaxSpeed) x 2 (sprint) x 2 (a boost), and some
local SLACK = 60 -- studs of leeway on top, for sync jitter
local START_NEAR = -200 -- a ride's first sync must be closer to home than this (z)
local FLUSH = 30 -- seconds between saving raised bests

local podium = Config.Podium
local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "BestDistance")
if not ok then
	store = nil
end

local best = {} -- [userId] = metres, this server's riders
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

-- Where the winner stands: on the column's cap (the snake is the client's), facing
-- into the base (+z).
local origin = CFrame.new(podium.Position + Vector3.new(0, GrassSnake.capTop.Y * podium.SnakeScale, 0))
	* CFrame.Angles(0, math.pi, 0) -- (a character looks along its -z)
local model = Instance.new("Model")
model.Name = "Podium"
model.Parent = workspace

-- Who's standing there: { id, avatar }.
local standing

-- The leader strikes a victory pose (QM): Roblox's own Cheer emote, both arms flung up,
-- held still at its peak. Swap POSE (and POSE_AT, seconds into it) for another.
local POSE = { R15 = "rbxassetid://507770677", R6 = "rbxassetid://129423030" } -- Cheer
local POSE_AT = 0.45

local function idle(avatar)
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local animation = Instance.new("Animation")
	animation.AnimationId = if humanoid.RigType == Enum.HumanoidRigType.R15 then POSE.R15 else POSE.R6
	task.spawn(pcall, function()
		local track = animator:LoadAnimation(animation)
		track.Looped = false
		track.Priority = Enum.AnimationPriority.Action
		for _ = 1, 50 do -- (its length is 0 until it has loaded)
			if track.Length > 0 then
				break
			end
			task.wait(0.1)
		end
		track:Play(0)
		track:AdjustSpeed(0) -- held at its peak
		track.TimePosition = math.min(POSE_AT, track.Length)
	end)
end

local function stand(id)
	if standing and standing.id == id then
		return
	end
	if standing then
		standing.avatar:Destroy()
		standing = nil
	end
	if not id then
		return
	end
	local okModel, avatar = pcall(Players.CreateHumanoidModelFromUserId, Players, id)
	if not okModel or not avatar then
		return
	end
	avatar.Name = "Leader"
	-- Only the root is anchored: limbs held by their joints can be posed (anchored ones
	-- can't move, which left the avatar stiff).
	for _, part in avatar:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = part.Name == "HumanoidRootPart"
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	avatar:ScaleTo(podium.AvatarScale)
	-- Feet on the cap.
	local box, size = avatar:GetBoundingBox()
	local pivot = avatar:GetPivot()
	avatar:PivotTo(origin * CFrame.new(0, size.Y / 2 + (pivot.Position.Y - box.Position.Y), 0))
	avatar.Parent = model
	idle(avatar)
	standing = { id = id, avatar = avatar }
end

local function refresh()
	local scores = {} -- [userId] = metres
	if store then
		local okPages, pages = pcall(store.GetSortedAsync, store, false, 1)
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
	local leader, most = nil, 0
	for id, metres in scores do
		if metres > most then
			leader, most = id, metres
		end
	end
	stand(leader)
end

task.spawn(function()
	while true do
		refresh()
		task.wait(podium.Refresh)
	end
end)
