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
local Studs = require(ReplicatedStorage.Shared.Studs)
local Funnel = require(script.Parent.Funnel)
require(script.Parent.Passes) -- (PassVIP: the gold fence, below)

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

local world = workspace:WaitForChild("World")
local pens = workspace:WaitForChild("Pens")
local postColors = {} -- [post] = its level 1 colour
local fenceLooks = {} -- [rail or brace] = { Color, Material } as built, for when VIP goes

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
-- Top at 0.3: the underlying ground textures bleed through the old 0.1 gap at shallow angles.
local function floorOf(pen)
	local floor = pen:FindFirstChild("Floor")
	local tiles = pen:FindFirstChild("Tiles")
	if floor or not tiles then
		if floor and tiles then -- the pen may have grown
			floor.Size = Vector3.new(tiles.Size.X, 0.1, tiles.Size.Z)
			floor.CFrame = CFrame.new(tiles.Position.X, 0.25, tiles.Position.Z)
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
	floor.CFrame = CFrame.new(tiles.Position.X, 0.25, tiles.Position.Z)
	local ground = world.Ground:GetChildren()[1]
	for _, texture in ground:GetChildren() do
		if texture:IsA("Texture") then
			texture:Clone().Parent = floor
		end
	end
	floor.Parent = pen
	return floor
end

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
		local want = centre + Vector3.new(corner.X * half.X, 0, corner.Z * half.Z)
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
	local n = if owner then level(owner) else 1
	local fence = sizePen(pen, n) or pen
	local floor = floorOf(pen)
	if floor then
		local show = n > 1 and not fence:GetAttribute("CustomFloor")
		floor.Transparency = if show then 0 else 1
		for _, texture in floor:GetChildren() do
			if texture:IsA("Texture") then
				texture.Transparency = if show then 0 else 1
			end
		end
		if show then
			local prefix = WorldColors.prefix(n)
			floor.Color = WorldColors.saturate(world:GetAttribute(prefix .. "GroundA") or Config.Biomes[n].GroundColors[1])
			for _, texture in floor:GetChildren() do
				if texture.Name == "Checker" then
					texture.Color3 = WorldColors.saturate(world:GetAttribute(prefix .. "GroundB") or Config.Biomes[n].GroundColors[2])
				end
			end
		end
	end
	local vip = owner ~= nil and owner:GetAttribute("PassVIP") == true
	for _, part in fence:GetDescendants() do
		if part.Name == "Post" then
			postColors[part] = postColors[part] or part.Color
			part.Color = if vip then Config.Vip.Fence.Post
				elseif n > 1 and Config.Biomes[n].PostColor then Config.Biomes[n].PostColor
				else postColors[part]
		elseif part:IsA("BasePart") and (part.Name == "Rail" or part.Name == "Brace") then
			fenceLooks[part] = fenceLooks[part] or { part.Color, part.Material }
			part.Color = if vip then Config.Vip.Fence[part.Name] else fenceLooks[part][1]
			-- (the Godlands' Neon lava rails go plain gold; the rest keep their studs)
			part.Material = if vip and fenceLooks[part][2] == Enum.Material.Neon then Enum.Material.SmoothPlastic else fenceLooks[part][2]
		end
	end
	vipBanners(pen, fence, vip)
end

-- The Godlands' own pen (Server/GodlandsPen), built from each pen's biggest size
-- when the place has none for it.
do
	local godlands
	for i, biome in Config.Biomes do
		if biome.Name == "Godlands" then
			godlands = i
		end
	end
	local GodlandsPen = require(script.Parent.GodlandsPen)
	for _, pen in pens:GetChildren() do
		local list = sizesOf(pen)
		if godlands and pen:FindFirstChild("Sizes") and not list[godlands] and list[godlands - 1] then
			local model = GodlandsPen.build(list[godlands - 1])
			model.Name = "Size" .. godlands
			model.Parent = spare
			list[godlands] = model
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
	for _, name in { "PenLevel", "PassVIP" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			local pen = penOf(player)
			if pen then
				paintPen(pen)
			end
		end)
	end
	load(player)
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
	if level(player) == 2 then
		player:SetAttribute("FuseLesson", true) -- fusing opens with the Desert: the lesson's due (Hatchery saves it; client FuseLesson)
		player:SetAttribute("DesertAt", os.time()) -- (Stats.server: how long they stay after)
	end
	Funnel.step(player, "Unlocked Zone 2")
	Funnel.zone(player, level(player))
	return true
end
