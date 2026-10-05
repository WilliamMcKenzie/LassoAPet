-- On foot you can't walk past the start line into the stampede (QM, Oct 5): your
-- character is held at the line, and while you push against it the HUD says
-- "Return to your base to ride an animal!" where the event countdown goes. Riders
-- aren't touched: a rider's root is anchored to the mount (Ride.client), and a
-- character lying on the course after a fall, or far out past the line, is left
-- alone. Only your own character is held, on your client: no wall, nothing a
-- rider could hit.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local world = workspace:WaitForChild("World")

local LIMIT = if world:FindFirstChild("StartLine") then world.StartLine:GetBoundingBox().Position.Z else -2 -- (Ride.client's START_LINE_Z)
local BAND = 40 -- studs past the line still held back (anyone further out got there some other way)
local LINGER = 0.5 -- seconds the notice stays after the last push
local TEXT = "Return to your base to ride an animal!"

local lastPush = -math.huge

RunService.PreSimulation:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and not root.Anchored and not humanoid.Sit and not humanoid.PlatformStand
		and humanoid.Health > 0 then
		local z = root.Position.Z
		if z < LIMIT and z > LIMIT - BAND then
			root.CFrame += Vector3.new(0, 0, LIMIT - z)
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, math.max(v.Z, 0))
			lastPush = os.clock()
		end
	end
	Hud.setNotice(if os.clock() - lastPush < LINGER then TEXT else nil)
end)
