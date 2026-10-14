-- The animals' low-poly meshes (QM, Oct 14; tools/bbmodel_to_luau.py --meshes): one MeshPart
-- per mesh in ReplicatedStorage.AnimalMeshes, named as its .obj, which Rig.luau copies (scripts
-- can't set MeshId, so the game can't make them itself). Needed in every Place an animal can
-- show up in (pets travel between worlds). Rerunnable: run in the command bar after filling IDS.
--
-- To fill IDS: upload each assets/meshes/<Kind>/<Name>.obj (Asset Manager > Bulk Import, or
-- Import 3D: units studs, no rig, keep the name) and put its mesh asset id next to its name.
local AssetService = game:GetService("AssetService")
local IDS = {
	ToadstoolFrog_Cap_neck = 80583789207097,
	ToadstoolFrog_Gill_neck = 90637008093060,
	ToadstoolFrog_Spot_neck = 80302708979871,
	GreenCrab_Red_root = 0, -- (the Green Crab's carapace, QM Oct 14)
	GreenCrab_Red_ClawL = 0, -- (its claws' tops)
	GreenCrab_Red_ClawR = 0,
	TreasureHermit_Crab_neck = 0, -- (the Treasure Hermit's head and claw tops, like the Green Crab's: QM Oct 14)
	TreasureHermit_Crab_ClawL = 0,
	TreasureHermit_Crab_ClawR = 0,
	TreasureTurtle_Shell_root = 0, -- (the Treasure Turtle's shell, one smooth mesh: QM Oct 14)
	GhostShip_Deck_root = 0, -- (the Ghost Ship, on the pirate ship prop: QM Oct 14)
	GhostShip_Flag_Flag = 0,
	GhostShip_Flag_root = 0,
	GhostShip_Gold_root = 0,
	GhostShip_Hull_root = 0,
	GhostShip_Hulldark_Jaw = 0,
	GhostShip_Mast_root = 0,
	GhostShip_Rail_root = 0,
	GhostShip_Sail_SailF = 0,
	GhostShip_Sail_SailM = 0,
	GhostShip_Sail_root = 0,
	GhostShip_White_Flag = 0,
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
