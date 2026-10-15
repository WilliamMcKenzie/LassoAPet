-- The animals' low-poly meshes (QM, Oct 14; tools/bbmodel_to_luau.py --meshes): one MeshPart
-- per mesh in ReplicatedStorage.AnimalMeshes, named as its .obj, which Rig.luau copies (scripts
-- can't set MeshId, so the game can't make them itself). Needed in every Place an animal can
-- show up in (pets travel between worlds). Rerunnable: run in the command bar after filling IDS.
--
-- To fill IDS: upload each assets/meshes/<Kind>/<Name>.obj (Asset Manager > Bulk Import, or
-- Import 3D: units studs, no rig, keep the name) and put its mesh asset id next to its name.
local AssetService = game:GetService("AssetService")
local IDS = {
	ToadstoolFrog_Cap_neck = 113676246756247, -- (re-upload: QM's Blockbench edit, Oct 15)
	ToadstoolFrog_Gill_neck = 118811291987440, -- (re-upload: QM's Blockbench edit, Oct 15)
	ToadstoolFrog_Spot_neck = 101087756608521, -- (re-upload: QM's Blockbench edit, Oct 15)
	GreenCrab_Red_root = 129403060148775, -- (the Green Crab's carapace, QM Oct 14)
	GreenCrab_Red_ClawL = 86915530155881, -- (its claws' tops)
	GreenCrab_Red_ClawR = 88608798113715,
	TreasureHermit_Crab_neck = 90664321484638, -- (the Treasure Hermit's head and claw tops, like the Green Crab's: QM Oct 14)
	TreasureHermit_Crab_ClawL = 100973532077609,
	TreasureHermit_Crab_ClawR = 94863051921521,
	TreasureTurtle_Shell_root = 134661861738303, -- (the Treasure Turtle's shell, one smooth mesh: QM Oct 14)
	TreasureTurtle_Sanddark_root = 78623906471175, -- (the sand island dome on its shell, QM Oct 14)
	GhostShip_Deck_root = 139059304610733, -- (the Ghost Ship, on the pirate ship prop: QM Oct 14)
	GhostShip_Flag_Flag = 91677109949137,
	GhostShip_Flag_root = 112054783839535,
	GhostShip_Gold_root = 70583742678210,
	GhostShip_Hull_root = 97435701886321,
	GhostShip_Mast_root = 113933522114883,
	GhostShip_Rail_root = 89259235330850,
	GhostShip_Sail_SailF = 139005826343219,
	GhostShip_Sail_SailM = 101983046030341,
	GhostShip_Sail_root = 107969410845724,
	GhostShip_White_Flag = 74100158036798,
	Ladybug_Black_ShellL = 85921473817669, -- (re-upload: QM's Blockbench edit, Oct 15; the Ladybug shell and the Bumblebee body and wings, QM Oct 14)
	Ladybug_Black_ShellR = 98752802337169, -- (re-upload: QM's Blockbench edit, Oct 15)
	Ladybug_Red_ShellL = 103177915144410, -- (re-upload: QM's Blockbench edit, Oct 15)
	Ladybug_Red_ShellR = 110848259912731, -- (re-upload: QM's Blockbench edit, Oct 15)
	Bumblebee_Black_Abdomen = 88744261457751,
	Bumblebee_Black_root = 114671736332286,
	Bumblebee_Wing_WingBL = 126428174511432, -- (re-upload: QM's Blockbench edit, Oct 15)
	Bumblebee_Wing_WingBR = 124395339512885, -- (re-upload: QM's Blockbench edit, Oct 15)
	Bumblebee_Wing_WingFL = 126854557968209, -- (re-upload: QM's Blockbench edit, Oct 15)
	Bumblebee_Wing_WingFR = 76404368724892, -- (re-upload: QM's Blockbench edit, Oct 15)
	Bumblebee_Yellow_Abdomen = 79819704203552,
	Bumblebee_Yellow_root = 73623092957303,
	VineMonster_Leaf_LeavesL = 132839468011196, -- (the Vine Monster: QM's Blockbench edit, Oct 15)
	VineMonster_Leaf_LeavesR = 102753960814800,
	VineMonster_Rose_Rose = 139718791105732,
	VineMonster_Rosedark_Rose = 101570267675570,
	VineMonster_Vinelight_VineL = 103130234470918,
	VineMonster_Vinelight_VineR = 115011483764524,
	SunflowerLion_Leaf_LegFL = 0, -- (the Sunflower Lion: QM's Blockbench edit, Oct 15)
	SunflowerLion_Leaf_LegFR = 0,
	SunflowerLion_Leaf_LegHL = 0,
	SunflowerLion_Leaf_LegHR = 0,
	SunflowerLion_Leafdark_Tail = 0,
	SunflowerLion_Petal_Mane = 0,
	SunflowerLion_Petal_Tail = 0,
	SunflowerLion_Petaldark_Mane = 0,
	SunflowerLion_Petaldark_Tail = 0,
	SunflowerLion_Seed_Mane = 0,
	SunflowerLion_Seed_Tail = 0,
	SunflowerLion_Seeddark_Mane = 0,
	SunflowerLion_Seeddark_Tail = 0,
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
