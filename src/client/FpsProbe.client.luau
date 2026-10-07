-- Frame rate as players get it (QM, Oct 7: Creator Hub showed Android's slowest 10%
-- at about 19 fps, with no way to see where). Every player measures their own frame
-- rate, split by where they are (home, or the zone they're in), and every 30 s sends
-- Stats.server the totals; "/stats" shows them by device and place. Draws nothing.
--
-- "Logic" is the time each frame spends from PreAnimation to the end of Heartbeat:
-- the stampede, scripts and physics. The rest of a frame is mostly drawing it, so a
-- slow place with little logic time is slow to draw, not slow to run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldColors = require(ReplicatedStorage.Shared:WaitForChild("WorldColors"))

if RunService:IsStudio() then
	return -- (Studio's frame rate says nothing about players')
end
local report = ReplicatedStorage:WaitForChild("FpsReport", 60)
if not report then
	return
end

local player = Players.LocalPlayer
local SEND_EVERY = 30
local LOW_FPS = 20 -- a second with fewer frames than this counts as a slow second

local function device()
	if GuiService:IsTenFootInterface() then
		return "Console"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Touch"
	end
	return "PC"
end

-- "Home", or the zone's name (the course runs down -z from the home base at z > 0).
local function place()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local z = if root then root.Position.Z else workspace.CurrentCamera.CFrame.Position.Z
	if z > 0 then
		return "Home"
	end
	local biome = Config.Biomes[WorldColors.biomeAt(z)]
	return biome and biome.Name or "Home"
end

local totals = {} -- [place] = { frames, seconds, logic, low, mem }
local where = place()
local second, secondFrames = 0, 0
local logicStart = os.clock()
local logic = 0

RunService.PreAnimation:Connect(function()
	logicStart = os.clock()
end)
RunService.Heartbeat:Connect(function(dt)
	logic = os.clock() - logicStart
	local t = totals[where]
	if not t then
		t = { frames = 0, seconds = 0, logic = 0, low = 0, mem = 0 }
		totals[where] = t
	end
	dt = math.min(dt, 1) -- (a hitch over a second counts as one slow second)
	t.frames += 1
	t.seconds += dt
	t.logic += math.min(logic, dt)
	second += dt
	secondFrames += 1
	if second >= 1 then
		if secondFrames < LOW_FPS then
			t.low += 1
		end
		t.mem += Stats:GetTotalMemoryUsageMb() -- (once a second: an average over the seconds)
		second, secondFrames = 0, 0
		where = place()
	end
end)

local kind = device()
while true do
	task.wait(SEND_EVERY)
	local batch = totals
	totals = {}
	for at, t in batch do
		if t.seconds > 0 then
			report:FireServer(kind, at, t.frames, t.seconds, t.logic, t.low, t.mem)
		end
	end
end
