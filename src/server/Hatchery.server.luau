-- Eggs you bring home and the pets they hatch into, saved between visits.
--
-- A grabbed egg (Nests sets the player's "CarriedEgg") becomes yours when the
-- ride gets it home (DeliverEgg). It goes in your Roblox inventory: one Tool
-- per kind of egg ("Pinto Egg"), its "Count" attribute how many you have.
-- Equip it and click anywhere in your pen to place one there (PlaceEgg), where
-- it hatches after Config.HatchTime seconds and the pet stays on that spot.
--
-- What's in a pen goes on the pen as its "Contents" attribute for every
-- client to draw: JSON of { [id] = { x, z, egg, hatchAt } or { x, z, pet } },
-- x and z in studs from the centre of the pen's Area.
--
-- Any pet can be ridden: the one you ride waits on Slot1 (the player's
-- "RidePet" attribute, Config.DefaultPet to start). Clicking a pet in your pen
-- makes it the one you ride, and the old one takes its place (RidePet remote).
--
-- Saving needs a published place with API access, like Gold.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals

local SPACING = 4.5 -- studs kept between eggs and pets placed in a pen
local EDGE = 2 -- studs kept from the pen's fences

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Pen")
if not ok then
	store = nil
end

-- [player] = { eggs = { [kind] = n }, items = { [id] = { x, z, egg, hatchAt } or { x, z, pet } }, ride = kind }
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

-- The egg Tools in the player's inventory match their egg counts.
local function syncTools(player, eggs)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local have = {}
	for _, holder in { backpack, player.Character } do
		for _, tool in holder and holder:GetChildren() or {} do
			local kind = tool:IsA("Tool") and tool:GetAttribute("EggKind")
			if kind then
				if (eggs[kind] or 0) < 1 or have[kind] then
					tool:Destroy()
				else
					have[kind] = tool
				end
			end
		end
	end
	for kind, n in eggs do
		local tool = have[kind]
		if not tool then
			tool = Instance.new("Tool")
			tool.Name = kind .. " Egg"
			tool.RequiresHandle = false
			tool.CanBeDropped = false
			tool.TextureId = Config.EggIcons[kind] or ""
			tool:SetAttribute("EggKind", kind)
			tool.Parent = backpack
		end
		tool:SetAttribute("Count", n)
		tool.ToolTip = kind .. " Egg x" .. n
	end
end

-- Copies the profile onto the player (inventory, ride pet) and their pen (what's in it).
local function publish(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	syncTools(player, profile.eggs)
	player:SetAttribute("RidePet", profile.ride)
	local pen = penOf(player)
	if pen then
		pen:SetAttribute("Contents", HttpService:JSONEncode(profile.items))
	end
end

-- Whether (x, z) in the pen's Area is a free place for an egg.
local function canPlace(pen, profile, x, z)
	local area = pen:FindFirstChild("Area")
	if not area or math.abs(x) > area.Size.X / 2 - EDGE or math.abs(z) > area.Size.Z / 2 - EDGE then
		return false
	end
	local ride = pen.Slots.Slot1.Position - area.Position
	if Vector2.new(x - ride.X, z - ride.Z).Magnitude < SPACING * 1.5 then
		return false -- the pet you ride waits there
	end
	for _, item in profile.items do
		if Vector2.new(x - item.x, z - item.z).Magnitude < SPACING then
			return false
		end
	end
	return true
end

local function load(player)
	local profile = { eggs = {}, items = {}, ride = Config.DefaultPet }
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
					if isAnimal(data.ride) then
						profile.ride = data.ride
					end
					for id, item in data.items or {} do
						if typeof(item) == "table" and tonumber(item.x) and tonumber(item.z)
							and (isAnimal(item.egg) or isAnimal(item.pet)) then
							profile.items[id] = item
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
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, { eggs = profile.eggs, items = profile.items, ride = profile.ride }) then
			return
		end
		task.wait(attempt)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- The pen is claimed on join too (Pens); wait for it so its contents show.
	for _ = 1, 20 do -- no pen at all when the five are taken
		if player:GetAttribute("Pen") then
			break
		end
		task.wait(0.25)
	end
	player.CharacterAdded:Connect(function()
		task.wait() -- a fresh Backpack comes with each character
		local profile = profiles[player]
		if profile then
			syncTools(player, profile.eggs)
		end
	end)
	load(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(load, player)
end

-- Empties a pen for the next owner (its pets leave with the player).
local function clearPen(pen)
	pen:SetAttribute("Contents", "{}")
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

-- Put an egg from the inventory down in your pen, at (x, z) from the Area's centre.
remote("PlaceEgg", function(player, kind, x, z)
	local profile = profiles[player]
	local pen = penOf(player)
	if not profile or not pen or not isAnimal(kind) or (profile.eggs[kind] or 0) < 1 then
		return
	end
	if typeof(x) ~= "number" or typeof(z) ~= "number" or not canPlace(pen, profile, x, z) then
		return
	end
	profile.eggs[kind] -= 1
	if profile.eggs[kind] == 0 then
		profile.eggs[kind] = nil
	end
	profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = kind, hatchAt = os.time() + hatchTime(kind) }
	publish(player)
end)

-- Ride the pet `id` from now on; the pet you rode takes its place in the pen.
remote("RidePet", function(player, id)
	local profile = profiles[player]
	local item = profile and typeof(id) == "string" and profile.items[id]
	if not item or not item.pet then
		return
	end
	item.pet, profile.ride = profile.ride, item.pet
	publish(player)
end)

-- Testing: "/give <pet> [count]" in chat puts pets straight into your pen, at
-- random free places. Only in Studio or for the game's owner.
local function allowed(player)
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

local function give(player, text)
	local profile = profiles[player]
	local pen = penOf(player)
	local name, count = text:match("^/give%s+(%S+)%s*(%d*)")
	if not name or not profile or not pen or not allowed(player) then
		return
	end
	local kind
	for _, module in Animals:GetChildren() do
		if module:IsA("ModuleScript") and module.Name:lower() == name:lower() and not module.Name:match("Model$") and module.Name ~= "Rig" then
			kind = module.Name
		end
	end
	if not kind then
		return
	end
	local area = pen.Area
	for _ = 1, math.clamp(tonumber(count) or 1, 1, 20) do
		for _ = 1, 50 do -- try random places until one is free
			local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
			local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
			if canPlace(pen, profile, x, z) then
				profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = kind }
				break
			end
		end
	end
	publish(player)
end

-- A chat command, so the "/give ..." line itself doesn't show in chat.
local command = Instance.new("TextChatCommand")
command.Name = "Give"
command.PrimaryAlias = "/give"
command.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	if player then
		give(player, text)
	end
end)
command.Parent = game:GetService("TextChatService")

-- Every pet in your pen earns Config.PetIncome gold a second (the pet you ride too).
local function income(profile)
	local total = Config.PetIncome[profile.ride] or 0
	for _, item in profile.items do
		if item.pet then
			total += Config.PetIncome[item.pet] or 0
		end
	end
	return total
end

task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in profiles do
			local earned = income(profile)
			if earned > 0 and player.Parent then
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + earned)
			end
		end
	end
end)

-- Hatch eggs whose time is up: the pet takes the egg's spot.
while true do
	task.wait(0.5)
	local now = os.time()
	for player, profile in profiles do
		local changed = false
		for _, item in profile.items do
			if item.egg and now >= item.hatchAt then
				item.pet, item.egg, item.hatchAt = item.egg, nil, nil
				changed = true
			end
		end
		if changed then
			publish(player)
		end
	end
end
