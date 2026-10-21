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
local Telemetry = require(script.Parent.Telemetry)
local Quests = require(script.Parent.Quests)
local Passes = require(script.Parent.Passes)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Animals = ReplicatedStorage.Shared.Animals

local EDGE = 2 -- studs kept from the pen's fences

-- One pen across every world (QM, Oct 14: "you have the same pets in each world"): World
-- 1's store, "Pen", in all of them. Each world's own quests and Analytics V1 record are
-- kept in it apart (WORLD_KEYS). The old per-world pens ("Pen_W2"...) are merged into it
-- once, the first time a player loads after this (mergeOld, data.merged), and kept as they
-- were as a backup.
local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("Pen", 1))
if not ok then
	store = nil
end
local oldStores = {} -- [world] = its old "Pen_W<world>" store (merged in once)
for world in Config.Places do
	if world ~= 1 then
		local okOld, old = pcall(DataStoreService.GetDataStore, DataStoreService, Config.storeName("Pen", world))
		oldStores[world] = if okOld then old else nil
	end
end
local otherStores = {} -- (no other worlds' pens any more: one pen)
local otherIncome = {} -- [player] = 0 (it was what their pets in the other worlds earned)
-- A world's own fields in the shared pen: World 1's as they were, the others' with the
-- world's number on ("quests2", "v1_2").
local function worldKey(name, world)
	world = world or Config.World
	return if world == 1 then name elseif name == "v1" then "v1_" .. world else name .. world
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

-- A saved hybrid's stats as it loads, brought up to the fusion speed formula (Fusion.best:
-- max + min x Config.FuseSpeedShare) for its two animals. Only ever raises Speed, from the
-- animals themselves, so loading again doesn't add to it.
local function loadedHybridStats(kind, fuse, stats)
	local saved = savedStats(stats)
	if not saved then
		return nil
	end
	local fresh = Fusion.best(Fusion.stats(kind), Fusion.stats(fuse))
	return { Speed = math.max(saved.Speed, fresh.Speed), Stamina = saved.Stamina }
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
-- How full the pen is: every egg and pet in it, and the pet you ride (Config.PenCapacity).
local function penCount(profile)
	local n = if profile.ride then 1 else 0
	for _ in profile.items do
		n += 1
	end
	return n
end
local function penCap(player)
	local cfg = Config.PenCapacity
	if not cfg then
		return math.huge -- (uncapped: QM, Oct 14)
	end
	return cfg.Base + cfg.PerUpgrade * ((player:GetAttribute("PenLevel") or 1) - 1)
end

local freeSpot -- (below)
local function publish(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	-- No pet waits at the pen's gap any more (QM, Oct 15: "the starter is just whichever pet is
	-- fastest": Client/Ride rides your fastest at the start line): the one that did is an ordinary
	-- pen pet now. (Not mid-tutorial: its first ride is still from there.)
	local gapPen = profile.ride and not player:GetAttribute("Tutorial") and penOf(player)
	local gapArea = gapPen and gapPen:FindFirstChild("Area")
	if gapArea and freeSpot then
		local spot = freeSpot(gapPen, profile, gapArea)
		profile.items[HttpService:GenerateGUID(false)] = { x = spot.X, z = spot.Y, pet = profile.ride, merged = profile.rideMerged, fuse = profile.rideFuse,
			income = profile.rideIncome, stats = profile.rideStats, worth = profile.rideWorth, tier = profile.rideTier, auto = profile.rideAuto }
		profile.ride, profile.rideMerged, profile.rideFuse, profile.rideIncome = nil, nil, nil, nil
		profile.rideStats, profile.rideWorth, profile.rideTier, profile.rideAuto = nil, nil, nil, nil
	end
	syncTools(player, profile.eggs)
	player:SetAttribute("HatchCredits", math.max(0, (player:GetAttribute("BoughtHatches") or 0) - (profile.usedHatches or 0)))
	player:SetAttribute("RidePet", profile.ride or "")
	player:SetAttribute("RollPrice", rollPrice(profile))
	player:SetAttribute("RainbowTrail", profile.rainbowTrail or nil) -- bought (Config.RainbowTrail): every ride trails a rainbow
	player:SetAttribute("QuestsSeen", profile.questsSeen or nil) -- (BaseUi: the tap hand on the folded Quests panel till it's opened once)
	player:SetAttribute("RidesDone", profile.ridesDone or 0) -- (PassButtons: from the 3rd)
	player:SetAttribute("RideMerged", profile.rideMerged or 1) -- how many pets it's merged from (Shared/Merge)
	player:SetAttribute("RideFuse", profile.rideFuse) -- the donor, if it's a hybrid (Shared/Fusion)
	player:SetAttribute("RideTier", profile.rideFuse and profile.rideTier or nil) -- its saved size tier (Fusion.tier)
	player:SetAttribute("RideAuto", profile.rideFuse and profile.rideAuto or nil) -- its kept automatic ability (Fusion.autoAbility)
	player:SetAttribute("RideIncome", profile.rideIncome) -- (a hybrid's: what both its pets earned)
	player:SetAttribute("RideWorth", profile.rideWorth) -- (a hybrid's FUSE price: Fusion.worth)
	local stats = profile.rideFuse and profile.rideStats
	player:SetAttribute("RideStats", stats and Vector2.new(stats.Speed, stats.Stamina) or nil) -- (a hybrid's Speed, Stamina: Fusion.stats)
	-- Caught, for the Index (QM, Oct 15: "any you either hatch as a pet, or come back from riding
	-- with it": a pet you actually got): every pet you have now (in your pen, taken out, the one
	-- you ride) goes in, kept for good (saved as "caught").
	profile.caught = profile.caught or {}
	for _, list in { profile.items, profile.stored or {} } do
		for _, item in list do
			if typeof(item.pet) == "string" and isAnimal(item.pet) then
				profile.caught[item.pet] = true
			end
		end
	end
	if profile.ride and isAnimal(profile.ride) then
		profile.caught[profile.ride] = true
	end
	local caught = {}
	for kind in profile.caught do
		table.insert(caught, kind)
	end
	table.sort(caught)
	player:SetAttribute("Caught", HttpService:JSONEncode(caught))
	player:SetAttribute("Ridden", HttpService:JSONEncode(riddenList(profile))) -- for the animal dictionary (AnimalDex)
	player:SetAttribute("StoredPets", HttpService:JSONEncode(profile.stored or {})) -- (the Pets panel's unequipped ones: Client/PetsPanel)
	local pen = penOf(player)
	if pen then
		pen:SetAttribute("Contents", HttpService:JSONEncode(profile.items))
		pen:SetAttribute("PetCount", penCount(profile)) -- (Pens.server's "5/10"; Pen.client stops placing when full)
		pen:SetAttribute("PetCap", if Config.PenCapacity then penCap(player) else nil) -- (none: no "5/10" on the sign)
	end
	if profile.quests then
		Quests.penCount(player, profile.quests, penCount(profile)) -- ("Collect animals": live)
	end
end

-- Whether (x, z) in the pen's Area is inside it. Eggs can go anywhere in the
-- pen, even on top of each other (QM).
local function canPlace(pen, x, z)
	local area = pen:FindFirstChild("Area")
	return area ~= nil and math.abs(x) <= area.Size.X / 2 - EDGE and math.abs(z) <= area.Size.Z / 2 - EDGE
end

-- Every pet in your pen earns Config.PetIncome gold a second (the pet you ride too).
-- x2 Gold (game pass) and rebirths (Config.goldX): x this on all the gold pets earn.
local function goldX(player)
	return Config.goldX(player)
end

-- Fast Hatch (game pass): hatch times / this.
local function hatchX(player)
	return if player:GetAttribute("PassFastHatch") then Config.PassHatchSpeed else 1
end

local function income(profile)
	-- (a merged pet earns for all it's made of; a hybrid what both its pets earned)
	-- (only the pets that earn in this world: Halloween ones in the Halloween world, the rest
	-- everywhere else, Config.earnsHere; QM, Oct 15)
	local total = if profile.ride and not Config.earnsHere(profile.ride, profile.rideFuse) then 0
		else profile.rideIncome or (Config.PetIncome[profile.ride] or 0) * (profile.rideMerged or 1)
	for _, item in profile.items do
		if item.pet and Config.earnsHere(item.pet, item.fuse) then
			total += item.income or (Config.PetIncome[item.pet] or 0) * (item.merged or 1)
		end
	end
	return total
end

-- While you were away (QM, Oct 3): back after time away, your pets have earned
-- Config.AwayRate of their usual gold a second for up to Config.AwayCap seconds of
-- it. It waits in the "AwayGold" attribute until ClaimAway (the client sends it at
-- once: QM, Oct 11, no popup); unclaimed, it's saved and added to the next visit's.
local function awayGold(player, profile, data)
	local seen = tonumber(data.seen)
	local away = if seen then math.clamp(os.time() - seen, 0, Config.AwayCap) else 0
	local x = (if Passes.owns(player, "DoubleGold") then Config.PassGoldMultiplier else 1) -- (waits for the pass check)
		* (Config.Rebirth.Gold[player:GetAttribute("Rebirths") or 0] or 1)
	return (tonumber(data.awayGold) or 0) + math.floor(income(profile) * x * Config.AwayRate * away)
end

-- A saved pen's gold a second (as income(), from its save), at its own world's rates.
local function savedIncome(data, world)
	if typeof(data) ~= "table" or not (data.tutorial or next(data.items or {})) then
		return 0
	end
	local total = tonumber(data.rideIncome) or (Config.incomeIn(world, data.ride) or 0) * (tonumber(data.rideMerged) or 1)
	for _, item in typeof(data.items) == "table" and data.items or {} do
		if typeof(item) == "table" and item.pet then
			total += tonumber(item.income) or (Config.incomeIn(world, item.pet) or 0) * (tonumber(item.merged) or 1)
		end
	end
	return total
end

local function loadOtherWorlds(player)
	local total = 0
	for world, other in otherStores do
		local success, data = pcall(other.GetAsync, other, "u" .. player.UserId)
		if success then
			total += savedIncome(data, world)
		end
	end
	otherIncome[player] = total
end

-- Leaving: the other worlds' pens were "here" all along (their pets were earning).
local function markOtherWorldsSeen(player)
	local now = os.time()
	for _, other in otherStores do
		pcall(other.UpdateAsync, other, "u" .. player.UserId, function(data)
			if typeof(data) ~= "table" then
				return nil
			end
			data.seen = now
			return data
		end)
	end
end

-- The old per-world pens into the shared one, once (QM, Oct 14): their pets and eggs added
-- to it (a world's ride as a pet in the pen), their quests and Analytics V1 record under
-- that world's own keys, the shop counts the higher of the two. nil data: no shared pen yet.
-- Returns the data to load, with .merged set, or nil and false if an old pen couldn't be
-- read (tried again next time; nothing's lost meanwhile).
local function mergeOld(player, data)
	if typeof(data) == "table" and data.merged then
		return data, true
	end
	local olds = {}
	for world, old in oldStores do
		local success, value = pcall(old.GetAsync, old, "u" .. player.UserId)
		if not success then
			return data, false
		end
		olds[world] = value
	end
	local merged = if typeof(data) == "table" then data else nil
	for world, old in olds do
		if typeof(old) ~= "table" then
			continue
		end
		merged = merged or { eggs = {}, items = {}, tutorial = old.tutorial }
		merged.eggs = typeof(merged.eggs) == "table" and merged.eggs or {}
		merged.items = typeof(merged.items) == "table" and merged.items or {}
		for kind, n in typeof(old.eggs) == "table" and old.eggs or {} do
			if tonumber(n) then
				merged.eggs[kind] = (tonumber(merged.eggs[kind]) or 0) + n
			end
		end
		for id, item in typeof(old.items) == "table" and old.items or {} do
			merged.items[id] = item
		end
		if isAnimal(old.ride) then -- (the pet you rode there: into the pen with the rest)
			local k = 0
			for _ in merged.items do
				k += 1
			end
			merged.items[HttpService:GenerateGUID(false)] = { x = -14 + (k % 5) * 7, z = 14 - (k // 5 % 5) * 7, pet = old.ride,
				merged = old.rideMerged, fuse = old.rideFuse, income = old.rideFuse and old.rideIncome or nil, stats = old.rideStats,
				worth = old.rideWorth, tier = old.rideTier }
		end
		merged[worldKey("quests", world)] = old.quests
		merged[worldKey("v1", world)] = old.v1
		for _, field in { "boughtPets", "boughtHalloweenPets", "boughtGiantEggs", "boughtLoongs", "boughtRoboSharks", "usedHatches", "homeEggs" } do
			if tonumber(old[field]) then
				merged[field] = math.max(tonumber(merged[field]) or 0, old[field])
			end
		end
		merged.tutorial = merged.tutorial or old.tutorial
	end
	if merged then
		merged.merged = true
	end
	return merged, true
end

local inviteCredits -- (below: "Invite a friend")
local claimStarter -- (below: the Starter Pack)
local function load(player)
	task.spawn(loadOtherWorlds, player)
	local profile = { eggs = {}, items = {}, ride = Config.DefaultPet, ridden = {} }
	local fresh = true -- (no save in this world: a first visit, for Funnel)
	if store then
		for attempt = 1, 3 do
			local success, data = pcall(store.GetAsync, store, "u" .. player.UserId)
			local mergedOk
			if success then
				data, mergedOk = mergeOld(player, data)
				profile.merged = mergedOk or nil -- (saved with it: not merged again)
			end
			if success then
				if typeof(data) == "table" then
					-- (a first visit to this world: no record of it in the shared pen yet. World 1
					-- keeps meaning a brand new player.)
					fresh = if Config.World == 1 then false else data[worldKey("v1")] == nil
					profile.keep = {} -- (the other worlds' own fields, written back as they were)
					for world in Config.Places do
						if world ~= Config.World then
							for _, name in { "quests", "v1" } do
								profile.keep[worldKey(name, world)] = data[worldKey(name, world)]
							end
						end
					end
					profile.v1 = data[worldKey("v1")] -- (Funnel's: entry build, enrolment, steps logged once)
					for kind, n in data.eggs or {} do
						if eggPet(kind) and tonumber(n) and n > 0 then
							profile.eggs[kind] = math.floor(n)
						end
					end
					if isAnimal(data.ride) then
						profile.ride = data.ride
						profile.rideMerged = tonumber(data.rideMerged) and math.max(1, math.floor(data.rideMerged)) or nil
						if isAnimal(data.rideFuse) and tonumber(data.rideIncome) then -- (its donor can be its own kind: Fusion.combine)
							profile.rideFuse, profile.rideIncome = data.rideFuse, math.max(0, tonumber(data.rideIncome))
							profile.rideStats = loadedHybridStats(profile.ride, profile.rideFuse, data.rideStats)
							profile.rideWorth = tonumber(data.rideWorth) and math.max(0, tonumber(data.rideWorth)) or nil
							profile.rideTier = tonumber(data.rideTier) -- (none before Oct 8: Fusion.tier works it out)
							profile.rideAuto = if typeof(data.rideAuto) == "string" and Config.AutoAbilities[data.rideAuto] then data.rideAuto else nil
						end
					end
					profile.rolls = tonumber(data.rolls) and math.max(0, math.floor(data.rolls)) or nil
					profile.homeEggs = tonumber(data.homeEggs) -- (animals brought home, counted from the Egg Rodeo's first session: Funnel)
					profile.quests = Quests.load(data[worldKey("quests")])
					profile.rainbowTrail = data.rainbowTrail == true or nil
					profile.questsSeen = data.questsSeen == true or nil -- (opened the Quests panel: no tap hand on it)
					profile.starterPack = data.starterPack == true or nil -- (the Starter Pack's gold and Snake given)
					profile.ab = typeof(data.ab) == "table" and data.ab or nil -- (the ride egg A/B: their cohort day, day 1 return counted)
					-- (rides finished, for the pass buttons: they show from the 3rd, QM Oct 14. A save
					-- from before this, past the tutorial, counts as plenty)
					profile.ridesDone = tonumber(data.ridesDone) or (if data.tutorial then 3 else 0)
					player:SetAttribute("FuseLesson", nil) -- (no fuse lesson any more: QM, Oct 8)
					profile.tutorial = data.tutorial == true or next(data.eggs or {}) ~= nil or next(data.items or {}) ~= nil
					for _, kind in typeof(data.ridden) == "table" and data.ridden or {} do
						if isAnimal(kind) then
							profile.ridden[kind] = true
						end
					end
					for id, item in data.items or {} do
						if typeof(item) == "table" and tonumber(item.x) and tonumber(item.z)
							and (isAnimal(item.egg) or isAnimal(item.pet)) then
							if not (item.pet and isAnimal(item.fuse) and tonumber(item.income)) then
								item.fuse, item.income = nil, nil -- (a hybrid: Shared/Fusion)
							end
							item.stats = item.fuse and loadedHybridStats(item.pet, item.fuse, item.stats) or nil
							item.worth = item.fuse and tonumber(item.worth) and math.max(0, tonumber(item.worth)) or nil
							item.tier = item.fuse and tonumber(item.tier) or nil
							item.auto = item.fuse and typeof(item.auto) == "string" and Config.AutoAbilities[item.auto] and item.auto or nil
							profile.items[id] = item
						end
					end
					profile.caught = {} -- (the Index's: pets you've had, publish)
					for _, kind in typeof(data.caught) == "table" and data.caught or {} do
						if isAnimal(kind) then
							profile.caught[kind] = true
						end
					end
					-- (pets taken out of the pen in the Pets panel: kept, not earning, QM Oct 15)
					profile.stored = {}
					for id, item in typeof(data.stored) == "table" and data.stored or {} do
						if typeof(item) == "table" and isAnimal(item.pet) then
							if not (isAnimal(item.fuse) and tonumber(item.income)) then
								item.fuse, item.income = nil, nil
							end
							item.stats = item.fuse and loadedHybridStats(item.pet, item.fuse, item.stats) or nil
							item.worth = item.fuse and tonumber(item.worth) and math.max(0, tonumber(item.worth)) or nil
							item.tier = item.fuse and tonumber(item.tier) or nil
							profile.stored[id] = item
						end
					end
					if profile.tutorial then
						profile.awayGold = awayGold(player, profile, data)
					end
					profile.usedHatches = tonumber(data.usedHatches) or 0
					profile.hatchTarget = typeof(data.hatchTarget) == "string" and data.hatchTarget or nil
					profile.boughtHalloweenPets = tonumber(data.boughtHalloweenPets)
					profile.boughtPets = tonumber(data.boughtPets) -- Legendary Pets from the shop already in (addBoughtPets)
					profile.boughtGiantEggs = tonumber(data.boughtGiantEggs) -- Giant Horse eggs from the shop already in (addBoughtGiantEggs)
					profile.boughtLoongs = tonumber(data.boughtLoongs) -- Loongs bought at the base already in (addBoughtOffer)
					profile.boughtRoboSharks = tonumber(data.boughtRoboSharks) -- and Robo Sharks
				end
				loaded[player] = true
				player:GetAttributeChangedSignal("PenLevel"):Connect(function() -- (an upgrade makes room: Config.PenCapacity)
					publish(player)
				end)
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
	profile.quests = profile.quests or Quests.load(nil)
	-- (Analytics V1: a fresh pen is a new arrival only if its load went through, or in Studio)
	Funnel.start(player, profile, fresh and (loaded[player] == true or RunService:IsStudio()))
	Telemetry.profileReady(player, Config.World == 1 and fresh and (loaded[player] == true or RunService:IsStudio()))
	if store and not loaded[player] and not RunService:IsStudio() then
		Telemetry.loadFailed(player)
	end
	Quests.publish(player, profile.quests)
	player:GetAttributeChangedSignal("PassStarterPack"):Connect(function()
		claimStarter(player)
	end)
	task.spawn(claimStarter, player)
	task.spawn(function() -- friends you invited who joined while you were elsewhere ("Invite a friend")
		local credits = inviteCredits(player)
		for _ = 1, credits do
			if profiles[player] then
				Quests.count(player, profiles[player].quests, "invite")
			end
		end
	end)
	player:GetAttributeChangedSignal("GatesBroken"):Connect(function() -- ("Enter Desert" and the like)
		if profiles[player] then
			Quests.publish(player, profiles[player].quests)
		end
	end)
	if not profile.tutorial then
		profile.homeEggs = profile.homeEggs or 0
	end
	-- Only World 1 has the tutorial: in the others you've done it (QM: a new pen there).
	local tutorial = Config.Tutorial and not profile.tutorial and Config.World == 1
	if Config.World ~= 1 then
		profile.tutorial = true
	end
	if tutorial then
		profile.ride = nil -- RidePet "": no pet waits in the pen yet
		profile.eggs = { [Config.DefaultPet] = 1 }
	end
	player:SetAttribute("Tutorial", if tutorial then true else nil)
	player:SetAttribute("AwayGold", if (profile.awayGold or 0) > 0 then profile.awayGold else nil)
	publish(player)
end

-- "Invite a friend" (QM, Oct 12): the invite (BaseUi: SocialService) carries the
-- inviter's UserId as its launch data. When the friend joins, the inviter's quest counts
-- one, here if they're in this server, else saved under InviteCredits for their next join.
local inviteStore
do
	local okInvites, s = pcall(DataStoreService.GetDataStore, DataStoreService, "InviteCredits")
	inviteStore = if okInvites then s else nil
end
inviteCredits = function(player) -- (taken: the count's gone from the store once read)
	if not inviteStore then
		return 0
	end
	local n = 0
	pcall(inviteStore.UpdateAsync, inviteStore, "u" .. player.UserId, function(old)
		n = tonumber(old) or 0
		return if n > 0 then 0 else nil
	end)
	return n
end
Players.PlayerAdded:Connect(function(player)
	local okJoin, data = pcall(player.GetJoinData, player)
	local inviter = okJoin and data and tonumber(data.LaunchData)
	if not inviter or inviter == player.UserId then
		return
	end
	local there = Players:GetPlayerByUserId(inviter)
	if there and profiles[there] then
		Quests.count(there, profiles[there].quests, "invite")
	elseif inviteStore then
		pcall(inviteStore.UpdateAsync, inviteStore, "u" .. inviter, function(old)
			return (tonumber(old) or 0) + 1
		end)
	end
end)

local savedAs = {} -- [player] = the profile as last saved, as JSON (autosave skips it if unchanged)

-- onlyIfChanged: the autosave's, which skips it when nothing changed.
local function save(player, onlyIfChanged)
	local profile = profiles[player]
	if not store or not profile or not loaded[player] or player:GetAttribute("Tutorial") then
		return
	end
	local data = { eggs = profile.eggs, items = profile.items, stored = profile.stored, caught = profile.caught and (function() local t = {} for k in profile.caught do table.insert(t, k) end return t end)() or nil, ride = profile.ride, rideMerged = profile.rideMerged, rideFuse = profile.rideFuse, rideIncome = profile.rideIncome, rideStats = profile.rideStats, rideWorth = profile.rideWorth, rideTier = profile.rideTier, rideAuto = profile.rideAuto, tutorial = profile.tutorial, ridden = riddenList(profile),
		awayGold = profile.awayGold, boughtHalloweenPets = profile.boughtHalloweenPets, boughtPets = profile.boughtPets, boughtGiantEggs = profile.boughtGiantEggs, boughtLoongs = profile.boughtLoongs, boughtRoboSharks = profile.boughtRoboSharks, usedHatches = profile.usedHatches, hatchTarget = profile.hatchTarget, rolls = profile.rolls,
		rainbowTrail = profile.rainbowTrail, questsSeen = profile.questsSeen, starterPack = profile.starterPack, ridesDone = profile.ridesDone, homeEggs = profile.homeEggs, fuseLesson = player:GetAttribute("FuseLesson") == true or nil,
		merged = profile.merged, ab = profile.ab }
	data[worldKey("quests")], data[worldKey("v1")] = profile.quests, profile.v1 -- (this world's own)
	for name, value in profile.keep or {} do -- (the other worlds', as they were)
		data[name] = value
	end
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
	local at = pen.Area.CFrame:PointToWorldSpace(Vector3.new(item.x, 0, item.z)) -- (x, z in the pen's frame: its pens are turned)
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
	return "purchase", item.hatchAt - os.time() -- (its time left picks the product: Config.speedupTier)
end
prepareHatch.Parent = game:GetService("ServerStorage")

-- Fast Hatch bought in game: the eggs already waiting in the pen have their time
-- left cut too (the eggs placed from then on start out with half).
Passes.onBought(function(player, key)
	local profile = profiles[player]
	if key ~= "FastHatch" or not profile or player:GetAttribute("Tutorial") then
		return
	end
	local now = os.time()
	for _, item in profile.items do
		if item.egg and item.hatchAt > now then
			item.hatchAt = now + math.ceil((item.hatchAt - now) / Config.PassHatchSpeed)
		end
	end
	publish(player)
end)

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
	if loaded[player] then
		task.spawn(markOtherWorldsSeen, player)
	end
	save(player)
	profiles[player], loaded[player], savedAs[player], applyingHatch[player], otherIncome[player] = nil, nil, nil, nil, nil
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

-- An animal you rode home or over the finish line (QM, Oct 13: the animal itself, not its
-- egg; eggs come from quests now): straight into your pen as a pet, at the first clear
-- spot from the middle out. A full pen (Config.PenCapacity) gets its egg instead.
-- The first clear spot in your pen from the middle out (or anywhere in it).
freeSpot = function(pen, profile, area)
		local best
		for r = 0, 6 do
			for dx = -r, r do
				for dz = -r, r do
					if not best and math.max(math.abs(dx), math.abs(dz)) == r then
						local x, z = dx * 7, dz * 7
						local clear = canPlace(pen, x, z)
						for _, item in profile.items do
							if clear and math.abs(item.x - x) < 6 and math.abs(item.z - z) < 6 then
								clear = false
							end
						end
						best = if clear then Vector2.new(x, z) else nil
					end
				end
			end
		end
		return best or Vector2.new(Random.new():NextNumber(-1, 1) * (area.Size.X / 2 - EDGE), Random.new():NextNumber(-1, 1) * (area.Size.Z / 2 - EDGE)) -- (no clear spot: anywhere in it)
end
local function givePet(player, profile, kind)
	Funnel.rewarded(player) -- (the server's award: Analytics V1)
	Telemetry.reward(player)
	local pen = penOf(player)
	local area = pen and pen:FindFirstChild("Area")
	if area and penCount(profile) < penCap(player) then
		local best = freeSpot(pen, profile, area)
		profile.items[HttpService:GenerateGUID(false)] = { x = best.X, z = best.Y, pet = kind }
		profile.pastStarter = true
		publish(player)
		return true
	end
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
	return false
end

-- Ride egg A/B (Config.RideEggAB, QM Oct 19). The arm is by UserId, so it's the same every
-- session and server; it's on the player as "ABRideEgg". The "egg" arm's rides home and finish
-- lines give the animal's egg instead of the animal, into the egg inventory to place, as rides
-- did before Oct 13. The tutorial's first ride's egg goes straight into the pen, so its "a new
-- one in your pen" step goes on, and stays an egg (no tutorial auto-hatch: byHand) till you
-- hatch it, after Config.RideEggAB.FastHatch seconds (QM, Oct 19).
local RideEggAB = {}
function RideEggAB.arm(player)
	local ab = Config.RideEggAB
	if RunService:IsStudio() then
		return ab.Studio
	end
	return if (player.UserId + ab.Salt * 389) % 1000 < ab.Share * 1000 then "egg" else "control"
end
function RideEggAB.give(player, profile, kind)
	if player:GetAttribute("ABRideEgg") ~= "egg" or not isAnimal(kind) then
		return givePet(player, profile, kind)
	end
	Funnel.rewarded(player) -- (as givePet: the server's award)
	Telemetry.reward(player)
	local pen = penOf(player)
	local area = pen and pen:FindFirstChild("Area")
	if player:GetAttribute("Tutorial") and area and penCount(profile) < penCap(player) then
		local spot = freeSpot(pen, profile, area)
		profile.items[HttpService:GenerateGUID(false)] = { x = spot.X, z = spot.Y, egg = kind, hatchAt = os.time() + Config.RideEggAB.FastHatch, byHand = true }
		profile.pastStarter = true
		publish(player)
		return true
	end
	profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	publish(player)
	return false
end
-- Each arm's totals in the shared stats store ("ab-rideegg-<arm>", read by /stats ab): sessions
-- and their seconds, new players by the day they started ("new:<day>"), and those who came back
-- the next day ("d1:<day>"). Robux is added by Telemetry.purchase.
RideEggAB.joined = {}
function RideEggAB.join(player)
	local arm = RideEggAB.arm(player)
	player:SetAttribute("ABRideEgg", arm)
	RideEggAB.joined[player] = os.clock()
	for _ = 1, 60 do -- (till their save's loaded: a new player?)
		if loaded[player] or not player.Parent then
			break
		end
		task.wait(0.5)
	end
	local profile = profiles[player]
	if not profile or not player.Parent then
		return
	end
	local today = os.date("!%Y-%m-%d")
	local fields = { sessions = 1 }
	if not profile.ab and not profile.tutorial then -- (a new player: their cohort is today)
		profile.ab = { day = today }
		fields["new:" .. today] = 1
	elseif profile.ab and not profile.ab.d1 and profile.ab.day == os.date("!%Y-%m-%d", os.time() - 86400) then
		profile.ab.d1 = true
		fields["d1:" .. profile.ab.day] = 1
	end
	require(script.Parent.StatsStore).addShared("ab-rideegg-" .. arm, fields)
end
Players.PlayerAdded:Connect(RideEggAB.join)
for _, player in Players:GetPlayers() do -- (joined while this script was still starting: Studio's Play)
	task.spawn(RideEggAB.join, player)
end
Players.PlayerRemoving:Connect(function(player)
	local at, arm = RideEggAB.joined[player], player:GetAttribute("ABRideEgg")
	RideEggAB.joined[player] = nil
	if at and arm then
		require(script.Parent.StatsStore).addShared("ab-rideegg-" .. arm, { seconds = math.floor(os.clock() - at) })
	end
end)

-- The Pets panel (QM, Oct 15): a pet in your pen taken out (stored: it keeps everything but its
-- spot, and earns nothing), or a stored one put back in at the first clear spot, room allowing.
remote("UnequipPet", function(player, id)
	local profile = profiles[player]
	if profile and id == "ride" and profile.ride then
		-- (the pet at your pen's gap, the one a ride sets off on: out like any other, QM Oct 15;
		-- your best other pet in the pen takes its place there, if you have one)
		profile.stored = profile.stored or {}
		profile.stored[HttpService:GenerateGUID(false)] = { pet = profile.ride, merged = profile.rideMerged, fuse = profile.rideFuse,
			income = profile.rideIncome, stats = profile.rideStats, worth = profile.rideWorth, tier = profile.rideTier, auto = profile.rideAuto }
		local bestId, best
		for itemId, item in profile.items do
			local earns = item.pet and Fusion.earning(item.pet, item.merged, item.income)
			if earns and (not best or earns > best) then
				bestId, best = itemId, earns
			end
		end
		local next = bestId and profile.items[bestId]
		profile.ride = next and next.pet
		profile.rideMerged, profile.rideFuse, profile.rideIncome = next and next.merged, next and next.fuse, next and next.income
		profile.rideStats, profile.rideWorth, profile.rideTier, profile.rideAuto = next and next.stats, next and next.worth, next and next.tier, next and next.auto
		if bestId then
			profile.items[bestId] = nil
		end
		publish(player)
		save(player)
		return
	end
	local item = profile and typeof(id) == "string" and profile.items[id]
	if not item or not isAnimal(item.pet) then
		return
	end
	profile.stored = profile.stored or {}
	profile.items[id] = nil
	item.x, item.z = nil, nil
	profile.stored[id] = item
	publish(player)
	save(player)
end)
remote("EquipPet", function(player, id)
	local profile = profiles[player]
	local item = profile and profile.stored and typeof(id) == "string" and profile.stored[id]
	local pen = penOf(player)
	local area = pen and pen:FindFirstChild("Area")
	if not item or not area or penCount(profile) >= penCap(player) then
		return
	end
	profile.stored[id] = nil
	if not profile.ride and player:GetAttribute("Tutorial") then -- (mid-tutorial, nothing at the gap: it waits there)
		profile.ride, profile.rideMerged, profile.rideFuse, profile.rideIncome = item.pet, item.merged, item.fuse, item.income
		profile.rideStats, profile.rideWorth, profile.rideTier, profile.rideAuto = item.stats, item.worth, item.tier, item.auto
	else
		local spot = freeSpot(pen, profile, area)
		item.x, item.z = spot.X, spot.Y
		profile.items[id] = item
	end
	publish(player)
	save(player)
end)

-- The ride got its animal home: the animal itself, into your pen (givePet), the
-- tutorial's first ride's too (QM, Oct 13: its new animal cutscene; the tutorial goes on
-- once there's a new pet in the pen).
remote("DeliverEgg", function(player, kind)
	local profile = profiles[player]
	if not profile or not isAnimal(kind) or player:GetAttribute("CarriedEgg") ~= kind then
		return
	end
	player:SetAttribute("CarriedEgg", nil)
	if profile.homeEggs then
		profile.homeEggs += 1
	end
	RideEggAB.give(player, profile, kind)
end)

-- The Starter Pack (game pass, QM, Oct 13): Config.StarterPack's gold and pet, once, when
-- you own it (bought now, or on joining), saved with the pen so it's never given twice.
-- Not till the pen's loaded (a failed load could give it again) or the tutorial's done.
claimStarter = function(player)
	local profile = profiles[player]
	if not profile or profile.starterPack or not player:GetAttribute("PassStarterPack") then
		return
	end
	if not loaded[player] and not RunService:IsStudio() then
		return
	end
	if player:GetAttribute("Tutorial") then
		task.delay(5, claimStarter, player)
		return
	end
	profile.starterPack = true
	for _, kind in Config.StarterPack.Pets do -- (into the pen, or the egg inventory if it's full: givePet)
		givePet(player, profile, kind)
	end
	if Config.StarterPack.World then -- (World 2 unlocked at once: Gold.server saves it)
		player:SetAttribute("OwnsWorld" .. Config.StarterPack.World, true)
	end
	task.spawn(save, player)
	local newAnimal = ReplicatedStorage:FindFirstChild("NewAnimal")
	if newAnimal then
		newAnimal:FireClient(player, Config.StarterPack.Pets[1]) -- (the Robo Shark's cutscene, as /give's)
	end
end

-- You held E by an egg in your pen that's ready (Pen.client): it hatches.
remote("HatchEgg", function(player, id)
	local profile = profiles[player]
	local pen = penOf(player)
	local item = profile and typeof(id) == "string" and profile.items[id]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not loaded[player] or not pen or not root or not item or not item.egg or item.hatchAt > os.time() or applyingHatch[player] then
		return
	end
	local at = pen.Area.CFrame:PointToWorldSpace(Vector3.new(item.x, 0, item.z)) -- (x, z in the pen's frame: its pens are turned)
	if (root.Position - at).Magnitude > Config.SpeedupEgg.Range + 4 then
		return
	end
	item.pet, item.egg, item.hatchAt = item.egg, nil, nil
	if not profile.pastStarter then
		Funnel.starterReady(player) -- (Analytics V1)
	end
	Telemetry.once(player, "eggHatched")
	publish(player)
end)

-- The ride crossed the finish line at the end of the course: the animal you rode there
-- (QM, Oct 13: the animal itself, givePet), or (a hybrid, say) a random one, drawn like the
-- stampede itself (each biome's Herd counts as weights, so a Unicorn is as rare as Unicorns are). And
-- (until Oct 15, the next of Config.FinishTrails too). Returns
-- the kind, for the egg reveal.
local finished = {} -- [player] = os.clock() of their last finish
local finishCourse = Instance.new("RemoteFunction")
finishCourse.Name = "FinishCourse"
finishCourse.OnServerInvoke = function(player, rode)
	local profile = profiles[player]
	if not profile or (finished[player] and os.clock() - finished[player] < 10) then
		return nil
	end
	finished[player] = os.clock()
	-- (no trail for it any more: QM, Oct 15; ones already earned stay, Config.FinishTrails)
	Quests.count(player, profile.quests, "finish") -- ("Cross the finish line 5 times", QM Oct 15)
	if typeof(rode) == "string" and isAnimal(rode) then
		RideEggAB.give(player, profile, rode)
		return rode
	end
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
	RideEggAB.give(player, profile, kind)
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

-- Claiming a finished quest (Config.Quests; BaseUi's CLAIM): its egg, and your pen's
-- next level (up to the last biome's). Returns the egg's kind, for the egg reveal; nil
-- if it didn't go through.
local claimQuest = Instance.new("RemoteFunction")
claimQuest.Name = "ClaimQuest"
claimQuest.OnServerInvoke = function(player, i)
	local profile = profiles[player]
	local quest = profile and typeof(i) == "number" and Quests.claim(player, profile.quests, i)
	if not quest then
		return nil
	end
	local level = math.clamp(player:GetAttribute("PenLevel") or 1, 1, Config.PenLevels)
	if level < Config.PenLevels and not quest.NoPenLevel then -- (not "Reach Meadow": QM)
		player:SetAttribute("PenLevel", level + 1)
	end
	Funnel.claimed(player, i) -- (Analytics V1)
	local eggs = if typeof(quest.Egg) == "table" then quest.Egg else { quest.Egg } -- (several: World 2's Kitsune quest)
	for _, kind in eggs do
		profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
	end
	publish(player)
	return eggs[1]
end
claimQuest.Parent = ReplicatedStorage
-- Gold.server's: a lasso landed on a wild animal ("Lasso animals", and "Lasso Snowmen" by its kind).
local questProgress = Instance.new("BindableEvent")
questProgress.Name = "QuestProgress"
questProgress.Event:Connect(function(player, kind, animal)
	local profile = profiles[player]
	if profile then
		Quests.count(player, profile.quests, kind, animal)
	end
end)
questProgress.Parent = game:GetService("ServerStorage")
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
	if penCount(profile) >= penCap(player) then
		return -- the pen's full (Config.PenCapacity)
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
	Telemetry.once(player, "eggPlaced") -- (Analytics V1: the session's first)
	local pet = eggPet(kind)
	local special = Config.SpecialEggs[kind]
	if special then -- (hatches into its Pet, merged from Merged: a Giant Horse is 10 horses)
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = pet, merged = special.Merged, eggScale = special.EggScale, hatchAt = os.time() + math.ceil(special.HatchTime / hatchX(player)) }
	else
		local seconds = if player:GetAttribute("Tutorial") then Config.TutorialHatchTime else math.ceil(hatchTime(kind) / hatchX(player))
		if player:GetAttribute("ABRideEgg") == "egg" and (profile.ridesDone or 0) < Config.RideEggAB.FastRides then
			seconds = math.min(seconds, Config.RideEggAB.FastHatch) -- (the ride egg A/B: the first rides' eggs hatch quickly, QM Oct 19)
		end
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, egg = kind, hatchAt = os.time() + seconds }
	end
	publish(player)
end

-- The client finished the tutorial: it never shows again.
-- The rider got on an animal of this kind (Ride.client): it's in their animal
-- dictionary from now on.
-- A ride's over ("end": Ride.client): counted (saved), up to a point.
task.spawn(function()
	ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
		local profile = profiles[player]
		if what == "end" and profile and (profile.ridesDone or 0) < 100 then
			profile.ridesDone = (profile.ridesDone or 0) + 1
			player:SetAttribute("RidesDone", profile.ridesDone)
		end
	end)
end)

-- The Quests panel opened for the first time (BaseUi): its tap hand's done for good.
remote("QuestsSeen", function(player)
	local profile = profiles[player]
	if profile and not profile.questsSeen then
		profile.questsSeen = true
		publish(player)
	end
end)

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
	Funnel.tutorialDone(player) -- (Analytics V1)
	Telemetry.tutorialDone(player)
end)

-- Ran to the start line in the tutorial before riding the starter pet (QM, Oct 8:
-- many kids do): as if they'd placed the egg, it had hatched and they'd got on.
-- The starter egg, in the inventory or in the pen (hatched or not), becomes the
-- pet they ride (Tutorial.toLine, which then rides it from the line).
local toLine = Instance.new("RemoteFunction")
toLine.Name = "TutorialToLine"
toLine.OnServerInvoke = function(player)
	local profile = profiles[player]
	if not profile or not player:GetAttribute("Tutorial") then
		return false
	end
	if profile.ride then
		return true
	end
	local kind = Config.DefaultPet
	local placed
	for id, item in profile.items do
		if item.egg == kind or item.pet == kind then
			placed = id
			break
		end
	end
	if placed then
		profile.items[placed] = nil
	elseif (profile.eggs[kind] or 0) > 0 then
		profile.eggs[kind] -= 1
		if profile.eggs[kind] == 0 then
			profile.eggs[kind] = nil
		end
	else
		return false
	end
	profile.ride = kind
	Funnel.starterReady(player) -- (Analytics V1)
	Funnel.event(player, "Ran To Start Line")
	publish(player)
	return true
end
toLine.Parent = ReplicatedStorage

-- Ride the pet `id` from now on; the pet you rode takes its place in the pen.
remote("RidePet", function(player, id)
	if not player:GetAttribute("Tutorial") then
		return -- (no pet waits at the gap any more: the one you ride stays a pen pet, QM Oct 15)
	end
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
		item.worth, profile.rideWorth = profile.rideWorth, item.worth
		item.tier, profile.rideTier = profile.rideTier, item.tier
		item.auto, profile.rideAuto = profile.rideAuto, item.auto
	else
		profile.ride, profile.rideMerged, profile.items[id] = item.pet, item.merged, nil -- your first pet: nothing to swap with
		profile.rideFuse, profile.rideIncome, profile.rideStats, profile.rideWorth = item.fuse, item.income, item.stats, item.worth
		profile.rideTier = item.tier
		profile.rideAuto = item.auto
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
	local tier = if rides then Fusion.tier(kind, fuse, profile.rideTier) else 0 -- (the biggest of them: never smaller)
	for id, item in profile.items do
		if item.pet == kind and item.fuse == fuse then
			table.insert(ids, id)
			total += item.merged or 1
			earns += item.income or 0
			tier = math.max(tier, Fusion.tier(kind, fuse, item.tier))
		end
	end
	if #ids + (if rides then 1 else 0) < 2 then
		return
	end
	table.sort(ids)
	if rides then
		profile.rideMerged = total
		profile.rideIncome = if fuse then earns else nil
		profile.rideTier = if fuse then tier else nil
	else
		profile.items[ids[1]].merged = total
		profile.items[ids[1]].income = if fuse then earns else nil
		profile.items[ids[1]].tier = if fuse then tier else nil
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
			return profile.ride and { pet = profile.ride, fuse = profile.rideFuse, merged = profile.rideMerged, income = profile.rideIncome, stats = profile.rideStats, worth = profile.rideWorth, tier = profile.rideTier, auto = profile.rideAuto }
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
	local auto = Fusion.autoAbility(a.pet, a.fuse, a.auto, b.pet, b.fuse, b.auto) -- (kept through the lineage: QM)
	local earns = Fusion.earning(a.pet, a.merged, a.income) + Fusion.earning(b.pet, b.merged, b.income) -- (a hybrid's is saved)
	local stats = Fusion.best(Fusion.stats(a.pet, a.fuse, a.stats), Fusion.stats(b.pet, b.fuse, b.stats)) -- the best of both (QM)
	local tier = math.max(Fusion.tier(a.pet, a.fuse, a.tier), Fusion.tier(b.pet, b.fuse, b.tier)) -- the bigger of the two (QM, Oct 8)
	local lesson = player:GetAttribute("FuseLesson") == true -- (the fuse lesson's fuse is free, once: QM)
	local free = lesson or player:GetAttribute("MergeFree") == true -- (and your first merge ever: QM, Oct 11; Quests.publish)
	local worth = Fusion.worth(a.pet, a.fuse, a.worth) + Fusion.worth(b.pet, b.fuse, b.worth) -- (QM: a hybrid costs all its pets)
	local price = if free then 0 else Fusion.price(earns) -- (QM, Oct 11: minutes of what the two earn)
	local gold = player:GetAttribute("Gold") or 0
	if gold < price then
		return
	end
	player:SetAttribute("Gold", gold - price)
	if lesson then
		player:SetAttribute("FuseLesson", nil) -- (done: client FuseLesson sees the hybrid land)
	end
	if baseId == "ride" or donorId == "ride" then -- the hybrid is the one you ride
		profile.ride, profile.rideFuse, profile.rideMerged, profile.rideIncome, profile.rideStats, profile.rideWorth = base, donor, nil, earns, stats, worth
		profile.rideTier = tier
		profile.rideAuto = auto
		profile.items[if baseId == "ride" then donorId else baseId] = nil
	else
		profile.items[baseId] = { x = a.x, z = a.z, pet = base, fuse = donor, income = earns, stats = stats, worth = worth, tier = tier, auto = auto }
		profile.items[donorId] = nil
	end
	Funnel.event(player, "Fused Pets")
	Quests.count(player, profile.quests, "merge")
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
local newAnimal = Instance.new("RemoteEvent") -- (the client's new animal cutscene, Client/NewAnimal: /give's)
newAnimal.Name = "NewAnimal"
newAnimal.Parent = ReplicatedStorage
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
	newAnimal:FireClient(player, kind) -- (its new animal cutscene, as a ride home's: QM)
end

-- The shop's Legendary Pet (Shop.server): its "BoughtPets" attribute is the
-- running total bought; each one not yet in your profile (boughtPets, saved with
-- it) is a random pet by Config.Shop.LegendaryOdds straight into your pen, hatched, saved at once, and
-- its card shows (ShopGrant). Waits for your profile and pen.
local function addBoughtPets(player, halloween)
	local field = if halloween then "boughtHalloweenPets" else "boughtPets"
	local profile = profiles[player]
	local pen = penOf(player)
	local total = player:GetAttribute(if halloween then "BoughtHalloweenPets" else "BoughtPets")
	if profile and total and profile[field] == nil and Config.World ~= 1 then
		-- (a new pen in another world: what was bought before landed in the world it was
		-- bought in; only what's bought from now on comes here. QM, Oct 13)
		profile[field] = total
		return
	end
	if not profile or not pen or not total or total <= (profile[field] or 0) then
		return
	end
	local area = pen.Area
	local kinds = {}
	for _ = (profile[field] or 0) + 1, total do
		local kind = pick(if halloween then Config.Shop.HalloweenOdds else Config.Shop.LegendaryOdds)
		if isAnimal(kind) then
			local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
			local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
			profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = kind }
			table.insert(kinds, kind)
		end
	end
	profile[field] = total
	publish(player)
	save(player)
	if halloween then
		ReplicatedStorage:WaitForChild("ShopGrant"):FireClient(player, "HalloweenPets", kinds)
	else
		for _, kind in kinds do
			ReplicatedStorage:WaitForChild("ShopGrant"):FireClient(player, "LegendaryPet", kind)
		end
	end
end
-- The shop's Giant Horse (Shop.server): its "BoughtGiantEggs" attribute is the running
-- total bought; each one not yet in your profile (boughtGiantEggs, saved with it) is
-- a Giant Horse egg in your inventory (Config.SpecialEggs.GiantHorse).
local function addBoughtGiantEggs(player)
	local profile = profiles[player]
	local total = player:GetAttribute("BoughtGiantEggs")
	if profile and total and profile.boughtGiantEggs == nil and Config.World ~= 1 then
		profile.boughtGiantEggs = total -- (as addBoughtPets: bought before, landed in its own world)
		return
	end
	if not profile or not total or total <= (profile.boughtGiantEggs or 0) then
		return
	end
	profile.eggs.GiantHorse = (profile.eggs.GiantHorse or 0) + total - (profile.boughtGiantEggs or 0)
	profile.boughtGiantEggs = total
	publish(player)
	save(player)
end
-- The pets at World 1's base stands (Config.PetOffers, QM Oct 15: the Loong, the Robo Shark):
-- "Bought<Kind>s" is the running total bought (Shop.server); each one not yet in your profile
-- (bought<Kind>s) goes straight into your pen, as the Legendary Pet's do, with the new animal popup.
local function addBoughtOffer(player, pet)
	local profile = profiles[player]
	local pen = penOf(player)
	local field = pet.ClaimField or ("bought" .. pet.Kind .. "s")
	local total = player:GetAttribute("Bought" .. pet.Kind .. "s")
	if profile and total and profile[field] == nil and Config.World ~= 1 then
		profile[field] = total -- (as addBoughtPets: bought before, landed in its own world)
		return
	end
	if not profile or not pen or not total or total <= (profile[field] or 0) then
		return
	end
	local area = pen.Area
	local n = total - (profile[field] or 0)
	for _ = 1, n do
		local x = (math.random() - 0.5) * (area.Size.X - 2 * EDGE)
		local z = (math.random() - 0.5) * (area.Size.Z - 2 * EDGE)
		profile.items[HttpService:GenerateGUID(false)] = { x = x, z = z, pet = pet.Kind }
	end
	profile[field] = total
	publish(player)
	save(player)
	for _ = 1, n do
		ReplicatedStorage:WaitForChild("ShopGrant"):FireClient(player, "LoongPet", pet.Kind) -- (the new animal popup, not the Legend Egg's card roll: QM, Oct 15)
	end
end
Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("BoughtPets"):Connect(function()
		addBoughtPets(player)
	end)
	player:GetAttributeChangedSignal("BoughtHalloweenPets"):Connect(function()
		addBoughtPets(player, true)
	end)
	for _, pet in Config.PetOffers do
		player:GetAttributeChangedSignal("Bought" .. pet.Kind .. "s"):Connect(function()
			addBoughtOffer(player, pet)
		end)
	end
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
	addBoughtPets(player, true)
	addBoughtGiantEggs(player)
	for _, pet in Config.PetOffers do
		addBoughtOffer(player, pet)
	end
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
-- the ride). "/boss <biome>" (QM, Oct 10): the same at its end, with the ride's
-- timer at 0.01 s, so the boss comes. Same rule as /give for who can use them.
local BIOME_ALIASES = { tundra = "snow" }
if Config.World == 2 then -- (World 2's biomes keep World 1's names in Config: these are what QM calls them)
	for alias, name in { marble = "meadow", crimson = "desert", cavern = "snow", crystal = "snow", woodland = "ocean", temple = "volcano", tomb = "jurassic" } do
		BIOME_ALIASES[alias] = name
	end
elseif Config.World == 3 then
	for alias, name in { pirate = "piratecove", cove = "piratecove", candy = "candyland", jelly = "cnidaria" } do
		BIOME_ALIASES[alias] = name
	end
end
-- The biome a command names (its name, an alias, or its number), or nil.
local function biomeNamed(name)
	name = name and (BIOME_ALIASES[name:lower()] or name:lower())
	local index = tonumber(name)
	for i, biome in Config.Biomes do
		if i == index or biome.Name:lower() == name then
			return i, biome
		end
	end
	return nil
end

-- Testing: "/egg <biome>" (QM, Oct 13): one egg of every animal in that biome's herd,
-- into your inventory. Same rule as /give for who can use it.
local eggCommand = Instance.new("TextChatCommand")
eggCommand.Name = "Egg"
eggCommand.PrimaryAlias = "/egg"
eggCommand.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	local profile = player and profiles[player]
	local _, biome = biomeNamed(text:match("^/egg%s+(%S+)"))
	if not profile or not biome or not allowed(player) then
		return
	end
	for kind, weight in biome.Herd or {} do
		if weight > 0 and eggPet(kind) then
			profile.eggs[kind] = (profile.eggs[kind] or 0) + 1
		end
	end
	publish(player)
	save(player)
end)
eggCommand.Parent = game:GetService("TextChatService")
local biomeWarp = Instance.new("RemoteEvent")
biomeWarp.Name = "BiomeWarp"
biomeWarp.Parent = ReplicatedStorage
for alias, boss in { biome = false, boss = true } do
	local biomeCommand = Instance.new("TextChatCommand")
	biomeCommand.Name = if boss then "Boss" else "Biome"
	biomeCommand.PrimaryAlias = "/" .. alias
	biomeCommand.Triggered:Connect(function(source, text)
		local player = Players:GetPlayerByUserId(source.UserId)
		local name = text:match("^/" .. alias .. "%s+(%S+)")
		if not player or not name or not allowed(player) then
			return
		end
		name = BIOME_ALIASES[name:lower()] or name:lower()
		for index, biome in Config.Biomes do
			if biome.Name:lower() == name then
				local kinds = {}
				for kind, weight in biome.Herd do
					if weight > 0 then -- (one that runs in its stampede)
						table.insert(kinds, kind)
					end
				end
				biomeWarp:FireClient(player, index, kinds[math.random(#kinds)], boss)
				return
			end
		end
	end)
	biomeCommand.Parent = game:GetService("TextChatService")
end

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
	profiles[player] = { eggs = { [Config.DefaultPet] = 1 }, items = {}, ride = nil, ridden = {}, boughtHalloweenPets = old.boughtHalloweenPets, boughtPets = old.boughtPets, boughtGiantEggs = old.boughtGiantEggs, boughtLoongs = old.boughtLoongs, boughtRoboSharks = old.boughtRoboSharks, usedHatches = old.usedHatches, quests = Quests.load(nil), merged = old.merged, keep = {} }
	Quests.publish(player, profiles[player].quests)
	if store and loaded[player] then
		-- Keep the shop counts saved too: without them, rejoining hands every Giant Horse
		-- egg and Legendary Pet ever bought over again (addBoughtGiantEggs / addBoughtPets).
		task.spawn(pcall, store.SetAsync, store, "u" .. player.UserId, { eggs = {}, items = {}, tutorial = false, usedHatches = old.usedHatches,
			boughtHalloweenPets = old.boughtHalloweenPets, boughtPets = old.boughtPets, boughtGiantEggs = old.boughtGiantEggs, boughtLoongs = old.boughtLoongs, boughtRoboSharks = old.boughtRoboSharks, merged = old.merged })
	end
	player:SetAttribute("Gold", 0) -- Gold and PenLevel save these when you leave
	player:SetAttribute("PenLevel", 1)
	player:SetAttribute("GatesBroken", 1) -- (and every barrier back, as a new player's: else "Enter Desert" is done already)
	player:SetAttribute("CarriedEgg", nil)
	player:SetAttribute("FuseLesson", nil)
	player:SetAttribute("Tutorial", nil) -- off then on, so a tutorial already running starts over
	publish(player) -- before it's back on: the old RidePet still set as it starts skipped the
	-- client's step 1 ("Place your egg") straight to riding a pet that's gone, with no hint
	task.wait()
	player:SetAttribute("Tutorial", if Config.Tutorial then true else nil)
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

-- The "While you were away" panel's Claim button: the gold earned while away goes
-- into your total. Its rainbow button (Config.AwayBoost, bought: Shop.server's receipt) banks it
-- Multiplier times over through BankAway, true if there was any to bank.
local function bankAway(player, times)
	local profile = profiles[player]
	if not profile or (profile.awayGold or 0) <= 0 then
		return false
	end
	local currency = if Config.Gems then "Gems" else "Gold" -- (the Halloween world's pets earn gems: Config.Gems)
	local banked = profile.awayGold * (if Config.Gems then Config.Gems.Rate else 1) * (tonumber(times) or 1)
	player:SetAttribute(currency, (player:GetAttribute(currency) or 0) + banked)
	profile.awayGold = nil
	player:SetAttribute("AwayGold", nil)
	if (tonumber(times) or 1) > 1 then
		task.spawn(save, player) -- (paid for: kept even if the server goes down)
	end
	return true
end
remote("ClaimAway", function(player)
	bankAway(player, 1)
end)
do
	local bank = Instance.new("BindableFunction")
	bank.Name = "BankAway"
	bank.OnInvoke = bankAway
	bank.Parent = game:GetService("ServerStorage")
end

-- The fuse lesson (client FuseLesson): due once you unlock the Desert (PenLevel.server
-- sets "FuseLesson"), saved till you've fused, then never again.
remote("FuseLessonDone", function(player)
	player:SetAttribute("FuseLesson", nil)
end)

-- Testing: "/fuselesson" runs the fuse lesson again (from the Desert on).
local fuseLessonCommand = Instance.new("TextChatCommand")
fuseLessonCommand.Name = "FuseLesson"
fuseLessonCommand.PrimaryAlias = "/fuselesson"
fuseLessonCommand.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	if player and allowed(player) then
		player:SetAttribute("FuseLesson", true)
	end
end)
fuseLessonCommand.Parent = game:GetService("TextChatService")

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
	profile.awayGold = (profile.awayGold or 0) + math.max(1, math.floor(income(profile) * goldX(player) * Config.AwayRate * Config.AwayCap))
	player:SetAttribute("AwayGold", nil)
	task.wait()
	player:SetAttribute("AwayGold", profile.awayGold)
end)
awayCommand.Parent = game:GetService("TextChatService")

-- Testing: "/reset" wipes you completely (QM, Oct 13): gold, rebirths, finish line trails,
-- World 2's unlock, every world's pen (pets, eggs, pen level, quests) and every barrier,
-- saved at once. The tutorial stays done ("/tutorial" for that): you're left with a fresh
-- Config.DefaultPet to ride. The shop counts are kept (else rejoining hands out every Giant
-- Horse egg and Legendary Pet ever bought again). Gold.server's HardReset does its save.
local resetCommand = Instance.new("TextChatCommand")
resetCommand.Name = "HardReset"
resetCommand.PrimaryAlias = "/reset"
resetCommand.Triggered:Connect(function(source)
	local player = Players:GetPlayerByUserId(source.UserId)
	local old = player and profiles[player]
	if not old or not allowed(player) then
		return
	end
	Telemetry.exclude(player) -- (a test from here on: not in the play data)
	profiles[player] = { eggs = {}, items = {}, ride = Config.DefaultPet, ridden = {}, tutorial = true, boughtHalloweenPets = old.boughtHalloweenPets, boughtPets = old.boughtPets,
		boughtGiantEggs = old.boughtGiantEggs, boughtLoongs = old.boughtLoongs, boughtRoboSharks = old.boughtRoboSharks, usedHatches = old.usedHatches, quests = Quests.load(nil), merged = old.merged, keep = {} }
	for _, other in otherStores do -- (the other worlds' pens, empty)
		task.spawn(pcall, other.SetAsync, other, "u" .. player.UserId, { eggs = {}, items = {}, tutorial = true })
	end
	otherIncome[player] = 0
	for _, name in { "CarriedEgg", "FuseLesson", "Tutorial", "AwayGold" } do
		player:SetAttribute(name, nil)
	end
	player:SetAttribute("PenLevel", 1)
	local hardReset = game:GetService("ServerStorage"):FindFirstChild("HardReset")
	if hardReset then
		hardReset:Fire(player) -- (gold, rebirths, trails, worlds, barriers: Gold.server)
	end
	Quests.publish(player, profiles[player].quests)
	publish(player)
	task.spawn(save, player)
	player:LoadCharacter() -- off any ride, back at your pen
end)
resetCommand.Parent = game:GetService("TextChatService")

-- Rebirth (Gold.server, QM Oct 13: "lose all pets"): every pet and egg gone, in every world,
-- saved before it returns (the trip to World 1 loads that world's pen next); a fresh
-- Config.DefaultPet to ride. Quests, pen level, the tutorial and the shop counts stay.
local rebirthPets = Instance.new("BindableFunction")
rebirthPets.Name = "RebirthPets"
rebirthPets.OnInvoke = function(player)
	local old = profiles[player]
	if not old then
		return false
	end
	profiles[player] = { eggs = {}, items = {}, ride = Config.DefaultPet, ridden = old.ridden or {}, tutorial = true, boughtHalloweenPets = old.boughtHalloweenPets, boughtPets = old.boughtPets,
		boughtGiantEggs = old.boughtGiantEggs, boughtLoongs = old.boughtLoongs, boughtRoboSharks = old.boughtRoboSharks, usedHatches = old.usedHatches, quests = old.quests, v1 = old.v1, questsSeen = old.questsSeen,
		starterPack = old.starterPack, rainbowTrail = old.rainbowTrail, homeEggs = old.homeEggs, merged = old.merged, keep = old.keep, ridesDone = old.ridesDone }
	local writes = {}
	for _, other in otherStores do -- (the other worlds' pens, empty)
		table.insert(writes, task.spawn(function()
			pcall(other.UpdateAsync, other, "u" .. player.UserId, function(data)
				data = if typeof(data) == "table" then data else {}
				data.eggs, data.items, data.ride, data.rideMerged, data.rideFuse, data.rideIncome, data.rideStats, data.rideWorth, data.rideTier = {}, {}, nil, nil, nil, nil, nil, nil, nil
				data.tutorial = true
				return data
			end)
		end))
	end
	otherIncome[player] = 0
	player:SetAttribute("CarriedEgg", nil)
	publish(player)
	save(player)
	for _, thread in writes do -- (wait for the other worlds' writes too)
		while coroutine.status(thread) ~= "dead" do
			task.wait(0.1)
		end
	end
	return true
end
rebirthPets.Parent = game:GetService("ServerStorage")

-- Testing: "/gold <amount>" adds that much gold, 5000, 2.5m, 10b (k, m, b, t); "/gold" alone
-- 10m; a minus takes it away (QM, Oct 13).
local goldCommand = Instance.new("TextChatCommand")
goldCommand.Name = "Gold"
goldCommand.PrimaryAlias = "/gold"
goldCommand.Triggered:Connect(function(source, text)
	local player = Players:GetPlayerByUserId(source.UserId)
	if not player or not allowed(player) then
		return
	end
	local number, unit = text:lower():match("^/gold%s+(%-?[%d%.]+)%s*([kmbt]?)")
	local amount = if number then (tonumber(number) or 0) * (({ k = 1e3, m = 1e6, b = 1e9, t = 1e12 })[unit] or 1) else 1e7
	amount = math.floor(amount)
	player:SetAttribute("Gold", math.max(0, (player:GetAttribute("Gold") or 0) + amount))
	Telemetry.gold(player, "grant", math.abs(amount)) -- (test gold: their gold checkpoints aren't counted)
	devChat:FireClient(player, "/gold: " .. (if amount < 0 then "-" else "+") .. "$" .. Config.short(math.abs(amount)) .. ", now $" .. Config.short(player:GetAttribute("Gold")))
end)
goldCommand.Parent = game:GetService("TextChatService")

Telemetry.incomeOf = function(player) -- (gold a second: the gold checkpoints)
	local profile = profiles[player]
	return if profile then (income(profile) + (otherIncome[player] or 0)) * goldX(player) else 0
end

-- Fired to a player each time their pets pay out, so the client can pop "+N$"
-- over each pet's head.
local paid = Instance.new("RemoteEvent")
paid.Name = "PetIncome"
paid.Parent = ReplicatedStorage

task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in profiles do
			local earned = if player:GetAttribute("Tutorial") then 0 else (income(profile) + (otherIncome[player] or 0)) * goldX(player) -- (nothing till the tutorial's done)
			if earned > 0 and player.Parent and Config.Gems then
				-- (the Halloween world: your pets earn gems, not cash: Config.Gems, QM Oct 15)
				local gems = earned * Config.Gems.Rate
				player:SetAttribute("Gems", (player:GetAttribute("Gems") or 0) + gems)
				paid:FireClient(player, gems) -- (the HUD shows it by the gem counter)
			elseif earned > 0 and player.Parent then
				player:SetAttribute("Gold", (player:GetAttribute("Gold") or 0) + earned)
				Telemetry.gold(player, "earned", earned)
				paid:FireClient(player, earned) -- (the HUD shows it by the gold counter)
			end
		end
	end
end)

-- The tutorial's eggs hatch by themselves once their time is up: the pet takes the
-- egg's spot, and so do everyone's with Auto Hatch (game pass). Every other egg
-- waits to be hatched by hand (HatchEgg, above).
while true do
	task.wait(0.5)
	local now = os.time()
	for player, profile in profiles do
		local changed = false
		for _, item in profile.items do
			-- (in the tutorial, not the starter egg: you hatch that one yourself, QM Oct 11)
			if item.egg and now >= item.hatchAt and ((player:GetAttribute("Tutorial") and profile.ride ~= nil and not item.byHand) or player:GetAttribute("PassAutoHatch")) then
				item.pet, item.egg, item.hatchAt = item.egg, nil, nil
				changed = true
				Telemetry.once(player, "eggHatched")
				if profile.pastStarter then
				end
			end
		end
		if changed then
			publish(player)
		end
	end
end
