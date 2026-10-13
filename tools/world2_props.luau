-- World 2's props (QM, Oct 13; design/crimson, design/crystals): one Model per item, one
-- MeshPart per piece at the item's origin (base at y = 0), studded. ServerStorage.World2Props,
-- for the Level design thread's scatter scripts to clone. Runes glow (Neon).
local AssetService = game:GetService("AssetService")
local ITEMS = {CrimsonTuft={{1,114395846446715,"Strands",217,15,44},{2,78857250172063,"Strands",176,12,36}},CrystalCyanLarge={{1,118283637628462,"Crystal",0,190,231},{2,117990202835534,"Crystal",90,220,245}},CrystalCyanMedium={{1,82513204529097,"Crystal",0,190,231},{2,106651690205509,"Crystal",90,220,245}},CrystalCyanXXL={{1,81112022302625,"Crystal",0,190,231},{2,77273093830509,"Crystal",90,220,245}},CrystalPinkLarge={{1,137181112047030,"Crystal",229,131,251},{2,75785266368599,"Crystal",242,170,253}},CrystalPinkMedium={{1,128842636670450,"Crystal",229,131,251},{2,100714574410078,"Crystal",242,170,253}},CrystalPinkXXL={{1,94086630520529,"Crystal",229,131,251},{2,94429983130943,"Crystal",242,170,253}},FungusCluster={{1,77656092345836,"Stem",232,220,212},{2,98941970592621,"Cap",134,83,142},{3,130409285074163,"Underside",96,59,102},{4,120439572232646,"Spots",250,248,252}},FungusLarge={{1,109789854997273,"Stem",232,220,212},{2,140363710566377,"Cap",0,190,231},{3,131870366242518,"Underside",0,136,166}},FungusMedium={{1,119820839283227,"Stem",232,220,212},{2,93828271326715,"Cap",131,98,103},{3,119790743764909,"Underside",94,70,74}},MushroomGiant={{1,115074322784965,"Stem",228,172,180},{2,99701108207377,"Cap",217,15,44},{3,91132492184058,"Underside",150,10,32}},MushroomMedium={{1,94005266203475,"Stem",228,172,180},{2,137951153401602,"Cap",217,15,44},{3,70886908775061,"Underside",150,10,32}},MushroomSmall={{1,82216113216386,"Stem",228,172,180},{2,120989610052288,"Cap",217,15,44},{3,106119244343802,"Underside",150,10,32}},RuneBlock={{1,90478958459189,"Stone",156,124,120},{2,101120574242401,"Chunk",170,138,132},{3,121260807146407,"Runes",255,186,60}},RunestoneShort={{1,76425566347787,"Stone",156,124,120},{2,111974434822198,"Cap",140,110,106},{3,118815857600148,"Runes",255,186,60}},RunestoneTall={{1,89336867376900,"Stone",156,124,120},{2,137946154144534,"Cap",140,110,106},{3,139822247577148,"Runes",255,186,60}}}
local folder = game.ServerStorage:FindFirstChild("World2Props") or Instance.new("Folder")
folder.Name = "World2Props"
folder:ClearAllChildren()
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
return n .. " pieces in " .. #folder:GetChildren() .. " props"
