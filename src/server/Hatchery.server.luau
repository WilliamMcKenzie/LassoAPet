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
-- A new player gets the tutorial (Tutorial.luau): the player's "Tutorial"
-- attribute is true until the client says it's done (TutorialDone), which is
-- saved with the pen. Anyone with eggs or pets saved from before has done it.
-- A new player starts with no pet at all, only a Config.DefaultPet egg (it
-- hatches at once): that pet becomes the one you ride the first time you ride
-- it. Nothing is saved until the tutorial's done, so leaving starts it over.
-- Pets earn nothing in the tutorial until an egg is placed in a pen that already
-- has a pet (the egg brought home): that's when the money starts.
--
-- Saving needs a published place with API access, like Gold.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Animals = ReplicatedStorage.Shared.Animals

local EDGE = 2 -- studs kept from the pen's fences

local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, "Pen")
if not ok then
	store = nil
end

-- [player] = { eggs = { [kind] = n }, items = { [id] = { x, z, egg, hatchAt } or { x, z, pet } }, ride = kind, tutorial = done }
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

-- The kinds of animal this profile has ridden, sorted.
local function riddenList(profile)
	local list = {}
	for kind in profile.ridden do
		table.insert(list, kind)
	end
	table.sort(list)
	return list
end

-- Copies the profile onto the player (inventory, ride pet) and their pen (what's in it).
local function publish(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	syncTools(player, profile.eggs)
	player:SetAttribute("RidePet", profile.ride or "")
	player:SetAttribute("RideMerged", profile.rideMerged or 1) -- how many pets it's merged from (Shared/Merge)
	player:SetAttribute("Ridden", HttpService:JSONEncode(riddenList(profile))) -- for the animal dictionary (AnimalDex)
	local pen = penOf(player)
	if pen then
		pen:SetAttribute("Contents", HttpService:JSONEncode(profile.items))
	end
end

-- Whether (x, z) in the pen's Area is inside it. Eggs can go anywhere in the
-- pen, even on top of each other (QM).
local function canPlace(pen, x, z)
	local area = pen:FindFirstChild("Area")
	return area ~= nil and math.abs(x) <= area.Size.X / 2 - EDGE and math.abs(z) <= area.Size.Z / 2 - EDGE
end

-- Every pet in your pen earns Config.PetIncome gold a second (the pet you ride too).
local function income(profile)
	local total = (Config.PetIncome[profile.ride] or 0) * (profile.rideMerged or 1)
	for _, item in profile.items do
		if item.pet then
			total += (Config.PetIncome[item.pet] or 0) * (item.merged or 1) -- (a merged pet earns for all it's made of)
		end
	end
	return total
end

-- While you were away (QM, Oct 3): back after time away, your pets have earned
-- Config.AwayRate of their usual gold a second for up to Config.AwayCap seconds of
-- it. It waits in the "AwayGold" attribute (the client's popup) until ClaimAway;
-- unclaimed, it's saved and added to the next visit's.
local function awayGold(profile, data)
	local seen = tonumber(data.seen)
	local away = if seen then math.clamp(os.time() - seen, 0, Config.AwayCap) else 0
	return (tonumber(data.awayGold) or 0) + math.floor(income(profile) * Config.AwayRate * away)
end

local function load(player)
	local profile = { eggs = {}, items = {}, ride = Config.DefaultPet, ridden = {} }
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
						profile.rideMerged = tonumber(data.rideMerged) and math.max(1, math.floor(data.rideMerged)) or nil
					end
					profile.tutorial = data.tutorial == true or next(data.eggs or {}) ~= nil or next(data.items or {}) ~= nil
					for _, kind in typeof(data.ridden) == "table" and data.ridden or {} do
						if isAnimal(kind) then
							profile.ridden[kind] = true
						end
					end
					for id, item in data.items or {} do
						if typeof(item) == "table" and tonumber(item.x) and tonumber(item.z)
							and (isAnimal(item.egg) or isAnimal(item.pet)) then
							profile.items[id] = item
						end
					end
					if profile.tutorial then
						profile.awayGold = awayGold(profile, data)
					end
				end
				loaded[player] = true
				break
			end
			if attempt == 3 or RunService:IsStudio() then
				break -- no API access in Studio fails every time: don't keep the player waiting
			end
			task.wait(attempt * 2)
		end
	end
	if not player.Parent then
		return
	end
	profiles[player] = profile
	local tutorial = Config.Tutorial and not profile.tutorial
	if tutorial then
		profile.ride = nil -- RidePet "": no pet waits in the pen yet
		profile.eggs = { [Config.DefaultPet] = 1 }
	end
	player:SetAttribute("Tutorial", if tutorial then true else nil)
	player:SetAttribute("AwayGold", if (profile.awayGold or 0) > 0 then profile.awayGold else nil)
	publish(player)
end

local function save(player)
	local profile = profiles[player]
	if not store or not profile or not loaded[player] or player:GetAttribute("Tutorial") then
		return
	end
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, { eggs = profile.eggs, items = profile.items, ride = profile.ride, rideMerged = profile.rideMerged, tutorial = profile.tutorial, ridden = riddenList(profile),
			seen = os.time(), awayGold = profile.awayGold }) then
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

-- The ride crossed the finish line at the end of the course: a random egg, drawn
-- like the stampede itself (each biome's Herd counts as weights, so a Unicorn egg
-- is as rare as Unicorns are). Returns the kind, for the egg reveal.
local finished = {} -- [player] = os.clock() of their last finish
local finishCourse = Instance.new("RemoteFunction")
finishCourse.Name = "FinishCourse"
finishCourse.OnServerInvoke = function(player)
	local profile = profiles[player]
	if not profile or (finished[player] and os.clock() - finished[player] < 10) then
		return nil
	end
	finished[player] = os.clock()
	local pool, total = {}, 0
	for _, biome in Config.Biomes do
		-- (a borrowed placeholder herd would count its animals twice)
		for kind, weight in (if biome.PlaceholderHerd then {} else biome.Herd or {}) do
			if isAnimal(kind) then
				total += weight
				table.insert(pool, { kind = kind, upTo = total })
			end
		end
	end
	local roll = Random.new():NextNumber(0, total)
	local kind
	for _, entry in pool do
		kind = entry.kind
		if roll <= entry.upTo then
			break
		end
	end
	if not kind then
		return nil
	end
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
	return kind
end
finishCourse.Parent = ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
	finished[player] = nil
end)

-- The Egg Machine (Config.Gacha): pay its price for a random egg, a tier picked
-- by Odds and then an egg from that tier's Pool. Returns the kind and whether
-- it's an Exclusive (gacha-only), for the egg reveal; nil if you can't pay.
local function pick(weights)
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = Random.new():NextNumber(0, total)
	local last
	for kind, weight in weights do
		last = kind
		roll -= weight
		if roll <= 0 then
			return kind
		end
	end
	return last
end

local rolled = {} -- [player] = os.clock() of their last roll
local rollGacha = Instance.new("RemoteFunction")
rollGacha.Name = "RollGacha"
rollGacha.OnServerInvoke = function(player)
	local profile = profiles[player]
	local gacha = Config.Gacha
	local gold = player:GetAttribute("Gold") or 0
	if not profile or not gacha.Enabled or gold < gacha.Price or (rolled[player] and os.clock() - rolled[player] < 1) then
		return nil
	end
	local odds = {}
	for tier, weight in gacha.Odds do
		if next(gacha.Pool[tier] or {}) then
			odds[tier] = weight
		end
	end
	local tier = pick(odds)
	local kind = tier and pick(gacha.Pool[tier] or {})
	if not isAnimal(kind) then
		return nil
	end
	rolled[player] = os.clock()
	player:SetAttribute("Gold", gold - gacha.Price)
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
	return kind, tier == "Exclusive"
end
rollGacha.Parent = ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
	rolled[player] = nil
end)

-- Put an egg from the inventory down in your pen, at (x, z) from the Area's centre.
remote("PlaceEgg", function(player, kind, x, z)
	local profile = profiles[player]
	local pen = penOf(player)
	if not profile or not pen or not isAnimal(kind) or (profile.eggs[kind] or 0) < 1 then
		return
	end
	if typeof(x) ~= "number" or typeof(z) ~= "number" or not canPlace(pen, x, z) then
		return
	end
	profile.eggs[kind] -= 1
	if profile.eggs[kind] == 0 then
		profile.eggs[kind] = nil
	end
	if profile.ride or next(profile.items) then
		profile.earning = true -- the tutorial's second egg: pets start earning
	end
	profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = kind, hatchAt = os.time() + (if player:GetAttribute("Tutorial") then Config.TutorialHatchTime else hatchTime(kind)) }
	publish(player)
end)

-- The client finished the tutorial: it never shows again.
-- The rider got on an animal of this kind (Ride.client): it's in their animal
-- dictionary from now on.
remote("Ridden", function(player, kind)
	local profile = profiles[player]
	if profile and isAnimal(kind) and not profile.ridden[kind] then
		profile.ridden[kind] = true
		publish(player)
	end
end)

remote("TutorialDone", function(player)
	local profile = profiles[player]
	if profile then
		profile.tutorial = true
	end
	player:SetAttribute("Tutorial", nil)
end)

-- Ride the pet `id` from now on; the pet you rode takes its place in the pen.
remote("RidePet", function(player, id)
	local profile = profiles[player]
	local item = profile and typeof(id) == "string" and profile.items[id]
	if not item or not item.pet then
		return
	end
	if profile.ride then
		item.pet, profile.ride = profile.ride, item.pet
		item.merged, profile.rideMerged = profile.rideMerged, item.merged -- (a merged pet stays merged)
	else
		profile.ride, profile.rideMerged, profile.items[id] = item.pet, item.merged, nil -- your first pet: nothing to swap with
	end
	publish(player)
end)

-- MERGE (QM, Oct 4; Shared/Merge): every pet of `kind` you have, in the pen and the
-- one you ride, becomes one pet of that kind made of all of them. If the one you
-- ride is among them, it's the one that stays.
remote("MergePets", function(player, kind)
	local profile = profiles[player]
	if not profile or not isAnimal(kind) then
		return
	end
	local ids, total = {}, if profile.ride == kind then profile.rideMerged or 1 else 0
	for id, item in profile.items do
		if item.pet == kind then
			table.insert(ids, id)
			total += item.merged or 1
		end
	end
	if #ids + (if profile.ride == kind then 1 else 0) < 2 then
		return
	end
	table.sort(ids)
	if profile.ride == kind then
		profile.rideMerged = total
	else
		profile.items[ids[1]].merged = total
		table.remove(ids, 1)
	end
	for _, id in ids do
		profile.items[id] = nil
	end
	publish(player)
end)

-- Testing: "/give <pet> [count]" in chat puts pets straight into your pen, at
-- random places. Only in Studio or for the game's owner.
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
		local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
		local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = kind }
	end
	publish(player)
end

-- The shop's Legendary Pet (Shop.server): a random Legendary straight into your
-- pen, hatched. Returns its kind, or nil if you have no pen yet.
local grantPet = Instance.new("BindableFunction")
grantPet.Name = "GrantPet"
grantPet.OnInvoke = function(player)
	local profile = profiles[player]
	local pen = penOf(player)
	local kind = profile and pen and pick(Config.Gacha.Pool.Legendary)
	if not isAnimal(kind) then
		return nil
	end
	local area = pen.Area
	local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
	local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
	profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = kind }
	publish(player)
	return kind
end
grantPet.Parent = game:GetService("ServerStorage")

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

-- Testing: "/biome <meadow|desert|tundra|ocean>" puts you at the start of that
-- biome riding a random animal from its herd, past any gate (Ride.client does
-- the ride). Same rule as /give for who can use it.
local BIOME_ALIASES = { tundra = "snow" }
local biomeWarp = Instance.new("RemoteEvent")
biomeWarp.Name = "BiomeWarp"
biomeWarp.Parent = ReplicatedStorage
local biomeCommand = Instance.new("TextChatCommand")
biomeCommand.Name = "Biome"
biomeCommand.PrimaryAlias = "/biome"
biomeCommand.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	local name = text:match("^/biome%s+(%S+)")
	if not player or not name or not allowed(player) then
		return
	end
	name = BIOME_ALIASES[name:lower()] or name:lower()
	for index, biome in Config.Biomes do
		if biome.Name:lower() == name then
			local kinds = {}
			for kind in biome.Herd do
				table.insert(kinds, kind)
			end
			biomeWarp:FireClient(player, index, kinds[math.random(#kinds)])
			return
		end
	end
end)
biomeCommand.Parent = game:GetService("TextChatService")

-- Testing: "/tutorial" wipes your progress (eggs, pen, pets, gold, pen level),
-- saved as well, and starts the tutorial again from a fresh character.
local tutorialCommand = Instance.new("TextChatCommand")
tutorialCommand.Name = "Tutorial"
tutorialCommand.PrimaryAlias = "/tutorial"
tutorialCommand.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or not profiles[player] or not allowed(player) then
		return
	end
	profiles[player] = { eggs = { [Config.DefaultPet] = 1 }, items = {}, ride = nil, ridden = {} }
	if store and loaded[player] then
		task.spawn(pcall, store.SetAsync, store, "u" .. player.UserId, { eggs = {}, items = {}, tutorial = false })
	end
	player:SetAttribute("Gold", 0) -- Gold and PenLevel save these when you leave
	player:SetAttribute("PenLevel", 1)
	player:SetAttribute("CarriedEgg", nil)
	player:SetAttribute("Tutorial", nil) -- off then on, so a tutorial already running starts over
	task.wait()
	player:SetAttribute("Tutorial", if Config.Tutorial then true else nil)
	publish(player)
	player:LoadCharacter() -- off any ride, back at your pen
end)
tutorialCommand.Parent = game:GetService("TextChatService")

-- Testing: "/skip" ends the tutorial on the spot, as finishing it would, with a
-- Config.DefaultPet waiting to ride if you don't have a pet yet.
local skipCommand = Instance.new("TextChatCommand")
skipCommand.Name = "Skip"
skipCommand.PrimaryAlias = "/skip"
skipCommand.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	local profile = player and profiles[player]
	if not profile or not allowed(player) or not player:GetAttribute("Tutorial") then
		return
	end
	profile.tutorial = true
	if not profile.ride and not next(profile.items) then
		profile.ride = Config.DefaultPet
	end
	player:SetAttribute("Tutorial", nil)
	publish(player)
end)
skipCommand.Parent = game:GetService("TextChatService")

-- The "While you were away" popup's Claim button: the gold earned while away goes
-- into your total.
remote("ClaimAway", function(player)
	local profile = profiles[player]
	if not profile or (profile.awayGold or 0) <= 0 then
		return
	end
	player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + profile.awayGold)
	profile.awayGold = nil
	player:SetAttribute("AwayGold", nil)
end)

-- Testing: "/away" shows the popup as if you'd been gone the whole Config.AwayCap.
local awayCommand = Instance.new("TextChatCommand")
awayCommand.Name = "Away"
awayCommand.PrimaryAlias = "/away"
awayCommand.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	local profile = player and profiles[player]
	if not profile or not allowed(player) then
		return
	end
	profile.awayGold = (profile.awayGold or 0) + math.max(1, math.floor(income(profile) * Config.AwayRate * Config.AwayCap))
	player:SetAttribute("AwayGold", nil)
	task.wait()
	player:SetAttribute("AwayGold", profile.awayGold)
end)
awayCommand.Parent = game:GetService("TextChatService")

-- Fired to a player each time their pets pay out, so the client can pop "+N$"
-- over each pet's head.
local paid = Instance.new("RemoteEvent")
paid.Name = "PetIncome"
paid.Parent = ReplicatedStorage

task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in profiles do
			local earned = if profile.earning or not player:GetAttribute("Tutorial") then income(profile) else 0
			if earned > 0 and player.Parent then
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + earned)
				paid:FireClient(player)
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
