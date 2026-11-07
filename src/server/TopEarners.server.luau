-- The Top Earners board (Config.TopEarners, QM Nov 6): left of the start line, the players
-- whose pens earn the most gold a second, worldwide, in a grass-and-dirt frame with a gold crown.
--
-- Builds workspace.TopEarners: the frame (plain blocks in the map's look, Shared/VoxelBlock) and
-- "Screen", the Part in its opening that
-- Client/TopEarners draws the list on.
-- Every Refresh seconds it records everyone here (their "PenIncome" attribute, Hatchery's:
-- gold a second, x2 Gold and rebirths in) in the OrderedDataStore "TopEarners" ("u" .. UserId
-- = their latest, not their best: "latest recorded"), then reads the Top back, mixed with
-- this server's players' latest (so it works in Studio without API access too), and puts
-- it in ReplicatedStorage.TopEarners (a StringValue: JSON { { id, name, display, gold } },
-- best first; its "Next" attribute is the server time of the next refresh).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Config = require(ReplicatedStorage.Shared.Config)
local VoxelBlock = require(ReplicatedStorage.Shared.VoxelBlock)

local CFG = Config.TopEarners
local MAX = 2 ^ 53 -- (an OrderedDataStore holds whole numbers)

-- ---- the board --------------------------------------------------------------

local origin = CFrame.new(CFG.Position) * CFrame.Angles(0, math.rad(CFG.Yaw), 0)
local model = Instance.new("Model")
model.Name = "TopEarners"
-- The frame (QM, Nov 7: the stone gate "looks bad", remade in the map's look): a grass-topped
-- dirt plinth, two dirt pillars, a gold trim round the screen, a lintel capped with grass like
-- the map's walls, and a blocky gold crown on top. Board space: the board faces -z, the
-- opening centred on x = 0 from s.Bottom up s.Height.
do
	local s = CFG.Screen
	local C = Config.WorldColors
	local DIRT, DIRT_C = C.WallDirt, C.WallDirtChecker
	local GRASS, GRASS_C = C.Grass, C.GrassChecker
	local GOLD = Color3.fromRGB(255, 196, 40)
	local function b(name, x0, y0, z0, x1, y1, z1, color, checker)
		return VoxelBlock.at(model, origin, name, x0, y0, z0, x1, y1, z1, color, checker)
	end
	local hw = s.Width / 2
	local bottom, top = s.Bottom, s.Bottom + s.Height
	local px = hw + 6 -- each pillar's outer face
	local sill = bottom - 1.4
	-- the plinth: dirt, a grass cap with a lip
	b("Plinth", -px - 1.5, -0.5, -5, px + 1.5, sill - 1, 4, DIRT, DIRT_C)
	b("PlinthCap", -px - 2, sill - 1, -5.5, px + 2, sill, 4.5, GRASS, GRASS_C)
	for side = -1, 1, 2 do
		-- a dirt pillar, a grass band low on it, and the gold trim down the opening's edge
		b("Pillar", side * (hw + 0.4), sill, -3, side * px, top + 1.2, 3, DIRT, DIRT_C)
		b("PillarBand", side * (hw + 0.4), sill + 3, -3.4, side * (px + 0.4), sill + 4.2, 3.4, GRASS, GRASS_C)
		b("TrimSide", side * (hw + 0.2), sill, -3.6, side * (hw + 1.4), top + 1.2, -2.4, GOLD)
	end
	b("TrimBottom", -hw - 1.4, sill, -3.6, hw + 1.4, bottom, -2.4, GOLD)
	b("TrimTop", -hw - 1.4, top, -3.6, hw + 1.4, top + 1.2, -2.4, GOLD)
	-- the lintel: dirt with a grass cap overhanging it, as the map's walls
	local y = top + 1.2
	b("Lintel", -px - 1, y, -3.5, px + 1, y + 4, 3.5, DIRT, DIRT_C)
	b("LintelCap", -px - 1.8, y + 4, -4.3, px + 1.8, y + 6, 4.3, GRASS, GRASS_C)
	y += 6
	-- the crown: a band, five prongs (the middle and outer ones taller), gems on its front
	b("CrownBand", -6, y, -2.5, 6, y + 2.8, 2.5, GOLD)
	for i = -2, 2 do
		local tall = if i == 0 then 3.6 elseif math.abs(i) == 2 then 2.8 else 1.8
		local x = i * 2.6
		b("CrownProng", x - 0.8, y + 2.8, -1.6, x + 0.8, y + 2.8 + tall, 1.6, GOLD)
		if i % 2 == 0 then
			b("CrownTip", x - 0.6, y + 2.8 + tall, -0.6, x + 0.6, y + 3.8 + tall, 0.6, Color3.fromRGB(255, 236, 140), false)
		end
	end
	for _, side in { -1, 1 } do
		b("Gem", side * 4.4 - 0.7, y + 0.7, -2.9, side * 4.4 + 0.7, y + 2.1, -2.3, Color3.fromRGB(60, 160, 255), false)
	end
	b("Gem", -1.1, y + 0.5, -2.9, 1.1, y + 2.3, -2.3, Color3.fromRGB(235, 45, 60), false)
end
local s = CFG.Screen
local screen = Instance.new("Part")
screen.Name = "Screen"
screen.Anchored = true
screen.CanQuery = false
screen.CanTouch = false
screen.Material = Enum.Material.SmoothPlastic
screen.Color = Color3.fromRGB(10, 14, 12)
screen.Size = Vector3.new(s.Width + 0.4, s.Height, 0.6)
screen.CFrame = origin * CFrame.new(0, s.Bottom + s.Height / 2, -2.2) -- (its front, the list's face, at -2.5: in the frame's opening)
screen.Locked = true
screen.Parent = model
model.PrimaryPart = screen
model.Parent = workspace

-- ---- the list ---------------------------------------------------------------

local value = Instance.new("StringValue")
value.Name = "TopEarners"
value.Value = "[]"
value.Parent = ReplicatedStorage

local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.storeName("TopEarners"))
if not ok then
	store = nil
end

local recorded = {} -- [userId] = the gold a second last saved for them
local names = {} -- [userId] = { name, display }

local function record(player)
	local id = player.UserId
	local gold = math.clamp(math.floor(tonumber(player:GetAttribute("PenIncome")) or 0), 0, MAX)
	if not store or id <= 0 or recorded[id] == gold then
		return -- (Studio's test players have negative ids)
	end
	recorded[id] = gold
	pcall(store.SetAsync, store, "u" .. id, gold)
end

local function lookUp(ids)
	local missing = {}
	for _, id in ids do
		if not names[id] and id > 0 then
			table.insert(missing, id)
		end
	end
	if #missing > 0 then
		local okInfo, infos = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, missing)
		if okInfo then
			for _, info in infos do
				names[info.Id] = { info.Username, info.DisplayName }
			end
		end
	end
	for _, id in ids do
		if not names[id] then
			local player = Players:GetPlayerByUserId(id)
			if player then
				names[id] = { player.Name, player.DisplayName }
			else
				local okName, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
				if okName and name then
					names[id] = { name, name }
				end
			end
		end
	end
end

local function refresh()
	local gold = {} -- [userId] = gold a second
	for _, player in Players:GetPlayers() do
		record(player)
	end
	if store then
		local okPages, pages = pcall(store.GetSortedAsync, store, false, CFG.Top)
		if okPages then
			for _, entry in pages:GetCurrentPage() do
				local id = tonumber(string.match(entry.key, "^u(%d+)$"))
				if id then
					gold[id] = entry.value
				end
			end
		end
	end
	for _, player in Players:GetPlayers() do -- (theirs live: their latest)
		local mine = tonumber(player:GetAttribute("PenIncome")) or 0
		if mine > 0 then
			gold[player.UserId] = mine
		end
	end
	local rows = {}
	for id, g in gold do
		if g > 0 then
			table.insert(rows, { id = id, gold = g })
		end
	end
	table.sort(rows, function(a, b)
		return a.gold > b.gold
	end)
	while #rows > CFG.Top do
		table.remove(rows)
	end
	local ids = {}
	for _, row in rows do
		table.insert(ids, row.id)
	end
	lookUp(ids)
	local out = {}
	for _, row in rows do
		local n = names[row.id] or { "Player", "Player" }
		table.insert(out, { row.id, n[1], n[2], row.gold })
	end
	value:SetAttribute("Next", workspace:GetServerTimeNow() + CFG.Refresh)
	value.Value = HttpService:JSONEncode(out)
end

Players.PlayerRemoving:Connect(record)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		record(player)
	end
end)

task.spawn(function()
	task.wait(5) -- (the first players' pens loaded: their PenIncome set)
	while true do
		refresh()
		task.wait(CFG.Refresh)
	end
end)
