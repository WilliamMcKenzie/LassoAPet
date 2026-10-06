-- Eggs you bring home and the pets they hatch into, saved between visits.
--
-- A grabbed egg (Nests sets the player's "CarriedEgg") becomes yours when the
-- ride gets it home (DeliverEgg). It goes in your Roblox inventory: one Tool
-- per kind of egg ("Pinto Egg"), its "Count" attribute how many you have.
-- Equip it and click anywhere in your pen to place one there (PlaceEgg). It's
-- ready after Config.PetHatchTime (or HatchTime) seconds, then waits for you to
-- hatch it: stand by it and hold F (HatchEgg; Pen.client's prompt). The pet stays
-- on that spot. Only the tutorial's eggs hatch by themselves (QM, Oct 6).
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
-- Pets earn nothing until the tutorial's done (QM, Oct 6): the money starts the
-- moment it ends, finished or skipped.
--
-- Saving needs a published place with API access, like Gold.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Funnel = require(script.Parent.Funnel)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
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

-- A hybrid's saved Speed and Stamina (Fusion.stats), or nil if there's none.
local function savedStats(stats)
	local speed, stamina = typeof(stats) == "table" and tonumber(stats.Speed), typeof(stats) == "table" and tonumber(stats.Stamina)
	return if speed and stamina and speed > 0 and stamina > 0 then { Speed = speed, Stamina = stamina } else nil
end

local function hatchTime(kind)
	local rarity = require(Animals[kind]).Rarity
	return Config.PetHatchTime[kind] or Config.HatchTime[rarity] or Config.HatchTime.Uncommon
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
-- The animal an inventory egg of `kind` holds (an animal's own, or Config.SpecialEggs'), if any.
local function eggPet(kind)
	local special = typeof(kind) == "string" and Config.SpecialEggs[kind]
	if special then
		return special.Pet
	end
	return if isAnimal(kind) then kind else nil
end

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
			local special = Config.SpecialEggs[kind]
			tool.Name = (if special then special.Name else kind) .. " Egg"
			tool.RequiresHandle = false
			tool.CanBeDropped = false
			tool.TextureId = Config.EggIcons[kind] or Config.EggIcons[eggPet(kind)] or ""
			tool:SetAttribute("EggKind", kind)
			-- An invisible Handle, so the arm comes up to hold the egg (HeldEgg.client
			-- draws the egg there).
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.2, 0.2, 0.2)
			handle.Transparency = 1
			handle.CanCollide = false
			handle.CanQuery = false
			handle.CanTouch = false
			handle.Massless = true
			handle.Parent = tool
			tool.Parent = backpack
		end
		tool:SetAttribute("Count", n)
		tool.ToolTip = tool.Name .. " x" .. n
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

-- What this profile's next egg roll costs (Config.Gacha: PriceGrowth x per roll so far,
-- two significant figures).
local function rollPrice(profile)
	local price = Config.Gacha.Price * (Config.Gacha.PriceGrowth or 1) ^ (profile.rolls or 0)
	local step = 10 ^ math.max(math.floor(math.log10(price)) - 1, 0)
	return math.floor(price / step + 0.5) * step
end

-- Copies the profile onto the player (inventory, ride pet) and their pen (what's in it).
local function publish(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	syncTools(player, profile.eggs)
	player:SetAttribute("HatchCredits", math.max(0, (player:GetAttribute("BoughtHatches") or 0) - (profile.usedHatches or 0)))
	player:SetAttribute("RidePet", profile.ride or "")
	player:SetAttribute("RollPrice", rollPrice(profile))
	player:SetAttribute("RainbowTrail", profile.rainbowTrail or nil) -- bought (Config.RainbowTrail): every ride trails a rainbow
	player:SetAttribute("RideMerged", profile.rideMerged or 1) -- how many pets it's merged from (Shared/Merge)
	player:SetAttribute("RideFuse", profile.rideFuse) -- the donor, if it's a hybrid (Shared/Fusion)
	player:SetAttribute("RideIncome", profile.rideIncome) -- (a hybrid's: what both its pets earned)
	local stats = profile.rideFuse and profile.rideStats
	player:SetAttribute("RideStats", stats and Vector2.new(stats.Speed, stats.Stamina) or nil) -- (a hybrid's Speed, Stamina: Fusion.stats)
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
	-- (a merged pet earns for all it's made of; a hybrid what both its pets earned)
	local total = profile.rideIncome or (Config.PetIncome[profile.ride] or 0) * (profile.rideMerged or 1)
	for _, item in profile.items do
		if item.pet then
			total += item.income or (Config.PetIncome[item.pet] or 0) * (item.merged or 1)
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
						if eggPet(kind) and tonumber(n) and n > 0 then
							profile.eggs[kind] = math.floor(n)
						end
					end
					if isAnimal(data.ride) then
						profile.ride = data.ride
						profile.rideMerged = tonumber(data.rideMerged) and math.max(1, math.floor(data.rideMerged)) or nil
						if isAnimal(data.rideFuse) and data.rideFuse ~= data.ride and tonumber(data.rideIncome) then
							profile.rideFuse, profile.rideIncome = data.rideFuse, math.max(0, tonumber(data.rideIncome))
							profile.rideStats = savedStats(data.rideStats)
						end
					end
					profile.rolls = tonumber(data.rolls) and math.max(0, math.floor(data.rolls)) or nil
					profile.rainbowTrail = data.rainbowTrail == true or nil
					profile.tutorial = data.tutorial == true or next(data.eggs or {}) ~= nil or next(data.items or {}) ~= nil
					for _, kind in typeof(data.ridden) == "table" and data.ridden or {} do
						if isAnimal(kind) then
							profile.ridden[kind] = true
						end
					end
					for id, item in data.items or {} do
						if typeof(item) == "table" and tonumber(item.x) and tonumber(item.z)
							and (isAnimal(item.egg) or isAnimal(item.pet)) then
							if not (item.pet and isAnimal(item.fuse) and item.fuse ~= item.pet and tonumber(item.income)) then
								item.fuse, item.income = nil, nil -- (a hybrid: Shared/Fusion)
							end
							item.stats = item.fuse and savedStats(item.stats) or nil
							profile.items[id] = item
						end
					end
					if profile.tutorial then
						profile.awayGold = awayGold(profile, data)
					end
					profile.usedHatches = tonumber(data.usedHatches) or 0
					profile.hatchTarget = typeof(data.hatchTarget) == "string" and data.hatchTarget or nil
					profile.boughtPets = tonumber(data.boughtPets) -- Legendary Pets from the shop already in (addBoughtPets)
					profile.boughtGiantEggs = tonumber(data.boughtGiantEggs) -- Giant Horse eggs from the shop already in (addBoughtGiantEggs)
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
	if not profile.tutorial then
		Funnel.track(player) -- a new player
	end
	local tutorial = Config.Tutorial and not profile.tutorial
	if tutorial then
		profile.ride = nil -- RidePet "": no pet waits in the pen yet
		profile.eggs = { [Config.DefaultPet] = 1 }
	end
	player:SetAttribute("Tutorial", if tutorial then true else nil)
	player:SetAttribute("AwayGold", if (profile.awayGold or 0) > 0 then profile.awayGold else nil)
	publish(player)
end

local savedAs = {} -- [player] = the profile as last saved, as JSON (autosave skips it if unchanged)

-- onlyIfChanged: the autosave's, which skips it when nothing changed.
local function save(player, onlyIfChanged)
	local profile = profiles[player]
	if not store or not profile or not loaded[player] or player:GetAttribute("Tutorial") then
		return
	end
	local data = { eggs = profile.eggs, items = profile.items, ride = profile.ride, rideMerged = profile.rideMerged, rideFuse = profile.rideFuse, rideIncome = profile.rideIncome, rideStats = profile.rideStats, tutorial = profile.tutorial, ridden = riddenList(profile),
		awayGold = profile.awayGold, boughtPets = profile.boughtPets, boughtGiantEggs = profile.boughtGiantEggs, usedHatches = profile.usedHatches, hatchTarget = profile.hatchTarget, rolls = profile.rolls,
		rainbowTrail = profile.rainbowTrail }
	local as = HttpService:JSONEncode(data)
	if onlyIfChanged and savedAs[player] == as then
		return true
	end
	data.seen = os.time() -- (when you were last here: the while-you-were-away gold counts from it)
	for attempt = 1, 3 do
		if pcall(store.SetAsync, store, "u" .. player.UserId, data) then
			savedAs[player] = as
			return true
		end
		task.wait(attempt)
	end
end

-- A paid hatch is a durable credit: the purchase ledger owns the total bought,
-- and the pen saves the total used together with the resulting pet.
local applyingHatch = {}
local function applyHatch(player)
	local profile = profiles[player]
	local total = player:GetAttribute("BoughtHatches")
	if not profile or not loaded[player] or total == nil or applyingHatch[player] then
		return
	end
	local used = profile.usedHatches or 0
	player:SetAttribute("HatchCredits", math.max(0, total - used))
	local item = profile.hatchTarget and profile.items[profile.hatchTarget]
	if total <= used or not item or not item.egg or item.hatchAt <= os.time() then
		return -- already hatched during checkout: keep the credit for another egg
	end
	applyingHatch[player] = true
	profile.usedHatches, profile.hatchTarget = used + 1, nil
	item.pet, item.egg, item.hatchAt = item.egg, nil, nil
	Funnel.step(player, "Egg Hatched")
	save(player)
	publish(player)
	applyingHatch[player] = nil
end

-- Shop calls this before opening checkout; the client only supplies the item id.
local prepareHatch = Instance.new("BindableFunction")
prepareHatch.Name = "PrepareEggSpeedup"
prepareHatch.OnInvoke = function(player, id)
	local profile = profiles[player]
	local pen = penOf(player)
	local item = profile and typeof(id) == "string" and profile.items[id]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not loaded[player] or not pen or not root or not item or not item.egg
		or item.hatchAt <= os.time() or player:GetAttribute("Tutorial") or applyingHatch[player] then
		return nil
	end
	local at = pen.Area.Position + Vector3.new(item.x, 0, item.z)
	if (root.Position - at).Magnitude > Config.SpeedupEgg.Range + 4 then
		return nil
	end
	profile.hatchTarget = id
	if (player:GetAttribute("BoughtHatches") or 0) > (profile.usedHatches or 0) then
		applyHatch(player)
		return "credit"
	end
	-- Save the selected egg before charging, so a reconnect can finish the hatch.
	if not save(player) then
		profile.hatchTarget = nil
		return nil
	end
	if not player.Parent or not item.egg or item.hatchAt <= os.time() then
		return nil
	end
	return "purchase"
end
prepareHatch.Parent = game:GetService("ServerStorage")

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("BoughtHatches"):Connect(function() applyHatch(player) end)
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
	applyHatch(player)
end)
for _, player in Players:GetPlayers() do
	player:GetAttributeChangedSignal("BoughtHatches"):Connect(function() applyHatch(player) end)
	task.spawn(function() load(player) applyHatch(player) end)
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
	profiles[player], loaded[player], savedAs[player], applyingHatch[player] = nil, nil, nil, nil
end)

-- Autosave (QM, Oct 4): every Config.AutosaveEvery seconds each player's eggs, pets and pen is saved
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

local function remote(name, handler)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.OnServerEvent:Connect(handler)
	event.Parent = ReplicatedStorage
end

local place -- (below, after PlaceEgg)
local TUTORIAL_SPOTS = { Vector2.new(0, 0), Vector2.new(8, 0), Vector2.new(-8, 0), Vector2.new(0, 8), Vector2.new(0, -8), Vector2.new(8, 8) }

-- The ride got its egg home.
remote("DeliverEgg", function(player, kind)
	local profile = profiles[player]
	if not profile or not isAnimal(kind) or player:GetAttribute("CarriedEgg") ~= kind then
		return
	end
	player:SetAttribute("CarriedEgg", nil)
	Funnel.step(player, "Brought Egg Home")
	-- The tutorial's egg brought home goes straight into the pen (balance pass, Oct 6: a
	-- fifth of new players left at "Place your egg" a second time). The first spot clear
	-- of the starter pet, from the middle out.
	local pen = penOf(player)
	if player:GetAttribute("Tutorial") and pen and (profile.ride or next(profile.items)) then
		for _, spot in TUTORIAL_SPOTS do
			local clear = canPlace(pen, spot.X, spot.Y)
			for _, item in profile.items do
				if clear and math.abs(item.x - spot.X) < 6 and math.abs(item.z - spot.Y) < 6 then
					clear = false
				end
			end
			if clear then
				place(player, profile, kind, spot.X, spot.Y)
				return
			end
		end
	end
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
end)

-- You held E by an egg in your pen that's ready (Pen.client): it hatches.
remote("HatchEgg", function(player, id)
	local profile = profiles[player]
	local pen = penOf(player)
	local item = profile and typeof(id) == "string" and profile.items[id]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not loaded[player] or not pen or not root or not item or not item.egg or item.hatchAt > os.time() or applyingHatch[player] then
		return
	end
	local at = pen.Area.Position + Vector3.new(item.x, 0, item.z)
	if (root.Position - at).Magnitude > Config.SpeedupEgg.Range + 4 then
		return
	end
	item.pet, item.egg, item.hatchAt = item.egg, nil, nil
	if profile.pastStarter then
		Funnel.step(player, "Egg Hatched")
	end
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

-- The Rainbow Trail (Config.RainbowTrail): Price gold, once, only with the last
-- biome (the Godlands) open. Saved straight away: the gold's gone either way.
-- Returns true if it went through.
local buyTrail = Instance.new("RemoteFunction")
buyTrail.Name = "BuyRainbowTrail"
buyTrail.OnServerInvoke = function(player)
	local profile = profiles[player]
	local price = Config.RainbowTrail.Price
	local gold = player:GetAttribute("Gold") or 0
	if not profile or profile.rainbowTrail or (player:GetAttribute("PenLevel") or 1) < #Config.Biomes or gold < price then
		return false
	end
	player:SetAttribute("Gold", gold - price)
	profile.rainbowTrail = true
	publish(player)
	task.spawn(save, player)
	return true
end
buyTrail.Parent = ReplicatedStorage

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
	local price = profile and rollPrice(profile)
	if not profile or not gacha.Enabled or gold < price or (rolled[player] and os.clock() - rolled[player] < 1) then
		return nil
	end
	-- Gold can be bought with Robux, so a roll is a paid random item: none where the
	-- player's policy restricts them (Shop.server checks).
	local restricted = game:GetService("ServerStorage"):FindFirstChild("RandomRestricted")
	if not restricted or restricted:Invoke(player) then
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
	player:SetAttribute("Gold", gold - price)
	profile.rolls = (profile.rolls or 0) + 1
	Funnel.event(player, "Rolled Egg")
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
	local pet = eggPet(kind)
	if not profile or not pen or not pet or (profile.eggs[kind] or 0) < 1 then
		return
	end
	if typeof(x) ~= "number" or typeof(z) ~= "number" or not canPlace(pen, x, z) then
		return
	end
	profile.eggs[kind] -= 1
	if profile.eggs[kind] == 0 then
		profile.eggs[kind] = nil
	end
	place(player, profile, kind, x, z)
end)

-- Puts an egg of `kind` (already out of the inventory) down at (x, z) in the pen.
place = function(player, profile, kind, x, z)
	if profile.ride or next(profile.items) then
		profile.pastStarter = true -- placed with a pet already there: not the starter egg (the funnel tells them apart)
	end
	local pet = eggPet(kind)
	local special = Config.SpecialEggs[kind]
	if special then -- (hatches into its Pet, merged from Merged: a Giant Horse is 10 horses)
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = pet, merged = special.Merged, eggScale = special.EggScale, hatchAt = os.time() + special.HatchTime }
	else
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = kind, hatchAt = os.time() + (if player:GetAttribute("Tutorial") then Config.TutorialHatchTime else hatchTime(kind)) }
	end
	if profile.pastStarter then
		Funnel.step(player, "Placed Egg") -- the egg brought home, not the starter egg placed before the first ride
	else
		Funnel.step(player, "Placed Starter Egg")
	end
	publish(player)
end

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
	Funnel.step(player, "Tutorial Done")
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
		item.fuse, profile.rideFuse = profile.rideFuse, item.fuse -- (and a hybrid a hybrid)
		item.income, profile.rideIncome = profile.rideIncome, item.income
		item.stats, profile.rideStats = profile.rideStats, item.stats
	else
		profile.ride, profile.rideMerged, profile.items[id] = item.pet, item.merged, nil -- your first pet: nothing to swap with
		profile.rideFuse, profile.rideIncome, profile.rideStats = item.fuse, item.income, item.stats
	end
	publish(player)
end)

-- MERGE (QM, Oct 4; Shared/Merge): every pet of `kind` you have, in the pen and the
-- one you ride, becomes one pet of that kind made of all of them. If the one you
-- ride is among them, it's the one that stays.
remote("MergePets", function(player, key)
	if not Config.MergeEnabled then -- (off for now: QM)
		return
	end
	local profile = profiles[player]
	if typeof(key) ~= "string" then
		return
	end
	local kind, fuse = Fusion.split(key) -- (two of the same hybrid merge too: Shared/Fusion)
	if not profile or not isAnimal(kind) or (fuse and not isAnimal(fuse)) then
		return
	end
	local rides = profile.ride == kind and profile.rideFuse == fuse
	local ids, total, earns = {}, if rides then profile.rideMerged or 1 else 0, if rides then profile.rideIncome or 0 else 0
	for id, item in profile.items do
		if item.pet == kind and item.fuse == fuse then
			table.insert(ids, id)
			total += item.merged or 1
			earns += item.income or 0
		end
	end
	if #ids + (if rides then 1 else 0) < 2 then
		return
	end
	table.sort(ids)
	if rides then
		profile.rideMerged = total
		profile.rideIncome = if fuse then earns else nil
	else
		profile.items[ids[1]].merged = total
		profile.items[ids[1]].income = if fuse then earns else nil
		table.remove(ids, 1)
	end
	for _, id in ids do
		profile.items[id] = nil
	end
	Funnel.event(player, "Merged Pets")
	publish(player)
end)

-- FUSE (QM, Oct 6; Shared/Fusion): two pets of different kinds, in the pen or the
-- one you ride ("ride"), become one hybrid where the base was. The first (the left
-- pick) is the base; the other sets its size and colours. It earns what both
-- earned and has the higher Speed and Stamina of the two (QM, 20:53). Hybrids fuse again.
remote("FusePets", function(player, idA, idB)
	local profile = profiles[player]
	if not profile or typeof(idA) ~= "string" or typeof(idB) ~= "string" or idA == idB then
		return
	end
	local function pet(id) -- (hybrids fuse again too: QM)
		if id == "ride" then
			return profile.ride and { pet = profile.ride, fuse = profile.rideFuse, merged = profile.rideMerged, income = profile.rideIncome, stats = profile.rideStats }
		end
		local item = profile.items[id]
		return item and item.pet and item
	end
	local a, b = pet(idA), pet(idB)
	if not a or not b then
		return
	end
	local base, donor, aIsBase = Fusion.combine(a.pet, a.fuse, b.pet, b.fuse)
	if not base then
		return
	end
	local baseId, donorId = idA, idB
	if not aIsBase then
		a, b, baseId, donorId = b, a, idB, idA
	end
	local function earning(item) -- (a hybrid's is saved; a plain pet's is its kind's, times its merges)
		return item.income or (Config.PetIncome[item.pet] or 0) * (item.merged or 1)
	end
	local earns = earning(a) + earning(b)
	local stats = Fusion.best(Fusion.stats(a.pet, a.fuse, a.stats), Fusion.stats(b.pet, b.fuse, b.stats)) -- the best of both (QM)
	local price = Fusion.price(a.pet, b.pet) -- (QM: fusing costs gold, by rarity; free for now)
	local gold = player:GetAttribute("Gold") or 0
	if gold < price then
		return
	end
	player:SetAttribute("Gold", gold - price)
	if baseId == "ride" or donorId == "ride" then -- the hybrid is the one you ride
		profile.ride, profile.rideFuse, profile.rideMerged, profile.rideIncome, profile.rideStats = base, donor, nil, earns, stats
		profile.items[if baseId == "ride" then donorId else baseId] = nil
	else
		profile.items[baseId] = { x = a.x, z = a.z, pet = base, fuse = donor, income = earns, stats = stats }
		profile.items[donorId] = nil
	end
	Funnel.event(player, "Fused Pets")
	publish(player)
end)

-- Testing: "/give <pet> [count]" in chat puts pets straight into your pen, at
-- random places. Only in Studio or for the game's owner.
local function allowed(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local success, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return success and group.Owner ~= nil and player.UserId == group.Owner.Id
end

-- The animal (or special egg, e.g. GiantHorse) a /give names, any case, or nil.
local function animalNamed(name)
	for _, module in Animals:GetChildren() do
		if module:IsA("ModuleScript") and module.Name:lower() == name:lower() and not module.Name:match("Model$") and module.Name ~= "Rig" then
			return module.Name
		end
	end
	for kind in Config.SpecialEggs do
		if kind:lower() == name:lower() then
			return kind
		end
	end
	return nil
end

-- The one player whose username or display name is `name`, or starts with it (any
-- case); nil and why if none or several do.
local function playerNamed(name)
	name = name:lower()
	local found = {}
	for _, p in Players:GetPlayers() do
		if p.Name:lower() == name or p.DisplayName:lower() == name then
			return p
		end
		if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
			table.insert(found, p)
		end
	end
	if #found == 1 then
		return found[1]
	end
	return nil, if #found == 0 then "no player called " .. name else #found .. " players start with " .. name
end

-- Dev chat replies (DevChat.client shows them in the chat window).
local devChat = Instance.new("RemoteEvent")
devChat.Name = "DevChat"
devChat.Parent = ReplicatedStorage

local function give(player, text)
	if not allowed(player) then
		return
	end
	local first, second, third = text:match("^/give%s+(%S+)%s*(%S*)%s*(%S*)")
	if not first then
		return
	end
	-- "/give <player> <animal> [n]" (QM, Oct 6): n eggs of that animal into that
	-- player's inventory. (A second word that's a number is the old form's count.)
	if second ~= "" and not tonumber(second) then
		local target, why = playerNamed(first)
		local kind = animalNamed(second)
		if not target then
			devChat:FireClient(player, "/give: " .. why)
			return
		elseif not kind then
			devChat:FireClient(player, "/give: no animal called " .. second)
			return
		elseif not profiles[target] then
			devChat:FireClient(player, "/give: " .. target.Name .. " hasn't loaded yet")
			return
		end
		local n = math.clamp(tonumber(third) or 1, 1, 20)
		local eggs = profiles[target].eggs
		eggs[kind] = (eggs[kind] or 0) + n
		publish(target)
		devChat:FireClient(player, "/give: " .. n .. " " .. kind .. " egg" .. (if n > 1 then "s" else "") .. " to " .. target.Name)
		return
	end
	-- "/give <animal> [n]": n of that animal, hatched, in your own pen.
	local profile = profiles[player]
	local pen = penOf(player)
	local name, count = first, second
	if not profile or not pen then
		return
	end
	local kind = animalNamed(name)
	if not kind or Config.SpecialEggs[kind] then
		devChat:FireClient(player, "/give: no animal called " .. name)
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

-- The shop's Legendary Pet (Shop.server): its "BoughtPets" attribute is the
-- running total bought; each one not yet in your profile (boughtPets, saved with
-- it) is a random pet by Config.Shop.LegendaryOdds straight into your pen, hatched, saved at once, and
-- its card shows (ShopGrant). Waits for your profile and pen.
local function addBoughtPets(player)
	local profile = profiles[player]
	local pen = penOf(player)
	local total = player:GetAttribute("BoughtPets")
	if not profile or not pen or not total or total <= (profile.boughtPets or 0) then
		return
	end
	local area = pen.Area
	local kinds = {}
	for _ = (profile.boughtPets or 0) + 1, total do
		local kind = pick(Config.Shop.LegendaryOdds)
		if isAnimal(kind) then
			local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
			local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
			profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = kind }
			table.insert(kinds, kind)
		end
	end
	profile.boughtPets = total
	publish(player)
	save(player)
	for _, kind in kinds do
		ReplicatedStorage:WaitForChild("ShopGrant"):FireClient(player, "LegendaryPet", kind)
	end
end
-- The shop's Giant Horse (Shop.server): its "BoughtGiantEggs" attribute is the running
-- total bought; each one not yet in your profile (boughtGiantEggs, saved with it) is
-- a Giant Horse egg in your inventory (Config.SpecialEggs.GiantHorse).
local function addBoughtGiantEggs(player)
	local profile = profiles[player]
	local total = player:GetAttribute("BoughtGiantEggs")
	if not profile or not total or total <= (profile.boughtGiantEggs or 0) then
		return
	end
	profile.eggs.GiantHorse = (profile.eggs.GiantHorse or 0) + total - (profile.boughtGiantEggs or 0)
	profile.boughtGiantEggs = total
	publish(player)
	save(player)
end
Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("BoughtPets"):Connect(function()
		addBoughtPets(player)
	end)
	player:GetAttributeChangedSignal("BoughtGiantEggs"):Connect(function()
		addBoughtGiantEggs(player)
	end)
	for _ = 1, 120 do -- (bought on an earlier visit: once your pets have loaded)
		if profiles[player] or not player.Parent then
			break
		end
		task.wait(0.5)
	end
	addBoughtPets(player)
	addBoughtGiantEggs(player)
end)

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
	local old = profiles[player]
	profiles[player] = { eggs = { [Config.DefaultPet] = 1 }, items = {}, ride = nil, ridden = {}, boughtPets = old.boughtPets, boughtGiantEggs = old.boughtGiantEggs, usedHatches = old.usedHatches }
	if store and loaded[player] then
		-- Keep the shop counts saved too: without them, rejoining hands every Giant Horse
		-- egg and Legendary Pet ever bought over again (addBoughtGiantEggs / addBoughtPets).
		task.spawn(pcall, store.SetAsync, store, "u" .. player.UserId, { eggs = {}, items = {}, tutorial = false, usedHatches = old.usedHatches,
			boughtPets = old.boughtPets, boughtGiantEggs = old.boughtGiantEggs })
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
			local earned = if player:GetAttribute("Tutorial") then 0 else income(profile) -- (nothing till the tutorial's done)
			if earned > 0 and player.Parent then
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + earned)
				paid:FireClient(player)
			end
		end
	end
end)

-- The tutorial's eggs hatch by themselves once their time is up: the pet takes the
-- egg's spot. Every other egg waits to be hatched by hand (HatchEgg, above).
while true do
	task.wait(0.5)
	local now = os.time()
	for player, profile in profiles do
		local changed = false
		for _, item in profile.items do
			if item.egg and now >= item.hatchAt and player:GetAttribute("Tutorial") then
				item.pet, item.egg, item.hatchAt = item.egg, nil, nil
				changed = true
				if profile.pastStarter then
					Funnel.step(player, "Egg Hatched") -- (not the starter egg, which hatches before the first ride)
				end
			end
		end
		if changed then
			publish(player)
		end
	end
end
