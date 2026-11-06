-- Builds the map (Server/Map: the base, then one straight walled corridor through the
-- biomes), turns on the live colour attributes (Shared/WorldColors) and marks the world
-- ready. The sky and fog are Lighting's, in default.project.json.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Map = require(script.Parent.Map)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local world = Map.build()
WorldColors.watch(world)
world:SetAttribute("Ready", true)
