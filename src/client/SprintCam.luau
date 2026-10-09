-- The sprint camera (QM, Oct 9): while you sprint, the view widens (a higher
-- FieldOfView stretches the screen's edges, the nearest Roblox gets to a fisheye) and
-- the camera pulls in on you, easing in over InTime seconds and back over OutTime.
-- How much goes with your speed (QM, Oct 9): Fov / Zoom as set at a horse's sprint
-- (HorseSprint studs/s), more the faster you go (up to MaxScale x), less if slower,
-- in tiers (Config.SprintTiers: the speeds each one starts at): crossing into a new
-- tier snaps it to speed / HorseSprint, and within a tier it only creeps on at Creep x
-- that rate. Config.SprintCam.
--
--   SprintCam.update(dt, sprinting, speed) -> degrees to add to the field of view, x the camera's distance
--   SprintCam.tier(speed) -> 0 (under the first) .. #Config.SprintTiers
--   SprintCam.tierLoudness(tier) -> 1 .. 2: the wind's volume step for that tier

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local SprintCam = {}

local t = 0 -- 0 (off) .. 1 (full sprint look)
local scale = 1 -- how much, by speed (eased, so a speed change doesn't jump the view)
local tierBase, lastTier = 1, 0

function SprintCam.tier(speed)
	local n = 0
	for i, from in Config.SprintTiers do
		if (speed or 0) >= from then
			n = i
		end
	end
	return n
end

function SprintCam.tierLoudness(tier)
	-- even steps from 1x (the first tier) to 2x (the last: QM, Oct 9)
	local n = #Config.SprintTiers
	return if n > 1 then 1 + math.clamp(tier - 1, 0, n - 1) / (n - 1) else 1
end

function SprintCam.update(dt, sprinting, speed)
	local cfg = Config.SprintCam
	if not cfg.On then
		t = 0
		return 0, 1
	end
	if sprinting then
		t = math.min(t + dt / cfg.InTime, 1)
	else
		t = math.max(t - dt / cfg.OutTime, 0)
	end
	local k = t * t * (3 - 2 * t) -- (smoothstep: eased at both ends)
	if sprinting and speed then
		local full = math.clamp(speed / cfg.HorseSprint, cfg.MinScale, cfg.MaxScale)
		local tier = SprintCam.tier(speed)
		if tier ~= lastTier then
			lastTier = tier
			tierBase = full -- (a new tier: it snaps to the full amount for this speed)
		end
		local want = tierBase + (full - tierBase) * cfg.Creep
		scale += (want - scale) * (1 - math.exp(-(if math.abs(want - scale) > 0.05 then 18 else 4) * dt)) -- (snappy on a tier change)
	else
		lastTier = 0
	end
	k *= scale
	return (cfg.Fov - 70) * k, math.max(1 + (cfg.Zoom - 1) * k, 0.4)
end

return SprintCam
