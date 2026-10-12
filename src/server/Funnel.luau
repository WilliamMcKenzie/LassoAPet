-- Analytics funnels for Creator Hub > Analytics > Funnels (QM, Oct 11: the old ones,
-- Onboarding, Zones, Captured Animals and Zones Reached, retired; nothing logs them now).
--
-- Player Journey: a new player from their first join through the tutorial, then each
-- quest claimed, in the rough order we expect players to get to them (JOURNEY), so its
-- completion rate is the share who've done the lot. One pass per player (the session id
-- is their UserId), so it runs across sessions; a step logged out of order still counts,
-- and Roblox keeps only a player's first of each step. Only for players who started
-- after it went in (Hatchery's profile.journey: Funnel.join).
--
-- Zones Unlocked: for the same players, the first ride through each biome's barrier
-- (Gold.server's BreakGate), every biome skipped on the way counted too.
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

local JOURNEY = "Player Journey"
local ZONES = "Zones Unlocked"

-- The tutorial, then the quests by [line * 100 + place] (Config.Quests, Quests.claim's i),
-- each named for the quest.
local STEPS = {
	"Joined",
	"Tutorial Started", -- (client) the tap hand on the starter egg
	"Placed Starter Egg",
	"Hatched Starter Egg", -- held E by it in your pen
	"Started Ride", -- (client) on your new pet
	"Rode Out", -- past the start line on an animal
	"Landed Lasso", -- (client) on the animal you lassoed
	"Boss Appeared", -- (client) BOSS IN let go: the Chicken's coming
	"Brought Egg Home",
	"Tutorial Done",
}
local QUEST_ORDER = { 101, 201, 102, 202, 203, 103, 204, 104, 205, 105, 206, 106, 207 }
local questStep = {} -- [quest i] = its step
for _, i in QUEST_ORDER do
	local quest = Config.Quests[i // 100] and Config.Quests[i // 100][i % 100]
	if quest then
		table.insert(STEPS, "Claimed " .. quest.Text .. (if quest.Need and quest.Need > 1 then " " .. quest.Need else ""))
		questStep[i] = #STEPS
	end
end
local stepIndex = {}
for i, name in STEPS do
	stepIndex[name] = i
end
-- The tutorial's steps the client reports (Client/Tutorial's funnel()).
local CLIENT_STEPS = {
	place = "Tutorial Started",
	ride = "Started Ride",
	lasso = "Landed Lasso",
	boss = "Boss Appeared",
}

local cohort = {} -- [player] = { [step] = true }: in the funnels (started after they went in)

local function log(player, i)
	local done = cohort[player]
	if done and i and not done[i] then
		done[i] = true
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, JOURNEY, tostring(player.UserId), i, STEPS[i])
	end
end

-- A tutorial step happened (by name; any other name is ignored).
function Funnel.step(player, name)
	log(player, stepIndex[name])
end

-- Hatchery: a new player (no save yet): "Joined".
function Funnel.track(player)
	Funnel.join(player)
	Funnel.step(player, "Joined")
end

-- Hatchery: a player in the funnels (profile.journey), each session.
function Funnel.join(player)
	cohort[player] = cohort[player] or {}
end

-- Hatchery: quest i claimed.
function Funnel.claimed(player, i)
	log(player, questStep[i])
end

-- Gold.server: the player rode through biome `to`'s barrier, the last they'd broken
-- `from` (1: none yet). Step 1 is the Desert (biome 2).
function Funnel.reached(player, from, to)
	if not cohort[player] then
		return
	end
	for i = math.max(from + 1, 2), math.min(to, #Config.Biomes) do
		pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, ZONES, tostring(player.UserId), i - 1, "Unlocked " .. Config.Biomes[i].Name)
	end
end

-- (no Captured Animals funnel any more)
function Funnel.captured() end

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
		if cohort[player] and type(kind) == "string" and kind ~= "" and typeof(riderCFrame) == "CFrame" and riderCFrame.Position.Z < 0 then
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
	shopPass[player], cohort[player] = nil, nil
end)

return Funnel
