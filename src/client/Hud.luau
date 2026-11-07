-- Riding HUD built from QM's images: the Hold bar with the distance on it, one
-- action button (TAKE EGG or LASSO), a center message, and the home buttons
-- (RIDE, Gold, Pets, Upgrade Pen). Layout follows QM's mockups. Shop, over Roll,
-- opens the Robux shop (Shop); the gold icon itself does nothing (QM, Oct 5).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Inventory = require(script.Parent.Inventory)
local Sounds = require(script.Parent.Sounds)
local RewardPopups = require(script.Parent.RewardPopups)
local AnimalDex = require(script.Parent.AnimalDex)
local RollMenu = require(script.Parent.RollMenu)
local Shop = require(script.Parent.Shop)
local Gamepad = require(script.Parent.Gamepad)
local LowMemory = require(script.Parent.LowMemory)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
-- The new riding UI (QM, Oct 9): with Config.RideHud off, the ride's calls below go to it.
local RideUi = if Config.RideHud == false then require(script.Parent.RideUi) else nil

local Hud = {}

local FONT = Enum.Font.FredokaOne
local STROKE = 6
local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 72, 72)

-- Uploaded from QM's ui_assets; size is each image's native pixel size.
local IMAGES = {
	takeEgg = { id = "rbxassetid://104292931687556", size = Vector2.new(960, 434) },
	lasso = { id = "rbxassetid://94121512214531", size = Vector2.new(960, 358) },
	lassoDisabled = { id = "rbxassetid://83416502851504", size = Vector2.new(960, 358) },
	ride = { id = "rbxassetid://108897443176698", size = Vector2.new(960, 308) },
	merge = { id = "rbxassetid://134299381559519", size = Vector2.new(960, 308) }, -- MergePet.png
	home = { id = "rbxassetid://91332218189700", size = Vector2.new(960, 364) },
	continue = { id = "rbxassetid://124255755969598", size = Vector2.new(960, 308) }, -- Continue.png
	dodge = { id = "rbxassetid://96827860827213", size = Vector2.new(1423, 115) },
	sunburst = { id = "rbxassetid://130261551778736", size = Vector2.new(1995, 1996) }, -- white rays, behind TAKE EGG
	vignette = { id = "rbxassetid://102545209742676", size = Vector2.new(512, 512) }, -- white; clear to 60% out, full only in the corners
	buckedOff = { id = "rbxassetid://114839635512682", size = Vector2.new(1015, 300) },
	crash = { id = "rbxassetid://137889269113133", size = Vector2.new(632, 230) },
	barFilled = { id = "rbxassetid://82401653732533", size = Vector2.new(1292, 220) },
	barEmpty = { id = "rbxassetid://128272625286546", size = Vector2.new(1292, 220) },
	pets = { id = "rbxassetid://90844952883979", size = Vector2.new(254, 256) },
	fuseIcon = { id = "rbxassetid://126004469719414", size = Vector2.new(366, 289) }, -- MergeIcon.png (QM, Oct 7: Fuse is "Merge" to players): picks two pets to fuse (FuseMenu); "" shows a "Merge" label
	-- (With no id, the button is a plain outlined "Shop" label in the same spot.)
	shopIcon = { id = "rbxassetid://105477086117375", size = Vector2.new(256, 259) }, -- Shop.png: opens the Robux shop
	-- The roll menu's own art (RollMenu draws it; listed here so it's preloaded with the rest).
	rollMenu = { id = "rbxassetid://104698392936555", size = Vector2.new(2892, 1900) }, -- RollPanel.png
	rollMenuOdds = { id = "rbxassetid://110875946388838", size = Vector2.new(2892, 1900) }, -- RollPanelOdds.png
	rollButton = { id = "rbxassetid://112026122025466", size = Vector2.new(960, 378) }, -- RollButton.png
	eggs = { id = "rbxassetid://76827079745406", size = Vector2.new(264, 277) },
	coin = { id = "rbxassetid://99312860837685", size = Vector2.new(256, 256) },
	upgradePen = { id = "rbxassetid://120690804030353", size = Vector2.new(1152, 284) }, -- UpgradePenActive.png
	upgradePenDisabled = { id = "rbxassetid://134427342737800", size = Vector2.new(1158, 285) }, -- UpgradePenDisabled.png
	-- Each biome's own Upgrade Pen (Config.Biomes[i].UpgradeImage), all this size.
	upgradePenBiome = { id = "", size = Vector2.new(1024, 256) }, -- UpgradePenDesertEnabled.png etc. (QM, Oct 8)
	-- TAKE EGG for rarer eggs (takeEgg itself is the Uncommon one).
	takeEggRare = { id = "rbxassetid://137561422342054", size = Vector2.new(960, 434) },
	takeEggEpic = { id = "rbxassetid://114155984376753", size = Vector2.new(960, 434) },
	takeEggLegendary = { id = "rbxassetid://93889609154413", size = Vector2.new(960, 434) },
	sprint = { id = "rbxassetid://104509002348710", size = Vector2.new(618, 524) },
	ability = { id = "rbxassetid://95632395593874", size = Vector2.new(618, 524) }, -- Ability.png
	abilityCooldown = { id = "rbxassetid://86071723052223", size = Vector2.new(618, 524) }, -- AbilityCooldown.png
	-- The ready half while it's still filling up: always the one without [SPACE],
	-- even on a computer, where [SPACE] shows only once it's fully ready (QM).
	abilityFilling = { id = "rbxassetid://95632395593874", size = Vector2.new(618, 524) }, -- Ability.png
	-- The Egg Machine's ROLL button (QM's art to come; a green text button until then).
	roll = { id = "", size = Vector2.new(960, 308) }, -- Roll.png
	-- Egg renders for the reward popups, cropped to the egg (assets/ui/<Kind>EggRender.png).
	eggHorse = { id = "rbxassetid://96698232796495", size = Vector2.new(502, 799) }, -- HorseEggRender.png
	eggArmoredHorse = { id = "rbxassetid://96698232796495", size = Vector2.new(502, 799) }, -- the Horse's (QM, Oct 13)
	eggPinto = { id = "rbxassetid://79525419811481", size = Vector2.new(496, 788) }, -- PintoEggRender.png
	eggPig = { id = "rbxassetid://139970505549400", size = Vector2.new(496, 730) }, -- PigEggRender.png
	eggBunny = { id = "rbxassetid://102165948456968", size = Vector2.new(502, 920) }, -- BunnyEggRender.png
	eggFish = { id = "rbxassetid://105098230793344", size = Vector2.new(586, 810) }, -- FishEggRender.png
	eggRhino = { id = "rbxassetid://139482781062355", size = Vector2.new(496, 735) }, -- RhinoEggRender.png
	eggMarbleColossus = { id = "rbxassetid://110439659872687", size = Vector2.new(502, 825) }, -- MarbleColossusEggRender.png (World 2)
	eggCrystalCentipede = { id = "rbxassetid://101332917430774", size = Vector2.new(502, 846) }, -- CrystalCentipedeEggRender.png (World 2)
	eggMajesticUnicorn = { id = "rbxassetid://112045413530937", size = Vector2.new(502, 985) }, -- MajesticUnicornEggRender.png (World 2)
	eggRedMushroom = { id = "rbxassetid://102610484944753", size = Vector2.new(502, 675) }, -- RedMushroomEggRender.png (World 2)
	eggBrownMushroom = { id = "rbxassetid://84196239547123", size = Vector2.new(502, 668) }, -- BrownMushroomEggRender.png (World 2)
	eggPurpleMushroom = { id = "rbxassetid://132151928968903", size = Vector2.new(502, 675) }, -- PurpleMushroomEggRender.png (World 2)
	eggMarbleFish = { id = "rbxassetid://121162393893227", size = Vector2.new(593, 938) }, -- MarbleFishEggRender.png (World 2)
	eggBlueCrystal = { id = "rbxassetid://112194074349421", size = Vector2.new(502, 877) }, -- BlueCrystalEggRender.png (World 2)
	eggPinkCrystal = { id = "rbxassetid://117236752430565", size = Vector2.new(502, 877) }, -- PinkCrystalEggRender.png (World 2)
	eggLion = { id = "rbxassetid://82682007346790", size = Vector2.new(518, 720) }, -- LionEggRender.png (World 2)
	eggBuffalo = { id = "rbxassetid://118027620960011", size = Vector2.new(531, 713) }, -- BuffaloEggRender.png (World 2)
	eggCrocodile = { id = "rbxassetid://138455431560057", size = Vector2.new(506, 719) }, -- CrocodileEggRender.png (World 2)
	eggCrystalSpider = { id = "rbxassetid://98286776885826", size = Vector2.new(502, 856) }, -- CrystalSpiderEggRender.png (World 2)
	eggEyeworm = { id = "rbxassetid://132028611021169", size = Vector2.new(502, 779) }, -- EyewormEggRender.png (World 2)
	eggMaw = { id = "rbxassetid://121895939250438", size = Vector2.new(513, 668) }, -- MawEggRender.png (World 2)
	eggIvorySpider = { id = "rbxassetid://79662614434978", size = Vector2.new(556, 673) }, -- IvorySpiderEggRender.png (World 2)
	eggAsura = { id = "rbxassetid://113695299206853", size = Vector2.new(590, 982) }, -- AsuraEggRender.png (World 2)
	eggCrimsonScorpion = { id = "rbxassetid://126802958042799", size = Vector2.new(599, 770) }, -- CrimsonScorpionEggRender.png (World 2)
	eggCrystalPhoenix = { id = "rbxassetid://137731947260447", size = Vector2.new(941, 1000) }, -- CrystalPhoenixEggRender.png (World 2)
	eggCrystalElephant = { id = "rbxassetid://105220500829443", size = Vector2.new(650, 911) }, -- CrystalElephantEggRender.png (World 2)
	eggSeraph = { id = "rbxassetid://129763838096024", size = Vector2.new(700, 760) }, -- SeraphEggRender.png (World 2)
	eggCrimsonSeraph = { id = "rbxassetid://132120882288488", size = Vector2.new(700, 760) }, -- CrimsonSeraphEggRender.png (World 2)
	eggCrystalSeraph = { id = "rbxassetid://100476636621954", size = Vector2.new(700, 760) }, -- CrystalSeraphEggRender.png (World 2)
	eggBlackWidow = { id = "rbxassetid://131073330411941", size = Vector2.new(556, 673) }, -- BlackWidowEggRender.png (World 2)
	eggCaterpillar = { id = "rbxassetid://109185103681711", size = Vector2.new(502, 841) }, -- CaterpillarEggRender.png (World 2)
	eggPinkButterfly = { id = "rbxassetid://139551342957176", size = Vector2.new(700, 839) }, -- PinkButterflyEggRender.png (World 2)
	eggOrangeButterfly = { id = "rbxassetid://136557216823067", size = Vector2.new(700, 826) }, -- OrangeButterflyEggRender.png (World 2)
	eggLivingBirch = { id = "rbxassetid://78918914654470", size = Vector2.new(557, 944) }, -- LivingBirchEggRender.png (World 2)
	eggGiantGolem = { id = "rbxassetid://130649889910224", size = Vector2.new(584, 902) }, -- GiantGolemEggRender.png (World 2)
	eggHawkmoth = { id = "rbxassetid://111594299533130", size = Vector2.new(553, 817) }, -- HawkmothEggRender.png (World 2)
	eggRollingLog = { id = "rbxassetid://125301165432908", size = Vector2.new(518, 794) }, -- RollingLogEggRender.png (World 2)
	eggCatfish = { id = "rbxassetid://136135901593127", size = Vector2.new(672, 821) }, -- CatfishEggRender.png (World 2)
	eggTiger = { id = "rbxassetid://112691374931555", size = Vector2.new(502, 720) }, -- TigerEggRender.png (World 2)
	eggJadeStatue = { id = "rbxassetid://106883633786837", size = Vector2.new(502, 804) }, -- JadeStatueEggRender.png (World 2)
	eggGarnetStatue = { id = "rbxassetid://121784684526161", size = Vector2.new(502, 752) }, -- GarnetStatueEggRender.png (World 2)
	eggFox = { id = "rbxassetid://92522948167443", size = Vector2.new(502, 806) }, -- FoxEggRender.png (World 2)
	eggNineTailedFox = { id = "rbxassetid://110560724842212", size = Vector2.new(544, 806) }, -- NineTailedFoxEggRender.png (World 2)
	eggKitsune = { id = "rbxassetid://124688776792586", size = Vector2.new(522, 849) }, -- KitsuneEggRender.png (World 2)
	eggGreenCrab = { id = "rbxassetid://74196090261063", size = Vector2.new(602, 791) }, -- GreenCrabEggRender.png (World 3)
	eggLimeCrab = { id = "rbxassetid://85578461423986", size = Vector2.new(602, 791) }, -- LimeCrabEggRender.png (World 3)
	eggParrot = { id = "rbxassetid://96862284524676", size = Vector2.new(573, 774) }, -- ParrotEggRender.png (World 3)
	eggBananaMonkey = { id = "rbxassetid://128398088115519", size = Vector2.new(502, 750) }, -- BananaMonkeyEggRender.png (World 3)
	eggTreasureHermit = { id = "rbxassetid://87618949538639", size = Vector2.new(549, 723) }, -- TreasureHermitEggRender.png (World 3)
	eggHalloweenSnake = { id = "rbxassetid://117365953821607", size = Vector2.new(553, 960) }, -- HalloweenSnakeEggRender.png (Halloween giga rare)
	eggHalloweenUnicorn = { id = "rbxassetid://74912601109263", size = Vector2.new(502, 865) }, -- HalloweenUnicornEggRender.png (Halloween giga rare)
	eggHalloweenKraken = { id = "rbxassetid://128790726871911", size = Vector2.new(696, 900) }, -- HalloweenKrakenEggRender.png (Halloween giga rare)
	eggHalloweenBoneRex = { id = "rbxassetid://134717406361017", size = Vector2.new(566, 945) }, -- HalloweenBoneRexEggRender.png (Halloween giga rare)
	eggHalloweenSeraph = { id = "rbxassetid://131579993641835", size = Vector2.new(700, 760) }, -- HalloweenSeraphEggRender.png (Halloween giga rare)
	eggHalloweenKitsune = { id = "rbxassetid://88660119728664", size = Vector2.new(522, 849) }, -- HalloweenKitsuneEggRender.png (Halloween giga rare)
	eggHalloweenLoong = { id = "rbxassetid://132053102713664", size = Vector2.new(560, 863) }, -- HalloweenLoongEggRender.png (Halloween giga rare)
	eggHalloweenPhoenix = { id = "rbxassetid://103296530187654", size = Vector2.new(700, 982) }, -- HalloweenPhoenixEggRender.png (Halloween giga rare)
	eggHalloweenCrystalElephant = { id = "rbxassetid://93115607475102", size = Vector2.new(650, 911) }, -- HalloweenCrystalElephantEggRender.png (Halloween giga rare)
	eggBlackCat = { id = "rbxassetid://90649473102708", size = Vector2.new(502, 759) }, -- BlackCatEggRender.png (Halloween)
	eggBat = { id = "rbxassetid://134273437630221", size = Vector2.new(569, 818) }, -- BatEggRender.png (Halloween)
	eggPumpkinPup = { id = "rbxassetid://85542206203209", size = Vector2.new(502, 762) }, -- PumpkinPupEggRender.png (Halloween)
	eggPurpleTarantula = { id = "rbxassetid://77502329949420", size = Vector2.new(678, 704) }, -- PurpleTarantulaEggRender.png (Halloween)
	eggWerewolf = { id = "rbxassetid://76054901949807", size = Vector2.new(502, 798) }, -- WerewolfEggRender.png (Halloween)
	eggGhost = { id = "rbxassetid://120779575988151", size = Vector2.new(647, 703) }, -- GhostEggRender.png (Halloween)
	eggSkeletonDog = { id = "rbxassetid://138690310482207", size = Vector2.new(502, 719) }, -- SkeletonDogEggRender.png (Halloween)
	eggTombstoneCrawler = { id = "rbxassetid://85290109366044", size = Vector2.new(502, 668) }, -- TombstoneCrawlerEggRender.png (Halloween)
	eggZombieBear = { id = "rbxassetid://117268933780863", size = Vector2.new(502, 722) }, -- ZombieBearEggRender.png (Halloween)
	eggWispWolf = { id = "rbxassetid://137089266842594", size = Vector2.new(502, 818) }, -- WispWolfEggRender.png (Halloween)
	eggGrimReaper = { id = "rbxassetid://105770722348639", size = Vector2.new(593, 734) }, -- GrimReaperEggRender.png (Halloween)
	eggEyepatchShark = { id = "rbxassetid://133989350638738", size = Vector2.new(502, 775) }, -- EyepatchSharkEggRender.png (World 3)
	eggTreasureTurtle = { id = "rbxassetid://94903975169870", size = Vector2.new(502, 817) }, -- TreasureTurtleEggRender.png (World 3)
	eggGhostShip = { id = "rbxassetid://83345853164128", size = Vector2.new(522, 868) }, -- GhostShipEggRender.png (World 3)
	eggJollyRogerWyvern = { id = "rbxassetid://106595353110687", size = Vector2.new(602, 734) }, -- JollyRogerWyvernEggRender.png (World 3)
	eggLadybug = { id = "rbxassetid://108874116333491", size = Vector2.new(502, 778) }, -- LadybugEggRender.png (World 3)
	eggBumblebee = { id = "rbxassetid://126546375629358", size = Vector2.new(645, 727) }, -- BumblebeeEggRender.png (World 3)
	eggToadstoolFrog = { id = "rbxassetid://115536781118070", size = Vector2.new(502, 676) }, -- ToadstoolFrogEggRender.png (World 3)
	eggVineMonster = { id = "rbxassetid://116358195389802", size = Vector2.new(524, 710) }, -- VineMonsterEggRender.png (World 3)
	eggVenusFlytrap = { id = "rbxassetid://99027902215314", size = Vector2.new(557, 668) }, -- VenusFlytrapEggRender.png (World 3)
	eggSunflowerLion = { id = "rbxassetid://109315089615628", size = Vector2.new(667, 689) }, -- SunflowerLionEggRender.png (World 3)
	eggRafflesiaBeast = { id = "rbxassetid://105998022695625", size = Vector2.new(658, 695) }, -- RafflesiaBeastEggRender.png (World 3)
	eggAncientTreant = { id = "rbxassetid://100941370514849", size = Vector2.new(502, 694) }, -- AncientTreantEggRender.png (World 3)
	eggGiantRafflesia = { id = "rbxassetid://81971373381902", size = Vector2.new(564, 764) }, -- FlytrapQueenEggRender.png (World 3; the Giant Rafflesia keeps the Flytrap Queen's egg for now)
	eggGummyBear = { id = "rbxassetid://82472901970710", size = Vector2.new(502, 750) }, -- GummyBearEggRender.png (World 3)
	eggYellowGummyBear = { id = "rbxassetid://71659275230398", size = Vector2.new(502, 750) }, -- YellowGummyBearEggRender.png (World 3)
	eggGreenGummyBear = { id = "rbxassetid://133913042752808", size = Vector2.new(502, 750) }, -- GreenGummyBearEggRender.png (World 3)
	eggGumdropFrog = { id = "rbxassetid://96785493203961", size = Vector2.new(502, 719) }, -- GumdropFrogEggRender.png (World 3)
	eggGingerbreadMan = { id = "rbxassetid://109625880806599", size = Vector2.new(502, 668) }, -- GingerbreadManEggRender.png (World 3)
	eggCreampuff = { id = "rbxassetid://139714019730087", size = Vector2.new(502, 780) }, -- CreampuffEggRender.png (World 3)
	eggSwollFairy = { id = "rbxassetid://127716474790012", size = Vector2.new(600, 721) }, -- SwollFairyEggRender.png (World 3)
	eggDesireTroll = { id = "rbxassetid://100253441445728", size = Vector2.new(502, 760) }, -- DesireTrollEggRender.png (World 3)
	eggRockCandyDragon = { id = "rbxassetid://112086344358353", size = Vector2.new(502, 815) }, -- RockCandyDragonEggRender.png (World 3)
	eggGumballGolem = { id = "rbxassetid://125539296607125", size = Vector2.new(502, 727) }, -- GumballGolemEggRender.png (World 3)
	eggGigacorn = { id = "rbxassetid://72903095022775", size = Vector2.new(502, 848) }, -- GigacornEggRender.png (World 3)
	eggMoonJellyfish = { id = "rbxassetid://130186009688014", size = Vector2.new(560, 686) }, -- MoonJellyfishEggRender.png (World 3)
	eggAnomalocaris = { id = "rbxassetid://124388771955215", size = Vector2.new(606, 830) }, -- AnomalocarisEggRender.png (World 3)
	eggBoxJellyfish = { id = "rbxassetid://119877368095785", size = Vector2.new(502, 676) }, -- BoxJellyfishEggRender.png (World 3)
	eggBlueRingOctopus = { id = "rbxassetid://72113109901514", size = Vector2.new(502, 699) }, -- BlueRingOctopusEggRender.png (World 3)
	eggManOWar = { id = "rbxassetid://84987070586649", size = Vector2.new(502, 837) }, -- ManOWarEggRender.png (World 3)
	eggMermaid = { id = "rbxassetid://87614321273679", size = Vector2.new(522, 795) }, -- MermaidEggRender.png (World 3)
	eggAbyssalDragon = { id = "rbxassetid://107912461575187", size = Vector2.new(585, 811) }, -- AbyssalDragonEggRender.png (World 3)
	eggReefTitan = { id = "rbxassetid://85646971920304", size = Vector2.new(660, 795) }, -- ReefTitanEggRender.png (World 3)
	eggRoyalCnidarian = { id = "rbxassetid://95339327375816", size = Vector2.new(502, 823) }, -- RoyalCnidarianEggRender.png (World 3)
	eggTombJackal = { id = "rbxassetid://114106715330048", size = Vector2.new(530, 879) }, -- TombJackalEggRender.png (World 2)
	eggLionArcher = { id = "rbxassetid://117473019333658", size = Vector2.new(505, 800) }, -- LionArcherEggRender.png (World 2)
	eggNut = { id = "rbxassetid://120782360993998", size = Vector2.new(623, 874) }, -- NutEggRender.png (World 2)
	eggGeb = { id = "rbxassetid://93281428675559", size = Vector2.new(522, 822) }, -- GebEggRender.png (World 2)
	eggEagleSentry = { id = "rbxassetid://117861828286868", size = Vector2.new(585, 893) }, -- EagleSentryEggRender.png (World 2)
	eggBes = { id = "rbxassetid://91869381995495", size = Vector2.new(517, 897) }, -- BesEggRender.png (World 2)
	eggBloatedMummy = { id = "rbxassetid://113530717781179", size = Vector2.new(565, 691) }, -- BloatedMummyEggRender.png (World 2)
	eggScarab = { id = "rbxassetid://90717259678888", size = Vector2.new(517, 770) }, -- ScarabEggRender.png (World 2)
	eggUnicorn = { id = "rbxassetid://85066893166855", size = Vector2.new(496, 859) }, -- UnicornEggRender.png
	eggCactus = { id = "rbxassetid://95599437590618", size = Vector2.new(635, 766) }, -- CactusEggRender.png
	eggKitten = { id = "rbxassetid://124881834655792", size = Vector2.new(502, 749) }, -- KittenEggRender.png
	eggScorpion = { id = "rbxassetid://84668325203507", size = Vector2.new(599, 1007) }, -- ScorpionEggRender.png (QM's update)
	eggSandworm = { id = "rbxassetid://102795691143589", size = Vector2.new(502, 767) }, -- SandwormEggRender.png (QM's update)
	eggSnake = { id = "rbxassetid://90142926499080", size = Vector2.new(553, 960) }, -- SnakeEggRender.png (QM's update)
	eggBeholder = { id = "rbxassetid://111649507533762", size = Vector2.new(647, 758) }, -- BeholderEggRender.png
	eggPenguin = { id = "rbxassetid://135143840112034", size = Vector2.new(582, 709) }, -- PenguinEggRender.png
	eggSnowman = { id = "rbxassetid://105231134861157", size = Vector2.new(675, 772) }, -- SnowmanEggRender.png
	eggSpineLizard = { id = "rbxassetid://131132122596946", size = Vector2.new(502, 982) }, -- SpineLizardEggRender.png (QM's update)
	eggBoar = { id = "rbxassetid://137113936385932", size = Vector2.new(589, 849) }, -- BoarEggRender.png (QM's update)
	eggIceGolem = { id = "rbxassetid://103638328020279", size = Vector2.new(502, 973) }, -- IceGolemEggRender.png (QM's update)
	eggSnackYak = { id = "rbxassetid://86307268458670", size = Vector2.new(700, 668) }, -- SnackYakEggRender.png (QM's update)
	eggIcebringer = { id = "rbxassetid://93831958938146", size = Vector2.new(502, 915) }, -- IcebringerEggRender.png (QM's update)
	eggKraken = { id = "rbxassetid://78320352111053", size = Vector2.new(696, 900) }, -- KrakenEggRender.png (QM's update)
	eggSquid = { id = "rbxassetid://128883182267763", size = Vector2.new(696, 785) }, -- SquidEggRender.png
	eggWhale = { id = "rbxassetid://97101351248514", size = Vector2.new(502, 684) }, -- WhaleEggRender.png
	eggKingCrab = { id = "rbxassetid://80563240117126", size = Vector2.new(700, 668) }, -- KingCrabEggRender.png (QM's update)
	eggBlueCrab = { id = "rbxassetid://119349539273288", size = Vector2.new(660, 668) }, -- BlueCrabEggRender.png
	eggRoboShark = { id = "rbxassetid://95626930006876", size = Vector2.new(514, 752) }, -- RoboSharkEggRender.png
	eggFirebird = { id = "rbxassetid://100787444937359", size = Vector2.new(502, 956) }, -- FirebirdEggRender.png
	eggRockHog = { id = "rbxassetid://82336240433052", size = Vector2.new(828, 998) }, -- RockHogEggRender.png
	eggRockworm = { id = "rbxassetid://105149417332337", size = Vector2.new(498, 909) }, -- RockwormEggRender.png
	eggFireLobster = { id = "rbxassetid://83951862994609", size = Vector2.new(808, 882) }, -- FireLobsterEggRender.png
	eggLavaWhale = { id = "rbxassetid://137754762277353", size = Vector2.new(502, 877) }, -- LavaWhaleEggRender.png
	eggTRex = { id = "rbxassetid://132088301588431", size = Vector2.new(562, 677) }, -- TRexEggRender.png
	eggRaptor = { id = "rbxassetid://86585294053216", size = Vector2.new(544, 725) }, -- RaptorEggRender.png
	eggSpinosaurus = { id = "rbxassetid://118684084308728", size = Vector2.new(524, 1017) }, -- SpinosaurusEggRender.png
	eggPterodactyl = { id = "rbxassetid://125349573529100", size = Vector2.new(944, 864) }, -- PterodactylEggRender.png
	eggAnkylosaurus = { id = "rbxassetid://117144807245289", size = Vector2.new(591, 754) }, -- AnkylosaurusEggRender.png
	eggPalmGuy = { id = "rbxassetid://119803210932578", size = Vector2.new(522, 734) }, -- PalmGuyEggRender.png
	eggBoneRex = { id = "rbxassetid://139955585467041", size = Vector2.new(546, 911) }, -- BoneRexEggRender.png
	eggPhoenix = { id = "rbxassetid://77371080716061", size = Vector2.new(1034, 1099) }, -- PhoenixEggRender.png
	eggVolcanoTortoise = { id = "rbxassetid://89848692685766", size = Vector2.new(502, 686) }, -- VolcanoTortoiseEggRender.png
	eggStarfish = { id = "rbxassetid://114368032731288", size = Vector2.new(680, 783) }, -- StarfishEggRender.png
	eggLionfish = { id = "rbxassetid://114164241366433", size = Vector2.new(898, 929) }, -- LionfishEggRender.png
	eggClownfish = { id = "rbxassetid://130227469695086", size = Vector2.new(593, 821) }, -- ClownfishEggRender.png
	eggFishSchool = { id = "rbxassetid://137156704531563", size = Vector2.new(530, 721) }, -- FishSchoolEggRender.png
	eggLoong = { id = "rbxassetid://70469571709365", size = Vector2.new(560, 863) }, -- LoongEggRender.png (QM's egg)
	eggWarElephant = { id = "rbxassetid://84356622911486", size = Vector2.new(656, 673) }, -- WarElephantEggRender.png
	eggSoulHorse = { id = "rbxassetid://136725772402125", size = Vector2.new(502, 812) }, -- SoulHorseEggRender.png
	eggSludge = { id = "rbxassetid://140005979942732", size = Vector2.new(561, 713) }, -- SludgeEggRender.png
	eggLeviathan = { id = "rbxassetid://95236739672996", size = Vector2.new(680, 684) }, -- LeviathanEggRender.png
}

-- On a computer (keyboard, no touch screen) the ride buttons show their key:
-- LASSO [E], RIDE [E], Sprint [SHIFT] and Ability [SPACE] (QM's PC art, same sizes).
-- The Ability button's cooldown picture stays the same. While a controller is in
-- use they go back to the plain art, with the pad's button on them (Gamepad).
local KEYBOARD_ART = {} -- [image key] = { keys = the PC art, plain = the art without a key }
if game:GetService("UserInputService").KeyboardEnabled and not game:GetService("UserInputService").TouchEnabled then
	for key, id in {
		lasso = "rbxassetid://101879608972078", -- LassoE.png
		lassoDisabled = "rbxassetid://118282623101402", -- LassoDisabledE.png
		ride = "rbxassetid://120239297848540", -- RideE.png
		sprint = "rbxassetid://99201367360467", -- SprintSHIFT.png
		ability = "rbxassetid://85357705922490", -- AbilitySPACE.png
	} do
		KEYBOARD_ART[key] = { keys = id, plain = IMAGES[key].id }
		IMAGES[key].id = id
	end
end

local BUTTON_WIDTH = 256
local SPRINT_WIDTH = 164 -- about 2/3 of TAKE EGG's width, as in the mockup
local BAR_WIDTH = 352
local ICON_HEIGHT = 80 -- Gold
local UPGRADE_WIDTH = 360 -- Upgrade Pen, top centre (20% up from 300, QM Oct 7: easier to notice)
local SIDE_ICON_HEIGHT = 80 -- Pets and Eggs, a little smaller in the mockup
local MARGIN = 24
local REFERENCE_WIDTH = 1320 -- screen width the sizes above are drawn for

-- Action text from the ride -> which image the action button shows.
local ACTIONS = { ["GRAB EGG"] = "takeEgg", LASSO = "lasso" }
-- The TAKE EGG image by the egg's rarity; anything else uses takeEgg (Uncommon).
local EGG_BUTTONS = { Rare = "takeEggRare", Epic = "takeEggEpic", Legendary = "takeEggLegendary", Divine = "takeEggLegendary", Celestial = "takeEggLegendary", Void = "takeEggLegendary", Omega = "takeEggLegendary" }

-- Banners drawn as images instead of text.
local BANNERS = { ["BUCKED OFF"] = "buckedOff", ["CRASH!"] = "crash" }
local BANNER_SCALE = 0.55 -- banner images show at this share of their pixel size

-- Banner colors: bad news red, good news yellow, anything else white.
local TONES = {
	["CRASH!"] = RED,
	["BUCKED OFF"] = RED,
	["TOO FAR!"] = RED,
}

local sprint, sprintInput -- the Sprint button, and the touch or click holding it down
local ability, abilityPressed, abilityFill, abilityReady, abilityTime -- the Ability button, a press not yet used, the ready part (and its picture) and the countdown
local mergeButton, mergeWanted -- MERGE, in RIDE's spot when RIDE isn't up (Hud.showMerge), and whether there's anything to merge
local fuseIcon -- Fuse, under Pets: picks two pets to fuse (FuseMenu, through Hud.onFuse)
local fuseIconAt -- its usual { Size, AnchorPoint, Position }: the merge lesson shows it bigger
-- The ride's distance ("238 m" over the top bar) and its cash (coin and "$0" beside
-- it): off (QM, Oct 8: the top bar's HOLD ON!'s now). True brings them back.
local SHOW_RIDE_TOP = false
local LESSON_FUSE_SCALE = 2 / 1.5 -- (QM, Oct 8: big so nobody can miss it, then 1.5x smaller than 2x; Tutorial's hand stays at the 2x size: Hud.cursorBoost)
local shopIcon -- Shop, over Roll (or over Pets without Roll): opens the Robux shop (Shop)
local continueButton -- the fail screen's Continue, for Robux (Hud.showContinue)
local CONTINUE_GAP = 12 -- between Continue and the Home button under it
local tip, tipText -- the fail screen's tooltip in place of "+$N" (Hud.setTip), and its text
local roll, rollShown -- the Egg Machine's ROLL button, and whether you're at the machine
-- The first-time tutorial's stage (Hud.setTutorial): nil when it's off, "bare"
-- (no Gold, Pets or Upgrade Pen) while it runs, "fuse" (Fuse alone) at its fuse step.
local tutorial = nil
local lesson = false -- the fuse lesson's on (Hud.setLesson): nothing but Fuse shows
local upgradeScale -- Upgrade Pen's UIScale
-- A line of text top centre (Hud.setNotice), in its own always-on ScreenGui.
local NOTICE = { TEXT_SIZE = 40, TOP = 16 + 352 * 220 / 1292 + 36 } -- TOP: just under the Hold bar (QM; BAR_WIDTH x barEmpty's shape)
local gui, homeGui, rideRoot, homeRoot, rootScale, holdFrame, holdClip, distance, action, message, home, banner, ride, gold, pets, upgrade, upgradeShown, rideCash, gained, dodge, dodgePulse, vignette, abilityTint, sunburst, actionScale

-- Money as "$950", "$1.2k", "$104k", "$3.5M", "$2B": from 1000 up, a suffix
-- with at most one decimal (and none from 100 of a unit up).
local SUFFIXES = { "k", "M", "B", "T", "Qa", "Qi" }
local function money(amount)
	amount = math.floor(amount)
	local sign = if amount < 0 then "-" else ""
	local n, suffix = math.abs(amount), ""
	for _, s in SUFFIXES do
		if n < 1000 then
			break
		end
		n /= 1000
		suffix = s
	end
	if suffix == "" then
		return sign .. "$" .. n
	end
	-- Round down, so 999,999 reads $999k rather than $1000k.
	local text = if n >= 100 then tostring(math.floor(n)) else (string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", ""))
	return sign .. "$" .. text .. suffix
end

-- Text outlines, kept at a whole number of screen pixels. The HUD's UIScale scales
-- them too, and at fractional widths the dot UIStroke leaves in small letter
-- holes (the 6 in "63 m") comes out oversized.
local strokes = {}
local function roundStroke(stroke)
	local scale = rootScale or 1
	stroke.Thickness = math.max(1, math.round(strokes[stroke] * scale)) / scale
end

local function label(parent, size, position, textSize, thickness)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = WHITE
	l.Text = ""
	local s = Instance.new("UIStroke")
	strokes[s] = thickness or STROKE
	roundStroke(s)
	s.Destroying:Connect(function()
		strokes[s] = nil
	end)
	s.Color = Color3.new(0, 0, 0)
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- Image at its native aspect ratio: pass a width or a height and the other follows.
local function fit(key, width, height)
	local native = IMAGES[key].size
	return UDim2.fromOffset(width or height * native.X / native.Y, height or width * native.Y / native.X)
end

local function image(parent, key, size, position)
	local i = Instance.new("ImageLabel")
	i.BackgroundTransparency = 1
	i.AnchorPoint = Vector2.new(0.5, 0.5)
	i.Size = size
	i.Position = position
	i.Image = IMAGES[key].id
	i.Parent = parent
	return i
end

-- Full-screen frame that everything is laid out in, in pixels of a REFERENCE_WIDTH
-- wide screen. It's scaled to the real screen width, so the HUD keeps the mockup's
-- proportions (Hold bar a third of the screen, action button a quarter).
local function root(screenGui)
	local frame = Instance.new("Frame")
	frame.Name = "Root"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local camera = workspace.CurrentCamera
	local function resize()
		-- (the screen it's on, edge to edge: ScreenEdges.client takes the safe-area insets
		-- off every screen, so the buttons sit at the real edges on phones too)
		local screen = if screenGui.AbsoluteSize.X > 0 then screenGui.AbsoluteSize else camera.ViewportSize
		scale.Scale = screen.X / REFERENCE_WIDTH * Config.HudScale
		frame.Size = UDim2.fromOffset(screen.X / scale.Scale, screen.Y / scale.Scale)
		rootScale = scale.Scale
		for stroke in strokes do
			roundStroke(stroke)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	frame.Parent = screenGui
	return frame
end

-- Image button that shrinks a little while pressed.
local function button(parent, key, size, anchor, position, onActivated)
	local root = Instance.new("ImageButton")
	root.Name = key
	root.BackgroundTransparency = 1
	root.AnchorPoint = anchor
	root.Size = size
	root.Position = position
	root.Image = IMAGES[key].id
	local scale = Instance.new("UIScale")
	scale.Parent = root
	local press = TweenInfo.new(0.08)
	root.MouseButton1Down:Connect(function()
		TweenService:Create(scale, press, { Scale = 0.93 }):Play()
	end)
	for _, event in { root.MouseButton1Up, root.MouseLeave } do
		event:Connect(function()
			TweenService:Create(scale, press, { Scale = 1 }):Play()
		end)
	end
	if onActivated then
		root.Activated:Connect(onActivated)
	end
	root.Parent = parent
	return root, scale
end

local BOTTOM_CENTER = Vector2.new(0.5, 1)
local BUTTON_SPOT = UDim2.new(0.5, 0, 1, -MARGIN)

-- Coin with the amount beside it, the text overlapping the coin's edge
-- (QM's MoreGold look). Used for this ride's cash and for the fail screen's total.
local function cashRow(parent, coinSize, textSize, anchor, position, strokeThickness)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.AnchorPoint = anchor
	row.Position = position
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, -coinSize * 0.2)
	layout.Parent = row
	local coin = image(row, "coin", UDim2.fromOffset(coinSize, coinSize), UDim2.new())
	coin.ZIndex = 1
	local text = label(row, UDim2.fromOffset(0, coinSize), UDim2.new(), textSize, strokeThickness or 3)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.LayoutOrder = 1
	text.ZIndex = 3 -- the text overlaps the coin's edge, drawn on top
	local scale = Instance.new("UIScale")
	scale.Parent = row
	row.Parent = parent
	return { row = row, coin = coin, text = text, scale = scale }
end

-- The ride's cash reads "N$"; the fail screen's reads "+N$".
local rideAmount = 0
local noCash = false -- Hud.setCash(nil): this fail screen shows no cash
local function setCash(amount)
	rideAmount = amount
	rideCash.text.Text = money(amount)
end

function Hud.init(onAction, onHome, onRide, onContinue)
	if RideUi then
		RideUi.onAction = onAction
	end
	-- With ShowHud off the HUD is built but never parented, so nothing shows.
	local playerGui = Config.ShowHud and Players.LocalPlayer:WaitForChild("PlayerGui") or nil
	if not Config.ShowHud then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "RideHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = playerGui
	rideRoot = root(gui)
	rideRoot.Visible = Config.RideHud ~= false -- (QM, Oct 9: no riding UI for now)

	-- Hold bar: the empty bar, with the full bar cropped to the Hold fraction on top.
	-- The full image keeps the bar's size inside the clip, so the crop lines up 1:1.
	local barSize = fit("barEmpty", BAR_WIDTH)
	holdFrame = image(rideRoot, "barEmpty", barSize, UDim2.new(0.5, 0, 0, 16 + barSize.Y.Offset / 2))
	holdFrame.Name = "Hold"
	holdClip = Instance.new("Frame")
	holdClip.Name = "Fill"
	holdClip.BackgroundTransparency = 1
	holdClip.ClipsDescendants = true
	holdClip.Size = UDim2.fromScale(1, 1)
	holdClip.Parent = holdFrame
	local filled = image(holdClip, "barFilled", barSize, UDim2.fromScale(0, 0))
	filled.AnchorPoint = Vector2.zero

	-- Distance, on the bar.
	distance = label(rideRoot, UDim2.fromOffset(BAR_WIDTH, barSize.Y.Offset), holdFrame.Position, 40, 3) -- 3px outline (QM)
	distance.Name = "Distance"
	distance.Visible = SHOW_RIDE_TOP
	distance.ZIndex = 2

	-- Ride back: only DODGE THE STAMPEDE!, pulsing between 90% and 110%, and a red
	-- vignette that fades out over the last stretch home.
	dodge = image(rideRoot, "dodge", fit("dodge", 440), UDim2.fromScale(0.5, 0.15))
	dodge.Visible = false
	Instance.new("UIScale").Parent = dodge
	dodgePulse = TweenService:Create(dodge.UIScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 })
	vignette = image(rideRoot, "vignette", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	vignette.ImageColor3 = Config.VignetteColor
	-- A second vignette an ability tints the screen with (the Snake's blue haze).
	abilityTint = image(rideRoot, "vignette", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5))
	abilityTint.ImageTransparency = 1
	abilityTint.Visible = false
	vignette.ZIndex = 0
	vignette.Visible = false

	message = label(rideRoot, UDim2.fromOffset(600, 80), UDim2.fromScale(0.5, 0.3), 56)
	banner = image(rideRoot, "buckedOff", fit("buckedOff", IMAGES.buckedOff.size.X * BANNER_SCALE), message.Position)
	banner.Visible = false
	Instance.new("UIScale").Parent = banner

	action, actionScale = button(rideRoot, "lasso", fit("lasso", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onAction)
	action.Name = "Action"
	action.ZIndex = 2
	-- Slowly turning sunburst behind TAKE EGG (Config.TakeEggSunburst).
	local eggHeight = fit("takeEgg", BUTTON_WIDTH).Y.Offset
	sunburst = image(rideRoot, "sunburst", UDim2.fromOffset(BUTTON_WIDTH * 1.5, BUTTON_WIDTH * 1.5), UDim2.new(0.5, 0, 1, -MARGIN - eggHeight / 2))
	sunburst.ImageTransparency = 0.25
	sunburst.Visible = false

	home = button(rideRoot, "home", fit("home", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onHome)
	home.Visible = false
	local overHome = UDim2.new(0.5, 0, 1, -MARGIN - fit("home", BUTTON_WIDTH).Y.Offset - CONTINUE_GAP)
	continueButton = button(rideRoot, "continue", fit("continue", BUTTON_WIDTH), BOTTOM_CENTER, overHome, onContinue)
	continueButton.Visible = false
	-- Sprint, bottom left: held down, not clicked. Remembers the touch or click that
	-- pressed it, so sliding a finger off the button doesn't drop the sprint.
	sprint = button(rideRoot, "sprint", fit("sprint", SPRINT_WIDTH), Vector2.new(0, 1), UDim2.new(0, MARGIN, 1, -MARGIN))
	sprint.Visible = false
	sprint.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			sprintInput = input
		end
	end)
	-- Ability, bottom right (only for a pet that has one): held down like Sprint.
	-- Grey while it cools down, the ready (red) picture filling in from the top
	-- with the seconds left on it.
	local abilitySize = fit("ability", SPRINT_WIDTH)
	ability = image(rideRoot, "abilityCooldown", abilitySize, UDim2.new(1, -MARGIN, 1, -MARGIN))
	ability.Name = "ability"
	ability.AnchorPoint = Vector2.new(1, 1)
	ability.Active = true
	ability.Visible = false
	abilityFill = Instance.new("Frame")
	abilityFill.BackgroundTransparency = 1
	abilityFill.ClipsDescendants = true
	abilityFill.Size = UDim2.fromScale(1, 1)
	abilityFill.Parent = ability
	abilityReady = image(abilityFill, "ability", abilitySize, UDim2.new())
	abilityReady.AnchorPoint = Vector2.zero
	abilityTime = label(ability, UDim2.fromScale(1, 0.4), UDim2.fromScale(0.58, 0.55), 40, 5)
	abilityTime.ZIndex = 2
	local abilityScale = Instance.new("UIScale")
	abilityScale.Parent = ability
	ability.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			abilityPressed = true
			TweenService:Create(abilityScale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
		end
	end)
	ability.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(abilityScale, TweenInfo.new(0.08), { Scale = 1 }):Play()
		end
	end)
	gained = cashRow(rideRoot, 84, 58, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.57), 4) -- 4px outline (QM)
	-- A tooltip that takes the gained cash's place on a fail screen (Hud.setTip):
	-- just the outlined white text, no box (QM, Oct 1).
	tip = Instance.new("Frame")
	tip.Name = "Tip"
	tip.AnchorPoint = Vector2.new(0.5, 0.5)
	tip.Position = gained.row.Position
	tip.AutomaticSize = Enum.AutomaticSize.XY
	tip.BackgroundTransparency = 1
	tip.Visible = false
	local tipPad = Instance.new("UIPadding")
	tipPad.PaddingLeft, tipPad.PaddingRight = UDim.new(0, 28), UDim.new(0, 28)
	tipPad.PaddingTop, tipPad.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12)
	tipPad.Parent = tip
	tipText = label(tip, UDim2.fromOffset(0, 56), UDim2.new(), 44, 3)
	tipText.AnchorPoint = Vector2.zero
	tipText.AutomaticSize = Enum.AutomaticSize.X
	Instance.new("UIScale").Parent = tip
	tip.Parent = rideRoot
	rideCash = cashRow(rideRoot, 60, 46, Vector2.new(0, 0.5), UDim2.new(0.5, BAR_WIDTH / 2 + 8, 0, holdFrame.Position.Y.Offset), 3) -- 3px outline (QM)
	rideCash.row.Visible = SHOW_RIDE_TOP

	-- Home buttons, always on screen outside a ride; Gold stays during rides too.
	homeGui = Instance.new("ScreenGui")
	homeGui.Name = "HomeHud"
	homeGui.ResetOnSpawn = false
	homeGui.IgnoreGuiInset = true
	homeGui.Parent = playerGui
	homeRoot = root(homeGui)
	ride = button(homeRoot, "ride", fit("ride", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, onRide)
	ride.Visible = false
	mergeButton = button(homeRoot, "merge", fit("merge", BUTTON_WIDTH), BOTTOM_CENTER, BUTTON_SPOT, function()
			if Hud.onMerge then
				Hud.onMerge()
			end
		end)
	mergeButton.Visible = false
	-- Gold and Pets have a screen of their own so they stay up while the animal
	-- dictionary hides the rest of the home HUD (QM: only the dictionary, Pets and
	-- the gold show then).
	local sideGui = Instance.new("ScreenGui")
	sideGui.Name = "GoldPets"
	sideGui.ResetOnSpawn = false
	sideGui.IgnoreGuiInset = true
	sideGui.Enabled = Config.HomeHud ~= false -- (QM, Oct 9: no gold, Pets, Shop or Merge for now)
	sideGui.Parent = playerGui
	local sideRoot = root(sideGui)
	-- Bottom left: gold, its icon with the number beside it overlapping the icon's edge.
	gold = Instance.new("Frame")
	gold.Name = "Counters"
	gold.BackgroundTransparency = 1
	gold.AutomaticSize = Enum.AutomaticSize.XY
	gold.AnchorPoint = Vector2.new(0, 1)
	gold.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, 4)
	stack.Parent = gold
	gold.Parent = sideRoot
	local goldRow = cashRow(gold, ICON_HEIGHT, 44, Vector2.zero, UDim2.new(), 4)
	goldRow.row.LayoutOrder = 1
	local player = Players.LocalPlayer
	local function showGold()
		goldRow.text.Text = money(player:GetAttribute("Gold") or 0)
	end
	player:GetAttributeChangedSignal("Gold"):Connect(showGold)
	showGold()
	-- Each payout from your pets (Hatchery's PetIncome, every second): "+$N" beside
	-- the gold in the money yellow, smaller, which then slides up and fades to make
	-- room for the next (QM, Oct 8).
	-- (its labels go in a holder of their own, shown only while the gold counter is)
	local ticker = Instance.new("Frame")
	ticker.Name = "GoldTicker"
	ticker.BackgroundTransparency = 1
	ticker.Size = UDim2.fromScale(1, 1)
	ticker.Parent = sideRoot
	local function follow()
		ticker.Visible = gold.Visible
	end
	gold:GetPropertyChangedSignal("Visible"):Connect(follow)
	follow()
	task.spawn(function() -- (not holding up the HUD's build for it)
	RewardPopups.watchCash(money) -- (gold you're given pops up in the lower middle, QM Nov 6)
	RewardPopups.watchLuck() -- (and luck from goals, QM Nov 7)
	game:GetService("ReplicatedStorage"):WaitForChild("PetIncome").OnClientEvent:Connect(function(earned)
		if type(earned) ~= "number" or earned <= 0 or not gold.Visible or not sideRoot:FindFirstAncestorOfClass("ScreenGui").Enabled then
			return -- (nothing while the counter's hidden: riding...)
		end
		-- (its own label on sideRoot, outside the gold's layout: inside the gold text it
		-- widened that text's AutomaticSize and pushed the number and coin about, Oct 8)
		local tx = goldRow.text
		local scale = sideRoot.AbsoluteSize.X / math.max(sideRoot.Size.X.Offset, 1)
		local right = tx.AbsolutePosition.X + (tx.AbsoluteSize.X + tx.TextBounds.X) / 2
		local at = (Vector2.new(right, tx.AbsolutePosition.Y + tx.AbsoluteSize.Y / 2) - sideRoot.AbsolutePosition) / scale
		local plus = label(ticker, UDim2.fromOffset(0, 34), UDim2.fromOffset(at.X + 8, at.Y), 30, 3)
		plus.AnchorPoint = Vector2.new(0, 0.5)
		plus.AutomaticSize = Enum.AutomaticSize.X
		plus.TextColor3 = Color3.fromHex("FFC41E")
		plus.Text = "+" .. money(earned)
		plus.ZIndex = 3
		local stroke = plus:FindFirstChildOfClass("UIStroke")
		local pop = Instance.new("UIScale")
		pop.Scale = 0.6
		pop.Parent = plus
		TweenService:Create(pop, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		task.delay(0.4, function()
			local away = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(plus, away, { Position = plus.Position - UDim2.fromOffset(0, 30), TextTransparency = 1 }):Play()
			TweenService:Create(stroke, away, { Transparency = 1 }):Play()
			task.delay(0.6, plus.Destroy, plus)
		end)
	end)
	end)
	-- The coin keeps the bottom left to itself; the bottom right column is Fuse,
	-- Shop, Pets from the top, all the same height (QM, Oct 6 19:24). Row 0 is the
	-- bottom one. (The egg roll menu opens from Carl, its NPC.)
	local function columnSpot(row)
		return UDim2.new(1, -MARGIN - SIDE_ICON_HEIGHT / 2, 1, -MARGIN - row * (SIDE_ICON_HEIGHT + 8))
	end
	-- Pets: it opens and closes the animal dictionary (AnimalDex).
	pets = button(sideRoot, "pets", fit("pets", nil, SIDE_ICON_HEIGHT), Vector2.new(0.5, 1), columnSpot(0), AnimalDex.toggle)
	-- Fuse, on top of the column: tap two of your pets to fuse them (FuseMenu).
	fuseIcon = button(sideRoot, "fuseIcon", fit("fuseIcon", nil, SIDE_ICON_HEIGHT), Vector2.new(0.5, 1), columnSpot(2), function()
		if Hud.onFuse then
			Hud.onFuse()
		end
	end)
	fuseIconAt = { Size = fuseIcon.Size, AnchorPoint = fuseIcon.AnchorPoint, Position = fuseIcon.Position }

	fuseIcon.Visible = pets.Visible and Hud.fuseUnlocked()
	for _, name in { "PenLevel", "FuseLesson" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			Hud.setTutorial(tutorial) -- (Fuse shows from the Desert on)
		end)
	end
	if IMAGES.fuseIcon.id == "" then
		local fuseText = label(fuseIcon, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), 34, 3) -- 3px outline (QM)
		fuseText.Text = "Merge"
	end
	-- Shop, in the middle: it opens the Robux shop.
	shopIcon = button(sideRoot, "shopIcon", fit("shopIcon", nil, SIDE_ICON_HEIGHT), Vector2.new(0.5, 1), columnSpot(1), function()
		if Shop.hasOffers() then
			Shop.toggle()
		end
	end)
	shopIcon.Visible = pets.Visible and Config.ShopOn
	if IMAGES.shopIcon.id == "" then
		local shopText = label(shopIcon, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), 34, 3) -- 3px outline (QM)
		shopText.Text = "Shop"
	end
	-- Opening one menu closes the others at once, with no closing animation (QM): only
	-- the one coming in pops.
	AnimalDex.onToggle = function(open)
		if open then
			if Hud.closeFuse then
				Hud.closeFuse(true)
			end
			RollMenu.close(true)
			Shop.close(true)
		end
		homeGui.Enabled = not open
	end
	RollMenu.onToggle = function(open)
		if open then
			if Hud.closeFuse then
				Hud.closeFuse(true)
			end
			AnimalDex.close(true)
			Shop.close(true)
		end
		homeGui.Enabled = not open
	end
	-- The shop hides the rest of the home HUD like the other menus.
	-- The Fuse page (FuseMenu) is a menu like the others.
	function Hud.fuseToggled(open)
		if open then
			AnimalDex.close(true)
			RollMenu.close(true)
			Shop.close(true)
		end
		homeGui.Enabled = not open
	end
	Shop.onToggle = function(open)
		if open then
			if Hud.closeFuse then
				Hud.closeFuse(true)
			end
			AnimalDex.close(true)
			RollMenu.close(true)
		end
		homeGui.Enabled = not open
	end
	local halloweenQueue, showingHalloween = {}, false
	-- A Legendary Pet bought in the shop is in your pen: its card shows which.
	game:GetService("ReplicatedStorage"):WaitForChild("ShopGrant").OnClientEvent:Connect(function(key, kind)
		if key ~= "LegendaryPet" and key ~= "HalloweenPets" then
			Sounds.play("purchase") -- (the Legend Egg's pet comes as a second grant: one sound)
		end
		Shop.close()
		if key == "HalloweenPets" and typeof(kind) == "table" and #kind > 0 then
			table.insert(halloweenQueue, kind)
			if not showingHalloween then
				showingHalloween = true
				task.spawn(function()
					while #halloweenQueue > 0 do
						while Hud.revealing() do RunService.Heartbeat:Wait() end
						local batch = table.remove(halloweenQueue, 1)
						local animal = game:GetService("ReplicatedStorage").Shared.Animals:FindFirstChild(batch[1])
						Hud.eggReveal(if animal then require(animal).Rarity else "Legendary", batch[1], true, batch)
						while Hud.revealing() do RunService.Heartbeat:Wait() end
					end
					showingHalloween = false
				end)
			end
		elseif key == "LoongPet" and kind then
			require(script.Parent.NewAnimal).show(kind) -- (the bought Loong: the new animal popup, QM Oct 15)
		elseif key == "LegendaryPet" and kind then
			-- (its own rarity's card: the Loong and Robo Shark are Exclusive)
			local animal = game:GetService("ReplicatedStorage").Shared.Animals:FindFirstChild(kind)
			Hud.eggReveal(if animal then require(animal).Rarity else "Legendary", kind, true)
		end
	end)
	Inventory.init(homeRoot)

	-- Upgrade Pen, top centre: buys your pen's next level (UpgradePen). It's the
	-- next biome's own button (its UpgradeImage, with the price drawn in),
	-- throbbing when you have the gold, its UpgradeImageDisabled when you don't
	-- (greyed if it has none). A biome without
	-- one gets the plain button, green or grey, with the price written over the
	-- bottom of its coin. Once there's no next level it sells the Rainbow Trail
	-- (Config.RainbowTrail, its own art the same way) until that's bought, then hides.
	local upgradePen = game:GetService("ReplicatedStorage"):WaitForChild("UpgradePen")
	local buyTrail = game:GetService("ReplicatedStorage"):WaitForChild("BuyRainbowTrail")
	local upgradeSize = fit("upgradePenBiome", UPGRADE_WIDTH)
	-- Anchored at its middle so the throb grows it evenly. Top centre (QM, Oct 7: more
	-- obvious there than in the corner).
	upgrade, upgradeScale = button(homeRoot, "upgradePen", upgradeSize, Vector2.new(0.5, 0.5),
		UDim2.new(0.5, 0, 0, MARGIN + upgradeSize.Y.Offset / 2))
	-- It fills up as your gold does (QM, Oct 7), like the Hold bar: the disabled art
	-- is the button, and the enabled art sits on it, cropped to gold / price from the left.
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundTransparency = 1
	fill.ClipsDescendants = true
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = upgrade
	image(fill, "upgradePen", upgradeSize, UDim2.fromScale(0, 0)).AnchorPoint = Vector2.zero
	local price = label(upgrade, UDim2.fromOffset(0, 36), UDim2.fromScale(0.855, 0.66), 36, 3.6)
	price.ZIndex = 2 -- over the fill (this ScreenGui layers by ZIndex across the whole tree)
	price.AutomaticSize = Enum.AutomaticSize.X
	local cost -- gold for the next level (or the Rainbow Trail), nil when there's nothing to buy
	local trail = false -- selling the Rainbow Trail
	local function refreshUpgrade()
		local nextBiome = Config.Biomes[(player:GetAttribute("PenLevel") or 1) + 1]
		cost = Config.PenUpgrades and nextBiome and nextBiome.UnlockCost or nil
		trail = Config.PenUpgrades and cost == nil and not player:GetAttribute("RainbowTrail")
		if trail then
			cost = Config.RainbowTrail.Price
		end
		upgradeShown = cost ~= nil and Config.HomeHud ~= false -- (QM, Oct 9: none for now)
		upgrade.Visible = upgradeShown and gold.Visible
		if cost then
			local affordable = (player:GetAttribute("Gold") or 0) >= cost
			local art = if trail then Config.RainbowTrail else { Image = nextBiome.UpgradeImage, ImageDisabled = nextBiome.UpgradeImageDisabled }
			local own = if art.Image ~= "" then art.Image else nil
			price.Text = money(cost)
			price.Visible = not own
			local ownDisabled = own and not affordable and art.ImageDisabled ~= "" and art.ImageDisabled
			upgrade.Image = ownDisabled or own or IMAGES[if affordable then "upgradePen" else "upgradePenDisabled"].id
			upgrade.ImageColor3 = if own and not affordable and not ownDisabled then Color3.fromRGB(150, 150, 150) else Color3.new(1, 1, 1)
			fill.ImageLabel.Image = own or IMAGES.upgradePen.id
			fill.Size = UDim2.fromScale(if affordable then 1 else math.clamp((player:GetAttribute("Gold") or 0) / cost, 0, 1), 1)
		end
	end
	local buying = false
	local function buyUpgrade()
		if buying or not cost or (player:GetAttribute("Gold") or 0) < cost then
			return
		end
		buying = true
		local remote = if trail then buyTrail else upgradePen
		pcall(remote.InvokeServer, remote)
		buying = false
	end
	upgrade.Activated:Connect(buyUpgrade)
	player:GetAttributeChangedSignal("Gold"):Connect(refreshUpgrade)
	player:GetAttributeChangedSignal("PenLevel"):Connect(refreshUpgrade)
	player:GetAttributeChangedSignal("RainbowTrail"):Connect(refreshUpgrade)
	refreshUpgrade()
	-- The throb, while it's affordable (and not while it's held down).
	local pressed = false
	upgrade.MouseButton1Down:Connect(function()
		pressed = true
	end)
	for _, event in { upgrade.MouseButton1Up, upgrade.MouseLeave } do
		event:Connect(function()
			pressed = false
		end)
	end
	-- The tutorial's clicking hand (Tutorial.luau's cursor) over it too, while it's
	-- affordable and the tutorial's not on (QM).
	local hand = Instance.new("ImageLabel")
	hand.Name = "Hand"
	hand.BackgroundTransparency = 1
	hand.Image = "rbxassetid://134865745295413" -- assets/ui/TapHand.png (QM's; the old TutorialCursor art is a grey placeholder while Config.UiArt is off)
	hand.AnchorPoint = Vector2.new(0.365, 0.03) -- its tip, so it throbs about it
	hand.Position = UDim2.fromScale(0.5, 0.6)
	hand.SizeConstraint = Enum.SizeConstraint.RelativeYY
	hand.Size = UDim2.fromScale(0.9 * 488 / 610, 0.9) -- (TapHand.png is 488 x 610)
	hand.Visible = false
	hand.ZIndex = 2 -- over the fill
	local handScale = Instance.new("UIScale")
	handScale.Parent = hand
	hand.Parent = upgrade
	local throbbing = false
	RunService.RenderStepped:Connect(function()
		local affordable = cost ~= nil and (player:GetAttribute("Gold") or 0) >= cost
		hand.Visible = affordable and not trail and tutorial == nil and not player:GetAttribute("Tutorial")
		if hand.Visible then
			handScale.Scale = 1 + 0.1 * math.sin(os.clock() * 2 * math.pi)
		end
		if affordable and not pressed and upgrade.Visible then
			throbbing = true
			upgradeScale.Scale = 1 + 0.06 * (0.5 - 0.5 * math.cos(os.clock() * math.pi * 2 / 0.9))
		elseif throbbing and not pressed then
			throbbing = false
			upgradeScale.Scale = 1
		end
	end)

	-- Egg Machine (Config.Gacha): walking up to it shows ROLL where RIDE goes; it
	-- (or E) pays the price for a random egg, shown in its reward popup. The prompt
	-- draws nothing, like RIDE's. Green when you have the gold, grey when you don't.
	local rollGacha = game:GetService("ReplicatedStorage"):WaitForChild("RollGacha")
	local rollSize = fit("roll", BUTTON_WIDTH)
	roll = button(homeRoot, "roll", rollSize, BOTTOM_CENTER, BUTTON_SPOT)
	roll.Visible = false
	local rollText
	if IMAGES.roll.id == "" then
		roll.BackgroundTransparency = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = roll
		local edge = Instance.new("UIStroke")
		edge.Thickness = 5
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = roll
		rollText = label(roll, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), 46, 5)
	end
	local rolling = false
	-- The next roll's price climbs with each roll (Hatchery's "RollPrice").
	local function rollPrice()
		return player:GetAttribute("RollPrice") or Config.Gacha.Price
	end
	local function canRoll()
		return (player:GetAttribute("Gold") or 0) >= rollPrice()
	end
	local function refreshRoll()
		RollMenu.setPrice(money(rollPrice()))
		if rollText then
			rollText.Text = "ROLL " .. money(rollPrice())
			roll.BackgroundColor3 = Color3.fromRGB(92, 214, 72) -- always pressable (QM): short of gold, it offers a gold pack
		end
	end
	player:GetAttributeChangedSignal("Gold"):Connect(refreshRoll)
	player:GetAttributeChangedSignal("RollPrice"):Connect(refreshRoll)
	refreshRoll()
	-- ROLL is always pressable (QM): without the gold for it, it asks you to buy the
	-- smallest gold pack that gets you there (Shop.buyGoldFor); press ROLL again once
	-- it's in.
	local function doRoll()
		if rolling or not (rollShown or RollMenu.isOpen()) or gui.Enabled then
			return
		end
		if not canRoll() then
			Shop.buyGoldFor(rollPrice() - (player:GetAttribute("Gold") or 0))
			return
		end
		rolling = true
		local ok, kind, exclusive = pcall(rollGacha.InvokeServer, rollGacha)
		-- The egg's reward popup, as coming home with it (QM, Nov 6: no RNG card).
		local rarity = ok and kind and require(game:GetService("ReplicatedStorage").Shared.Animals[kind]).Rarity
		RollMenu.setHidden(rarity ~= nil)
		local seconds = rarity and Hud.eggReveal(rarity, kind, true)
		task.wait(seconds or 0.3)
		if rarity then
			RollMenu.close() -- one egg per roll: the menu doesn't come back (QM)
		end
		RollMenu.setHidden(false)
		rolling = false
	end
	roll.Activated:Connect(doRoll)
	RollMenu.onRoll = doRoll
	local function setRollShown(shown)
		rollShown = shown
		roll.Visible = shown and not gui.Enabled and not lesson
		Inventory.setVisible(not shown and not ride.Visible and not mergeButton.Visible and not gui.Enabled and not lesson)
	end

	-- A line of text top centre (Hud.setNotice), where the event countdown was.
	local noticeGui = Instance.new("ScreenGui")
	noticeGui.Name = "NoticeHud"
	noticeGui.ResetOnSpawn = false
	noticeGui.IgnoreGuiInset = true
	noticeGui.DisplayOrder = 5
	noticeGui.Parent = playerGui
	NOTICE.label = label(root(noticeGui), UDim2.fromOffset(0, NOTICE.TEXT_SIZE + 8), UDim2.new(0.5, 0, 0, NOTICE.TOP), NOTICE.TEXT_SIZE, 3) -- 3px outline (QM)
	NOTICE.label.AutomaticSize = Enum.AutomaticSize.X
	NOTICE.label.Visible = false

	-- Controllers (Gamepad): each button's pad button on its corner, shown only
	-- while a pad is in use, and the presses that work it.
	local TOP_RIGHT, RIGHT, LEFT = Vector2.new(0.92, 0.12), Vector2.new(1.05, 0.5), Vector2.new(-0.05, 0.5)
	Gamepad.hint(action, Enum.KeyCode.ButtonA, TOP_RIGHT)
	Gamepad.hint(sprint, Enum.KeyCode.ButtonL2, TOP_RIGHT)
	Gamepad.hint(ability, Enum.KeyCode.ButtonR1, Vector2.new(0.08, 0.12))
	Gamepad.hint(home, Enum.KeyCode.ButtonA, TOP_RIGHT)
	Gamepad.hint(continueButton, Enum.KeyCode.ButtonY, TOP_RIGHT)
	Gamepad.hint(ride, Enum.KeyCode.ButtonX, TOP_RIGHT) -- (the ride prompt's own gamepad key)
	Gamepad.hint(roll, Enum.KeyCode.ButtonX, TOP_RIGHT) -- (the Egg Machine prompt's)
	Gamepad.hint(mergeButton, Enum.KeyCode.ButtonY, TOP_RIGHT)
	Gamepad.hint(shopIcon, Enum.KeyCode.DPadUp, LEFT, 44) -- (the column's on the right edge: hints to its left)
	Gamepad.hint(fuseIcon, Enum.KeyCode.DPadLeft, LEFT, 44)
	Gamepad.hint(pets, Enum.KeyCode.DPadDown, LEFT, 44)
	Gamepad.hint(upgrade, Enum.KeyCode.DPadRight, LEFT, 44)
	local function onScreen(button)
		local screen = button and button:FindFirstAncestorOfClass("ScreenGui")
		return button ~= nil and button.Parent ~= nil and button.Visible and screen ~= nil and screen.Enabled
	end
	Gamepad.bind("Home", Enum.KeyCode.ButtonA, onHome, function()
		return onScreen(home)
	end)
	Gamepad.bind("Continue", Enum.KeyCode.ButtonY, onContinue, function()
		return onScreen(continueButton)
	end)
	Gamepad.bind("Merge", Enum.KeyCode.ButtonY, function()
		if Hud.onMerge then
			Hud.onMerge()
		end
	end, function()
		return onScreen(mergeButton)
	end)
	Gamepad.bind("Shop", Enum.KeyCode.DPadUp, function()
		if Shop.hasOffers() then
			Shop.toggle()
		end
	end, function()
		return onScreen(shopIcon)
	end)
	Gamepad.bind("Fuse", Enum.KeyCode.DPadLeft, function()
		if Hud.onFuse then
			Hud.onFuse()
		end
	end, function()
		return onScreen(fuseIcon)
	end)
	Gamepad.bind("Pets", Enum.KeyCode.DPadDown, AnimalDex.toggle, function()
		return onScreen(pets)
	end)
	Gamepad.bind("Upgrade", Enum.KeyCode.DPadRight, function()
		task.spawn(buyUpgrade)
	end, function()
		return onScreen(upgrade)
	end)
	-- The PC art's keys don't mean anything on a pad: the plain art while one's in use.
	Gamepad.onChanged(function(active)
		local swaps = {}
		for key, art in KEYBOARD_ART do
			local from, to = art.keys, art.plain
			if not active then
				from, to = to, from
			end
			IMAGES[key].id = to
			swaps[from] = to
		end
		if next(swaps) == nil then
			return
		end
		for _, screen in { gui, homeGui } do
			for _, d in screen:GetDescendants() do
				if (d:IsA("ImageButton") or d:IsA("ImageLabel")) and swaps[d.Image] then
					d.Image = swaps[d.Image]
				end
			end
		end
	end)

	-- Load every image now, so the first BUCKED OFF banner isn't still
	-- downloading while it animates. Downloading alone isn't enough: Roblox only
	-- readies an image for drawing the first time it's on screen, which stalls
	-- that frame. So each image also stays drawn in the corner at 1 pixel and
	-- nearly invisible, keeping it ready for the moment it's needed. Not on phones and
	-- tablets (LowMemory): pinned, these ~190 pictures hold ~300 MB there for good.
	local warm = Instance.new("Frame")
	warm.Name = "Preload"
	warm.BackgroundTransparency = 1
	warm.Size = UDim2.fromOffset(1, 1)
	warm.Parent = if LowMemory.on then nil else homeGui
	local labels = {}
	-- (QM, Nov 6: not with the native UI on: the PNG art never shows there)
	for key, entry in (if Config.NativeUi.On then {} else IMAGES) do
		if entry.id ~= "" then -- not uploaded yet
			local l = Instance.new("ImageLabel")
			l.Name = key
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromOffset(1, 1)
			l.Image = entry.id
			l.ImageTransparency = 0.99
			l.Parent = warm
			table.insert(labels, l)
		end
	end
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync(labels)
	end)
end

function Hud.show(visible)
	if visible then
		AnimalDex.close() -- off on a ride: no dictionary
		RollMenu.close()
		Shop.close()
		mergeWanted = false -- (MERGE is for home: it'd sit behind the fail screen's Home)
		mergeButton.Visible = false
	end
	gui.Enabled = visible
	if RideUi then
		RideUi.show(visible)
	end
	if visible then
		rollShown = false
		roll.Visible = false
	end
	if not visible then
		message.Text = ""
		banner.Visible = false
		home.Visible = false
		Hud.showContinue(nil)
	end
	ride.Visible = false -- comes back when the ride prompt shows again
	gold.Visible = not visible and tutorial == nil
	pets.Visible = not visible and tutorial == nil
	fuseIcon.Visible = not visible and ((tutorial == nil and Hud.fuseUnlocked()) or tutorial == "fuse")
	shopIcon.Visible = pets.Visible and Config.ShopOn
	upgrade.Visible = upgradeShown and not visible and tutorial == nil
	Inventory.setVisible(not visible and not lesson) -- your eggs, hidden while riding
	gained.row.Visible = false
	noCash = false
	Hud.setTip(nil)
	rideCash.row.Visible = SHOW_RIDE_TOP and (tutorial == nil)
	Hud.setReturning(false)
	Hud.setVignette(0)
	actionScale.Scale = 1
	setCash(0)
end

-- Shows or hides the Sprint button (on the way out only). Never on a phone or tablet:
-- pushing the joystick out sprints there (Ride.client, Config.TouchSprintAt).
local UIS = game:GetService("UserInputService")
local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled
function Hud.setSprint(visible, active)
	if RideUi then
		return RideUi.setSprint(visible, active)
	end
	sprint.Visible = visible and not touchOnly
	if not visible then
		sprintInput = nil
	end
end

-- The Ability button: nil hides it (the pet has no ability); otherwise ready is
-- 0..1 of the cooldown done (1 = ready) and seconds is the time left on it.
function Hud.setAbility(ready, seconds, active)
	if RideUi then
		return RideUi.setAbility(ready, seconds, active)
	end
	ability.Visible = ready ~= nil
	if not ready then
		abilityPressed = nil
		return
	end
	abilityFill.Size = UDim2.fromScale(1, ready)
	abilityReady.Image = IMAGES[if ready >= 1 then "ability" else "abilityFilling"].id
	abilityTime.Text = if ready < 1 and seconds then math.ceil(seconds) .. "s" else ""
end

-- Whether the Ability button was pressed since the last call (each press counts
-- once, however quick the tap).
function Hud.abilityPressed()
	if RideUi then
		return RideUi.abilityPressed()
	end
	local pressed = abilityPressed
	abilityPressed = nil
	return pressed == true
end

-- Whether the Sprint button is being held down right now.
function Hud.sprintHeld()
	if RideUi then
		return RideUi.sprintHeld()
	end
	if sprintInput and (sprintInput.UserInputState == Enum.UserInputState.End or sprintInput.UserInputState == Enum.UserInputState.Cancel) then
		sprintInput = nil
	end
	return sprintInput ~= nil
end

local TIRED_RED = Color3.fromRGB(255, 90, 90)

-- tired: whether an empty bar slows the mount (not while it carries an egg home).
function Hud.setHold(fraction, tired, total)
	if RideUi then
		return RideUi.setHold(fraction, tired, total)
	end
	holdFrame.Visible = fraction ~= nil
	if fraction then
		holdClip.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		-- Empty (the mount's tired, at half speed): the bar pulses a subtle red (QM, Oct 5).
		holdFrame.ImageColor3 = if fraction <= 0 and tired ~= false
			then Color3.new(1, 1, 1):Lerp(TIRED_RED, 0.5 + 0.5 * math.sin(os.clock() * math.pi * 2))
			else Color3.new(1, 1, 1)
	end
end

function Hud.setDistance(text)
	if RideUi then
		return RideUi.setDistance(text)
	end
	distance.Text = text
end

-- text = nil hides the button; ready = false shows LASSO's disabled image;
-- rarity picks TAKE EGG's colours.
function Hud.setAction(text, ready, rarity)
	if RideUi then
		return RideUi.setAction(text, ready, rarity)
	end
	action.Visible = text ~= nil
	if text then
		local key = ACTIONS[text]
		if key == "lasso" and not ready then
			key = "lassoDisabled"
		elseif key == "takeEgg" then
			key = EGG_BUTTONS[rarity] or key
		end
		action.Image = IMAGES[key].id
		action.Size = fit(key, BUTTON_WIDTH)
	end
	-- TAKE EGG pulses so it can't be missed.
	local egg = text ~= nil and ACTIONS[text] == "takeEgg"
	sunburst.Visible = egg and Config.TakeEggSunburst
	if egg then
		actionScale.Scale = 1 + 0.07 * math.sin(os.clock() * math.pi * 3)
		sunburst.Rotation = os.clock() * 25
	end
end

-- Slams a banner image in: drops from big to size fast, squashes, and shakes.
local function slam(target, key, width)
	target.Image = IMAGES[key].id
	target.Size = fit(key, width or IMAGES[key].size.X * BANNER_SCALE)
	target.Visible = true
	target.ImageTransparency = 1
	target.Rotation = -4
	local scale = target.UIScale
	scale.Scale = 3
	local rest = target.Position
	TweenService:Create(target, TweenInfo.new(0.12), { ImageTransparency = 0 }):Play()
	local drop = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
	drop.Completed:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
		TweenService:Create(target, TweenInfo.new(0.7, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		task.spawn(function()
			for i = 14, 1, -1 do
				target.Position = rest + UDim2.fromOffset(math.random(-i, i) * 2, math.random(-i, i) * 2)
				task.wait(0.03)
			end
			target.Position = rest
		end)
	end)
	drop:Play()
end

function Hud.flash(text, seconds)
	-- Fail screens hide the ride's cash and the ride back's look; the Home screen shows what was gained instead.
	if TONES[text] == RED then
		rideCash.row.Visible = false
		Hud.setVignette(0)
	end
	banner.Visible = false
	if BANNERS[text] then
		message.Text = ""
		slam(banner, BANNERS[text])
		return
	end
	message.Text = text
	message.TextColor3 = TONES[text] or WHITE
	message.TextTransparency = 0
	message.UIStroke.Transparency = 0
	message.Size = UDim2.fromOffset(500, 70)
	TweenService:Create(message, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(600, 80) }):Play()
	if seconds then
		task.delay(seconds, function()
			if message.Text == text then
				local fade = TweenInfo.new(0.3)
				TweenService:Create(message, fade, { TextTransparency = 1 }):Play()
				TweenService:Create(message.UIStroke, fade, { Transparency = 1 }):Play()
			end
		end)
	end
end

-- An egg you got (a ride home's, a roll's, a quest's, the shop's): straight into its reward
-- popup, no RNG card (QM, Nov 6: client/RewardPopups). batch: several at once, side by side.
-- Returns 0 (callers once waited out the card).
function Hud.revealing()
	return false
end

function Hud.eggReveal(rarity, kind, rolled, batch)
	Sounds.play(if rolled then "roll_reveal" else "reveal_pop")
	local counts, order = {}, {}
	for _, each in batch or { kind } do
		if not counts[each] then
			table.insert(order, each)
		end
		counts[each] = (counts[each] or 0) + 1
	end
	for _, each in order do
		-- (the Eggs panel's picture of it, client/NativeEggs; else the old render)
		local egg = IMAGES["egg" .. tostring(each)]
		local icon = Config.EggIcons[each] or (egg and egg.id ~= "" and egg.id) or IMAGES.eggPinto.id
		RewardPopups.show(icon, "x" .. counts[each])
	end
	return 0
end

-- Cutscenes hide the whole ride HUD.
-- The ride HUD slides off screen for the egg close-up. It isn't disabled:
-- re-enabling a ScreenGui rebuilds all its text and images in one frame, which
-- hitched as the cutscene ended.
function Hud.setCutscene(on)
	rideRoot.Position = if on then UDim2.fromScale(0.5, 3) else UDim2.fromScale(0.5, 0.5)
end

-- RIDE shows only while you're close enough to your animal (replaces the [E] prompt).
function Hud.showRide(visible)
	ride.Visible = visible and not gui.Enabled and not lesson
	Hud.showMerge(mergeWanted) -- RIDE comes first; MERGE takes the spot when it goes
	Inventory.setVisible(not ride.Visible and not mergeButton.Visible and not rollShown and not gui.Enabled and not lesson) -- the RIDE button takes its place
end

-- MERGE (QM): in RIDE's spot whenever you have pets to merge and RIDE isn't up;
-- it takes the place of your egg inventory.
function Hud.showMerge(visible)
	mergeWanted = visible
	local shown = visible and not ride.Visible and not rollShown and not gui.Enabled and not lesson
	if shown ~= mergeButton.Visible then
		mergeButton.Visible = shown
		Inventory.setVisible(not ride.Visible and not shown and not rollShown and not gui.Enabled and not lesson)
	end
end

-- The fuse lesson (FuseLesson, QM Oct 7): while it's on, nothing shows but Fuse and
-- what it leads you through: no RIDE (Ride.client won't ride either), MERGE, egg
-- slots, ROLL, nameplates (PetPlates) or the rest (setTutorial's "bare"/"fuse").
function Hud.setLesson(on)
	if on == lesson then
		return
	end
	lesson = on
	if on then
		ride.Visible, roll.Visible = false, false
	end
	-- The merge lesson's Fuse button: twice the size, kept on screen by growing up and
	-- in from its bottom right corner.
	if fuseIconAt then
		local at = fuseIconAt
		if on then
			local size = at.Size
			fuseIcon.Size = UDim2.fromOffset(size.X.Offset * LESSON_FUSE_SCALE, size.Y.Offset * LESSON_FUSE_SCALE)
			fuseIcon.AnchorPoint = Vector2.new(1, 1)
			fuseIcon.Position = at.Position + UDim2.fromOffset(size.X.Offset * (1 - at.AnchorPoint.X), 0)
		else
			fuseIcon.Size, fuseIcon.AnchorPoint, fuseIcon.Position = at.Size, at.AnchorPoint, at.Position
		end
	end
	Hud.showMerge(mergeWanted)
	Inventory.setVisible(not ride.Visible and not mergeButton.Visible and not rollShown and not gui.Enabled and not lesson)
end

function Hud.inLesson()
	return lesson
end

-- Ride back home: DODGE THE STAMPEDE! slams in, then pulses; no cash or distance.
function Hud.setReturning(returning)
	dodgePulse:Cancel()
	dodge.Visible = false
	if returning then
		slam(dodge, "dodge", 440)
		task.delay(1, function()
			if dodge.Visible then
				-- Ease down to 90%, then pulse 90%..110%.
				local down = TweenService:Create(dodge.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Scale = 0.9 })
				down.Completed:Connect(function(state)
					if state == Enum.PlaybackState.Completed and dodge.Visible then
						dodgePulse:Play()
					end
				end)
				down:Play()
			end
		end)
	end
	rideCash.row.Visible = SHOW_RIDE_TOP and (not returning and tutorial == nil)
	distance.Visible = SHOW_RIDE_TOP and not returning
end

-- Ride back's red vignette: 1 full, 0 gone. It and DODGE THE STAMPEDE! go once it's 0.
-- It breathes slowly, in time with the text's pulse.
function Hud.setVignette(strength)
	local breath = 1 - Config.VignettePulse * (0.5 + 0.5 * math.sin(os.clock() * math.pi / 0.6))
	vignette.Visible = strength > 0
	vignette.ImageTransparency = 1 - strength * Config.VignetteOpacity * breath
	if strength <= 0 and dodge.Visible then
		dodgePulse:Cancel()
		dodge.Visible = false
	end
end

-- The ability's screen tint: 0 = none, 1 = full, in `color`.
function Hud.setAbilityTint(strength, color)
	abilityTint.Visible = strength > 0.01
	abilityTint.ImageTransparency = 1 - strength
	if color then
		abilityTint.ImageColor3 = color
	end
end

-- Home button, shown after a failed ride with the cash gained; sends you back home.
function Hud.showHome(visible)
	home.Visible = visible
	local tipping = tipText.Text ~= ""
	tip.Visible = visible and tipping
	if tip.Visible then
		tip.UIScale.Scale = 0
		TweenService:Create(tip.UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	gained.row.Visible = visible and not noCash and not tipping
	if gained.row.Visible then
		gained.text.Text = "+" .. money(rideAmount)
		gained.scale.Scale = 0
		TweenService:Create(gained.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

-- The fail screen's Continue, above Home (QM's mockup): nil hides it, "ready"
-- shows it and "waiting" (the Robux prompt is up) dims it and Home (Ride ignores
-- Home until the prompt closes).
function Hud.showContinue(state)
	continueButton.Visible = state ~= nil
	local dim = if state == "waiting" then 0.5 else 0
	continueButton.ImageTransparency = dim
	home.ImageTransparency = dim
	if state == "ready" and not continueButton:GetAttribute("Shown") then
		continueButton:SetAttribute("Shown", true)
		continueButton.UIScale.Scale = 0
		TweenService:Create(continueButton.UIScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	elseif state == nil then
		continueButton:SetAttribute("Shown", nil)
	end
end

-- Continued after a fail (Ride.client): the fail screen goes and the ride's HUD
-- comes back as it was, the way out or the ride back.
function Hud.resume(returning)
	message.Text = ""
	banner.Visible = false
	home.Visible = false
	Hud.showContinue(nil)
	gained.row.Visible = false
	Hud.setTip(nil)
	Hud.setReturning(returning)
end

-- A tooltip in place of the fail screen's "+$N" (riding into a locked gate:
-- "Upgrade your pen to go further"); nil clears it. Shows with the Home button.
function Hud.setTip(text)
	tipText.Text = text or ""
	if not text then
		tip.Visible = false
	end
end

-- Fusing opens with the Desert: the Fuse button's hidden till then (QM, Oct 7), and
-- till the fuse lesson (FuseLesson) has shown it to you.
function Hud.fuseUnlocked()
	local player = Players.LocalPlayer
	return true -- (no fuse lesson any more, QM Oct 8: it shows once the tutorial's done)
end

-- The first-time tutorial (Tutorial.luau) shows only what each step needs.
-- stage "bare": no Gold, Pets or Upgrade Pen at home and no ride cash (Ride leaves
-- out Sprint, Ability and the Hold bar). "fuse": the same but for Fuse, the one
-- button showing, for the fuse lesson once the Desert's unlocked (FuseLesson). nil:
-- everything's back.
function Hud.setTutorial(stage)
	tutorial = stage
	local riding = gui.Enabled
	gold.Visible = not riding and stage == nil
	pets.Visible = not riding and stage == nil
	fuseIcon.Visible = not riding and ((stage == nil and Hud.fuseUnlocked()) or stage == "fuse")
	shopIcon.Visible = pets.Visible and Config.ShopOn
	upgrade.Visible = upgradeShown and not riding and stage == nil
	rideCash.row.Visible = SHOW_RIDE_TOP and (stage == nil and not noCash)
end

-- The Fuse button, for the fuse lesson's cursor.
function Hud.fuseButton()
	return fuseIcon
end

-- A line of text top centre (QM, Oct 5: "Return to your base to ride an animal!"
-- when you walk at the start line, WalkLimit.client), or nil to hide it.
function Hud.setNotice(text)
	if not NOTICE.label or NOTICE.label.Visible == (text ~= nil) and NOTICE.label.Text == (text or "") then
		return
	end
	NOTICE.label.Visible = text ~= nil
	NOTICE.label.Text = text or ""
end

-- Money as the HUD writes it: "$950", "$1.2k".
Hud.money = money
-- On a ride (the ride's screen is up): BaseUi hides then.
function Hud.isRiding()
	return gui ~= nil and gui.Enabled
end

-- nil: no cash at all this time (run over on foot): the ride's cash and the
-- fail screen's "+$N" stay hidden until the next ride.
function Hud.setCash(amount)
	noCash = amount == nil
	rideCash.row.Visible = SHOW_RIDE_TOP and (not noCash and tutorial == nil)
end

-- Cash gained this ride.
function Hud.setCoins(amount)
	setCash(amount and amount * Config.goldX(Players.LocalPlayer)) -- (the x2 Gold pass doubles what's banked: Passes)
	rideCash.scale.Scale = 1.25
	TweenService:Create(rideCash.scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- "+1" with a coin that pops in at a screen point, floats up and fades.
-- Same pattern as the common DevForum coin-popup recipe: pop with Back easing, rise with Quad, fade out.
function Hud.coinPopup(screenPoint, amount)
	screenPoint /= rootScale -- screen pixels -> HUD root pixels
	-- Same coin and "+N$" as the fail screen, a bit smaller.
	local popup = cashRow(homeRoot, 64, 44, Vector2.new(0.5, 0.5), UDim2.fromOffset(screenPoint.X, screenPoint.Y))
	popup.text.Text = "+" .. money(amount * Config.goldX(Players.LocalPlayer))
	popup.text.TextColor3 = Color3.fromHex("FFC41E") -- golden yellow, like the login money (QM, Oct 8)
	popup.scale.Scale = 0

	TweenService:Create(popup.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(popup.row, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(screenPoint.X, screenPoint.Y - 80),
	}):Play()
	task.delay(0.65, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(popup.text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(popup.text.UIStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(popup.coin, fade, { ImageTransparency = 1 }):Play()
	end)
	task.delay(1.05, function()
		popup.row:Destroy()
	end)
end

-- The same popup in the world: "+N$" over `part`, `height` studs above its
-- centre, following it as it moves and rising a few studs as it fades.
local coinDepth = 0
function Hud.coinPopupAt(part, height, amount)
	if not homeGui or not homeGui.Parent then
		return -- (a payout just after joining, before Hud.init has built the HUD)
	end
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(200, 80)
	board.Adornee = part
	board.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	coinDepth = (coinDepth + 1) % 400
	board.StudsOffset = Vector3.new(0, 0, coinDepth * 0.005) -- (each a hair nearer the camera: overlapping ones don't z-fight)
	board.LightInfluence = 0
	board.AlwaysOnTop = true
	board.MaxDistance = 150
	board.ResetOnSpawn = false
	-- The same size as training's "+1" lasso popup (Training.client: 34 px icon, 30 px text; QM, Oct 8).
	local popup = cashRow(board, 34, 30, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5))
	popup.text.Text = "+" .. money(amount * Config.goldX(Players.LocalPlayer))
	popup.scale.Scale = 0
	board.Parent = homeGui.Parent

	TweenService:Create(popup.scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(board, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, height + 3, 0),
	}):Play()
	task.delay(0.65, function()
		local fade = TweenInfo.new(0.35)
		TweenService:Create(popup.text, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(popup.text.UIStroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(popup.coin, fade, { ImageTransparency = 1 }):Play()
	end)
	task.delay(1.05, function()
		board:Destroy()
	end)
end

return Hud
