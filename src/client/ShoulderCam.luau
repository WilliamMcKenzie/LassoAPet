-- The run home's camera (QM, Oct 10): low over the rider's right shoulder, looking
-- nearly level down the course, eased in as you turn for home and back out at the
-- home line. Config.ShoulderCam: Right / Back studs from the rider, and the point it
-- looks at, Ahead studs on and LookUp up. How high (QM, Oct 10): by how high you sit,
-- your seat's height less UpBelow, kept between UpMin and UpMax (a horse ~5, an Ice
-- Golem ~10, an Icebringer 12), and BurrowUp while a Sandworm's under the ground.
--
--   ShoulderCam.blend(dt, on, riding) -> 0 .. 1: how far into it the camera is
--
-- Tuning live in a playtest: Shoulder<Key> attributes on the camera (ShoulderRight...)
-- win over Config, and ShoulderTest = true shows it on the way out too.
--   ShoulderCam.pose(rider, yaw, zoom, seat, burrowed) -> its CFrame (zoom: x its
--     distance; seat: the rider's height over the ground)

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ShoulderCam = {}

local k = 0

-- In Studio the camera gets the attributes up front, at Config's values, so they're
-- there to edit in a playtest (Workspace > Camera, in the Client view).
local TUNE = { "Right", "Back", "Ahead", "LookUp", "LookRight" } -- (and ShoulderUp, if you add it, wins over the fit)
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

local up, upAt = nil, 0 -- the height in use (eased), and when it was last eased
function ShoulderCam.pose(rider, yaw, zoom, seat, burrowed)
	local cfg = Config.ShoulderCam
	local want = workspace.CurrentCamera:GetAttribute("ShoulderUp")
		or if burrowed then cfg.BurrowUp else math.clamp((seat or 0) - cfg.UpBelow, cfg.UpMin, cfg.UpMax)
	local now = os.clock()
	up = if up then up + (want - up) * (1 - math.exp(-4 * math.min(now - upAt, 0.1))) else want
	upAt = now
	local basis = CFrame.new(rider) * CFrame.Angles(0, yaw, 0)
	local from = basis * Vector3.new(get(cfg, "Right") * zoom, up * zoom, get(cfg, "Back") * zoom)
	local at = basis * Vector3.new(get(cfg, "LookRight") * zoom, get(cfg, "LookUp"), -get(cfg, "Ahead"))
	return CFrame.lookAt(from, at)
end

return ShoulderCam
