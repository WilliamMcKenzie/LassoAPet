-- Exclusive animal events (Config.Events, QM Oct 4): one every 10 minutes. Each event
-- picks one of the exclusive animals (the Loong, Snack Yak, Robo Shark), and
-- Countdown seconds later that animal pops in at the start line and runs off with
-- the stampede to the finish line (every client draws it, Ride.client). Nothing
-- announces it (QM, Oct 6: the hard part is finding and riding it in the wild);
-- lasso it and the nests give its egg, like any wild animal's (Nests.server). The
-- event's over once someone's jumped on it (theirs now), it's run off the far end
-- of the course, or the next one's due; a new one starts every Config.Events.Cycle
-- seconds (the first one a full cycle after the server starts).
--
-- What the clients read, on Workspace.World:
--   EventKind     the animal ("" between events)
--   EventId       counts up each event; its animal is stampede key -EventId
--   EventSpawnAt  server time the animal spawns (the countdown ends; the clients
--                 build it meanwhile, since a big animal is slow to build)
--   EventTaken    true once someone has jumped on (or knocked away) the animal

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local EVENTS = Config.Events
local world = workspace:WaitForChild("World")
local rng = Random.new()

-- Just past the start line: where the animal's run down the course starts (below).
local START_Z = (if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else 0) - 40

-- Someone jumped on (or knocked away) this event's animal: it's gone for everyone,
-- including players who join later.
ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(_, what, key)
	if (what == "take" or what == "knock") and tonumber(key) == -(world:GetAttribute("EventId") or 0) then
		world:SetAttribute("EventTaken", true)
	end
end)

while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end

-- A new event every Config.Events.Cycle seconds (QM, Oct 4: a 10 minute cycle,
-- picking at random from the three).
-- Testing: "/event loong|roboshark|yak" in chat starts that event now (its countdown
-- first), ending the one that's on; the 10 minute cycle starts over from it.
-- Only in Studio or for the game's owner.
local forced -- the kind "/event" asked for, until the loop picks it up
local ALIASES = { loong = "Loong", roboshark = "RoboShark", shark = "RoboShark", yak = "SnackYak", snackyak = "SnackYak" }
local eventCommand = Instance.new("TextChatCommand")
eventCommand.Name = "Event"
eventCommand.PrimaryAlias = "/event"
eventCommand.Triggered:Connect(function(source, text)
	local name = (text:match("^/event%s+(%S+)") or ""):lower()
	if (game:GetService("RunService"):IsStudio() or source.UserId == game.CreatorId) and ALIASES[name] then
		forced = ALIASES[name]
	end
end)
eventCommand.Parent = game:GetService("TextChatService")
-- (The same from the server side, for testing in Studio: World's "ForceEvent" attribute.
-- The shop's Spawn Loong sets it too, with "ForceEventNow" first: no countdown.)
local forcedNow = false
world:GetAttributeChangedSignal("ForceEvent"):Connect(function()
	local kind = world:GetAttribute("ForceEvent")
	if kind and table.find(EVENTS.Forceable or EVENTS.Animals, kind) then
		forced = kind
		forcedNow = world:GetAttribute("ForceEventNow") == true
	end
	world:SetAttribute("ForceEvent", nil)
	world:SetAttribute("ForceEventNow", nil)
end)

-- Waits `seconds` (or until it's true that `stop()`), checking every so often.
local function waitFor(seconds, stop)
	local untilTime = os.clock() + seconds
	while os.clock() < untilTime and not stop() do
		task.wait(0.25)
	end
end
local function isForced()
	return forced ~= nil
end

local id = 0
-- A new server waits a full cycle before its first event (QM, Oct 5); Spawn Loong
-- and "/event" still start one straight away.
waitFor(EVENTS.Cycle, isForced)
local cycleStart = os.clock()
while true do
	-- Count down to it.
	local kind = forced or EVENTS.Animals[rng:NextInteger(1, #EVENTS.Animals)]
	local countdown = if forced and forcedNow then 0 else EVENTS.Countdown
	if forced then
		forced, forcedNow, cycleStart = nil, false, os.clock()
	end
	id += 1
	world:SetAttribute("EventTaken", false)
	world:SetAttribute("EventSpawnAt", workspace:GetServerTimeNow() + countdown)
	world:SetAttribute("EventId", id)
	world:SetAttribute("EventKind", kind)
	waitFor(countdown, isForced)

	if not forced then
		-- The animal pops in on every client and runs off with the stampede. The event's
		-- on until someone's jumped on it (theirs now), it's run off the far end of the
		-- course at its stampede speed (as every client draws it, Ride.client), or the
		-- next one's due.
		local nextCycle = cycleStart + EVENTS.Cycle
		local speed = require(ReplicatedStorage.Shared.HerdSpeed)((Config.AnimalStats[kind] or {}).Speed or 1) -- (as Ride.client's)
		local endZ = require(ReplicatedStorage.Shared.WorldColors).biomeNamedStart(EVENTS.DespawnBiome) or (-Config.CourseLength + Config.FinishFromEnd) -- (the Jungle's edge: QM, Oct 11)
		local runsOff = os.clock() + (START_Z + 44 - endZ) / speed + 1
		while os.clock() < nextCycle - 1.5 and not forced and not world:GetAttribute("EventTaken") and os.clock() < runsOff do
			task.wait(0.5)
		end
	end

	-- Over: ridden, run off, the next one is due, or "/event" started another. Wait
	-- out the rest of the cycle.
	local nextCycle = cycleStart + EVENTS.Cycle
	world:SetAttribute("EventKind", "")
	waitFor(math.max(nextCycle - os.clock(), 0), isForced)
	if not forced then
		cycleStart = nextCycle
	end
end
