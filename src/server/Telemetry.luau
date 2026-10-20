-- Analytics V1, part 2 (QM, Oct 13): our own play data for /stats and the dashboard. Every
-- server in both worlds adds into the store they share (StatsStore.addShared) under today's
-- key ("v1d-YYYY-MM-DD") and this build's ("v1b-w<world>-<build>"), so a session is counted
-- once wherever it ends; World 2's progress of new World 1 players goes in "v1-worlds".
-- Sessions going on right now: each server's count in the MemoryStore map "V1Active",
-- every HEARTBEAT seconds, expiring if a server stops (Telemetry.active). Totals and bounded
-- histograms only: no player ids.
--
-- Fields, each under a segment: "all", "new" or "ret" (a player's first session, or not),
-- and the device ("pc", "phone", "tablet", "console", from the client):
--   <seg>|c:<name>             a count
--   <seg>|h:<name>:<bucket>    a histogram (bucket b holds values from 1.2^(b-1) to 1.2^b;
--                              0 holds under 1), with <seg>|s:<name> its sum and
--                              <seg>|n:<name> its sample count
--   max:updated                when it was last added to (os.time)
-- Histograms merge across servers by adding buckets, so percentiles are computed from the
-- merged counts (never by averaging servers' medians).
--
-- A session is one visit to the game, across both worlds (QM, Oct 13): a trip to the other
-- world carries its id and online time over in the teleport data and isn't a quit; each
-- world's part is a place visit (placeVisit, h:placeVisit). Time is online time only (the
-- teleport's loading isn't counted). As it goes, the session's also written to the V1Transfers
-- store; the world it arrives in deletes that, confirming the trip. If it's still there
-- CONFIRM seconds later (they never arrived), the world they left closes the session there;
-- if that server's shut down first, the next world they join afresh closes it. One that
-- arrives after it was closed starts a new session. A teleport that fails carries on here.
--
-- What's recorded:
--   startup   join, profileReady, clientReady, loadFail, eggPlaced, eggHatched, mounted,
--             lassoChance (the prompt first shows on a ride), lassoThrow, lassoLand,
--             returnStart (the boss appeared: you turn for home), questsOpened
--   sessions  start, end, h:session (seconds), quit<1..6> (Stats' bands)
--   first     fsEntrant, fsAlive<1/5/10/15/20> (still playing at that many minutes), of
--             completed first sessions only, so every cohort's old enough
--   runs      tut|post: run, success, crash, retryEligible and retry (a ride within 60 s
--             of getting control back after one); h:successes per completed session
--   exit      exit:<startup|tutorial|outbound|return|reward|base> as they left
--   places    placeVisit<w>, h:placeVisit<w> (seconds), w<w>reach<i>: place visits to world w
--             whose player had (ever) reached its biome i
--   pacing    h:toFirstRide, h:toFirstReward (seconds into the first session),
--             h:toNextRide (from the tutorial's end), h:w<w>biome<i> (online seconds in world
--             w to first reach biome i: Gold.server's BiomeUnlocked)
--   replay    replayEligible (tutorial finishers), replay (rode again within 90 s)
--   reach     fv<i>: first sessions that reached World 1's biome i
--   gold      at 1, 5 and 10 minutes into a first session: g<t>|n and histograms
--             g<t>:wallet, g<t>:earned, g<t>:spent, g<t>:income (a second); a player who
--             bought gold or has x2 Gold is counted under gp<t> instead; one given test
--             gold (/gold) isn't counted
--
-- Not counted: Studio sessions saved (StatsStore keeps Studio's in memory), the game's
-- owner, and anyone who's used /reset this session.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StatsStore = require(script.Parent.StatsStore)
local SimpleStats = require(script.Parent.SimpleStats)
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local okTransfers, transfers = pcall(DataStoreService.GetDataStore, DataStoreService, "V1Transfers")
if not okTransfers or RunService:IsStudio() then
	transfers = nil
end

local Telemetry = {}

local BUILD = game.PlaceVersion
local BANDS = { 1, 5, 10, 20, 30, math.huge } -- minutes (Stats.server's quit bands)
local SURVIVAL = { 1, 5, 10, 15, 20 } -- minutes
local GOLD_AT = { 1, 5, 10 } -- minutes
local RETRY, REPLAY = 60, 90 -- seconds
local WORLD = Config.World
local HEARTBEAT = 30 -- seconds between this server's active-session counts (they expire after 3)
local REWARD_PHASE = 5 -- seconds the new animal's cutscene counts as "reward"
local CONFIRM = 120 -- seconds for a trip to the other world to arrive before it's closed here
local LOG_BASE = math.log(1.2)
Telemetry.BUILD, Telemetry.BANDS, Telemetry.SURVIVAL, Telemetry.GOLD_AT = BUILD, BANDS, SURVIVAL, GOLD_AT

-- Income a second right now (Hatchery's, set at its start).
Telemetry.incomeOf = function()
	return 0
end

local sessions = {} -- [player] = this session's state

local function isOwner(player)
	if RunService:IsStudio() then
		return false
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local success, group = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return success and group.Owner ~= nil and player.UserId == group.Owner.Id
end

function Telemetry.bucket(value)
	return if value < 1 then 0 else math.floor(math.log(value) / LOG_BASE) + 1
end
-- A bucket's middle (for percentiles).
function Telemetry.bucketValue(b)
	return if b == 0 then 0.5 else 1.2 ^ (b - 0.5)
end

local function segments(s)
	local list = { "all", if s.new then "new" else "ret" }
	if s.device then
		table.insert(list, s.device)
	end
	return list
end

-- Adds fields (name = n, under each of the session's segments) to today's and this build's totals.
local function add(s, counts, samples)
	if not s or s.excluded then
		return
	end
	local fields = { ["max:updated"] = os.time() }
	for _, seg in segments(s) do
		for name, n in counts or {} do
			fields[seg .. "|c:" .. name] = (fields[seg .. "|c:" .. name] or 0) + n
		end
		for name, value in samples or {} do
			value = math.max(0, value)
			local h = seg .. "|h:" .. name .. ":" .. Telemetry.bucket(value)
			fields[h] = (fields[h] or 0) + 1
			fields[seg .. "|s:" .. name] = (fields[seg .. "|s:" .. name] or 0) + value
			fields[seg .. "|n:" .. name] = (fields[seg .. "|n:" .. name] or 0) + 1
		end
	end
	pcall(function()
		StatsStore.addShared("v1d-" .. os.date("!%Y-%m-%d"), fields)
		StatsStore.addShared("v1b-w" .. WORLD .. "-" .. BUILD, fields)
	end)
end
local function count(player, name, n)
	add(sessions[player], { [name] = n or 1 })
end
Telemetry.count = count
-- Counted once a session (the first egg placed, the first hatched).
function Telemetry.once(player, name)
	local s = sessions[player]
	if s and not (s.onceDone and s.onceDone[name]) then
		s.onceDone = s.onceDone or {}
		s.onceDone[name] = true
		add(s, { [name] = 1 })
	end
end

-- A Robux purchase (Shop.server's products, Passes' game passes): /stats' "bought" rate.
function Telemetry.purchase(player, robux, sku)
	local spent = robux
	if type(spent) ~= "number" then -- (a pass: its price)
		for _, pass in Config.Passes do
			if sku == "pass:" .. pass.Id then
				spent = pass.Price
			end
		end
	end
	local arm = player and player:GetAttribute("ABRideEgg") -- (the ride egg A/B's Robux: Hatchery, /stats ab)
	if arm then
		StatsStore.addShared("ab-rideegg-" .. arm, { robux = tonumber(spent) or 0, buys = 1 })
	end
	if player and sessions[player] then
		SimpleStats.purchase(not sessions[player].excluded and sessions[player].simple or nil, sku, spent)
		Telemetry.once(player, "bought")
		count(player, "purchases")
		if type(robux) == "number" and robux > 0 then
			count(player, "robux", robux)
		end
	end
end

-- Monetization views and successful checkout prompts, once per logical session.
function Telemetry.monoView(player, surface)
 local s = sessions[player]
 if s and not s.excluded then SimpleStats.view(s.simple, surface) end
end
function Telemetry.monoCancel(player, sku) -- (a checkout closed without buying: SimpleStats.cancel)
 local s = sessions[player]
 if s and not s.excluded then SimpleStats.cancel(s.simple, sku) end
end
function Telemetry.monoPrompt(player, sku, surface)
 local s = sessions[player]
 if s and not s.excluded then SimpleStats.prompt(s.simple, sku, surface) end
end

-- Online seconds this session, both worlds.
local function elapsed(s)
	return s.onlineBase + os.time() - s.arrived
end

local function phaseOf(s, player)
	if not s.ready then
		return "startup"
	elseif s.phase == "reward" and os.clock() - s.phaseAt > REWARD_PHASE then
		s.phase = "base"
	end
	if s.phase == "base" and player and player:GetAttribute("Tutorial") then
		return "tutorial"
	end
	return s.phase
end

local close -- (below)
local rideFacts -- (below)

-- A session from its snapshot (Telemetry.leaving's), for closing a trip that never arrived.
local function fromSnapshot(snap)
	return {
		id = snap.id, onlineBase = tonumber(snap.online) or 0, arrived = os.time(), new = snap.new == true,
		firstSession = snap.first == true, reached = tonumber(snap.reached), successes = tonumber(snap.successes) or 0,
		excluded = snap.excluded == true, device = snap.device, ready = snap.ready == true,
		phase = "transfer", phaseAt = os.clock(), simple = snap.simple,
	}
end

-- A player arrived in this world (from Players.PlayerAdded): a new session, or the one they
-- brought over from the other world. (carried: Studio's tests pass a snapshot in.)
local function join(player, carried)
	if carried == nil then
		pcall(function()
			local data = player:GetJoinData().TeleportData
			carried = typeof(data) == "table" and typeof(data.v1) == "table" and data.v1 or nil
		end)
	end
	local s = {
		id = carried and type(carried.id) == "string" and carried.id or HttpService:GenerateGUID(false),
		onlineBase = carried and tonumber(carried.online) or 0,
		arrived = os.time(),
		new = carried ~= nil and carried.new == true,
		firstSession = carried ~= nil and carried.first == true,
		tutorialDone = carried ~= nil and carried.tutorialDone == true,
		reached = carried and tonumber(carried.reached) or nil,
		successes = carried and tonumber(carried.successes) or 0,
		postRides = carried and tonumber(carried.postRides) or nil, lastRide = carried and carried.lastRide or nil,
		runs = carried and tonumber(carried.runs) or 0,
		phase = "base",
		phaseAt = os.clock(),
		gold = { earned = 0, purchased = 0, grant = 0 },
		goldAt = {},
		carried = carried ~= nil,
	}
	if carried then -- (the rest of what the other world had: timers, gold, what's counted once)
		for kind in s.gold do
			s.gold[kind] = tonumber(typeof(carried.gold) == "table" and carried.gold[kind]) or 0
		end
		for _, t in typeof(carried.goldAt) == "table" and carried.goldAt or {} do
			s.goldAt[tonumber(t) or 0] = true
		end
		s.wallet0 = tonumber(carried.wallet0)
		s.tutorialDoneAt = tonumber(carried.tutorialDoneAt)
		s.firstRide, s.firstReward, s.nextRide = carried.firstRide == true, carried.firstReward == true, carried.nextRide == true
		s.clientReady = carried.clientReady == true
		s.device = type(carried.device) == "string" and carried.device or nil
		s.onceDone = {}
		for _, name in typeof(carried.once) == "table" and carried.once or {} do
			s.onceDone[tostring(name)] = true
		end
	end
	s.excluded = (carried ~= nil and carried.excluded == true) or isOwner(player)
	s.simple = if s.excluded then nil else SimpleStats.begin(carried and carried.simple)
	sessions[player] = s
	if not transfers then
		if not carried then
			add(s, { join = 1 })
		end
		return
	end
	task.spawn(function()
		-- Arrived: the world they left needn't close it. (Joining afresh: a trip that never
		-- arrived, from a server that shut down before closing it, is closed now.)
		local got, old = pcall(transfers.RemoveAsync, transfers, "u" .. player.UserId)
		old = got and typeof(old) == "table" and old or nil
		if carried and not (old and old.id == s.id) then
			-- (too late: the world they left closed it, so this is a new session)
			s.id, s.onlineBase, s.arrived, s.carried = HttpService:GenerateGUID(false), 0, os.time(), false
			s.successes, s.runs = 0, 0
			s.simple = if s.excluded then nil else SimpleStats.begin(nil)
			add(s, if s.ready then { join = 1, start = 1, profileReady = 1 } else { join = 1 }) -- (profileReady's still to come: it adds them)
		elseif not carried then
			if old and old.id then
				close(fromSnapshot(old), nil)
			end
			add(s, { join = 1 })
		end
	end)
end

-- Hatchery: the player's pen has loaded (isNew: a brand new player, World 1's first visit).
function Telemetry.profileReady(player, isNew)
	local s = sessions[player]
	if not s then
		return
	end
	if not s.carried then
		s.new, s.firstSession = isNew, isNew
		add(s, { start = 1, profileReady = 1 })
	end
	s.ready = true
	SimpleStats.reach(s.simple, WORLD, player:GetAttribute("GatesBroken") or 1)
	s.wallet0 = s.wallet0 or player:GetAttribute("Gold") or 0
	if isNew and Config.World == 1 then
		player:SetAttribute("V1New", true) -- (Gold.server saves it: World 2's progress of new players)
		pcall(StatsStore.addShared, "v1-worlds", { w1new = 1 })
	end
end

function Telemetry.loadFailed(player)
	count(player, "loadFail")
end

-- Hatchery: the server gave the player the animal they rode home.
function Telemetry.reward(player)
	local s = sessions[player]
	if not s then
		return
	end
	local tut = player:GetAttribute("Tutorial") and "tut" or "post"
	s.successes += 1
	s.rideAnimal = true
	s.phase, s.phaseAt = "reward", os.clock()
	local samples = {}
	if s.firstSession and not s.firstReward then
		s.firstReward = true
		samples.toFirstReward = elapsed(s)
	end
	add(s, { [tut .. "Success"] = 1 }, samples)
end

function Telemetry.tutorialDone(player)
	local s = sessions[player]
	if s and not s.tutorialDone then
		s.tutorialDone, s.tutorialDoneAt = true, elapsed(s)
		s.replayDue = os.clock() + REPLAY
		add(s, { replayEligible = 1 })
	end
end

-- Gold the player got ("earned": pets and rides, "purchased": Robux, "grant": /gold).
function Telemetry.gold(player, kind, n)
	local s = sessions[player]
	if s and s.gold[kind] then
		s.gold[kind] += n
	end
end

-- "/reset": nothing more from them this session.
function Telemetry.exclude(player)
	local s = sessions[player]
	if s then
		s.excluded = true
	end
end

local function snapshot(s)
	local goldAt, once = {}, {}
	for t in s.goldAt do
		table.insert(goldAt, t)
	end
	for name in s.onceDone or {} do
		table.insert(once, name)
	end
	return { id = s.id, online = elapsed(s), new = s.new, first = s.firstSession, tutorialDone = s.tutorialDone, reached = s.reached,
		successes = s.successes, runs = s.runs, excluded = s.excluded, device = s.device, ready = s.ready,
		gold = s.gold, goldAt = goldAt, wallet0 = s.wallet0, tutorialDoneAt = s.tutorialDoneAt, firstRide = s.firstRide,
		firstReward = s.firstReward, nextRide = s.nextRide, clientReady = s.clientReady, once = once,
		postRides = s.postRides, lastRide = s.lastRide, simple = s.simple }
end

-- Gold.server, as it teleports them to the other world: what carries the session over
-- (into the teleport data). Telemetry.stayed(player) if the teleport fails.
function Telemetry.leaving(player)
	local s = sessions[player]
	if not s then
		return nil
	end
	s.transferring = true
	return snapshot(s)
end
function Telemetry.stayed(player)
	local s = sessions[player]
	if s then
		s.transferring = nil
	end
end

-- A ride crossed the start line.
local function rideStarted(player, s)
	local tut = player:GetAttribute("Tutorial") and "tut" or "post"
	s.runs += 1
	s.rideFar, s.rideGates = 0, player:GetAttribute("GatesBroken") or 1 -- (the quit snapshot's: how far this ride got)
	s.phase, s.phaseAt = "outbound", os.clock()
	s.lassoChance = false
	local counts, samples = { [tut .. "Run"] = 1 }, {}
	if s.controlAt then -- (control was back after a ride: within RETRY, a retry)
		counts[s.retryOpen .. "RetryEligible"] = 1
		if os.clock() - s.controlAt <= RETRY then
			counts[s.retryOpen .. "Retry"] = 1
		end
		s.controlAt, s.retryOpen = nil, nil
	end
	if s.firstSession and not s.firstRide then
		s.firstRide = true
		samples.toFirstRide = elapsed(s)
	end
	if s.tutorialDoneAt and tut == "post" and not s.nextRide then
		s.nextRide = true
		samples.toNextRide = elapsed(s) - s.tutorialDoneAt
		if s.replayDue then
			if os.clock() <= s.replayDue then
				counts.replay = 1
			end
			s.replayDue = nil
		end
	end
	add(s, counts, samples)
end

-- The session's over (not a trip to the other world). (s: a session from a trip that never
-- arrived, closed by the world it left: Telemetry's transfer check.)
-- How far a ride got (s.rideFar, s.rideGates: since it crossed the start line): how far into
-- the furthest biome they've opened, the one whose barrier's next ("<50", "<80", "<95",
-- "95+" %, or "gate" when it broke a barrier), and against their best ride before it
-- this session ("first", "best": further, "near": at least 90% of it, "short").
function rideFacts(player, s)
	local gates = player:GetAttribute("GatesBroken") or 1
	local into
	if gates > (s.rideGates or gates) then
		into = "gate"
	else
		local edge = 0
		for i = 1, gates - 1 do
			edge -= Config.Biomes[i].Length
		end
		local biome = Config.Biomes[gates]
		local f = if biome then math.clamp((edge - s.rideFar) / biome.Length, 0, 1) else 0
		into = if f < 0.5 then "<50" elseif f < 0.8 then "<80" elseif f < 0.95 then "<95" else "95+"
	end
	local vs = if not s.bestFar or s.bestFar >= 0 then "first"
		elseif s.rideFar < s.bestFar then "best"
		elseif s.rideFar <= s.bestFar * 0.9 then "near"
		else "short"
	return into, vs
end

-- What the player was doing as they left (QM, Oct 14: "so we stop guessing"), by when they
-- left (Q: 1 under a minute, 2 at 1-5, 3 at 5-10, 4 at 10-20, 5 later), all as
-- "q<Q>:<what>" counts: rides since the tutorial (0, 1, 2, 3-5, 6+), how the last one ended
-- (animal, crash, empty, riding now, none), seconds since it ended (<15, <60, 60+), an egg
-- in the pen (ready, hatching, none), a quest to claim (yes, no), the furthest barrier
-- (w<world>reach<i>), and whether they had the gold for World 2 (World 1, not owned yet).
local QUIT_AT = { 1, 5, 10, 20, math.huge }
local function quitSnapshot(s, player, length, counts)
	local q = 5
	for i, m in QUIT_AT do
		if length < m * 60 then
			q = i
			break
		end
	end
	local function put(what)
		counts["q" .. q .. ":" .. what] = 1
	end
	put("n")
	local rides = s.postRides or 0
	put("rides" .. (if rides >= 6 then "6+" elseif rides >= 3 then "3-5" else tostring(rides)))
	put("last:" .. (if s.riding then "riding" else s.lastRide or "none"))
	-- (that ride, or the one they're on: how far it got, QM, Oct 14: "WHY they decided to leave")
	local far, vs = s.lastRideFar, s.lastRideVs
	if s.riding and s.rideFar then
		far, vs = rideFacts(player, s)
	end
	if far then
		put("far:" .. far)
		put("vs:" .. vs)
		local since = s.ridesSinceGate or 0
		if s.riding and s.rideFar and far ~= "gate" then
			since += 1
		elseif s.riding and far == "gate" then
			since = 0
		end
		put("stuck:" .. (if since == 0 then "0" elseif since <= 2 then "1-2" elseif since <= 5 then "3-5" else "6+"))
	end
	if s.lastEnd and not s.riding then
		local idle = os.clock() - s.lastEnd
		put("idle:" .. (if idle < 15 then "<15" elseif idle < 60 then "<60" else "60+"))
	end
	put("w" .. WORLD .. "reach" .. tostring(player:GetAttribute("GatesBroken") or 1)) -- (the world they left from)
	local egg = "none"
	pcall(function()
		local items = game:GetService("HttpService"):JSONDecode(s.penContents or "{}") -- (kept every few seconds: the pen's emptied as they go)
		for _, item in items do
			if item.egg then
				egg = if (tonumber(item.hatchAt) or 0) <= os.time() then "ready" elseif egg ~= "ready" then "hatching" else egg
			end
		end
	end)
	put("egg:" .. egg)
	local claim = "no"
	pcall(function()
		for _, quest in game:GetService("HttpService"):JSONDecode(player:GetAttribute("Quests") or "[]") do
			if (tonumber(quest.have) or 0) >= (tonumber(quest.need) or 1) then
				claim = "yes"
			end
		end
	end)
	put("claim:" .. claim)
	if WORLD == 1 and not player:GetAttribute("OwnsWorld2") then
		local can = (player:GetAttribute("Gold") or 0) >= (Config.WorldPrices[2] or math.huge)
		put("w2gold:" .. (if can then "yes" else "no"))
		if can and s.affordAt then -- (how long they'd had it, and whether they were at base since, where the bar's prompt is: QM, Oct 14)
			local held = os.clock() - s.affordAt
			put("w2for:" .. (if held < 60 then "<1m" elseif held < 300 then "1-5m" else "5m+"))
			put("w2seen:" .. (if s.sawW2 then "yes" else "no"))
		end
	end
end

function close(s, player)
	local length = elapsed(s)
	if not s.excluded then
		if player then SimpleStats.reach(s.simple, WORLD, player:GetAttribute("GatesBroken") or 1) end
		SimpleStats.finish(s.simple, length, s.firstSession, s.ready)
	end
	local counts = { ["end"] = 1, ["exit:" .. phaseOf(s, player)] = 1 }
	if player then
		pcall(quitSnapshot, s, player, length, counts)
	end
	for i, band in BANDS do
		if length < band * 60 then
			counts["quit" .. i] = 1
			break
		end
	end
	if s.controlAt then
		counts[s.retryOpen .. "RetryEligible"] = 1 -- (left before riding again: a failed retry)
	end
	if s.firstSession then
		counts.fsEntrant = 1
		for _, t in SURVIVAL do
			if length >= t * 60 then
				counts["fsAlive" .. t] = 1
			end
		end
		for i = 1, math.min(s.reached or 1, #Config.Biomes) do
			counts["fv" .. i] = 1
		end
	end
	add(s, counts, { session = length, successes = s.successes })
end

-- fn(player, transferring) as each player leaves this world (Funnel: where its session
-- funnels stopped).
local leaveHandlers = {}
function Telemetry.onLeave(fn)
	table.insert(leaveHandlers, fn)
end

local function leave(player)
	local s = sessions[player]
	sessions[player] = nil
	if not s then
		return
	end
	for _, fn in leaveHandlers do
		task.spawn(pcall, fn, player, s.transferring == true)
	end
	local visit = { ["placeVisit" .. WORLD] = 1 } -- (this world's part)
	for i = 1, math.min(player:GetAttribute("GatesBroken") or 1, #Config.Biomes) do
		visit["w" .. WORLD .. "reach" .. i] = 1
	end
	add(s, visit, { ["placeVisit" .. WORLD] = os.time() - s.arrived })
	if not s.transferring then
		close(s, player)
		return
	end
	-- A trip to the other world: written down, and closed here if it never arrives.
	local snap = snapshot(s)
	snap.phase = phaseOf(s, player)
	if not transfers then
		return
	end
	local key, store = "u" .. player.UserId, transfers
	pcall(store.SetAsync, store, key, snap)
	task.delay(CONFIRM, function()
		local got, still = pcall(store.GetAsync, store, key)
		if got and typeof(still) == "table" and still.id == snap.id then
			local removed, old = pcall(store.RemoveAsync, store, key)
			if removed and typeof(old) == "table" and old.id == snap.id then -- (not just arrived)
				close(fromSnapshot(snap), nil) -- (online time to when it left)
			end
		end
	end)
end

-- Every few seconds: the gold checkpoints, the replay window and the reward phase.
task.spawn(function()
	while true do
		task.wait(2)
		for player, s in sessions do
			if s.ready and elapsed(s) >= 10 * 60 and not (s.onceDone and s.onceDone.communityPrompt) then
				player:SetAttribute("CommunityPromptDue", true)
			end
			if s.firstSession and s.ready then
				for _, t in GOLD_AT do
					if not s.goldAt[t] and elapsed(s) >= t * 60 then
						s.goldAt[t] = true
						if s.gold.grant == 0 then
							local wallet = player:GetAttribute("Gold") or 0
							local g = s.gold
							local spent = math.max(0, (s.wallet0 or 0) + g.earned + g.purchased - wallet)
							local paid = g.purchased > 0 or player:GetAttribute("PassDoubleGold") == true
							local key = (if paid then "gp" else "g") .. t
							local ok, income = pcall(Telemetry.incomeOf, player)
							add(s, { [key] = 1 }, {
								[key .. ":wallet"] = wallet,
								[key .. ":earned"] = g.earned,
								[key .. ":spent"] = spent,
								[key .. ":income"] = if ok and type(income) == "number" then income else 0,
							})
						end
					end
				end
			end
			if s.replayDue and os.clock() > s.replayDue then
				s.replayDue = nil -- (no voluntary ride within the window: counted as eligible only)
			end
			if WORLD == 1 then -- (first-visit reach: World 1's biomes)
				s.reached = math.max(s.reached or 1, player:GetAttribute("GatesBroken") or 1)
			end
		end
	end
end)

-- The client's reports: "ready" (with its device), "lassoChance", "questsOpened". Each
-- name counted at most once a ride or so (RATE seconds apart).
local RATE = 5
local CLIENT = { ready = true, lassoChance = true, questsOpened = true, shopOpened = true, monoView = true, communityPromptShown = true }
local DEVICES = { pc = true, phone = true, tablet = true, console = true }
local remote = Instance.new("RemoteEvent")
remote.Name = "Telemetry"
remote.OnServerEvent:Connect(function(player, name, device)
	local s = sessions[player]
	if not s or type(name) ~= "string" or not CLIENT[name] then
		return
	end
	if name == "monoView" and not SimpleStats.validSurface(device) then return end
	s.last = s.last or {}
	local rateKey = name .. (if name == "monoView" then device else "")
	if s.last[rateKey] and os.clock() - s.last[rateKey] < RATE then
		return
	end
	s.last[rateKey] = os.clock()
	if name == "communityPromptShown" then
		if elapsed(s) >= 10 * 60 then
			s.onceDone = s.onceDone or {}
			s.onceDone.communityPrompt = true -- carried between worlds with the other once-per-session flags
			player:SetAttribute("CommunityPromptDue", false)
		end
	elseif name == "monoView" then
		Telemetry.monoView(player, device)
	elseif name == "ready" then
		if s.clientReady then
			return
		end
		s.clientReady = true
		if type(device) == "string" and DEVICES[device] then
			s.device = device
		end
		count(player, "clientReady")
	elseif name == "lassoChance" then
		if s.lassoChance then
			return
		end
		s.lassoChance = true
		count(player, "lassoChance")
	elseif name == "shopOpened" then -- (QM, Oct 14: /stats' shop open rate)
		Telemetry.monoView(player, "shop")
		Telemetry.once(player, "shopOpened")
		count(player, "shopOpens")
	else
		count(player, name)
	end
end)
remote.Parent = ReplicatedStorage

task.spawn(function() -- (Riders makes these)
	ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _, riderCFrame)
		local s = sessions[player]
		if not s or type(kind) ~= "string" then
			return
		end
		local z = if typeof(riderCFrame) == "CFrame" then riderCFrame.Position.Z else nil
		if kind ~= "" and z and z < 0 and (s.lastZ == nil or s.lastZ >= 0) then
			rideStarted(player, s)
		end
		s.lastZ = if kind == "" then nil else z
		if kind ~= "" and z and s.rideFar then
			s.rideFar = math.min(s.rideFar, z) -- (the course runs toward -z)
		end
	end)
	ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
		local s = sessions[player]
		if not s then
			return
		end
		local tut = player:GetAttribute("Tutorial") and "tut" or "post"
		if what == "out" then
			count(player, "mounted")
			s.riding, s.rideAnimal, s.rideCrash = true, false, false -- (the quit snapshot's: below)
		elseif what == "lasso" then
			count(player, "lassoThrow")
		elseif what == "landed" then
			count(player, "lassoLand")
		elseif what == "boss" then
			s.phase, s.phaseAt = "return", os.clock()
			count(player, "returnStart")
		elseif what == "crash" then
			count(player, tut .. "Crash")
			s.rideCrash = true
			s.phase, s.phaseAt = "base", os.clock()
		elseif what == "end" then
			s.lastRide = if s.rideAnimal then "animal" elseif s.rideCrash then "crash" else "empty"
			s.riding, s.lastEnd = false, os.clock()
			if s.rideFar then -- (how far it got: the quit snapshot's)
				s.lastRideFar, s.lastRideVs = rideFacts(player, s)
				s.ridesSinceGate = if (player:GetAttribute("GatesBroken") or 1) > s.rideGates then 0 else (s.ridesSinceGate or 0) + 1
				s.bestFar = math.min(s.bestFar or 0, s.rideFar)
				s.rideFar = nil
			end
			if s.affordAt then
				s.sawW2 = true -- (back at base with World 2's gold: the bar's prompt)
			end
			if tut == "post" then
				s.postRides = (s.postRides or 0) + 1
			end
			if s.phase ~= "reward" then
				s.phase, s.phaseAt = "base", os.clock()
			end
			s.controlAt = os.clock() -- (control's back: a ride within RETRY is a retry)
			s.retryOpen = tut
			task.delay(RETRY, function()
				if sessions[player] == s and s.controlAt and os.clock() - s.controlAt >= RETRY then
					count(player, s.retryOpen .. "RetryEligible") -- (didn't ride again in time)
					s.controlAt, s.retryOpen = nil, nil
				end
			end)
		end
	end)
end)

-- Gold.server's: online seconds in this world to first reach biome i.
task.spawn(function()
	local unlocked = ServerStorage:WaitForChild("BiomeUnlocked", 30)
	if unlocked then
		unlocked.Event:Connect(function(player, biome, seconds)
			local s = sessions[player]
			if s and type(biome) == "number" and type(seconds) == "number" then
				SimpleStats.reach(s.simple, WORLD, biome)
				add(s, nil, { ["w" .. WORLD .. "biome" .. biome] = seconds })
			end
		end)
	end
end)

Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end
Players.PlayerRemoving:Connect(leave)
task.spawn(function() -- (the quit snapshot's copy of each pen, and when they could first buy World 2)
	while true do
		task.wait(5)
		for player, s in sessions do
			local pens = workspace:FindFirstChild("Pens")
			local pen = pens and pens:FindFirstChild("Pen" .. tostring(player:GetAttribute("Pen")))
			s.penContents = pen and pen:GetAttribute("Contents") or s.penContents
			if WORLD == 1 and not s.affordAt and not player:GetAttribute("OwnsWorld2") and (player:GetAttribute("Gold") or 0) >= (Config.WorldPrices[2] or math.huge) then
				s.affordAt, s.sawW2 = os.clock(), not s.riding -- (first could buy World 2: at base, the prompt's up)
			end
		end
	end
end)
game:BindToClose(function()
	for player in sessions do
		leave(player)
	end
	StatsStore.flush() -- final session summaries must be queued before the last flush
end)

-- Stats.server: the session's online seconds so far and whether it's on its way to the
-- other world (its own counts treat both worlds as one session too).
-- Sessions going on now, in every server of both worlds: { all, new, ret } (this server's
-- alone if the MemoryStore can't be reached).
local okMap, activeMap = pcall(function()
	return game:GetService("MemoryStoreService"):GetHashMap("V1Active")
end)
activeMap = okMap and activeMap or nil
local function activeHere()
	local t = { all = 0, new = 0, ret = 0 }
	for _, s in sessions do
		if not s.excluded and not s.transferring then
			t.all += 1
			t[if s.new then "new" else "ret"] += 1
		end
	end
	return t
end
task.spawn(function()
	while activeMap and not RunService:IsStudio() do
		pcall(activeMap.SetAsync, activeMap, game.JobId, activeHere(), HEARTBEAT * 3)
		task.wait(HEARTBEAT)
	end
end)
function Telemetry.active()
	local total, servers = { all = 0, new = 0, ret = 0 }, 0
	local ok = activeMap and not RunService:IsStudio() and pcall(function()
		local pages = activeMap:ListItemsAsync(200)
		while true do
			for _, item in pages:GetCurrentPage() do
				servers += 1
				for k in total do
					total[k] += typeof(item.value) == "table" and tonumber(item.value[k]) or 0
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	if not ok or servers == 0 then
		return activeHere(), false
	end
	return total, true
end

-- Studio tests: a player's session, and a stand-in transfers store and confirm time.
Telemetry.join, Telemetry.leave, Telemetry.sessions = join, leave, sessions
function Telemetry.test(store, confirm)
	transfers, CONFIRM = store, confirm or CONFIRM
end
function Telemetry.session(player)
	local s = sessions[player]
	return s and elapsed(s), s and s.transferring == true, s and s.carried == true
end

return Telemetry
