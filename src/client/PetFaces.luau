-- Pet pictures: each pet's headshot (assets/ui/Pet<Kind>.png, tools/pet_headshots.py),
-- as the animal dictionary (AnimalDex) shows them.
--
--   PetFaces.HEADSHOTS[kind]       -- the headshot's image id ("" if not uploaded)

local PetFaces = {}

-- Headshots rendered from each pet's model; "" until uploaded.
local HEADSHOTS = {
	Horse = "rbxassetid://129206679931938", -- PetHorse.png
	Pinto = "rbxassetid://137788325926698", -- PetPinto.png
	Pig = "rbxassetid://126771183103796", -- PetPig.png
	Bunny = "rbxassetid://77770407898290", -- PetBunny.png
	Fish = "rbxassetid://73704828076245", -- PetFish.png
	Rhino = "rbxassetid://135065306024440", -- PetRhino.png
	MarbleColossus = "rbxassetid://108907184921325", -- PetMarbleColossus.png (World 2)
	CrystalCentipede = "rbxassetid://104988827630449", -- PetCrystalCentipede.png (World 2)
	MajesticUnicorn = "rbxassetid://130282330232819", -- PetMajesticUnicorn.png (World 2)
	RedMushroom = "rbxassetid://124374143045410", -- PetRedMushroom.png (World 2)
	BrownMushroom = "rbxassetid://130801596510368", -- PetBrownMushroom.png (World 2)
	PurpleMushroom = "rbxassetid://138212580504024", -- PetPurpleMushroom.png (World 2)
	MarbleFish = "rbxassetid://116976247481915", -- PetMarbleFish.png (World 2)
	BlueCrystal = "rbxassetid://98660783250158", -- PetBlueCrystal.png (World 2)
	PinkCrystal = "rbxassetid://81727302148573", -- PetPinkCrystal.png (World 2)
	Lion = "rbxassetid://88231046504339", -- PetLion.png (World 2: QM's edit)
	Buffalo = "rbxassetid://76004844910290", -- PetBuffalo.png (World 2)
	Crocodile = "rbxassetid://98539038654284", -- PetCrocodile.png (World 2)
	Eyeworm = "rbxassetid://130020402774350", -- PetEyeworm.png (World 2)
	Maw = "rbxassetid://116932906016084", -- PetMaw.png (World 2)
	IvorySpider = "rbxassetid://122315330787047", -- PetIvorySpider.png (World 2)
	Asura = "rbxassetid://76139030639613", -- PetAsura.png (World 2: the white blade)
	CrimsonScorpion = "rbxassetid://138705038863318", -- PetCrimsonScorpion.png (World 2)
	CrystalPhoenix = "rbxassetid://91347373015350", -- PetCrystalPhoenix.png (World 2)
	CrystalElephant = "rbxassetid://126713751536950", -- PetCrystalElephant.png (World 2)
	Seraph = "rbxassetid://86322926031259", -- PetSeraph.png (World 2)
	CrimsonSeraph = "rbxassetid://104704985706188", -- PetCrimsonSeraph.png (World 2)
	CrystalSeraph = "rbxassetid://127357727820671", -- PetCrystalSeraph.png (World 2)
	CrystalSpider = "rbxassetid://123636538923577", -- PetCrystalSpider.png (World 2)
	Unicorn = "rbxassetid://123940745305285", -- PetUnicorn.png
	Cactus = "rbxassetid://95422181220957", -- PetCactus.png
	Kitten = "rbxassetid://85779463172831", -- PetKitten.png
	Scorpion = "rbxassetid://85451012004987", -- PetScorpion.png
	Sandworm = "rbxassetid://122144649250110", -- PetSandworm.png
	Snake = "rbxassetid://91376372256857", -- PetSnake.png
	Beholder = "rbxassetid://122284072508208", -- PetBeholder.png
	Penguin = "rbxassetid://126516601606999", -- PetPenguin.png
	Snowman = "rbxassetid://131420314948529", -- PetSnowman.png
	SpineLizard = "rbxassetid://88911086754037", -- PetSpineLizard.png
	Boar = "rbxassetid://110647985191783", -- PetBoar.png
	IceGolem = "rbxassetid://97270712812416", -- PetIceGolem.png
	SnackYak = "rbxassetid://94992992543344", -- PetSnackYak.png
	Icebringer = "rbxassetid://76507499572286", -- PetIcebringer.png
	Kraken = "rbxassetid://97706370740023", -- PetKraken.png
	Squid = "rbxassetid://114559155845756", -- PetSquid.png
	Whale = "rbxassetid://109306533952798", -- PetWhale.png
	KingCrab = "rbxassetid://131403632828209", -- PetKingCrab.png
	BlueCrab = "rbxassetid://122498091168554", -- PetBlueCrab.png
	RoboShark = "rbxassetid://115675656988340", -- PetRoboShark.png
	VolcanoTortoise = "rbxassetid://135342979510615", -- PetVolcanoTortoise.png
	Firebird = "rbxassetid://95424707176181", -- PetFirebird.png
	RockHog = "rbxassetid://127855796399644", -- PetRockHog.png
	Rockworm = "rbxassetid://99218772198712", -- PetRockworm.png
	FireLobster = "rbxassetid://140546571870649", -- PetFireLobster.png
	LavaWhale = "rbxassetid://119751520536740", -- PetLavaWhale.png
	TRex = "rbxassetid://138666035263738", -- PetTRex.png
	Raptor = "rbxassetid://108946547828595", -- PetRaptor.png
	Spinosaurus = "rbxassetid://80632533990002", -- PetSpinosaurus.png
	Pterodactyl = "rbxassetid://103216213990752", -- PetPterodactyl.png
	Ankylosaurus = "rbxassetid://77760703895296", -- PetAnkylosaurus.png
	PalmGuy = "rbxassetid://71574733885552", -- PetPalmGuy.png
	BoneRex = "rbxassetid://109967588707999", -- PetBoneRex.png
	Phoenix = "rbxassetid://86265592768260", -- PetPhoenix.png
	Starfish = "rbxassetid://112526271674778", -- PetStarfish.png
	Lionfish = "rbxassetid://110158665076562", -- PetLionfish.png
	Clownfish = "rbxassetid://123616877831050", -- PetClownfish.png
	FishSchool = "rbxassetid://132126224577278", -- PetFishSchool.png
	Loong = "rbxassetid://110728718265049", -- PetLoong.png
	WarElephant = "rbxassetid://88035044263993", -- PetWarElephant.png
	SoulHorse = "rbxassetid://102872657938822", -- PetSoulHorse.png
	Sludge = "rbxassetid://119834887149656", -- PetSludge.png
	Leviathan = "rbxassetid://93677343741816", -- PetLeviathan.png
}

PetFaces.HEADSHOTS = HEADSHOTS

return PetFaces
