-- Pen levels: your pen's level is how many biomes you've unlocked. Everyone
-- starts at 1 (the first biome). Upgrading to level n costs Config.Biomes[n].
-- UnlockCost gold (UpgradePen), opens biome n's gate for you (Gate.client) and
-- repaints your pen for everyone: its N x N floor tiles (the pen's Tiles marker)
-- take biome n's ground colours and its posts biome n's PostColor. The pen also
-- grows with each level (QM, Oct 3), up to about twice the area at the Ocean:
-- each pen's Sizes folder (tools/pens.py) holds one SizeK model per level, a
-- fence and its markers laid out for that size. The owner's level picks the
-- one on show, and the pen's live markers (Spawn, Sign, Area, Tiles, Slots)
-- move onto its copies, so pets, eggs and rides follow without knowing.
-- The level lives in the player's "PenLevel" attribute and is saved like Gold.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "PenLevel")
if not ok then
	store = nil
end

local loaded = {}

local function level(player)
	return math.clamp(player:GetAttribute("PenLevel") or 1, 1, #Config.Biomes)
end

local function load(player)
	player:SetAttribute("PenLevel", 1)
	if not store then
		return
	end
	for attempt = 1, 3 do
		local success, value = pcall(store.GetAsync, store, "u" .. player.UserId)
		if success then
			if player.Parent then
				player:SetAttribute("PenLevel", math.max(level(player), tonumber(value) or 1))
				loaded[player] = true
			end
			return
		end
		if attempt == 3 or RunService:IsStudio() then
			break -- no API access in Studio fails every time: don't keep the player waiting
		end
		task.wait(attempt * 2)
	end
end

local function save(player)
	if not store or not loaded[player] then
		return
	end
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, level(player)) then
			return
		end
		task.wait(attempt)
	end
end

-- Pen looks ------------------------------------------------------------------

local world = workspace:WaitForChild("World")
local pens = workspace:WaitForChild("Pens")
local postColors = {} -- [post] = its level 1 colour

-- Pen sizes ------------------------------------------------------------------

local spare = Instance.new("Folder") -- the sizes not on show
spare.Name = "PenSizes"
spare.Parent = ServerStorage
local sizes = {} -- [pen] = { [k] = SizeK model }

local function sizesOf(pen)
	if not sizes[pen] then
		sizes[pen] = {}
		local folder = pen:FindFirstChild("Sizes")
		for _, model in (if folder then folder:GetChildren() else {}) do
			local k = tonumber(model.Name:match("^Size(%d+)$"))
			if k then
				sizes[pen][k] = model
			end
		end
	end
	return sizes[pen]
end

local function copyBox(from, to)
	if from and to then
		to.Size = from.Size
		to.CFrame = from.CFrame
	end
end

-- Shows the size for level n (the biggest there is, past the last) and moves
-- the live markers onto it. Returns the fence model on show.
local function sizePen(pen, n)
	local list = sizesOf(pen)
	local k = math.min(n, #list)
	for i, model in list do
		model.Parent = if i == k then pen.Sizes else spare
	end
	local shown = list[k]
	if not shown then
		return nil
	end
	for _, name in { "Spawn", "Sign", "Area", "Tiles" } do
		copyBox(shown:FindFirstChild(name), pen:FindFirstChild(name))
	end
	local slots, liveSlots = shown:FindFirstChild("Slots"), pen:FindFirstChild("Slots")
	if slots and liveSlots then
		for _, slot in slots:GetChildren() do
			copyBox(slot, liveSlots:FindFirstChild(slot.Name))
		end
	end
	return shown
end

-- A thin copy of the ground over the pen's tiles, with the ground's checker.
local function floorOf(pen)
	local floor = pen:FindFirstChild("Floor")
	local tiles = pen:FindFirstChild("Tiles")
	if floor or not tiles then
		if floor and tiles then -- the pen may have grown
			floor.Size = Vector3.new(tiles.Size.X, 0.1, tiles.Size.Z)
			floor.CFrame = CFrame.new(tiles.Position.X, 0.05, tiles.Position.Z)
		end
		return floor
	end
	floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.CanCollide = false
	floor.CanQuery = false
	floor.CanTouch = false
	floor.CastShadow = false
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.Size = Vector3.new(tiles.Size.X, 0.1, tiles.Size.Z)
	floor.CFrame = CFrame.new(tiles.Position.X, 0.05, tiles.Position.Z)
	local ground = world.Ground:GetChildren()[1]
	for _, texture in ground:GetChildren() do
		if texture:IsA("Texture") then
			texture:Clone().Parent = floor
		end
	end
	floor.Parent = pen
	return floor
end

local function paintPen(pen)
	local owner = Players:GetPlayerByUserId(pen:GetAttribute("Owner") or 0)
	local n = if owner then level(owner) else 1
	local fence = sizePen(pen, n) or pen
	local floor = floorOf(pen)
	if floor then
		local show = n > 1
		floor.Transparency = if show then 0 else 1
		for _, texture in floor:GetChildren() do
			if texture:IsA("Texture") then
				texture.Transparency = if show then 0 else 1
			end
		end
		if show then
			local prefix = WorldColors.prefix(n)
			floor.Color = world:GetAttribute(prefix .. "GroundA") or Config.Biomes[n].GroundColors[1]
			for _, texture in floor:GetChildren() do
				if texture.Name == "Checker" then
					texture.Color3 = world:GetAttribute(prefix .. "GroundB") or Config.Biomes[n].GroundColors[2]
				end
			end
		end
	end
	for _, part in fence:GetChildren() do
		if part.Name == "Post" then
			postColors[part] = postColors[part] or part.Color
			part.Color = if n > 1 and Config.Biomes[n].PostColor then Config.Biomes[n].PostColor else postColors[part]
		end
	end
end

for _, pen in pens:GetChildren() do
	pen:GetAttributeChangedSignal("Owner"):Connect(function()
		paintPen(pen)
	end)
	paintPen(pen)
end

local function penOf(player)
	local index = player:GetAttribute("Pen")
	local pen = index and pens:FindFirstChild("Pen" .. index)
	return if pen and pen:GetAttribute("Owner") == player.UserId then pen else nil
end

local function watch(player)
	player:GetAttributeChangedSignal("PenLevel"):Connect(function()
		local pen = penOf(player)
		if pen then
			paintPen(pen)
		end
	end)
	load(player)
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(2)
end)

-- Buying the next level --------------------------------------------------------

local upgrade = Instance.new("RemoteFunction")
upgrade.Name = "UpgradePen"
upgrade.Parent = ReplicatedStorage
-- Tells the buyer which biome they just opened, ahead of PenLevel changing, so
-- its gate breaks open on camera (Gate.client) instead of quietly fading as it
-- does when your saved level loads.
local zoneUnlocked = Instance.new("RemoteEvent")
zoneUnlocked.Name = "ZoneUnlocked"
zoneUnlocked.Parent = ReplicatedStorage

-- Returns true if the upgrade went through.
upgrade.OnServerInvoke = function(player)
	local nextBiome = Config.Biomes[level(player) + 1]
	local cost = nextBiome and nextBiome.UnlockCost
	local gold = player:GetAttribute("Gold") or 0
	if not cost or gold < cost then
		return false
	end
	player:SetAttribute("Gold", gold - cost)
	zoneUnlocked:FireClient(player, level(player) + 1)
	player:SetAttribute("PenLevel", level(player) + 1)
	return true
end
