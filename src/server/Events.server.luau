-- Exclusive animal events (Config.Events, QM Oct 4): one is always on. Each event
-- picks one of the exclusive animals (the Loong, Snack Yak, Robo Shark), counts
-- down, then that animal pops in at the start line and runs off with the
-- stampede to the finish line (every client draws it, Ride
-- .client) and its egg drops in the EventNest somewhere random on the course.
-- Riding that kind of animal while the egg is out, the guide arrows lead to it.
-- The first player to grab the egg gets it (Nests.server, like any nest's); that,
-- or running out of time, ends the event, and the next countdown starts.
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
for _, child in nest:GetChildren() do
	if child:IsA("BasePart") then
		child.Anchored = true
	end
end
local spot = nest:WaitForChild("EggSpot")
-- How far the egg's centre sits above the floor, and the nest's pivot from the egg.
local SPOT_LIFT = template.EggSpot.Position.Y
	- Ground.heightAt(template.EggSpot.Position.X, template.EggSpot.Position.Z)
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

local id, last = 0, nil
while true do
	-- Count down to the next one.
	local kinds = {}
	for _, kind in EVENTS.Animals do
		if kind ~= last or #EVENTS.Animals == 1 then
			table.insert(kinds, kind)
		end
	end
	local kind = kinds[rng:NextInteger(1, #kinds)]
	last, id = kind, id + 1
	world:SetAttribute("EventTaken", false)
	world:SetAttribute("EventSpawnAt", workspace:GetServerTimeNow() + EVENTS.Countdown)
	world:SetAttribute("EventId", id)
	world:SetAttribute("EventKind", kind)
	task.wait(EVENTS.Countdown)

	-- The animal pops in on every client; the egg drops (nest first, then its egg,
	-- so the egg shows up in the nest's new spot).
	nest:PivotTo(CFrame.new(randomSpot()) * FROM_SPOT)
	task.wait()
	nest:SetAttribute("Egg", kind)
	local ends = os.clock() + EVENTS.Duration
	while nest:GetAttribute("Egg") ~= "" and os.clock() < ends do
		task.wait(0.5)
	end

	-- Over: grabbed, or out of time.
	nest:SetAttribute("Egg", "")
	world:SetAttribute("EventKind", "")
	task.wait(1)
	nest:PivotTo(PARKED)
	task.wait(EVENTS.Gap)
end
