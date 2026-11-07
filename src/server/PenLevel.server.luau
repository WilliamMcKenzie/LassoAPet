-- Pen levels: everyone starts at 1, and each quest you claim takes it up one, to
-- Config.PenLevels (QM, Oct 11: Hatchery's ClaimQuest; it used to cost the next biome's
-- UnlockCost gold, UpgradePen). Pens no longer grow with it (QM, Nov 6: Fight to Steal an
-- Egg's pens, one size, built by Server/Map from the map editor's map). VIP (the game pass)
-- gilds its owner's fence and hangs banners on its corners.
-- The level lives in the player's "PenLevel" attribute and is saved like Gold.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Studs = require(ReplicatedStorage.Shared.Studs)
local Passes = require(script.Parent.Passes) -- (PassVIP: the gold fence; PassAllSlingshots, below)

-- One pen level across every world (QM, Oct 14: the pen carries over, and its size): World
-- 1's store in all of them. The old per-world levels ("PenLevel_W2"...) count too: the
-- highest of them all (read every load, so nothing's lost).
local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("PenLevel", 1))
if not ok then
	store = nil
end
local oldStores = {}
for world in Config.Places do
	if world ~= 1 then
		local okOld, old = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("PenLevel", world))
		if okOld then
			table.insert(oldStores, old)
		end
	end
end

local loaded = {}

local function level(player)
	return math.clamp(player:GetAttribute("PenLevel") or 1, 1, Config.PenLevels or #Config.Biomes)
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
				local best = tonumber(value) or 1
				for _, old in oldStores do
					local got, was = pcall(old.GetAsync, old, "u" .. player.UserId)
					if got and tonumber(was) then
						best = math.max(best, tonumber(was))
					end
				end
				player:SetAttribute("PenLevel", math.max(level(player), best))
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

local savedAs = {} -- [player] = the level last saved (autosave skips it if unchanged)

-- onlyIfChanged: the autosave's, which skips it when nothing changed.
local function save(player, onlyIfChanged)
	if not store or not loaded[player] then
		return
	end
	local value = level(player)
	if onlyIfChanged and savedAs[player] == value then
		return
	end
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, value) then
			savedAs[player] = value
			return
		end
		task.wait(attempt)
	end
end

-- Pen looks ------------------------------------------------------------------

local pens = workspace:WaitForChild("Pens")
local fenceLooks = {} -- [post, rail] = { Color, Material } as built, for when VIP goes

-- VIP (game pass): a red banner on a gold pole on each corner post of the fence,
-- facing out. Rebuilt with each repaint (the pen grows), gone without VIP.
local function bannerPart(parent, size, cframe, color, shape)
	local p = Instance.new("Part")
	p.Name = "Banner"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Size, p.CFrame, p.Color = size, cframe, color
	Studs.apply(p, 0.5)
	p.Parent = parent
end

local function vipBanners(pen, fence, vip)
	local old = pen:FindFirstChild("VipBanners")
	if old then
		old:Destroy()
	end
	local tiles = pen:FindFirstChild("Tiles")
	if not vip or not tiles then
		return
	end
	local posts = {}
	for _, part in fence:GetDescendants() do
		if part.Name == "Post" and part:IsA("BasePart") then
			table.insert(posts, part)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "VipBanners"
	local centre, half = tiles.Position, tiles.Size / 2
	local gold, red = Config.Vip.Fence.Post, Config.Vip.Banner
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		local want = tiles.CFrame:PointToWorldSpace(Vector3.new(corner.X * half.X, 0, corner.Z * half.Z)) -- (in the pen's frame)
		local best, bestD = nil, math.huge
		for _, post in posts do
			local d = (Vector3.new(post.Position.X, 0, post.Position.Z) - Vector3.new(want.X, 0, want.Z)).Magnitude
			if d < bestD then
				best, bestD = post, d
			end
		end
		if best then
			local top = best.Position + Vector3.new(0, best.Size.Y / 2, 0)
			local out = Vector3.new(top.X - centre.X, 0, top.Z - centre.Z).Unit
			local face = CFrame.lookAt(top, top + out) -- -Z faces out of the pen
			bannerPart(folder, Vector3.new(0.5, 6, 0.5), face * CFrame.new(0, 3, 0), gold) -- pole
			bannerPart(folder, Vector3.new(1.1, 1.1, 1.1), face * CFrame.new(0, 6.4, 0), gold, Enum.PartType.Ball) -- its knob
			bannerPart(folder, Vector3.new(3.4, 0.4, 0.4), face * CFrame.new(0, 5.5, -0.5), gold) -- cross bar
			bannerPart(folder, Vector3.new(3, 3.4, 0.3), face * CFrame.new(0, 3.6, -0.5), red) -- the banner
			bannerPart(folder, Vector3.new(3, 0.5, 0.35), face * CFrame.new(0, 2.1, -0.5), gold) -- its gold hem
		end
	end
	folder.Parent = pen
end

local function paintPen(pen)
	local owner = Players:GetPlayerByUserId(pen:GetAttribute("Owner") or 0)
	local vip = owner ~= nil and owner:GetAttribute("PassVIP") == true
	local fence = pen:FindFirstChild("Fence") or pen
	for _, part in fence:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "Post" or part.Name == "Rail") then
			fenceLooks[part] = fenceLooks[part] or { part.Color, part.Material }
			part.Color = if vip then Config.Vip.Fence[part.Name] else fenceLooks[part][1]
		end
	end
	vipBanners(pen, fence, vip)
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

-- Unlock All Slingshots (game pass, QM Nov 7): every biome on the Slingshot's menu unlocked,
-- as if each were bought (Server/Slingshot's GrantBiome: the pen level up to the last one).
local function allSlingshots(player)
	if player.Parent and player:GetAttribute("PassAllSlingshots") then
		local top = math.min(#Config.Biomes, Config.PenLevels or #Config.Biomes)
		if (player:GetAttribute("PenLevel") or 1) < top then
			player:SetAttribute("PenLevel", top)
		end
	end
end

local function watch(player)
	player:GetAttributeChangedSignal("PassAllSlingshots"):Connect(function()
		allSlingshots(player)
	end)
	for _, name in { "PassVIP" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			local pen = penOf(player)
			if pen then
				paintPen(pen)
			end
		end)
	end
	load(player)
	Passes.owns(player, "AllSlingshots") -- (waits for the join check)
	allSlingshots(player)
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	task.spawn(watch, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player], savedAs[player] = nil, nil
end)

-- Autosave (QM, Oct 4): every Config.AutosaveEvery seconds each player's pen level is saved
-- if it changed since it was last saved (so a server crash loses that much at most),
-- spread out over the interval to stay inside the DataStore budget. Shutting down
-- saves everyone and waits for the saves to finish (Roblox allows up to 30 s).
task.spawn(function()
	while true do
		local list = Players:GetPlayers()
		if #list == 0 then
			task.wait(Config.AutosaveEvery)
			continue
		end
		for _, player in list do
			task.wait(Config.AutosaveEvery / #list)
			if player.Parent then
				task.spawn(save, player, true)
			end
		end
	end
end)

game:BindToClose(function()
	local left = 0
	for _, player in Players:GetPlayers() do
		left += 1
		task.spawn(function()
			save(player)
			left -= 1
		end)
	end
	local deadline = os.clock() + 25
	while left > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
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

-- Returns true if the upgrade went through. Off with Config.PenUpgrades (QM, Oct 11:
-- claiming a quest upgrades your pen now, Hatchery's ClaimQuest).
upgrade.OnServerInvoke = function(player)
	if not Config.PenUpgrades then
		return false
	end
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
