-- World 2's prop assets (QM, Oct 13; design/crimson, crystals, birches, sword_stone): one
-- Model per item in ServerStorage.World2Assets, one MeshPart per piece at the item's origin
-- (the middle of its base, y = 0), at the .obj's size, studded; the pivot is that origin.
-- tools/world2_props.luau (the Level design thread's) clones them into the world. Runes glow
-- (Neon). Re-running rebuilds them all.
local AssetService = game:GetService("AssetService")
local ITEMS = {
	BirchLean = {{ 1, 118974268226290, "Trunk", 238, 234, 226 }, { 2, 109543604875393, "Marks", 52, 46, 44 }, { 3, 133214842004722, "Leaves", 214, 72, 43 }, { 4, 134458368038840, "Leaves", 242, 109, 57 }, { 5, 110548204076678, "Leaves", 196, 58, 36 }},
	BirchSmall = {{ 1, 96025683908109, "Trunk", 238, 234, 226 }, { 2, 125364007737630, "Marks", 52, 46, 44 }, { 3, 102813774278109, "Leaves", 242, 109, 57 }, { 4, 72728731312569, "Leaves", 254, 234, 92 }, { 5, 73493856631074, "Leaves", 248, 168, 64 }},
	BirchTall = {{ 1, 91604322386174, "Trunk", 238, 234, 226 }, { 2, 100305573536472, "Marks", 52, 46, 44 }, { 3, 113925729682375, "Leaves", 254, 234, 92 }, { 4, 73269697056598, "Leaves", 250, 214, 70 }, { 5, 101778457283668, "Leaves", 255, 240, 120 }},
	BirchTwin = {{ 1, 128690718469805, "Trunk", 238, 234, 226 }, { 2, 77355180303272, "Marks", 52, 46, 44 }, { 3, 105851412349244, "Leaves", 242, 109, 57 }, { 4, 115051256817562, "Leaves", 246, 132, 72 }, { 5, 85465629565931, "Leaves", 224, 92, 46 }},
	CrimsonTuft = {{ 1, 114395846446715, "Strands", 217, 15, 44 }, { 2, 78857250172063, "Strands", 176, 12, 36 }},
	CrystalCyanLarge = {{ 1, 118283637628462, "Crystal", 0, 190, 231 }, { 2, 117990202835534, "Crystal", 90, 220, 245 }},
	CrystalCyanMedium = {{ 1, 82513204529097, "Crystal", 0, 190, 231 }, { 2, 106651690205509, "Crystal", 90, 220, 245 }},
	CrystalCyanXXL = {{ 1, 81112022302625, "Crystal", 0, 190, 231 }, { 2, 77273093830509, "Crystal", 90, 220, 245 }},
	CrystalPinkLarge = {{ 1, 137181112047030, "Crystal", 229, 131, 251 }, { 2, 75785266368599, "Crystal", 242, 170, 253 }},
	CrystalPinkMedium = {{ 1, 128842636670450, "Crystal", 229, 131, 251 }, { 2, 100714574410078, "Crystal", 242, 170, 253 }},
	CrystalPinkXXL = {{ 1, 94086630520529, "Crystal", 229, 131, 251 }, { 2, 94429983130943, "Crystal", 242, 170, 253 }},
	FungusCluster = {{ 1, 77656092345836, "Stem", 232, 220, 212 }, { 2, 98941970592621, "Cap", 134, 83, 142 }, { 3, 130409285074163, "Underside", 96, 59, 102 }, { 4, 120439572232646, "Spots", 250, 248, 252 }},
	FungusLarge = {{ 1, 109789854997273, "Stem", 232, 220, 212 }, { 2, 140363710566377, "Cap", 0, 190, 231 }, { 3, 131870366242518, "Underside", 0, 136, 166 }},
	FungusMedium = {{ 1, 119820839283227, "Stem", 232, 220, 212 }, { 2, 93828271326715, "Cap", 131, 98, 103 }, { 3, 119790743764909, "Underside", 94, 70, 74 }},
	MushroomGiant = {{ 1, 115074322784965, "Stem", 228, 172, 180 }, { 2, 99701108207377, "Cap", 217, 15, 44 }, { 3, 91132492184058, "Underside", 150, 10, 32 }},
	MushroomMedium = {{ 1, 94005266203475, "Stem", 228, 172, 180 }, { 2, 137951153401602, "Cap", 217, 15, 44 }, { 3, 70886908775061, "Underside", 150, 10, 32 }},
	MushroomSmall = {{ 1, 82216113216386, "Stem", 228, 172, 180 }, { 2, 120989610052288, "Cap", 217, 15, 44 }, { 3, 106119244343802, "Underside", 150, 10, 32 }},
	RuneBlock = {{ 1, 90478958459189, "Stone", 156, 124, 120 }, { 2, 101120574242401, "Chunk", 170, 138, 132 }, { 3, 121260807146407, "Runes", 255, 186, 60 }},
	RunestoneShort = {{ 1, 76425566347787, "Stone", 156, 124, 120 }, { 2, 111974434822198, "Cap", 140, 110, 106 }, { 3, 118815857600148, "Runes", 255, 186, 60 }},
	RunestoneTall = {{ 1, 89336867376900, "Stone", 156, 124, 120 }, { 2, 137946154144534, "Cap", 140, 110, 106 }, { 3, 139822247577148, "Runes", 255, 186, 60 }},
	SwordStone = {{ 1, 117918039589025, "Rock", 214, 196, 142 }, { 2, 92556836847130, "Rock", 196, 178, 126 }, { 3, 116200676311757, "Blade", 206, 214, 224 }, { 4, 77662760456357, "Guard", 232, 182, 58 }, { 5, 105597963152140, "Grip", 112, 72, 46 }, { 6, 90013430545752, "Pommel", 232, 182, 58 }},
}
local folder = game.ServerStorage:FindFirstChild("World2Assets") or Instance.new("Folder")
folder.Name = "World2Assets"
folder:ClearAllChildren()
local old = game.ServerStorage:FindFirstChild("World2Props") -- (its first name)
if old then
	old:Destroy()
end
local n = 0
for name, pieces in ITEMS do
	local m = Instance.new("Model")
	m.Name = name
	table.sort(pieces, function(a, b) return a[1] < b[1] end)
	for _, pc in pieces do
		local p = AssetService:CreateMeshPartAsync(Content.fromUri("rbxassetid://" .. pc[2]))
		p.Name = name .. "_" .. pc[1] .. "_" .. pc[3]
		p.Anchored = true
		p.CFrame = CFrame.new()
		p.Color = Color3.fromRGB(pc[4], pc[5], pc[6])
		if pc[3] == "Runes" then
			p.Material = Enum.Material.Neon
		else
			p.Material = Enum.Material.Glacier
			p.MaterialVariant = "Studs"
		end
		p.Parent = m
		n += 1
	end
	m.WorldPivot = CFrame.new()
	m.Parent = folder
end
folder.Parent = game.ServerStorage
return n .. " pieces in " .. #folder:GetChildren() .. " assets"
