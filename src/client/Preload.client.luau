-- Preloads the UI's images soon after joining (QM, Oct 4: the shop and the animal
-- dictionary's pages took ages to show the first time; Oct 13: all of the UI's art, so
-- none of it pops in late). Every picture the client's scripts use that can actually show
-- (the HUD, menus, popups and buttons) is drawn 1 px and nearly see-through on a screen
-- that's always on, so it stays loaded. The headshots, the dictionary's sheets and the egg
-- art load when their screen opens (QM, Nov 6: no dead preloads). Nothing waits on it.
--
-- The list is made by tools/preload_ids.py: re-run it when art is added. Sounds
-- preload in Sounds.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LowMemory = require(script.Parent.LowMemory)
local Config = require(ReplicatedStorage.Shared.Config)

-- Every image in the client's scripts (tools/preload_ids.py).
local PANELS = {
	"rbxassetid://127821178410489", "rbxassetid://125418799809598", "rbxassetid://107362573611718",
	"rbxassetid://106855326447623", "rbxassetid://119060039201858", "rbxassetid://132882732722928",
	"rbxassetid://135845846149671", "rbxassetid://126251339270486", "rbxassetid://72356826090260",
	"rbxassetid://76663783463176", "rbxassetid://128722118314123", "rbxassetid://120142364189594",
	"rbxassetid://133997765094952", "rbxassetid://72901094417133", "rbxassetid://72181051059940",
	"rbxassetid://115847818752186", "rbxassetid://136367932806454", "rbxassetid://88826165672196",
	"rbxassetid://76511917573203", "rbxassetid://113926447181781", "rbxassetid://136773861994278",
	"rbxassetid://128175495014059", "rbxassetid://85408798859805", "rbxassetid://107816753420921",
	"rbxassetid://127715475489628", "rbxassetid://102985018399551", "rbxassetid://122061064731565",
	"rbxassetid://87361968703172", "rbxassetid://77533462942727", "rbxassetid://88460994933250",
	"rbxassetid://84920756991403", "rbxassetid://130261551778736", "rbxassetid://102545209742676",
	"rbxassetid://89190624413208", "rbxassetid://128255311278989", "rbxassetid://79213006654938",
	"rbxassetid://84991607264564", "rbxassetid://77508300986598", "rbxassetid://87221432893647",
	"rbxassetid://82895123115484", "rbxassetid://74773300097555", "rbxassetid://87136104713556",
	"rbxassetid://96698232796495", "rbxassetid://79525419811481", "rbxassetid://139970505549400",
	"rbxassetid://102165948456968", "rbxassetid://105098230793344", "rbxassetid://139482781062355",
	"rbxassetid://110439659872687", "rbxassetid://101332917430774", "rbxassetid://112045413530937",
	"rbxassetid://102610484944753", "rbxassetid://84196239547123", "rbxassetid://132151928968903",
	"rbxassetid://121162393893227", "rbxassetid://112194074349421", "rbxassetid://117236752430565",
	"rbxassetid://82682007346790", "rbxassetid://118027620960011", "rbxassetid://138455431560057",
	"rbxassetid://98286776885826", "rbxassetid://132028611021169", "rbxassetid://121895939250438",
	"rbxassetid://79662614434978", "rbxassetid://113695299206853", "rbxassetid://126802958042799",
	"rbxassetid://137731947260447", "rbxassetid://105220500829443", "rbxassetid://129763838096024",
	"rbxassetid://132120882288488", "rbxassetid://100476636621954", "rbxassetid://131073330411941",
	"rbxassetid://109185103681711", "rbxassetid://139551342957176", "rbxassetid://136557216823067",
	"rbxassetid://78918914654470", "rbxassetid://130649889910224", "rbxassetid://111594299533130",
	"rbxassetid://125301165432908", "rbxassetid://136135901593127", "rbxassetid://112691374931555",
	"rbxassetid://106883633786837", "rbxassetid://121784684526161", "rbxassetid://92522948167443",
	"rbxassetid://110560724842212", "rbxassetid://124688776792586", "rbxassetid://74196090261063",
	"rbxassetid://85578461423986", "rbxassetid://96862284524676", "rbxassetid://128398088115519",
	"rbxassetid://87618949538639", "rbxassetid://117365953821607", "rbxassetid://74912601109263",
	"rbxassetid://128790726871911", "rbxassetid://134717406361017", "rbxassetid://131579993641835",
	"rbxassetid://88660119728664", "rbxassetid://132053102713664", "rbxassetid://103296530187654",
	"rbxassetid://93115607475102", "rbxassetid://90649473102708", "rbxassetid://134273437630221",
	"rbxassetid://85542206203209", "rbxassetid://77502329949420", "rbxassetid://76054901949807",
	"rbxassetid://120779575988151", "rbxassetid://138690310482207", "rbxassetid://85290109366044",
	"rbxassetid://117268933780863", "rbxassetid://137089266842594", "rbxassetid://105770722348639",
	"rbxassetid://133989350638738", "rbxassetid://94903975169870", "rbxassetid://83345853164128",
	"rbxassetid://106595353110687", "rbxassetid://108874116333491", "rbxassetid://126546375629358",
	"rbxassetid://115536781118070", "rbxassetid://116358195389802", "rbxassetid://99027902215314",
	"rbxassetid://109315089615628", "rbxassetid://105998022695625", "rbxassetid://100941370514849",
	"rbxassetid://81971373381902", "rbxassetid://82472901970710", "rbxassetid://71659275230398",
	"rbxassetid://133913042752808", "rbxassetid://96785493203961", "rbxassetid://109625880806599",
	"rbxassetid://139714019730087", "rbxassetid://127716474790012", "rbxassetid://100253441445728",
	"rbxassetid://112086344358353", "rbxassetid://125539296607125", "rbxassetid://72903095022775",
	"rbxassetid://130186009688014", "rbxassetid://124388771955215", "rbxassetid://119877368095785",
	"rbxassetid://72113109901514", "rbxassetid://84987070586649", "rbxassetid://87614321273679",
	"rbxassetid://107912461575187", "rbxassetid://85646971920304", "rbxassetid://95339327375816",
	"rbxassetid://114106715330048", "rbxassetid://117473019333658", "rbxassetid://120782360993998",
	"rbxassetid://93281428675559", "rbxassetid://117861828286868", "rbxassetid://91869381995495",
	"rbxassetid://113530717781179", "rbxassetid://90717259678888", "rbxassetid://85066893166855",
	"rbxassetid://95599437590618", "rbxassetid://124881834655792", "rbxassetid://84668325203507",
	"rbxassetid://102795691143589", "rbxassetid://90142926499080", "rbxassetid://111649507533762",
	"rbxassetid://135143840112034", "rbxassetid://105231134861157", "rbxassetid://131132122596946",
	"rbxassetid://137113936385932", "rbxassetid://103638328020279", "rbxassetid://86307268458670",
	"rbxassetid://93831958938146", "rbxassetid://78320352111053", "rbxassetid://128883182267763",
	"rbxassetid://97101351248514", "rbxassetid://80563240117126", "rbxassetid://119349539273288",
	"rbxassetid://95626930006876", "rbxassetid://100787444937359", "rbxassetid://82336240433052",
	"rbxassetid://105149417332337", "rbxassetid://83951862994609", "rbxassetid://137754762277353",
	"rbxassetid://132088301588431", "rbxassetid://86585294053216", "rbxassetid://118684084308728",
	"rbxassetid://125349573529100", "rbxassetid://117144807245289", "rbxassetid://119803210932578",
	"rbxassetid://139955585467041", "rbxassetid://77371080716061", "rbxassetid://89848692685766",
	"rbxassetid://114368032731288", "rbxassetid://114164241366433", "rbxassetid://130227469695086",
	"rbxassetid://137156704531563", "rbxassetid://70469571709365", "rbxassetid://84356622911486",
	"rbxassetid://136725772402125", "rbxassetid://140005979942732", "rbxassetid://95236739672996",
	"rbxassetid://124966752636756", "rbxassetid://86824541929406", "rbxassetid://85834206672187",
	"rbxassetid://100466055719917", "rbxassetid://108585154222977", "rbxassetid://106151758290669",
	"rbxassetid://107961643042370", "rbxassetid://112260275929453", "rbxassetid://111082975846791",
	"rbxassetid://78103765703011", "rbxassetid://17520182385", "rbxassetid://7216979807",
	"rbxassetid://73420824782915", "rbxassetid://140037705020050", "rbxassetid://90506809044433",
	"rbxassetid://125036875690208", "rbxassetid://86572003302585", "rbxassetid://77065186414976",
	"rbxassetid://127409850784423", "rbxassetid://135248482417682", "rbxassetid://72137957416956",
	"rbxassetid://101951033426315", "rbxassetid://83223429511866", "rbxassetid://113449238733442",
	"rbxassetid://129857278922864", "rbxassetid://94861344921194", "rbxassetid://128433749405556",
	"rbxassetid://114300820141286", "rbxassetid://107487299920702", "rbxassetid://80262179750586",
	"rbxassetid://134865745295413", "rbxassetid://128484192846174", "rbxassetid://118018475359108",
	"rbxassetid://139647408711436", "rbxassetid://114889489768256", "rbxassetid://90551038508587",
	"rbxassetid://83311618092760", "rbxassetid://84547643672529", "rbxassetid://71738076831384",
	"rbxassetid://104793392329968", "rbxassetid://100062651101544", "rbxassetid://105502035787337",
	"rbxassetid://96598497238200", "rbxassetid://130130177164969", "rbxassetid://95664942496836",
}

-- On phones and tablets (LowMemory) nothing is pinned: the UI's art alone is ~500 MB of
-- textures held for the whole session (measured in Studio, Oct 20), and the <2 GB
-- devices crash on it. There the pictures are only downloaded and decoded, so the
-- first show is quick but Roblox can drop them when memory runs low, and the
-- headshots and the dictionary's sheets load when they're opened.
local warm = Instance.new("ScreenGui")
warm.Name = "PreloadWarm"
warm.ResetOnSpawn = false
-- (QM, Nov 6: with the native UI on, the old PNG art never shows, so only the native UI's
-- own pictures, client/HudImages, are kept loaded)
local list = PANELS
if Config.NativeUi.On then
	list = {}
	for _, id in require(script.Parent.HudImages) do
		if typeof(id) == "string" and id ~= "" then
			table.insert(list, id)
		end
	end
end
for _, id in list do
	local keep = Instance.new("ImageLabel")
	keep.BackgroundTransparency = 1
	keep.Size = UDim2.fromOffset(1, 1)
	keep.Image = id
	keep.ImageTransparency = 0.99
	keep.Parent = warm
end
if not LowMemory.on then
	warm.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

task.spawn(function()
	pcall(ContentProvider.PreloadAsync, ContentProvider, warm:GetChildren())
end)
