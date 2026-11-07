-- The Top Earners board (Config.TopEarners, QM Nov 6): left of the start line, the players
-- whose pens earn the most gold a second, worldwide, in a square stone frame.
--
-- Builds workspace.TopEarners: the frame's meshes (tools/earners_board_meshes.py, uploaded by
-- tools/earners_board_upload.py) and "Screen", the Part in its opening that
-- Client/TopEarners draws the list on.
-- Every Refresh seconds it records everyone here (their "PenIncome" attribute, Hatchery's:
-- gold a second, x2 Gold and rebirths in) in the OrderedDataStore "TopEarners" ("u" .. UserId
-- = their latest, not their best: "latest recorded"), then reads the Top back, mixed with
-- this server's players' latest (so it works in Studio without API access too), and puts
-- it in ReplicatedStorage.TopEarners (a StringValue: JSON { { id, name, display, gold } },
-- best first; its "Next" attribute is the server time of the next refresh).

local AssetService = game:GetService("AssetService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Config = require(ReplicatedStorage.Shared.Config)
local Studs = require(ReplicatedStorage.Shared.Studs)

local CFG = Config.TopEarners
local MAX = 2 ^ 53 -- (an OrderedDataStore holds whole numbers)

-- ---- the board --------------------------------------------------------------

local origin = CFrame.new(CFG.Position) * CFrame.Angles(0, math.rad(CFG.Yaw), 0)
local model = Instance.new("Model")
model.Name = "TopEarners"
for i, piece in CFG.Meshes do
	local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromUri("rbxassetid://" .. piece[1]))
	if ok then
		part.Name = "Frame" .. i
		part.Anchored = true
		part.Color = Color3.fromRGB(piece[2], piece[3], piece[4])
		part.CFrame = origin -- (an uploaded EditableMesh keeps its own origin: the board's, as the Slingshot's pieces)
		Studs.apply(part, 0.5)
		part.Locked = true
		part.Parent = model
	else
		warn("TopEarners: mesh " .. piece[1] .. " didn't load: " .. tostring(part))
	end
end
if #CFG.Meshes == 0 then
	warn("TopEarners: no frame meshes yet (Config.TopEarners.Meshes: tools/earners_board_upload.py)")
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
