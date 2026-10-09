-- No UI art for now (QM, Oct 9: all of it's being redrawn). While Config.UiArt is
-- false, every UI picture (ImageLabel / ImageButton on your screen, or on a
-- BillboardGui or SurfaceGui in the world) is drawn as a plain placeholder instead:
-- a flat rounded box, its art's name written on it, so it still works and shows
-- where the new art goes. Its size and position are the art's, untouched. Buttons
-- that swap art (Enabled / Disabled) swap names; "Enabled", "On" and "Filled" ones
-- are green, "Disabled" and "Off" ones darker.
--
-- Left as they are: egg renders (Config.EggIcons), pet headshots (PetFaces) and the
-- dictionary's running animals (AnimalDex): those are content, not UI. And two
-- effects: the ride's vignette and the sunburst behind the egg reveal.
--
-- The names come from the art's file names in the scripts (made with a script;
-- re-run it when art is added). Setting Config.UiArt back to true puts the art back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

if Config.UiArt ~= false then
	return
end

local KEEP = {
	["101217167881986"] = true, ["101851743328298"] = true, ["102165948456968"] = true, ["102545209742676"] = true,
	["102795691143589"] = true, ["102872657938822"] = true, ["103163746025717"] = true, ["103485896070996"] = true,
	["103638328020279"] = true, ["103797474563946"] = true, ["104966778015588"] = true, ["104986890781116"] = true,
	["105026411084404"] = true, ["105098230793344"] = true, ["105231134861157"] = true, ["108540506579286"] = true,
	["109306533952798"] = true, ["109509060486808"] = true, ["109623848986836"] = true, ["110647985191783"] = true,
	["110728718265049"] = true, ["111649507533762"] = true, ["112526271674778"] = true, ["113606148401403"] = true,
	["114358725443293"] = true, ["114368032731288"] = true, ["114559155845756"] = true, ["115620712947682"] = true,
	["115675656988340"] = true, ["116109970242443"] = true, ["119349539273288"] = true, ["119834887149656"] = true,
	["120149236853502"] = true, ["120731347381935"] = true, ["121345968224573"] = true, ["122144649250110"] = true,
	["122284072508208"] = true, ["122418900338409"] = true, ["122498091168554"] = true, ["123940745305285"] = true,
	["124881834655792"] = true, ["125520132317720"] = true, ["126037490360673"] = true, ["126516601606999"] = true,
	["126771183103796"] = true, ["128883182267763"] = true, ["129206679931938"] = true, ["130093266232562"] = true,
	["130261551778736"] = true, ["131132122596946"] = true, ["131302675159660"] = true, ["131389846384914"] = true,
	["131403632828209"] = true, ["131420314948529"] = true, ["132126224577278"] = true, ["135065306024440"] = true,
	["135143840112034"] = true, ["136725772402125"] = true, ["137113936385932"] = true, ["137156704531563"] = true,
	["137788325926698"] = true, ["139482781062355"] = true, ["139839156164981"] = true, ["139970505549400"] = true,
	["140005979942732"] = true, ["70469571709365"] = true, ["71539574618443"] = true, ["73704828076245"] = true,
	["74812837390041"] = true, ["76507499572286"] = true, ["76735200273090"] = true, ["77455009647862"] = true,
	["77770407898290"] = true, ["78320352111053"] = true, ["79068936169772"] = true, ["79124427569630"] = true,
	["79525419811481"] = true, ["80563240117126"] = true, ["84356622911486"] = true, ["84668325203507"] = true,
	["85066893166855"] = true, ["85451012004987"] = true, ["85779463172831"] = true, ["86307268458670"] = true,
	["88035044263993"] = true, ["88553226475116"] = true, ["88911086754037"] = true, ["90142926499080"] = true,
	["91376372256857"] = true, ["93677343741816"] = true, ["93831958938146"] = true, ["94170840211405"] = true,
	["94192117186470"] = true, ["94992992543344"] = true, ["95236739672996"] = true, ["95422181220957"] = true,
	["95599437590618"] = true, ["95626930006876"] = true, ["96425037730261"] = true, ["96698232796495"] = true,
	["97101351248514"] = true, ["97270712812416"] = true, ["97706370740023"] = true,
}

local NAMES = {
	["95632395593874"] = "Ability", ["86071723052223"] = "AbilityCooldown", ["85357705922490"] = "AbilitySPACE", ["13107325341"] = "Bk",
	["13107329809"] = "Bk", ["13107334845"] = "Bk", ["84747779882944"] = "CHECKER", ["99312860837685"] = "COIN",
	["135663178618300"] = "Claim", ["79697917998703"] = "Common", ["126644097924232"] = "CommonPanel", ["124255755969598"] = "Continue",
	["130844925944438"] = "DexArrow", ["77735968469215"] = "DexDesertExamine", ["80615979394374"] = "DexGodlandsExamine", ["78091503897812"] = "DexMeadowExamine",
	["93558185988056"] = "DexOceanExamine", ["112429560665609"] = "DexSnowExamine", ["71726481257884"] = "DisabledRainbowTrail", ["137693950544184"] = "Epic",
	["94491197892789"] = "EpicEggRNG", ["81588505365795"] = "FLAT", ["92820434532680"] = "FuseButton", ["74328700033740"] = "FuseButtonOff",
	["120348389827821"] = "FuseButtonOn", ["132460179762796"] = "FusionPanel", ["113778810800288"] = "GateDesert", ["81079145393331"] = "GateGodlands",
	["75356296124042"] = "GateOcean", ["93384010922515"] = "GateTundra", ["101032148634562"] = "GuideArrow", ["118282623101402"] = "LassoDisabledE",
	["101879608972078"] = "LassoE", ["80504921595928"] = "Legendary", ["124659626997084"] = "LegendaryEggRNG", ["13107337703"] = "Lf",
	["13107340396"] = "Lf", ["13107344387"] = "Lf", ["126004469719414"] = "MergeIcon", ["92882303663654"] = "MergePanel",
	["134299381559519"] = "MergePet", ["87748999824256"] = "PassPopupAutoHatch", ["135226874634598"] = "PassPopupDoubleGold", ["85992452177736"] = "PassPopupFastHatch",
	["132592725982767"] = "PassPopupVIP", ["74500954492785"] = "RainbowTrail", ["72145821537095"] = "Rare", ["112042125080788"] = "RareEggRNG",
	["120239297848540"] = "RideE", ["112026122025466"] = "RollButton", ["104698392936555"] = "RollPanel", ["110875946388838"] = "RollPanelOdds",
	["7447638591"] = "STUDS", ["105477086117375"] = "Shop", ["73979296990982"] = "ShopGiantHorse", ["136220197688301"] = "ShopGold100k",
	["103982023506783"] = "ShopGold1M", ["125476338322601"] = "ShopLegendaryEgg", ["102515912144773"] = "ShopLegendaryEggOdds", ["83654143211576"] = "ShopOddsButton",
	["105155399825774"] = "ShopPanel", ["70887174133121"] = "ShopSpawnLoong", ["137596967858841"] = "SlotCommon", ["75096704585668"] = "SlotEpic",
	["100279863676585"] = "SlotLegendary", ["92909054184182"] = "SlotRare", ["120075276423928"] = "SlotUncommon", ["99201367360467"] = "SprintSHIFT",
	["93240211999923"] = "TutorialCursor", ["129147449223279"] = "Uncommon", ["73673910929091"] = "UncommonEggRNG", ["77096507947185"] = "UnknownEgg",
	["113381581343322"] = "UnknownEgg1", ["111066508903972"] = "UnknownEgg2", ["120690804030353"] = "UpgradePenActive", ["97537967185164"] = "UpgradePenDesertDisabled",
	["134340111977085"] = "UpgradePenDesertEnabled", ["134427342737800"] = "UpgradePenDisabled", ["73528380270412"] = "UpgradePenGodlandsDisabled", ["122300024756957"] = "UpgradePenGodlandsEnabled",
	["98686807740770"] = "UpgradePenOceanDisabled", ["86611519789045"] = "UpgradePenOceanEnabled", ["133303061216721"] = "UpgradePenTundraDisabled", ["105968538824751"] = "UpgradePenTundraEnabled",
	["10509843977"] = "WELD", ["87800549075293"] = "arrive_home", ["128272625286546"] = "barEmpty", ["82401653732533"] = "barFilled",
	["1840347412"] = "base", ["121038229911289"] = "book_flip", ["93383284601909"] = "book_open", ["114839635512682"] = "buckedOff",
	["102399207280537"] = "button_click", ["137889269113133"] = "crash", ["94142874131984"] = "crash", ["96827860827213"] = "dodge",
	["94379425317312"] = "egg_grab", ["112644148635720"] = "egg_hatch", ["76827079745406"] = "eggs", ["129029116650332"] = "gallop_loop",
	["9116938119"] = "gate_break", ["123673857032707"] = "gold_tick", ["91332218189700"] = "home", ["94121512214531"] = "lasso",
	["83416502851504"] = "lassoDisabled", ["132698985263025"] = "lasso_land", ["80604101469428"] = "lasso_throw", ["102947888103382"] = "merge_poof",
	["130377429757922"] = "merge_pop", ["131427370077297"] = "merge_whoosh", ["90844952883979"] = "pets", ["127625005664662"] = "purchase",
	["117371326373841"] = "reveal_pop", ["91812796089050"] = "reveal_tick", ["108897443176698"] = "ride", ["1836101135"] = "ride",
	["101552385373858"] = "roll_reveal", ["90604529915688"] = "smash", ["104509002348710"] = "sprint", ["73983934702758"] = "sprint_whoosh",
	["104292931687556"] = "takeEgg", ["114155984376753"] = "takeEggEpic", ["93889609154413"] = "takeEggLegendary", ["137561422342054"] = "takeEggRare",
}

local GREY = Color3.fromRGB(95, 98, 110)
local ON = Color3.fromRGB(70, 150, 80)
local OFF = Color3.fromRGB(60, 62, 70)
local PLACEHOLDER = "ArtPlaceholder"

local function colourFor(name)
	if name:find("Disabled") or name:find("Off") then
		return OFF
	elseif name:find("Enabled") or name:find("On$") or name:find("Filled") or name:find("Active") then
		return ON
	end
	return GREY
end

local done = {} -- [image] = true once it's watched

local function show(image)
	local id = string.match(image.Image, "%d+")
	if not id or KEEP[id] or image:FindFirstAncestor("PreloadWarm") then
		return
	end
	local name = NAMES[id] or image.Name
	image.Image = ""
	image.BackgroundColor3 = colourFor(name)
	image.BackgroundTransparency = 0.2 + 0.8 * image.ImageTransparency
	if not image:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = image
	end
	local label = image:FindFirstChild(PLACEHOLDER)
	if not label then
		label = Instance.new("TextLabel")
		label.Name = PLACEHOLDER
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.9, 0.8)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Active = false
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 2
		stroke.Parent = label
		local size = Instance.new("UITextSizeConstraint")
		size.MaxTextSize = 28
		size.Parent = label
		label.Parent = image
	end
	label.Text = name
	label.ZIndex = image.ZIndex
	label.TextTransparency = image.ImageTransparency
	label.UIStroke.Transparency = image.ImageTransparency
end

local function watch(image)
	if done[image] or not (image:IsA("ImageLabel") or image:IsA("ImageButton")) then
		return
	end
	done[image] = true
	show(image)
	image:GetPropertyChangedSignal("Image"):Connect(function()
		if image.Image ~= "" then
			show(image) -- (it swapped art: Enabled / Disabled and the like)
		end
	end)
	image:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
		local label = image:FindFirstChild(PLACEHOLDER)
		if label then -- (fading in and out as the art did)
			image.BackgroundTransparency = 0.2 + 0.8 * image.ImageTransparency
			label.TextTransparency = image.ImageTransparency
			label.UIStroke.Transparency = image.ImageTransparency
		end
	end)
	image.Destroying:Connect(function()
		done[image] = nil
	end)
end

local function inWorldGui(inst)
	return inst:FindFirstAncestorWhichIsA("BillboardGui") ~= nil or inst:FindFirstAncestorWhichIsA("SurfaceGui") ~= nil
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
playerGui.DescendantAdded:Connect(watch)
for _, inst in playerGui:GetDescendants() do
	watch(inst)
end
workspace.DescendantAdded:Connect(function(inst)
	if (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) and inWorldGui(inst) then
		watch(inst)
	end
end)
for _, inst in workspace:GetDescendants() do
	if (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) and inWorldGui(inst) then
		watch(inst)
	end
end
