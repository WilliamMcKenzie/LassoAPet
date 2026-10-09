-- The sprint camera (QM, Oct 9): while you sprint, the view widens (a higher
-- FieldOfView stretches the screen's edges, the nearest Roblox gets to a fisheye) and
-- the camera pulls in on you, easing in over InTime seconds and back over OutTime.
-- Config.SprintCam.
--
--   SprintCam.update(dt, sprinting) -> degrees to add to the field of view, x the camera's distance

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local SprintCam = {}

local t = 0 -- 0 (off) .. 1 (full sprint look)

function SprintCam.update(dt, sprinting)
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
	return (cfg.Fov - 70) * k, 1 + (cfg.Zoom - 1) * k
end

return SprintCam
