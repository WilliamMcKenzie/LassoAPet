-- Analytics V1 (Telemetry on the server): tells the server the game's loaded here, and what
-- it's played on (phone, tablet, console or pc), for /stats' startup and device numbers.
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function device()
	if GuiService:IsTenFootInterface() then
		return "console"
	elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local size = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(0, 0)
		return if math.min(size.X, size.Y) >= 600 then "tablet" else "phone"
	end
	return "pc"
end

local telemetry = ReplicatedStorage:WaitForChild("Telemetry", 60)
if telemetry then
	telemetry:FireServer("ready", device())
end
