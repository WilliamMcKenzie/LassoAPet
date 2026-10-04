-- The exclusive animal event's countdown (Events.server): for the last
-- Config.Events.Countdown seconds before the event's animal spawns, the banner
-- top centre reads "<name> spawns in Ns...". Nothing else about events is
-- announced. (The animal itself and the guide arrows are Ride.client's.)

local RunService = game:GetService("RunService")

local Hud = require(script.Parent.Hud)

local world = workspace:WaitForChild("World")

RunService.Heartbeat:Connect(function()
	local kind = world:GetAttribute("EventKind") or ""
	local left = (world:GetAttribute("EventSpawnAt") or 0) - workspace:GetServerTimeNow()
	if kind ~= "" and left > 0 then
		Hud.setEventCountdown(kind, math.ceil(left))
	else
		Hud.setEventCountdown(nil)
	end
end)
