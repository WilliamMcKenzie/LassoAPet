-- The giant slingshot's launch (shared: Server/Slingshot rests it, Client/SlingshotLaunch plays it) (design/slingshot, tools/slingshot_meshes.py): no pouch,
-- the band hangs slack between the prongs (QM, Nov 7), stretches back to the player and
-- their pet waiting behind it, draws back a touch more, snaps forward past the fork,
-- wobbles and hangs slack again. Same timings as the preview GIF.
--
--   SlingshotPose.place(model, base, t)               -- the bands at time t of the shot (0: resting)
--   SlingshotPose.launch(model, onStep, onRelease)   -- plays the shot; returns when wound back
--     onStep(pullCFrame)                         -- each frame until the release: hold the
--                                                   rider here (it faces -Z, the band behind)
--     onRelease(pullCFrame, direction)           -- as the band passes the fork: fling the
--                                                   player and their pet along direction
--
-- The Model's pivot is the middle of its base (it flings toward its -Z). Inside it:
--   BandL, BandMid, BandR  SlingshotBand MeshParts (anchored), stretched each frame:
--                          tip -> rider's left, across the rider's back, rider's right -> tip

local RunService = game:GetService("RunService")

local TIPS = { Vector3.new(-7.6, 14.6, 0), Vector3.new(7.6, 14.6, 0) }
local BAND_SIDE = { Vector3.new(-2, 0.9, 0.3), Vector3.new(2, 0.9, 0.3) }
local SLACK = Vector3.new(0, 10.4, 0) -- resting: hanging between the tips
local NEUTRAL = SLACK -- what it wobbles about after the shot
local GRAB = 0.5 -- s: stretched back from slack to the rider
local LOAD = Vector3.new(0, 1.6, 11) -- (QM, Nov 7: the slingshot is nearer the pen, so the rider waits nearer it; was 17)
local DRAW = Vector3.new(0, 1.6, 13.5)
local OVER = Vector3.new(0, 22, -7)
local FIRE = 0.24
local TILT = 0.35
local BAND_SIZE = Vector2.new(1.2, 0.8)

local DURATION = GRAB + 0.6 + 0.2 + FIRE + 0.9 + 0.4
local RELEASE = GRAB + 0.6 + 0.2 + FIRE * 0.8

local Slingshot = {}
Slingshot.RELEASE = RELEASE
Slingshot.DURATION = DURATION

local function smooth(u)
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function pullAt(t)
	if t < GRAB then
		return SLACK:Lerp(LOAD, smooth(t / GRAB))
	end
	t -= GRAB
	if t < 0.6 then
		return LOAD:Lerp(DRAW, smooth(t / 0.6))
	end
	t -= 0.6
	if t < 0.2 then
		return DRAW
	end
	t -= 0.2
	if t < FIRE then
		local u = t / FIRE
		return DRAW:Lerp(OVER, u * u)
	end
	t -= FIRE
	if t < 0.9 then
		return NEUTRAL + (OVER - NEUTRAL) * math.cos(2 * math.pi * 1.8 * t) * math.exp(-4.5 * t)
	end
	return NEUTRAL
end

-- the pull's CFrame in the slingshot's space: facing the tips, only partly pitched
local function pullLocal(t)
	local p = pullAt(t)
	local mid = (TIPS[1] + TIPS[2]) / 2
	-- (never straight up: hanging slack, it faces -z too)
	return CFrame.lookAt(p, Vector3.new(mid.X, p.Y + (mid.Y - p.Y) * TILT, p.Z - math.max(p.Z - mid.Z, 1)))
end

local function stretch(band, a, b)
	if band then
		band.Size = Vector3.new(BAND_SIZE.X, BAND_SIZE.Y, math.max((b - a).Magnitude, 0.05))
		band.CFrame = CFrame.lookAt((a + b) / 2, b)
	end
end

local function place(model, base, t)
	local cf = base * pullLocal(t)
	local tipL, tipR = base * TIPS[1], base * TIPS[2]
	local sideL, sideR = cf * BAND_SIDE[1], cf * BAND_SIDE[2]
	stretch(model:FindFirstChild("BandL"), tipL, sideL)
	stretch(model:FindFirstChild("BandMid"), sideL, sideR)
	stretch(model:FindFirstChild("BandR"), sideR, tipR)
	return cf
end

Slingshot.place = place -- (model, base CFrame, t): returns the pull's CFrame
Slingshot.pullLocal = pullLocal

function Slingshot.launch(model, onStep, onRelease, base)
	base = base or model:GetPivot()
	local released = false
	local t0 = os.clock()
	while true do
		local t = math.min(os.clock() - t0, DURATION)
		local cf = place(model, base, t)
		if not released and t < RELEASE and onStep then
			onStep(if t < GRAB then base * pullLocal(GRAB) else cf) -- (the rider waits behind it while the band comes back)
		end
		if not released and t >= RELEASE then
			released = true
			local a = (base * pullLocal(RELEASE)).Position
			local b = (base * pullLocal(RELEASE + 1 / 240)).Position
			if onRelease then
				task.spawn(onRelease, cf, (b - a).Unit)
			end
		end
		if t >= DURATION then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

return Slingshot
