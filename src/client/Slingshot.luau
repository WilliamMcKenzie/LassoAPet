-- The giant slingshot's launch (design/slingshot, tools/slingshot_meshes.py): the pouch
-- rests pulled back by the ground, draws back a touch more, snaps forward past the fork,
-- wobbles on the bands and winds back down. Same timings as the preview GIF.
--
--   Slingshot.pose(model)                 -- the resting pose (call once after placing it)
--   Slingshot.launch(model, onRelease)    -- plays the shot; returns when it has wound back
--     onRelease(pouchCFrame, direction)   -- called as the pouch passes the fork: fling the
--                                            player and their pet from there along direction
--
-- The Model's pivot is the middle of its base (it flings toward its -Z). Inside it:
--   Pouch         a Model of the SlingshotPouch pieces, its pivot at the pouch's middle
--   BandL, BandR  SlingshotBand MeshParts (anchored): each is stretched tip -> pouch
-- Anything welded to the Pouch's parts (the rider) moves with it until the release.

local RunService = game:GetService("RunService")

local TIPS = { Vector3.new(-7.6, 14.6, 0), Vector3.new(7.6, 14.6, 0) }
local POUCH_SIDE = { Vector3.new(-4.7, 0.4, -1.2), Vector3.new(4.7, 0.4, -1.2) }
local NEUTRAL = Vector3.new(0, 13, 3.6)
local LOAD = Vector3.new(0, 4.4, 17)
local DRAW = Vector3.new(0, 3.6, 20)
local OVER = Vector3.new(0, 22, -7)
local FIRE = 0.24
local TILT = 0.35
local BAND_SIZE = Vector2.new(1.2, 0.8)

local DURATION = 0.6 + 0.2 + FIRE + 0.9 + 1.4
local RELEASE = 0.6 + 0.2 + FIRE * 0.8

local Slingshot = {}

local function smooth(u)
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function pouchAt(t)
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
	t -= 0.9
	return NEUTRAL:Lerp(LOAD, smooth(t / 1.4))
end

-- the pouch's CFrame in the slingshot's space: facing the tips, only partly pitched
local function pouchLocal(t)
	local p = pouchAt(t)
	local mid = (TIPS[1] + TIPS[2]) / 2
	return CFrame.lookAt(p, Vector3.new(mid.X, p.Y + (mid.Y - p.Y) * TILT, mid.Z))
end

local function place(model, base, t)
	local cf = base * pouchLocal(t)
	local pouch = model:FindFirstChild("Pouch")
	if pouch then
		pouch:PivotTo(cf)
	end
	for i, name in { "BandL", "BandR" } do
		local band = model:FindFirstChild(name)
		if band then
			local a = (base * CFrame.new(TIPS[i])).Position
			local b = (cf * CFrame.new(POUCH_SIDE[i])).Position
			band.Size = Vector3.new(BAND_SIZE.X, BAND_SIZE.Y, (b - a).Magnitude)
			band.CFrame = CFrame.lookAt((a + b) / 2, b)
		end
	end
	return cf
end

function Slingshot.pose(model)
	return place(model, model:GetPivot(), 0)
end

function Slingshot.launch(model, onRelease)
	local base = model:GetPivot()
	local released = false
	local t0 = os.clock()
	while true do
		local t = math.min(os.clock() - t0, DURATION)
		local cf = place(model, base, t)
		if not released and t >= RELEASE then
			released = true
			local a = (base * pouchLocal(RELEASE)).Position
			local b = (base * pouchLocal(RELEASE + 1 / 240)).Position
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
