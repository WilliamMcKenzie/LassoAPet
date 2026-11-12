-- Studs as a material on the map (Config.StudMaterial, Shared/Studs): this client's
-- copy of the course swaps its stud Textures for the stud MaterialVariant, a slice
-- at a time so loading in doesn't stall. The ground keeps its studded checker.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Studs = require(ReplicatedStorage.Shared.Studs)

local PER_SLICE = 2000

if Studs.variant(0.5) or Studs.variant(1) then
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local n = 0
	for _, part in workspace:WaitForChild("World"):GetDescendants() do
		if part:IsA("BasePart") then
			Studs.convert(part)
			n += 1
			if n % PER_SLICE == 0 then
				task.wait()
			end
		end
	end
end
