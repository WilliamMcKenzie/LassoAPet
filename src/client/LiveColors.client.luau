-- Repaints the map locally when World colour attributes are edited from the
-- client view in Studio (see Shared.WorldColors).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local world = workspace:WaitForChild("World")
while not world:GetAttribute("Ready") do
	world:GetAttributeChangedSignal("Ready"):Wait()
end
require(ReplicatedStorage.Shared.WorldColors).watch(world)
