-- The run home's camera (QM, Oct 10): low over the rider's right shoulder, looking
-- nearly level down the course, eased in as you turn for home and back out at the
-- home line. Config.ShoulderCam: Right / Up / Back studs from the rider, and the
-- point it looks at, Ahead studs on and LookUp up.
--
--   ShoulderCam.blend(dt, on) -> 0 .. 1: how far into it the camera is
--   ShoulderCam.pose(rider, yaw, zoom) -> its CFrame (zoom: x its distance)

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ShoulderCam = {}

local k = 0

function ShoulderCam.blend(dt, on)
	local cfg = Config.ShoulderCam
	on = on and cfg.On
	k = math.clamp(k + (if on then dt / cfg.InTime else -dt / cfg.OutTime), 0, 1)
	return k * k * (3 - 2 * k)
end

function ShoulderCam.pose(rider, yaw, zoom)
	local cfg = Config.ShoulderCam
	local basis = CFrame.new(rider) * CFrame.Angles(0, yaw, 0)
	local from = basis * Vector3.new(cfg.Right * zoom, cfg.Up * zoom, cfg.Back * zoom)
	local at = basis * Vector3.new(cfg.Right * zoom, cfg.LookUp, -cfg.Ahead)
	return CFrame.lookAt(from, at)
end

return ShoulderCam
