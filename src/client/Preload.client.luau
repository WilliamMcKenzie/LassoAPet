-- Preloads the UI's images soon after joining (QM, Oct 4: the shop and the animal
-- dictionary's pages took ages to show the first time; Oct 13: all of the UI's art, so
-- none of it pops in late). Every picture the client's scripts use (the HUD, menus,
-- popups and buttons) comes first and stays loaded (each drawn 1 px and nearly see-through
-- on a screen that's always on, as AnimalDex does for its sheets, so they aren't dropped);
-- then the headshots, the dictionary's sheets and Config's art, in the background.
-- Nothing waits on it.
--
-- The lists are made by tools/preload_ids.py: re-run it when art is added. Sounds
-- preload in Sounds.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

-- Every image in the client's scripts (tools/preload_ids.py).
local PANELS = {
	"rbxassetid://127821178410489", "rbxassetid://119060039201858", "rbxassetid://135845846149671",
	"rbxassetid://126251339270486", "rbxassetid://72356826090260", "rbxassetid://76663783463176",
	"rbxassetid://120142364189594", "rbxassetid://133997765094952", "rbxassetid://72901094417133",
	"rbxassetid://72181051059940", "rbxassetid://115847818752186", "rbxassetid://136367932806454",
	"rbxassetid://88826165672196", "rbxassetid://76511917573203", "rbxassetid://113926447181781",
	"rbxassetid://136773861994278", "rbxassetid://128175495014059", "rbxassetid://85408798859805",
	"rbxassetid://7447638591", "rbxassetid://87361968703172", "rbxassetid://77533462942727",
	"rbxassetid://88460994933250", "rbxassetid://84920756991403", "rbxassetid://104292931687556",
	"rbxassetid://94121512214531", "rbxassetid://83416502851504", "rbxassetid://108897443176698",
	"rbxassetid://134299381559519", "rbxassetid://91332218189700", "rbxassetid://124255755969598",
	"rbxassetid://96827860827213", "rbxassetid://130261551778736", "rbxassetid://102545209742676",
	"rbxassetid://114839635512682", "rbxassetid://137889269113133", "rbxassetid://82401653732533",
	"rbxassetid://128272625286546", "rbxassetid://90844952883979", "rbxassetid://126004469719414",
	"rbxassetid://105477086117375", "rbxassetid://104698392936555", "rbxassetid://110875946388838",
	"rbxassetid://112026122025466", "rbxassetid://76827079745406", "rbxassetid://99312860837685",
	"rbxassetid://120690804030353", "rbxassetid://134427342737800", "rbxassetid://137561422342054",
	"rbxassetid://114155984376753", "rbxassetid://93889609154413", "rbxassetid://104509002348710",
	"rbxassetid://95632395593874", "rbxassetid://86071723052223", "rbxassetid://89190624413208",
	"rbxassetid://128255311278989", "rbxassetid://79213006654938", "rbxassetid://84991607264564",
	"rbxassetid://77508300986598", "rbxassetid://87221432893647", "rbxassetid://82895123115484",
	"rbxassetid://74773300097555", "rbxassetid://87136104713556", "rbxassetid://96698232796495",
	"rbxassetid://79525419811481", "rbxassetid://139970505549400", "rbxassetid://102165948456968",
	"rbxassetid://105098230793344", "rbxassetid://139482781062355", "rbxassetid://110439659872687",
	"rbxassetid://101332917430774", "rbxassetid://112045413530937", "rbxassetid://102610484944753",
	"rbxassetid://84196239547123", "rbxassetid://132151928968903", "rbxassetid://121162393893227",
	"rbxassetid://112194074349421", "rbxassetid://117236752430565", "rbxassetid://82682007346790",
	"rbxassetid://118027620960011", "rbxassetid://138455431560057", "rbxassetid://98286776885826",
	"rbxassetid://132028611021169", "rbxassetid://121895939250438", "rbxassetid://79662614434978",
	"rbxassetid://113695299206853", "rbxassetid://126802958042799", "rbxassetid://137731947260447",
	"rbxassetid://105220500829443", "rbxassetid://129763838096024", "rbxassetid://132120882288488",
	"rbxassetid://100476636621954", "rbxassetid://131073330411941", "rbxassetid://109185103681711",
	"rbxassetid://139551342957176", "rbxassetid://136557216823067", "rbxassetid://78918914654470",
	"rbxassetid://130649889910224", "rbxassetid://111594299533130", "rbxassetid://125301165432908",
	"rbxassetid://136135901593127", "rbxassetid://112691374931555", "rbxassetid://106883633786837",
	"rbxassetid://121784684526161", "rbxassetid://92522948167443", "rbxassetid://110560724842212",
	"rbxassetid://124688776792586", "rbxassetid://114106715330048", "rbxassetid://117473019333658",
	"rbxassetid://120782360993998", "rbxassetid://93281428675559", "rbxassetid://117861828286868",
	"rbxassetid://91869381995495", "rbxassetid://113530717781179", "rbxassetid://90717259678888",
	"rbxassetid://85066893166855", "rbxassetid://95599437590618", "rbxassetid://124881834655792",
	"rbxassetid://84668325203507", "rbxassetid://102795691143589", "rbxassetid://90142926499080",
	"rbxassetid://111649507533762", "rbxassetid://135143840112034", "rbxassetid://105231134861157",
	"rbxassetid://131132122596946", "rbxassetid://137113936385932", "rbxassetid://103638328020279",
	"rbxassetid://86307268458670", "rbxassetid://93831958938146", "rbxassetid://78320352111053",
	"rbxassetid://128883182267763", "rbxassetid://97101351248514", "rbxassetid://80563240117126",
	"rbxassetid://119349539273288", "rbxassetid://95626930006876", "rbxassetid://100787444937359",
	"rbxassetid://82336240433052", "rbxassetid://105149417332337", "rbxassetid://83951862994609",
	"rbxassetid://137754762277353", "rbxassetid://132088301588431", "rbxassetid://86585294053216",
	"rbxassetid://118684084308728", "rbxassetid://125349573529100", "rbxassetid://117144807245289",
	"rbxassetid://119803210932578", "rbxassetid://139955585467041", "rbxassetid://77371080716061",
	"rbxassetid://89848692685766", "rbxassetid://114368032731288", "rbxassetid://114164241366433",
	"rbxassetid://130227469695086", "rbxassetid://137156704531563", "rbxassetid://70469571709365",
	"rbxassetid://84356622911486", "rbxassetid://136725772402125", "rbxassetid://140005979942732",
	"rbxassetid://95236739672996", "rbxassetid://101879608972078", "rbxassetid://118282623101402",
	"rbxassetid://120239297848540", "rbxassetid://99201367360467", "rbxassetid://85357705922490",
	"rbxassetid://93240211999923", "rbxassetid://119064104030965", "rbxassetid://71854224710325",
	"rbxassetid://9120972321", "rbxassetid://86824541929406", "rbxassetid://137596967858841",
	"rbxassetid://120075276423928", "rbxassetid://92909054184182", "rbxassetid://75096704585668",
	"rbxassetid://100279863676585", "rbxassetid://85834206672187", "rbxassetid://100466055719917",
	"rbxassetid://128119306382781", "rbxassetid://108884731983075", "rbxassetid://126647709261103",
	"rbxassetid://78103765703011", "rbxassetid://75097533166591", "rbxassetid://118605133730785",
	"rbxassetid://124966752636756", "rbxassetid://17520182385", "rbxassetid://7216979807",
	"rbxassetid://73420824782915", "rbxassetid://140037705020050", "rbxassetid://90506809044433",
	"rbxassetid://83654143211576", "rbxassetid://103831602991183", "rbxassetid://99393989394598",
	"rbxassetid://127128286637741", "rbxassetid://100105531661393", "rbxassetid://104044722461852",
	"rbxassetid://95428452126143", "rbxassetid://99027271786746", "rbxassetid://111300482619596",
	"rbxassetid://82082521618286", "rbxassetid://79299508640873", "rbxassetid://131361280239840",
	"rbxassetid://134865745295413", "rbxassetid://128484192846174", "rbxassetid://118018475359108",
	"rbxassetid://139647408711436", "rbxassetid://114889489768256", "rbxassetid://90551038508587",
	"rbxassetid://83311618092760", "rbxassetid://84547643672529", "rbxassetid://71738076831384",
	"rbxassetid://104793392329968", "rbxassetid://73306793972865", "rbxassetid://108726643390976",
	"rbxassetid://88891851849945", "rbxassetid://108345016053649", "rbxassetid://117854477071908",
	"rbxassetid://123640921226077", "rbxassetid://122859842408693", "rbxassetid://72409176941710",
	"rbxassetid://104387240097786", "rbxassetid://128346351326066",
}

-- The headshots, the dictionary's sheets and Config's (tools/preload_ids.py).
local REST = {
	"rbxassetid://103615321543388", "rbxassetid://133433182612945", "rbxassetid://120149236853502",
	"rbxassetid://126037490360673", "rbxassetid://114358725443293", "rbxassetid://105026411084404",
	"rbxassetid://108540506579286", "rbxassetid://96425037730261", "rbxassetid://109509060486808",
	"rbxassetid://76735200273090", "rbxassetid://92445178825484", "rbxassetid://84423041173252",
	"rbxassetid://101259765786362", "rbxassetid://98609799525177", "rbxassetid://136257565701438",
	"rbxassetid://116867911164006", "rbxassetid://107947322659885", "rbxassetid://83277205426899",
	"rbxassetid://118475104372693", "rbxassetid://122762734286787", "rbxassetid://110282216559726",
	"rbxassetid://122123351672825", "rbxassetid://134915752151829", "rbxassetid://107213392278992",
	"rbxassetid://82014579609498", "rbxassetid://111810935342924", "rbxassetid://120212888052337",
	"rbxassetid://109623848986836", "rbxassetid://113606148401403", "rbxassetid://79124427569630",
	"rbxassetid://116109970242443", "rbxassetid://131302675159660", "rbxassetid://94170840211405",
	"rbxassetid://139839156164981", "rbxassetid://94192117186470", "rbxassetid://131389846384914",
	"rbxassetid://125520132317720", "rbxassetid://79068936169772", "rbxassetid://103163746025717",
	"rbxassetid://98236364459356", "rbxassetid://103797474563946", "rbxassetid://88553226475116",
	"rbxassetid://101217167881986", "rbxassetid://121345968224573", "rbxassetid://122418900338409",
	"rbxassetid://120731347381935", "rbxassetid://103485896070996", "rbxassetid://71539574618443",
	"rbxassetid://101851743328298", "rbxassetid://130093266232562", "rbxassetid://115620712947682",
	"rbxassetid://77455009647862", "rbxassetid://104966778015588", "rbxassetid://74812837390041",
	"rbxassetid://104986890781116", "rbxassetid://129206679931938", "rbxassetid://137788325926698",
	"rbxassetid://126771183103796", "rbxassetid://77770407898290", "rbxassetid://73704828076245",
	"rbxassetid://135065306024440", "rbxassetid://108907184921325", "rbxassetid://104988827630449",
	"rbxassetid://130282330232819", "rbxassetid://124374143045410", "rbxassetid://130801596510368",
	"rbxassetid://138212580504024", "rbxassetid://116976247481915", "rbxassetid://98660783250158",
	"rbxassetid://81727302148573", "rbxassetid://88231046504339", "rbxassetid://76004844910290",
	"rbxassetid://98539038654284", "rbxassetid://130020402774350", "rbxassetid://116932906016084",
	"rbxassetid://122315330787047", "rbxassetid://76139030639613", "rbxassetid://138705038863318",
	"rbxassetid://91347373015350", "rbxassetid://126713751536950", "rbxassetid://86322926031259",
	"rbxassetid://104704985706188", "rbxassetid://127357727820671", "rbxassetid://116913111074004",
	"rbxassetid://70444854729766", "rbxassetid://119374884181309", "rbxassetid://90243386568029",
	"rbxassetid://73580594665861", "rbxassetid://92233802055091", "rbxassetid://109269281877417",
	"rbxassetid://128928489315063", "rbxassetid://139371473138755", "rbxassetid://89762462451770",
	"rbxassetid://131844695881348", "rbxassetid://128134052112067", "rbxassetid://83668558501850",
	"rbxassetid://76021920369476", "rbxassetid://72122408163416", "rbxassetid://84160086379257",
	"rbxassetid://92501064864589", "rbxassetid://72514752204972", "rbxassetid://70760945054950",
	"rbxassetid://129930463179623", "rbxassetid://136966848448695", "rbxassetid://74488017413447",
	"rbxassetid://124156103651750", "rbxassetid://123636538923577", "rbxassetid://123940745305285",
	"rbxassetid://95422181220957", "rbxassetid://85779463172831", "rbxassetid://85451012004987",
	"rbxassetid://122144649250110", "rbxassetid://91376372256857", "rbxassetid://122284072508208",
	"rbxassetid://126516601606999", "rbxassetid://131420314948529", "rbxassetid://88911086754037",
	"rbxassetid://110647985191783", "rbxassetid://97270712812416", "rbxassetid://94992992543344",
	"rbxassetid://76507499572286", "rbxassetid://97706370740023", "rbxassetid://114559155845756",
	"rbxassetid://109306533952798", "rbxassetid://131403632828209", "rbxassetid://122498091168554",
	"rbxassetid://115675656988340", "rbxassetid://135342979510615", "rbxassetid://95424707176181",
	"rbxassetid://127855796399644", "rbxassetid://99218772198712", "rbxassetid://140546571870649",
	"rbxassetid://119751520536740", "rbxassetid://138666035263738", "rbxassetid://108946547828595",
	"rbxassetid://80632533990002", "rbxassetid://103216213990752", "rbxassetid://77760703895296",
	"rbxassetid://71574733885552", "rbxassetid://109967588707999", "rbxassetid://86265592768260",
	"rbxassetid://112526271674778", "rbxassetid://110158665076562", "rbxassetid://123616877831050",
	"rbxassetid://132126224577278", "rbxassetid://110728718265049", "rbxassetid://88035044263993",
	"rbxassetid://102872657938822", "rbxassetid://119834887149656", "rbxassetid://93677343741816",
	"rbxassetid://113778810800288", "rbxassetid://134340111977085", "rbxassetid://97537967185164",
	"rbxassetid://93384010922515", "rbxassetid://105968538824751", "rbxassetid://133303061216721",
	"rbxassetid://75356296124042", "rbxassetid://86611519789045", "rbxassetid://98686807740770",
	"rbxassetid://87302593393430", "rbxassetid://74500954492785", "rbxassetid://71726481257884",
	"rbxassetid://77807866797953",
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
