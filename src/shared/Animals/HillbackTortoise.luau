-- Hillback Tortoise: World 1 Meadow's Legendary titan (QM, Nov 7: one of the luck-padding animals
-- QM picked), a giant tortoise with a grassy hill on its shell and the map's tall pine growing
-- on it (QM: "an actual tree mesh"). Model from tools/filler_meadow.py, rigged by
-- tools/filler_export.py (which writes this file) into HillbackTortoiseModel.luau. The pine's
-- MeshParts come from ReplicatedStorage.AnimalMeshes (Server/AnimalMeshCopies copies them from
-- the map's ServerStorage.WorldAssets.PineTall).

local Horse = require(script.Parent.Horse)
local HillbackTortoiseModel = require(script.Parent.HillbackTortoiseModel)

local PINE = {
	{ name = "PineTrunk", bone = "root", class = "Part", size = Vector3.new(0.57, 3.72, 0.57), cframe = CFrame.new(0, 9.44, 0.42), color = Color3.fromRGB(120, 84, 58) },
	{ name = "PineTier1", bone = "root", class = "MeshPart", mesh = "PineTall_Tier1", size = Vector3.new(3, 2.22, 3.08), cframe = CFrame.new(-0.13, 10.31, 0.43), color = Color3.fromRGB(46, 125, 80) },
	{ name = "PineTier2", bone = "root", class = "MeshPart", mesh = "PineTall_Tier2", size = Vector3.new(2.71, 2.2, 2.68), cframe = CFrame.new(-0.14, 11.19, 0.47), color = Color3.fromRGB(58, 140, 88) },
	{ name = "PineTier3", bone = "root", class = "MeshPart", mesh = "PineTall_Tier3", size = Vector3.new(2.1, 2.22, 2.16), cframe = CFrame.new(0.04, 12.05, 0.43), color = Color3.fromRGB(40, 112, 72) },
	{ name = "PineTier4", bone = "root", class = "MeshPart", mesh = "PineTall_Tier4", size = Vector3.new(1.75, 2.06, 1.64), cframe = CFrame.new(-0.01, 12.85, 0.45), color = Color3.fromRGB(66, 150, 96) },
}

local data = table.clone(HillbackTortoiseModel)
data.parts = table.clone(HillbackTortoiseModel.parts)
for _, part in PINE do
	table.insert(data.parts, part)
end

return Horse.variant("HillbackTortoise", data, "Legendary", {
	seat = Vector3.new(0, 7.14, -2.1),
	neck = { center = Vector3.new(0, 4.41, -6.09), radius = 1.49 },
})
