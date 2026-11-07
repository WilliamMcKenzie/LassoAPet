-- Map meshes some animals wear (QM, Nov 7: the Hillback Tortoise's tree is the map's tall pine):
-- each piece's MeshPart copied from ServerStorage.WorldAssets.<item> into
-- ReplicatedStorage.AnimalMeshes as <item>_<piece>, where Rig.luau looks for an animal's meshes.
-- Copied at server start, so they need no upload of their own.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local COPIES = {
	PineTall = { "Trunk", "Tier1", "Tier2", "Tier3", "Tier4" }, -- (the Hillback Tortoise's tree)
}

local assets = ServerStorage:FindFirstChild("WorldAssets")
local folder = ReplicatedStorage:FindFirstChild("AnimalMeshes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AnimalMeshes"
	folder.Parent = ReplicatedStorage
end
for item, pieces in COPIES do
	local model = assets and assets:FindFirstChild(item)
	for _, piece in pieces do
		local name = item .. "_" .. piece
		local source = model and model:FindFirstChild(piece)
		if folder:FindFirstChild(name) then
			continue
		elseif source and source:IsA("MeshPart") then
			local copy = source:Clone()
			copy:ClearAllChildren()
			copy.Name = name
			copy.Anchored = true
			copy.Parent = folder
		else
			warn("AnimalMeshCopies: no MeshPart " .. piece .. " in ServerStorage.WorldAssets." .. item)
		end
	end
end
