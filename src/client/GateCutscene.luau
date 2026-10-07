-- The tutorial's last beat (QM, Oct 7): the moment your pet smashes the Desert gate,
-- time drops into slow motion and the camera swings round from behind you to the
-- side and in front, so you watch yourself and your pet charge through the shards.
-- Then it fades to black, you're put back at your base, and the merge lesson takes
-- over (Tutorial: TutorialDone sets FuseLesson).
--
--   GateCutscene.play(onHome)  -- starts it; onHome() once the screen's black and the
--                                 ride's over. GateCutscene.camera is set while it runs.
--   GateCutscene.camera(dt, at)  -- Ride's camera hook while it's on (nil when it isn't)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GateCutscene = {}

local SLOW = 0.22 -- the time scale while it rolls (the egg close-up's is 0.5)
local WATCH = 2.2 -- seconds of it, in that slowed time
local FADE = 0.45 -- seconds the screen takes to go black
local HOLD = 0.35 -- seconds it stays black before you're home
local SWING = 155 -- degrees the camera comes round, from behind you to in front
local gui, cover

local player = Players.LocalPlayer

GateCutscene.slowMo = nil -- the time scale Ride should run at while it's on (nil: off)
GateCutscene.camera = nil

local function screen()
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "GateCutscene"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 20
		gui.Parent = player:WaitForChild("PlayerGui")
		cover = Instance.new("Frame")
		cover.BackgroundColor3 = Color3.new(0, 0, 0)
		cover.BackgroundTransparency = 1
		cover.Size = UDim2.fromScale(1, 1)
		cover.Visible = false
		cover.Parent = gui
	end
	return cover
end

-- The camera: starts where it was (behind and above), swings SWING degrees round
-- and drops low and ahead, looking back at the rider as they come through.
local function makeCamera()
	local t = 0
	return function(dt, at)
		t += dt
		local a = math.clamp(t / (WATCH * 0.9), 0, 1)
		a = a * a * (3 - 2 * a)
		local angle = math.rad(SWING) * a
		local back = Vector3.new(math.sin(angle), 0, math.cos(angle)) -- behind (+z) round to in front
		local distance = 26 - 8 * a
		local height = 24 - 15 * a
		local from = Vector3.new(at.X, 0, at.Z) + back * distance + Vector3.new(0, height, 0)
		return CFrame.lookAt(from, Vector3.new(at.X, 4 + at.Y, at.Z))
	end
end

local running = false

function GateCutscene.play(onHome)
	if running then
		return
	end
	running = true
	GateCutscene.camera = makeCamera()
	GateCutscene.slowMo = SLOW
	task.spawn(function()
		task.wait(WATCH * SLOW) -- (real seconds: WATCH of the slowed ride)
		local black = screen()
		black.BackgroundTransparency = 1
		black.Visible = true
		TweenService:Create(black, TweenInfo.new(FADE, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
		task.wait(FADE)
		GateCutscene.camera, GateCutscene.slowMo = nil, nil
		if onHome then
			onHome() -- off the ride, back at the base (Ride's Tutorial.endRide)
		end
		task.wait(HOLD)
		local back = TweenService:Create(black, TweenInfo.new(FADE, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
		back:Play()
		back.Completed:Wait()
		black.Visible = false
		running = false
	end)
end

function GateCutscene.running()
	return running
end

return GateCutscene
