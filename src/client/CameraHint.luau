-- The camera flies up and over to look at something, holds, and flies back (the
-- tutorial's zoom to the Desert's gate; the quests' hints: QM, Oct 11). The base UI
-- hides meanwhile ("Cutscene"). One at a time.
--   CameraHint.show(look, from, [inTime, hold, outTime]) -- look: the point; from: the camera's offset from it
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraHint = {}
local busy = false

function CameraHint.show(look, from, inTime, hold, outTime)
	if busy then
		return
	end
	busy = true
	local view = CFrame.lookAt(look + from, look)
	local was, wasType = camera.CFrame, camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	player:SetAttribute("Cutscene", true)
	local high = was + Vector3.new(0, 60, 0)
	local function fly(a, b, c, time)
		local t = 0
		while t < time do
			t += RunService.RenderStepped:Wait()
			local u = math.clamp(t / time, 0, 1)
			u = u * u * (3 - 2 * u)
			local p = a.Position:Lerp(b.Position, u):Lerp(b.Position:Lerp(c.Position, u), u)
			camera.CFrame = CFrame.new(p) * a.Rotation:Lerp(c.Rotation, u)
		end
	end
	fly(was, high, view, inTime or 0.8)
	task.wait(hold or 1.25)
	fly(view, high, was, outTime or 0.65)
	camera.CameraType = wasType
	player:SetAttribute("Cutscene", nil)
	busy = false
end

return CameraHint
