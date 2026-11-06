-- The live world colours (Shared/WorldColors): repaints the map whenever one of
-- workspace.WorldColors' attributes changes (tune them in Play, in the Client view).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.WorldColors).watch()
