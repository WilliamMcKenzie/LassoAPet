-- The animals' low-poly meshes (QM, Oct 14; tools/bbmodel_to_luau.py --meshes): one MeshPart
-- per mesh in ReplicatedStorage.AnimalMeshes, named as its .obj, which Rig.luau copies (scripts
-- can't set MeshId, so the game can't make them itself). Needed in every Place an animal can
-- show up in (pets travel between worlds). Rerunnable: run in the command bar after filling IDS.
--
-- To fill IDS: upload each assets/meshes/<Kind>/<Name>.obj (Asset Manager > Bulk Import, or
-- Import 3D: units studs, no rig, keep the name) and put its mesh asset id next to its name.
local AssetService = game:GetService("AssetService")
local IDS = {
	ToadstoolFrog_Belly_neck = 0,
	ToadstoolFrog_Belly_root = 0,
	ToadstoolFrog_Cap_neck = 0,
	ToadstoolFrog_Capdark_neck = 0,
	ToadstoolFrog_Gill_neck = 0,
	ToadstoolFrog_Green_LegFL = 0,
	ToadstoolFrog_Green_LegFR = 0,
	ToadstoolFrog_Green_LegHL = 0,
	ToadstoolFrog_Green_LegHR = 0,
	ToadstoolFrog_Green_neck = 0,
	ToadstoolFrog_Green_root = 0,
	ToadstoolFrog_Greendark_neck = 0,
	ToadstoolFrog_Greendark_root = 0,
	ToadstoolFrog_Mouth_neck = 0,
	ToadstoolFrog_Spot_neck = 0,
	ToadstoolFrog_Toe_LegFL = 0,
	ToadstoolFrog_Toe_LegFR = 0,
	ToadstoolFrog_Toe_LegHL = 0,
	ToadstoolFrog_Toe_LegHR = 0,
	ToadstoolFrog_Tongue_neck = 0,
}
local folder = game.ReplicatedStorage:FindFirstChild("AnimalMeshes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AnimalMeshes"
	folder.Parent = game.ReplicatedStorage
end
for name, id in IDS do
	if id == 0 then
		continue
	end
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. id), {
			CollisionFidelity = Enum.CollisionFidelity.Box,
		})
	end)
	if not ok then
		warn(name, part)
		continue
	end
	local old = folder:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.DoubleSided = false
	part.Parent = folder
end
print(#folder:GetChildren(), "animal meshes")
