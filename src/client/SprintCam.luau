-- The sprint camera (QM, Oct 9): while you sprint, the view widens (a higher
-- FieldOfView stretches the screen's edges, the nearest Roblox gets to a fisheye) and
-- the camera pulls in on you, easing in over InTime seconds and back over OutTime.
-- How much goes with your speed (QM, Oct 9): Fov / Zoom as set at a horse's sprint
-- (HorseSprint studs/s), more the faster you go (up to MaxScale x), less if slower.
-- Config.SprintCam.
--
--   SprintCam.update(dt, sprinting, speed) -> degrees to add to the field of view, x the camera's distance

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local SprintCam = {}

local t = 0 -- 0 (off) .. 1 (full sprint look)
local scale = 1 -- how much, by speed (eased, so a speed change doesn't jump the view)

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
		local want = math.clamp(speed / cfg.HorseSprint, cfg.MinScale, cfg.MaxScale)
		scale += (want - scale) * (1 - math.exp(-4 * dt))
	end
	k *= scale
	return (cfg.Fov - 70) * k, math.max(1 + (cfg.Zoom - 1) * k, 0.4)
end

return SprintCam
