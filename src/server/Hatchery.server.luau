-- Eggs you bring home and the pets they hatch into, saved between visits.
--
-- A grabbed egg (Nests sets the player's "CarriedEgg") becomes yours when the
-- ride gets it home (DeliverEgg). It goes in your inventory, the player's
-- "Eggs" attribute: JSON of { [kind] = count }. From there you place it on a
-- free spot in your pen (PlaceEgg), where it hatches after Config.HatchTime
-- seconds and the pet stays on that spot.
--
-- Pen spots are the pen's Slots; Slot1 is where the pet you ride waits, so eggs
-- go on Slot2 and up. Each slot part carries what's on it for every client to
-- draw: "Egg" (kind) with "HatchAt" (os.time), or "Pet" (kind).
--
-- Saving needs API access in Studio, like Gold.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals

local FIRST_SLOT = 2

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Pen")
if not ok then
	store = nil
end

-- [player] = { eggs = { [kind] = n }, slots = { [index] = { egg, hatchAt } or { pet } } }
local profiles = {}
local loaded = {}

local function isAnimal(kind)
	return typeof(kind) == "string" and Animals:FindFirstChild(kind) ~= nil
end

local function hatchTime(kind)
	local rarity = require(Animals[kind]).Rarity
	return Config.HatchTime[rarity] or Config.HatchTime.Uncommon
end

local function penOf(player)
	local index = player:GetAttribute("Pen")
	local pen = index and workspace.Pens:FindFirstChild("Pen" .. index)
	if pen and pen:GetAttribute("Owner") == player.UserId then
		return pen
	end
	return nil
end

local function slotPart(pen, index)
	return pen and pen:FindFirstChild("Slots") and pen.Slots:FindFirstChild("Slot" .. index)
end

-- Copies the profile onto the player (inventory) and their pen's slots (what's on each).
local function publish(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Eggs", HttpService:JSONEncode(profile.eggs))
	local pen = penOf(player)
	if not pen then
		return
	end
	for _, slot in pen.Slots:GetChildren() do
		local index = tonumber(slot.Name:match("^Slot(%d+)$"))
		local entry = index and profile.slots[index]
		slot:SetAttribute("Pet", entry and entry.pet or nil)
		slot:SetAttribute("HatchAt", entry and entry.hatchAt or nil)
		slot:SetAttribute("Egg", entry and entry.egg or nil)
	end
end

local function clearPen(pen)
	for _, slot in pen.Slots:GetChildren() do
		slot:SetAttribute("Egg", nil)
		slot:SetAttribute("HatchAt", nil)
		slot:SetAttribute("Pet", nil)
	end
end

local function load(player)
	local profile = { eggs = {}, slots = {} }
	if store then
		for attempt = 1, 3 do
			local success, data = pcall(store.GetAsync, store, "u" .. player.UserId)
			if success then
				if typeof(data) == "table" then
					for kind, n in data.eggs or {} do
						if isAnimal(kind) and tonumber(n) and n > 0 then
							profile.eggs[kind] = math.floor(n)
						end
					end
					for key, entry in data.slots or {} do
						local index = tonumber(key) -- saved tables have string keys
						if index and typeof(entry) == "table" and (isAnimal(entry.egg) or isAnimal(entry.pet)) then
							profile.slots[index] = entry
						end
					end
				end
				loaded[player] = true
				break
			end
			task.wait(attempt * 2)
		end
	end
	if not player.Parent then
		return
	end
	profiles[player] = profile
	publish(player)
end

local function save(player)
	local profile = profiles[player]
	if not store or not profile or not loaded[player] then
		return
	end
	local slots = {}
	for index, entry in profile.slots do
		slots[tostring(index)] = entry
	end
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, { eggs = profile.eggs, slots = slots }) then
			return
		end
		task.wait(attempt)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- The pen is claimed on join too (Pens); wait for it so the slots get filled in.
	for _ = 1, 20 do -- no pen at all when the five are taken
		if player:GetAttribute("Pen") then
			break
		end
		task.wait(0.25)
	end
	load(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

Players.PlayerRemoving:Connect(function(player)
	local pen = penOf(player)
	if pen then
		clearPen(pen)
	end
	save(player)
	profiles[player], loaded[player] = nil, nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(2)
end)

local function remote(name, handler)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.OnServerEvent:Connect(handler)
	event.Parent = ReplicatedStorage
end

-- The ride got its egg home.
remote("DeliverEgg", function(player, kind)
	local profile = profiles[player]
	if not profile or not isAnimal(kind) or player:GetAttribute("CarriedEgg") ~= kind then
		return
	end
	player:SetAttribute("CarriedEgg", nil)
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
end)

-- Put an egg from the inventory on a free spot in your pen.
remote("PlaceEgg", function(player, kind, index)
	local profile = profiles[player]
	local pen = penOf(player)
	if not profile or not pen or not isAnimal(kind) or (profile.eggs[kind] or 0) < 1 then
		return
	end
	if typeof(index) ~= "number" or index < FIRST_SLOT or profile.slots[index] or not slotPart(pen, index) then
		return
	end
	profile.eggs[kind] -= 1
	if profile.eggs[kind] == 0 then
		profile.eggs[kind] = nil
	end
	profile.slots[index] = { egg = kind, hatchAt = os.time() + hatchTime(kind) }
	publish(player)
end)

-- Hatch eggs whose time is up: the pet takes the egg's spot.
while true do
	task.wait(0.5)
	local now = os.time()
	for player, profile in profiles do
		local changed = false
		for index, entry in profile.slots do
			if entry.egg and now >= entry.hatchAt then
				profile.slots[index] = { pet = entry.egg }
				changed = true
			end
		end
		if changed then
			publish(player)
		end
	end
end
