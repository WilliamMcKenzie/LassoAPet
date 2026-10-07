-- Preloads the UI's images soon after joining (QM, Oct 4: the shop and the animal
-- dictionary's pages took ages to show the first time). The big menu panels come
-- first and stay loaded (each drawn 1 px and nearly see-through on a screen that's
-- always on, as AnimalDex does for its sheets, so they aren't dropped); then every
-- other picture the UI uses, in the background. Nothing waits on it.
--
-- The lists are every image id in the client's scripts and Config (made with a script;
-- re-run it when art is added: see the commit). Sounds preload in Sounds.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

-- The shop's, the roll menu's and the dictionary's pages, and the Fuse menu's art
-- (its panel, FUSE button, rarity cards and the Fuse icon: QM, Oct 6).
local PANELS = {
	"rbxassetid://105155399825774", "rbxassetid://83654143211576", "rbxassetid://73979296990982",
	"rbxassetid://70887174133121", "rbxassetid://136220197688301", "rbxassetid://103982023506783",
	"rbxassetid://125476338322601", "rbxassetid://102515912144773", "rbxassetid://104698392936555",
	"rbxassetid://110875946388838", "rbxassetid://119520152431016", "rbxassetid://78091503897812",
	"rbxassetid://77735968469215", "rbxassetid://112429560665609", "rbxassetid://93558185988056",
	"rbxassetid://80615979394374", "rbxassetid://120348389827821", "rbxassetid://74328700033740", -- (the FUSE button on and off)
	"rbxassetid://132460179762796", "rbxassetid://92820434532680", "rbxassetid://79697917998703",
	"rbxassetid://129147449223279", "rbxassetid://72145821537095", "rbxassetid://137693950544184",
	"rbxassetid://80504921595928", "rbxassetid://132069626373718",
}

-- Everything else: HUD buttons, egg cards, headshots, egg renders, the dictionary's
-- running sheets, gates and the rest.
local REST = {
	"rbxassetid://104292931687556", "rbxassetid://94121512214531", "rbxassetid://83416502851504",
	"rbxassetid://108897443176698", "rbxassetid://134299381559519", "rbxassetid://115987106435760",
	"rbxassetid://91332218189700", "rbxassetid://124255755969598", "rbxassetid://96827860827213",
	"rbxassetid://130261551778736", "rbxassetid://102545209742676", "rbxassetid://114839635512682",
	"rbxassetid://137889269113133", "rbxassetid://82401653732533", "rbxassetid://128272625286546",
	"rbxassetid://90844952883979", "rbxassetid://107116554539032", "rbxassetid://76827079745406",
	"rbxassetid://99312860837685", "rbxassetid://120690804030353", "rbxassetid://134427342737800",
	"rbxassetid://137561422342054", "rbxassetid://114155984376753", "rbxassetid://93889609154413",
	"rbxassetid://104509002348710", "rbxassetid://95632395593874", "rbxassetid://86071723052223",
	"rbxassetid://77096507947185", "rbxassetid://113381581343322", "rbxassetid://111066508903972",
	"rbxassetid://73673910929091", "rbxassetid://112042125080788", "rbxassetid://94491197892789",
	"rbxassetid://124659626997084", "rbxassetid://96698232796495", "rbxassetid://79525419811481",
	"rbxassetid://139970505549400", "rbxassetid://105098230793344", "rbxassetid://139482781062355",
	"rbxassetid://85066893166855", "rbxassetid://95599437590618", "rbxassetid://84668325203507",
	"rbxassetid://102795691143589", "rbxassetid://90142926499080", "rbxassetid://111649507533762",
	"rbxassetid://135143840112034", "rbxassetid://105231134861157", "rbxassetid://131132122596946",
	"rbxassetid://137113936385932", "rbxassetid://103638328020279", "rbxassetid://86307268458670",
	"rbxassetid://93831958938146", "rbxassetid://78320352111053", "rbxassetid://128883182267763",
	"rbxassetid://97101351248514", "rbxassetid://80563240117126", "rbxassetid://119349539273288",
	"rbxassetid://95626930006876", "rbxassetid://114368032731288", "rbxassetid://137156704531563",
	"rbxassetid://70469571709365", "rbxassetid://84356622911486", "rbxassetid://136725772402125",
	"rbxassetid://140005979942732", "rbxassetid://95236739672996", "rbxassetid://125494868051538",
	"rbxassetid://136877153343024", "rbxassetid://85550148075389", "rbxassetid://101879608972078",
	"rbxassetid://118282623101402", "rbxassetid://120239297848540", "rbxassetid://99201367360467",
	"rbxassetid://85357705922490", "rbxassetid://130844925944438", "rbxassetid://120149236853502",
	"rbxassetid://126037490360673", "rbxassetid://114358725443293", "rbxassetid://105026411084404",
	"rbxassetid://108540506579286", "rbxassetid://96425037730261", "rbxassetid://109623848986836",
	"rbxassetid://113606148401403", "rbxassetid://79124427569630", "rbxassetid://116109970242443",
	"rbxassetid://131302675159660", "rbxassetid://94170840211405", "rbxassetid://139839156164981",
	"rbxassetid://94192117186470", "rbxassetid://131389846384914", "rbxassetid://125520132317720",
	"rbxassetid://79068936169772", "rbxassetid://103163746025717", "rbxassetid://103797474563946",
	"rbxassetid://88553226475116", "rbxassetid://101217167881986", "rbxassetid://121345968224573",
	"rbxassetid://122418900338409", "rbxassetid://120731347381935", "rbxassetid://103485896070996",
	"rbxassetid://71539574618443", "rbxassetid://101851743328298", "rbxassetid://130093266232562",
	"rbxassetid://115620712947682", "rbxassetid://77455009647862", "rbxassetid://104966778015588",
	"rbxassetid://74812837390041", "rbxassetid://104986890781116", "rbxassetid://129206679931938",
	"rbxassetid://137788325926698", "rbxassetid://126771183103796", "rbxassetid://73704828076245",
	"rbxassetid://135065306024440", "rbxassetid://123940745305285", "rbxassetid://95422181220957",
	"rbxassetid://85451012004987", "rbxassetid://122144649250110", "rbxassetid://91376372256857",
	"rbxassetid://122284072508208", "rbxassetid://126516601606999", "rbxassetid://131420314948529",
	"rbxassetid://88911086754037", "rbxassetid://110647985191783", "rbxassetid://97270712812416",
	"rbxassetid://94992992543344", "rbxassetid://76507499572286", "rbxassetid://97706370740023",
	"rbxassetid://114559155845756", "rbxassetid://109306533952798", "rbxassetid://131403632828209",
	"rbxassetid://122498091168554", "rbxassetid://115675656988340", "rbxassetid://112526271674778",
	"rbxassetid://132126224577278", "rbxassetid://110728718265049", "rbxassetid://88035044263993",
	"rbxassetid://102872657938822", "rbxassetid://119834887149656", "rbxassetid://93677343741816",
	"rbxassetid://137596967858841", "rbxassetid://120075276423928", "rbxassetid://92909054184182",
	"rbxassetid://75096704585668", "rbxassetid://100279863676585", "rbxassetid://135663178618300",
	"rbxassetid://93909017403661", "rbxassetid://110142835452075", "rbxassetid://87420526826729",
	"rbxassetid://91804135266195", "rbxassetid://140505417870582", "rbxassetid://116651352653628",
	"rbxassetid://93240211999923", "rbxassetid://101032148634562", "rbxassetid://7447638591",
	"rbxassetid://17520182385", "rbxassetid://7216979807", "rbxassetid://73420824782915",
	"rbxassetid://113778810800288", "rbxassetid://78830244894115", "rbxassetid://81637358609980",
	"rbxassetid://93384010922515", "rbxassetid://88059029653274", "rbxassetid://110114947102534",
	"rbxassetid://75356296124042", "rbxassetid://98442121637216", "rbxassetid://134800932476227",
	"rbxassetid://81079145393331", "rbxassetid://133410257702964", "rbxassetid://75177337427277",
}

local warm = Instance.new("ScreenGui")
warm.Name = "PreloadWarm"
warm.ResetOnSpawn = false
for _, id in PANELS do
	local keep = Instance.new("ImageLabel")
	keep.BackgroundTransparency = 1
	keep.Size = UDim2.fromOffset(1, 1)
	keep.Image = id
	keep.ImageTransparency = 0.99
	keep.Parent = warm
end
warm.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

task.spawn(function()
	pcall(ContentProvider.PreloadAsync, ContentProvider, warm:GetChildren())
	-- (as image labels, not bare ids: PreloadAsync fails plain image id strings)
	local labels = {}
	for _, id in REST do
		local label = Instance.new("ImageLabel")
		label.Image = id
		table.insert(labels, label)
	end
	pcall(ContentProvider.PreloadAsync, ContentProvider, labels)
end)
