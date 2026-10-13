-- Buying a world (the Worlds menu's Buy, World 1's World 2 bar: QM, Oct 13). In World 1,
-- buying World 2 plays its unlock cutscene: every bit of UI goes, the camera flies in to
-- the base's portal gate, its swirl (hidden till now: PortalFx's HideSwirl) fades in, and
-- the camera flies back. Then "GuideTravel" is set: the arrows to the gate
-- (World2Bar.client) and the tap hand on World 2's Travel (WorldsMenu) till you go.
--   WorldUnlock.buy(world, [bought]) -- true if it went through; bought() runs first, before the cutscene
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WorldUnlock = {}
local busy = false

local function gate()
	local decor = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("BaseDecor")
	return decor and decor:FindFirstChild("PortalGate")
end

-- The camera from a to b (CFrames) over time, eased.
local function fly(a, b, time)
	local t = 0
	while t < time do
		t += RunService.RenderStepped:Wait()
		local u = math.clamp(t / time, 0, 1)
		u = u * u * (3 - 2 * u)
		camera.CFrame = a:Lerp(b, u)
	end
end

local function cutscene(portal)
	player:SetAttribute("Cutscene", true)
	local hidden = {}
	local function hideAll()
		for _, g in player.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "WorldsMenu" then -- (the menu closes itself)
				g.Enabled = false
				if not table.find(hidden, g) then
					table.insert(hidden, g)
				end
			end
		end
	end
	hideAll()
	local holdHidden = RunService.RenderStepped:Connect(hideAll) -- (some of it turns itself back on)
	local ok, controls = pcall(function()
		return require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	end)
	controls = ok and controls or nil
	if controls then
		controls:Disable()
	end
	-- In front of the gate's opening, on your side of it.
	local S = portal:GetScale()
	local pivot = portal:GetPivot()
	local centre = (pivot * CFrame.new(0, (2.8 + 11) * S, 0)).Position
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local side = pivot.LookVector
	if root and (root.Position - centre):Dot(side) < 0 then
		side = -side
	end
	local view = CFrame.lookAt(centre + side * 30 * S + Vector3.new(0, 2 * S, 0), centre)
	local was, wasType = camera.CFrame, camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	fly(was, view, 1.6)
	portal:SetAttribute("HideSwirl", nil) -- (it fades in: PortalFx)
	local t = 0
	while t < 2.8 do -- (holds, creeping in)
		t += RunService.RenderStepped:Wait()
		camera.CFrame = view * CFrame.new(0, 0, -t * 1.2)
	end
	fly(camera.CFrame, was, 1.1)
	camera.CameraType = wasType
	if controls then
		controls:Enable()
	end
	holdHidden:Disconnect()
	for _, g in hidden do
		g.Enabled = true
	end
	player:SetAttribute("Cutscene", nil)
	player:SetAttribute("GuideTravel", true)
end

function WorldUnlock.buy(world, bought)
	if busy then
		return false
	end
	busy = true
	local portal = if world == 2 and Config.World == 1 then gate() else nil
	if portal then
		portal:SetAttribute("HideSwirl", true) -- (it stays rock till the cutscene shows it)
	end
	local ok, done = pcall(ReplicatedStorage.BuyWorld.InvokeServer, ReplicatedStorage.BuyWorld, world)
	done = ok and done == true
	if not done then
		if portal then
			portal:SetAttribute("HideSwirl", nil)
		end
		busy = false
		return false
	end
	if bought then
		bought()
	end
	if portal then
		task.spawn(function()
			cutscene(portal)
			busy = false
		end)
	else
		busy = false
	end
	return true
end

return WorldUnlock
