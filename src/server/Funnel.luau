-- Analytics funnels for Creator Hub > Analytics > Funnels.
--
-- Onboarding: a new player's first session, step by step through the tutorial
-- and on to unlocking the Desert. Hatchery calls track() for a player with no
-- save yet; only they're logged, each step once (Roblox also keeps only a
-- player's first of each step). Steps are logged when they happen, so one done
-- out of order still counts. Steps the server can't see (the tutorial's own
-- hints) come from the client over the FunnelStep remote; riding out, the
-- lasso and gold are watched here; the rest are step() calls where they happen
-- (Hatchery, Nests, PenLevel).
--
-- Captured Animals and Zones Reached (QM, Oct 11: the Egg Rodeo's progress): for
-- players who started on it (Funnel.join: Hatchery, from their first session on),
-- one pass per player (the session id is their UserId), so they run across
-- sessions. Captured Animal N: the Nth animal brought home for its egg (1 to
-- CAPTURE_STEPS). Reached <biome>: the first ride through each biome's barrier
-- (Gold.server's BreakGate), every biome you skipped on the way counted too.
-- (The old Zones funnel counted pen upgrades, which unlock nothing now.)
--
-- Shop: each time the shop opens is a pass: opened, picked an offer (the
-- Robux prompt), bought it.
--
-- Rolls and merges are custom events (Analytics > Custom Events), every time.
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Funnel = {}

local desert = Config.Biomes[2]
-- The new tutorial (QM, Oct 11: Client/Tutorial), then on to the Desert.
local STEPS = {
	"Joined",
	"Tutorial Started", -- (client) the tap hand on the starter egg
	"Held Starter Egg", -- (client) it's in your hand: the tap hand moves to your pen
	"Placed Starter Egg",
	"Hatched Starter Egg", -- held E by it in your pen
	"Started Ride", -- (client) on your new pet
	"Rode Out", -- past the start line on an animal
	"Lasso In Reach", -- (client) the first slow-down: an animal's in reach
	"Threw Lasso",
	"Landed Lasso", -- (client) on the animal you lassoed
	"Sprinted", -- (client) the Sprint step done (Shift on a computer, the stick pushed out elsewhere)
	"Boss Appeared", -- (client) BOSS IN let go: the Chicken's coming
	"Brought Egg Home",
	"Placed Egg", -- (it goes in your pen by itself in the tutorial)
	"Egg Hatched",
	"Saw Next Zones", -- (client) the camera's tour of the gates to the Jurassic
	"Tutorial Done",
	"Rode Out Again",
	"Brought Egg Home Again",
	"Saved Half For " .. desert.Name,
	"Can Afford " .. desert.Name,
	"Unlocked Zone 2",
}
local stepIndex = {}
for i, name in STEPS do
	stepIndex[name] = i
end
-- The tutorial's steps the client reports (Client/Tutorial's funnel()).
local CLIENT_STEPS = {
	place = "Tutorial Started",
	hold = "Held Starter Egg",
	ride = "Started Ride",
	reach = "Lasso In Reach",
	lasso = "Landed Lasso",
	sprint = "Sprinted",
	boss = "Boss Appeared",
	tour = "Saw Next Zones",
}
-- Done again once the tutorial's over.
local AGAIN = {
	["Rode Out"] = "Rode Out Again",
	["Brought Egg Home"] = "Brought Egg Home Again",
}
local TUTORIAL_DONE = stepIndex["Tutorial Done"]

local logged = {} -- [player] = { [step] = true }, only for players being tracked

function Funnel.step(player, name)
	local done = logged[player]
	local i = stepIndex[name]
	if done and i and done[i] and AGAIN[name] and done[TUTORIAL_DONE] then
		name = AGAIN[name]
		i = stepIndex[name]
	end
	if not done or not i or done[i] then
		return
	end
	done[i] = true
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, i, name)
end

local function watchGold(player)
	local function check()
		local gold = player:GetAttribute("Gold") or 0
		if gold >= desert.UnlockCost / 2 then
			Funnel.step(player, "Saved Half For " .. desert.Name)
		end
		if gold >= desert.UnlockCost then
			Funnel.step(player, "Can Afford " .. desert.Name)
		end
	end
	player:GetAttributeChangedSignal("Gold"):Connect(check)
	check()
end

function Funnel.track(player)
	if not logged[player] then
		logged[player] = {}
		Funnel.step(player, "Joined")
		watchGold(player)
	end
end

local CAPTURE_STEPS = 20
local cohort = {} -- [player] = true: started on the Egg Rodeo, so in the progress funnels

function Funnel.join(player)
	cohort[player] = true
end

-- Hatchery: the player's `n`th animal brought home (their saved count).
function Funnel.captured(player, n)
	if cohort[player] and n >= 1 and n <= CAPTURE_STEPS then
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Captured Animals", tostring(player.UserId), n, "Captured Animal " .. n)
	end
end

-- Gold.server: the player rode through biome `to`'s barrier, the last they'd broken
-- `from` (1: none yet). Step 1 is the Desert (biome 2).
function Funnel.reached(player, from, to)
	if not cohort[player] then
		return
	end
	for i = math.max(from + 1, 2), math.min(to, #Config.Biomes) do
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Zones Reached", tostring(player.UserId), i - 1, "Reached " .. Config.Biomes[i].Name)
	end
end

function Funnel.event(player, name)
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, name)
end

-- The shop: [player] = { id = its pass's session id, done = { [step] = true } }
-- for the latest time they opened it.
local shopPass = {}
local SHOP_STEPS = { "Opened Shop", "Picked Offer", "Bought" }
local function shopStep(player, i)
	local pass = shopPass[player]
	if pass and not pass.done[i] then
		pass.done[i] = true
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, "Shop", pass.id, i, SHOP_STEPS[i])
	end
end
-- Shop.server: the player asked to buy an offer (2), or paid for one (3).
-- Only counted in a pass that started with the shop open.
function Funnel.shopPicked(player)
	shopStep(player, 2)
end
function Funnel.shopBought(player)
	if shopPass[player] and shopPass[player].done[2] then
		shopStep(player, 3)
	end
end

local funnelStep = Instance.new("RemoteEvent")
funnelStep.Name = "FunnelStep"
funnelStep.OnServerEvent:Connect(function(player, kind, name)
	if kind == "tutorial" and type(name) == "string" and CLIENT_STEPS[name] then
		Funnel.step(player, CLIENT_STEPS[name])
	elseif kind == "shop" then
		local pass = shopPass[player]
		if pass and os.clock() - pass.at < 1 then
			return
		end
		shopPass[player] = { id = HttpService:GenerateGUID(false), done = {}, at = os.clock() }
		shopStep(player, 1)
	end
end)
funnelStep.Parent = ReplicatedStorage

task.spawn(function() -- (Riders makes these: don't hold up whoever requires this)
	ReplicatedStorage:WaitForChild("RideSync").OnServerEvent:Connect(function(player, kind, _, riderCFrame)
		if logged[player] and type(kind) == "string" and kind ~= "" and typeof(riderCFrame) == "CFrame" and riderCFrame.Position.Z < 0 then
			Funnel.step(player, "Rode Out")
		end
	end)
	ReplicatedStorage:WaitForChild("RideCue").OnServerEvent:Connect(function(player, what)
		if what == "lasso" then
			Funnel.step(player, "Threw Lasso")
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	logged[player], shopPass[player], cohort[player] = nil, nil, nil
end)

return Funnel
