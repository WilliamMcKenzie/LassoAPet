-- The map (Server/Map: Fight to Steal an Egg's, from the map editor's maps/world.map): the one
-- baked into the place in Studio, or built now if there's none. Then the live colours
-- (workspace.WorldColors, Shared/WorldColors) and the studs' knobs (workspace.StudStyle),
-- and the world's marked ready. The sky and fog are Lighting's, in default.project.json.
-- Sky: the Creator Store "Anime sky" (asset 13107361022), QM Nov 7; was flat blue 81588505365795.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- (the pet lineup is for sizing animals in Studio's Edit mode, Shared/PetLineup: not in the
-- game, where it would stand in the stampede; workspace.PetScale stays, the animals' sizes)
local lineup = workspace:FindFirstChild("PetLineup")
if lineup then
	lineup:Destroy()
end

local Map = require(script.Parent.Map)
local StudStyle = require(ReplicatedStorage.Shared.StudStyle)
local WorldColors = require(ReplicatedStorage.Shared.WorldColors)

local baked = workspace:FindFirstChild("World")
baked = baked and baked:GetAttribute("Baked")
local world = Map.ensure()
StudStyle.ensure()
if not baked then
	StudStyle.applyAll() -- (a map built just now: its studs to workspace.StudStyle's knobs)
end
WorldColors.create() -- (after the map: it paints it)
world:SetAttribute("Ready", true)
