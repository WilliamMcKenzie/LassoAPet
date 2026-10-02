-- Pen levels: your pen's level is how many biomes you've unlocked. Everyone
-- starts at 1 (the first biome). Upgrading to level n costs Config.Biomes[n].
-- UnlockCost gold (UpgradePen), opens biome n's gate for you (Gate.client) and
-- repaints your pen for everyone: its N x N floor tiles (the pen's Tiles marker)
-- take biome n's ground colours and its posts biome n's PostColor.
-- The level lives in the player's "PenLevel" attribute and is saved like Gold.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- A thin copy of the ground over the pen's tiles, with the ground's checker.
local function floorOf(pen)
	local floor = pen:FindFirstChild("Floor")
	local tiles = pen:FindFirstChild("Tiles")
	if floor or not tiles then
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
	for _, part in pen:GetChildren() do
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

-- Returns true if the upgrade went through.
upgrade.OnServerInvoke = function(player)
	local nextBiome = Config.Biomes[level(player) + 1]
	local cost = nextBiome and nextBiome.UnlockCost
	local gold = player:GetAttribute("Gold") or 0
	if not cost or gold < cost then
		return false
	end
	player:SetAttribute("Gold", gold - cost)
	player:SetAttribute("PenLevel", level(player) + 1)
	return true
end
