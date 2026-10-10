-- The run home's camera (QM, Oct 10): low over the rider's right shoulder, looking
-- nearly level down the course, eased in as you turn for home and back out at the
-- home line. Config.ShoulderCam: Right / Up / Back studs from the rider, and the
-- point it looks at, Ahead studs on and LookUp up.
--
--   ShoulderCam.blend(dt, on, riding) -> 0 .. 1: how far into it the camera is
--
-- Tuning live in a playtest: Shoulder<Key> attributes on the camera (ShoulderRight...)
-- win over Config, and ShoulderTest = true shows it on the way out too.
--   ShoulderCam.pose(rider, yaw, zoom) -> its CFrame (zoom: x its distance)

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ShoulderCam = {}

local k = 0

-- In Studio the camera gets the attributes up front, at Config's values, so they're
-- there to edit in a playtest (Workspace > Camera, in the Client view).
local TUNE = { "Right", "Up", "Back", "Ahead", "LookUp", "LookRight" }
if game:GetService("RunService"):IsStudio() then
	local function seed()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		for _, key in TUNE do
			if camera:GetAttribute("Shoulder" .. key) == nil then
				camera:SetAttribute("Shoulder" .. key, Config.ShoulderCam[key])
			end
		end
		if camera:GetAttribute("ShoulderTest") == nil then
			camera:SetAttribute("ShoulderTest", false)
		end
	end
	seed()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(seed)
end

local function get(cfg, key)
	local v = workspace.CurrentCamera:GetAttribute("Shoulder" .. key)
	if v ~= nil then
		return v
	end
	return cfg[key]
end

function ShoulderCam.blend(dt, on, riding)
	local cfg = Config.ShoulderCam
	on = (on or (riding and workspace.CurrentCamera:GetAttribute("ShoulderTest") == true)) and cfg.On
	k = math.clamp(k + (if on then dt / cfg.InTime else -dt / cfg.OutTime), 0, 1)
	return k * k * (3 - 2 * k)
end

function ShoulderCam.pose(rider, yaw, zoom)
	local cfg = Config.ShoulderCam
	local basis = CFrame.new(rider) * CFrame.Angles(0, yaw, 0)
	local from = basis * Vector3.new(get(cfg, "Right") * zoom, get(cfg, "Up") * zoom, get(cfg, "Back") * zoom)
	local at = basis * Vector3.new(get(cfg, "LookRight") * zoom, get(cfg, "LookUp"), -get(cfg, "Ahead"))
	return CFrame.lookAt(from, at)
end

return ShoulderCam
