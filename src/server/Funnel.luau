-- Analytics V1 (QM, Oct 13: "scrap ALL the funnels, start fresh"): the one server-side
-- recorder for the native funnels (Creator Hub > Analytics > Funnels). Every step goes to
-- AnalyticsService:LogFunnelStepEvent and is counted in our own totals too (StatsStore's
-- "v1-funnels", for /stats). The old funnels (Player Journey, Zones Unlocked, Shop) are no
-- longer logged; their history stays in Creator Hub. When a funnel's definition changes,
-- bump its prefix ([V2] ...), separately from game builds.
--
--   [V1] Tutorial              new World 1 players, first session only:
--       1 New Profile Loaded, 2 Intro Finished, 3 Starter Pet Ready, 4 Crossed Start Line,
--       5 First Animal Awarded, 6 Tutorial Finished
--   [V1] First Session Loop    the same players, first session only (no tutorial rides):
--       1 New Profile Loaded, 2 Tutorial Finished, 3 Ride Started, 4 Reward Received,
--       5 Another Ride Started, 6 Another Reward Received
--   [V1] World <n> Biomes      players whose first visit to this world came after V1, across
--       visits: 1 First Arrival, 2 <biome 1> (crossed the start line), 3.. each next biome's
--       barrier ridden through
--   [V1] Quest Claims          once a session in each world, anyone with a quest still to do:
--       1 Has Unfinished Quests, 2 Has Claimable Quest, 3 Claimed 1, 4 Claimed 2, 5 Claimed 3
--   [V1] Quest Progress        one instance per player, world and quest, from when it's the
--       current quest (never backfilled for quests claimed before): 1 Current, 2 Ready, 3 Claimed
--   [V1] Worlds                one instance per player across all three worlds (QM, Oct 15: do
--       they leave after joining World 3?): 1 Joined World 1, 2 Bought World 2, 3 Arrived World 2,
--       4 Rode In World 2, 5 Bought World 3, 6 Arrived World 3, 7 Rode In World 3,
--       8 Back In World 3 (a later session there). Each world logs its own steps.
--
-- Leaving (QM, Oct 15), on Telemetry.onLeave: custom events "Left Game In World <n>" (the
-- session ended there) or "Travelled From World <n>" (a teleport to another), and "Left World
-- <n> After <time>" (time in that world this visit: Under 1m, 1-5m, 5-15m, 15m+); and in
-- StatsStore's "v1-leaves" for /stats: "w<n>|quit|<time>" and "w<n>|travel|<time>".
--
-- A run starts when the ride crosses the start line (RideSync); a reward is the server's
-- award (Hatchery's givePet). Session funnels use a new id each session; persistent ones
-- use player/world (and quest) ids, and what they've logged is saved with the pen
-- (profile.v1.done) so it's logged once. Roblox fills in skipped steps, so our counts do
-- too. Custom fields: entry build (the first build a player was recorded on), new or
-- returning, the world or quest key. The game's owner is never recorded (but is in Studio,
-- where Roblox logs nothing and StatsStore only prints, for testing).
--
-- Where session funnels stopped, for /stats' "pending" against "ended without": as a player
-- leaves (Telemetry.onLeave), "<funnel>|end<step>" counts the step they'd got to: Quest
-- Claims on leaving the world, Tutorial and First Session Loop only when the session ends
-- (not a trip to the other world).
--
-- Custom events (Analytics > Custom Events), every time: Funnel.event(player, name).
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local StatsStore = require(script.Parent.StatsStore)
local Telemetry = require(script.Parent.Telemetry)

local Funnel = {}

local WORLD = Config.World
local BUILD = game.PlaceVersion
local TUTORIAL = "[V1] Tutorial"
local LOOP = "[V1] First Session Loop"
local BIOMES = "[V1] World " .. WORLD .. " Biomes"
local CLAIMS = "[V1] Quest Claims"
local PROGRESS = "[V1] Quest Progress"
local WORLDS = "[V1] Worlds"
Funnel.STEPS = { -- (by funnel: /stats lists them)
	[TUTORIAL] = { "New Profile Loaded", "Intro Finished", "Starter Pet Ready", "Crossed Start Line", "First Animal Awarded", "Tutorial Finished" },
	[LOOP] = { "New Profile Loaded", "Tutorial Finished", "Ride Started", "Reward Received", "Another Ride Started", "Another Reward Received" },
	[CLAIMS] = { "Has Unfinished Quests", "Has Claimable Quest", "Claimed 1", "Claimed 2", "Claimed 3" },
	[PROGRESS] = { "Current", "Ready", "Claimed" },
	[WORLDS] = { "Joined World 1", "Bought World 2", "Arrived World 2", "Rode In World 2", "Bought World 3", "Arrived World 3", "Rode In World 3", "Back In World 3" },
}
local ARRIVED = { [1] = 1, [2] = 3, [3] = 6 } -- [world] = its Worlds step
local RODE = { [2] = 4, [3] = 7 }
local BOUGHT = { [2] = 2, [3] = 5 }
local BIOME_NAMES = Config.BiomeNames[WORLD]
Funnel.STEPS[BIOMES] = { "First Arrival" }
for _, name in BIOME_NAMES do
	table.insert(Funnel.STEPS[BIOMES], name)
end
Funnel.BIOMES = BIOMES

local state = {} -- [player] = this session's: see Funnel.start

local function isOwner(player)
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local success, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return success and group.Owner ~= nil and player.UserId == group.Owner.Id
end

-- Logs funnel `name`'s step `step` for instance `id` (memo: how it's remembered, saved if
-- `persist`), and every step before it not logged yet, as Roblox fills them in.
local function log(player, name, id, memo, step, key, persist)
	local s = state[player]
	if not s or s.excluded then
		return
	end
	local was = s.logged[memo] or 0
	if was >= step then
		return
	end
	s.logged[memo] = step
	if persist then
		s.profile.v1.done[memo] = step
	end
	local fields = {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "build " .. tostring(s.profile.v1.build),
		[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = if s.new then "new" else "returning",
		[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = key,
	}
	pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, name, id, step, Funnel.STEPS[name][step], fields)
	local counts = {}
	for i = was + 1, step do
		counts[name .. "|" .. i] = 1
		if name == PROGRESS then
			counts[name .. "|" .. key .. "|" .. i] = 1 -- (each quest's own: /stats names them)
		end
	end
	StatsStore.add("v1-funnels", counts)
end

-- Hatchery: the player's pen in this world has loaded (isNew: no save here before).
function Funnel.start(player, profile, isNew)
	local v1 = typeof(profile.v1) == "table" and profile.v1 or {}
	v1.build = tonumber(v1.build) or BUILD
	v1.done = typeof(v1.done) == "table" and v1.done or {}
	if isNew then
		v1.biomes = true -- (first arrival in this world after V1: in its Biomes funnel for good)
	end
	profile.v1 = v1
	local s = {
		profile = profile,
		new = isNew,
		session = HttpService:GenerateGUID(false),
		logged = table.clone(v1.done),
		firstSession = isNew and WORLD == 1, -- (Tutorial and First Session Loop)
		rides = 0,
	}
	s.excluded = not RunService:IsStudio() and isOwner(player) -- (nothing's logged for the owner; in Studio, where Roblox logs nothing, StatsStore prints the steps for testing)
	state[player] = s
	if s.firstSession then
		log(player, TUTORIAL, s.session, "tut", 1, "w" .. WORLD)
		log(player, LOOP, s.session, "loop", 1, "w" .. WORLD)
	end
	if v1.biomes then
		log(player, BIOMES, player.UserId .. ":w" .. WORLD, "b", 1, "w" .. WORLD, true)
	end
	s.arrivedAt = os.clock()
	log(player, WORLDS, tostring(player.UserId), "worlds", ARRIVED[WORLD], "w" .. WORLD, true)
	if WORLD == 3 and not isNew then
		log(player, WORLDS, tostring(player.UserId), "worldsBack", 8, "w3", true) -- (a later session in World 3)
	end
end

-- Gold.server: the player bought world `world`.
function Funnel.boughtWorld(player, world)
	if BOUGHT[world] then
		log(player, WORLDS, tostring(player.UserId), "worlds", BOUGHT[world], "w" .. world, true)
	end
end

-- (client) the intro's over.
function Funnel.intro(player)
	local s = state[player]
	if s and s.firstSession then
		log(player, TUTORIAL, s.session, "tut", 2, "w" .. WORLD)
	end
end

-- Hatchery: the starter pet is out of its egg (or /skip-ped to).
function Funnel.starterReady(player)
	local s = state[player]
	if s and s.firstSession then
		log(player, TUTORIAL, s.session, "tut", 3, "w" .. WORLD)
	end
end

-- A ride crossed the start line.
local function rideStarted(player)
	local s = state[player]
	if not s then
		return
	end
	if s.profile.v1.biomes then
		log(player, BIOMES, player.UserId .. ":w" .. WORLD, "b", 2, "w" .. WORLD, true)
	end
	if RODE[WORLD] then
		log(player, WORLDS, tostring(player.UserId), "worldsRode", RODE[WORLD], "w" .. WORLD, true)
	end
	if not s.firstSession then
		return
	end
	if player:GetAttribute("Tutorial") then
		log(player, TUTORIAL, s.session, "tut", 4, "w" .. WORLD)
	elseif s.tutorialDone then
		s.rides += 1
		local at = s.logged.loop or 0
		if at == 2 then
			log(player, LOOP, s.session, "loop", 3, "w" .. WORLD)
		elseif at == 4 then
			log(player, LOOP, s.session, "loop", 5, "w" .. WORLD)
		end
	end
end

-- Hatchery: the server gave the player the animal they rode home (or over the finish line).
function Funnel.rewarded(player)
	local s = state[player]
	if not s or not s.firstSession then
		return
	end
	if player:GetAttribute("Tutorial") then
		log(player, TUTORIAL, s.session, "tut", 5, "w" .. WORLD)
	elseif s.tutorialDone then
		local at = s.logged.loop or 0
		if at == 3 then
			log(player, LOOP, s.session, "loop", 4, "w" .. WORLD)
		elseif at == 5 then
			log(player, LOOP, s.session, "loop", 6, "w" .. WORLD)
		end
	end
end

-- Hatchery: the tutorial's over and the player has control again.
function Funnel.tutorialDone(player)
	local s = state[player]
	if s and s.firstSession and not s.tutorialDone then
		s.tutorialDone = true
		log(player, TUTORIAL, s.session, "tut", 6, "w" .. WORLD)
		log(player, LOOP, s.session, "loop", 2, "w" .. WORLD)
	end
end

-- Gold.server: the player rode through biome `to`'s barrier, the last they'd broken `from`
-- (1: none yet).
function Funnel.reached(player, from, to)
	local s = state[player]
	if not s or not s.profile.v1.biomes then
		return
	end
	local last = math.min(to, #BIOME_NAMES)
	if last >= 2 then
		log(player, BIOMES, player.UserId .. ":w" .. WORLD, "b", last + 1, "w" .. WORLD, true)
	end
end

-- Quests.publish: the quests up now, { { i, have, need } }, i = line * 100 + place.
function Funnel.quests(player, list)
	local s = state[player]
	if not s then
		return
	end
	s.quests = list
	if #list == 0 then
		return -- (every quest done: not in Quest Claims)
	end
	local claims = s.session .. ":w" .. WORLD
	log(player, CLAIMS, claims, "claims", 1, "w" .. WORLD)
	for _, q in list do
		local key = "w" .. WORLD .. ":q" .. q.i
		log(player, PROGRESS, player.UserId .. ":" .. key, "q" .. q.i, 1, key, true)
		if q.have >= q.need then
			log(player, CLAIMS, claims, "claims", 2, "w" .. WORLD)
			log(player, PROGRESS, player.UserId .. ":" .. key, "q" .. q.i, 2, key, true)
		end
	end
end

-- Hatchery: quest i claimed.
function Funnel.claimed(player, i)
	local s = state[player]
	if not s then
		return
	end
	local key = "w" .. WORLD .. ":q" .. i
	if (s.logged["q" .. i] or 0) >= 1 then -- (never backfilled: only quests seen as current)
		log(player, PROGRESS, player.UserId .. ":" .. key, "q" .. i, 3, key, true)
	end
	if (s.logged.claims or 0) >= 1 then
		s.claimed = (s.claimed or 0) + 1
		log(player, CLAIMS, s.session .. ":w" .. WORLD, "claims", math.min(2 + s.claimed, 5), "w" .. WORLD)
	end
end

function Funnel.event(player, name)
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, name)
end

-- The client's reports: only the intro's end now ("tutorial", "intro"). Anything else
-- (the old tutorial and shop steps) is ignored.
local funnelStep = Instance.new("RemoteEvent")
funnelStep.Name = "FunnelStep"
funnelStep.OnServerEvent:Connect(function(player, kind, name)
	if kind == "tutorial" and name == "intro" then
		Funnel.intro(player)
	end
end)
funnelStep.Parent = ReplicatedStorage

task.spawn(function() -- (Riders makes these: don't hold up whoever requires this)
	ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _, riderCFrame)
		local s = state[player]
		if not s or type(kind) ~= "string" then
			return
		end
		-- (a ride starts when the rider goes from this side of the start line to the far side)
		local z = if typeof(riderCFrame) == "CFrame" then riderCFrame.Position.Z else nil
		if kind ~= "" and z and z < 0 and (s.lastZ == nil or s.lastZ >= 0) then
			rideStarted(player)
		end
		s.lastZ = if kind == "" then nil else z
	end)
end)
Telemetry.onLeave(function(player, transferring)
	local s = state[player]
	state[player] = nil
	if not s or s.excluded then
		return
	end
	-- How long they were in this world this visit, and whether they left the game or travelled on.
	local minutes = (os.clock() - (s.arrivedAt or os.clock())) / 60
	local spent = if minutes < 1 then "Under 1m" elseif minutes < 5 then "1-5m" elseif minutes < 15 then "5-15m" else "15m+"
	Funnel.event(player, (if transferring then "Travelled From World " else "Left Game In World ") .. WORLD)
	Funnel.event(player, "Left World " .. WORLD .. " After " .. spent)
	StatsStore.add("v1-leaves", { ["w" .. WORLD .. "|" .. (if transferring then "travel" else "quit") .. "|" .. spent] = 1 })
	local ends = {}
	if s.logged.claims then
		ends[CLAIMS .. "|end" .. s.logged.claims] = 1
	end
	if s.firstSession and not transferring then
		ends[TUTORIAL .. "|end" .. (s.logged.tut or 1)] = 1
		ends[LOOP .. "|end" .. (s.logged.loop or 1)] = 1
	end
	if next(ends) then
		StatsStore.add("v1-funnels", ends)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	task.delay(5, function() -- (Telemetry's goes first; this only tidies up)
		if not player.Parent then
			state[player] = nil
		end
	end)
end)

return Funnel
