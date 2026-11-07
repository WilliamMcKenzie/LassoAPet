-- A pet's still picture as a ViewportFrame: its model, mid-gallop, from the headshot's camera
-- (tools/pet_headshots.py, "action"), framed to just what shows. Moved here from the Fuse
-- menu's still3D, as it was, so the Index can show pets without an uploaded headshot.
--
--   PetStill.view(kind, fuse) -> ViewportFrame, or nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)

local Animals = ReplicatedStorage.Shared.Animals

local PetStill = {}

-- The headshot's camera (tools/pet_headshots.py, "action"): 3/4 front from a little
-- above, mid-gallop (the Snake and Starfish in their idle stance).
local YAW, PITCH, FOV = math.rad(35), math.rad(12), 26
local FACING = { Kraken = math.pi }
local ACTION_IDLE = { Snake = true, Starfish = true }

-- A pet standing still in 3D, as it is: drawn once, never redrawn (QM: unanimated).
function PetStill.view(kind, fuse)
	local module = Animals:FindFirstChild(kind)
	local ok, animal = pcall(function()
		return require(module).new()
	end)
	if not ok or not animal then
		return nil
	end
	animal:setSaddled(false)
	Fusion.paint(animal.model, kind, fuse)
	local gallop = animal.data and animal.data.animations and animal.data.animations.gallop
	if gallop and not ACTION_IDLE[kind] then
		animal.speed, animal.clocks.gallop = 1000, gallop.length * 0.35
		pcall(animal.update, animal, 0, 1000, 0)
	else
		pcall(animal.update, animal, 0, 0, 0)
	end
	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-1, -2, -1)
	local world = Instance.new("WorldModel") -- (it places the posed parts on their joints)
	world.Parent = view
	animal.model:PivotTo(CFrame.new())
	animal.model.Parent = world
	local box, extents = animal.model:GetBoundingBox()
	local yaw = YAW + (FACING[kind] or 0)
	local dir = Vector3.new(-math.sin(yaw) * math.cos(PITCH), math.sin(PITCH), -math.cos(yaw) * math.cos(PITCH))
	local radius = extents.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = FOV
	cam.CFrame = CFrame.lookAt(box.Position + dir * radius / math.sin(math.rad(FOV) / 2) * 0.95, box.Position)
	cam.Parent = view
	view.CurrentCamera = cam
	-- Once the WorldModel has put the posed parts on their joints (a frame on), frame
	-- just what shows, as seen from the camera, so the pet sits in the middle (QM).
	task.spawn(function()
		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()
		if not view.Parent then
			return
		end
		local look = CFrame.lookAt(dir, Vector3.zero)
		local right, up, back = look.RightVector, look.UpVector, -look.LookVector
		local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
		local points = {}
		for _, part in animal.model:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then
				local half = part.Size / 2
				for _, corner in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
					local p = part.CFrame:PointToWorldSpace(half * corner) - box.Position
					local x, y = p:Dot(right), p:Dot(up)
					minX, maxX, minY, maxY = math.min(minX, x), math.max(maxX, x), math.min(minY, y), math.max(maxY, y)
					table.insert(points, Vector3.new(x, y, p:Dot(back)))
				end
			end
		end
		if #points == 0 then
			return
		end
		local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
		local tan = math.tan(math.rad(FOV) / 2)
		local distance = 0
		for _, p in points do -- far enough back that every corner is in view
			distance = math.max(distance, math.max(math.abs(p.X - cx), math.abs(p.Y - cy)) / tan + p.Z)
		end
		local middle = box.Position + right * cx + up * cy
		cam.CFrame = CFrame.lookAt(middle + back * distance * 1.06, middle)
	end)
	return view
end

return PetStill
