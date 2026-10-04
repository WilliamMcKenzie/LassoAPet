-- Exclusive animal events (Config.Events, QM Oct 4): one every 10 minutes. Each event
-- picks one of the exclusive animals (the Loong, Snack Yak, Robo Shark), counts
-- down, then that animal pops in at the start line and runs off with the
-- stampede to the finish line (every client draws it, Ride.client) and its egg drops in the EventNest somewhere random on the course.
-- Riding that kind of animal while the egg is out, the guide arrows lead to it.
-- The first player to grab the egg gets it (Nests.server, like any nest's), which
-- ends the event; a new one starts every Config.Events.Cycle seconds.
--
-- What the clients read, on Workspace.World:
--   EventKind     the animal ("" between events)
--   EventId       counts up each event; its animal is stampede key -EventId
--   EventSpawnAt  server time the animal spawns and the egg drops (the countdown ends)
--   EventTaken    true once someone has jumped on (or knocked away) the animal
-- and World.Nests.EventNest's "Egg" attribute, as for every nest.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Godlands = require(ReplicatedStorage.Shared.Godlands)

local EVENTS = Config.Events
local world = workspace:WaitForChild("World")
local rng = Random.new()

-- The event's nest: a copy of a map nest, parked out of sight between events.
-- Nests.server skips it when it rolls and restocks the others.
local PARKED = CFrame.new(0, -500, 0)
local template = world.Nests:FindFirstChildWhichIsA("Model")
local nest = template:Clone()
nest.Name = "EventNest"
-- No nest to see (QM): the event's egg just lies on the ground. The copy's parts stay
-- (EggSpot is where the egg goes), all of them invisible and out of the way.
for _, child in nest:GetDescendants() do
	if child:IsA("BasePart") then
		child.Anchored = true
		child.Transparency = 1
		child.CanCollide, child.CanQuery, child.CanTouch = false, false, false
	elseif child:IsA("Decal") or child:IsA("Texture") then
		child.Transparency = 1
	end
end
local spot = nest:WaitForChild("EggSpot")
-- How far the egg's centre sits above the floor: on the ground itself (a 1x egg's
-- centre is 1.6 studs up; Ride.client lifts a bigger one to match).
local SPOT_LIFT = 1.6
local FROM_SPOT = CFrame.new(-spot.Position) * nest:GetPivot()
nest:SetAttribute("Egg", "")
nest:PivotTo(PARKED)
nest.Parent = world.Nests

-- Obstacle footprints (each obstacle's "Base" part, else its lowest part), as Ride.client reads them.
local footprints = {}
for _, model in world.Obstacles:GetChildren() do
	local base = model:FindFirstChild("Base")
	for _, part in if base then {} else model:GetChildren() do
		if part:IsA("BasePart") and (not base or part.Position.Y < base.Position.Y) then
			base = part
		end
	end
	if base then
		table.insert(footprints, { x = base.Position.X, z = base.Position.Z, hx = base.Size.X / 2, hz = base.Size.Z / 2 })
	end
end

-- The course from just past the start line to just before the finish line
-- (or the Godlands' line while it's on).
local START_Z = (if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else 0) - 40
local END_Z = if Config.CourseLength == math.huge
	then (Godlands.start or -8000) + 40
	else -Config.CourseLength + Config.FinishFromEnd + 40

local function clear(x, z)
	for i = 2, #Config.Biomes do
		if math.abs(z - WorldColors.biomeStart(i)) < EVENTS.GateMargin then
			return false
		end
	end
	for _, o in footprints do
		if math.abs(o.x - x) < o.hx + EVENTS.ObstacleMargin and math.abs(o.z - z) < o.hz + EVENTS.ObstacleMargin then
			return false
		end
	end
	return true
end

-- A random clear spot anywhere on the course, in any biome.
local function randomSpot()
	local half = Config.CourseHalfWidth - EVENTS.WallMargin
	local x, z
	for _ = 1, 200 do
		x, z = rng:NextNumber(-half, half), rng:NextNumber(END_Z, START_Z)
		if clear(x, z) then
			break
		end
	end
	return Vector3.new(x, Ground.heightAt(x, z) + SPOT_LIFT, z)
end

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
-- picking at random from the three). Its egg stays out until someone grabs it or
-- the next one's countdown starts.
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
-- (The same from the server side, for testing in Studio: World's "ForceEvent" attribute.)
world:GetAttributeChangedSignal("ForceEvent"):Connect(function()
	local kind = world:GetAttribute("ForceEvent")
	if kind and table.find(EVENTS.Animals, kind) then
		forced = kind
	end
	world:SetAttribute("ForceEvent", nil)
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
local cycleStart = os.clock()
while true do
	-- Count down to it.
	local kind = forced or EVENTS.Animals[rng:NextInteger(1, #EVENTS.Animals)]
	if forced then
		forced, cycleStart = nil, os.clock()
	end
	id += 1
	world:SetAttribute("EventTaken", false)
	world:SetAttribute("EventSpawnAt", workspace:GetServerTimeNow() + EVENTS.Countdown)
	world:SetAttribute("EventId", id)
	world:SetAttribute("EventKind", kind)
	waitFor(EVENTS.Countdown, isForced)

	if not forced then
		-- The animal pops in on every client; the egg drops (nest first, then its egg,
		-- so the egg shows up in the nest's new spot).
		nest:PivotTo(CFrame.new(randomSpot()) * FROM_SPOT)
		task.wait()
		nest:SetAttribute("Egg", kind)
		-- The egg stays out until it's grabbed, the next event is due, or (QM) the event's
		-- animal is gone: run off the far end of the course at its stampede speed, as every
		-- client draws it (Ride.client). Once someone's riding it, it's theirs to chase.
		local nextCycle = cycleStart + EVENTS.Cycle
		local speed = Config.HerdSpeed * ((Config.AnimalStats[kind] or {}).Speed or 1)
		local runsOff = os.clock() + (START_Z + 44 - (-Config.CourseLength + Config.FinishFromEnd)) / speed + 1
		while nest:GetAttribute("Egg") ~= "" and os.clock() < nextCycle - 1.5 and not forced
			and (world:GetAttribute("EventTaken") or os.clock() < runsOff) do
			task.wait(0.5)
		end
	end

	-- Over: grabbed, the next one is due, or "/event" started another. Wait out the
	-- rest of the cycle.
	local nextCycle = cycleStart + EVENTS.Cycle
	nest:SetAttribute("Egg", "")
	world:SetAttribute("EventKind", "")
	task.wait(1)
	nest:PivotTo(PARKED)
	waitFor(math.max(nextCycle - os.clock(), 0), isForced)
	if not forced then
		cycleStart = nextCycle
	end
end
